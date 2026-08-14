# Shadowsocks for koolshare Merlin 380 ARM

科学上网插件的 armv7l 分支，基于 [cary-sas/v2ray_bin](https://github.com/cary-sas/v2ray_bin)，
在其之上**聚焦UDP和QUIC加速稳定性**做链路修复与界面精简。上游本身衍生自
[fancyss_arm380](https://github.com/hq450/fancyss_history_package/tree/master/legacy/fancyss_arm380)。

当前版本：**5.3.0** · 离线包 `shadowsocks-5.3.0-beta3.tar.gz`

> `beta3` 只标识本次修正版离线包，插件内部版本仍为 **5.3.0**。

> **5.3.0 说明**：本版**下线 Hysteria2 的透明 UDP**，并把 Hysteria2 拥塞控制的默认项改为
> **Brutal**（默认写入上行 `100 mbps`、下行 `200 mbps`）。经过三轮真机取证，确认 UDP 问题
> 不是配置问题、
> 不是 hysteria 构建问题、也不是服务端问题，而是**本固件内核与 hysteria `udpTProxy` 架构的
> 结构性冲突** —— 在 Merlin AM380 的 2.6.36.4 内核上它不可能正确工作。详见
> [Hysteria2 的透明 UDP 为什么在本固件上不可用](#hysteria2-的透明-udp-为什么在本固件上不可用)。
>
> 随之移除的界面与代码：【Hysteria2设定】里的 **UDP 开关**与**日志级别**下拉框、
> `/tmp/hysteria.log` 及其解析、`ss_runtime_hy2_server_udp` / `ss_runtime_hy2_udp_unsupported`
> 两个运行时结论、`start_hy2` 里"剥掉 udpTProxy 重试"的自愈分支。
> Hysteria2 节点下，全局的「同步UDP与TCP」会被**锁定为【关闭】并置灰**，旁边写明原因。
>
> **TCP 代理完全不受影响。** 要用 UDP / 游戏加速，请改用 Xray 系节点
> （VLESS / VMess / Trojan）—— 它的 `dokodemo-door` 在用户态自己做 `(src,dst)` 分流，
> 不依赖内核接管，在本固件上工作正常，已由本轮 A/B 实测确认（VLESS 侧 2312 包全部命中 TPROXY）。
>
> **兼容性**：删除 dbus 键 `ss_basic_hy2_udp`、`ss_basic_hy2_log_level`（安装/恢复/卸载三处
> 都会清理历史值）。5.2.9-beta1 引入的探针增量判据（`ss_runtime_udp_probe_game_prev{,_t}`）
> 与详细状态页的现场重采样**保留**，它们与节点类型无关且已实测有效。
> DNS 劫持同时删除旧“全部”档及其 TCP/53、DoT/DoH、`strict-order` 后备实现；界面只保留
> “默认 UDP/53”复选确认框。升级清理只拆除 `SHADOWSOCKS_DNSF`、`ss_doh` 等可证明归属
> 插件的命名对象；旧版直写的 TCP/UDP-53 DNAT 没有所有权标记，且可与 Pi-hole 规则逐 token
> 完全相同，新版运行期不会扫描或猜删。正常升级改用包内新版 `stop`，不再执行旧版的无界删除；
> 检测到旧值 `2` 时，安装器会暂时锁住插件开关并调用固件标准 `restart_firewall` 重建运行时表，
> 再由各插件的 `nat-start` 按所有权重新下发持久化规则。手工直写且未挂入 `nat-start` 的临时
> iptables 规则本来就无法跨防火墙重启保留，需要先写入持久化钩子。

离线包校验：

```text
SHA256  571f7fed722e3f3d9931767fcd71ed4688b97aa8f728f1c28a1e324e20f6e9a1
MD5     ffccf446ebd4766e0313454ece28b62d
```

---

## 真机验证清单

本版删代码多于加代码，所以**回归项排在最前**：先确认 Xray 侧一个字没坏，再看 hy2 侧该消失的
东西是不是都消失了。

### 0　VLESS 不许被碰坏（回归项，最先测）

改动只落在 hy2 分支、界面与状态输出；`apply_nat_rules` / TPROXY / 策略路由**逐字未动**。
但 `ss/cru/udp.sh` 与 `ss_proc_status.sh` 是两个核心共用的，必须实测。

1. 切 VLESS 节点，「同步UDP与TCP」= 仅代理QUIC+Game，填好 Game 端口，应用。
2. 界面：「同步UDP与TCP」下拉框**可选、不置灰**，旁边**没有**黄色提示。
3. 开游戏 5 分钟，看「系统状态」：

```text
mangle PREROUTING  multiport dports <你的Game端口>   ← 包数应持续增长
mangle SHADOWSOCKS_CHN  TPROXY                       ← 与上一行同量级
ss_runtime_udp_probe = [flow]
```

4. 游戏退出后再看一次，隔 5 分钟以上：probe 应从 `flow` 转 `ok`（增量为 0），
   而不是一直绿着。

### 1　hy2 的 UDP 界面与配置彻底消失

1. 切 Hysteria2 节点，进【Hysteria2设定】：**没有 UDP 开关、没有日志级别下拉框**；
   拥塞控制默认显示 **Brutal**，带宽默认显示上行 `100`、下行 `200` Mbps。
2. 全局「同步UDP与TCP」下拉框**置灰锁定在【关闭】**，右侧有黄色说明写明内核原因。
3. 应用后检查生成的配置：

```bash
jq 'del(.auth)' /koolshare/ss/hysteria.json
```

`udpTProxy` 键**必须不存在**；`socks5` 与 `tcpRedirect` 照常。

默认配置还必须包含：

```json
"bandwidth": {"up": "100 mbps", "down": "200 mbps"}
```

且不能出现 `"congestion": {"type": "brutal"}`。选择 BBR standard 时，`bandwidth` 与
`congestion` 都应省略；BBR conservative/aggressive 与 Reno 才生成 `congestion`。

4. `/tmp/hysteria.log` **不应被创建**（本版不再写日志）。

### 2　hy2 的 TCP 代理完全不受影响

同一 hy2 节点下正常上网 5 分钟：

```text
nat SHADOWSOCKS_CHN  REDIRECT ... redir ports 3333   ← 包数正常增长
```

网页、DNS（dns2socks 走 SOCKS5）均正常。这是本版最重要的"没弄坏"判据。

### 3　降级文案与状态位正确

hy2 节点下看「系统状态」：

```text
ss_runtime_udp_state = [degraded_node]
ss_runtime_udp_probe = [unsupported]     ← 黄灯，不是红灯 fail
-- Hysteria2 透明UDP（已下线，非故障）--  ← 有这一段，写明内核原因
```

**不应**再出现 `ss_runtime_hy2_udp_unsupported`、`ss_runtime_hy2_server_udp`、
以及「hysteria 运行日志」整段。

### 4　历史 dbus 键被清理

升级安装后：

```bash
dbus get ss_basic_hy2_udp          # 应为空
dbus get ss_basic_hy2_log_level    # 应为空
dbus get ss_runtime_hy2_server_udp # 应为空
```

从 5.2.x 的备份恢复配置后再查一次（`ss_conf_restore.sh` 也做了清理）。

### 5　ACL 主机IP地址控件的外观（界面项）

「访问控制」页第一行：**主机IP地址**框应与同行的**访问控制**下拉框等宽（160px）、
等高、左边距一致；设备列表箭头**内嵌在输入框右端**，不再是外挂的方形按钮。
点箭头仍能正常拉出设备列表，选中后 IP 正确回填。

### 6　顶部页签栏（本版新修，Chrome 必测）

1. **用 Chrome 打开**插件页面：顶部应能看到「Shadowsocks 设置」「Xray本地聚合」两个页签，
   **不被下面的主面板遮住**。这是本版修复的主要症状。
2. 页签只有这两个，没有「负载均衡设置」「Socks5设置」。
3. 两个页签互相跳转正常，跳过去之后页签栏依然可见。
4. 再用 iOS Safari 看一次（改动前它就是正常的）：应与 Chrome 表现一致，不能变差。
5. 若手上有 Firefox 也看一眼：页面底部内容不应被裁掉（本版去掉了固定 975px 高度）。

> 若页签栏仍被遮住，多半是浏览器缓存了旧的 `ss-menu.js`，强刷一次（Ctrl+F5）。
> 样式表这边已经把两个变体类的负边距归零来兜这种情况。

### 7　ACL 主机的 UDP 档位守卫（历史项，本版未改）

ACL 里给某台主机单独选模式时，「同步UDP与TCP」的档位仍按主模式守卫处理，
行为应与 5.2.9-beta1 一致。

### 8　DNS 劫持只剩默认模式

1. 【DNS劫持】应为复选确认框，不再出现“全部”选项。
2. 勾选后只应下发经 `SHADOWSOCKS_DNS_*` 链的 UDP/53 DNAT；不应创建 TCP/53 DNAT、
   `SHADOWSOCKS_DNSF` 或 `ss_doh`。
3. 从旧配置升级时，值 `2` 自动迁移为 `1`；新版清理旧 DNSF、DoT/DoH 与 `ss_doh`。
   正常升级在替换文件前运行包内新版 `stop`，并对旧值 `2` 执行一次标准防火墙重建；安装器
   不匹配匿名 DNAT，持久化的第三方规则由各自 `nat-start` 在重建后恢复。

### 出问题时怎么收集

「系统状态」整页 + 应用时的插件日志。本版已不再有 hysteria 运行日志，
若需要协议级证据，临时前台跑一次即可（不改任何配置）：

```bash
killall hysteria; cd /koolshare/bin && ./hysteria -c /koolshare/ss/hysteria.json -l debug --disable-update-check 2>&1 | grep -E "connected to server|UDP transparent"
```

## 支持的协议

SS（含 SS2022）· VMess · VLESS（XTLS Vision / REALITY）· Trojan · Trojan-Go · Hysteria2

xray 已完全取代 v2ray 与 trojan-go，同时承载 VMess / VLESS / Trojan / Trojan-Go ws / SS2022。
另支持多 xray 节点聚合与负载均衡、SmartDNS、ChinaDNS-NG。

> 上面这份清单只列**本分支实际维护与验证**的协议。代码里还留着
> **SSR / NaiveProxy / koolgame / AnyTLS** 的实现：前三个已没有「添加节点」入口，
> AnyTLS 仍可通过「添加节点 → Trojan → 二进制选 AnyTLS」新建（入口保留，与上游一致），
> 但都不在维护范围内，故不列出。存量节点不受影响，仍可正常使用与编辑。

## 适用机型

需刷 koolshare 梅林 **380** 改版固件（linux 内核 2.6.36.4，armv7l）：

* 华硕：`RT-AC56U` `RT-AC68U` `RT-AC66U-B1` `RT-AC1900P` `RT-AC87U` `RT-AC88U` `RT-AC3100` `RT-AC3200` `RT-AC5300`
* 网件：`R6300V2` `R6400` `R6900` `R7000` `R8000` `R8500`
* Linksys EA：`EA6200` `EA6400` `EA6500v2` `EA6700` `EA6900`
* 华为：`ws880`

---

## 本分支的两条核心链路

大陆白名单模式下"部分境外站点（尤其 Google / YouTube 等 HTTP/3 站点）打不开、不走代理"
这类问题，根源集中在 UDP 与 DNS 两处。这两条链路是本分支改动最多的地方。

完整的逻辑拆解（含内核包路径推导、规则次序、降级路径、两条链路的交叉矩阵）见
**[`review_archive/chain-logic.md`](review_archive/chain-logic.md)**。

### 一、同步 UDP 与 TCP（全局设定）

原开关由「开 / 关」升级为四档，按负载从低到高排列：

| 档位 | 导入透明代理的 UDP | 适用 |
|---|---|---|
| **关闭** | 无 | 出厂默认 |
| **仅代理 QUIC**（推荐） | UDP/443 + 黑名单目标全端口 | 让 HTTP/3 站点正常走代理，又不让 BT/视频的大流量 UDP 涌进 TPROXY |
| **仅代理 QUIC+Game** | 上者 + Game Port 指定的端口 | 境外游戏服走代理、国内直连 |
| **全量 UDP** | 全部 UDP | 分流最彻底，逐包处理 + 用户态转发，CPU 负载最高 |


#### 这四档在链路的哪一层生效

档位**不直接**决定下发什么规则 —— 中间隔着 `mangle` 这个总闸。理解这一点能解释
大部分"我选了档位但好像没生效"的现象：

```
 档位 ss_basic_udp_sync ─┐
 游戏模式 / ACL游戏主机  ─┤
 节点核心能力            ─┼─▶ 消毒 ─▶  mangle=1 或 ""  ─▶ 决定第①层建不建、建成什么形状
 传输层（SIP003 插件）   ─┤   非SS节点：       ▲
 内核 TPROXY 是否可用    ─┤   主模式3→2       │  5 条静默降级路径，任一命中即 mangle=""
 fwmark 0x07 / table 310 ─┘   game_on 清空    │  （核心无透明UDP入站 / TPROXY探测失败 /
                                              │    fwmark 被占 / table 310 被占）
  LAN 客户端 UDP ────────────────────────────▶│
                                              ▼
 ┌─ 第①层  入口筛选（mangle PREROUTING，四条 hook 全部 -i br+）────────────────────┐
 │   仅QUIC/仅QUIC+Game →  --dport 443 ┊ black_list目标 ┊ Game端口(3档且校验通过)  │
 │   其余情形           →  -p udp（全部）                                          │
 │   —— 唯一看档位的一层                                                            │
 └────────────────────────────────────────────────────────────────────────────────┘
         │ 没被 hook 匹配的 UDP 到此为止：直连出去，不进下面任何一层
         ▼
 ┌─ 第②层  分流判决（mangle/SHADOWSOCKS + 五条模式链）—— 只看目的地，不看档位 ─────┐
 │   UDP/53 → RETURN ┊ white_list → RETURN                                        │
 │   → ACL 主机走自己的模式链 → 其余走默认模式链                                     │
 │   模式链内：white → RETURN、black → 代理、chnroute/gfwlist 判决，落空即直连       │
 └────────────────────────────────────────────────────────────────────────────────┘
         │ TPROXY --on-port 3333 --tproxy-mark 0x07 → ip rule → table 310 → 本机
         │ （内核显示为 mark 0x7/0xffffffff：不补零，且缺省掩码是全字覆盖 ——
         │   拿 0x07 去 grep iptables/ip rule 的输出会一无所获）
         ▼
 ┌─ 第③层  数据面 ────────────────────────────────────────────────────────────────┐
 │   ss-libev  `ss-redir -u`                                                       │
 │   Xray      dokodemo-door  network=udp  sockopt.tproxy=tproxy                   │
 │   两者配置都监听 3333；运行时可能呈现为 [::]:3333 的双栈套接字，                 │
 │   同一 socket 以 v4-mapped 形式收 IPv4，故 IPv4 的 TPROXY 投递照常成立            │
 │   （真机实测：/proc/net/udp 里没有 3333，只有 /proc/net/udp6 有）                 │
 │   都做：收包 → 取原始目的地址 → 经隧道送出 → 伪装源地址回                          │
 │   代理核心【不知道"档位"这回事】，换协议只换这一层，①②两层一字不动               │
 └────────────────────────────────────────────────────────────────────────────────┘
```

几个容易踩的点（都经过逐行核验，不是推测）：

* **`mangle` 才是开关，档位只是它的输入之一。** 上面那 5 条降级路径任一命中，
  第①层整块消失、UDP 全部直连，而界面上你选的仍然是「仅代理 QUIC」——
  这正是主界面要有 UDP 状态行的原因，它显示的是**实际生效值**。
* **档位选「关闭」也未必没有 hook**：SS 协议节点上，只要主模式是游戏模式、
  或访问控制里有游戏模式主机，仍会下发全量 UDP hook。非 SS 节点则不会（已被消毒逻辑挡掉）。
* **「仅代理 QUIC+Game」可能在运行时悄悄等于「仅代理 QUIC」**：Game 端口语法没过、
  或 multiport 规则写入失败，都会让第三条规则不存在，而**界面上的档位不会变**，
  只能靠状态栏那行看出来。
* **Hysteria2 不进入第③层**：本固件 2.6.36.4 内核缺少 hysteria `udpTProxy` 依赖的
  UDP established socket 接管，5.3.0 起该节点只做 TCP 透明代理；界面会锁定 UDP 档位为关闭。

完整的逐行拆解（含每条规则的行号、消毒逻辑、以及初稿被核验推翻的三处错误）见
[`review_archive/chain-logic.md`](review_archive/chain-logic.md) §2.0。

* Game Port 支持单端口与端口段，逗号隔开，如 `27015,7777-7778`。前后端双重语法检查
  （端口 1-65535、multiport 槽位 ≤15、**不允许前导零**），非法则不下发规则；留空时与「仅代理 QUIC」一致。
* 存在游戏模式主机、或主模式为游戏模式时，游戏需要全量 UDP，自动按全量处理。
* 访问控制列表里的主机，其 UDP 走该主机自己的模式链，与它的 TCP 语义一致
  （「不通过代理」的主机仍然直连）。
* **节点必须能承载 UDP**，这不只看核心类型还看传输层：
  * **VLESS / VMess（Xray，type 3）—— UDP 路径已逐条核对，是通的**：
    `xray_in_tproxy` 给的是 `network:"udp"` + `sockopt.tproxy:"tproxy"` 的 dokodemo 入站、
    监听 3333，正对上 mangle 的 `TPROXY --on-port 3333 --tproxy-mark 0x07`；
    该入站在 8 处配置生成点都按 `mangle` 条件加入（普通路径与节点聚合路径均覆盖）；
    配置里没有 `sniffing`（不会改写目的地再重路由）也没有 `block` 出站（xray 自身不拦 UDP）；
    非聚合路径无 routing 段、全部走首个出站，聚合路径的 routing 规则含 `in-tproxy`。
    「开启片段」那个 `fragment` 出站只改写外层 TLS ClientHello，UDP 在该连接内隧道化，不受影响；
  * **ss-libev + SIP003 simple-obfs —— 不行**：simple-obfs 是纯 TCP 插件，
    而 `ss-redir -u` 会把 UDP 绕过插件直发 `server:port`、服务端不接受。
    插件会识别这一组合并降级纯 TCP，状态栏显示「插件阻断」；
  * **Hysteria2 —— 当前固件只支持 TCP 透明代理**。生成器拒绝 `udpTProxy`，全局 UDP 档位
    在该节点下锁定为关闭；根因与实机证据见下文专节；
  * **naive / anytls —— 本插件未为其配置透明 UDP 入站**，会降级纯 TCP。
    注意这是"缺配置"而不是"核心无能力"。

**境外 QUIC 泄漏防护（UDP 链路的 fallback）**：「关闭」档下，境外 QUIC（UDP/443）首包会被
filter 层拦截，强制浏览器回退 TCP 走代理。**仅在【大陆白名单】/【游戏模式】下成立** ——
该防护只在主模式 2 建链，gfwlist / 全局 / 回国模式没有这道兜底，此时境外 UDP（含 QUIC）为明文直连；
要在这些模式下覆盖 QUIC，请选「仅代理 QUIC」。

> UDP 链路的兜底只有主模式 2/3 的 filter guard。
> gfwlist / 全局 / 回国模式下 UDP 降级后境外 QUIC 是明文直连，没有任何兜底。
> 补齐它需要让 guard 的内容随模式改形（chnroute 形状照搬到 gfwlist 会 reset 所有
> 非 gfwlist 境外 TCP），属重构；且现有那道 guard 本身尚未上真机验证，
> 在未验证的机制上再叠一层未验证的实现风险过高，故排在真机验证之后。

**IPv6 泄漏防护**：大陆白名单模式且启用 IPv6 时，拒绝把 IPv6 转发到外网，
让客户端立即回退到受透明代理接管的 IPv4（保留内网 IPv6 互访）。

### 二、DNS 劫持（原 chromecast）

界面只保留一个复选确认框：

* 勾选（默认）：把 LAN 客户端发往任意地址的明文 **UDP/53** 请求 DNAT 到路由器 dnsmasq；
* 取消勾选：不下发 DNS 劫持规则。

旧“全部”档已经删除，不再劫持 TCP/53，不再创建 `SHADOWSOCKS_DNSF` 或 `ss_doh`，也不再
拦截 DoT/DoH/DoQ；`dnsmasq.postconf` 不再插入 `strict-order` 与国内后备上游。原因是代理
QUIC 后，这套静态加密 DNS 拦截不能提供完整覆盖，却增加了规则、状态与故障面。

配置兼容：旧值 `2`、空值和损坏值在安装、恢复及启动时归一为 `1`；用户明确取消勾选产生的
`0` 会保留。新版清理函数只拆除 5.2.x 中具备插件所有权标记的 DoT/DoH bypass、DNSF 与
`ss_doh`；不扫描无法区分来源的 PREROUTING DNAT。当前版本不会重新创建这些旧对象。

默认模式只能接管明文 UDP DNS。客户端自己的 TCP DNS、DoH、DoT 或 DoQ 仍可绕过路由器；
这是删除“全部”后的明确边界，不再以“全部强制”文案承诺无法完整实现的覆盖。

### dnsmasq-fastlookup 兼容性

* 替换/还原用 bind mount + service 重启原地换血，不再先杀 dnsmasq 等 init 异步拉起，
  消除人为的 DNS 中断窗口；还原用惰性卸载（`umount -l`），挂载点精确匹配 `/usr/sbin/dnsmasq`；
* 替换前用 fastlookup 二进制 `--test` 预检当前配置，不兼容则放弃替换保留原版；
* **该预检不充分**，所以才有上面那道事后校验：`/etc/dnsmasq.conf` 是固件在重启时重新生成的，
  插件本次写入 `/jffs/configs/dnsmasq.conf.add` 的内容要等生成后才进去，`--test` 此刻测不到。
  "`--test` 通过但重启起不来"是可能的；
* 关闭插件时先清空劫持规则再动 dnsmasq，消除停止瞬间的 DNS 中断。

---

## 运行时状态显示

UDP 下拉框里选的是请求值，实际生效值还取决于节点核心能力、内核 TPROXY、fwmark 与
table 310。DNS 复选框只有默认/关闭两种状态。主界面状态栏分别显示两条链路的运行结果：

* **UDP 代理** —— 两枚芯片。档位段来自配置层；实测段来自运行层探测
  （校验 UDP/3333 透明入站监听、fwmark→table310 策略路由、table310 本机路由、
  mangle PREROUTING 钩子、模式链内 TPROXY 规则）。
  **QUIC/443 按设计排除在实测之外**：「仅代理 QUIC」档代理的就只有 UDP/443，
  没有非 443 UDP 可查，显示为「不适用」（空心点）而非失败 —— 否则选了推荐档反而看到红灯。
* **DNS 劫持** —— 只显示关闭或默认 UDP/53；同行显示 **dnsmasq-fastlookup 的实际状态**：
  已挂载则一枚 `fastlookup` 芯片，
  「选了替换但实际没挂上」（`--test` 未通过，多为与当前 dnsmasq 配置不兼容）则标红说明 ——
  此前这个差异在界面上无处可看，只在日志里一行。

两行都在提交完成后立即重取刷新，并随状态栏轮询保持更新。
「系统状态」页有对应诊断输出（UDP/53 规则、dnsmasq 存活与 fastlookup 挂载情况）。

### 探针语义：累计值 vs 增量（5.2.9-beta1 起）

主界面那枚「实测」芯片由 `ss/cru/udp.sh` 每 5 分钟回写一次（apply 收尾与打开「系统状态」页
时也会各跑一次）。它判断"有没有流量"用的是**两次采样之间的增量**，不是累计值。

这个区分是必要的：`iptables` 的规则计数是**自建链以来的累计值**，只有重新 apply
（删链重建）才归零。旧版据此判 `>0` 就报"已有流量经代理"，于是游戏关了、隧道断了、
UDP 全程被服务端拒掉，芯片照样是绿的 —— 一个永远不会熄的灯。

真机上这正好掩盖过一次真故障：HY2 四分钟 114 包（0.42 包/秒）与 VLESS 3281 包
（12 包/秒）相差 29 倍，形态是"发出去没人回、游戏在退避重试"，但两者在旧判据下都只是 `>0`。

现在的取值：

| probe | 含义 |
|---|---|
| `flow` | 上个采样周期内**有新增**包经 TPROXY |
| `ok` | 累计 >0 但一个周期内**零新增** —— 游戏已退出则正常；游戏还在跑就是"UDP 只出不回" |
| `warn` | Game 端口命中了，但 TPROXY 计数为 0 —— 包按分流规则走了直连（白名单 / chnroute 国内段） |
| `unsupported` | 该节点/协议提供不了 UDP 加速（黄灯，**不是故障**）。含新增的"服务端未开 UDP" |
| `fail` | 该生效却没立起来，或内核/环境故障 —— 只有这个是真红灯 |

已处理两个边界：apply 后计数器归零（基线还停在重建前的高值，不会误报"零新增"）、
以及连点两次「系统状态」（间隔太短时不下"流量停了"的结论，也不破坏基线）。

### Hysteria2：不再有 UDP 相关的运行时状态（5.3.0 起）

5.2.9-beta1 曾在这里显示两层 hy2 UDP 前提（构建是否认 `udpTProxy`、服务端是否声明
`UDPEnabled`）。5.3.0 起这两个键连同 `/tmp/hysteria.log` 一并移除 —— 因为真正的阻断在
**第三层**，而它是无条件成立的：本固件内核根本不做 UDP 的 TPROXY established 接管，
所以前两层判成什么都没有意义。原委见下一节。

Hysteria2 节点下，「同步UDP与TCP」在界面上被锁定为【关闭】并置灰，
`ss_runtime_udp_state` 回写 `degraded_node`，探针给 `unsupported`（黄灯，不是红灯）。

---

## Hysteria2 的透明 UDP 为什么在本固件上不可用

这一节记录一次完整的误诊与最终定位，因为中间三个"看起来很像"的结论**全都是错的**，
而且每一个都能自圆其说。

### 结论

hysteria 的 `udpTProxy` 依赖一个内核特性：**TPROXY 对 UDP 的 established socket 接管**。
Merlin AM380 的 2.6.36.4 内核没有这个特性（它在 2.6.37 才进主线）。
两者叠加的结果是 hysteria 退化成**一个包一条会话**，游戏永远建立不了连接。

这不是配置错误、不是 hysteria 构建缺特性、也不是服务端没开 UDP —— 这三条都被实测逐一排除。

### 机制

hysteria 的透明 UDP 入站是这样设计的（[`app/internal/tproxy/udp_linux.go`][hy2-udp]）：

```go
for {
    // We will only get the first packet of each src/dst pair here,
    // because newPair will create a TProxy connection and take over
    // the src/dst pair. Later packets will be sent there instead of here.
    n, srcAddr, dstAddr, err := tproxy.ReadFromUDP(conn, buf)
    r.newPair(srcAddr, dstAddr, buf[:n])
}
```

`newPair()` 会 `tproxy.DialUDP(dst, src)` 建一个 **connected 的 `IP_TRANSPARENT` socket**
（绑在游戏服务器地址上、连到 LAN 客户端），然后指望内核把该四元组的**后续包**直接投递给它，
通配监听器只负责首包。

这个"接管"靠的是 `xt_TPROXY` 的**两段查找**：

```c
/* 先按原始四元组查 established socket */
sk = nf_tproxy_get_sock_v4(..., NF_TPROXY_LOOKUP_ESTABLISHED);
if (!sk)
    /* 查不到才回落到 --on-port 指定的 listener */
    sk = nf_tproxy_get_sock_v4(..., lport, ..., NF_TPROXY_LOOKUP_LISTENER);
```

**UDP 的 established 那一段是 2.6.37 才加进主线的**，而本插件只支持的 AM380 内核是
2.6.36.4 —— 它只有 listener 查找。于是每一个包都落回通配监听器，`newPair()` 对**每个包**
各跑一次。

后果是**会话身份被打碎**，不是效率损失：

| 环节 | 正常内核 | 本固件内核 |
|---|---|---|
| 一次游戏会话的 `newPair` 次数 | 1 | 每包 1 次 |
| HY2 UDP SessionID | 1 个 | 每包一个新的 |
| 服务端出站 socket | 1 个，源端口固定 | 每包一个新的，**源端口每包都在变** |
| 游戏服务器看到的 | 一个稳定的客户端 | 每包来自一个"新客户端" |
| 孤儿会话 | 无 | 每个都空转到 20s 超时才关 |

### 实机证据

把日志级别开到 `debug`、玩 5 分钟游戏，`/tmp/hysteria.log` 里是这样的：

```text
14:09:30Z DEBUG UDP transparent proxy connect {"addr":"192.168.50.167:57411","reqAddr":"94.242.209.76:7777"}
14:09:30Z DEBUG UDP transparent proxy connect {"addr":"192.168.50.167:57411","reqAddr":"94.242.209.76:7777"}
14:09:31Z DEBUG UDP transparent proxy connect {"addr":"192.168.50.167:57411","reqAddr":"94.242.209.76:7777"}
...                                            ← 11 秒内 22 次，源端口与目的地全程不变
14:09:50Z DEBUG UDP transparent proxy closed  {"addr":"192.168.50.167:57411","reqAddr":"94.242.209.76:7777"}
                                               ← 恰好比对应的 connect 晚 20 秒（配置的 timeout）
```

**同一个 `(src,dst)` 对反复 `newPair`**，这在正确的内核上整场游戏只该出现一行。
每条会话都从没收到任何回包，20 秒读超时才关闭。

三次 HY2 测试的 Game 端口计数：

| 样本 | 包数 | 字节 | 平均包长 | 速率 |
|---|---:|---:|---:|---:|
| HY2 #1 | 114 | 10137 | 88.9 B | 0.42 包/秒 |
| HY2 #2 | 114 | 10134 | 88.9 B | 0.16 包/秒 |
| HY2 #3（debug） | 76 | 6753 | 88.9 B | 0.26 包/秒 |
| **VLESS 对照** | **2312** | **398K** | **176 B** | **7.7 包/秒** |

平均包长三次都是 88.9 B 且高度一致 —— 全是同一种连接尝试包，**从来没有进入过真正的游戏数据**；
VLESS 的 176 B 才是在跑的状态同步。速率相差约 30–48 倍。

### 被排除的三个错误结论

| 猜测 | 为什么看起来对 | 怎么被推翻 |
|---|---|---|
| 插件没给 hy2 配 UDP 入站 | 上游确实只写了 `tcpRedirect` | 补上 `udpTProxy` 后监听器确实起来了（`UDP transparent proxy listening {"addr":"0.0.0.0:3333"}`），问题照旧 |
| 这份 hysteria 构建不认 `udpTProxy` | 启动失败会是同样现象 | 进程正常启动、PID 全程不变、日志明确打印监听成功 |
| 服务端没开 UDP | 现象完全吻合：计数正常、界面全绿、游戏不通 | 日志直接给出 `connected to server {"udpEnabled": true, ...}`，并且**零条** `UDP transparent proxy error`（Warn 级，与日志里几十条 `TCP redirect error` 同级、确认可见） |

第三条尤其有迷惑性：它在 `xt_TPROXY` **之后**失败，而 iptables 计数是在 target 做 socket
lookup **之前**就加过的，所以"Game 计数正常、TPROXY 计数正常、游戏不通"这组现象，
`udpEnabled=false` 和本次的内核问题**完全一致**。区分它们只能靠 hysteria 自己的日志。

### Xray 为什么不受影响

Xray 的 `dokodemo-door` TPROXY 入站**根本不依赖内核接管**：所有包都留在那一个通配监听器上，
逐包读 `IP_ORIGDSTADDR` 拿原始目的地，`(src,dst) → session` 的 demux **在用户态自己做**。
与内核版本无关。

这就是为什么同一台路由器、同一套 iptables/TPROXY/策略路由规则下，
VLESS 的 2312 个游戏包全部正常经代理，而 HY2 一个都建立不起来。

### 未来怎么修

按代价从低到高：

**1. 换 Xray 系节点（当前推荐，零成本）**

VLESS / VMess / Trojan 走 Xray，UDP 与游戏加速在本固件上工作正常，已实测。
Hysteria2 继续用作 TCP 代理，不受任何影响。

**2. 给 hysteria 打用户态 demux 补丁并重新编译（正确的修法）**

把 `ListenAndServe` 改成自己维护 `map[src+dst]*pair`：命中就复用已有 `hyConn.Send()`，
没命中才 `newPair`；per-pair 那个 `conn.Read` goroutine 直接去掉（它在本内核上永远收不到
东西），只保留回程的 `Local <- Remote`。约 30 行，改完 hysteria 就和 Xray 一样不挑内核。

仓库里已有 `hysteria-master/` 源码与 `hyperbole.py` 构建脚本；目标架构 `GOARCH=arm GOARM=7`。
这属于换二进制，不是插件配置层能解决的，所以没有并入本版。

**3. 用 Xray 前置 + hysteria 的 SOCKS5 出站（不重编，但代价大）**

hysteria 的 SOCKS5 服务端支持 UDP ASSOCIATE（[`app/internal/socks5/server.go`][hy2-socks5]）。
于是可以：UDP 走 Xray `dokodemo-door` tproxy 入站（占 **UDP** 3333）→ `socks` 出站到
`127.0.0.1:23456` 且 `"udp": true`；TCP 仍走 hysteria 的 `tcpRedirect`（占 **TCP** 3333，
同号不同协议不冲突）。

代价是两个核心常驻、多一跳本地 SOCKS5，CPU 明显上升；且现有启动流程是"先杀 xray 再起
hysteria"，要改的地方不少。除非有强需求，方案 1 或 2 都更划算。

[hy2-udp]: https://github.com/apernet/hysteria/blob/master/app/internal/tproxy/udp_linux.go
[hy2-socks5]: https://github.com/apernet/hysteria/blob/master/app/internal/socks5/server.go

---

## 与上游的界面差异

上游功能列表描述的是插件底层能力，本分支在界面上精简了部分入口，**以此处为准**：

* 移除「KCP 加速」「UDP 加速」入口，并移除 `koolgame` `speederv1` `speederv2` `udp2raw` `pdu`
  二进制及相关死代码（安装包缩小约 2.5MB，升级时自动清理路由器上的旧文件）；
* 「更新管理」移除「节点订阅设置」「通过链接添加服务器」；
* 「添加节点」移除「SSR」「koolgame」「Naive」（存量节点仍可正常编辑）；
* 移除主界面「检查并更新」按钮 —— 有新版本时仍会在版本号旁提示，升级请走软件中心；
* **顶部页签只保留「Shadowsocks 设置」与「Xray本地聚合」**（5.3.0）：「负载均衡设置」
  与「Socks5设置」功能已过时，从导航里摘掉。两个 `.asp` 与其后端代码仍在包内，
  直接输入地址可访问，只是不再从页签暴露；
* **游戏模式仅限 SS 协议节点**：其它协议跑全量 UDP 透明代理对路由器负载过重。
  非 SS 节点选择游戏模式时自动回退大陆白名单模式，其 UDP 需求由「同步 UDP 与 TCP」覆盖
  （界面与后端双重拦截，均有日志提示）。

### 界面样式

沿用 Merlin X380.6 固件原本的蓝灰配色（与固件外壳本是一体，不另起一套），只做精细化：
半径梯度收敛为四级且层级同心、实心硬边换成发丝线、层次改用内高光与极轻阴影；
把原本散落的 7 种黄 / 6 种绿 / 3 种红 / 3 种青 / 5 种紫 / 6 套按钮渐变统一成一套语义色阶
（用属性选择器在样式层就地映射，标记未改动）；强调色只保留固件自己的高亮蓝且只表示"可交互"，
状态一律走语义色阶。不引入网络字体。

设置项分组：「账号设置」原本 61 个设置行、零分组、其中 34 行按节点类型条件隐藏，
平铺着只能靠肉眼扫。现按 节点 / 协议类型 / 连接 / SS·SSR 参数 / V2Ray·Xray·Trojan 参数 / 其它
分成 6 组。分组行用普通 `<tr class="ss-group">` 而非 `<thead>`（一张表多个 `thead` 不合法，
且用 `tr` 完全不影响现有行与 `update_visibility` 里那批 `showhide` 的引用）；
空组由 `update_group_headers()` 自动隐藏，不会留下孤立表头。

---

## 更新源

* 插件自动更新指向本分支 [guijianchou/v2ray_bin_lite](https://github.com/guijianchou/v2ray_bin_lite)；
* 二进制（xray / hysteria / naive 等）沿用上游 [cary-sas/v2ray_bin](https://github.com/cary-sas/v2ray_bin)。

---

## 开发说明

### 仓库结构

```
shadowsocks/            插件本体（打包进离线包的就是这个目录）
  ss/ssconfig.sh        主脚本：规则下发、DNS、进程管理
  ss/cru/udp.sh         UDP 代理运行时探测（cron ssudpstat 每5分钟 + apply 收尾同步跑一次）
  scripts/              各功能脚本（状态页、规则更新、打包…）
  webs/ res/            网页与静态资源
review_archive/         评审归档与核查工具
v2ray_bin-main/         上游副本，作对照基线（drift.py 依赖）
```

### 打包

`shadowsocks/scripts/ss_pack.sh` 在路由器上跑；本地出包直接
`tar czf shadowsocks-<ver>.tar.gz shadowsocks`。
**包内顶层目录名必须是 `shadowsocks/`** —— `install.sh` 按 `/tmp/shadowsocks/...` 取文件，
外层文件名可以随意，这个名字不能改。

Windows 自带 bsdtar 可能把文件/目录写成 `0666/0777`；发布包还必须核对 Unix 权限，至少保证
目录、`install.sh`、`uninstall.sh`、`scripts/*.sh`、`ss/*.sh` 为 `0755`，普通资源为 `0644`。
打包前应拒绝 `shadowsocks/ss/` 直属的运行时 JSON，而不是使用 `ss/*.json` 通配排除 ——
后者会连必需的 `shadowsocks/ss/rules/cdns.json` 一起删掉。

### 行尾必须是 LF

仓库里的脚本要在路由器的 busybox ash 下执行，一旦被写成 CRLF，
`#!/bin/sh\r` 会变成坏解释器，且每条命令都带一个尾随 `\r`，插件会**静默失效**。
仓库已设 `core.autocrlf=false`，并用 `.gitattributes` 强制 LF（后者随仓库走，
不受 clone 者本机配置影响）。改动脚本后请确认行尾。

### 核查工具（`review_archive/`）

改完代码建议依次重跑：

| 脚本 | 作用 |
|---|---|
| `drift.py` | 三方对比（上游 4.38.3 / 基线 / 当前）函数、自建链、内置链钩子、ipset、dbus 键、cron、命令行分支、网页保存键、文件清单，分清"哪些偏移是历史升级带来的、哪些是本次改动带来的" |
| `pipeline.py` | 对比 `apply_ss` / `load_nat` / `flush_nat` / `disable_ss` 的调用顺序与关键链内规则次序 |
| `lifecycle.py` | 把"创建的东西"与"清理的东西"配对，找只创建不清理的残留 |
| `jscheck.py` | JS 词法扫描（正确跳过字符串/模板串/正则/注释后检查括号配平），用于 262KB 的 ASP。会先剥掉 `<% %>` 模板标记 |
| `test_udp_probe.sh` | `cru/udp.sh` 判定矩阵的桩测试，22 种组合 |
| `test_dns_legacy_cleanup.sh` | DNS“全部”档下线契约：只清插件命名对象，不扫描或删除用户/第三方 PREROUTING DNAT |
| `hy2_audit.py` | 真实提取生产与测速生成函数，核对 Brutal/BBR/Reno、旧配置迁移、冲突归一及非法 JSON 拒绝 |
| `collect.sh` | 路由器环境信息收集（只读 + 临时链实测，收尾自删，敏感值不落盘） |
| `build_preview.py` | 把真实的 `shadowsocks.css` 内联进预览页，保证界面预览与上机效果不漂移 |
| `rhythm_audit.py` | 节奏审计：摊开每个控件的尺寸来源（种类、行内写死的宽高、宽度离散度、空格/`<br>` 撑排版的残留），改样式前先量化 |
| `css_check.py` | 样式表自检：括号配平、变量是否都声明、**属性选择器的实际命中范围**（连页内脚本与 ss-menu.js 一起搜），并守住「主开关不被接管」这条 |
| `baselines.py` | 三棵对照树的唯一解析口径（上游副本 / git 基线 `005bda5` / 工作树），断言非空 —— 前三个脚本曾因硬编码未入库的快照目录而静默比空树 |
| `consistency.py` | 跨文件一致性核对：重复的常量表、网页文案与后端取值、节点表读/写字段配对 |

`chain-logic.md` 是两条核心链路的逻辑拆解，改动这两条链路前后都应对照它。
`Stage.md` 记录当前进度与待决事项。

---

## 变更记录

### 5.3.0

**Hysteria2 默认改为 Brutal。** 页面新增明确的 `Brutal / BBR / Reno` 模式键，默认 Brutal
并写入官方示例值上行 `100 mbps`、下行 `200 mbps`。Brutal 通过 `bandwidth` 启用，绝不生成
无效的 `congestion.type=brutal`；BBR standard 省略 `bandwidth` 与 `congestion`，避免与核心
默认的 BBR standard 重复。旧的单向带宽及 `bandwidth + congestion` 混合配置仍可加载和保存。
显式模式键是最终意图来源：恢复或部分写入造成 `BBR/Reno + bandwidth` 冲突时，生产启动与
节点测速都会移除冲突字段并按所选模式生成；Brutal 下合法的 `congestion` 仍作为服务端忽略
客户端带宽时的回退。旧 JSON 若只有混淆等非拥塞设置、且还没有独立模式键，会保留历史默认
BBR standard，不会因新版界面默认 Brutal 而改变行为。页面加载对空对象、数组、未知字段、非法 profile 与非法带宽执行完整
schema 校验，损坏配置会锁住保存，避免静默覆盖。生产启动与节点测速共用同一套枚举、带宽
格式、最终 schema 和动态核心版本校验。

**DNS 劫持删除“全部”档。** 页面改为默认 UDP/53 的复选确认框；删除 TCP/53 直 DNAT、
DoT/DoH 拦截链、`ss_doh` 集合、仲裁/fallback 状态及 `strict-order` 国内后备。旧值 `2` 自动迁移
到 `1`；当前版本只清理具备插件命名所有权的旧链/集合，不创建这些对象，也不扫描或猜删
无法区分来源的 PREROUTING DNAT。

**下线 Hysteria2 的透明 UDP。** 经三轮真机取证定位为**内核与 hysteria `udpTProxy` 架构的
结构性冲突**，非配置/构建/服务端问题，在 Merlin AM380 的 2.6.36.4 内核上不可能正确工作。
完整病因、实机证据与三条未来修法见
[Hysteria2 的透明 UDP 为什么在本固件上不可用](#hysteria2-的透明-udp-为什么在本固件上不可用)。

一句话机制：hysteria 只把每个 `(src,dst)` 的首包交给通配监听器，随后建 connected
`IP_TRANSPARENT` socket 并**指望内核接管**后续包；该接管靠 `xt_TPROXY` 的 established 查找，
而 UDP 的那一段 2.6.37 才进主线。于是每包新建一次会话，服务端每包换一个出站源端口，
游戏服务器看到的源端口不停变化，会话永远建不起来。
实测：同一 `(src,dst)` 对 11 秒内 22 次 `newPair`，各自 20 秒后超时关闭；
三次采样平均包长恒为 88.9 B（纯连接尝试），VLESS 对照为 176 B / 7.7 包每秒。

**移除**

* 【Hysteria2设定】里的 **UDP 开关**（`ss_basic_hy2_udp`）与**日志级别**（`ss_basic_hy2_log_level`）
* `/tmp/hysteria.log` 及其全部解析（`hy2_log_level` / `hy2_log_strip` / 服务端 `udpEnabled` 判定）
* 运行时结论 `ss_runtime_hy2_server_udp`、`ss_runtime_hy2_udp_unsupported`
* `start_hy2` 里"启动失败 → 剥掉 `udpTProxy` 重试 → 落库不支持"的整条自愈分支
* 「系统状态」里的【hysteria 运行日志】与两段 hy2 UDP 能力输出

**行为变化**

* `udp_tproxy_supported` 不再把 Hysteria2 算作支持，新降级原因 `hy2_udp_kernel`
  → `degraded_node`，探针给 `unsupported`（黄灯，不是红灯）
* `create_hy2_json` 不再生成 `udpTProxy`；`hy2_validate_final_json` **主动拒绝**该键，
  防止用户从【Hysteria2设定】的自定义 JSON 把它塞回来
* 界面：hy2 节点下「同步UDP与TCP」锁定【关闭】并置灰，旁注写明内核原因
* 安装 / 配置恢复 / 卸载三处都会清理两个历史 dbus 键

**界面**

* **节点添加/编辑浮层适配可视区**：浮层限制在浏览器可视区内并由自身纵向滚动，
  不再被主面板裁切；小屏下滚动到底即可操作「返回」与「添加」。
* **收紧 V2Ray JSON 编辑器高度**：节点浮层与主界面的「使用JSON配置」编辑器均缩为
  12 行（约 210px），长配置在文本框内滚动且仍可纵向调整，保存/应用按钮保持可达。
* **修复 Chrome 下顶部页签栏被主面板遮死**（iOS Safari 一直正常）。成因在
  `ss-menu.js` 的 `browser_compatibility1()`：它按 UA 给 `#FormTitle` 挂
  `.FormTitle_chrome56` / `.FormTitle_firefox`，而这两个类带 `margin-top:-100px`
  —— 主面板被上提 100px，正好压在紧邻其上的 `#tabMenu` 上。上游那套半透明配色下
  页签还能透出来，本主题给 `#FormTitle` 上了不透明底色与阴影之后就彻底看不见了。
  iOS Safari 的 UA 里没有 `Chrome`（Chrome for iOS 是 `CriOS`），三条分支一条都不命中，
  保持 HTML 写死的 `class="FormTitle"` —— 也就是说 **Safari 那份才是正确布局**。
  现在让所有浏览器都走这条路：`browser_compatibility1()` 只把 `#FormTitle` 归一到
  `.FormTitle` 并清掉行内偏移；两个变体类保留但负边距归零（兜住浏览器缓存里的旧 JS）；
  `#tabMenu` 另给 `position:relative; z-index:2` 作为最后一道保险。
  顺带去掉 Firefox 分支那句 `height="975px"` —— 当时 `#FormTitle` 还有 `overflow:hidden`
  用于圆角裁切，固定高度会直接裁掉超出内容，而这几页高度随标签页变化很大。
* 「访问控制」页的**主机IP地址**控件改为与同行「访问控制」下拉框一致的单控件外观：
  等宽 160px、等高、左边距一致，设备列表箭头内嵌到输入框右端，
  不再是「输入框 + 5px 间隙 + 独立方钮」的两件套（原总宽 174px，与邻居对不齐）

**导航**

* 顶部页签由四个收敛为两个：**Shadowsocks 设置**、**Xray本地聚合**。
  移除「负载均衡设置」与「Socks5设置」两个过时入口（`menu_hook()` 的
  `tabtitle`/`tablink`）。底层 `.asp` 与后端代码原样保留在包内，未做任何删除。

**保留**（5.2.9-beta1 引入，与节点类型无关且已实测有效）

* 探针的**增量判据**（`ss_runtime_udp_probe_game_prev{,_t}`）：累计值一旦 >0 就永久粘住，
  停滞流会被误报成"有流量"
* 「系统状态」页打开时**现场重新采样**探针，不再并排展示"实时计数"与"5 分钟前的结论"

**未改动**：UDP TPROXY / 策略路由及 Xray 数据面；iptables 的变化仅限删除 DNS“全部”档并
保留一次性升级清理。

### 5.2.9-beta1

专修 Hysteria2 UDP 链路的可观测性。**未改动任何 iptables / TPROXY / 策略路由代码**，
Xray（VLESS）路径逐字未动 —— 所有 hy2 相关改动都在
`ss_basic_type==4 && ss_basic_trojan_binary==Hysteria2` 的门控之内。

* **hysteria 运行日志**（`ssconfig.sh` `hy2_spawn`）：由 `-l error >/dev/null 2>&1`
  改为 `-l <级别> >>/tmp/hysteria.log 2>&1`，默认级别 `info`。
  选 `info` 而非 `warn` 的理由：`connected to server ... udpEnabled=` 是 Info 级，
  而它是判断「服务端到底给不给 UDP」的**唯一**依据；hysteria 的 Info 是一次性的
  （启动几行 + 每次握手一行），per-connection 日志都在 Debug，量可忽略。
  新增【Hysteria2设定 → 日志级别】下拉（`ss_basic_hy2_log_level`，默认 `info`）。
* **日志级别必须白名单**：非法级别会让 hysteria 打印 `unsupported log level` 后
  `os.Exit(1)`（`app/cmd/root.go:141`）。若把 dbus 值直接透传，一个打错的日志档位就会
  被 `start_hy2` 的自愈分支误判成「这份构建不接受 udpTProxy」并**永久落库**
  `ss_runtime_hy2_udp_unsupported=1`，让 UDP 瘸掉。`hy2_log_level()` 兜住并回落 `info`。
* **启动失败时打出真实原因**：旧版把 stderr 丢进 `/dev/null`，导致「剥掉 udpTProxy 再试」
  这个结论无从证伪（第一次失败也可能是端口占用、别的键不认、内存不足）。现在重试之前
  先把日志末尾 12 行打进插件日志。该结论仍是启发式的，不一致时以日志为准。
* **新增「服务端 UDP 能力」判定**（`cru/udp.sh`）：这是此前**整个缺失**的一层。
  旧代码只有一个 hy2 UDP 降级概念 —— `ss_runtime_hy2_udp_unsupported`
  =「本机这份**构建**不认 udpTProxy」，没有任何一处表达「对端**服务端**在握手里
  声明 `UDPEnabled=false`」。后者的现象是包正常走到 TPROXY、正常进 hysteria，
  然后被 `HyClient.UDP()` 拒掉（`core/client/client.go:226` 返回
  `DialError{"UDP not enabled"}`），**iptables 计数全部正常而游戏完全不通**。
  新增运行时键 `ss_runtime_hy2_server_udp`，从日志里取 `udpEnabled=` 或
  `UDP not enabled` 两条判据之一，命中 `0` 时 probe 报 `unsupported`（黄灯，不是红灯 ——
  链路没坏，是对端不提供该能力）并给出「换节点或联系服务商」的处置。
  判不出来一律留空按「支持」继续，绝不猜（`lazy=1` 默认值下要等第一个请求才握手）。
* **探针改用增量判据**（`cru/udp.sh`）：`GAME_PKTS` / `TP_PKTS` 是**自建链以来的累计值**，
  一旦大于 0 就永久粘住 —— 游戏关了、隧道断了、UDP 全程被拒，状态栏照样显示「已有流量」。
  真机上这正好掩盖了故障：HY2 四分钟 114 包（0.42 包/秒）与 VLESS 3281 包（12 包/秒）
  相差 29 倍，形态是「发出去没人回、游戏在退避重试」，但两者在旧判据下都只是 `>0`。
  现在判活跃看**两次采样之间的增量**：有新增 → `flow`；累计 >0 但一个周期零新增 →
  `ok` 并明说「若游戏正在运行，说明 UDP 只出不回」。已处理计数器归零（apply 后）
  与快速重采样（连点详细状态页）两个边界，不会误报。
* **「经代理」这个词收紧**：Game hook 命中只证明目的端口对上了，之后还要过
  white_list / chnroute / ACL 三道分流才轮得到 TPROXY。旧文案一律报「已有流量经代理」，
  比实际测到的强。现在 TPROXY 计数为 0 时改报 `warn`，并指出目标多半在白名单或
  chnroute 国内段，给出加黑名单的处置。
* **详细状态页改为现场采样**（`ss_proc_status.sh`）：打印 UDP 段之前同步跑一次
  `cru/udp.sh`。这修掉了本页最容易骗人的地方 —— 原来它读 5 分钟前的 probe 缓存，
  却在同一页现场执行 `iptables -nvL` 打实时计数，把两个采样点并排展示成矛盾，
  一个纯显示问题掩盖了真故障。同时新增【hysteria 运行日志】段：过滤出全部 UDP 相关行
  并附判读表（`udpEnabled=false` → 服务端无解；`=true` 且无 error → 继续往服务端出口查）。
* **跨会话污染防护**：`start_hy2` 每次启动前清空 `/tmp/hysteria.log` 并清掉
  `ss_runtime_hy2_server_udp`。否则换节点后旧日志里的 `UDP not enabled` 会被 grep 到，
  把新节点误判成服务端不给 UDP。日志封顶 256KB 由 `cru/udp.sh` 每 5 分钟检查
  （`/tmp` 是 tmpfs，吃的是内存），且**在读取判据之后**才轮转。

### 5.2.9

* **全局设置宽度**：“选择中国DNS”“DNS劫持”“节点域名解析DNS服务器”和“同步UDP与TCP”
  四个选择框统一由 `300px` 增加到 `330px`（+10%）。
* **附加功能宽度**：“替换为dnsmasq-fastlookup”选择框由 `370px` 增加到 `444px`（+20%）。
* **响应式约束**：保留原有窄屏 `max-width` 限制；页面结构、配置键、事件处理和运行逻辑不变。
* **版本与发布审计**：插件内部版本更新为 `5.2.9`；页面 JavaScript、配置一致性、Hysteria2
  专项审计 76/76、差异格式及离线包 95 条内容/权限核对通过。

### 5.2.8-beta6

* **Hysteria2 校验修复**：生产启动与节点 webtest 不再调用随包旧 jq 不支持的 `keys_unsorted`、`floor` 和正则 `test()`；合法的混淆、拥塞控制及带宽设定不会再被统一误判并触发自动关闭。
* **配置契约**：保留官方 `fastOpen`、`lazy`、`udpTProxy`、`congestion`、`bandwidth` 字段结构；UDP 开关关闭时仅给出 TCP 降级提示，不属于配置错误。混淆密码按官方约束在前端、后端和 webtest 统一要求至少 4 字节。
* **运行状态布局**：“详细状态”移动到“分流检测”右侧，两按钮水平齐平；按钮组中线对齐“国外连接 / 国内连接”两行的中线，事件处理函数不变。
* **发布审计**：Hysteria2 专项审计 76/76 通过；相关 Shell 文件语法、差异空白检查、归档路径、Unix 权限、内部版本及包内逐文件内容均已核对。

### 5.2.8-beta5

本版只调整四类指定控件的尺寸；不改按钮处理函数、配置键、代理、DNS、路由或 Hysteria2 逻辑。

* **运行状态按钮**：“分流检测”和“详细状态”收紧为约 62×25px，保留 5px 间距、禁止换行；四个汉字的实际 `scrollWidth` 未超过可用宽度。原有 `pop_111(3)` 与 `get_proc_status(3)` 事件不变。
* **编辑框高度**：自定义 dnsmasq 从当前真机尺寸缩小 25% 到 139px；域名白名单和域名黑名单缩小 25% 到 93px。三个控件宽度不变，IP/CIDR 白名单和黑名单不受影响。
* **附加功能宽度**：`替换为dnsmasq-fastlookup` 从 336px 增加到 370px（约 +10.1%）；窄屏继续由 `max-width` 限制，不突破控件区域。
* **实机状态复核**：所附 VLESS + QUIC/Game 详细状态未显示故障或降级；Xray、dns2socks、dnsmasq 均运行，UDP 状态为 `quic_game`、探测为 `ok`，UDP/443 已命中 TPROXY。Game 端口计数为零只表示采样时未观察到对应流量；`UDP/53监听=[]` 更像旧版 `netstat` 的诊断盲点，可用 `/proc/net/udp{,6}` 与一次 `nslookup` 复核。
* **发布审计**：相对 beta4 的包内源码只有 `shadowsocks.css` 变化；页面 JavaScript、Shell 语法、CSS 布局漂移、配置一致性、生命周期及目标 DOM 尺寸检查通过。归档共 95 条，路径、Unix 权限、内部版本和逐文件内容均已核对。

### 5.2.8-beta4

本版修正 beta3 实机截图确认的 UI/UX 回归，并补齐应用前的 HY2 服务器地址校验；不改配置键、
配置生成、代理、DNS 或路由逻辑。

* **彻底清除灰色条**：真机固件 `form_style.css` 会给 `.FormTable td span` 强制设置 `#475A5F` 背景和黄色文字；beta3 只清了外层，所以无效。本版定向清除运行状态与 HY2 内层 `span` 背景，父层明确恢复插件原面板色 `#4D595D`，并恢复 HY2 普通标签色；真实下拉框和输入框底色不变。
* **状态展示去胶囊**：状态值不再保留胶囊的 padding、圆角、背景、边框和阴影，只显示原有语义色文字及圆点；没有增加、删除或拆分状态项目。
* **详细状态浮层**：旧版沿用上游 `width:980px`、`margin-left:-215px`，与新版 `#FormTitle overflow:hidden` 冲突，导致左侧 215px 被裁掉。本版把浮层限制在主面板左右 8px 内，标题、说明和日志首列完整显示，长 iptables 行使用横向滚动。
* **状态按钮**：分流检测和详细状态改为稳定的纵向按钮组，字号与 padding 收紧，按钮间保留 5px 间距；原有 `pop_111(3)`、`get_proc_status(3)` 处理函数不变。
* **HY2 地址校验**：应用配置和节点测速都会拒绝非法服务器地址，仅接受合法域名、IPv4 或方括号 IPv6；前端校验同时去除服务器与端口两侧空白，避免浏览器校验通过而后端因空白拒绝。
* **本地验证**：模拟固件 `span` 规则后，状态与 HY2 子项计算背景均透明、父层为 `#4D595D`、控件仍为 `#576D73`；769px 与宽屏下详细状态均未越界，横向/纵向滚动和返回关闭通过。地址校验在前端及两个 Shell 路径各通过 41 组正反例；页面 JavaScript、CSS 布局漂移、目标断言及 `git diff --check` 通过。

### 5.2.8-beta3

本版只修 beta2 实机截图确认的三项 UI/UX，不改配置键、配置生成、代理、DNS 或路由逻辑。

* **运行状态去背景**：国外链接、国内链接、UDP 代理和 DNS 劫持的状态徽标取消装饰背景与边框，只保留原有绿、黄、红、灰文字及圆点语义，不增加或拆分任何状态行。
* **Hysteria2 设置区去背景**：容器、所有子行及 hover 背景改为透明，分隔线和左对齐排版保留；真实下拉框、输入框仍使用主体控件底色。
* **长文本框尺寸**：`自定义dnsmasq` 与四个黑白名单文本框的桌面宽度由控件列的 60% 扩到 72%；可见行数分别由 12 行缩到 8 行、由 7 行缩到 5 行。600px 以下仍恢复 100% 宽度。
* **本地验证**：生产 DOM 计算样式确认两类装饰背景与边框透明、真实表单控件底色未丢失；桌面像素截图和 429px 窄屏控件布局已检查，目标 CSS/DOM 断言、页面 JavaScript 语法与 `git diff --check` 通过。

### 5.2.8-beta2

本版只修 beta1 实机反馈的 UI/UX，不改任何配置键、配置生成、代理、DNS 或路由逻辑。

* **运行状态配色**：修正后置规则把国外链接、国内链接、UDP 代理和 DNS 劫持徽标压成深灰色的问题；五种状态继续保留绿、黄、红、灰的文字和圆点语义，背景与边框统一使用主体控件蓝灰色。
* **Hysteria2 设置区配色**：容器和每个子行明确使用主体面板色，标题与附属标签使用普通设置项的标签色；下拉框和输入框继续使用主体控件色，避免透明背景叠加父级悬停色后产生割裂。
* **附加功能宽度**：`替换为dnsmasq-fastlookup` 选择框由最长选项自然撑开的约 424px 收到 336px，窄屏仍受单元格宽度约束。
* **长文本框宽度**：`自定义dnsmasq`、IP/CIDR 白名单、域名白名单、IP/CIDR 黑名单和域名黑名单在桌面统一为控件列的 60%（实测约 349px，原约 576px）；600px 以下恢复 100%，高度和可见行数不变。
* **本地验证**：上述选择器只命中指定控件；桌面与 429px 窄屏均无整页横向溢出，HY2 宽内容只在自身区域滚动，`git diff --check` 与目标 CSS 断言通过。

### 5.2.8-beta1

本次发布只增强 Hysteria2 配置路径并修正指定 UI/UX；没有改动其它协议、DNS 或路由规则。

* **Hysteria2 开关**：UDP 从复选框改为「关闭 / 打开」选择框，并在其下新增 `fastOpen`、`lazy` 选择框。两项默认打开，与旧版生成器固定写入 `true` 的行为兼容；安装和配置恢复会为旧配置补齐 `0 / 1 / 1` 默认值。
* **应用前校验**：保存前检查服务器、认证密码、单端口及 `443,20000-50000` 这类端口跳跃；前后端共同校验三个开关、带宽、混淆、Gecko 包大小、拥塞控制和 BBR 模式。生产配置与节点测速都改用 `jq` 结构化生成 JSON，最终 schema 校验通过后才替换正式配置或启动核心。
* **版本门槛**：`congestion` 要求 Hysteria `v2.8.1+`，`gecko` 要求 `v2.9.2+`；核心版本不满足时明确拒绝应用。随包 Hysteria 二进制保持不变，与 `v2ray_bin-main` 中的参考文件 SHA256 相同。
* **Hysteria2设定排版**：标题由「Hysteria2 全局设定」改为「Hysteria2设定」；混淆、密码、包大小、拥塞控制、带宽、UDP、`fastOpen`、`lazy` 使用统一的左对齐标题列、透明背景和分隔线。拥塞控制与 BBR 模式保持同组同一行，UDP 说明精简为 `启用透明 UDP 代理，为「同步UDP与TCP」支持`。
* **全局设置尺寸**：中国 DNS、DNS 劫持、节点域名解析 DNS 与同步 UDP/TCP 的选择框统一为 300px；外国 DNS 保持 200px、参数输入框保持 160px，并排显示。窄屏下 HY2 和访问控制使用局部横向滚动，避免撑宽整页。
* **访问控制**：主机 IP 输入框与设备下拉触发器组成一个控件，不再互相覆盖；保留固件依赖的 `img#pull_arrow` 接口，并用主题蓝灰色包装箭头按钮，与主机别名和访问控制列对齐。
* **运行状态配色**：国外链接、国内链接、UDP 代理和 DNS 劫持继续使用原有状态行，只统一徽标背景与边框为主体蓝灰色；绿、黄、红、灰仍表示原有状态语义，没有增加「未启用状态」或其它展示行。
* **本地验证**：Shell 与 JavaScript 语法、差异格式、开关和端口正反例、HY2 全局/最终 schema，以及桌面与窄屏生产 DOM 布局均已检查；最终视觉与 Hysteria 实际运行效果以本轮路由器实机测试为准。

### 5.2.6-beta18

主界面现在能一眼分清**「UDP 正在加速」/「这个节点不支持 UDP 加速」/「环境故障」**三件事。

此前 7 种降级原因一律标红，但它们是两类完全不同的东西：

| 原因 | 本质 | 该做什么 | 现在 |
|---|---|---|---|
| hy2 的 UDP 开关为关闭 | 配置 | 设为打开 | 黄 · 节点不支持UDP加速 |
| hy2 构建不认 udpTProxy | 能力 | 换构建 | 黄 · 传输层不支持UDP |
| naive/anytls 没配透明UDP入站 | 能力 | 换协议 | 黄 · 节点不支持UDP加速 |
| SIP003 simple-obfs 无UDP通路 | 能力 | 换节点 | 黄 · 传输层不支持UDP |
| 内核不接受TPROXY / fwmark 被占 / 路由表310被占 | **故障** | 排查环境 | **红 · 内核/环境故障** |

前四种链路本身是好的 —— 标红会让人以为插件坏了，实际换个节点或勾个开关就解决。
降级说明文字的颜色也跟着严重度走，不再一律红。
「系统状态」页补全了 probe 七种取值的含义（原先只解释了 pass）。

另：「Game端口未命中」的文案改准确了。真机反馈 ASA 这类用 EOS/Steam 中继的游戏是
**随机开一堆端口转发到服务端**，固定的 `multiport` 列表永远抓不住 —— 那不是"填错"，
是端口匹配这个方法对它不适用。正确出路是按**目的地**匹配：
把服务器 IP/域名加进【黑名单】，黑名单目标的 UDP **不限端口**一律走代理，
且在「仅代理QUIC」档就生效，不必开全量UDP 抬高整机负载。提示里已写明这条。

### 5.2.6-beta17

拿**真机实测输出**当基准，核对探测代码与文档断言是否对得上真实格式。查出两个真缺陷、
一条新判据、五处文档错误 —— 全部是"按命令行写法去 grep 内核渲染结果"这一类。

**代码缺陷**

* **table310 冲突检测认不出自己下发的路由**：下发的是 `ip route add local 0.0.0.0/0 dev lo`，
  而 iproute2 规范化后输出 `local default dev lo  scope host`，原先 grep 的是命令行字面量，
  **必然 MISS** → 只要上次的路由残留就被判成"被其它组件占用" → `mangle=""` 静默降级，
  状态栏还给出完全错误的归因。同段的 fwmark 判据当初就按渲染形写对了，唯独这条没有；
* **计数超过 10 万会被 `iptables -nvL` 缩写成 `198K`**，`awk '{s+=$1}'` 读成 105 会**少报千倍**。
  真机的 `Chain PREROUTING (policy ACCEPT 198K packets, 103M bytes)` 就是现成例子。
  三处计数统一改用 `-x`，并保留 K/M/G 后缀兜底。

**新判据：Game 端口疑似填错**

真机开游戏前后对比给出决定性证据：Game 端口 hook `0 → 2` 包，而
`SHADOWSOCKS_FWD` 的**链尾 RETURN** `0 → 75 包 / 42KB`。链尾 RETURN 只可能是
**境外的非 443 UDP** —— 就是游戏流量本身，它绕过了 Game 端口 hook 被直接放行直连。
即：端口填错时游戏 UDP 从来没进过代理，而插件一个字都不提示（档位照常、状态栏因 QUIC 有流量还是绿灯）。
现在这种组合会报黄色警示并直接给出查真实端口的命令。三条边界均有桩测试。

**文档错误**（详见提交记录）：asp 注释里的 dbconf 前缀与代码矛盾（照它改会让 DNS 行永久"未知"）、
三层图的 `0.0.0.0:3333` 与真机及 README 自身矛盾、`0x07` 的内核渲染形与缺省掩码从未说明、
§2.0 行号基准未标注、`ss_runtime_udp_state` 枚举漏了 3 种取值。

**同时确认（真机证据）**：UDP 代理链路**一直在正常工作** ——
40 个境外 QUIC 包进链、39 个真的被 TPROXY 到 3333；`xt_TPROXY` 模块 9 个引用；
xray 的 `in-tproxy` 入站形态与文档声称的完全一致。此前的"未就绪"红灯是纯粹的探测器误报。

### 5.2.6-beta16

对 beta14/15 声称已修的 9 个问题做了一轮**独立证伪核查**（8 个核查员各负责一条，
立场设为"没修好"，要求逐行证据）。结果：3 条真修好、**5 条只修了一半或修错了地方**。
本版把这 5 条补齐。

* **问题2 修出了新 bug**：只留「节点」一个分组标题后，`update_group_headers()`
  会把这唯一的标题也隐藏掉 —— 它挂在 `update_visibility()` 上，而后者的 12 个调用点
  **全都发生在「账号设置」已隐藏时**，那一刻组内所有行的 `offsetParent` 都是 null，
  于是被判成空组；切回来又没有任何代码重算，标题永久消失。函数与调用一并删除；
* **问题8「按钮没对齐」修的是错的地方**：上一版加的 `.show-btn3_1/_2` 规则是**死代码**
  （这两个 class 本分支零引用），注释里"变体漏收"的根因是没核实就写的。
  用户点名的是【开关行】：移除「检查并更新」后，同格的版本号(170px) 与「插件帮助」(270px)
  仍是绝对定位 + 按旧宽度算的硬编码偏移，70px 处还留了个洞。已改 markup 收回文档流；
* **问题3 后半参照物选错**：拉齐的那两个下拉框隔着一屏、不会同屏；而「DNS劫持」真正的
  上下邻居没有行内 margin，被我加宽后左右边缘落差反而更大。已按真实邻居重做，
  并补齐 hy2 块内三个下拉框的宽度归一与两个条件子项的间距；
* **问题1/5 有残留**：`.content_status` 少补了 `margin-left:-215px`（详细状态弹窗右移出屏）；
  访问控制那格里 `#pull_arrow` 的 `align="right"` 仍是浮动、`#ClientList_Block`
  的 `margin-top:25px` 是按旧的浮动布局标定的。均已修。

**核查工具本身也有盲区**：`css_layout_drift.py` 的属性白名单原先不含 `margin-*`/`padding-*`，
所以上面那条 `margin-left` 的丢失被静默放行，我据此写下了"全部补回"——
假信心比没有工具更糟。现已计入，并顺带查出 `.FormTitle_chrome56/_firefox`
丢失的 `margin-top:-100px`（`ss-menu.js` 按 UA 挂这两个 class，是活代码，丢了主表单下移 100px）。

另：真机 `/proc/net/udp6` 输出确认**问题6/7 是探测器误报** ——
核心一直监听在 `[::]:3333`（双栈，同时收 IPv4），而 busybox 的 `netstat -unl` 没报出来。
beta15 改用 `/proc/net/udp{,6}` 的判据已用该真机数据正反验证通过。

### 5.2.6-beta15

补齐 beta14 漏掉的两条（都是我上一轮自查不严）：

* **问题9 只做了一半**：只改了软件中心列表名与菜单页签，页面上实际看到的标题
  （浏览器标签、页面顶部大标题、主开关标签、详细状态弹窗、4 处错误弹窗、
  6 处加载遮罩）全都还是「科学上网」。判据应是**产品名 vs 普通名词** ——
  作为产品名用的改，"…多协议客户端的科学上网工具""此模式非科学上网方式"
  这类普通名词用法保留（共 4 处）；
* **问题3 后半（DNS劫持选框没对齐）此前根本没修**：两个档位下拉框行内都是
  `width:auto`，各按最长选项文案撑开，「全部（强制TCP/UDP-53+拦DoT/DoH，
  白名单可靠）」比「仅代理QUIC+Game（QUIC+自定义UDP端口）」长一截，
  右边缘就错开。改为共同宽度。

### 5.2.6-beta14

真机反馈的界面问题修复。**其中五个是同一个根因**：`res/shadowsocks.css` 是整份重写的，
重写时只保留了上游同名选择器的装饰性声明，把 `display` / `position` / `top` / `width`
这些**功能性**声明丢了 —— 样式表里的 `display:none` 是行为不是装饰，丢掉它等价于删掉一行 JS。

* **节点对话框漂浮在「账号设置」里**：`.contentM_qis` 丢了 `display:none` + `position:absolute`。
  `.content_status`（详细状态弹窗）同样受影响。已全部补回；
* **多行输入框右侧无间距**：`textarea` 不在 `box-sizing:border-box` 名单里，
  行内 `width:99%` 加 padding 必然溢出；
* **访问控制的「主机ip地址」错位**：它用 `.input_15_table`，不在控件样式名单里，
  走的是浏览器默认渲染，还带行内 `float:left`；
* **状态栏四种芯片全渲染成黄色**：五行状态包在 `<a class="hintstyle">` 里，
  固件对该类有配色规则而芯片规则没写 `!important`，被盖掉 ——
  「异常」和「链路就绪」看起来一模一样，状态栏等于失效；
* **主界面按钮不对齐**：`.show-btn3_1/_2` 从未被药丸样式收录；右侧两个按钮用
  `position:absolute` + 硬编码像素偏移定位，按钮改成药丸后宽度变了就对不上；
* 新增 `review_archive/css_layout_drift.py` 防复发：对比上游与当前的同名选择器，
  列出缺失的布局属性，有意偏离走白名单。现输出为零。

其余：

* 「账号设置」只保留「节点」一个分组标题，其余 5 个移除；
* 「Hysteria2设定」从 `<span width:70px>` + `<br>` 的伪两栏改为真 CSS grid ——
  固定宽度只能对齐标签，标签之后各行控件宽度不同，附属文字纵向必然错开。底部说明文字移除；
* 软件中心与菜单里的显示名改为 **Shadowsocks**（日志文案不动）；
* **UDP/3333 监听检测改用 `/proc/net/udp`**：真机上 hy2 与 xray 两个独立核心
  被判成同一个错误，指向探测手段本身 —— busybox 的 `netstat -l` 对无连接的 UDP
  语义依编译而异，且 `2>/dev/null` 会把 "applet not found" 一并吞掉。
  改用内核直出的 `/proc/net/udp`（3333 = `0x0D05`），netstat 降为次选。
  **这只解决探测层面**；若 `/proc/net/udp` 里确实没有 `:0D05`，那是另一个问题。

### 5.2.6-beta13

为真机验证准备的一版，无功能改动。

* **诊断输出补全**：`ss_runtime_hy2_udp_unsupported` 此前只存在于 dbus，
  「系统状态」页看不到 —— 而它正是判断「开机路径为什么不下发 UDP 规则」的唯一证据，
  缺了它 beta11 那条 hy2 修复在真机上没法验证。现已补上，并说明该结论的来源与清除方式。
  运行时状态键的诊断覆盖率由 10/11 变为 **11/11**；
* `consistency.py` 增加第四项核对：**后端 `dbus set` 的每个 `ss_runtime_*` 键，
  「系统状态」页都必须取得到**。写了不显示等于真机排查时是黑箱，
  而这类缺口不会有任何报错。已验证移除该键后核对脚本会报错；
* README 新增**真机验证清单**：按风险排序的 6 项，每项给出造条件的方法、
  看哪里、什么算过、以及不过时的具体后果。

### 5.2.6-beta12

界面：**节奏与密度**。只动样式层（`res/shadowsocks.css`），ASP 结构与 JS 一律未碰。
数值不是凭观感调的 —— 先用新增的 `review_archive/rhythm_audit.py` 把界面上每个控件的
尺寸来源摊开，再针对量出来的问题改。前后对照预览（用真实样式表渲染，不会漂移）：
<https://claude.ai/code/artifact/5aed0e48-dd22-4fc2-8195-cd6622e61233>

* **宽度阶梯**：行内 `style` 里共 32 种宽度，真正伤观感的是"差一点点"的近邻值 ——
  `342px`×19 与 `350px`×17 差 8px（主输入列 36 个控件）、`160px`×10 与 `164px`×17 差 4px、
  `60/61/65/66/70px` 一片（38 处，多数由 JS 生成）。近似而不相等让同列右边缘参差，
  读起来像没对齐，比明显不同更糟。收敛成 `--w-xs/sm/md/lg/xl` 五级，
  用属性选择器就地归一（与收敛配色同一套办法）。**只归并近邻值**，
  `120~200px` 那些一次性宽度保持原样 —— 它们是按内容选的，强行拉齐反而错；
* **垂直节奏**：标签列 `10px` / 控件列 `8px` 的内边距统一到 `--sp-2`，两列节奏对齐；
  新增 `--ss-ctl-h` 控件高度，按钮与并排的输入框共用同一条中线；
* **复选框**：14 个 `input[type=checkbox]` 此前完全没样式，是浏览器默认的约 13px，
  基线比旁边 29px 的控件矮一截。现给 `accent-color` 与尺寸 ——
  **排除 `class="switch"`**，主开关是 `display:none` 由固件 `jquery.iphone-switch.js`
  接管渲染，碰它会把开关弄坏；
* **节点列表单独收一档密度**（垂直 6px、行高 1.45、行内按钮 24px）：
  那张表是要"扫"而不是"读"的，设置表那套间距在这里偏松，行数一多就要滚动，
  而滚动会打断比较。按钮同时降档，否则控件会把行重新撑开、密度白收。

新增 `review_archive/css_check.py`：括号配平、变量是否都声明过、
以及**属性选择器的实际命中范围** —— `[style*="…"]` 写错不会报错，只会静默失效。

> 这个检查的第一版自己就错了：只搜剥掉 `<script>` 之后的 `style` 属性，
> 把 JS 运行时拼进 DOM 的那批颜色全判成失效（15 条假阳性）。
> 改成连页内脚本与 `ss-menu.js` 一起搜之后，查出 **7 个真死的选择器**：
> 3 个上游遗留的小写变体（`#fc0` / `#ff0000` / `#00ffe4`，全项目 0 处），
> 4 个我这轮误加的 `width:85/95/97/98px` —— 审计时把 `width:99%` 这类百分比当成了 px。
> 已全部删除，配色收敛覆盖率不变（15 种仍全部收敛）。

**描述**：清掉与实际维护范围不符的协议清单。README「支持的协议」原本列了
SSR / NaiveProxy / AnyTLS，而同一篇里的「与上游的界面差异」早已写明前两者的
「添加节点」入口被移除，前后矛盾；主界面顶部的红字提示与协议清单同样清理
（`xray/trojan/naiveproxy/hysteria2/anytls` → `xray/trojan/hysteria2`，移除 AnyTLS 链接）。
核实时确认一处与原设想不同：**AnyTLS 仍可新建** —— 它没有独立协议入口，
但走「添加节点 → Trojan → 二进制选 AnyTLS」，当前与上游的下拉都是四项。
按决定：入口保留，只从描述里拿掉。纯描述改动，未动任何功能。

### 5.2.6-beta11

本轮做了一次以上游 `v2ray_bin-main` 为框架基线的**全面复查**（8 条独立评审线并行，
每条高危发现再由独立 agent 做对抗性复核，最后一轮完整性评审找遗漏）。
框架层确认零偏移，但查出 **8 个真缺陷**，其中 3 个是本项目 5.2.5/5.2.6 引入的回归。

**先修的三条回归（都能让用户明确选择的设置失效）**

* **ACL 主机的 UDP 在档位=关闭时仍被代理**（5.2.5 引入）。
  修「同步UDP与TCP 对 ACL 主机空转」时只保留了 `mangle == 1` 一道守卫，
  而 mangle 可能仅因「存在游戏模式 ACL 主机」而置位 —— 此时用户的档位其实是【关闭】。
  结果：链尾兜底有档位守卫、【剩余主机】正确直连，但 ACL 列表里设成「全局模式」的主机
  其 UDP 被全量塞进透明代理。同一台路由器上两类主机表现相反，无法归因。
  现补上与链尾兜底同款的档位判据；不满足时恢复上游语义整机 `RETURN`。
* **「全部」档回退时，加密DNS 从「走代理」变成「明文直连」**（5.2.5 引入）。
  `dns_force_bypass` 放行 853/DoH-443 与 `SHADOWSOCKS_DNSF` 的拦截本是一对，
  回退路径只拆了后者、没撤前者。于是发往那 19 个已知解析器的 DoT/DoH
  既不进代理也不被拦，直接明文出境 —— 比从没开过该档更差，
  与回退分支注释里「保证至少不比原版差」正好相反。新增 `clean_dns_bypass()`。
* **hy2 的降级结论只在内存里，jq 却把配置文件永久改了**（beta9 引入）。
  自愈分支剥离 `udpTProxy` 是**持久**的（写回磁盘），结论却是**易失**的。
  下次开机走 `WAN_ACTION` 路径不重新生成配置 → hysteria 一次就起来 →
  自愈分支不执行 → 判定「支持」→ 把 UDP 规则下发到一个只监听 TCP/3333 的核心上。
  `xt_TPROXY` 查不到 socket 直接丢包：Game 端口 UDP 整段黑洞，
  而日志一路「启动成功」。**这正是那套自愈本想避免的黑洞。**
  现把结论落库为 `ss_runtime_hy2_udp_unsupported`，能力判定读它；
  手动点【应用】视为「再试一次」自动清除，开机路径则沿用结论不再白试。
  顺带让 `create_hy2_json` 里那个 `HY2_UDP_UNSUPPORTED` 守卫真正生效 ——
  此前它是死条件（该变量只在 `start_hy2` 里赋值，而它在 `create_hy2_json` 之后执行）。

**上游遗留的两条高危**

* **ws/h2 多域名 host 生成非法 JSON，插件被 `close_in_five` 自动关停**。
  「incase multi-domain input」那段把逗号改写成 `", "`，这对**数组**位置
  （tcp-http 的 `headers.Host`、h2 的 `host`）是正确的，但 `serverName` 与
  ws 的 `headers.Host` 是**标量**，拿到改写后的值就会多出一个没有键的裸值。
  触发条件：ws/h2 + TLS + host 填多个域名 + 未单独填 SNI。
  日志只有一句配置错误，用户几乎不可能想到根因是「host 填了两个域名」。
  现在标量位置取第一个域名（TLS 握手本就只能带一个 SNI）；
  已验证单域名场景新旧输出**逐字节相同**。
* **gRPC 的 `serviceName` 改完切一次节点就丢**。节点表的读列表（`params2`）有它，
  写列表（`params`）没有，而其余「只读不写」的字段都各有独立回写点，只有它是孤立的。
  用户会以为没保存成功，反复改反复丢。

**其它**

* **国内DNS映射表在 `dnsmasq.postconf` 里是旧的一份**：oneDNS 指向搬迁前早已停服的
  `112.124.47.27`/`114.215.126.16`（界面显示的却是正确的 `117.50.x.x`，
  `ssconfig.sh` 里的同名表也是正确的）；SmartDNS(13) 更是完全没有映射，
  `CDN` 为空导致写出 `server=#53` 这条非法指令、dnsmasq 起不来 ——
  叠加「DNS劫持=全部」就是全网 DNS 全断。现两表对齐、补 `CDN_PORT`（SmartDNS 是 5335）、
  并对空值兜底。
* **UDP 探测漏了 `degraded_plugin`**：SIP003 插件阻断与 hy2 构建不支持这两种降级
  会掉进链路完整性检查。写补丁前以为后果只是归因错误的红灯，加了桩测试才发现更糟 ——
  这两种降级发生在能力判定阶段、规则本来就没下发，链路件反而是「齐」的，
  于是探测判定为 **ok，状态栏显示绿灯「链路就绪」**，而 UDP 完全没走代理。
* 关插件后复位 DNS 行的三个附属芯片（尤其 fastlookup：`umount_dnsmasq_now` 已经卸载了，
  界面却仍是绿色「已挂载」）；Game 端口回退文案补上「规则写入失败」这条成因。
* `uninstall.sh` 补上 11 个 `ss_runtime_*` 键的清理，并修正开机钩子清理路径 ——
  `auto_start` 写的是 `/jffs/scripts/`，卸载删的却是 `/koolshare/scripts/`，
  且用 `ssconfig.sh` 去匹配 wan-start 里的 `ss_config.sh`（下划线对不上），钩子一直没被清掉。

**核查工具**

* **三个核查脚本一直在拿空树做对比**。`drift.py`/`pipeline.py`/`lifecycle.py` 硬编码了两个
  **从未入库**的临时快照目录；目录被清后 `pipeline.py` 直接崩，而 `drift.py` 的 `read()`
  对不存在的路径返回空串 —— 它**静默地**把空字符串当「原版」和「接手时」在比，
  输出的偏移全是假的，而 README 一直把这三个脚本写成「改完代码建议依次重跑」。
  现新增 `baselines.py` 统一从仓库真实来源解析（上游副本 + git 提交 `005bda5` + 工作树），
  三棵树都断言非空，缺任何一棵直接退出。
* 新增 `consistency.py`：核对「同一份常量表抄了两遍」这类问题（国内DNS映射表、
  网页选项文案里的【IP】与后端实际地址、节点表读/写字段是否配对）。
  上面两个 bug 都属于这一类，加核对是为了不再复发。
* `test_udp_probe.sh` 补两条回归桩（19/21 → 19 项全过），已验证撤销修复时会 FAIL。

**框架基线核对结果（修复后重跑，这次是真的）**

| 维度 | 原版 4.38.3 | 接手时 5.2.4 | 当前 |
|---|---|---|---|
| 自建 iptables 链 | 10 | 14 | 14 |
| 内置链钩子 | 5 | 9 | 9 |
| ipset 集合 | 5 | 6 | 6 |
| 命令行分支 | 4 | 4 | 4（三方完全一致） |

`apply_ss` / `load_nat` / `flush_nat` / `disable_ss` 四个主流程骨架的调用顺序与接手时**逐字一致**；
`mangle/SHADOWSOCKS` 链内规则次序修复后也回到与基线**完全一致**；
全项目剩下的唯一链内差异是 `filter/SHADOWSOCKS_FWD` 头部的 ESTABLISHED 短路（有意为之）。
生命周期核查无残留。

### 5.2.6-beta10
* 核对「Hysteria2设定」与当前官方文档：**混淆与拥塞控制的选项已经是完整的**，无需新增 ——
  obfs 支持 `salamander` 与 `gecko`（含 `minPacketSize` / `maxPacketSize`），
  congestion 支持 `bbr`（含 `bbrProfile`：standard / conservative / aggressive）与 `reno`；
  文档明确 `bandwidth` 决定某方向是否用 Brutal，不用 Brutal 的方向才走 `congestion` 里配的控制器。
  生成的字段名逐个与文档比对无误（注意是 `congestion.bbrProfile`，不是 `bbr.profile`）；
* `chain-logic.md` 新增 §2.2c：hy2 与 VLESS 两条 UDP 链路的**逐段拆解**
  （能力门控 → 配置生成 → 启动与自愈 → 规则下发 → 实测）；
* 记录一个拆解中发现的边界情况：`create_*_json` 受 `[ -z "$WAN_ACTION" ]` 约束、
  开机不重新生成配置，磁盘配置里的 UDP 入站可能与本次 `mangle` 不同步；
  有害方向（有规则、无监听）由 `cru/udp.sh` 的 UDP/3333 监听检查兜住。

### 5.2.6-beta9
* **Hysteria2 支持透明 UDP 代理**，由【Hysteria2设定】新增的 UDP 开关显式启用
  （默认关，理由是性能：hy2 是 QUIC 协议、开销大，弱路由器上开了 UDP 更早撞 CPU 上限）。
  配置键名与字段取自官方 Full Client Config 文档 —— 是 `udpTProxy` 而不是 `tproxyUDP`
  （后者是想当然的写法，靠读文档纠正）。写入条件为"开关已勾 且 本次需要 UDP 代理"，
  与 xray 侧的 `mangle` 条件一致，4 种组合已逐一实测；
* `start_hy2` 加安全网：若该构建不接受 `udpTProxy` 导致启动失败，剥掉该键重启一次并降级 UDP，
  而不是原来直接 `close_in_five`（那会连 TCP 代理一起关掉）；
* 状态栏可区分三种情形：开关未开（`hy2_udp_off`）、构建不支持（`hy2_udp_unsupported`）、
  以及其它降级原因。

### 5.2.6-beta8
* **逐条核对 VLESS/Xray 的 UDP 路径并确认无误**（入站形态、8 处生成点的条件一致性、
  无 sniffing/无 block 出站、两条 routing 路径、fragment 不影响 UDP），结论写入
  [`chain-logic.md`](review_archive/chain-logic.md) §2.2b；
* 更正 hysteria2 的归因措辞：原文说"当前节点核心无透明UDP入站能力"会让人误判成要换协议，
  实际是**本插件没给它配 UDP 入站**（hysteria2 本身是 QUIC 协议、UDP 中继是其强项）。
  anytls 的 `-nat 0.0.0.0:3333` 是否含 UDP 未经证实，未证实前不声称其无能力；
* 子选项行改为真实层级：原先在标签里塞 `&nbsp;&nbsp;* ` 手搓缩进（把结构编码成空格，
  字体一变就对不齐），现改为 `tr.ss-sub` + 左侧细导轨，连续子行间不重复画分隔线。

### 5.2.6-beta7
* **UDP 能力判定补上传输层这一层**：此前只看节点核心类型，会把「ss-libev + SIP003 simple-obfs」
  判成支持 UDP。实际 simple-obfs 是纯 TCP 插件、无 UDP 通路，而 `ss-redir -u` 会把 UDP
  直接发往 `server:port` 绕过插件、服务端不接受 —— UDP 进黑洞。
  这解释了一个反直觉现象：**「仅代理 QUIC」实测通过并不代表该节点能承载 UDP**
  （QUIC 被黑洞后浏览器自动回退 TCP，现象被掩盖），而「仅代理 QUIC+Game」下 Game 端口
  没有 TCP 回退路径，游戏直接不通；CDN/CF 前置节点还会因持续收到不被识别的 UDP 而限流，
  连 TCP 一起失败，表现为「换完节点一会儿就掉线」。
  现已识别该组合并降级纯 TCP，状态栏显示「插件阻断」，日志明确指出卡在传输层而非核心；
* SSR 节点非 plain obfs 在档3/游戏模式下给出告警（服务端是否接受 UDP 取决于其实现，
  本地无法可靠判定，故不强制降级）。

### 5.2.6-beta6（界面）
* **清掉三个死控件**（机器审计发现：界面上能改、也会存进去，但后端全项目无人读取）——
  `ss_game2_dns_foreign` / `ss_game2_dns2ss_user`（koolgame 遗留，整行删除）与
  `ss_basic_refreshrate`（保存列表里的幽灵键，页面上根本没有对应控件）；
* **「账号设置」加分组**：61 行零分组改为 6 组，并加空组自动隐藏；
* `review_archive/ui_audit.py`：新增 UI 审计脚本，把"界面上让用户填的东西"与"后端真的读它的地方"
  对起来，找死控件、幽灵键与未收敛的行内颜色；
* 修正 README 中"两条链路都有 fallback"的说法 —— 实际不对称，UDP 侧只有主模式 2/3 有兜底。

### 5.2.6-beta5
* **把「卡顿」的成因定位到两层，并给出根治路径**：除了第一层（dnsmasq 默认上游）的
  `strict-order` 兜底，新增按【国外DNS方案】判定第二层（7913 解析器）有无国内仲裁 ——
  按 `start_dns` 里各方案的实际启动参数分类：ChinaDNS-NG / chinadns1 自带仲裁，
  cdns（4 个上游全境外）与 dns2socks / ss-tunnel / https_dns_proxy / v2ray_dns 是纯隧道。
  纯隧道型 + 「全部」档时，主界面与日志都会提示改用 ChinaDNS-NG；
* 这同时**消除了上一轮遗留的不确定性**：`strict-order` 在实际那份 UPX 压缩二进制上是否被接受
  已无法离线核对，但根治路径（换方案）与 dnsmasq 选项无关，探测失败也不影响修复；
* 状态栏 DNS 行补上 `7913无国内仲裁` 提醒（warn 芯片：能用但有已知代价，既非故障也不该是绿灯）。

### 5.2.6-beta4
* 查证 fastlookup 上游源码（infinet/dnsmasq），**定性 `strict-order` 可用且语义正确**：
  严格按序、不并发扇出、失败才前进 —— 该 fork 只改了域名匹配的存储结构，
  server 遍历与 `OPT_ORDER` 分支是原版未动。同时确认不加它的后果比原先描述的更严重
  （会并发扇出所有上游并采用最先返回者，被墙域名必然拿到污染应答）。结论写进代码注释与
  [`chain-logic.md`](review_archive/chain-logic.md) §1.7，避免以后被"简化"掉。

### 5.2.6-beta3
* **重写 beta1 的 dnsmasq 就绪校验** —— 那版拿"53 端口绑没绑"做门禁，
  但 dnsmasq 先解析完约 12.3 万行配置才绑端口，会在健康启动过程中误判并把「全部」误回退「默认」，
  开着 fastlookup 时更易触发（替换必然伴随完整重启+重新解析）；且超时会自动卸掉用户的 fastlookup。
  现改为只看"进程在不在"，且不再替用户卸载任何东西；
* `strict-order` 改为运行时能力探测（fastlookup 二进制是 UPX 压缩的，静态扫不出选项名），
  不支持则不加第二上游并写日志，避免无 strict-order 时的污染风险；
* 主界面 DNS 行显示 fastlookup 的**实际**状态，把「选了替换但没挂上」这个差异暴露出来；
  「系统状态」页补上上游顺序、strict-order 探测结果与 `--test` 输出。

### 5.2.6-beta2
* **「全部」档增加 DNS 解析后备**（`strict-order` + 国内 DNS）—— 修「流量直连的网页偶尔卡顿」，
  根因是 dnsmasq 默认上游走隧道且 `no-resolv` 没有退路，详见上文与
  [`chain-logic.md`](review_archive/chain-logic.md) §1.7；
* DNS 劫持移除「关闭」档（历史存量自动迁移为「默认」）；
* 修「节点管理→添加节点→添加 SS 配置」里游戏模式仍为灰色：
  该处此前用 `is_ss_node()` 判断，而它读的是**当前生效节点**；
  新节点在 db 里还不存在，于是实际拿旧节点的类型在判。现改为看对话框自身的类型（`save_flag`）；
* Game 端口宽范围负载提醒（`1024-65535` 这类写法槽位合法但效果等同全量 UDP）。

### 5.2.6-beta1
* 「全部」档下发 53 改道前增加 dnsmasq 就绪校验与 fastlookup 回退阶梯
  （此前 dnsmasq 起不来会造成全网 DNS 全断，且全流程无任何检测）；
* UDP 运行时探测的监听检查改为有界重试（此前在 apply 收尾同步跑，
  代理核心刚拉起还没绑上 UDP/3333，会在"应用完成"瞬间误报红灯）；
* DNS 链路补上「请求值 vs 生效值」双层显示，与 UDP 对称；
* 移除主界面「检查并更新」按钮；接管此前未处理的帮助浮层样式，理顺状态栏五行的节奏。

### 5.2.5
* **加密 DNS 拦截可达性修复**：此前拦截链建在 filter/FORWARD，但境外解析器的包在 nat PREROUTING
  就被 REDIRECT、或在 mangle PREROUTING 被 TPROXY 抢走，FORWARD 恒不遍历 ——
  结果只拦得住国内加密 DNS，真正该挡的境外 DoH 反而被加密隧道化送出，且档位越高漏得越多
  （全量 UDP 档下一条都不命中）。现已在 nat/mangle 两条链头部放行 853 与已知 DoH 解析器的 443；
* 移除 5.2.4 引入的 TCP/53 监听探测（紧跟异步 `restart_dnsmasq`，必踩窗口，
  导致 TCP 改道整会话缺席；探测本身也多余）；53 改道判据改为 UDP+TCP 的 AND 语义；
* **访问控制下的 UDP 分流修复**：此前 ACL 列表里的主机 UDP 被无条件 RETURN，
  「同步 UDP 与 TCP」对这些主机完全空转；
* Game Port 禁止前导零（`07777` 会被 iptables 按八进制解析成 4095，静默错端口）；
  multiport 规则改为按返回码决定日志；
* filter 层兜底 guard 加 ESTABLISHED 短路（该链在 FORWARD 第 1 位，
  此前每个转发包都付两次 ipset 查询）；
* 首装补上两个新档位的默认值（此前界面显示的与实际生效的不一致）；
* 把三处"境外 QUIC 会被拦截"的无条件表述限定到实际成立的模式；
* 界面样式重构（配色统一、半径梯度、发丝线）；新增 UDP 代理运行时状态行。

### 5.2.0 – 5.2.4
* 游戏模式限定 SS 协议节点；移除 koolgame / speeder / udp2raw 等二进制与死代码；
* 「同步 UDP 与 TCP」四档化，新增「仅代理 QUIC+Game」与 Game Port；
* DNS 劫持三档化；dnsmasq-fastlookup 替换/还原改为 bind mount + 原地重启；
* 修复「恢复配置」时临时脚本首行混入杂质导致的 `n: not found`。
