# Shadowsocks ONLY on koolshare Merlin 380 ARM （安全，好用）
This project will update bin and package for [**fancyss_arm380**](https://github.com/hq450/fancyss_history_package/tree/master/legacy/fancyss_arm380)    

add and support new features  
fixed many historical legacy issues  

除插件原有功能外，另外

* 支持 xray, vless, xtls vision, reality, trojan, trojan-go, NaiveProxy, Hysteria2, AnyTLS 等协议及更新，
* 支持 ss2022，
* 支持多个 xray 节点聚合，负载平衡，
* 支持混合节点订阅，
* 支持同时订阅多个链接，回车隔开，
* 支持ss:// vless:// trojan:// trojan-go:// hysteria2:// hy2:// anytls:// 格式订阅和导入，
* 支持smartDNS (不熟悉配置请勿选择)，ChinaDNS-NG
* 支持在线更新

目前 xray 完全替代了 v2ray，trojan-go，xray 支持 vmess，vless，trojan，trojan-go ws 和 ss2022。

NaiveProxy 使用下来也还不错，延迟很低，速度也很快。
Hysteria2 目前是最稳定，速度也是最快的。 

离线安装包仅能在 koolshare 梅林 arm 380 平台，且 linux 内核为 2.6.36.4 的 armv7 架构的机器上使用！

**离线安装包**支持机型（需刷 koolshare 梅林**380**改版固件，最新版本：X7.9.1）：

* 华硕系列：`RT-AC56U` `RT-AC68U` `RT-AC66U-B1` `RT-AC1900P` `RT-AC87U` `RT-AC88U` `RT-AC3100` `RT-AC3200` `RT-AC5300`
* 网件系列：`R6300V2` `R6400` `R6900` `R7000` `R8000` `R8500`
* linksys EA系列：`EA6200` `EA6400` `EA6500v2` `EA6700` `EA6900`
* 华为：`ws880`

---

## 本分支（v2ray_bin_lite）变更

当前版本：**5.2.4**（离线包：`shadowsocks-5.2.4.tar.gz`）

本分支在原 [cary-sas/v2ray_bin](https://github.com/cary-sas/v2ray_bin) 基础上，聚焦大陆白名单场景做了如下调整（上文功能列表描述的是插件底层能力，本分支在界面上对部分入口做了精简，以下为准）：

### 代理链路修复
修复大陆白名单模式下部分境外网站（尤其 Google / YouTube 等 HTTP/3 站点）加载不出、不走代理的问题：

* **境外 QUIC 泄漏防护**：未开启 UDP 代理时，丢弃境外 QUIC（UDP/443）首包，强制浏览器回退 TCP 走代理；
* **IPv6 泄漏防护**：白名单模式且启用 IPv6 时，拒绝 IPv6 直连转发，强制回退到受透明代理接管的 IPv4。

### UDP / QUIC 分流（全局设定 →「同步 UDP 与 TCP」）
原开关由「开/关」升级为四档：

* **关闭**：UDP 不走代理（默认）；
* **仅代理 QUIC（低负载，推荐）**：只把 QUIC（UDP/443）按 chnroute 分流走代理，其余 UDP（BT、视频、游戏等）一律直连，兼顾 HTTP/3 站点可用与路由器负载；
* **仅代理 QUIC+Game（5.2.2）**：在仅代理 QUIC 基础上，把 Game Port 输入框指定的 UDP 端口一并按 chnroute 分流（境外游戏服走代理，国内直连）。端口支持单端口与端口段，逗号隔开，如 `27015,7777-7778`（方舟生存飞升 ASA）；前端保存与后端加载前双重语法检查（端口 1-65535、multiport 槽位 ≤15），非法则不下发规则；留空时与仅代理 QUIC 行为完全一致；
* **全量 UDP（高负载）**：所有 UDP 按 chnroute 分流走代理；
* SS 协议节点下存在游戏模式主机、或主模式为游戏模式时，自动回退为全量 UDP。

### 游戏模式仅限 SS 协议（5.2.0）
游戏模式（全量 UDP 透明代理）仅对 SS（ss-libev）节点开放；其它协议（SSR / V2Ray / Xray / Trojan / NaiveProxy / Hysteria2 / AnyTLS，含经 xray 运行的 SS2022）负载过重，不再提供：

* 非 SS 节点选择游戏模式时自动回退大陆白名单模式，访问控制中的游戏模式主机 TCP 按大陆白名单处理、UDP 按「同步 UDP 与 TCP」档位处理（界面与后端双重拦截，均有日志提示）；
* 非 SS 节点的 UDP 需求由「同步 UDP 与 TCP」三档（关闭 / 仅代理 QUIC / 全量 UDP）覆盖，足够日常使用。

### DNS 劫持（原 chromecast，三档）
* **关闭**：不劫持，客户端可自定义 DNS；
* **默认**：仅劫持明文 UDP/53 到路由器 dnsmasq；
* **全部（推荐用于大陆白名单）**：加劫持 TCP/53，并拦截 DoT(853) 与常见 DoH 解析器 IP 的 443，逼客户端回退明文 DNS 被路由器接管，保证白名单域名（含 Cloudflare/CDN 站）的真实 IP 可靠进入白名单直连；
* 出错回退：仅当劫持规则写入失败时自动回退「默认」；本机未监听 TCP/53 时自动跳过 TCP/53 改道（5.2.4，避免把 DNS 的 TCP 重试改道到不应答端口造成打开网页转圈）；劫持与 dnsmasq 瞬时状态完全解耦（两档最终都指向本机 dnsmasq，重启间隙由客户端重试自愈）。

### dnsmasq-fastlookup 兼容与安全加固（5.2.0 / 5.2.1）
「替换为 dnsmasq-fastlookup」与「DNS 劫持」两档在原版 / fastlookup 下均可靠工作：

* **DNS 劫持与替换状态彻底解耦（5.2.1）**：劫持规则无条件加载，不再探测 dnsmasq 瞬时状态——default/all 对本机 dnsmasq 的依赖完全相同，fastlookup 只是 dnsmasq 的替代实现，代理链路不因替换发生偏移；
* 替换/还原不再先杀 dnsmasq 等 init 异步拉起，改由 bind mount + service 重启原地换血，消除人为 DNS 中断窗口（此前该窗口会导致 DNS 劫持「全部」档被误回退「默认」）；
* 替换前用 fastlookup 二进制预检（`--test`）当前系统配置，旧版 fork 不兼容当前固件配置时自动放弃替换、保留原版，避免替换后全网断 DNS；
* 还原改用惰性卸载（`umount -l`），挂载点检测精确匹配 `/usr/sbin/dnsmasq`；关闭插件时先清空劫持规则再动 dnsmasq，消除停止瞬间的 DNS 中断；
* 修复「恢复配置」时临时脚本首行混入杂质导致的 `n: not found` 报错（5.2.1）。

### 界面与体积精简
* 移除「KCP 加速」「UDP 加速」入口；5.2.0 起进一步移除 `koolgame` `speederv1` `speederv2` `udp2raw` `pdu` 二进制及全部相关死代码（安装包缩小约 2.5MB，升级时自动清理路由器上的旧文件）；
* 「更新管理」移除「节点订阅设置」「通过链接添加服务器」入口；
* 「添加节点」移除「SSR」「koolgame」「Naive」入口（存量节点仍可正常编辑）。

### 更新源
* 插件自动更新指向本分支仓库 [guijianchou/v2ray_bin_lite](https://github.com/guijianchou/v2ray_bin_lite)；
* 二进制（xray / hysteria / naive 等）更新仍沿用原仓库 [cary-sas/v2ray_bin](https://github.com/cary-sas/v2ray_bin)。

