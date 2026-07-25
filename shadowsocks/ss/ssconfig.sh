#!/bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

eval `dbus export ss`
source /koolshare/scripts/base.sh
source helper.sh
# Variable definitions
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
dbus set ss_basic_version_local=`cat /koolshare/ss/version`
LOG_FILE=/tmp/syslog.log
CONFIG_FILE=/koolshare/ss/ss.json
V2RAY_CONFIG_FILE_TMP="/tmp/v2ray_tmp.json"
V2RAY_CONFIG_FILE="/koolshare/ss/v2ray.json"
NAIVE_CONFIG_FILE="/koolshare/ss/naive.json"
NAIVE2_CONFIG_FILE="/koolshare/ss/naive2.json"
HY2_CONFIG_FILE="/koolshare/ss/hysteria.json"
HY2_GLOBAL_CONFIG_FILE="/tmp/hysteria_global.json"
LOCK_FILE=/var/lock/koolss.lock
DNSF_PORT=7913
DNSC_PORT=53
ISP_DNS1=$(nvram get wan0_dns|sed 's/ /\n/g'|grep -v 0.0.0.0|grep -v 127.0.0.1|sed -n 1p)
ISP_DNS2=$(nvram get wan0_dns|sed 's/ /\n/g'|grep -v 0.0.0.0|grep -v 127.0.0.1|sed -n 2p)
IFIP_DNS1=`echo $ISP_DNS1|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
IFIP_DNS2=`echo $ISP_DNS2|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
gfw_on=`dbus list ss_acl_mode_|cut -d "=" -f 2 | grep -E "1"`
chn_on=`dbus list ss_acl_mode_|cut -d "=" -f 2 | grep -E "2|3|4"`
all_on=`dbus list ss_acl_mode_|cut -d "=" -f 2 | grep -E "5"`
lan_ipaddr=$(nvram get lan_ipaddr)
ip_prefix_hex=`nvram get lan_ipaddr | awk -F "." '{printf ("0x%02x", $1)} {printf ("%02x", $2)} {printf ("%02x", $3)} {printf ("00/0xffffff00\n")}'`
[ "$ss_basic_mode" == "4" ] && ss_basic_mode=3
game_on=`dbus list ss_acl_mode|cut -d "=" -f 2 | grep 3`
[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] || [ "$ss_basic_udp_sync" == "1" ] || [ "$ss_basic_udp_sync" == "2" ] || [ "$ss_basic_udp_sync" == "3" ] && mangle=1
ss_basic_password=`echo $ss_basic_password|base64_decode`
ARG_V2RAY_PLUGIN=""

if [ "$ss_basic_type" == "0" ];then
	case $ss_basic_method in
		2022-blake3-aes-128-gcm|2022-blake3-aes-256-gcm|2022-blake3-chacha20-poly1305|none) SS2022="Y";;
		*)             SS2022="N";;
	esac
fi
[ "$SS2022" == "Y" ] && ss_basic_type="3"

# 兼容3.8.9及其以下
[ -z "$ss_basic_type" ] && {
	if [ -n "$ss_basic_rss_protocol" ];then
		ss_basic_type="1"
	else
		if [ -n "$ss_basic_koolgame_udp" ];then
			ss_basic_type="2"
		else
			if [ -n "$ss_basic_v2ray_use_json" ];then
				ss_basic_type="3"
			else
				ss_basic_type="0"
			fi
		fi
	fi
}

# 游戏模式仅支持SS协议(ss-libev, type 0)节点：其它协议(SSR/V2Ray/Xray/Trojan/Naive/Hysteria2/
# AnyTLS，含经xray运行的SS2022)跑游戏模式的全量UDP透明代理对路由器负载过重，UDP需求已由
# 「同步UDP与TCP」三档(关闭/仅代理QUIC/全量UDP)覆盖。非SS节点下强制回退并按新状态重算mangle。
if [ "$ss_basic_type" != "0" ];then
	if [ "$ss_basic_mode" == "3" ];then
		echo_date "游戏模式仅支持SS协议节点，已自动回退为大陆白名单模式！UDP需求请使用【同步UDP与TCP】功能。"
		ss_basic_mode=2
		dbus set ss_basic_mode=2
	fi
	if [ -n "$game_on" ];then
		echo_date "访问控制中的游戏模式主机仅支持SS协议节点，其TCP按大陆白名单处理，UDP按【同步UDP与TCP】档位处理。"
		game_on=""
	fi
	# 剩余主机默认模式若为游戏模式同样降级（仅运行时，UI由主模式联动刷新）
	[ "$ss_acl_default_mode" == "3" ] && ss_acl_default_mode=2
	# game_on已清空且mode!=3，mangle仅由「同步UDP与TCP」档位决定
	mangle=""
	[ "$ss_basic_udp_sync" == "1" ] || [ "$ss_basic_udp_sync" == "2" ] || [ "$ss_basic_udp_sync" == "3" ] && mangle=1
fi

# UDP透明入站能力校验："同步UDP与TCP"三档(0关闭/2仅QUIC/1全量)与游戏模式共用此判定，
# 档位即开关，无额外门禁。支持透明UDP的核心：
# - ss-redir系(type 0/1/2: ss-redir/rss-redir/koolgame)：ss-redir原生 -U + mangle TPROXY→3333；
# - Xray系(type 3: v2ray/xray/ss2022, type 4: Trojan/Trojan-Go)：dokodemo拆分入站
#   in-redir(tcp,redirect)+in-tproxy(udp,tproxy带sockopt.tproxy)，见xray_in_redir/xray_in_tproxy，
#   祖传"单inbound tcp,udp缺sockopt.tproxy导致UDP黑洞"已从结构上消除。
# naive/hysteria2/anytls没有透明UDP监听器，自动降级纯TCP，境外QUIC由filter guard拦截促TCP回退（其余境外UDP直连）。
# 失败路径均fail-safe：内核无TPROXY/fwmark冲突由load_tproxy探测后降级mangle，guard兜底，不泄漏不黑洞。
udp_tproxy_supported="0"
case "$ss_basic_type" in
	0|1|2|3) udp_tproxy_supported="1" ;;
	4) case "$ss_basic_trojan_binary" in Trojan|Trojan-Go) udp_tproxy_supported="1" ;; esac ;;
esac
if [ "$udp_tproxy_supported" != "1" ]; then
	if [ "$ss_basic_udp_sync" == "1" ] || [ "$ss_basic_udp_sync" == "2" ] || [ "$ss_basic_udp_sync" == "3" ] || [ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ]; then
		echo_date "当前节点核心(naive/hysteria2/anytls等)无透明UDP入站能力，UDP同步/游戏UDP无法透明代理，已降级纯TCP（境外QUIC由filter层拦截促TCP回退，其余境外UDP直连）。"
	fi
	ss_basic_udp_sync="0"
	mangle=""
fi

get_lan_cidr(){
	netmask=`nvram get lan_netmask`
	local x=${netmask##*255.}
	set -- 0^^^128^192^224^240^248^252^254^ $(( (${#netmask} - ${#x})*2 )) ${x%%.*}
	x=${1%%$3*}
	suffix=$(( $2 + (${#x}/4) ))
	#prefix=`nvram get lan_ipaddr | cut -d "." -f1,2,3`
	echo $lan_ipaddr/$suffix
}

get_wan0_cidr(){
	netmask=`nvram get wan0_netmask`
	local x=${netmask##*255.}
	set -- 0^^^128^192^224^240^248^252^254^ $(( (${#netmask} - ${#x})*2 )) ${x%%.*}
	x=${1%%$3*}
	suffix=$(( $2 + (${#x}/4) ))
	prefix=`nvram get wan0_ipaddr`
	if [ -n "$prefix" -a -n "$netmask" ];then
		echo $prefix/$suffix
	else
		echo ""
	fi
}

get_server_resolver(){
	if [ "$ss_basic_server_resolver" == "1" ];then
		if [ -n "$IFIP_DNS1" ];then
			RESOLVER="$ISP_DNS1"
		else
			RESOLVER="114.114.114.114"
		fi
	fi
	[ "$ss_basic_server_resolver" == "2" ] && RESOLVER="223.5.5.5"
	[ "$ss_basic_server_resolver" == "3" ] && RESOLVER="223.6.6.6"
	[ "$ss_basic_server_resolver" == "4" ] && RESOLVER="114.114.114.114"
	[ "$ss_basic_server_resolver" == "5" ] && RESOLVER="114.114.115.115"
	[ "$ss_basic_server_resolver" == "6" ] && RESOLVER="1.2.4.8"
	[ "$ss_basic_server_resolver" == "7" ] && RESOLVER="210.2.4.8"
	[ "$ss_basic_server_resolver" == "8" ] && RESOLVER="117.50.11.11"
	[ "$ss_basic_server_resolver" == "9" ] && RESOLVER="117.50.22.22"
	[ "$ss_basic_server_resolver" == "10" ] && RESOLVER="180.76.76.76"
	[ "$ss_basic_server_resolver" == "11" ] && RESOLVER="119.29.29.29"
	[ "$ss_basic_server_resolver" == "13" ] && RESOLVER="8.8.8.8"
	[ "$ss_basic_server_resolver" == "12" ] && {
		[ -n "$ss_basic_server_resolver_user" ] && RESOLVER="$ss_basic_server_resolver_user" || RESOLVER="114.114.114.114"
	}
	echo $RESOLVER
}

set_lock(){
	exec 1000>"$LOCK_FILE"
	flock -x 1000
}

unset_lock(){
	flock -u 1000
	rm -rf "$LOCK_FILE"
}

close_in_five(){
	echo_date "插件将在5秒后自动关闭！！"
	sleep 1
	echo_date 5
	sleep 1
	echo_date 4
	sleep 1
	echo_date 3
	sleep 1
	echo_date 2
	sleep 1
	echo_date 1
	sleep 1
	echo_date 0
	dbus set ss_basic_enable="0"
	disable_ss >/dev/null
	echo_date "插件已关闭！！"
	echo_date ======================= 梅林固件 - 【科学上网】 ========================
	unset_lock
	exit
}

# ================================= ss stop ===============================
restore_conf(){
	echo_date 删除ss相关的名单配置文件.
	rm -rf /jffs/configs/dnsmasq.d/gfwlist.conf
	rm -rf /jffs/configs/dnsmasq.d/cdn.conf
	rm -rf /jffs/configs/dnsmasq.d/custom.conf
	rm -rf /jffs/configs/dnsmasq.d/wblist.conf
	rm -rf /jffs/configs/dnsmasq.d/ss_host.conf
	rm -rf /jffs/configs/dnsmasq.d/ss_server.conf
	rm -rf /jffs/configs/dnsmasq.conf.add
	rm -rf /jffs/scripts/dnsmasq.postconf
	rm -rf /tmp/sscdn.conf
	rm -rf /tmp/custom.conf
	rm -rf /tmp/wblist.conf
	rm -rf /tmp/ss_host.conf
	rm -rf /tmp/smartdns.conf
}

kill_process(){
	xray_process=`pidof xray`
	if [ -n "$xray_process" ];then 
		echo_date 关闭XRay进程...
		# 有时候killall杀不了Xray进程，所以用不同方式杀两次
		killall xray >/dev/null 2>&1
		kill -9 "$xray_process" >/dev/null 2>&1
	fi
	ssredir=`pidof ss-redir`
	if [ -n "$ssredir" ];then 
		echo_date 关闭ss-redir进程...
		killall ss-redir >/dev/null 2>&1
	fi

	naive_process=`pidof naive`
	if [ -n "$naive_process" ];then 
		echo_date 关闭naiveproxy进程...
		killall naive >/dev/null 2>&1
		kill -9 "$naive_process" >/dev/null 2>&1
	fi

	hy2_process=`pidof hysteria`
	if [ -n "$hy2_process" ];then 
		echo_date 关闭Hysteria2进程...
		killall hysteria >/dev/null 2>&1
		kill -9 "$hy2_process" >/dev/null 2>&1
	fi

	anytls_process=`pidof anytls`
	if [ -n "$anytls_process" ];then
		echo_date 关闭AnyTLS进程...
		killall anytls >/dev/null 2>&1
		kill -9 "$anytls_process" >/dev/null 2>&1
	fi

	rssredir=`pidof rss-redir`
	if [ -n "$rssredir" ];then 
		echo_date 关闭ssr-redir进程...
		killall rss-redir >/dev/null 2>&1
	fi
	sslocal=`ps | grep -w ss-local | grep -v "grep" | grep -w "23456" | awk '{print $1}'`
	if [ -n "$sslocal" ];then 
		echo_date 关闭ss-local进程:23456端口...
		kill $sslocal  >/dev/null 2>&1
	fi

	ssrlocal=`ps | grep -w rss-local | grep -v "grep" | grep -w "23456" | awk '{print $1}'`
	if [ -n "$ssrlocal" ];then 
		echo_date 关闭ssr-local进程:23456端口...
		kill $ssrlocal  >/dev/null 2>&1
	fi
	sstunnel=`pidof ss-tunnel`
	if [ -n "$sstunnel" ];then 
		echo_date 关闭ss-tunnel进程...
		killall ss-tunnel >/dev/null 2>&1
	fi
	rsstunnel=`pidof rss-tunnel`
	if [ -n "$rsstunnel" ];then 
		echo_date 关闭rss-tunnel进程...
		killall rss-tunnel >/dev/null 2>&1
	fi
	chinadns_process=`pidof chinadns`
	if [ -n "$chinadns_process" ];then 
		echo_date 关闭chinadns2进程...
		killall chinadns >/dev/null 2>&1
	fi
	chinadns1_process=`pidof chinadns1`
	if [ -n "$chinadns1_process" ];then 
		echo_date 关闭chinadns1进程...
		killall chinadns1 >/dev/null 2>&1
	fi
	chinadnsNG_process=$(pidof chinadns-ng)
	if [ -n "$chinadnsNG_process" ]; then
		echo_date 关闭chinadns-ng进程...
		killall chinadns-ng >/dev/null 2>&1
	fi
	cdns_process=`pidof cdns`
	if [ -n "$cdns_process" ];then 
		echo_date 关闭cdns进程...
		killall cdns >/dev/null 2>&1
	fi
	dns2socks_process=`pidof dns2socks`
	if [ -n "$dns2socks_process" ];then 
		echo_date 关闭dns2socks进程...
		killall dns2socks >/dev/null 2>&1
	fi
	smartdns_process=$(pidof smartdns)
	if [ -n "$smartdns_process" ]; then
		echo_date 关闭smartdns进程...
		killall smartdns >/dev/null 2>&1
	fi
	haproxy_process=`pidof haproxy`
	if [ -n "$haproxy_process" ];then 
		echo_date 关闭haproxy进程...
		killall haproxy >/dev/null 2>&1
	fi
	https_dns_proxy_process=`pidof https_dns_proxy`
	if [ -n "$https_dns_proxy_process" ];then 
		echo_date 关闭https_dns_proxy进程...
		killall https_dns_proxy >/dev/null 2>&1
	fi
	haveged_process=`pidof haveged`
	if [ -n "$haveged_process" ];then 
		echo_date 关闭haveged进程...
		killall haveged >/dev/null 2>&1
	fi
}

# ================================= ss prestart ===========================
ss_pre_start(){
	lb_enable=`dbus get ss_lb_enable`
	if [ "$lb_enable" == "1" ];then
		echo_date ---------------------- 【科学上网】 启动前触发脚本 ----------------------
		if [ `dbus get ss_basic_server | grep -o "127.0.0.1"` ] && [ `dbus get ss_basic_port` == `dbus get ss_lb_port` ];then
			echo_date ss启动前触发:触发启动负载均衡功能！
			#start haproxy
			sh /koolshare/scripts/ss_lb_config.sh
		else
			echo_date ss启动前触发:未选择负载均衡节点，不触发负载均衡启动！
		fi
	else
		if [ `dbus get ss_basic_server | grep -o "127.0.0.1"` ] && [ `dbus get ss_basic_port` == `dbus get ss_lb_port` ];then
			echo_date ss启动前触发【警告】：你选择了负载均衡节点，但是负载均衡开关未启用！！
		#else
			#echo_date ss启动前触发：你选择了普通节点，不触发负载均衡启动！
		fi
	fi
}
# ================================= ss start ==============================

resolv_server_ip(){
	if [ "$ss_basic_type" == "3" ] && [ "$ss_basic_v2ray_use_json" == "1" ];then
		#echo_date "你使用的v2ray json配置，请自行将v2ray服务器ip地址添加到IP/CIDR白名单！"
		return 1
	else
		IFIP=`echo $ss_basic_server|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
		if [ -z "$IFIP" ];then
			# 服务器地址强制由114解析，以免插件还未开始工作而导致解析失败
			echo "server=/$ss_basic_server/$(get_server_resolver)#53" > /jffs/configs/dnsmasq.d/ss_server.conf
			echo_date 尝试解析节点服务器的ip地址，DNS：$(get_server_resolver)
			server_ip=`nslookup "$ss_basic_server" $(get_server_resolver) | sed '1,4d' | awk '{print $3}' | grep -v :|awk 'NR==1{print}'`
			if [ "$?" == "0" ];then
				server_ip=`echo $server_ip|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
			else
				echo_date 节点服务器域名解析失败！
				echo_date 尝试用resolveip方式解析，DNS：系统
				server_ip=`resolveip -4 -t 2 $ss_basic_server|awk 'NR==1{print}'`
				if [ "$?" == "0" ];then
			    	server_ip=`echo $server_ip|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
				fi
			fi

			if [ -n "$server_ip" ];then
				echo_date 节点服务器的ip地址解析成功：$server_ip
				# 解析并记录一次ip，方便插件触发重启设定工作
				echo "address=/$ss_basic_server/$server_ip" > /tmp/ss_host.conf
				# 去掉此功能，以免ip发生变更导致问题，或者影响域名对应的其它二级域名
				#ln -sf /tmp/ss_host.conf /jffs/configs/dnsmasq.d/ss_host.conf
				ss_basic_server="$server_ip"
				ss_basic_server_ip="$server_ip"
				dbus set ss_basic_server_ip="$server_ip"
			else
				dbus remove ss_basic_server_ip
				echo_date 节点服务器的ip地址解析失败，将由ss-redir自己解析.
			fi
		else
			ss_basic_server_ip="$ss_basic_server"
			dbus set ss_basic_server_ip=$ss_basic_server
			echo_date 检测到你的节点服务器已经是IP格式：$ss_basic_server,跳过解析... 
		fi
	fi
}

ss_arg(){
	# v2ray-plugin
	if [ -n "$ss_basic_ss_v2ray_plugin_opts" ];then
		if [ "$ss_basic_ss_v2ray_plugin" == "2" ];then
			ARG_V2RAY_PLUGIN="--plugin obfs-local --plugin-opts $ss_basic_ss_v2ray_plugin_opts"	
		else
			ARG_V2RAY_PLUGIN=""
		fi
	fi
}
# create shadowsocks config file...
create_ss_json(){
	if [ "$ss_basic_type" == "0" ];then
		echo_date 创建SS配置文件到$CONFIG_FILE
		cat > $CONFIG_FILE <<-EOF
			{
			    "server":"$ss_basic_server",
			    "server_port":$ss_basic_port,
			    "local_address":"0.0.0.0",
			    "local_port":3333,
			    "password":"$ss_basic_password",
			    "timeout":600,
			    "method":"$ss_basic_method"
			}
		EOF
	elif [ "$ss_basic_type" == "1" ];then
		echo_date 创建SSR配置文件到$CONFIG_FILE
		cat > $CONFIG_FILE <<-EOF
			{
			    "server":"$ss_basic_server",
			    "server_port":$ss_basic_port,
			    "local_address":"0.0.0.0",
			    "local_port":3333,
			    "password":"$ss_basic_password",
			    "timeout":600,
			    "protocol":"$ss_basic_rss_protocol",
			    "protocol_param":"$ss_basic_rss_protocol_param",
			    "obfs":"$ss_basic_rss_obfs",
			    "obfs_param":"$ss_basic_rss_obfs_param",
			    "method":"$ss_basic_method"
			}
		EOF
	fi
}

get_type_name() {
	case "$1" in
		0)
			echo "shadowsocks-libev"
		;;
		1)
			echo "shadowsocksR-libev"
		;;
		2)
			echo "koolgame"
		;;
		3)
			echo "v2ray"
		;;
		4)
			echo "trojan"
		;;
		5)
			echo "naive"
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
			echo "chinadns1"
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

start_sslocal(){
	if [ "$ss_basic_type" == "1" ];then
		echo_date 开启ssr-local，提供socks5代理端口：23456
		rss-local -l 23456 -c $CONFIG_FILE -u -f /var/run/sslocal1.pid >/dev/null 2>&1
	elif  [ "$ss_basic_type" == "0" ];then
		echo_date 开启ss-local，提供socks5代理端口：23456
		if [ "$ss_basic_ss_v2ray_plugin" == "0" ];then
			ss-local -l 23456 -c $CONFIG_FILE -u -f /var/run/sslocal1.pid >/dev/null 2>&1
		else
			ss-local -l 23456 -c $CONFIG_FILE $ARG_V2RAY_PLUGIN -u -f /var/run/sslocal1.pid >/dev/null 2>&1
		fi
	elif [ "$ss_basic_type" == "4" ] && [ "$ss_basic_trojan_binary" == "Trojan-Go" ]; then
		echo_date Trojan-Go 使用 Xray 内置 socks5 入站端口：23456
	elif [ "$ss_basic_type" == "5" ] ; then
		echo_date 开启Naive Proxy，提供socks代理端口：23456 
		naive $NAIVE2_CONFIG_FILE >/dev/null 2>&1 &		
	fi
}

start_dns(){
	if [ "$ss_basic_mode" == "6" -a "$ss_foreign_dns" != "8" ];then
		ss_foreign_dns="8"
		dbus set ss_foreign_dns="8"
	fi
	
	# Start ss-local
	# [ "$ss_basic_type" != "3" ] && start_sslocal
	
	# Start cdns
	if [ "$ss_foreign_dns" == "1" ];then
		echo_date 开启cdns，用于dns解析...
		cdns -c /koolshare/ss/rules/cdns.json > /dev/null 2>&1 &
	fi

	# Start chinadns2
	if [ "$ss_foreign_dns" == "2" ];then
		echo_date 开启chinadns2，用于dns解析...
		clinet_ip="114.114.114.114"
		public_ip=`nvram get wan0_realip_ip`
		if [ -z "$public_ip" ];then
			# 路由公网ip为空则获取
			public_ip=`curl --connect-timeout 1 --retry 0 --max-time 1 -sk 'http://members.3322.org/dyndns/getip'`
			if [ "$?" == "0" ] && [ -n "$public_ip" ];then
				# 获取成功
				echo_date 你的公网ip地址是：$public_ip
				dbus set ss_basic_publicip="$public_ip"
				clinet_ip="$public_ip"
			else
				# 获取失败，则自动为114
				[ -n "$ss_basic_publicip" ] && clinet_ip="$ss_basic_publicip"
			fi
		else
			# 获取失败，则自动为114
			clinet_ip="$public_ip"
		fi

		if [ -n "$ss_basic_server_ip" ];then
			# 用chnroute去判断SS服务器在国内还是在国外
			ipset test chnroute $ss_basic_server_ip > /dev/null 2>&1
			if [ "$?" != "0" ];then
				# ss服务器是国外IP
				ss_real_server_ip="$ss_basic_server_ip"
			else
				# ss服务器是国内ip （可能用了国内中转，那么用谷歌dns ip地址去作为国外edns标签）
				ss_real_server_ip="8.8.8.8"
			fi
		else
			# ss服务器可能是域名且没有正确解析
			ss_real_server_ip="8.8.8.8"
		fi
		chinadns -p $DNSF_PORT -s $ss_chinadns_user -e $clinet_ip,$ss_real_server_ip -c /koolshare/ss/rules/chnroute.txt >/dev/null 2>&1 &
	fi
	
	# Start DNS2SOCKS (default)
	if [ "$ss_foreign_dns" == "3" ] || [ -z "$ss_foreign_dns" ];then
		[ -z "$ss_foreign_dns" ] && dbus set ss_foreign_dns="3"
		start_sslocal
		echo_date 开启dns2socks，用于dns解析...
		dns2socks 127.0.0.1:23456 "$ss_dns2socks_user" 127.0.0.1:$DNSF_PORT > /dev/null 2>&1 &
	fi
	
	# Start ss-tunnel
	if [ "$ss_foreign_dns" == "4" ];then
		if [ "$ss_basic_type" == "1" ];then
			echo_date 开启ssr-tunnel，用于dns解析...
			rss-tunnel -c $CONFIG_FILE -l $DNSF_PORT -L $ss_sstunnel_user -u -f /var/run/sstunnel.pid >/dev/null 2>&1
		elif [ "$ss_basic_type" == "0" ];then
			echo_date 开启ss-tunnel，用于dns解析...
			if [ "$ss_basic_ss_v2ray_plugin" == "0" ];then
				ss-tunnel -c $CONFIG_FILE -l $DNSF_PORT -L $ss_sstunnel_user -u -f /var/run/sstunnel.pid >/dev/null 2>&1
			else
				ss-tunnel -c $CONFIG_FILE -l $DNSF_PORT -L $ss_sstunnel_user $ARG_V2RAY_PLUGIN -u -f /var/run/sstunnel.pid >/dev/null 2>&1
			fi
		elif [ "$ss_basic_type" == "3" ] || [ "$ss_basic_type" == "4" ];then
			echo_date V2Ray 或 Trojan 下不支持 ss-tunnel，改用 dns2socks！
			dbus set ss_foreign_dns=3
			start_sslocal
			echo_date 开启dns2socks，用于dns解析...
			dns2socks 127.0.0.1:23456 "$ss_dns2socks_user" 127.0.0.1:$DNSF_PORT > /dev/null 2>&1 &
		fi
	fi
	
	#start chinadns1
	if [ "$ss_foreign_dns" == "5" ]; then
		# 当国内SmartDNS和国外chiandns1冲突
		if [ "$ss_dns_china" == "13" -a "$ss_foreign_dns" == "5" ]; then
			echo_date "！！中国DNS选择SmartDNS和外国DNS选择chiandns1冲突，将外国DNS默认改为dns2socks！！"
			ss_foreign_dns="3"
			dbus set ss_foreign_dns="3"
			start_sslocal
			echo_date 开启dns2socks，用于chinadns1上游...
			dns2socks 127.0.0.1:23456 "$ss_dns2socks_user" 127.0.0.1:$DNSF_PORT >/dev/null 2>&1 &
		else
			start_sslocal
			echo_date 开启dns2socks，用于chinadns1上游...
			dns2socks 127.0.0.1:23456 "$ss_chinadns1_user" 127.0.0.1:1055 >/dev/null 2>&1 &
			echo_date 开启chinadns1，用于dns解析...
			chinadns1 -p $DNSF_PORT -s $CDN,127.0.0.1:1055 -d -c /koolshare/ss/rules/chnroute.txt >/dev/null 2>&1 &
		fi
	fi

	#start chinadns_ng
	if [ "$ss_foreign_dns" == "10" ]; then
		start_sslocal
		echo_date 开启dns2socks，用于chinadns-ng的国外上游...
		dns2socks 127.0.0.1:23456 "$ss_chinadns1_user" 127.0.0.1:1055 >/dev/null 2>&1 &
		sed -e '/^server=/d' -e 's/ipset=\/.//g' -e 's/\/gfwlist//g' /koolshare/ss/rules/gfwlist.conf > /tmp/gfwlist.txt
		chinadns-ng -N -l ${DNSF_PORT} -c ${CDN}#${DNSC_PORT} -t 127.0.0.1#1055 -g /tmp/gfwlist.txt -m /koolshare/ss/rules/cdn.txt -M >/dev/null 2>&1 &
	fi

	#start https_dns_proxy
	if [ "$ss_foreign_dns" == "6" ];then
		echo_date 开启https_dns_proxy，用于dns解析...
		if [ -n "$ss_basic_server_ip" ];then
			# 用chnroute去判断SS服务器在国内还是在国外
			ipset test chnroute $ss_basic_server_ip > /dev/null 2>&1
			if [ "$?" != "0" ];then
				# ss服务器是国外IP
				ss_real_server_ip="$ss_basic_server_ip"
			else
				# ss服务器是国内ip （可能用了国内中转，那么用谷歌dns ip地址去作为国外edns标签）
				ss_real_server_ip="8.8.8.8"
			fi
		else
			# ss服务器可能是域名且没有正确解析
			ss_real_server_ip="8.8.8.8"
		fi
		https_dns_proxy -u nobody -p 7913 -b 8.8.8.8,1.1.1.1,8.8.4.4,1.0.0.1,145.100.185.15,145.100.185.16,185.49.141.37 -e $ss_real_server_ip/16 -r "https://cloudflare-dns.com/dns-query?ct=application/dns-json&" -d
	fi
	
	# start v2ray DNSF_PORT
	if [ "$ss_foreign_dns" == "7" ];then
		if [ "$ss_basic_type" == "3" ];then
			return 0
		else
			echo_date $(get_type_name $ss_basic_type)下不支持v2ray dns，改用dns2socks！
			dbus set ss_foreign_dns=3
			start_sslocal
			echo_date 开启dns2socks，用于dns解析...
			dns2socks 127.0.0.1:23456 "$ss_dns2socks_user" 127.0.0.1:$DNSF_PORT > /dev/null 2>&1 &
		fi
	fi

# 开启SmartDNS
	if [ "$ss_dns_china" == "13" ] && [ "$ss_foreign_dns" == "9" ]; then
		# 国内国外都启用SmartDNS （此情况下，如果是gfwlist模式则不用cdn.conf；如果是大陆白名单模式也不需要使用cdn.conf）

		echo_date "开启SmartDNS，用于DNS解析..."
		#if [ "$(nvram get ipv6_service)" == "disabled" ]; then
		#	sed 's/# force-AAAA-SOA yes/force-AAAA-SOA yes/g' /koolshare/ss/rules/smartdns_template.conf > /tmp/smartdns.conf
		#	sed -i '/^#/d /^$/d' /tmp/smartdns.conf
		#else
			sed '/^#/d /^$/d' /koolshare/ss/rules/smartdns_template.conf > /tmp/smartdns.conf
		#fi
		smartdns -c /tmp/smartdns.conf >/dev/null 2>&1 &
		start_sslocal
	elif [ "$ss_dns_china" == "13" ] && [ "$ss_foreign_dns" != "9" ]; then
		# 国内启用SmartDNS，国外不启用SmartDNS （此情况下，如果是gfwlist模式则不用cdn.conf；如果是大陆白名单模式则是根据国外DNS的选择而决定是否使用cdn.conf）
		echo_date "开启SmartDNS，用于DNS解析..."
		#if [ "$(nvram get ipv6_service)" == "disabled" ]; then
		#	sed 's/# force-AAAA-SOA yes/force-AAAA-SOA yes/g' /koolshare/ss/rules/smartdns_template.conf > /tmp/smartdns.conf
		#	sed -i '/^#/d /^$/d /foreign/d' /tmp/smartdns.conf
		#else
			sed '/^#/d /^$/d /foreign/d' /koolshare/ss/rules/smartdns_template.conf > /tmp/smartdns.conf
		#fi
		smartdns -c /tmp/smartdns.conf >/dev/null 2>&1 &
	elif [ "$ss_dns_china" != "13" ] && [ "$ss_foreign_dns" == "9" ]; then
		# 国内不启用SmartDNS，国外启用SmartDNS （此情况下，如果是gfwlist模式则不用cdn.conf；如果是大陆白名单模式则需要使用cdn.conf）
		echo_date "开启SmartDNS，用于DNS解析..."
		#if [ "$(nvram get ipv6_service)" == "disabled" ]; then
		#	sed 's/# force-AAAA-SOA yes/force-AAAA-SOA yes/g' /koolshare/ss/rules/smartdns_template.conf > /tmp/smartdns.conf
		#	sed -i '/^#/d /^$/d /china/d' /tmp/smartdns.conf
		#else
			sed '/^#/d /^$/d /china/d' /koolshare/ss/rules/smartdns_template.conf > /tmp/smartdns.conf
		#fi
		smartdns -c /tmp/smartdns.conf >/dev/null 2>&1 &
		start_sslocal
	fi

	# direct
	if [ "$ss_foreign_dns" == "8" ];then
		if [ "$ss_basic_mode" == "6" ];then
			echo_date 回国模式，国外dns采用直连方案。
		else
			echo_date 非回国模式，国外dns不能使用，自动切换到dns2socks方案。
			dbus set ss_foreign_dns=3
			start_sslocal
			echo_date 开启dns2socks，用于dns解析...
			dns2socks 127.0.0.1:23456 "$ss_dns2socks_user" 127.0.0.1:$DNSF_PORT > /dev/null 2>&1 &
		fi
	fi
	
}
#--------------------------------------------------------------------------------------

detect_domain(){
	domain1=`echo $1|grep -E "^https://|^http://|www|/"`
	domain2=`echo $1|grep -E "\."`
	if [ -n "$domain1" ] || [ -z "$domain2" ];then
		return 1
	else
		return 0
	fi
}

create_dnsmasq_conf(){
	if [ "$ss_dns_china" == "1" ];then
		if [ "$ss_basic_mode" == "6" ];then
			# 使用回国模式的时候，ISP dns是国外的，所以这里直接用114取代
			CDN="114.114.114.114"
		else
			if [ -n "$IFIP_DNS1" ];then
				# 用chnroute去判断运营商DNS是否为局域网(国外)ip地址，有些二级路由的是局域网ip地址，会被ChinaDNS 判断为国外dns服务器，这个时候用114取代之
				ipset test chnroute $IFIP_DNS1 > /dev/null 2>&1
				if [ "$?" != "0" ];then
					# 运营商DNS：ISP_DNS1是局域网(国外)ip
					CDN="114.114.114.114"
				else
					# 运营商DNS：ISP_DNS1是国内ip
					CDN="$ISP_DNS1"
				fi
			else
				# 运营商DNS：ISP_DNS1不是ip格式，用114取代之
				CDN="114.114.114.114"
			fi
		fi
	fi
	[ "$ss_dns_china" == "2" ] && CDN="223.5.5.5"
	[ "$ss_dns_china" == "3" ] && CDN="223.6.6.6"
	[ "$ss_dns_china" == "4" ] && CDN="114.114.114.114"
	[ "$ss_dns_china" == "5" ] && CDN="114.114.115.115"
	[ "$ss_dns_china" == "6" ] && CDN="1.2.4.8"
	[ "$ss_dns_china" == "7" ] && CDN="210.2.4.8"
	[ "$ss_dns_china" == "8" ] && CDN="117.50.11.11"
	[ "$ss_dns_china" == "9" ] && CDN="117.50.22.22"
	[ "$ss_dns_china" == "10" ] && CDN="180.76.76.76"
	[ "$ss_dns_china" == "11" ] && CDN="119.29.29.29"
	[ "$ss_dns_china" == "12" ] && {
		[ -n "$ss_dns_china_user" ] && CDN="$ss_dns_china_user" || CDN="114.114.114.114"
	}
	if [ "$ss_dns_china" == "13" ];then
		CDN="127.0.0.1"
		DNSC_PORT=5335
	fi
	# delete pre settings
	rm -rf /tmp/sscdn.conf
	rm -rf /tmp/custom.conf
	rm -rf /tmp/wblist.conf
	rm -rf /tmp/gfwlist.conf
	rm -rf /tmp/gfwlist.txt
	rm -rf /jffs/configs/dnsmasq.d/custom.conf
	rm -rf /jffs/configs/dnsmasq.d/wblist.conf
	rm -rf /jffs/configs/dnsmasq.d/cdn.conf
	rm -rf /jffs/configs/dnsmasq.d/gfwlist.conf
	rm -rf /jffs/scripts/dnsmasq.postconf
	rm -rf /tmp/smartdns.conf
	
	# custom dnsmasq settings by user
	if [ -n "$ss_dnsmasq" ];then
		echo_date 添加自定义dnsmasq设置到/tmp/custom.conf
		echo "$ss_dnsmasq" | base64_decode | sort -u >> /tmp/custom.conf
	fi

	# these sites need to go ss inside router
	if [ "$ss_basic_mode" != "6" ];then
		echo "#for router itself" >> /tmp/wblist.conf
		echo "server=/.google.com.tw/127.0.0.1#7913" >> /tmp/wblist.conf
		echo "ipset=/.google.com.tw/router" >> /tmp/wblist.conf
		echo "server=/dns.google.com/127.0.0.1#7913" >> /tmp/wblist.conf
		echo "ipset=/dns.google.com/router" >> /tmp/wblist.conf
		echo "server=/.github.com/127.0.0.1#7913" >> /tmp/wblist.conf
		echo "ipset=/.github.com/router" >> /tmp/wblist.conf
		echo "server=/.github.io/127.0.0.1#7913" >> /tmp/wblist.conf
		echo "ipset=/.github.io/router" >> /tmp/wblist.conf
		echo "server=/.raw.githubusercontent.com/127.0.0.1#7913" >> /tmp/wblist.conf
		echo "ipset=/.raw.githubusercontent.com/router" >> /tmp/wblist.conf
		echo "server=/.adblockplus.org/127.0.0.1#7913" >> /tmp/wblist.conf
		echo "ipset=/.adblockplus.org/router" >> /tmp/wblist.conf
		echo "server=/.entware.net/127.0.0.1#7913" >> /tmp/wblist.conf
		echo "ipset=/.entware.net/router" >> /tmp/wblist.conf
		echo "server=/.apnic.net/127.0.0.1#7913" >> /tmp/wblist.conf
		echo "ipset=/.apnic.net/router" >> /tmp/wblist.conf
	fi
	
	# append white domain list, not through ss
	wanwhitedomain=$(echo $ss_wan_white_domain | base64_decode)
	if [ -n "$ss_wan_white_domain" ];then
		echo_date 应用域名白名单
		echo "#for white_domain" >> /tmp/wblist.conf
		for wan_white_domain in $wanwhitedomain
		do
			detect_domain "$wan_white_domain"
			if [ "$?" == "0" ];then
				# 回国模式下，用外国DNS，否则用中国DNS。
				if [ "$ss_basic_mode" != "6" ];then
					echo "$wan_white_domain" | sed "s/^/server=&\/./g" | sed "s/$/\/$CDN#53/g" >> /tmp/wblist.conf
					echo "$wan_white_domain" | sed "s/^/ipset=&\/./g" | sed "s/$/\/white_list/g" >> /tmp/wblist.conf
				else
					echo "$wan_white_domain" | sed "s/^/server=&\/./g" | sed "s/$/\/$ss_direct_user/g" >> /tmp/wblist.conf
					echo "$wan_white_domain" | sed "s/^/ipset=&\/./g" | sed "s/$/\/white_list/g" >> /tmp/wblist.conf
				fi
			else
				echo_date ！！检测到域名白名单内的【"$wan_white_domain"】不是域名格式！！此条将不会添加！！
			fi
		done
	fi
	
	# 非回国模式下，apple 和 microsoft需要中国cdn
	if [ "$ss_basic_mode" != "6" ]; then
		echo "#for special site (Mandatory China DNS)" >>/tmp/wblist.conf
		for wan_white_domain2 in "apple.com" "microsoft.com" "dns.msftncsi.com"; do
			echo "$wan_white_domain2" | sed "s/^/server=&\/./g" | sed "s/$/\/$CDN#$DNSC_PORT/g" >>/tmp/wblist.conf
			echo "$wan_white_domain2" | sed "s/^/ipset=&\/./g" | sed "s/$/\/white_list/g" >>/tmp/wblist.conf
		done
	fi

	# append black domain list, through ss
	wanblackdomain=$(echo $ss_wan_black_domain | base64_decode)
	if [ -n "$ss_wan_black_domain" ];then
		echo_date 应用域名黑名单
		echo "#for black_domain" >>/tmp/wblist.conf
		for wan_black_domain in $wanblackdomain; do
			detect_domain "$wan_black_domain"
			if [ "$?" == "0" ]; then
				if [ "$ss_basic_mode" != "6" ]; then
					echo "$wan_black_domain" | sed "s/^/server=&\/./g" | sed "s/$/\/127.0.0.1#$DNSF_PORT/g" >>/tmp/wblist.conf
					echo "$wan_black_domain" | sed "s/^/ipset=&\/./g" | sed "s/$/\/black_list/g" >>/tmp/wblist.conf
				else
					echo "$wan_black_domain" | sed "s/^/server=&\/./g" | sed "s/$/\/$CDN#$DNSC_PORT/g" >>/tmp/wblist.conf
					echo "$wan_black_domain" | sed "s/^/ipset=&\/./g" | sed "s/$/\/black_list/g" >>/tmp/wblist.conf
				fi
			else
				echo_date ！！检测到域名黑名单内的【"$wan_black_domain"】不是域名格式！！此条将不会添加！！
			fi
		done
	fi

	# 使用cdn.conf和gfwlist的策略
	# cdn.conf的作用：cdn.conf内包含了4万多条国内的网站，基本包含了普通人的所有国内上网需求，使用cdn.conf会让里面指定的网站强制走中国DNS的解析
	# gfwlist的主用：gfwlist内包含了已知的被墙网站，大部分人的翻墙需求（google, youtube, netflix, etc...），能得到满足，使用gfwlist会让里面指定的网站走国外的dns解析（墙内出去需要防污染，墙外进来直连即可）
	# 1.1 在国内优先模式下（在墙内出去），dnsmasq的全局dns是中国的，所以不需要cdn.conf，此时对路由的dnsmasq的负担也较小，但是为了保证国外被墙的网站解析无污染，使用gfwlist来解析国外被墙网站（此处需要防污染的软件来获得正确dns，如dns2socks的转发方式，chinadns的过滤方式，cdns的edns的特殊获取方式等），这样如果遇到gfwlist漏掉的，或者上普通未被墙的国外网站可能速度较慢；
	# 1.2 在国内优先模式下（在墙外回来），dnsmasq的全局dns是中国的，所以不需要cdn.conf，此时对路由的dnsmasq的负担也较小，但是为了保证国外被墙的网站解析无污染，使用gfwlist来解析国外被墙网站（因为本来身在国外，直连国外当地dns即可，如果转发，则会让这些请求在国内vps上去做，导致污染，如果使用chinadns过滤，则无需指定通过转发的），但是这样会导致很多国外网站的访问是从国内的vps发起的，导致一些国外网站的体验不好
	
	# 2.1 在国外优先的模式下（在墙内出去），dnsmasq的全局dns是国外的（此处需要使用防污染的软件来获得正确的dns），但是要保证国内的网站的解析效果，只好引入cdn.conf，此时路由的负担也会较大，这样国内的网站解析效果完全靠cdn.tx，一般来说能普通人的所有国内上网需求
	# 2.2 在国外优先的模式下（在墙外回来），dnsmasq的全局dns是国外的（此处只需要直连国外当地的dns服务器即可！），但是要保证国内的网站的解析效果，只好引入cdn.conf，此时路由的负担也会较大，这样国内的网站解析效果完全靠cdn.conf，一般来说翻墙回来都是看国内影视剧和音乐等需要，cdn.conf应该能够满足。

	# 总结
	# 国内优先模式，使用gfwlist，不用cdn.conf，国内cdn好，国外cdn差，路由器负担小
	# 国外优先模式，不用gfwlist，使用cdn.conf，国内cdn好，国外cdn好，路由器负担大（dns2socks ss-tunnel，cdns）
	# 国外优先模式，如果dns自带了国内cdn，不用gfwlist，不用cdn.conf，国内cdn好，国外cdn好，路由器负小（chinadns1 chinadns2）

	# 使用场景 
	# 1.1 gfwlist模式：该模式的特点就是只有gfwlist内的网站走代理，所以dns部分也应该是相同的策略，即国内优先模式。
	# 1.2 在gfwlist模式下，如果访问控制内有主机走chnroute模式，那么怎么办？也许这台主机希望获得更好的国外访问效果？原来ks的策略是如果检测到这种情况则切换到国外优先，并且保持gfwlist存在（因为主模式下的主机在iptables内必须匹配gfwlist的ipset）；
	# 2.1 chnroute模式：除了国内的IP不走代理，其余都应该走代理，即使是某个国外的网站未被墙，因为用户的初衷是为了获得更好的国外访问效果才使用chnroute模式，所以dns部分也应该是类似的策略，即国外优先模式：
	# 2.2 在chnroute模式下，如果访问控制内有主机走gfwlist模式，那么怎么办？这台机器应该指望着获得更好的国内访问效果？原来ks的策略是如果检测这种情况，保持国外优先不变的情况下，再引入gfwlist（因为这些gfwlist的主机在iptables内必须匹配gfwlist的ipset）；
	# 对于访问控制存在上面的情况，都是向着国外优先

	# 指定策略
	# 1 一刀切的自动方案：和原KS方案相同，不过对于回国模式需要做出修改，国外的dns不能由软件转发等，直连就行了（fix）
	# 2 用户自己选择，一刀切的方案很多情况下都会走到国外优先上去，这对路由器的负担是很大的，而多数人的上网需求国内优先就足够了，一些人需要国外访问快（代理够快的情况下），可以自行选择国外优先（todo）
	# 3 所以最终保留自动方案，增加国内优先和国外优先的选择方案（todo）

	if [ "$ss_basic_mode" == "6" ];then
		# 回国模式中，因为国外DNS无论如何都不会污染的，所以采取的策略是直连就行，默认国内优先即可
		echo_date 自动判断在回国模式中使用国内优先模式，不加载cdn.conf
	else
		if [ "$ss_basic_mode" == "1" -a -z "$chn_on" -a -z "$all_on" ] || [ "$ss_basic_mode" == "6" ];then
			# gfwlist模式的时候，且访问控制主机中不存在 大陆白名单模式 游戏模式 全局模式，则使用国内优先模式
			# 回国模式下自动判断使用国内优先
			echo_date 自动判断使用国内优先模式，不加载cdn.conf
		else
			# 其它情况，均使用国外优先模式，以下区分是否加载cdn.conf
			# if [ "$ss_foreign_dns" == "2" ] || [ "$ss_foreign_dns" == "5" ] || [ "$ss_foreign_dns" == "9" -a "$ss_dns_china" == "13" ]; then
			if [ "$ss_foreign_dns" == "2" -o "$ss_foreign_dns" == "5" -a "$ss_dns_china" != "13" -o "$ss_foreign_dns" == "10" ]; then
				# 因为chinadns1 chinadns2自带国内cdn，所以也不需要cdn.conf
				echo_date 自动判断dns解析使用国外优先模式...
				echo_date 国外解析方案【$(get_dns_name $ss_foreign_dns)】自带国内cdn，无需加载cdn.conf，路由器开销小...
			else
				echo_date 自动判断dns解析使用国外优先模式...
				echo_date 国外解析方案【$(get_dns_name $ss_foreign_dns)】，需要加载cdn.conf提供国内cdn...
				echo_date 提示：cdn.conf规则量较大，如CPU占用偏高可考虑【替换为dnsmasq-fastlookup】（详见Web端说明）。
				# cdn列表按"cdn.txt内容md5+加速DNS"缓存于/tmp：同一次开机内切换节点/重启插件直接复用，
				# 免去11万+行的sed/sort/去重开销(ARMv7上数秒)；cdn.txt更新或更换加速DNS后自动重新生成。
				CDN_CACHE_KEY="$(md5sum /koolshare/ss/rules/cdn.txt 2>/dev/null | awk '{print $1}')_${CDN}_${DNSC_PORT}"
				if [ -s /tmp/sscdn.cache ] && [ "$(cat /tmp/sscdn.cache.key 2>/dev/null)" == "$CDN_CACHE_KEY" ];then
					echo_date 复用本次开机已生成的cdn加速列表缓存，加速用的dns：$CDN
				else
					echo_date 生成cdn加速列表到/tmp/sscdn.cache，加速用的dns：$CDN
					echo "#for china site CDN acclerate" > /tmp/sscdn.cache
					cat /koolshare/ss/rules/cdn.txt | sed "s/^/server=&\/./g" | sed "s/$/\/&$CDN#$DNSC_PORT/g" | sort | awk '{if ($0!=line) print;line=$0}' >> /tmp/sscdn.cache
					echo "$CDN_CACHE_KEY" > /tmp/sscdn.cache.key
				fi
				ln -sf /tmp/sscdn.cache /tmp/sscdn.conf
			fi
		fi
	fi

	#ln_conf
	if [ -f /tmp/custom.conf ];then
		#echo_date 创建域自定义dnsmasq配置文件软链接到/jffs/configs/dnsmasq.d/custom.conf
		ln -sf /tmp/custom.conf /jffs/configs/dnsmasq.d/custom.conf
	fi
	if [ -f /tmp/wblist.conf ];then
		#echo_date 创建域名黑/白名单软链接到/jffs/configs/dnsmasq.d/wblist.conf
		ln -sf /tmp/wblist.conf /jffs/configs/dnsmasq.d/wblist.conf
	fi
	
	if [ -f /tmp/sscdn.conf ];then
		#echo_date 创建cdn加速列表软链接/jffs/configs/dnsmasq.d/cdn.conf
		ln -sf /tmp/sscdn.conf /jffs/configs/dnsmasq.d/cdn.conf
	fi

	if [ "$ss_basic_mode" == "1" ];then
		echo_date 创建gfwlist的软连接到/jffs/etc/dnsmasq.d/文件夹.
		ln -sf /koolshare/ss/rules/gfwlist.conf /jffs/configs/dnsmasq.d/gfwlist.conf
	elif [ "$ss_basic_mode" == "2" ] || [ "$ss_basic_mode" == "3" ];then
		if [ -n "$gfw_on" ];then
			echo_date 创建gfwlist的软连接到/jffs/etc/dnsmasq.d/文件夹.
			ln -sf /koolshare/ss/rules/gfwlist.conf /jffs/configs/dnsmasq.d/gfwlist.conf
		fi
	elif [ "$ss_basic_mode" == "6" ];then
		# 回国模式下默认方案是国内优先，所以gfwlist里的网站不能由127.0.0.1#7913来解析了，应该是国外当地直连
		if [ -n "`echo $ss_direct_user|grep :`" ];then
			echo_date 国外直连dns设定格式错误，将自动更正为8.8.8.8#53.
			ss_direct_user="8.8.8.8#53"
			dbus set ss_direct_user="8.8.8.8#53"
		fi
		echo_date 创建回国模式专用gfwlist的软连接到/jffs/etc/dnsmasq.d/文件夹.
		[ -z "$ss_direct_user" ] && ss_direct_user="8.8.8.8#53"
		cat /koolshare/ss/rules/gfwlist.conf|sed "s/127.0.0.1#7913/$ss_direct_user/g" > /tmp/gfwlist.conf
		ln -sf /tmp/gfwlist.conf /jffs/configs/dnsmasq.d/gfwlist.conf
	fi

	#echo_date 创建dnsmasq.postconf软连接到/jffs/scripts/文件夹.
	[ ! -L "/jffs/scripts/dnsmasq.postconf" ] && ln -sf /koolshare/ss/rules/dnsmasq.postconf /jffs/scripts/dnsmasq.postconf
}

start_haveged(){
	echo_date "启动haveged，为系统提供更多的可用熵！"
	haveged -w 1024 >/dev/null 2>&1
}

auto_start(){
	# nat_auto_start
	mkdir -p /jffs/scripts
	# creating iptables rules to nat-start
	if [ ! -f /jffs/scripts/nat-start ]; then
	cat > /jffs/scripts/nat-start <<-EOF
		#!/bin/sh
		/usr/bin/onnatstart.sh
		
		EOF
	fi
	
	writenat=$(cat /jffs/scripts/nat-start | grep "ssconfig")
	if [ -z "$writenat" ];then
		echo_date 添加nat-start触发事件...用于ss的nat规则重启后或网络恢复后的加载...
		sed -i '2a sh /koolshare/ss/ssconfig.sh' /jffs/scripts/nat-start
		chmod +x /jffs/scripts/nat-start
	fi

	# wan_auto_start
	# Add service to auto start
	if [ ! -f /jffs/scripts/wan-start ]; then
		cat > /jffs/scripts/wan-start <<-EOF
			#!/bin/sh
			/usr/bin/onwanstart.sh
			
			EOF
	fi
	
	startss=$(cat /jffs/scripts/wan-start | grep "/koolshare/scripts/ss_config.sh")
	if [ -z "$startss" ];then
		echo_date 添加wan-start触发事件...用于ss的各种程序的开机启动...
		sed -i '2a sh /koolshare/scripts/ss_config.sh' /jffs/scripts/wan-start
	fi
	chmod +x /jffs/scripts/wan-start
}

start_ss_redir(){
	if [ "$ss_basic_type" == "1" ];then
		echo_date 开启ssr-redir进程，用于透明代理.
		BIN=rss-redir
	elif  [ "$ss_basic_type" == "0" ];then
		# ss-libev需要大于160的熵才能正常工作
		start_haveged
		echo_date 开启ss-redir进程，用于透明代理.
		ss_arg
		BIN=ss-redir
	fi

	# Start ss-redir
	if [ "$mangle" == "1" ];then
		# tcp udp go ss
		echo_date $BIN的 tcp 走$BIN.
		echo_date $BIN的 udp 走$BIN.
		$BIN -c $CONFIG_FILE $ARG_V2RAY_PLUGIN -u -f /var/run/shadowsocks.pid >/dev/null 2>&1
	else
		# tcp only go ss
		echo_date $BIN的 tcp 走$BIN.
		echo_date $BIN的 udp 未开启.
		$BIN -c $CONFIG_FILE $ARG_V2RAY_PLUGIN -f /var/run/shadowsocks.pid >/dev/null 2>&1
	fi
	echo_date $BIN 启动完毕！.
}

get_function_switch() {
	case "$1" in
		1)
			echo "true"
		;;
		*)
			echo "false"
		;;
	esac
}

get_ws_header() {
	if [ -n "$1" ];then
		echo {\"Host\": \"$1\"}
	else
		echo "null"
	fi
}

get_h2_host() {
	if [ -n "$1" ];then
		echo [\"$1\"]
	else
		echo "null"
	fi
}

get_path(){
	if [ -n "$1" ];then
		echo \"$1\"
	else
		echo "null"
	fi
}

get_fingerprint(){
	if [ -n "$1" ];then
		echo \"$1\"
	else
		echo "null"
	fi
}

resolve_node_ip4json(){	
	
	# 检测用户json的服务器ip地址
		node_protocol=$(cat "$V2RAY_CONFIG_FILE" | jq -r .outbounds[0].protocol)
		case $node_protocol in
		vmess)
			node_server=$(cat "$V2RAY_CONFIG_FILE" | jq -r .outbounds[0].settings.vnext[0].address)
			;;
		vless)
			node_server=$(cat "$V2RAY_CONFIG_FILE" | jq -r .outbounds[0].settings.vnext[0].address)
			;;			
		socks)
			node_server=$(cat "$V2RAY_CONFIG_FILE" | jq -r .outbounds[0].settings.servers[0].address)
			;;
		trojan)
			node_server=$(cat "$V2RAY_CONFIG_FILE" | jq -r .outbounds[0].settings.servers[0].address)
			;;
		shadowsocks)
			node_server=$(cat "$V2RAY_CONFIG_FILE" | jq -r .outbounds[0].settings.servers[0].address)
			;;
		*)
			node_server=""
			;;
		esac

		if [ -n "$node_server" -a "$node_server" != "null" ];then
			IFIP_VS=`echo $node_server|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
			if [ -n "$IFIP_VS" ];then
				ss_basic_server_ip="$node_server"
				echo_date "检测到你的json配置的${node_protocol}服务器是：$node_server"
			else
				echo_date "检测到你的json配置的${node_protocol}服务器：$node_server不是ip格式！"
				echo_date "为了确保${node_protocol}的正常工作，建议配置ip格式的${node_protocol}服务器地址！"
				echo_date "尝试解析${node_protocol}服务器的ip地址，DNS：$(get_server_resolver)"
				# 服务器地址强制由114解析，以免插件还未开始工作而导致解析失败
				echo "server=/$node_server/$(get_server_resolver)#53" > /jffs/configs/dnsmasq.d/ss_server.conf
				node_server_ip=`nslookup "$node_server" $(get_server_resolver) | sed '1,4d' | awk '{print $3}' | grep -v :|awk 'NR==1{print}'`
				if [ "$?" == "0" ]; then
					node_server_ip=`echo $node_server_ip|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
				else
					echo_date ${node_protocol}服务器域名解析失败！
					echo_date 尝试用resolveip方式解析，DNS：系统
					node_server_ip=`resolveip -4 -t 2 $ss_basic_server|awk 'NR==1{print}'`
					if [ "$?" == "0" ];then
						node_server_ip=`echo $node_server_ip|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
					fi
				fi

				if [ -n "$node_server_ip" ];then
					echo_date "${node_protocol}服务器的ip地址解析成功：$node_server_ip"
					# 解析并记录一次ip，方便插件触发重启设定工作
					echo "address=/$node_server/$node_server_ip" > /tmp/ss_host.conf
					# 去掉此功能，以免ip发生变更导致问题，或者影响域名对应的其它二级域名
					#ln -sf /tmp/ss_host.conf /jffs/configs/dnsmasq.d/ss_host.conf
					ss_basic_server_ip="$node_server_ip"
				else
					echo_date "${node_protocol}服务器的ip地址解析失败!插件将继续运行，域名解析将由${node_protocol}自己进行！"
					echo_date "请自行将${node_protocol}服务器的ip地址填入IP/CIDR白名单中!"
					echo_date "为了确保${node_protocol}的正常工作，建议配置ip格式的${node_protocol}服务器地址！"
					#close_in_five
				fi
			fi
		else
			echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			echo_date "+       没有检测到你的${node_protocol}服务器地址，如果你确定你的配置是正确的        +"
			echo_date "+   请自行将${node_protocol}服务器的ip地址填入【IP/CIDR】黑名单中，以确保正常使用   +"
			echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		fi
	
}


create_fragment_config(){
	case "$ss_basic_fragment" in
	1)
		cat <<EOF
 ,{
    "protocol": "freedom",
    "settings": {
        "fragment": {
            "interval": "10-20",
            "length": "50-100",
            "packets": "tlshello"
        },
        "noises": [
            {
                "delay": "10-20",
                "packet": "100-200",
                "type": "rand"
            }
        ]
    },
    "streamSettings": {
        "network": "tcp",
        "security": "",
        "sockopt": {
            "TcpNoDelay": true,
            "mark": 255
        }
    },
    "tag": "fragment"
 }
EOF
		;;
	*)
		echo ""
		;;
	esac
}


# Xray透明入站构造器：把祖传的单个 dokodemo(tcp,udp) 拆成 in-redir(tcp,redirect)+
# in-tproxy(udp,tproxy)。缺 sockopt.tproxy="tproxy" 正是UDP被TPROXY送进3333却黑洞的根因。
# 输出紧凑单行合法JSON，便于嵌入普通heredoc与转义的custom TEMPLATE字符串。
xray_in_redir(){
	printf '%s' '{"tag":"in-redir","listen":"0.0.0.0","port":3333,"protocol":"dokodemo-door","settings":{"network":"tcp","followRedirect":true},"streamSettings":{"sockopt":{"tproxy":"redirect"}}}'
}
xray_in_tproxy(){
	printf '%s' '{"tag":"in-tproxy","listen":"0.0.0.0","port":3333,"protocol":"dokodemo-door","settings":{"network":"udp","followRedirect":true},"streamSettings":{"sockopt":{"tproxy":"tproxy"}}}'
}

create_v2ray_json(){
	rm -rf "$V2RAY_CONFIG_FILE_TMP"
	rm -rf "$V2RAY_CONFIG_FILE"
	if [ "$ss_basic_v2ray_use_json" == "0" ]; then
		echo_date 生成V2Ray配置文件...
		local kcp="null"
		local tcp="null"
		local ws="null"
		local h2="null"
		local grpc="null"
		local tls="null"
		local reality="null"
		local vless_flow=""
		[ "$ss_basic_fingerprint" == "none" ] && local ss_basic_fingerprint=""

		# tcp和kcp下tlsSettings为null，ws和h2下tlsSettings
		[ -z "$(dbus get ss_basic_v2ray_mux_concurrency)" ] && local ss_basic_v2ray_mux_concurrency=8
		[ "$ss_basic_v2ray_network_security" == "none" ] && local ss_basic_v2ray_network_security=""

		# incase multi-domain input
		if [ "$(echo $ss_basic_v2ray_network_host | grep ",")" ]; then
			ss_basic_v2ray_network_host=$(echo $ss_basic_v2ray_network_host | sed 's/,/", "/g')
		fi

		if [ "$ss_basic_v2ray_network" == "ws" -o "$ss_basic_v2ray_network" == "h2" ] && [ -z "$ss_basic_v2ray_network_tlshost" ] && [ -n "$ss_basic_v2ray_network_host" ]; then
		 	local ss_basic_v2ray_network_tlshost="$ss_basic_v2ray_network_host"
		fi

		case "$ss_basic_v2ray_network_security" in
		tls)
			local tls="{
					\"allowInsecure\": $(get_function_switch $ss_basic_allowinsecure),
					\"fingerprint\": $(get_fingerprint $ss_basic_fingerprint),
					\"serverName\": \"$ss_basic_v2ray_network_tlshost\"
					}"
			[ "$ss_basic_v2ray_network_flow" != "none" -a "$ss_basic_v2ray_network_flow" != "" ] && local vless_flow="\"flow\": \"$ss_basic_v2ray_network_flow\","	|| 	local vless_flow=""
			;;
		reality)
			local reality="{
					\"serverName\": \"$ss_basic_v2ray_network_tlshost\",
					\"fingerprint\": $(get_fingerprint $ss_basic_fingerprint),
					\"publicKey\": \"$ss_basic_xray_publicKey\",
					\"shortId\": \"$ss_basic_xray_shortId\",
					\"spiderX\": \"\"
					}"
			local vless_flow="\"flow\": \"$ss_basic_v2ray_network_flow\","
			;;	
		*)
			local tls="null"
			local reality="null"
			;;
		esac
		
		case "$ss_basic_v2ray_network" in
		tcp)
			if [ "$ss_basic_v2ray_headtype_tcp" == "http" ]; then
				local tcp="{
					\"connectionReuse\": true,
					\"header\": {
					\"type\": \"http\",
					\"request\": {
					\"version\": \"1.1\",
					\"method\": \"GET\",
					\"path\": [\"/\"],
					\"headers\": {
					\"Host\": [\"$ss_basic_v2ray_network_host\"],
					\"User-Agent\": [\"Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36\",\"Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46\"],
					\"Accept-Encoding\": [\"gzip, deflate\"],
					\"Connection\": [\"keep-alive\"],
					\"Pragma\": \"no-cache\"
					}
					},
					\"response\": {
					\"version\": \"1.1\",
					\"status\": \"200\",
					\"reason\": \"OK\",
					\"headers\": {
					\"Content-Type\": [\"application/octet-stream\",\"video/mpeg\"],
					\"Transfer-Encoding\": [\"chunked\"],
					\"Connection\": [\"keep-alive\"],
					\"Pragma\": \"no-cache\"
					}
					}
					}
					}"
			else
				local tcp="null"
			fi
			;;
		kcp)
			local kcp="{
				\"mtu\": 1350,
				\"tti\": 50,
				\"uplinkCapacity\": 12,
				\"downlinkCapacity\": 100,
				\"congestion\": false,
				\"readBufferSize\": 2,
				\"writeBufferSize\": 2,
				\"seed\": \"$ss_basic_v2ray_network_path\",
				\"header\": {
				\"type\": \"$ss_basic_v2ray_headtype_kcp\",
				\"request\": null,
				\"response\": null
				}
				}"
			[ -z "$ss_basic_v2ray_network_path" ] && local kcp=$(echo $kcp |sed 's/"seed": "*, //')
			;;
		ws)
			local ws="{
				\"connectionReuse\": true,
				\"fingerprint\": $(get_fingerprint $ss_basic_fingerprint),
				\"path\": $(get_path $ss_basic_v2ray_network_path),
				\"headers\": $(get_ws_header $ss_basic_v2ray_network_host)
				}"
			;;
		h2)
			local h2="{
				\"fingerprint\": $(get_fingerprint $ss_basic_fingerprint),
				\"path\": $(get_path $ss_basic_v2ray_network_path),
				\"host\": $(get_h2_host $ss_basic_v2ray_network_host)
				}"
			;;
		grpc)
			local grpc="{
				\"multiMode\": true,
  				\"idle_timeout\": 13,
				\"fingerprint\": $(get_fingerprint $ss_basic_fingerprint),
				\"serviceName\": $(get_path $ss_basic_v2ray_serviceName) 
				}"
			;;	
		esac

		local tls_fragment=$(create_fragment_config)
		# log area
		cat >"$V2RAY_CONFIG_FILE_TMP" <<-EOF
			{
			"log": {
				"access": "/dev/null",
				"error": "/tmp/v2ray_log.log",
				"loglevel": "error"
			},
		EOF
		# inbounds area (7913 for dns resolve)
		if [ "$ss_foreign_dns" == "7" ]; then
			echo_date 配置v2ray dns，用于dns解析...
			cat >>"$V2RAY_CONFIG_FILE_TMP" <<-EOF
				"inbounds": [
					{
					"tag": "in-dns",
					"protocol": "dokodemo-door",
					"port": $DNSF_PORT,
					"settings": {
						"address": "8.8.8.8",
						"port": 53,
						"network": "udp",
						"timeout": 0,
						"followRedirect": false
						}
					},
					$(xray_in_redir)$( [ -n "$mangle" ] && printf ',%s' "$(xray_in_tproxy)" )
				],
			EOF
		else
			# inbounds area (23456 for socks5)
			cat >>"$V2RAY_CONFIG_FILE_TMP" <<-EOF
				"inbounds": [
					{
						"tag": "in-socks",
						"port": 23456,
						"listen": "0.0.0.0",
						"protocol": "socks",
						"settings": {
							"auth": "noauth",
							"udp": true,
							"ip": "127.0.0.1",
							"clients": null
						},
						"streamSettings": null
					},
					$(xray_in_redir)$( [ -n "$mangle" ] && printf ',%s' "$(xray_in_tproxy)" )
				],
			EOF
		fi
		# outbounds area
		if [ "$ss_basic_v2ray_protocol" == "vmess" ]; then
			cat >>"$V2RAY_CONFIG_FILE_TMP" <<-EOF
				"outbounds": [
				  {
					"tag": "agentout",
					"protocol": "vmess",
					"settings": {
					  "vnext": [
						{
						  "address": "$(dbus get ss_basic_server)",
						  "port": $ss_basic_port,
						  "users": [
							{
							  "id": "$ss_basic_v2ray_uuid",
							  "alterId": $ss_basic_v2ray_alterid,
							  "security": "$ss_basic_v2ray_security"
							}
						  ]
						}
					  ],
					  "servers": null
					},
					"streamSettings": {
					  "network": "$ss_basic_v2ray_network",
					  "security": "$ss_basic_v2ray_network_security",
					  "tlsSettings": $tls,
					  "tcpSettings": $tcp,
					  "kcpSettings": $kcp,
					  "wsSettings": $ws,
					  "httpSettings": $h2,
					  "grpcSettings": $grpc
					},
					"mux": {
					  "enabled": $(get_function_switch $ss_basic_v2ray_mux_enable),
					  "concurrency": $ss_basic_v2ray_mux_concurrency
					}
				  }
				]
				}
			EOF
		elif [ "$ss_basic_v2ray_protocol" == "vless" ]; then
		  #vless
		  cat >>"$V2RAY_CONFIG_FILE_TMP" <<-EOF
				"outbounds": [
				  {
					"tag": "agentout",
					"protocol": "vless",
					"settings": {
					  "vnext": [
						{
						  "address": "$(dbus get ss_basic_server)",
						  "port": $ss_basic_port,
						  "users": [
							{
							  "id": "$ss_basic_v2ray_uuid",
							  "level": 1,
							  $vless_flow
							  "encryption": "none"
							}
						  ]
						}
					  ],
					  "servers": null
					},
					"streamSettings": {
					  "network": "$ss_basic_v2ray_network",
					  "security": "$ss_basic_v2ray_network_security",
					  "tlsSettings": $tls,
					  "realitySettings": $reality,
					  "tcpSettings": $tcp,
					  "kcpSettings": $kcp,
					  "wsSettings": $ws,
					  "httpSettings": $h2,
					  "grpcSettings": $grpc
					},
					"mux": {
					  "enabled": $(get_function_switch $ss_basic_v2ray_mux_enable),
					  "concurrency": $ss_basic_v2ray_mux_concurrency
					}
				  } ${tls_fragment}
				]
				}
			EOF
		fi
		echo_date 解析V2Ray配置文件...
		cat "$V2RAY_CONFIG_FILE_TMP" | jq --tab . >"$V2RAY_CONFIG_FILE"
		echo_date V2Ray配置文件写入成功到"$V2RAY_CONFIG_FILE"
	elif [ "$ss_basic_v2ray_use_json" == "1" ]; then
		echo_date 使用自定义的v2ray json配置文件...
		echo "$ss_basic_v2ray_json" | base64_decode >"$V2RAY_CONFIG_FILE_TMP"
		local OB=$(cat "$V2RAY_CONFIG_FILE_TMP" | jq .outbound)
		local OBS=$(cat "$V2RAY_CONFIG_FILE_TMP" | jq .outbounds)

		# 兼容旧格式：outbound
		if [ "$OB" != "null" ]; then
			OUTBOUNDS=$(cat "$V2RAY_CONFIG_FILE_TMP" | jq .outbound)
		fi
		
		# 新格式：outbound[]
		if [ "$OBS" != "null" ]; then
			OUTBOUNDS=$(cat "$V2RAY_CONFIG_FILE_TMP" | jq .outbounds[])
		fi
		
		if [ "$ss_foreign_dns" == "7" ]; then
			local TEMPLATE="{
								\"log\": {
									\"access\": \"/dev/null\",
									\"error\": \"/tmp/v2ray_log.log\",
									\"loglevel\": \"error\"
								},
								\"inbounds\": [
									{
										\"tag\": \"in-dns\",
										\"protocol\": \"dokodemo-door\", 
										\"port\": $DNSF_PORT,
										\"settings\": {
											\"address\": \"8.8.8.8\",
											\"port\": 53,
											\"network\": \"udp\",
											\"timeout\": 0,
											\"followRedirect\": false
										}
									},
									$(xray_in_redir)$( [ -n "$mangle" ] && printf ',%s' "$(xray_in_tproxy)" )
								]
							}"
		else
			local TEMPLATE="{
								\"log\": {
									\"access\": \"/dev/null\",
									\"error\": \"/tmp/v2ray_log.log\",
									\"loglevel\": \"error\"
								},
								\"inbounds\": [
									{
										\"tag\": \"in-socks\",
										\"port\": 23456,
										\"listen\": \"0.0.0.0\",
										\"protocol\": \"socks\",
										\"settings\": {
											\"auth\": \"noauth\",
											\"udp\": true,
											\"ip\": \"127.0.0.1\",
											\"clients\": null
										},
										\"streamSettings\": null
									},
									$(xray_in_redir)$( [ -n "$mangle" ] && printf ',%s' "$(xray_in_tproxy)" )
								]
							}"
		fi
		echo_date 解析V2Ray配置文件...

		# 1) 统一 OUTBOUNDS 为数组
		OUTBOUNDS_ARR=$(cat "$V2RAY_CONFIG_FILE_TMP" | jq -c '
		if (.outbounds? // null) != null then
			.outbounds
		elif (.outbound? // null) != null then
			[ .outbound ]
		else
			[]
		end
		')

		# 2) 判断是否是 xagg 聚合输入（只要存在 xagg_ 前缀）
		IS_XAGG=$(echo "$OUTBOUNDS_ARR" | jq -r '
		any(.[]; ((.tag // "") | startswith("xagg_")))
		')

		# ===== 新增 A：读取聚合策略（默认 leastPing） =====
		XAGG_STRATEGY=$(echo "$OUTBOUNDS_ARR" | jq -r '
		.[] | select(.tag=="xagg_meta") | .settings.strategy // empty
		')

		[ -z "$XAGG_STRATEGY" ] && XAGG_STRATEGY="leastPing"
		# =====================================================

		if [ "$IS_XAGG" = "true" ]; then
			echo_date "检测到 xagg 聚合节点，策略: $XAGG_STRATEGY"

			# ===== 新增 B：剔除 xagg_meta =====
			REAL_OUTBOUNDS=$(echo "$OUTBOUNDS_ARR" | jq -c '
			map(select(.tag != "xagg_meta"))
			')
			# ==================================

			# 3) 提取真实节点 tag（只剩 xagg_1 / xagg_2 ...）
			TAGS=$(echo "$REAL_OUTBOUNDS" | jq -c '[ .[] | .tag ]')

			# 4) 生成 routing + observatory
			ROBS=$(jq -nc --argjson tags "$TAGS" --arg strategy "$XAGG_STRATEGY" '
			{
				"routing": {
					"domainStrategy": "AsIs",
					"balancers": [
						{
							"tag": "balancer-main",
							"selector": $tags,
							"strategy": { "type": $strategy }
						}
					],
					"rules": [
						{
							"type": "field",
							"inboundTag": ["in-socks","in-redir","in-tproxy"],
							"balancerTag": "balancer-main"
						}
					]
				},
				"observatory": {
					"subjectSelector": $tags,
					"probeURL": "https://www.gstatic.com/generate_204",
					"probeInterval": "30s"
				}
			}
			')

	# 5) 合并（注意：用 REAL_OUTBOUNDS）
	echo "$TEMPLATE" | jq \
		--argjson outbounds "$REAL_OUTBOUNDS" \
		--argjson robs "$ROBS" \
		'. + {outbounds: $outbounds} + $robs' >"$V2RAY_CONFIG_FILE"

	else
		# 普通自定义 JSON，未启用聚合逻辑
		echo "$TEMPLATE" | jq \
			--argjson outbounds "$OUTBOUNDS_ARR" \
			'. + {outbounds: $outbounds}' >"$V2RAY_CONFIG_FILE"
	fi

	echo_date "V2Ray/Xray 配置文件写入成功: $V2RAY_CONFIG_FILE"


		# 检测用户json的服务器ip地址
		resolve_node_ip4json
	fi

	cd /koolshare/bin
	result=$(xray -test -config="$V2RAY_CONFIG_FILE" | grep "Configuration OK.")

	if [ -n "$result" ]; then
		echo_date $result
		echo_date Xray配置文件通过测试!!!
	else
		echo_date Xray配置文件没有通过测试，请检查设置!!!
		rm -rf "$V2RAY_CONFIG_FILE_TMP"
		rm -rf "$V2RAY_CONFIG_FILE"
		close_in_five
	fi
}

create_trojan_json(){
	rm -rf "$V2RAY_CONFIG_FILE_TMP"
	rm -rf "$V2RAY_CONFIG_FILE"
	if  [ "$ss_basic_type" == "4" ] && [ "$ss_basic_trojan_binary" == "Trojan" ]; then
		echo_date 生成Trojan配置文件...
		 #trojan
		 local tls_fragment=$(create_fragment_config)
		 
		 # inbounds area (23456 for socks5)  
		cat >"$V2RAY_CONFIG_FILE_TMP" <<-EOF
		{
			"log": {
				"access": "/dev/null",
				"error": "/tmp/v2ray_log.log",
				"loglevel": "error"
			},
				"inbounds": [
					{
						"port": 23456,
						"listen": "0.0.0.0",
						"protocol": "socks",
						"settings": {
							"auth": "noauth",
							"udp": true,
							"ip": "127.0.0.1",
							"clients": null
						},
						"streamSettings": null
					},
					$(xray_in_redir)$( [ -n "$mangle" ] && printf ',%s' "$(xray_in_tproxy)" )
				],
			"outbounds": [
			  {
				"protocol": "trojan",
				"settings": {
				  "servers": [
					{
					  "address": "$(dbus get ss_basic_server)",
					  "port": $ss_basic_port,
					  "password": "$ss_basic_password"
					}
				  ]
				},
				"streamSettings": {
				  "network": "tcp",
				  "security": "tls",
				  "tlsSettings": {
					"allowInsecure": $(get_function_switch $ss_basic_allowinsecure),  
                    "serverName": "$ss_basic_trojan_sni"
                }
				}
			  }  ${tls_fragment}
			]
		}
		EOF
	
		echo_date 解析Trojan配置文件...
		cat "$V2RAY_CONFIG_FILE_TMP" | jq --tab . >"$V2RAY_CONFIG_FILE"
			
		echo_date Trojan配置文件写入成功到"$V2RAY_CONFIG_FILE"
			
		cd /koolshare/bin
		echo_date 测试Trojan配置文件.....
		result=$(xray -test -config="$V2RAY_CONFIG_FILE" | grep "Configuration OK.")
		if [ -n "$result" ]; then
			echo_date $result
			echo_date Trojan配置文件通过测试!!!
		else
			echo_date Trojan配置文件没有通过测试，请检查设置!!!
			rm -rf "$V2RAY_CONFIG_FILE_TMP"
			rm -rf "$V2RAY_CONFIG_FILE"
			close_in_five
		fi
	fi
}


create_trojango_json(){
	rm -rf "$V2RAY_CONFIG_FILE_TMP"
	rm -rf "$V2RAY_CONFIG_FILE"
	if  [ "$ss_basic_type" == "4" ] && [ "$ss_basic_trojan_binary" == "Trojan-Go" ]; then
		[ -z "$(dbus get ss_basic_v2ray_mux_concurrency)" ] && local ss_basic_v2ray_mux_concurrency=8
		local trojan_sni="$ss_basic_trojan_sni"
		[ -z "$trojan_sni" ] && [ -n "$ss_basic_v2ray_network_host" ] && trojan_sni="$ss_basic_v2ray_network_host"

		if [ "$ss_basic_trojan_network" == "1" ]; then
			[ -n "$ss_basic_v2ray_network_path" ] && local ss_basic_v2ray_network_path=$(echo "/$ss_basic_v2ray_network_path" | sed 's,//,/,')
			local trojango_network="ws"
			local ws_settings="{\"path\": \"$ss_basic_v2ray_network_path\", \"headers\": {\"Host\": \"$ss_basic_v2ray_network_host\"}}"
		else
			local trojango_network="tcp"
			local ws_settings="null"
		fi

		echo_date 生成Trojan-Go Xray配置文件...
		cat >"$V2RAY_CONFIG_FILE_TMP" <<-EOF
		{
			"log": {
				"access": "/dev/null",
				"error": "/tmp/v2ray_log.log",
				"loglevel": "error"
			},
			"inbounds": [
				{
					"tag": "in-socks",
					"port": 23456,
					"listen": "0.0.0.0",
					"protocol": "socks",
					"settings": {
						"auth": "noauth",
						"udp": true,
						"ip": "127.0.0.1",
						"clients": null
					},
					"streamSettings": null
				},
				$(xray_in_redir)$( [ -n "$mangle" ] && printf ',%s' "$(xray_in_tproxy)" )
			],
			"outbounds": [
				{
					"tag": "agentout",
					"protocol": "trojan-go",
					"settings": {
						"trojanGoMux": {
							"enabled": $(get_function_switch $ss_basic_v2ray_mux_enable),
							"concurrency": $ss_basic_v2ray_mux_concurrency,
							"idle_timeout": 60
						},
						"servers": [
							{
								"address": "$(dbus get ss_basic_server)",
								"port": $ss_basic_port,
								"password": "$ss_basic_password"
							}
						]
					},
					"streamSettings": {
						"network": "$trojango_network",
						"security": "tls",
						"tlsSettings": {
							"allowInsecure": $(get_function_switch $ss_basic_allowinsecure),
							"serverName": "$trojan_sni",
							"alpn": ["http/1.1"],
							"fingerprint": $(get_fingerprint $ss_basic_fingerprint)
						},
						"wsSettings": $ws_settings
					},
					"mux": {
						"enabled": false,
						"concurrency": 1
					}
				}
			]
		}
		EOF

		echo_date 写入Trojan-Go Xray配置文件...
		mv -f "$V2RAY_CONFIG_FILE_TMP" "$V2RAY_CONFIG_FILE"
		echo_date Trojan-Go Xray配置文件写入成功到"$V2RAY_CONFIG_FILE"

		cd /koolshare/bin
		echo_date 测试Trojan-Go Xray配置文件.....
		result=$(xray -test -config="$V2RAY_CONFIG_FILE" | grep "Configuration OK.")
		if [ -n "$result" ]; then
			echo_date $result
			echo_date Trojan-Go Xray配置文件通过测试!!!
		else
			echo_date Trojan-Go Xray配置文件没有通过测试，请检查设置!!!
			rm -rf "$V2RAY_CONFIG_FILE_TMP"
			rm -rf "$V2RAY_CONFIG_FILE"
			close_in_five
		fi
	fi
}

create_naive_json(){
	rm -rf "$NAIVE_CONFIG_FILE" "$NAIVE2_CONFIG_FILE"
	if  [ "$ss_basic_type" == "5" ] ; then
	
		echo_date 生成NaiveProxy配置文件...
		 #NaiveProxy
		 # 3333 for nat  
		cat >"$NAIVE_CONFIG_FILE" <<-EOF
			{
			"listen": "redir://0.0.0.0:3333",
			"proxy": "${ss_basic_naive_protocol}://${ss_basic_naive_user}:${ss_basic_password}@$(dbus get ss_basic_server):$ss_basic_port"
			}
		EOF
		echo_date NaiveProxy 配置文件写入成功到 "$NAIVE_CONFIG_FILE"
		 #  23456 for socks
		cat >"$NAIVE2_CONFIG_FILE" <<-EOF
			{
			"listen": "socks://127.0.0.1:23456",
			"proxy": "${ss_basic_naive_protocol}://${ss_basic_naive_user}:${ss_basic_password}@$(dbus get ss_basic_server):$ss_basic_port"
			}
		EOF
		
		echo_date NaiveProxy 配置文件写入成功到 "$NAIVE2_CONFIG_FILE"
	fi
}


create_ss2022_json(){
	rm -rf "$V2RAY_CONFIG_FILE_TMP"
	rm -rf "$V2RAY_CONFIG_FILE"
	if  [ "$ss_basic_type" == "3" ] && [ "$SS2022" == "Y" ]; then
		echo_date 生成 Shadowsocks 2022 配置文件...
		 #Shadowsocks 2022 
		 # inbounds area (23456 for socks5)  
		cat >"$V2RAY_CONFIG_FILE_TMP" <<-EOF
		{
			"log": {
				"access": "/dev/null",
				"error": "/tmp/v2ray_log.log",
				"loglevel": "error"
			},
				"inbounds": [
					{
						"port": 23456,
						"listen": "0.0.0.0",
						"protocol": "socks",
						"settings": {
							"auth": "noauth",
							"udp": true,
							"ip": "127.0.0.1",
							"clients": null
						},
						"streamSettings": null
					},
					$(xray_in_redir)$( [ -n "$mangle" ] && printf ',%s' "$(xray_in_tproxy)" )
				],
			"outbounds": [
			  {
				"protocol": "shadowsocks",
				"settings": {
				  "servers": [
					{
					  "address": "$(dbus get ss_basic_server)",
					  "port": $ss_basic_port,
					  "method": "$ss_basic_method",
					  "password": "$ss_basic_password"
					}
				  ]
				}
			  }
			]
		}
		EOF
	
		echo_date 解析 Shadowsocks 2022 配置文件...
		cat "$V2RAY_CONFIG_FILE_TMP" | jq --tab . >"$V2RAY_CONFIG_FILE"
			
		echo_date Shadowsocks 2022 配置文件写入成功到"$V2RAY_CONFIG_FILE"
			
		cd /koolshare/bin
		echo_date 测试 Shadowsocks 2022 配置文件.....
		result=$(xray -test -config="$V2RAY_CONFIG_FILE" | grep "Configuration OK.")
		if [ -n "$result" ]; then
			echo_date $result
			echo_date Shadowsocks 2022 配置文件通过测试!!!
		else
			echo_date Shadowsocks 2022 配置文件没有通过测试，请检查设置!!!
			rm -rf "$V2RAY_CONFIG_FILE_TMP"
			rm -rf "$V2RAY_CONFIG_FILE"
			close_in_five
		fi
	fi
}


create_hy2_json(){
	rm -f "$HY2_CONFIG_FILE" 
	if  [ "$ss_basic_type" == "4" ] && [ "$ss_basic_trojan_binary" == "Hysteria2" ]; then
	
		echo_date 生成Hysteria2配置文件...
		 #HY2

	cat >"$HY2_CONFIG_FILE" <<-EOF		
			{
				"server": "$(dbus get ss_basic_server):$ss_basic_port",
				"auth": "${ss_basic_password}",
				"tls": {
					"sni": "$ss_basic_trojan_sni",
					"insecure": $(get_function_switch $ss_basic_allowinsecure)
				},
				"fastOpen": true,
				"lazy": true,
				"socks5": {
					"listen": "127.0.0.1:23456"
				},
				"tcpRedirect": {
					"listen": "0.0.0.0:3333"
				}
			}
		EOF

		if [ -n "$ss_basic_hy2_global_json" ]; then
			echo "$ss_basic_hy2_global_json" | base64_decode >"${HY2_GLOBAL_CONFIG_FILE}.tmp"
			if jq -e 'type == "object" and length > 0 and (length == ([keys_unsorted[] | select(. == "obfs" or . == "congestion" or . == "bandwidth")] | length))' "${HY2_GLOBAL_CONFIG_FILE}.tmp" >/dev/null 2>&1; then
				mv "${HY2_GLOBAL_CONFIG_FILE}.tmp" "$HY2_GLOBAL_CONFIG_FILE"
				jq -s '.[0] * .[1]' "$HY2_CONFIG_FILE" "$HY2_GLOBAL_CONFIG_FILE" >"${HY2_CONFIG_FILE}.tmp" && mv "${HY2_CONFIG_FILE}.tmp" "$HY2_CONFIG_FILE"
				echo_date Hysteria2 全局设定合并成功
			else
				echo_date Hysteria2 全局设定格式错误，已跳过
			fi
			rm -f "$HY2_GLOBAL_CONFIG_FILE" "${HY2_GLOBAL_CONFIG_FILE}.tmp" "${HY2_CONFIG_FILE}.tmp"
		else
			rm -f "$HY2_GLOBAL_CONFIG_FILE" "${HY2_GLOBAL_CONFIG_FILE}.tmp" "${HY2_CONFIG_FILE}.tmp"
		fi

		echo_date Hysteria2 配置文件写入成功到 "$HY2_CONFIG_FILE"
	fi
}

start_xray_core() {
	if [ "$ss_basic_type" == "4" ]; then
		start_trojan
	elif [ "$SS2022" == "Y" ]; then
		start_ss2022		
	else
		start_xray
	fi
}

start_xray() {
	# xray start
	cd /koolshare/bin
	#export GOGC=30
	xray run -config=/koolshare/ss/v2ray.json >/dev/null 2>&1 &
	local xrayPID
	local i=10
	until [ -n "$xrayPID" ]; do
		i=$(($i - 1))
		xrayPID=$(pidof xray)
		if [ "$i" -lt 1 ]; then
			echo_date "xray 进程启动失败！"
			close_in_five
		fi
		sleep 1
	done
	echo_date xray启动成功，pid：$xrayPID
}

start_trojan() {
	# trojan start
	cd /koolshare/bin
	#export GOGC=30
	xray run -config=/koolshare/ss/v2ray.json >/dev/null 2>&1 &
	local trojanPID
	local i=10
	until [ -n "$trojanPID" ]; do
		i=$(($i - 1))
		trojanPID=$(pidof xray)
		if [ "$i" -lt 1 ]; then
			echo_date "trojan进程启动失败！"
			close_in_five
		fi
		sleep 1
	done
	echo_date trojan启动成功，pid：$trojanPID
}

start_trojango() {
	# trojan-go start by xray core
	cd /koolshare/bin
	xray run -config=$V2RAY_CONFIG_FILE >/dev/null 2>&1 &
	local trojangoPID
	local i=10
	until [ -n "$trojangoPID" ]; do
		i=$(($i - 1))
		trojangoPID=$(pidof xray)
		if [ "$i" -lt 1 ]; then
			echo_date "Trojan-Go Xray进程启动失败！"
			close_in_five
		fi
		sleep 1
	done
	echo_date Trojan-Go Xray启动成功，pid：$trojangoPID
}


start_naiveproxy() {
	# naiveproxy start
	cd /koolshare/bin
	naive $NAIVE_CONFIG_FILE >/dev/null 2>&1 &
	local naivePID
	local i=10
	until [ -n "$naivePID" ]; do
		i=$(($i - 1))
		naivePID=$(pidof naive)
		if [ "$i" -lt 1 ]; then
			echo_date "NaiveProxy进程启动失败！"
			close_in_five
		fi
		sleep 1
	done
	echo_date NaiveProxy启动成功，pid：$naivePID
}

start_hy2() {
	# Hysteria2 start
	export QUIC_GO_DISABLE_ECN=true
	cd /koolshare/bin
	hysteria -c $HY2_CONFIG_FILE -l error --disable-update-check  >/dev/null 2>&1 &
	local hy2PID
	local i=10
	until [ -n "$hy2PID" ]; do
		i=$(($i - 1))
		hy2PID=$(pidof hysteria)
		if [ "$i" -lt 1 ]; then
			echo_date "Hysteria2进程启动失败！"
			close_in_five
		fi
		sleep 1
	done
	echo_date Hysteria2启动成功，pid：$hy2PID
}

start_anytls(){
	# AnyTLS start
	cd /koolshare/bin
	if [ -n "$ss_basic_trojan_sni" ]; then
		anytls -socks 127.0.0.1:23456 -nat 0.0.0.0:3333 -s "$(dbus get ss_basic_server):$ss_basic_port" -p "$ss_basic_password" -sni "$ss_basic_trojan_sni" >/dev/null 2>&1 &
	else
		anytls -socks 127.0.0.1:23456 -nat 0.0.0.0:3333 -s "$(dbus get ss_basic_server):$ss_basic_port" -p "$ss_basic_password" >/dev/null 2>&1 &
	fi
	local anytlsPID=$!
	local i=10
	until [ -n "$anytlsPID" ] && kill -0 "$anytlsPID" >/dev/null 2>&1; do
		anytlsPID=$(pidof anytls)
		[ -n "$anytlsPID" ] && break
		i=$(($i - 1))
		if [ "$i" -lt 1 ]; then
			echo_date "AnyTLS进程启动失败！"
			close_in_five
		fi
		sleep 1
	done
	echo_date AnyTLS启动成功，pid：$anytlsPID
}

start_ss2022() {
	# Shadowsocks 2022  start
	cd /koolshare/bin
	#export GOGC=30
	xray run -config=/koolshare/ss/v2ray.json >/dev/null 2>&1 &
	local ss2022PID
	local i=10
	until [ -n "$ss2022PID" ]; do
		i=$(($i - 1))
		ss2022PID=$(pidof xray)
		if [ "$i" -lt 1 ]; then
			echo_date "Shadowsocks 2022 进程启动失败！"
			close_in_five
		fi
		sleep 1
	done
	echo_date Shadowsocks 2022 启动成功，pid：$ss2022PID
}

write_cron_job(){
	sed -i '/ssupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	if [ "1" == "$ss_basic_rule_update" ]; then
		echo_date 添加shadowsocks规则定时更新任务，每天"$ss_basic_rule_update_time"自动检测更新规则.
		cru a ssupdate "15 $ss_basic_rule_update_time * * * /bin/sh /koolshare/scripts/ss_rule_update.sh"
	else
		echo_date shadowsocks规则定时更新任务未启用！
	fi
	# 节点订阅入口已从 Web UI 移除：无条件清理订阅定时任务，并清零残留的废弃 DBus 开关，
	# 防止历史配置（ss_basic_node_update=1）让订阅在后台继续定时运行。
	sed -i '/ssnodeupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	if [ "$ss_basic_node_update" = "1" ];then
		echo_date "检测到已废弃的节点订阅自动更新开关，已清除（订阅功能入口已移除）。"
		dbus remove ss_basic_node_update >/dev/null 2>&1
		dbus remove ss_basic_node_update_day >/dev/null 2>&1
		dbus remove ss_basic_node_update_hr >/dev/null 2>&1
	fi
}

kill_cron_job(){
	if [ -n "`cru l|grep ssupdate`" ];then
		echo_date 删除shadowsocks规则定时更新任务...
		sed -i '/ssupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
	if [ -n "`cru l|grep ssnodeupdate`" ];then
		echo_date 删除节点定时订阅任务...
		sed -i '/ssnodeupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
}
#--------------------------------------nat part begin------------------------------------------------
load_tproxy(){
	MODULES="nf_tproxy_core xt_TPROXY xt_socket xt_comment"
	OS=$(uname -r)
	echo_date 加载TPROXY模块，用于udp转发...
	# best-effort加载：内核内建(built-in)模块不出现在lsmod属正常，不据此判失败。
	# (修复原版计数bug：j未定义、-ne 3却有4个模块、内建模块被误判缺失而close_in_five硬中止启动)
	for MODULE in $MODULES; do
		if ! lsmod | grep -q "$MODULE"; then
			insmod /lib/modules/${OS}/kernel/net/netfilter/${MODULE}.ko >/dev/null 2>&1
		fi
	done
	# 权威探测：用未挂接的临时链实测内核/xtables是否真正接受TPROXY target。
	# 比"数lsmod"可靠——内建模块、老内核命名差异都不会误判；探测后立即删除，不承载业务流量。
	iptables -t mangle -F SS_TPROXY_TEST >/dev/null 2>&1
	iptables -t mangle -X SS_TPROXY_TEST >/dev/null 2>&1
	iptables -t mangle -N SS_TPROXY_TEST >/dev/null 2>&1
	if iptables -t mangle -A SS_TPROXY_TEST -p udp -j TPROXY --on-port 3333 --tproxy-mark 0x07 >/dev/null 2>&1; then
		iptables -t mangle -F SS_TPROXY_TEST >/dev/null 2>&1
		iptables -t mangle -X SS_TPROXY_TEST >/dev/null 2>&1
		return 0
	fi
	iptables -t mangle -F SS_TPROXY_TEST >/dev/null 2>&1
	iptables -t mangle -X SS_TPROXY_TEST >/dev/null 2>&1
	echo_date "内核不接受TPROXY target(缺xt_TPROXY或老内核不支持)，UDP透明代理不可用，降级为TCP-only。"
	return 1
}


flush_nat(){
	echo_date 清除iptables规则和ipset...
	# flush rules and set if any
	nat_indexs=`iptables -nvL PREROUTING -t nat |sed 1,2d | sed -n '/SHADOWSOCKS/='|sort -r`
	for nat_index in $nat_indexs
	do
		iptables -t nat -D PREROUTING $nat_index >/dev/null 2>&1
	done
	#iptables -t nat -D PREROUTING -p tcp -j SHADOWSOCKS >/dev/null 2>&1
	
	iptables -t nat -F SHADOWSOCKS > /dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS > /dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_EXT > /dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_GFW > /dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_GFW > /dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_CHN > /dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_CHN > /dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_GAM > /dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_GAM > /dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_GLO > /dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_GLO > /dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_HOM > /dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_HOM > /dev/null 2>&1

	mangle_indexs=`iptables -nvL PREROUTING -t mangle |sed 1,2d | sed -n '/SHADOWSOCKS/='|sort -r`
	for mangle_index in $mangle_indexs
	do
		iptables -t mangle -D PREROUTING $mangle_index >/dev/null 2>&1
	done
	#iptables -t mangle -D PREROUTING -p udp -j SHADOWSOCKS >/dev/null 2>&1
	
	iptables -t mangle -F SHADOWSOCKS >/dev/null 2>&1 && iptables -t mangle -X SHADOWSOCKS >/dev/null 2>&1
	iptables -t mangle -F SS_TPROXY_TEST >/dev/null 2>&1 && iptables -t mangle -X SS_TPROXY_TEST >/dev/null 2>&1
	iptables -t mangle -F SHADOWSOCKS_QUIC >/dev/null 2>&1 && iptables -t mangle -X SHADOWSOCKS_QUIC >/dev/null 2>&1
	# 清理全部 mangle 模式 action 链（apply_nat_rules 现在预建全部 5 个）
	for MCHAIN in SHADOWSOCKS_GFW SHADOWSOCKS_CHN SHADOWSOCKS_GAM SHADOWSOCKS_GLO SHADOWSOCKS_HOM; do
		iptables -t mangle -F $MCHAIN >/dev/null 2>&1 && iptables -t mangle -X $MCHAIN >/dev/null 2>&1
	done
	# 精确删除本插件的 nat/OUTPUT 规则，不再整表 flush OUTPUT（避免误删其他插件/用户的 OUTPUT 规则）
	iptables -t nat -D OUTPUT -p tcp -m set --match-set router dst -j REDIRECT --to-ports 3333 >/dev/null 2>&1
	iptables -t nat -D OUTPUT -p tcp -m mark --mark "$ip_prefix_hex" -j SHADOWSOCKS_EXT >/dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_EXT > /dev/null 2>&1
	iptables -t nat -X SHADOWSOCKS_EXT > /dev/null 2>&1
	#iptables -t nat -D PREROUTING -p udp -s $(get_lan_cidr) --dport 53 -j DNAT --to $lan_ipaddr >/dev/null 2>&1
	# 清理DNS劫持规则和链
	chromecast_nu=`iptables -t nat -L PREROUTING -v -n --line-numbers|grep "SHADOWSOCKS_DNS_"|awk '{print $1}'|sort -r`
	if [ -n "$chromecast_nu" ]; then
		for chromecast_index in $chromecast_nu
		do
			iptables -t nat -D PREROUTING $chromecast_index >/dev/null 2>&1
		done
	fi
	VLAN_INDEXS=$(ifconfig | grep -E "^br" | awk '{print $1}' | sed 's/^br//g')
	for VLAN_INDEX in $VLAN_INDEXS
	do
		iptables -t nat -F SHADOWSOCKS_DNS_${VLAN_INDEX} >/dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_DNS_${VLAN_INDEX} >/dev/null 2>&1
	done

	iptables -t mangle -D QOSO0 -m mark --mark "$ip_prefix_hex" -j RETURN >/dev/null 2>&1
	# 清理 filter/FORWARD 的境外流量兜底 guard（IPv4）
	while iptables -t filter -D FORWARD -i br+ -j SHADOWSOCKS_FWD >/dev/null 2>&1; do :; done
	iptables -t filter -F SHADOWSOCKS_FWD >/dev/null 2>&1
	iptables -t filter -X SHADOWSOCKS_FWD >/dev/null 2>&1
	# 清理 DNS 强制(all)：FORWARD 的 DoT/DoH 拦截链 + PREROUTING 的 53 改道 + ss_doh 集
	clean_dns_force
	if command -v ip6tables >/dev/null 2>&1; then
		while ip6tables -t filter -D FORWARD -j SHADOWSOCKS_IPV6 >/dev/null 2>&1; do :; done
		ip6tables -t filter -F SHADOWSOCKS_IPV6 >/dev/null 2>&1
		ip6tables -t filter -X SHADOWSOCKS_IPV6 >/dev/null 2>&1
	fi
	# flush ipset
	ipset -F chnroute >/dev/null 2>&1 && ipset -X chnroute >/dev/null 2>&1
	ipset -F white_list >/dev/null 2>&1 && ipset -X white_list >/dev/null 2>&1
	ipset -F black_list >/dev/null 2>&1 && ipset -X black_list >/dev/null 2>&1
	ipset -F gfwlist >/dev/null 2>&1 && ipset -X gfwlist >/dev/null 2>&1
	ipset -F router >/dev/null 2>&1 && ipset -X router >/dev/null 2>&1
	#remove_redundant_rule
	ip_rule_exist=`ip rule show | grep "lookup 310" | grep -c 310`
	if [ -n "$ip_rule_exist" ];then
		#echo_date 清除重复的ip rule规则.
		until [ "$ip_rule_exist" = 0 ]
		do 
			IP_ARG=`ip rule show | grep "lookup 310"|head -n 1|cut -d " " -f3,4,5,6`
			ip rule del $IP_ARG
			ip_rule_exist=`expr $ip_rule_exist - 1`
		done
	fi
	#remove_route_table
	#echo_date 删除ip route规则.
	ip route del local 0.0.0.0/0 dev lo table 310 >/dev/null 2>&1
}

# 大陆白名单规则基于 IPv4 chnroute。启用 IPv6 时，客户端会绕过全部
# IPv4 iptables 规则，因此在该模式下拒绝把 IPv6 转发到外网，让客户端
# 立即回退到可被透明代理接管的 IPv4；同时保留 LAN 网段之间的 IPv6 互访。
apply_ipv6_leak_guard(){
	[ "$ss_basic_mode" == "2" ] || return 0
	[ "$(nvram get ipv6_service)" != "disabled" ] || return 0
	command -v ip6tables >/dev/null 2>&1 || return 0

	ip6tables -t filter -N SHADOWSOCKS_IPV6 >/dev/null 2>&1
	ip6tables -t filter -F SHADOWSOCKS_IPV6 >/dev/null 2>&1
	# 出接口是 LAN 桥的 IPv6（内网互访）放行，只拦经路由器转发到外部的 IPv6
	ip6tables -t filter -A SHADOWSOCKS_IPV6 -o br+ -j RETURN >/dev/null 2>&1
	ip6tables -t filter -A SHADOWSOCKS_IPV6 -j REJECT --reject-with icmp6-adm-prohibited >/dev/null 2>&1 || \
		ip6tables -t filter -A SHADOWSOCKS_IPV6 -j DROP >/dev/null 2>&1
	ip6tables -t filter -I FORWARD 1 -j SHADOWSOCKS_IPV6 >/dev/null 2>&1
	echo_date 大陆白名单模式：已阻止客户端IPv6直连外网\(保留内网IPv6\)，避免绕过IPv4透明代理。
}

# 大陆白名单模式下，NAT 透明代理只接管 TCP；QUIC(UDP/443) 与其余境外 UDP 会绕过 NAT
# REDIRECT。在 filter/FORWARD 建一道兜底 guard：漏过本地接管的境外 TCP 与境外 QUIC 拦下，
# 不依赖"浏览器丢弃 QUIC 后必然回退到受 NAT 接管的 TCP"这一假定。
#   - TCP 用 REJECT tcp-reset：漏过 NAT REDIRECT 的境外直连被立即 reset，而非裸奔；
#   - QUIC(UDP/443) 用 REJECT icmp-port-unreachable：让浏览器立即回退 TCP（比静默 DROP 快得多）；
#   - 非 443 的境外 UDP（游戏、语音、NTP 等）不拦截，保持直连——这类流量没有 TCP 回退路径，
#     拦了只会掐断游戏；需要强制走代理的目标请加黑名单（black_list 的 UDP 全端口仍拦截兜底）。
#   - REJECT 目标不可用时回退 DROP。
# 与 UDP 同步三档配合：关闭/仅QUIC 档未被 TPROXY 接管的境外 QUIC 由此拦截促回退，其余 UDP 直连；
# 全量档境外 UDP 均被 TPROXY，此处只兜底漏网的 QUIC。
# 校验并规范化Game端口表达式("27015,7777-7778")为iptables multiport格式("27015,7777:7778")。
# 合法：逗号分隔，每段为单端口或"低-高"端口段，端口1-65535，段内低≤高，multiport总槽位≤15(端口段占2)。
# 非法或为空时无输出且返回1——调用方必须以输出非空为下发规则的前提，语法检查不通过绝不加规则。
validate_game_ports(){
	local input=$(echo "$1" | sed 's/[[:space:]]//g')
	[ -z "$input" ] && return 1
	# 整体形状预检：只允许数字/短横线/逗号的合法组合，杜绝任何非法字符进入后续拼接
	echo "$input" | grep -qE '^[0-9]{1,5}(-[0-9]{1,5})?(,[0-9]{1,5}(-[0-9]{1,5})?)*$' || return 1
	local out="" seg lo hi slots=0
	local OLD_IFS="$IFS"
	IFS=','
	for seg in $input; do
		case "$seg" in
			*-*)
				lo=${seg%-*}
				hi=${seg#*-}
				[ "$lo" -ge 1 ] && [ "$lo" -le 65535 ] && [ "$hi" -ge 1 ] && [ "$hi" -le 65535 ] && [ "$lo" -le "$hi" ] || { IFS="$OLD_IFS"; return 1; }
				out="${out},${lo}:${hi}"
				slots=$((slots + 2))
				;;
			*)
				[ "$seg" -ge 1 ] && [ "$seg" -le 65535 ] || { IFS="$OLD_IFS"; return 1; }
				out="${out},${seg}"
				slots=$((slots + 1))
				;;
		esac
		[ "$slots" -gt 15 ] && { IFS="$OLD_IFS"; return 1; }
	done
	IFS="$OLD_IFS"
	echo "${out#,}"
}

apply_forward_guard(){
	[ "$ss_basic_mode" == "2" ] || return 0
	# 安全护栏：chnroute 集为空/未就绪时（如规则下载失败），大陆 IP 会被误判为境外而
	# 被本 guard 全部 REJECT 导致整网断。判断集合是否确有 IP 成员，异常则跳过 guard
	# （宁可暂时不拦境外，也不能误杀大陆流量断网）。
	if ! ipset list chnroute 2>/dev/null | grep -qE '^[0-9]'; then
		echo_date 警告：chnroute集未就绪，跳过filter层境外兜底guard以防误伤大陆流量导致断网。
		return 0
	fi

	iptables -t filter -N SHADOWSOCKS_FWD >/dev/null 2>&1
	iptables -t filter -F SHADOWSOCKS_FWD >/dev/null 2>&1
	# DNS(UDP/53) 交给既有 DNS 劫持逻辑，guard 不干预，避免改变现有 DNS 行为
	iptables -t filter -A SHADOWSOCKS_FWD -p udp --dport 53 -j RETURN >/dev/null 2>&1
	# 白名单与大陆 IP：正常直连转发。白名单优先于黑名单，与 nat/mangle 链的 white-first
	# 语义一致——同一 IP 同时命中黑白名单时，nat 已放行直连，guard 若再拦会掐断该连接。
	iptables -t filter -A SHADOWSOCKS_FWD -m set --match-set white_list dst -j RETURN >/dev/null 2>&1
	iptables -t filter -A SHADOWSOCKS_FWD -m set --match-set chnroute dst -j RETURN >/dev/null 2>&1
	# 强制走代理的黑名单目标若漏过本地接管，优先于境外兜底直接拦截
	iptables -t filter -A SHADOWSOCKS_FWD -m set --match-set black_list dst -p tcp -j REJECT --reject-with tcp-reset >/dev/null 2>&1 || \
		iptables -t filter -A SHADOWSOCKS_FWD -m set --match-set black_list dst -p tcp -j DROP >/dev/null 2>&1
	iptables -t filter -A SHADOWSOCKS_FWD -m set --match-set black_list dst -p udp -j REJECT --reject-with icmp-port-unreachable >/dev/null 2>&1 || \
		iptables -t filter -A SHADOWSOCKS_FWD -m set --match-set black_list dst -p udp -j DROP >/dev/null 2>&1
	# 其余=境外：TCP 漏网兜底 reset；QUIC(UDP/443) 拦截促 TCP 回退。
	# 非 443 境外 UDP（游戏等）不拦截，落到链尾 RETURN 直连——游戏 UDP 无 TCP 回退路径，拦截即断游戏。
	iptables -t filter -A SHADOWSOCKS_FWD -p tcp -j REJECT --reject-with tcp-reset >/dev/null 2>&1 || \
		iptables -t filter -A SHADOWSOCKS_FWD -p tcp -j DROP >/dev/null 2>&1
	iptables -t filter -A SHADOWSOCKS_FWD -p udp --dport 443 -j REJECT --reject-with icmp-port-unreachable >/dev/null 2>&1 || \
		iptables -t filter -A SHADOWSOCKS_FWD -p udp --dport 443 -j DROP >/dev/null 2>&1
	iptables -t filter -A SHADOWSOCKS_FWD -j RETURN >/dev/null 2>&1
	iptables -t filter -I FORWARD 1 -i br+ -j SHADOWSOCKS_FWD >/dev/null 2>&1
	echo_date 大陆白名单模式：已启用filter层境外兜底\(TCP reset / QUIC即时回退，非443境外UDP如游戏保持直连\)。
}

# DNS 强制（“DNS劫持=all/2”档）：白名单域名靠"客户端经路由器 dnsmasq 解析→ipset=/域名/white_list
# 把该 IP 写入 white_list"才生效。若客户端用 DoH/DoT 或指向公共 DNS，查询绕过 dnsmasq，
# 白名单域名的真实连接 IP 永远不进 white_list，就被 CHN !chnroute 兜底代理——这正是
# "加了白名单域名仍走代理/CF 盾显示代理出口 IP"的根因（CDN/anycast 站尤其明显）。
# 对策：强制 LAN 客户端 DNS 走本机 dnsmasq。
#   1) 明文 DNS(UDP+TCP/53) 改道到本机 dnsmasq（原版仅劫持 UDP/53，这里补 TCP/53）；
#   2) 拦 DoT(853) 与已知 DoH 解析器 IP 的 443(TCP/QUIC)，逼客户端回退明文 DNS→被改道。
# 规则不依赖 dnsmasq 瞬时状态：default 档同样改道到本机 dnsmasq，二者对 dnsmasq 的依赖完全相同
# (原版或 fastlookup 均可)，重启间隙由客户端自行重试。仅当 iptables 规则写入失败才返回 1 回退
# default。只作用于转发的客户端流量(FORWARD/PREROUTING -i br+)，不影响路由器自身上游 DNS(走 OUTPUT)。
apply_dns_force(){
	[ "$ss_basic_dns_hijack" == "2" ] || return 1

	# TCP/53 能力探测（软降级）：本机无 TCP/53 监听则跳过 TCP 改道，
	# 避免把 TCP DNS 改道到不应答端口导致客户端 TCP 超时（"转圈"）。UDP 强制 + DoT/DoH 仍生效。
	local tcp53_ok=0
	netstat -tnl 2>/dev/null | grep -qE "[:.]53[[:space:]]" && tcp53_ok=1

	# 明文 DNS 改道：-I PREROUTING 1 确保先于 nat SHADOWSOCKS 链，否则 TCP/53 发往境外
	# 解析器会命中 !chnroute 被 REDIRECT 进代理。目的为本机的 53 不改道，避免环路。
	local br dst applied=0
	for br in $(ifconfig | grep -E "^br" | awk '{print $1}'); do
		dst=$(ifconfig "$br" | grep "inet addr" | awk '{print $2}' | awk -F: '{print $2}')
		[ -n "$dst" ] || continue
		iptables -t nat -I PREROUTING 1 -i "$br" -p udp --dport 53 ! -d "$dst" -j DNAT --to-destination "$dst":53 >/dev/null 2>&1 && applied=1
		[ "$tcp53_ok" == "1" ] && iptables -t nat -I PREROUTING 1 -i "$br" -p tcp --dport 53 ! -d "$dst" -j DNAT --to-destination "$dst":53 >/dev/null 2>&1
	done
	if [ "$applied" != "1" ]; then
		echo_date "DNS劫持(all)：53 改道规则写入失败，自动回退默认劫持(default)。"
		clean_dns_force
		return 1
	fi
	[ "$tcp53_ok" != "1" ] && echo_date "DNS劫持(all)：本机未监听 TCP/53，已跳过 TCP/53 改道（仅 UDP 强制 + DoT/DoH）。"

	# 加密 DNS 拦截链（REJECT 不可用自动 DROP）
	ipset -! create ss_doh nethash >/dev/null 2>&1 && ipset flush ss_doh >/dev/null 2>&1
	# 已知公共 DoH/DoT 解析器 IP（Cloudflare/Google/Quad9/OpenDNS/AdGuard/CleanBrowsing/NextDNS 等）
	for ip in 1.1.1.1 1.0.0.1 1.1.1.2 1.0.0.2 8.8.8.8 8.8.4.4 9.9.9.9 149.112.112.112 149.112.112.9 \
		208.67.222.222 208.67.220.220 94.140.14.14 94.140.15.15 76.76.2.0 76.76.10.0 \
		185.228.168.9 185.228.169.9 45.90.28.0 45.90.30.0; do
		ipset -! add ss_doh "$ip" >/dev/null 2>&1
	done
	iptables -t filter -N SHADOWSOCKS_DNSF >/dev/null 2>&1
	iptables -t filter -F SHADOWSOCKS_DNSF >/dev/null 2>&1
	# DoT：TCP/UDP 853
	iptables -t filter -A SHADOWSOCKS_DNSF -p tcp --dport 853 -j REJECT --reject-with tcp-reset >/dev/null 2>&1 || \
		iptables -t filter -A SHADOWSOCKS_DNSF -p tcp --dport 853 -j DROP >/dev/null 2>&1
	iptables -t filter -A SHADOWSOCKS_DNSF -p udp --dport 853 -j REJECT --reject-with icmp-port-unreachable >/dev/null 2>&1 || \
		iptables -t filter -A SHADOWSOCKS_DNSF -p udp --dport 853 -j DROP >/dev/null 2>&1
	# DoH：已知解析器 IP 的 443（TCP 与 UDP/HTTP3），REJECT 促浏览器回退明文 DNS
	iptables -t filter -A SHADOWSOCKS_DNSF -p tcp --dport 443 -m set --match-set ss_doh dst -j REJECT --reject-with tcp-reset >/dev/null 2>&1 || \
		iptables -t filter -A SHADOWSOCKS_DNSF -p tcp --dport 443 -m set --match-set ss_doh dst -j DROP >/dev/null 2>&1
	iptables -t filter -A SHADOWSOCKS_DNSF -p udp --dport 443 -m set --match-set ss_doh dst -j REJECT --reject-with icmp-port-unreachable >/dev/null 2>&1 || \
		iptables -t filter -A SHADOWSOCKS_DNSF -p udp --dport 443 -m set --match-set ss_doh dst -j DROP >/dev/null 2>&1
	iptables -t filter -A SHADOWSOCKS_DNSF -j RETURN >/dev/null 2>&1
	iptables -t filter -I FORWARD 1 -i br+ -j SHADOWSOCKS_DNSF >/dev/null 2>&1
	echo_date DNS劫持：全部强制模式\(all\)已启用\(改道TCP/UDP-53，拦截DoT/DoH\)，确保白名单可靠生效。
	return 0
}

# 清理 DNS 强制(all)产生的规则/集合（档位切换回退与停止流程复用）
clean_dns_force(){
	while iptables -t filter -D FORWARD -i br+ -j SHADOWSOCKS_DNSF >/dev/null 2>&1; do :; done
	iptables -t filter -F SHADOWSOCKS_DNSF >/dev/null 2>&1
	iptables -t filter -X SHADOWSOCKS_DNSF >/dev/null 2>&1
	local br dst
	for br in $(ifconfig 2>/dev/null | grep -E "^br" | awk '{print $1}'); do
		dst=$(ifconfig "$br" | grep "inet addr" | awk '{print $2}' | awk -F: '{print $2}')
		[ -n "$dst" ] || continue
		while iptables -t nat -D PREROUTING -i "$br" -p udp --dport 53 ! -d "$dst" -j DNAT --to-destination "$dst":53 >/dev/null 2>&1; do :; done
		while iptables -t nat -D PREROUTING -i "$br" -p tcp --dport 53 ! -d "$dst" -j DNAT --to-destination "$dst":53 >/dev/null 2>&1; do :; done
	done
	ipset -F ss_doh >/dev/null 2>&1 && ipset -X ss_doh >/dev/null 2>&1
}

# create ipset rules
create_ipset(){
	echo_date 创建ipset名单
	ipset -! create white_list nethash && ipset flush white_list
	ipset -! create black_list nethash && ipset flush black_list
	ipset -! create gfwlist nethash && ipset flush gfwlist
	ipset -! create router nethash && ipset flush router
	ipset -! create chnroute nethash && ipset flush chnroute
	sed -e "s/^/add chnroute &/g" /koolshare/ss/rules/chnroute.txt | awk '{print $0} END{print "COMMIT"}' | ipset -R
}

# 域名黑白名单预解析：主动解析域名A记录并直接写入ipset，不再只依赖dnsmasq被动填充。
# 客户端走DoH/DoT或持有DNS缓存时会绕过路由器dnsmasq，白名单域名IP长期缺席white_list，
# 就被mode链(CHN !chnroute / GLO 无条件)兜底代理——这正是"加白名单域名仍走代理"的根因。
# 本函数在apply_nat_rules之前(add_white_black_ip内)调用，此时代理规则尚未建立，解析走直连。
resolve_domain_to_ipset(){
	local d="$1" setname="$2" dns="$3" ip ips=""
	[ -n "$dns" ] && ips=`nslookup "$d" "$dns" 2>/dev/null | sed '1,4d' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -v '^0\.'`
	[ -z "$ips" ] && ips=`resolveip -4 -t 2 "$d" 2>/dev/null | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}'`
	for ip in $ips; do
		ipset -! add "$setname" "$ip" >/dev/null 2>&1
	done
}

add_white_black_ip(){
	# black ip/cidr
	if [ "$ss_basic_mode" != "6" ];then
		ip_tg="149.154.0.0/16 91.108.4.0/22 91.108.56.0/24 109.239.140.0/24 67.198.55.0/24"
		for ip in $ip_tg
		do
			ipset -! add black_list $ip >/dev/null 2>&1
		done
	fi
	
	if [ -n "$ss_wan_black_ip" ];then
		ss_wan_black_ip=`dbus get ss_wan_black_ip|base64_decode|sed '/\#/d'`
		echo_date 应用IP/CIDR黑名单
		for ip in $ss_wan_black_ip
		do
			ipset -! add black_list $ip >/dev/null 2>&1
		done
	fi
	
	# white ip/cidr
	[ -n "$ss_basic_server_ip" ] && SERVER_IP="$ss_basic_server_ip" || SERVER_IP=""
	[ -n "$IFIP_DNS1" ] && ISP_DNS_a="$ISP_DNS1" || ISP_DNS_a=""
	[ -n "$IFIP_DNS2" ] && ISP_DNS_b="$ISP_DNS2" || ISP_DNS_a=""
	ip_lan="0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/4 240.0.0.0/4 223.5.5.5 223.6.6.6 114.114.114.114 114.114.115.115 1.2.4.8 210.2.4.8 117.50.11.11 117.50.22.22 180.76.76.76 119.29.29.29 $ISP_DNS_a $ISP_DNS_b $SERVER_IP $(get_wan0_cidr)"
	for ip in $ip_lan
	do
		ipset -! add white_list $ip >/dev/null 2>&1
	done
	
	if [ -n "$ss_wan_white_ip" ];then
		ss_wan_white_ip=`echo $ss_wan_white_ip|base64_decode|sed '/\#/d'`
		echo_date 应用IP/CIDR白名单
		for ip in $ss_wan_white_ip
		do
			ipset -! add white_list $ip >/dev/null 2>&1
		done
	fi

	# 域名黑白名单预解析(白名单失效的核心修复)：解析DNS用国内公共DNS，与直连语义一致。
	# $CDN此阶段可能是127.0.0.1(smartdns/chinadns前端口)尚未就绪，回退到223.5.5.5。
	local PRE_DNS="$CDN"
	case "$PRE_DNS" in 127.0.0.1*|localhost*|""|:*) PRE_DNS="223.5.5.5" ;; esac
	if [ -n "$ss_wan_white_domain" ];then
		echo_date 预解析域名白名单到white_list，确保白名单域名可靠直连...
		for d in `echo $ss_wan_white_domain|base64_decode`; do
			detect_domain "$d" && resolve_domain_to_ipset "$d" white_list "$PRE_DNS"
		done
	fi
	if [ -n "$ss_wan_black_domain" ];then
		echo_date 预解析域名黑名单到black_list...
		for d in `echo $ss_wan_black_domain|base64_decode`; do
			detect_domain "$d" && resolve_domain_to_ipset "$d" black_list "$PRE_DNS"
		done
	fi
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

get_mode_name() {
	case "$1" in
		0)
			echo "不通过SS"
		;;
		1)
			echo "gfwlist模式"
		;;
		2)
			echo "大陆白名单模式"
		;;
		3)
			echo "游戏模式"
		;;
		5)
			echo "全局模式"
		;;
		6)
			echo "回国模式"
		;;
	esac
}

factor(){
	if [ -z "$1" ] || [ -z "$2" ]; then
		echo ""
	else
		echo "$2 $1"
	fi
}

get_jump_mode(){
	case "$1" in
		0)
			echo "j"
		;;
		*)
			echo "g"
		;;
	esac
}

lan_acess_control(){
	# lan access control
	acl_nu=`dbus list ss_acl_mode_|cut -d "=" -f 1 | cut -d "_" -f 4 | sort -n`
	if [ -n "$acl_nu" ]; then
		for acl in $acl_nu
		do
			ipaddr=`dbus get ss_acl_ip_$acl`
			ipaddr_hex=`dbus get ss_acl_ip_$acl | awk -F "." '{printf ("0x%02x", $1)} {printf ("%02x", $2)} {printf ("%02x", $3)} {printf ("%02x\n", $4)}'`
			ports=`dbus get ss_acl_port_$acl`
			proxy_mode=`dbus get ss_acl_mode_$acl`
			# 游戏模式仅限SS协议：非SS节点下该主机按大陆白名单处理(TCP走CHN链，UDP不做全量mangle)
			[ "$proxy_mode" == "3" ] && [ "$ss_basic_type" != "0" ] && proxy_mode=2
			proxy_name=`dbus get ss_acl_name_$acl`
			if [ "$ports" == "all" ];then
				ports=""
				echo_date 加载ACL规则：【$ipaddr】【全部端口】模式为：$(get_mode_name $proxy_mode)
			else
				echo_date 加载ACL规则：【$ipaddr】【$ports】模式为：$(get_mode_name $proxy_mode)
			fi
			# 1 acl in SHADOWSOCKS for nat
			iptables -t nat -A SHADOWSOCKS $(factor $ipaddr "-s") -p tcp $(factor $ports "-m multiport --dport") -$(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
			# 2 acl in OUTPUT（used by koolproxy）
			iptables -t nat -A SHADOWSOCKS_EXT -p tcp  $(factor $ports "-m multiport --dport") -m mark --mark "$ipaddr_hex" -$(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
			# 3 acl in SHADOWSOCKS for mangle
			if [ "$proxy_mode" == "3" ];then
				iptables -t mangle -A SHADOWSOCKS $(factor $ipaddr "-s") -p udp $(factor $ports "-m multiport --dport") -$(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
			else
				[ "$mangle" == "1" ] && iptables -t mangle -A SHADOWSOCKS $(factor $ipaddr "-s") -p udp -j RETURN
			fi
		done

		if [ "$ss_acl_default_port" == "all" ];then
			ss_acl_default_port=""
			[ -z "$ss_acl_default_mode" ] && dbus set ss_acl_default_mode="$ss_basic_mode" && ss_acl_default_mode="$ss_basic_mode"
			echo_date 加载ACL规则：【剩余主机】【全部端口】模式为：$(get_mode_name $ss_acl_default_mode)
		else
			echo_date 加载ACL规则：【剩余主机】【$ss_acl_default_port】模式为：$(get_mode_name $ss_acl_default_mode)
		fi
	else
		ss_acl_default_mode="$ss_basic_mode"
		if [ "$ss_acl_default_port" == "all" ];then
			ss_acl_default_port="" 
			echo_date 加载ACL规则：【全部主机】【全部端口】模式为：$(get_mode_name $ss_acl_default_mode)
		else
			echo_date 加载ACL规则：【全部主机】【$ss_acl_default_port】模式为：$(get_mode_name $ss_acl_default_mode)
		fi
	fi
	dbus remove ss_acl_ip
	dbus remove ss_acl_name
	dbus remove ss_acl_mode
	dbus remove ss_acl_port
}

apply_nat_rules(){
	#----------------------BASIC RULES---------------------
	echo_date 写入iptables规则到nat表中...
	# 创建SHADOWSOCKS nat rule
	iptables -t nat -N SHADOWSOCKS
	# 扩展
	iptables -t nat -N SHADOWSOCKS_EXT
	# IP/cidr/白域名 白名单控制（不走ss）
	iptables -t nat -A SHADOWSOCKS -p tcp -m set --match-set white_list dst -j RETURN
	iptables -t nat -A SHADOWSOCKS_EXT -p tcp -m set --match-set white_list dst -j RETURN
	#-----------------------FOR GLOABLE---------------------
	# 创建gfwlist模式nat rule
	iptables -t nat -N SHADOWSOCKS_GLO
	# 白名单最高优先(防御纵深，与主链SHADOWSOCKS的white RETURN一致，防经ACL直连mode链绕过)
	iptables -t nat -A SHADOWSOCKS_GLO -p tcp -m set --match-set white_list dst -j RETURN
	# IP黑名单控制-gfwlist（走ss）
	iptables -t nat -A SHADOWSOCKS_GLO -p tcp -j REDIRECT --to-ports 3333
	#-----------------------FOR GFWLIST---------------------
	# 创建gfwlist模式nat rule
	iptables -t nat -N SHADOWSOCKS_GFW
	# 白名单最高优先(防御纵深)
	iptables -t nat -A SHADOWSOCKS_GFW -p tcp -m set --match-set white_list dst -j RETURN
	# IP/CIDR/黑域名 黑名单控制（走ss）
	iptables -t nat -A SHADOWSOCKS_GFW -p tcp -m set --match-set black_list dst -j REDIRECT --to-ports 3333
	# IP黑名单控制-gfwlist（走ss）
	iptables -t nat -A SHADOWSOCKS_GFW -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-ports 3333
	#-----------------------FOR CHNMODE---------------------
	# 创建大陆白名单模式nat rule
	iptables -t nat -N SHADOWSOCKS_CHN
	# 白名单最高优先(防御纵深)
	iptables -t nat -A SHADOWSOCKS_CHN -p tcp -m set --match-set white_list dst -j RETURN
	# IP/CIDR/域名 黑名单控制（走ss）
	iptables -t nat -A SHADOWSOCKS_CHN -p tcp -m set --match-set black_list dst -j REDIRECT --to-ports 3333
	# cidr黑名单控制-chnroute（走ss）
	iptables -t nat -A SHADOWSOCKS_CHN -p tcp -m set ! --match-set chnroute dst -j REDIRECT --to-ports 3333
	#-----------------------FOR GAMEMODE---------------------
	# 创建游戏模式nat rule
	iptables -t nat -N SHADOWSOCKS_GAM
	# 白名单最高优先(防御纵深)
	iptables -t nat -A SHADOWSOCKS_GAM -p tcp -m set --match-set white_list dst -j RETURN
	# IP/CIDR/域名 黑名单控制（走ss）
	iptables -t nat -A SHADOWSOCKS_GAM -p tcp -m set --match-set black_list dst -j REDIRECT --to-ports 3333
	# cidr黑名单控制-chnroute（走ss）
	iptables -t nat -A SHADOWSOCKS_GAM -p tcp -m set ! --match-set chnroute dst -j REDIRECT --to-ports 3333
	#-----------------------FOR HOMEMODE---------------------
	# 创建回国模式nat rule
	 iptables -t nat -N SHADOWSOCKS_HOM
	# 白名单最高优先(防御纵深)
	iptables -t nat -A SHADOWSOCKS_HOM -p tcp -m set --match-set white_list dst -j RETURN
	# IP/CIDR/域名 黑名单控制（走ss）
	iptables -t nat -A SHADOWSOCKS_HOM -p tcp -m set --match-set black_list dst -j REDIRECT --to-ports 3333
	# cidr黑名单控制-chnroute（走ss）
	iptables -t nat -A SHADOWSOCKS_HOM -p tcp -m set --match-set chnroute dst -j REDIRECT --to-ports 3333

	# UDP透明代理前置：TPROXY能力探测(B1) + fwmark/table冲突检测(B4)。
	# 任一不满足则降级为TCP-only(mangle=""，后续所有UDP mangle/TPROXY规则自动跳过)，
	# 境外UDP仍由filter层guard拦截并促TCP回退，绝不静默直连。
	if [ "$mangle" == "1" ]; then
		if ! load_tproxy; then
			mangle=""
		elif ip rule show 2>/dev/null | grep -qE "fwmark 0x7( |/|$)" && [ -z "`ip rule show 2>/dev/null | grep 'lookup 310'`" ]; then
			# 别的组件占用了fwmark 0x07但不是我们的table 310路由，避免抢占
			echo_date "检测到fwmark 0x07已被其它组件占用(QoS/VPN?)，为避免冲突降级为TCP-only。"
			mangle=""
		elif [ -n "`ip route show table 310 2>/dev/null`" ] && [ -z "`ip route show table 310 2>/dev/null | grep 'local 0.0.0.0/0 dev lo'`" ]; then
			echo_date "检测到table 310已被其它组件占用，为避免冲突降级为TCP-only。"
			mangle=""
		else
			ip rule add fwmark 0x07 table 310
			ip route add local 0.0.0.0/0 dev lo table 310
		fi
	fi
	if [ "$mangle" == "1" ]; then
		# mangle UDP 总入口
		iptables -t mangle -N SHADOWSOCKS
		# DNS(UDP/53)优先RETURN，留给NAT层DNS劫持处理，避免LAN DNS查询被TPROXY误送入代理(B5)
		iptables -t mangle -A SHADOWSOCKS -p udp --dport 53 -j RETURN
		# IP/cidr/白域名 白名单控制（不走ss）
		iptables -t mangle -A SHADOWSOCKS -p udp -m set --match-set white_list dst -j RETURN
		# 预建全部模式的 mangle action 链，各填对应 UDP TPROXY 语义（镜像 nat 的 TCP 语义）。
		# 否则混合 ACL（如主模式白名单、某设备 ACL 为游戏模式）会跳转到未创建的 SHADOWSOCKS_GAM
		# 等链而报错、只留半套规则，脚本却仍报启动成功。
		for MCHAIN in SHADOWSOCKS_GFW SHADOWSOCKS_CHN SHADOWSOCKS_GAM SHADOWSOCKS_GLO SHADOWSOCKS_HOM; do
			iptables -t mangle -N $MCHAIN
			# 白名单最高优先(防御纵深，镜像nat的mode链white RETURN，确保白名单UDP也直连)
			iptables -t mangle -A $MCHAIN -p udp -m set --match-set white_list dst -j RETURN
		done
		# GFW：黑名单 + gfwlist 命中走代理
		iptables -t mangle -A SHADOWSOCKS_GFW -p udp -m set --match-set black_list dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
		iptables -t mangle -A SHADOWSOCKS_GFW -p udp -m set --match-set gfwlist dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
		# CHN（大陆白名单）：黑名单 + 非大陆走代理
		iptables -t mangle -A SHADOWSOCKS_CHN -p udp -m set --match-set black_list dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
		iptables -t mangle -A SHADOWSOCKS_CHN -p udp -m set ! --match-set chnroute dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
		# GAM（游戏）：与大陆白名单同，境外 UDP 走代理
		iptables -t mangle -A SHADOWSOCKS_GAM -p udp -m set --match-set black_list dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
		iptables -t mangle -A SHADOWSOCKS_GAM -p udp -m set ! --match-set chnroute dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
		# GLO（全局）：全部 UDP 走代理
		iptables -t mangle -A SHADOWSOCKS_GLO -p udp -j TPROXY --on-port 3333 --tproxy-mark 0x07
		# HOM（回国）：黑名单 + 大陆走代理
		iptables -t mangle -A SHADOWSOCKS_HOM -p udp -m set --match-set black_list dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
		iptables -t mangle -A SHADOWSOCKS_HOM -p udp -m set --match-set chnroute dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
	fi
	#-------------------------------------------------------
	# 局域网黑名单（不走ss）/局域网黑名单（走ss）
	lan_acess_control
	#-----------------------FOR ROUTER---------------------
	# router itself
	[ "$ss_basic_mode" != "6" ] && iptables -t nat -A OUTPUT -p tcp -m set --match-set router dst -j REDIRECT --to-ports 3333
	iptables -t nat -A OUTPUT -p tcp -m mark --mark "$ip_prefix_hex" -j SHADOWSOCKS_EXT
	
	# 把最后剩余流量重定向到相应模式的nat表中对应的主模式的链
	iptables -t nat -A SHADOWSOCKS -p tcp $(factor $ss_acl_default_port "-m multiport --dport") -j $(get_action_chain $ss_acl_default_mode)
	iptables -t nat -A SHADOWSOCKS_EXT -p tcp $(factor $ss_acl_default_port "-m multiport --dport") -j $(get_action_chain $ss_acl_default_mode)
	
	# 如果是主模式游戏模式，则把SHADOWSOCKS链中剩余udp流量转发给SHADOWSOCKS_GAM链
	# 如果主模式不是游戏模式，则不需要把SHADOWSOCKS链中剩余udp流量转发给SHADOWSOCKS_GAM，不然会造成其他模式主机的udp也走游戏模式
	###[ "$mangle" == "1" ] && ss_acl_default_mode=3
	[ "$ss_acl_default_mode" != "0" ] && [ "$ss_acl_default_mode" != "3" ] && [ "$ss_basic_udp_sync" != "1" ] && [ "$ss_basic_udp_sync" != "2" ] && [ "$ss_basic_udp_sync" != "3" ]  && ss_acl_default_mode=0
	[ "$mangle" == "1" ] && { [ "$ss_basic_mode" == "3" ] || [ "$ss_basic_udp_sync" == "1" ] || [ "$ss_basic_udp_sync" == "2" ] || [ "$ss_basic_udp_sync" == "3" ]; } && iptables -t mangle -A SHADOWSOCKS -p udp -j $(get_action_chain $ss_acl_default_mode)
	# 重定所有流量到 SHADOWSOCKS
	KP_NU=`iptables -nvL PREROUTING -t nat |sed 1,2d | sed -n '/KOOLPROXY/='|head -n1`
	[ "$KP_NU" == "" ] && KP_NU=0
	INSET_NU=`expr "$KP_NU" + 1`
	iptables -t nat -I PREROUTING "$INSET_NU" -p tcp -j SHADOWSOCKS
	if [ "$mangle" == "1" ]; then
		# 仅QUIC(=2)/仅QUIC+Game(=3)且无游戏需求时，只把QUIC(UDP/443)（及3档校验通过的Game端口）
		# 导入透明代理链，其余UDP一律直连，避免BT/视频等大流量UDP涌入TPROXY拖垮路由器CPU。
		# 存在游戏模式主机(game_on)或主模式为游戏模式时，游戏需要全量UDP，自动回退到全量代理。
		# 所有hook限定 -i br+：只接管LAN入站UDP，防WAN侧/其他接口的UDP误进TPROXY热路径。
		# 用 -I PREROUTING 1 插到最前(B2)：确保插件先于其它mangle规则看到LAN UDP，避免被抢先改道。
		if { [ "$ss_basic_udp_sync" == "2" ] || [ "$ss_basic_udp_sync" == "3" ]; } && [ -z "$game_on" ] && [ "$ss_basic_mode" != "3" ]; then
			# 黑名单目标是"强制走代理"语义，其UDP全端口一并导入代理链(黑名单条目少，不增负载)，
			# 与全量档一致；所有hook都跳SHADOWSOCKS，链内white-first + mode语义统一决策，
			# 因此Game端口同样按国内外分流：境外游戏服走代理，国内游戏服直连。
			iptables -t mangle -I PREROUTING 1 -i br+ -p udp -m set --match-set black_list dst -j SHADOWSOCKS
			# 普通目标只把QUIC(UDP/443)导入代理，其余UDP直连，降低ARMv7负载。
			iptables -t mangle -I PREROUTING 1 -i br+ -p udp --dport 443 -j SHADOWSOCKS
			GAME_PORTS=""
			[ "$ss_basic_udp_sync" == "3" ] && GAME_PORTS=$(validate_game_ports "$ss_basic_udp_sync_game_port")
			if [ -n "$GAME_PORTS" ]; then
				iptables -t mangle -I PREROUTING 1 -i br+ -p udp -m multiport --dports $GAME_PORTS -j SHADOWSOCKS
				echo_date "仅代理QUIC+Game模式：境外QUIC（UDP/443）、Game端口【$(echo $GAME_PORTS | sed 's/:/-/g')】与黑名单目标UDP导入透明代理，其余UDP直连。"
			elif [ "$ss_basic_udp_sync" == "3" ]; then
				if [ -n "$(echo "$ss_basic_udp_sync_game_port" | sed 's/[[:space:]]//g')" ]; then
					echo_date "Game端口【$ss_basic_udp_sync_game_port】语法非法（应如 27015,7777-7778，端口1-65535，总槽位≤15），已忽略，不代理该端口！"
				fi
				echo_date "仅代理QUIC+Game模式：Game端口未配置或未通过语法检查，本次仅代理境外QUIC（UDP/443）与黑名单目标UDP，其余UDP直连。"
			else
				echo_date 仅代理QUIC模式：境外QUIC（UDP/443）与黑名单目标UDP导入透明代理，其余UDP直连以降低路由器负载。
			fi
		else
			iptables -t mangle -I PREROUTING 1 -i br+ -p udp -j SHADOWSOCKS
		fi
	fi
	apply_forward_guard
	apply_ipv6_leak_guard
	# QOS开启的情况下
	QOSO=`iptables -t mangle -S | grep -o QOSO | wc -l`
	RRULE=`iptables -t mangle -S | grep "A QOSO" | head -n1 | grep RETURN`
	if [ "$QOSO" -gt "1" ] && [ -z "$RRULE" ];then
		iptables -t mangle -I QOSO0 -m mark --mark "$ip_prefix_hex" -j RETURN
	fi
}

dns_hijack_control(){
	local VLAN_INDEXS=$(ifconfig | grep -E "^br" | awk '{print $1}' | sed 's/^br//g')
	for VLAN_INDEX in ${VLAN_INDEXS}
	do
		local dest_ipaddr=$(ifconfig br${VLAN_INDEX} | grep "inet addr" | awk '{print $2}'|awk -F ":" '{print $2}')
		iptables -t nat -N SHADOWSOCKS_DNS_${VLAN_INDEX} >/dev/null 2>&1
		iptables -t nat -F SHADOWSOCKS_DNS_${VLAN_INDEX} >/dev/null 2>&1
		iptables -t nat -A SHADOWSOCKS_DNS_${VLAN_INDEX} -p udp -j DNAT --to ${dest_ipaddr}:53
	done
}

# 默认劫持(default/1)：原 chromecast 行为，仅把 LAN 客户端 UDP/53 DNAT 到本机 dnsmasq。
# 也作为 all 档规则写入失败时的回退目标。
dns_hijack_default(){
	dns_hijack_control
	local VLAN_INDEXS=$(ifconfig | grep -E "^br" | awk '{print $1}' | sed 's/^br//g')
	local INSET_NU_DNS=$((${INSET_NU} + 1))
	for VLAN_INDEX in ${VLAN_INDEXS}
	do
		iptables -t nat -I PREROUTING "${INSET_NU_DNS}" -i br${VLAN_INDEX} -p udp -m udp --dport 53 -j SHADOWSOCKS_DNS_${VLAN_INDEX}
		let INSET_NU_DNS+=1
	done
}

chromecast(){
	# 清理旧的默认劫持链跳转（SHADOWSOCKS_DNS_*）
	chromecast_nu=`iptables -t nat -L PREROUTING -v -n --line-numbers|grep "SHADOWSOCKS_DNS_"|awk '{print $1}'|sort -r`
	if [ -n "$chromecast_nu" ]; then
		for chromecast_index in $chromecast_nu
		do
			iptables -t nat -D PREROUTING $chromecast_index >/dev/null 2>&1
		done
	fi
	# 清理旧的 all 档强制规则，避免档位切换后残留
	clean_dns_force
	# DNS劫持三档：0=关闭 / 1=default(仅UDP/53劫持) / 2=all(强制全部+拦DoT/DoH)
	case "$ss_basic_dns_hijack" in
		2)
			if apply_dns_force; then
				:
			else
				# 仅当规则写入失败才回退 default，保证至少不比原版差
				dns_hijack_default
			fi
			;;
		1)
			echo_date 开启DNS劫持功能\(默认模式\)，防止DNS污染...
			dns_hijack_default
			;;
		*)
			echo_date DNS劫持功能未开启，建议开启！
			;;
	esac
}
# -----------------------------------nat part end--------------------------------------------------------

restart_dnsmasq(){
	# Restart dnsmasq
	echo_date 重启dnsmasq服务...
	service restart_dnsmasq >/dev/null 2>&1
}

load_module(){
	xt=`lsmod | grep xt_set`
	OS=$(uname -r)
	if [ -f /lib/modules/${OS}/kernel/net/netfilter/xt_set.ko ] && [ -z "$xt" ];then
		echo_date "加载xt_set.ko内核模块！"
		insmod /lib/modules/${OS}/kernel/net/netfilter/xt_set.ko
	fi
}

# write number into nvram with no commit
write_numbers(){
	nvram set update_ipset="$(cat /koolshare/ss/rules/version | sed -n 1p | sed 's/#/\n/g'| sed -n 1p)"
	nvram set update_chnroute="$(cat /koolshare/ss/rules/version | sed -n 2p | sed 's/#/\n/g'| sed -n 1p)"
	nvram set update_cdn="$(cat /koolshare/ss/rules/version | sed -n 4p | sed 's/#/\n/g'| sed -n 1p)"
	nvram set ipset_numbers=$(cat /koolshare/ss/rules/gfwlist.conf | grep -c ipset)
	nvram set chnroute_numbers=$(cat /koolshare/ss/rules/chnroute.txt | grep -c .)
	nvram set cdn_numbers=$(cat /koolshare/ss/rules/cdn.txt | grep -c .)
}

set_ulimit(){
	ulimit -n 16384
	echo 1 > /proc/sys/vm/overcommit_memory
}

remove_ss_reboot_job(){
	if [ -n "`cru l|grep ss_reboot`" ]; then
		echo_date 删除插件自动重启定时任务...
		#cru d ss_reboot >/dev/null 2>&1
		sed -i '/ss_reboot/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
}

set_ss_reboot_job(){
	if [[ "${ss_reboot_check}" == "0" ]]; then
		remove_ss_reboot_job
	elif [[	"${ss_reboot_check}" ==	"1"	]];	then
		echo_date 设置每天${ss_basic_time_hour}时${ss_basic_time_min}分重启插件...
		cru	a ss_reboot	${ss_basic_time_min} ${ss_basic_time_hour}"	* *	* /koolshare/ss/ssconfig.sh	restart"
	elif [[	"${ss_reboot_check}" ==	"2"	]];	then
		echo_date 设置每周${ss_basic_week}的${ss_basic_time_hour}时${ss_basic_time_min}分重启插件...
		cru	a ss_reboot	${ss_basic_time_min} ${ss_basic_time_hour}"	* *	"${ss_basic_week}" /koolshare/ss/ssconfig.sh restart"
	elif [[	"${ss_reboot_check}" ==	"3"	]];	then
		echo_date 设置每月${ss_basic_day}日${ss_basic_time_hour}时${ss_basic_time_min}分重启插件...
		cru	a ss_reboot	${ss_basic_time_min} ${ss_basic_time_hour} ${ss_basic_day}"	* *	/koolshare/ss/ssconfig.sh restart"
	elif [[	"${ss_reboot_check}" ==	"4"	]];	then
		if [[ "${ss_basic_inter_pre}" == "1" ]]; then
			echo_date 设置每隔${ss_basic_inter_min}分钟重启插件...
			cru	a ss_reboot	"*/"${ss_basic_inter_min}" * * * * /koolshare/ss/ssconfig.sh restart"
		elif [[	"${ss_basic_inter_pre}"	== "2" ]]; then
			echo_date 设置每隔${ss_basic_inter_hour}小时重启插件...
			cru	a ss_reboot	"0 */"${ss_basic_inter_hour}" *	* *	/koolshare/ss/ssconfig.sh restart"
		elif [[	"${ss_basic_inter_pre}"	== "3" ]]; then
			echo_date 设置每隔${ss_basic_inter_day}天${ss_basic_inter_hour}小时${ss_basic_time_min}分钟重启插件...
			cru	a ss_reboot	${ss_basic_time_min} ${ss_basic_time_hour}"	*/"${ss_basic_inter_day} " * * /koolshare/ss/ssconfig.sh restart"
		fi
	elif [[	"${ss_reboot_check}" ==	"5"	]];	then
		check_custom_time=`dbus	get	ss_basic_custom	| base64_decode`
		echo_date 设置每天${check_custom_time}时的${ss_basic_time_min}分重启插件...
		cru	a ss_reboot	${ss_basic_time_min} ${check_custom_time}" * * * /koolshare/ss/ssconfig.sh restart"
	else
		remove_ss_reboot_job
	fi
}

remove_ss_trigger_job(){
	if [ -n "`cru l|grep ss_tri_check`" ]; then
		echo_date 删除插件触发重启定时任务...
		#cru d ss_tri_check >/dev/null 2>&1
		sed -i '/ss_tri_check/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
}

set_ss_trigger_job(){
	if [ "$ss_basic_tri_reboot_time" == "0" ] || [ -z "$ss_basic_tri_reboot_time" ];then
		remove_ss_trigger_job
	else
		if [ "$ss_basic_tri_reboot_policy" == "1" ];then
			echo_date 设置每隔$ss_basic_tri_reboot_time分钟检查服务器IP地址，如果IP发生变化，则重启科学上网插件...
		else
			echo_date 设置每隔$ss_basic_tri_reboot_time分钟检查服务器IP地址，如果IP发生变化，则重启dnsmasq...
		fi
		cru d ss_tri_check  >/dev/null 2>&1
		cru a ss_tri_check "*/$ss_basic_tri_reboot_time * * * * /koolshare/scripts/ss_reboot_job.sh check_ip"
	fi
}

load_nat(){
	nat_ready=$(iptables -t nat -L PREROUTING -v -n --line-numbers|grep -v PREROUTING|grep -v destination)
	i=120
	until [ -n "$nat_ready" ]
	do
		i=$(($i-1))
		if [ "$i" -lt 1 ];then
			echo_date "错误：不能正确加载nat规则!"
			close_in_five
		fi
		sleep 1
		nat_ready=$(iptables -t nat -L PREROUTING -v -n --line-numbers|grep -v PREROUTING|grep -v destination)
	done
	echo_date "加载nat规则!"
	#create_ipset
	add_white_black_ip
	apply_nat_rules
	chromecast
}

ss_post_start(){
	# 在SS插件启动成功后触发脚本
	mkdir -p /koolshare/ss/postscripts && cd /koolshare/ss/postscripts
	for i in $(find ./ -name 'P*' | sort) ;
	do
		trap "" INT QUIT TSTP EXIT
		echo_date ------------- 【科学上网】 启动后触发脚本: $i -------------
		if [ -r "$i" ]; then
			$i start
		fi
		echo_date ----------------- 触发脚本: $i 运行完毕 -----------------
	done
}

ss_pre_stop(){
	# 在SS插件关闭前触发脚本
	mkdir -p /koolshare/ss/postscripts && cd /koolshare/ss/postscripts
	for i in $(find ./ -name 'P*' | sort -r) ;
	do
		trap "" INT QUIT TSTP EXIT
		echo_date ------------- 【科学上网】 关闭前触发脚本: $i ------------
		if [ -r "$i" ]; then
			$i stop
		fi
		echo_date ----------------- 触发脚本: $i 运行完毕 -----------------
	done
}

detect(){
	# 检测jffs2脚本是否开启，如果没有开启，将会影响插件的自启和DNS部分（dnsmasq.postconf）
	if [ "`nvram get jffs2_scripts`" != "1" ];then
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date "+     发现你未开启Enable JFFS custom scripts and configs选项！     +"
		echo_date "+    【软件中心】和【科学上网】插件都需要此项开启才能正常使用！！         +"
		echo_date "+     请前往【系统管理】- 【系统设置】去开启，并重启路由器后重试！！      +"
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		close_in_five
	fi
	
	# 检测是否在lan设置中是否自定义过dns,如果有给干掉
	if [ -n "`nvram get dhcp_dns1_x`" ];then
		nvram unset dhcp_dns1_x
		nvram commit
	fi
	if [ -n "`nvram get dhcp_dns2_x`" ];then
		nvram unset dhcp_dns2_x
		nvram commit
	fi
}

mount_dnsmasq(){
	# bind mount不影响运行中的进程，无需killall，换血由随后的service restart_dnsmasq完成。
	# 挂载前用fastlookup试析当前配置(--test)，不兼容则保留原版，避免替换后dnsmasq起不来断DNS。
	if ! /koolshare/bin/dnsmasq --test -C /etc/dnsmasq.conf >/dev/null 2>&1;then
		echo_date "【dnsmasq替换】：dnsmasq-fastlookup与当前dnsmasq配置不兼容，取消替换，继续使用原版dnsmasq！"
		return 1
	fi
	mount --bind /koolshare/bin/dnsmasq /usr/sbin/dnsmasq
}

umount_dnsmasq(){
	# 惰性卸载(-l)：运行中的进程不受影响，由随后的restart换回原版；循环清理可能叠加的多层挂载
	local umnt_i=0
	while mount | grep -q " on /usr/sbin/dnsmasq ";do
		umount -l /usr/sbin/dnsmasq 2>/dev/null || { killall dnsmasq >/dev/null 2>&1; umount /usr/sbin/dnsmasq >/dev/null 2>&1; }
		umnt_i=$((umnt_i + 1))
		[ "$umnt_i" -ge 5 ] && break
	done
}


mount_dnsmasq_now(){
	# 精确匹配挂载点，避免其它含"dnsmasq"字样的无关挂载(如别的插件bind的dnsmasq.conf)造成误判
	MOUNTED=$(mount | grep " on /usr/sbin/dnsmasq ")
	case $ss_basic_dnsmasq_fastlookup in
	0)
		if [ -n "$MOUNTED" ];then
			echo_date "【dnsmasq替换】：从dnsmasq-fastlookup切换为原版dnsmasq"
			umount_dnsmasq
		fi
		;;
	1|3)
		if [ -n "$MOUNTED" ];then
			echo_date "【dnsmasq替换】：dnsmasq-fastlookup已经替换过了！"
		else
			echo_date "【dnsmasq替换】：用dnsmasq-fastlookup替换原版dnsmasq！"
			mount_dnsmasq
		fi
		;;
	2)
		if [ -L "/jffs/configs/dnsmasq.d/cdn.conf" ];then
			if [ -z "$MOUNTED" ];then
				echo_date "【dnsmasq替换】：检测到cdn.conf，用dnsmasq-fastlookup替换原版dnsmasq！"
				mount_dnsmasq
			fi
		else
			if [ -n "$MOUNTED" ];then
				echo_date "【dnsmasq替换】：没有检测到cdn.conf，从dnsmasq-fastlookup切换为原版dnsmasq"
				umount_dnsmasq
			else
				echo_date "【dnsmasq替换】：没有检测到cdn.conf，不替换dnsmasq-fastlookup"
			fi
		fi
		;;
	esac
}

umount_dnsmasq_now(){
	MOUNTED=$(mount | grep " on /usr/sbin/dnsmasq ")
	case $ss_basic_dnsmasq_fastlookup in
	0|1|2)
		if [ -n "$MOUNTED" ];then
			echo_date "【dnsmasq替换】：从dnsmasq-fastlookup切换为原版dnsmasq"
			umount_dnsmasq
		fi
		;;
	3)
		if [ -n "$MOUNTED" ];then
			echo_date "【dnsmasq替换】：dnsmasq-fastlookup已经替换过了，插件关闭后保持替换！"
		else
			echo_date "【dnsmasq替换】：用dnsmasq-fastlookup替换原版dnsmasq！且插件关闭后保持替换！"
			mount_dnsmasq
		fi
		;;
	esac
}

disable_ss(){
	echo_date ======================= 梅林固件 - 【科学上网】 ========================
	echo_date
	echo_date ------------------------- 关闭【科学上网】 -----------------------------
	nvram set ss_mode=0
	dbus set dns2socks=0
	dbus remove ss_basic_server_ip
	nvram commit
	kill_process
	remove_ss_trigger_job
	remove_ss_reboot_job
	restore_conf
	# 先清空劫持/转发规则再动dnsmasq：若先卸载重启dnsmasq，DNS劫持规则仍把全网:53指向
	# 换血中的本机dnsmasq，会造成关闭插件瞬间的DNS中断窗口。
	flush_nat
	umount_dnsmasq_now
	restart_dnsmasq
	kill_cron_job
	echo_date ------------------------ 【科学上网】已关闭 ----------------------------
}

apply_ss(){
	# router is on boot
	WAN_ACTION=`ps|grep /jffs/scripts/wan-start|grep -v grep`
	# now stop first
	echo_date ======================= 梅林固件 - 【科学上网】 ========================
	echo_date
	echo_date ------------------------- 启动【科学上网】 -----------------------------
	ss_pre_stop
	nvram set ss_mode=0
	dbus set dns2socks=0
	nvram commit
	kill_process
	remove_ss_trigger_job
	remove_ss_reboot_job
	restore_conf
	# restart dnsmasq when ss server is not ip or on router boot
	restart_dnsmasq
	flush_nat
	kill_cron_job
	#echo_date ------------------------ 【科学上网】已关闭 ----------------------------
	# pre-start
	ss_pre_start
	# start
	#echo_date ------------------------- 启动 【科学上网】 ----------------------------
	detect
	resolv_server_ip
	load_module
	create_ipset
	create_dnsmasq_conf
	# do not re generate json on router start, use old one
	[ -z "$WAN_ACTION" ] && [ "$ss_basic_type" != "3" ] && [ "$ss_basic_type" != "4" ] && create_ss_json
	[ -z "$WAN_ACTION" ] && [ "$ss_basic_type" = "3" ] && [ "$SS2022" != "Y" ] && create_v2ray_json
	[ -z "$WAN_ACTION" ] && [ "$ss_basic_type" = "3" ] && [ "$SS2022" == "Y" ] && create_ss2022_json
	[ -z "$WAN_ACTION" ] && [ "$ss_basic_type" = "4" -a "$ss_basic_trojan_binary" == "Trojan" ] && create_trojan_json
	[ -z "$WAN_ACTION" ] && [ "$ss_basic_type" = "4" -a "$ss_basic_trojan_binary" == "Trojan-Go" ] && create_trojango_json
	[ -z "$WAN_ACTION" ] && [ "$ss_basic_type" = "5" ] && create_naive_json
	[ -z "$WAN_ACTION" ] && [ "$ss_basic_type" = "4" -a "$ss_basic_trojan_binary" == "Hysteria2" ] && create_hy2_json
	[ "$ss_basic_type" == "0" ] || [ "$ss_basic_type" == "1" ] && start_ss_redir
	[ "$ss_basic_type" == "2" ] && echo_date "koolgame已不再支持，跳过启动，请更换其它类型节点！"
	[ "$ss_basic_type" == "3" ] || [ "$ss_basic_type" == "4" -a "$ss_basic_trojan_binary" == "Trojan" ] && start_xray_core
	[ "$ss_basic_type" == "4" -a "$ss_basic_trojan_binary" == "Trojan-Go" ] && start_trojango
	[ "$ss_basic_type" == "5" ] && start_naiveproxy
	[ "$ss_basic_type" == "4" -a "$ss_basic_trojan_binary" == "Hysteria2" ] && start_hy2
	[ "$ss_basic_type" == "4" -a "$ss_basic_trojan_binary" == "AnyTLS" ] && start_anytls
	[ "$ss_basic_type" != "2" ] && start_dns
	# dnsmasq替换(fastlookup)：bind mount不影响运行中的进程，由紧随的restart_dnsmasq完成换血；
	# 放在create_dnsmasq_conf之后、load_nat之前，重启后即为最终形态。
	mount_dnsmasq_now
	restart_dnsmasq
	#===load nat start===
	load_nat
	#===load nat end===
	auto_start
	write_cron_job
	set_ss_reboot_job
	set_ss_trigger_job
	# post-start
	ss_post_start
	echo_date ------------------------ 【科学上网】 启动完毕 ------------------------
}

# for debug
get_status(){
	echo_date 
	echo_date =========================================================
	echo_date "PID of this script: $$"
	echo_date "PPID of this script: $PPID"
	echo_date ========== 本脚本的PID ==========
	ps|grep $$|grep -v grep
	echo_date ========== 本脚本的PPID ==========
	ps|grep $PPID|grep -v grep
	echo_date ========== 所有运行中的shell ==========
	ps|grep "\.sh"|grep -v grep
	echo_date ------------------------------------

	WAN_ACTION=`ps|grep /jffs/scripts/wan-start|grep -v grep`
	NAT_ACTION=`ps|grep /jffs/scripts/nat-start|grep -v grep`
	WEB_ACTION=`ps|grep "ss_config.sh"|grep -v grep`
	[ -n "$WAN_ACTION" ] && echo_date 路由器开机触发koolss重启！
	[ -n "$NAT_ACTION" ] && echo_date 路由器防火墙触发koolss重启！
	[ -n "$WEB_ACTION" ] && echo_date WEB提交操作触发koolss重启！
	
	iptables -nvL PREROUTING -t nat
	iptables -nvL OUTPUT -t nat
	iptables -nvL SHADOWSOCKS -t nat
	iptables -nvL SHADOWSOCKS_EXT -t nat
	iptables -nvL SHADOWSOCKS_GFW -t nat
	iptables -nvL SHADOWSOCKS_CHN -t nat
	iptables -nvL SHADOWSOCKS_GAM -t nat
	iptables -nvL SHADOWSOCKS_GLO -t nat
}

# =========================================================================

case $ACTION in
start)
	set_lock
	if [ "$ss_basic_enable" == "1" ];then
		logger "[软件中心]: 启动科学上网插件！"
		set_ulimit >> "$LOG_FILE"
		apply_ss >> "$LOG_FILE"
		write_numbers >> "$LOG_FILE"
	else
		logger "[软件中心]: 科学上网插件未开启，不启动！"
	fi
	#get_status >> /tmp/ss_start.txt
	unset_lock
	;;
stop)
	set_lock
	ss_pre_stop
	disable_ss
	echo_date
	echo_date 你已经成功关闭shadowsocks服务~
	echo_date See you again!
	echo_date
	echo_date ======================= 梅林固件 - 【科学上网】 ========================
	#get_status >> /tmp/ss_start.txt
	unset_lock
	;;
restart)
	set_lock
	set_ulimit
	apply_ss
	write_numbers
	echo_date
	echo_date "Across the Great Wall we can reach every corner in the world!"
	echo_date
	echo_date ======================= 梅林固件 - 【科学上网】 ========================
	#get_status >> /tmp/ss_start.txt
	unset_lock
	;;
flush_nat)
	set_lock
	flush_nat
	unset_lock
	;;
*)
	set_lock
	if [ "$ss_basic_enable" == "1" ];then
		set_ulimit
		apply_ss
		write_numbers
	fi
	#get_status >> /tmp/ss_start.txt
	unset_lock
	;;
esac
