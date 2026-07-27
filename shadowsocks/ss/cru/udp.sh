#!/bin/sh
# UDP透明代理 运行时探测 —— 给主界面状态栏第4行（ss_state4）提供"真的在工作吗"的答案。
#
# 与 ss_runtime_udp_state 的分工：
#   ss_runtime_udp_state  = 本次 apply 之后【配置层】的真实档位（含节点能力/内核TPROXY/fwmark
#                           三处就地降级的结果），由 ssconfig.sh 的 write_udp_runtime_state 回写；
#   ss_runtime_udp_probe  = 现在这一刻【运行层】的实测结论，本脚本回写。
# 前者回答"你选的档位有没有被降级"，后者回答"该生效的东西此刻是不是真的立着"。
#
# 【443 的处理规则】非443 UDP 才是本探测的对象，QUIC(UDP/443) 一律排除在外：
# "仅代理QUIC"档下代理的就只有 UDP/443，此时没有任何非443 UDP 需要检查，直接报 pass(跳过)，
# 不能报 fail —— 否则用户选了推荐档位反而看到一个红灯，是纯粹的误报。
#
# 探测结论 ss_runtime_udp_probe：
#   off   插件未启用 / 档位关闭         —— 灰
#   pass  当前档位只代理QUIC/443，跳过  —— 中性
#   ok    链路就绪，尚无流量            —— 绿
#   flow  链路就绪，且已有流量经过      —— 绿
#   warn  链路好但配置多半有问题（Game端口未命中）—— 黄
#   unsupported 当前节点/协议提供不了UDP加速（换节点或勾开关即可）—— 黄
#   fail  该生效却没立起来 / 环境故障      —— 红

source /koolshare/scripts/base.sh

STATE=$(dbus get ss_runtime_udp_state 2>/dev/null)
STATE_TEXT=$(dbus get ss_runtime_udp_text 2>/dev/null)
ENABLE=$(dbus get ss_basic_enable 2>/dev/null)

PROBE="off"
PTEXT=""

write_out(){
	dbus set ss_runtime_udp_probe="$PROBE" >/dev/null 2>&1
	dbus set ss_runtime_udp_probe_text="$PTEXT" >/dev/null 2>&1
	dbus set ss_runtime_udp_probe_time="$(TZ=UTC-8 date '+%H:%M:%S')" >/dev/null 2>&1
	exit 0
}

# ---- 先看配置层结论，它已经把降级判断做完了，运行层不必重复 ----
if [ "$ENABLE" != "1" ]; then
	PROBE="off"; PTEXT="插件未启用"; write_out
fi

case "$STATE" in
	""|disabled)
		PROBE="off"; PTEXT="插件未启用或尚未应用过配置"; write_out
		;;
	off)
		PROBE="off"; PTEXT="当前档位不代理UDP"; write_out
		;;
	degraded_node|degraded_plugin)
		# 【能力不支持，不是故障】——这两类的共同点是：链路没坏，是这个节点/协议
		# 本来就提供不了 UDP 加速（hy2开关没开、hy2构建不认udpTProxy、
		# naive/anytls 没配透明UDP入站、SIP003 simple-obfs 没有UDP通路）。
		# 用户换个节点或勾个开关就能解决，标红会让人以为插件坏了，所以给 unsupported。
		# 注意 degraded_plugin 早先整个漏在这个 case 之外，会掉进下面的链路完整性检查，
		# 拿到"代理核心未监听UDP/3333"这个归因完全错误的结论。
		PROBE="unsupported"; PTEXT="${STATE_TEXT:-当前节点/协议不提供UDP加速}"; write_out
		;;
	degraded_kernel)
		# 【真故障】——内核不接受TPROXY、fwmark 0x07 被占、路由表310被占。
		# 这三种是环境问题，不换节点也解决不了，必须红灯。
		PROBE="fail"; PTEXT="${STATE_TEXT:-档位已被降级，UDP未走代理}"; write_out
		;;
	quic)
		# 用户规则：仅代理 UDP/443 时，非443 UDP 专项检查不适用，跳过而不是判失败
		PROBE="pass"; PTEXT="仅代理QUIC(UDP/443)，非443 UDP 按设计直连，本项跳过"; write_out
		;;
esac

# ---- 到这里 STATE 只可能是 quic_game / full / game，即确有非443 UDP 需要代理 ----

# 缺件用 ';' 分隔累积，最后再换成中文顿号。
# 不能用空格分隔再把空格全替成顿号 —— 缺件描述本身带空格（"缺少ip rule(...)"），
# 那样会被切成"缺少ip、rule(...)"。
MISS=""
add_miss(){ MISS="${MISS:+$MISS;}$1"; }

# 1) 代理核心是否真的开了 UDP/3333 透明入站（ss-redir -U / xray dokodemo tproxy）
#
# 有界重试而非一次性采样：本脚本除了被 cron 调用，还会被 ssconfig.sh 的
# write_udp_runtime_state 在 apply 收尾处【同步】调一次。那一刻代理核心刚被拉起，
# xray/ss-redir 绑定 UDP/3333 可能还差几百毫秒 —— 一次性采样会在"应用完成"的瞬间
# 报一个红灯，而那恰好是用户唯一会盯着状态栏看的时刻，属纯误报。
# 只在取不到时才重试，正常路径零额外开销。
#
# 【为什么不用 netstat】原来这里是 `netstat -unl | grep -qE "[:.]3333[[:space:]]"`。
# 真机上 hy2 与 xray 两个完全不同的核心都被判成"未监听"，而它们的 UDP 入站形态
# 早已逐条核对无误 —— 说明问题在探测手段本身。busybox 的 netstat 是可裁剪的 applet：
# -l（listening）本是 TCP 的状态概念，对无连接的 UDP 如何取舍取决于编译选项；
# 某些构建下 `-unl` 会把 UDP 全部过滤掉，也有构建根本没编进 netstat。
# 而 `2>/dev/null` 把 "netstat: applet not found" 一并吞掉，于是恒为"没监听"。
#
# 改用 /proc/net/udp：这是内核直接导出的，格式几十年未变，不依赖任何 applet。
# 第 2 列是 local_address，形如 HEXIP:HEXPORT；3333 = 0x0D05。
# udp6 一并看：核心若只在 IPv6 通配地址上监听，v4 映射流量同样由它收。
proc_udp_has_3333(){
	for f in /proc/net/udp /proc/net/udp6; do
		[ -r "$f" ] || continue
		awk 'NR>1 { n=split($2, a, ":"); if (toupper(a[n]) == "0D05") { found=1; exit } }
		     END { exit(found ? 0 : 1) }' "$f" 2>/dev/null && return 0
	done
	return 1
}

udp3333_ok=0
i=0
while [ "$i" -lt 4 ]; do
	if proc_udp_has_3333; then
		udp3333_ok=1
		break
	fi
	# 次选：/proc 不可读的异常环境下退回 netstat（宁可多一条判据，也不要没有）
	if netstat -unl 2>/dev/null | grep -qE "[:.]3333[[:space:]]"; then
		udp3333_ok=1
		break
	fi
	i=$((i + 1))
	[ "$i" -lt 4 ] && sleep 1
done
[ "$udp3333_ok" = "1" ] || add_miss "代理核心未监听UDP/3333"

# 2) fwmark 0x07 的策略路由是否在（内核显示为 0x7，不要按 0x07 匹配）
if ! ip rule show 2>/dev/null | grep -q "lookup 310"; then
	add_miss "缺少ip rule(fwmark->table310)"
fi

# 3) table 310 的本机路由是否在（内核可能渲染成 "local default dev lo"）
if ! ip route show table 310 2>/dev/null | grep -q "dev lo"; then
	add_miss "缺少table310本机路由"
fi

# 4) mangle PREROUTING 的 hook 与模式链里的 TPROXY 规则是否都在
if ! iptables -t mangle -S PREROUTING 2>/dev/null | grep -q "j SHADOWSOCKS"; then
	add_miss "缺少mangle PREROUTING hook"
fi
if ! iptables -t mangle -S 2>/dev/null | grep -q "TPROXY"; then
	add_miss "模式链内无TPROXY规则"
fi

if [ -n "$MISS" ]; then
	PROBE="fail"
	PTEXT="UDP透明代理未就绪：$(echo "$MISS" | sed 's/;/、/g')"
	write_out
fi

# ---- 链路完整，再看是否真有流量 ----
# 模式链里 TPROXY 规则的命中包数合计。full/game 档下非443 UDP 本就在代理范围内，
# 任何命中都是有效证据；quic_game 档另外单独读 Game 端口那条 hook 的计数（那才是纯非443部分）。
#
# 【为什么用 -x】iptables -nvL 不加 -x 时，计数超过 10 万会被缩写成 198K / 103M。
# 真机实测就已经出现了 `Chain PREROUTING (policy ACCEPT 198K packets, 103M bytes)`。
# 那样 awk '{s+=$1}' 读到 "105K" 会当成 105，比真实值少约 1000 倍 ——
# 红绿灯（>0 判定）不会翻转，但状态栏显示的包数会严重失真。
# sum_pkts 里仍然处理 K/M/G 后缀：万一某个构建不认 -x 而静默忽略，也不至于报错数。
sum_pkts(){
	awk 'function num(v){
	         if (v ~ /[Kk]$/) return substr(v,1,length(v)-1) * 1000
	         if (v ~ /[Mm]$/) return substr(v,1,length(v)-1) * 1000000
	         if (v ~ /[Gg]$/) return substr(v,1,length(v)-1) * 1000000000
	         return v + 0
	     }
	     { s += num($1) } END { printf "%d", s + 0 }'
}

TP_PKTS=$(iptables -t mangle -nvxL 2>/dev/null | grep "TPROXY" | sum_pkts)

GAME_PKTS=""
if [ "$STATE" == "quic_game" ]; then
	GAME_PKTS=$(iptables -t mangle -nvxL PREROUTING 2>/dev/null | grep "multiport" | grep "SHADOWSOCKS" | sum_pkts)
fi

# 【Game端口填错的检测】—— 真机实测催生的一条判据。
#
# 现象：用户按 ARK 的经典默认值填了 27015,7777-7778，档位选「仅代理QUIC+Game」，
# 界面一切正常（QUIC 有流量、状态栏绿灯），但游戏延迟毫无改善。
# 计数器给出的实情（开游戏前后对比）：
#   mangle PREROUTING 的 multiport hook  0 -> 2 包
#   filter SHADOWSOCKS_FWD 的【链尾 RETURN】 0 -> 75 包 / 42KB
# 链尾 RETURN 的语义是"既不在白名单、也不在 chnroute、非黑名单、非TCP、非UDP/443"，
# 剩下只可能是【境外的非443 UDP】—— 那就是游戏流量本身，它绕过了 Game 端口 hook
# 被直接放行直连了。也就是说：端口填错时，插件此前一个字都不会提示。
#
# 所以这里在 quic_game 档下多问一句：Game hook 几乎没命中，而兜底链尾却在放行
# 境外非443 UDP —— 两者同时成立时，八成是端口填错了，而不是"暂无流量"。
# 注意 SHADOWSOCKS_FWD 只在主模式2(大陆白名单)建链，取不到就跳过该判据，不误报。
FWD_TAIL=""
if iptables -t filter -nvL SHADOWSOCKS_FWD >/dev/null 2>&1; then
	# 链尾那条是无条件 RETURN（target=RETURN 且 prot=all 且无任何 match 描述）
	FWD_TAIL=$(iptables -t filter -nvxL SHADOWSOCKS_FWD 2>/dev/null \
		| awk '$3=="RETURN" && $4=="all" && NF<=9 {print $1}' | sum_pkts)
fi

if [ "$STATE" == "quic_game" ]; then
	if [ -n "$GAME_PKTS" ] && [ "$GAME_PKTS" -gt 0 ]; then
		PROBE="flow"; PTEXT="Game端口UDP已有流量经代理（${GAME_PKTS}包），QUIC/443不计入本项"
	elif [ -n "$FWD_TAIL" ] && [ "$FWD_TAIL" -gt 200 ]; then
		# Game 端口没命中，却有可观的境外非443 UDP 被兜底放行。
		# 两种成因，措辞上都要覆盖，不能只说"填错"：
		#   a) 端口确实填错了（照抄了默认值，而服务器用的是别的端口）；
		#   b) 该游戏根本不用固定目的端口 —— 很多用 EOS/Steam 中继的游戏是
		#      随机开一堆端口转发到服务端，固定的 multiport 列表永远抓不住。
		# 对 (b) 正确的解法不是继续猜端口，而是按【目的地】匹配：
		# 黑名单目标的 UDP 是不限端口一律走代理的（PREROUTING 那条
		# `-m set --match-set black_list dst -j SHADOWSOCKS` 没有端口限定），
		# 且在「仅代理QUIC」档就生效，不必开全量UDP。
		PROBE="warn"
		PTEXT="Game端口未命中：已有 ${FWD_TAIL} 个境外非443 UDP 包直连出去（未经代理）。可能是端口填错，也可能该游戏用随机目的端口（端口匹配对它无效）。后者请把游戏服务器的IP或域名加进【黑白名单→黑名单】——黑名单目标的UDP不限端口一律走代理。查真实目的地：在游戏运行时跑 grep udp /proc/net/nf_conntrack"
	else
		PROBE="ok";   PTEXT="链路就绪，Game端口暂无UDP流量（QUIC/443不计入本项）"
	fi
else
	if [ "$TP_PKTS" -gt 0 ]; then
		PROBE="flow"; PTEXT="UDP透明代理正常，已有流量经过（TPROXY命中${TP_PKTS}包）"
	else
		PROBE="ok";   PTEXT="UDP透明代理链路就绪，暂无流量经过"
	fi
fi

write_out
