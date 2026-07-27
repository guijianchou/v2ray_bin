#!/bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

eval `dbus export ss`
source /koolshare/scripts/base.sh
source helper.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'

get_mode_name() {
	case "$1" in
		1)
			echo "【gfwlist模式】"
		;;
		2)
			echo "【大陆白名单模式】"
		;;
		3)
			echo "【游戏模式】"
		;;
		5)
			echo "【全局模式】"
		;;
		6)
			echo "【回国模式】"
		;;
	esac
}

get_dns_name() {
	case "$1" in
		1)
			echo "cdns"
		;;
		2)
			echo "chinadns2"
		;;
		3)
			echo "dns2socks"
		;;
		4)
			if [ -n "$ss_basic_rss_obfs" ];then
				echo "ssr-tunnel"
			else
				echo "ss-tunnel"
			fi
		;;
		5)
			echo "chinadns1 + dns2socks上游"
		;;
		6)
			echo "https_dns_proxy"
		;;
		7)
			echo "v2ray dns"
		;;
		8)
			echo "koolgame内置"
		;;
		9)
			echo "SmartDNS"
		;;
		10)
			echo "ChinaDNS-NG"
		;;
	esac
}

get_action_chain() {
	case "$1" in
		0)
			echo "RETURN"
		;;
		1)
			echo "SHADOWSOCKS_GFW"
		;;
		2)
			echo "SHADOWSOCKS_CHN"
		;;
		3)
			echo "SHADOWSOCKS_GAM"
		;;
		5)
			echo "SHADOWSOCKS_GLO"
		;;
		6)
			echo "SHADOWSOCKS_HOM"
		;;
	esac
}

echo_version(){
	echo_date
	SOFVERSION=`cat /koolshare/ss/version`
	##---------------------------xray-----------------------
	if [ -z "$ss_basic_xray_version" ];then
		ss_basic_xray_version_tmp=`/koolshare/bin/xray -version 2>/dev/null | head -n 1 | cut -d " " -f2`
		if [ -n "$ss_basic_xray_version_tmp" ];then
			ss_basic_xray_version="$ss_basic_xray_version_tmp"
			dbus set ss_basic_xray_version="$ss_basic_xray_version_tmp"
		else
			ss_basic_xray_version="null"
		fi
	fi

	##---------------------------naive-----------------------
	if [ -z "$ss_basic_naive_version" ];then
		ss_basic_naive_version_tmp=`/koolshare/bin/naive -version 2>/dev/null | head -n 1 | cut -d " " -f2`
		if [ -n "$ss_basic_naive_version_tmp" ];then
			ss_basic_naive_version="$ss_basic_naive_version_tmp"
			dbus set ss_basic_naive_version="$ss_basic_naive_version_tmp"
		else
			ss_basic_naive_version="null"
		fi
	fi
	##---------------------------hysteria-----------------------
	if [ -z "$ss_basic_hysteria_version" ];then
		ss_basic_hysteria_version_tmp=`/koolshare/bin/hysteria version | grep 'Version:' | awk -F'[[:space:]]+' '{print $2}'`
		if [ -n "$ss_basic_hysteria_version_tmp" ];then
			ss_basic_hysteria_version="$ss_basic_hysteria_version_tmp"
			dbus set ss_basic_hysteria_version="$ss_basic_hysteria_version_tmp"
		else
			ss_basic_hysteria_version="null"
		fi
	fi

	##---------------------------anytls-----------------------
	if [ -z "$ss_basic_anytls_version" ];then
		ss_basic_anytls_version_tmp=`/koolshare/bin/anytls -version 2>/dev/null | head -n 1 | cut -d " " -f2`
		if [ -n "$ss_basic_anytls_version_tmp" ];then
			ss_basic_anytls_version="$ss_basic_anytls_version_tmp"
			dbus set ss_basic_anytls_version="$ss_basic_anytls_version_tmp"
		else
			ss_basic_anytls_version="null"
		fi
	fi

	echo ① 程序版本（插件版本：$SOFVERSION）：
	echo -----------------------------------------------------------
	echo "程序			版本		备注"
	echo "ss-redir		3.3.5		2020年9月15日编译"
	echo "ss-tunnel		3.3.5		2020年9月15日编译"
	echo "ss-local		3.3.5		2020年9月15日编译"
	echo "v2ray-plugin		4.45.0		2022年4月30日编译"
	echo "ssrr-redir		3.5.3 		2018年11月25日编译"
	echo "ssrr-tunnel		3.5.3 		2018年11月25日编译"
	echo "ssrr-local		3.5.3 		2018年11月25日编译"
	echo "haproxy			1.8.8 		2018年05月03日编译"
	echo "dns2socks		V2.0"
	echo "cdns			1.0 		2017年12月09日编译"
	echo "chinadns1		1.3.2 		2017年12月09日编译"
	echo "chinadns2		2.0.0 		2017年12月09日编译"
	echo "ChinaDNS-NG		1.0-beta.25 	2019年08月31日编译"
	echo "xray			$ss_basic_xray_version	"
	echo "naive		$ss_basic_naive_version	"
	echo "hysteria		$ss_basic_hysteria_version	"
	echo "anytls		$ss_basic_anytls_version	"
	echo -----------------------------------------------------------
}

check_status(){
	#echo
	SS_REDIR=`pidof ss-redir`
	SS_TUNNEL=`pidof ss-tunnel`
	SS_LOCAL=`ps|grep -w ss-local|grep 23456|awk '{print $1}'`
	V2RAY_PLUGIN=`pidof v2ray-plugin`
	OBFS_PLUGIN=`pidof obfs-local`
	SSR_REDIR=`pidof rss-redir`
	SSR_LOCAL=`ps|grep -w rss-local|grep 23456|awk '{print $1}'`
	SSR_TUNNEL=`pidof rss-tunnel`
	KOOLGAME=`pidof koolgame`
	DNS2SOCKS=`pidof dns2socks`
	CDNS=`pidof cdns`
	CHINADNS1=`pidof chinadns1`
	CHINADNS=`pidof chinadns`
	CHINADNSNG=`pidof chinadns-ng`
	HAPROXY=`pidof haproxy`
	V2RAY=`pidof v2ray`
	XRAY=`pidof xray`
	NAIVE=`pidof naive`
	HYSTERIA=`pidof hysteria`
	ANYTLS=`pidof anytls`
	HDP=`pidof https_dns_proxy`
	DMQ=`pidof dnsmasq`
	SMD=$(pidof smartdns)
	game_on=`dbus list ss_acl_mode|cut -d "=" -f 2 | grep 3`

	if [ "$ss_basic_type" == "0" ];then
		echo_version
		echo
		echo ② 检测当前相关进程工作状态：（你正在使用SS-libev,选择的模式是$(get_mode_name $ss_basic_mode),国外DNS解析方案是：$(get_dns_name $ss_foreign_dns)）
		echo -----------------------------------------------------------
		echo "程序		状态	PID"
		[ -n "$SS_REDIR" ] && echo "ss-redir	工作中	pid：$SS_REDIR" || echo "ss-redir	未运行"
		[ -n "$V2RAY_PLUGIN" ] && echo "v2ray-plugin	工作中	pid：$V2RAY_PLUGIN" || echo "v2ray-plugin	未运行"
		[ -n "$OBFS_PLUGIN" ] && echo "simple-obfs	工作中	pid：$OBFS_PLUGIN" || echo "simple-obfs	未运行"
	elif [ "$ss_basic_type" == "1" ];then
		echo_version
		echo
		echo ② 检测当前相关进程工作状态：（你正在使用SSR-libev,选择的模式是$(get_mode_name $ss_basic_mode),国外DNS解析方案是：$(get_dns_name $ss_foreign_dns)）
		echo -----------------------------------------------------------
		echo "程序		状态	PID"
		[ -n "$SSR_REDIR" ] && echo "ssr-redir	工作中	pid：$SSR_REDIR" || echo "ssr-redir	未运行"
	elif [ "$ss_basic_type" == "2" ];then
		echo_version
		echo
		echo ② 检测当前相关进程工作状态：（你选择的是koolgame节点，本版本已移除koolgame支持，插件不会启动）
		echo -----------------------------------------------------------
		echo "程序		状态	PID"
		echo "koolgame	已废弃	本版本不再分发koolgame二进制，插件已跳过启动以避免整链断网"
		echo "            请到【节点设置】改选SS/V2Ray/Xray/Trojan/Hysteria2/AnyTLS等其它类型节点后重新应用。"
	elif [ "$ss_basic_type" == "3" ];then
		echo_version
		echo
		echo ② 检测当前相关进程工作状态：（你正在使用V2Ray,选择的模式是$(get_mode_name $ss_basic_mode),国外DNS解析方案是：$(get_dns_name $ss_foreign_dns)）
		echo -----------------------------------------------------------
		echo "程序		状态	PID"
		[ -n "$V2RAY" ] && echo "v2ray		工作中	pid：$V2RAY" || echo "v2ray	未运行"
		[ -n "$XRAY" ] && echo "xray		工作中	pid：$XRAY" || echo "xray	未运行"
	elif [ "$ss_basic_type" == "4" ];then
		echo_version
		echo
		echo ② 检测当前相关进程工作状态：（你正在使用Trojan,选择的模式是$(get_mode_name $ss_basic_mode),国外DNS解析方案是：$(get_dns_name $ss_foreign_dns)）
		echo -----------------------------------------------------------
		echo "程序		状态	PID"
		[ -n "$XRAY" ] && echo "xray		工作中	pid：$XRAY" || echo "xray	未运行"	
		[ -n "$HYSTERIA" ] && echo "Hysteria2		工作中	pid：$HYSTERIA" || echo "Hysteria2	未运行"	
		[ -n "$ANYTLS" ] && echo "AnyTLS		工作中	pid：$ANYTLS" || echo "AnyTLS	未运行"
	elif [ "$ss_basic_type" == "5" ];then
		echo_version
		echo
		echo ② 检测当前相关进程工作状态：（你正在使用NaiveProxy,选择的模式是$(get_mode_name $ss_basic_mode),国外DNS解析方案是：$(get_dns_name $ss_foreign_dns)）
		echo -----------------------------------------------------------
		echo "程序		状态	PID"
		[ -n "$NAIVE" ] && echo "naiveproxy		工作中	pid：$NAIVE" || echo "naiveproxy	未运行"		
	fi

	if [ -z "$ss_basic_koolgame_udp" ];then
		if [ "$ss_basic_server" == "127.0.0.1" ];then
		 	[ -n "$HAPROXY" ] && echo "haproxy		工作中	pid：$HAPROXY" || echo "haproxy		未运行"
		fi
		
		if [ "$ss_foreign_dns" == "1" ];then
			[ -n "$CDNS" ] && echo "cdns		工作中	pid：$CDNS" || echo "cdns	未运行"
		elif [ "$ss_foreign_dns" == "2" ];then
			[ -n "$CHINADNS" ] && echo "chinadns	工作中	pid：$CHINADNS" || echo "chinadns	未运行"
		elif [ "$ss_foreign_dns" == "3" ];then
			if [ -n "$ss_basic_rss_obfs" ];then
				[ -n "$SSR_LOCAL" ] && echo "ssr-local	工作中	pid：$SSR_LOCAL" || echo "ssr-local	未运行"
				[ -n "$DNS2SOCKS" ] && echo "dns2socks	工作中	pid：$DNS2SOCKS" || echo "dns2socks	未运行"
			else
				if [ "$ss_basic_type" != "3" ];then
					[ -n "$SS_LOCAL" ] && echo "ss-local	工作中	pid：$SS_LOCAL" || echo "ss-local	未运行"
				fi
				[ -n "$DNS2SOCKS" ] && echo "dns2socks	工作中	pid：$DNS2SOCKS" || echo "dns2socks	未运行"
			fi
		elif [ "$ss_foreign_dns" == "4" ];then
			if [ -n "$ss_basic_rss_obfs" ];then
				[ -n "$SSR_TUNNEL" ] && echo "ssr-tunnel	工作中	pid：$SSR_TUNNEL" || echo "ssr-tunnel	未运行"
			else
				[ -n "$SS_TUNNEL" ] && echo "ss-tunnel	工作中	pid：$SS_TUNNEL" || echo "ss-tunnel	未运行"
			fi
		elif [ "$ss_foreign_dns" == "5" ];then
			if [ "$ss_basic_type" != "3" ];then
				[ -n "$SSR_LOCAL" ] && echo "ssr-local	工作中	pid：$SSR_LOCAL" || echo "ssr-local	未运行"
			fi
			[ -n "$DNS2SOCKS" ] && echo "dns2socks	工作中	pid：$DNS2SOCKS" || echo "dns2socks	未运行"
			[ -n "$CHINADNS1" ] && echo "chinadns1	工作中	pid：$CHINADNS1" || echo "chinadns1	未运行"
		elif [ "$ss_foreign_dns" == "6" ];then
			[ -n "$HDP" ] && echo "https_dns_proxy	工作中	pid：$HDP" || echo "https_dns_proxy	未运行"
		elif [ "$ss_foreign_dns" == "9" ]; then
			[ -n "$SMD" ] && echo "SmartDNS	工作中	pid：$SMD" || echo "SmartDNS	未运行"
		elif [ "$ss_foreign_dns" == "10" ]; then
			[ -n "$DNS2SOCKS" ] && echo "dns2socks	工作中	pid：$DNS2SOCKS" || echo "dns2socks	未运行"
			[ -n "$CHINADNSNG" ] && echo "ChinaDNS-NG	工作中	pid：$CHINADNSNG" || echo "ChinaDNS-NG	未运行"	
		fi
	fi
	[ "$ss_dnschina" == "13" ] &&{
		[ "$ss_foreign_dns" != "9" ] && [ -n "$SMD" ] && echo "SmartDNS	工作中	pid：$SMD" || echo "SmartDNS	未运行"
	}
	[ -n "$DMQ" ] && echo "dnsmasq		工作中	pid：$DMQ" || echo "dnsmasq	未运行"

	echo -----------------------------------------------------------
	echo
	echo
	echo ③ 检测iptbales工作状态：
	echo ----------------------------------------------------- nat表 PREROUTING 链 --------------------------------------------------------
	iptables -nvL PREROUTING -t nat
	echo
	echo ----------------------------------------------------- nat表 OUTPUT 链 ------------------------------------------------------------
	iptables -nvL OUTPUT -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS 链 --------------------------------------------------------
	iptables -nvL SHADOWSOCKS -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_EXT 链 --------------------------------------------------------
	iptables -nvL SHADOWSOCKS_EXT -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_GFW 链 ----------------------------------------------------
	iptables -nvL SHADOWSOCKS_GFW -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_CHN 链 -----------------------------------------------------
	iptables -nvL SHADOWSOCKS_CHN -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_GAM 链 -----------------------------------------------------
	iptables -nvL SHADOWSOCKS_GAM -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_GLO 链 -----------------------------------------------------
	iptables -nvL SHADOWSOCKS_GLO -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_HOM 链 -----------------------------------------------------
	iptables -nvL SHADOWSOCKS_HOM -t nat
	echo -----------------------------------------------------------------------------------------------------------------------------------
	echo
	MANGLE_SHOW=""
	{ [ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] || [ "$ss_basic_udp_sync" == "1" ] || [ "$ss_basic_udp_sync" == "2" ] || [ "$ss_basic_udp_sync" == "3" ]; } && MANGLE_SHOW=1
	if [ -n "$MANGLE_SHOW" ]; then
		echo ------------------------------------------------------ mangle表 PREROUTING 链 -------------------------------------------------------
		iptables -nvL PREROUTING -t mangle
		echo
		echo ------------------------------------------------------ mangle表 SHADOWSOCKS 链 -------------------------------------------------------
		iptables -nvL SHADOWSOCKS -t mangle
		echo
		for MCHAIN in SHADOWSOCKS_GFW SHADOWSOCKS_CHN SHADOWSOCKS_GAM SHADOWSOCKS_GLO SHADOWSOCKS_HOM; do
			echo ------------------------------------------------------ mangle表 $MCHAIN 链 -------------------------------------------------------
			iptables -nvL $MCHAIN -t mangle
			echo
		done
	fi
	# DNS劫持链路（原先这段完全不可见：nat PREROUTING 里能看到53改道，但最容易静默失效的
	# DoT/DoH 拦截链与 ss_doh 集一个都没打出来，出问题时无从判断是没建、建了没命中、还是
	# 被 REDIRECT/TPROXY 抢在 FORWARD 之前。）
	echo ------------------------------------------------------ DNS劫持档位与链路 -------------------------------------------------------
	echo "ss_basic_dns_hijack = [$ss_basic_dns_hijack]  (0=关闭 / 1=默认仅UDP53 / 2=全部强制+拦DoT/DoH)  <- 用户请求值"
	echo "ss_runtime_dns_state = [$(dbus get ss_runtime_dns_state)]  <- 实际生效值"
	echo "ss_runtime_dns_text  = [$(dbus get ss_runtime_dns_text)]"
	echo "  说明：state=fallback_default 表示选了【全部】但没能生效（53改道未写全，或本机dnsmasq未就绪），已退回【默认】档。"
	echo "  dnsmasq 存活情况：pid=[$(pidof dnsmasq)]  UDP/53监听=[$(netstat -unl 2>/dev/null | grep -oE "[:.]53[[:space:]]" | head -n1)]"
	echo "  dnsmasq-fastlookup 挂载=[$(mount | grep " on /usr/sbin/dnsmasq " | wc -l)]  (档位 ss_basic_dnsmasq_fastlookup=[$ss_basic_dnsmasq_fastlookup])"
	echo "  fastlookup 实际状态 ss_runtime_dns_fastlookup = [$(dbus get ss_runtime_dns_fastlookup)]"
	echo "    on=已挂载 / want_but_off=选了替换但没挂上(多为--test未通过，与当前dnsmasq配置不兼容) / off=未要求替换"
	echo "  7913解析器仲裁能力 ss_runtime_dns_arbiter = [$(dbus get ss_runtime_dns_arbiter)]  (国外DNS方案 ss_foreign_dns=[$ss_foreign_dns])"
	echo "    self=自带国内+隧道仲裁(chinadns1/ChinaDNS-NG) / tunnel_only=纯隧道无国内上游 / unknown=取决于用户配置(chinadns2/SmartDNS)"
	echo "    tunnel_only 时隧道抖动会让非gfwlist/cdn域名解析超时，即【直连网页偶尔卡顿】的结构性成因"
	echo "  DNS解析后备 ss_runtime_dns_fallback = [$(dbus get ss_runtime_dns_fallback)]"
	echo "    on=已启用strict-order+国内DNS后备 / unsupported=当前dnsmasq不认strict-order故未启用 / off=非全部强制档"
	echo "  /etc/dnsmasq.conf 的上游与顺序（strict-order 必须在 server= 之前才生效）："
	grep -nE "^(strict-order|all-servers|no-resolv|server=)" /etc/dnsmasq.conf 2>/dev/null | sed 's/^/    /'
	echo "  strict-order 能力探测（对即将运行的那个二进制）："
	/usr/sbin/dnsmasq --test --strict-order -C /dev/null >/dev/null 2>&1 && echo "    支持" || echo "    不支持"
	echo "  fastlookup 与当前配置兼容性实测（--test）："
	/koolshare/bin/dnsmasq --test -C /etc/dnsmasq.conf 2>&1 | sed 's/^/    /'
	echo "    exit=$?  (非0=不兼容，mount_dnsmasq 会放弃替换)"
	echo
	echo "-- nat PREROUTING 中的 53 改道规则（档2直接DNAT，档1经SHADOWSOCKS_DNS_*链）--"
	iptables -t nat -S PREROUTING 2>/dev/null | grep -E "dport 53|SHADOWSOCKS_DNS_"
	echo
	if [ "$ss_basic_dns_hijack" == "2" ]; then
		echo "-- filter表 SHADOWSOCKS_DNSF 链（DoT/DoH 拦截）--"
		iptables -nvL SHADOWSOCKS_DNSF -t filter
		echo
		echo "-- 加密DNS放行规则（把853/DoH-443从代理里放出来，否则上面这条链永远不遍历）--"
		iptables -t nat -S SHADOWSOCKS 2>/dev/null | grep -E "dport (853|443)"
		iptables -t mangle -S SHADOWSOCKS 2>/dev/null | grep -E "dport (853|443)"
		echo
		echo "-- ss_doh 集合成员 --"
		ipset -L ss_doh 2>/dev/null | grep -E "^[0-9]|Number of entries"
		echo
	fi
	echo -----------------------------------------------------------------------------------------------------------------------------------
	echo
	# UDP代理运行时状态（与主界面状态栏第4行同源）
	echo ------------------------------------------------------ UDP代理运行时状态 -------------------------------------------------------
	echo "档位(配置层) ss_runtime_udp_state = [$(dbus get ss_runtime_udp_state)]"
	echo "             ss_runtime_udp_text  = [$(dbus get ss_runtime_udp_text)]"
	echo "实测(运行层) ss_runtime_udp_probe = [$(dbus get ss_runtime_udp_probe)]  @$(dbus get ss_runtime_udp_probe_time)"
	echo "             ss_runtime_udp_probe_text = [$(dbus get ss_runtime_udp_probe_text)]"
	echo "  说明：probe 取值 —— off(未启用/档位关) / pass(仅代理QUIC，非443UDP不适用，跳过)"
	echo "        ok(链路就绪无流量) / flow(有流量经代理)"
	echo "        warn(Game端口未命中：可能填错，也可能该游戏用随机目的端口)"
	echo "        unsupported(该节点/协议提供不了UDP加速，换节点或勾开关即可，【不是故障】)"
	echo "        fail(该生效却没立起来，或内核/环境故障 —— 这才是真红灯)"
	# hy2 构建能力的【持久化】结论。这是唯一能看出「开机路径为什么不下发UDP规则」的地方 ——
	# 它不是本次运行算出来的，而是上一次 start_hy2 自愈时落库的，之后每次开机都沿用。
	HY2U=$(dbus get ss_runtime_hy2_udp_unsupported)
	echo "-- Hysteria2 透明UDP入站(udpTProxy) 构建能力 --"
	if [ "$HY2U" == "1" ]; then
		echo "  ss_runtime_hy2_udp_unsupported = [1] —— 已判定【这份 hysteria 构建不接受 udpTProxy】"
		echo "  该结论由上一次 start_hy2 的自愈流程落库，开机路径直接沿用、不再重试（省掉约9秒等待）。"
		echo "  影响：即使勾了 UDP 开关、档位选了2/3，本节点的 UDP 也不会下发透明代理规则（这是对的，"
		echo "        否则规则会指向一个不监听 UDP/3333 的核心，Game端口UDP整段黑洞）。"
		echo "  要重新探测：换一个编入TPROXY支持的构建后，在网页上【手动点一次应用】即会清掉该结论重试。"
	elif [ -n "$ss_basic_hy2_udp" ] && [ "$ss_basic_hy2_udp" == "1" ]; then
		echo "  ss_runtime_hy2_udp_unsupported = [空] —— 未判定为不支持，UDP开关已开启，按支持处理。"
	else
		echo "  ss_runtime_hy2_udp_unsupported = [${HY2U:-空}]（当前节点非hy2、或未开启hy2的UDP开关）"
	fi
	echo
	echo "-- ip rule / table 310 --"
	ip rule show 2>/dev/null | grep -E "310|fwmark"
	ip route show table 310 2>/dev/null
	echo
	echo "-- UDP/3333 透明入站监听 --"
	# 以 /proc/net/udp 为准：内核直出，不依赖 busybox netstat 的裁剪情况。
	# 3333 = 0x0D05，第2列是 local_address(HEXIP:HEXPORT)。
	PROC_HIT=""
	for f in /proc/net/udp /proc/net/udp6; do
		[ -r "$f" ] || continue
		L=$(awk 'NR>1 { n=split($2, a, ":"); if (toupper(a[n]) == "0D05") print FILENAME": "$0 }' "$f" 2>/dev/null)
		[ -n "$L" ] && { echo "$L"; PROC_HIT=1; }
	done
	[ -n "$PROC_HIT" ] || echo "（/proc/net/udp{,6} 里没有 :0D05 —— 核心确实没在 UDP/3333 上监听）"
	echo "  [对照] netstat -unl（busybox 的 -l 对无连接的 UDP 语义依编译而异，仅供参考）："
	netstat -unl 2>/dev/null | grep -E "[:.]3333[[:space:]]" || echo "  （netstat 无输出或不可用）"
	echo -----------------------------------------------------------------------------------------------------------------------------------
	echo
	# filter层境外流量兜底guard（大陆白名单模式）
	if [ "$ss_basic_mode" == "2" ]; then
		echo ------------------------------------------------------ filter表 SHADOWSOCKS_FWD 链（境外TCP/UDP兜底） -------------------------------------------------------
		iptables -nvL SHADOWSOCKS_FWD -t filter
		echo
		if command -v ip6tables >/dev/null 2>&1; then
			echo ------------------------------------------------------ filter表 SHADOWSOCKS_IPV6 链 -------------------------------------------------------
			ip6tables -nvL SHADOWSOCKS_IPV6 -t filter
			echo
		fi
	fi
	echo -----------------------------------------------------------------------------------------------------------------------------------
	echo
}

if [ "$ss_basic_enable" == "1" ];then
	echo "" > /tmp/ss_proc_status.log 2>&1
	check_status >> /tmp/ss_proc_status.log 2>&1
else
	echo 插件尚未启用！> /tmp/ss_proc_status.log 2>&1
fi
echo XU6J03M6 >> /tmp/ss_proc_status.log

# 这个脚本原本只写日志文件、不打终端 —— 因为它是给网页用的：
# res/ss_proc_status.htm 通过 <% nvram_dump("ss_proc_status.log","") %> 把文件灌进页面。
# 但它同时也是文档里推荐的命令行诊断入口，在 ssh 里直接跑会"什么都没输出"，
# 让人以为脚本坏了。这里在【标准输出是终端】时把结果一并打出来；
# 网页那条路径走的是文件，不受影响。
[ -t 1 ] && cat /tmp/ss_proc_status.log
