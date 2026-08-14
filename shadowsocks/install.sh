#! /bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

eval `dbus export ss`
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
mkdir -p /koolshare/ss
mkdir -p /tmp/ss_backup

# 5.2.x 的“全部”档会把 TCP/UDP 53 DNAT 直接写进 PREROUTING，规则没有 comment 或
# 自有链名。旧版 stop 使用 while -D，会把第三方创建的完全同形规则一并删掉。
# 只有同时满足“旧配置仍为全部档”且插件自有 DNSF hook 仍在时，才能证明旧版完整地
# 下发过这组 DNAT；升级时每个网桥、每种协议只撤销一条，保留其余同形规则。
legacy_dns_force_marker_present(){
	[ "$ss_basic_enable" = "1" ] || return 1
	[ "$ss_basic_dns_hijack" = "2" ] || return 1
	iptables -t filter -S FORWARD 2>/dev/null | grep -Fq -- '-j SHADOWSOCKS_DNSF'
}

clean_owned_legacy_dns_force_dnat(){
	[ "$LEGACY_DNS_FORCE_OWNED" = "1" ] || return 0
	LEGACY_DNS_DNAT_REMOVED=0
	for LEGACY_DNS_BR in $(ifconfig 2>/dev/null | grep -E "^br" | awk '{print $1}'); do
		LEGACY_DNS_DST=$(ifconfig "$LEGACY_DNS_BR" 2>/dev/null | grep "inet addr" | awk '{print $2}' | awk -F: '{print $2}')
		[ -n "$LEGACY_DNS_DST" ] || continue
		if iptables -t nat -D PREROUTING -i "$LEGACY_DNS_BR" -p udp --dport 53 ! -d "$LEGACY_DNS_DST" -j DNAT --to-destination "$LEGACY_DNS_DST":53 >/dev/null 2>&1;then
			LEGACY_DNS_DNAT_REMOVED=$((LEGACY_DNS_DNAT_REMOVED + 1))
		fi
		if iptables -t nat -D PREROUTING -i "$LEGACY_DNS_BR" -p tcp --dport 53 ! -d "$LEGACY_DNS_DST" -j DNAT --to-destination "$LEGACY_DNS_DST":53 >/dev/null 2>&1;then
			LEGACY_DNS_DNAT_REMOVED=$((LEGACY_DNS_DNAT_REMOVED + 1))
		fi
	done
	echo_date "已按旧版 DNSF 所有权证据撤销 $LEGACY_DNS_DNAT_REMOVED 条旧【全部】档 53/DNAT；同形第三方规则保持不动。"
}

# 判断路由架构和平台
case $(uname -m) in
	armv7l)
		echo_date 固件平台【koolshare merlin armv7l】符合安装要求，开始安装插件！
	;;
	*)
		echo_date 本插件适用于koolshare merlin armv7l固件平台，你的平台"$(uname -m)"不能安装！！！
		echo_date 退出安装！
		exit 1
	;;
esac

# 低于7.2的固件不能安装
firmware_version=`nvram get extendno|cut -d "X" -f2|cut -d "-" -f1|cut -d "_" -f1`
firmware_comp=`versioncmp $firmware_version 7.2`
if [ "$firmware_comp" == "1" ];then
	echo_date 本插件不支持X7.2以下的固件版本，当前固件版本$firmware_version，请更新固件！
	echo_date 退出安装！
	exit 1
fi

LEGACY_DNS_FORCE_OWNED=0
legacy_dns_force_marker_present && LEGACY_DNS_FORCE_OWNED=1
if [ "$ss_basic_enable" == "1" ] && [ -f /koolshare/ss/ssconfig.sh ];then
	echo_date 先关闭科学上网插件，保证文件更新成功!
	# 必须使用待安装包内的新 stop：旧版 stop 的无界 DNS DNAT 清理无法区分第三方规则。
	if ! (cd /tmp/shadowsocks/ss && sh ./ssconfig.sh stop);then
		echo_date 待安装版本无法安全停止旧插件，安装中止，现有文件保持不变！
		exit 1
	fi
	clean_owned_legacy_dns_force_dnat
fi

if [ -n "`ls /koolshare/ss/postscripts/P*.sh 2>/dev/null`" ];then
	echo_date 备份触发脚本!
	find /koolshare/ss/postscripts -name "P*.sh" -exec mv -f {} /tmp/ss_backup \;
fi

# 如果dnsmasq是mounted状态，先恢复（精确匹配挂载点；惰性卸载不打断运行中的进程，由restart换血）
MOUNTED=$(mount | grep " on /usr/sbin/dnsmasq ")
if [ -n "$MOUNTED" ];then
	echo_date 恢复dnsmasq-fastlookup为原版dnsmasq
	umount -l /usr/sbin/dnsmasq 2>/dev/null || { killall dnsmasq >/dev/null 2>&1; umount /usr/sbin/dnsmasq >/dev/null 2>&1; }
	service restart_dnsmasq >/dev/null 2>&1
fi

echo_date 清理旧文件
TARGET_BIN="base64_encode cdns chinadns  chinadns1 chinadns-ng client_linux_arm5 dns2socks dnsmasq haproxy haveged hysteria anytls httping https_dns_proxy jq koolbox koolgame pdu resolveip rss-local rss-redir smartdns speederv1 speederv2 ss-local ss-redir ss-tunnel trojan-go naive udp2raw obfs-local xray"
rm -rf /koolshare/ss/*
rm -rf /koolshare/scripts/ss_*
rm -rf /koolshare/webs/Main_Ss*
cd /koolshare/bin && rm -f $TARGET_BIN && cd /tmp
rm -rf /koolshare/res/layer
rm -rf /koolshare/res/shadowsocks.css
rm -rf /koolshare/res/icon-shadowsocks.png
rm -rf /koolshare/res/ss-menu.js
rm -rf /koolshare/res/all.png
rm -rf /koolshare/res/gfwlist.png
rm -rf /koolshare/res/chn.png
rm -rf /koolshare/res/game.png
rm -rf /koolshare/res/shadowsocks.css
rm -rf /koolshare/res/gameV2.png
rm -rf /koolshare/res/ss_proc_status.htm
rm -rf /koolshare/init.d/S89Socks5.sh
find /koolshare/init.d/ -name "*socks5.sh" -exec rm -rf {} \;

echo_date 开始复制文件！
cd /tmp

echo_date 复制相关二进制文件！此步时间可能较长！
echo_date 如果长时间没有日志刷新，请等待2分钟后进入插件看是否安装成功..。
cp -rf /tmp/shadowsocks/bin/* /koolshare/bin/
chmod 755 /koolshare/bin/*

echo_date 复制相关的脚本文件！
cp -rf /tmp/shadowsocks/ss/* /koolshare/ss/
cp -rf /tmp/shadowsocks/scripts/* /koolshare/scripts/
cp -rf /tmp/shadowsocks/install.sh /koolshare/scripts/ss_install.sh
cp -rf /tmp/shadowsocks/uninstall.sh /koolshare/scripts/uninstall_shadowsocks.sh

echo_date 复制相关的网页文件！
cp -rf /tmp/shadowsocks/webs/* /koolshare/webs/
cp -rf /tmp/shadowsocks/res/* /koolshare/res/

echo_date 移除安装包！
rm -rf /tmp/shadowsocks* >/dev/null 2>&1

echo_date 为新安装文件赋予执行权限...
chmod 755 /koolshare/ss/cru/*
chmod 755 /koolshare/ss/rules/*
chmod 755 /koolshare/ss/*
chmod 755 /koolshare/scripts/ss*
chmod 755 /koolshare/bin/*

if [ -n "`ls /tmp/ss_backup/P*.sh 2>/dev/null`" ];then
	echo_date 恢复触发脚本!
	mkdir -p /koolshare/ss/postscripts
	find /tmp/ss_backup -name "P*.sh" | xargs -i mv {} -f /koolshare/ss/postscripts
fi

echo_date 创建一些二进制文件的软链接！
[ ! -L "/koolshare/bin/rss-tunnel" ] && ln -sf /koolshare/bin/rss-local /koolshare/bin/rss-tunnel
[ ! -L "/koolshare/bin/base64" ] && ln -sf /koolshare/bin/koolbox /koolshare/bin/base64
[ ! -L "/koolshare/bin/shuf" ] && ln -sf /koolshare/bin/koolbox /koolshare/bin/shuf
[ ! -L "/koolshare/bin/netstat" ] && ln -sf /koolshare/bin/koolbox /koolshare/bin/netstat
[ ! -L "/koolshare/bin/base64_decode" ] && ln -s /koolshare/bin/base64_encode /koolshare/bin/base64_decode
[ ! -L "/koolshare/init.d/S99socks5.sh" ] && ln -sf /koolshare/scripts/ss_socks5.sh /koolshare/init.d/S99socks5.sh

echo_date 设置一些默认值
[ -z "$ss_dns_china" ] && dbus set ss_dns_china=11
[ -z "$ss_basic_ss_v2ray_plugin" ] && dbus set ss_basic_ss_v2ray_plugin=0
# DNS 复选框在网页中默认勾选，UDP 档位的首项则是关闭；安装阶段补齐同样的后端默认值，
# 避免用户第一次保存前出现“页面已勾选、实际未启用”的错位。
case "$ss_basic_dns_hijack" in
	0|1) ;;
	*) dbus set ss_basic_dns_hijack=1 ;;
esac
dbus remove ss_runtime_dns_arbiter >/dev/null 2>&1
dbus remove ss_runtime_dns_fallback >/dev/null 2>&1
[ -z "$ss_basic_udp_sync" ] && dbus set ss_basic_udp_sync=0
# Hysteria2 的透明UDP入站已在 5.3.0 结构性下线（本固件内核 2.6.36.4 的 xt_TPROXY 不做
# UDP established 接管，hysteria 的 udpTProxy 会退化成一包一会话，见 README）。
# 界面开关与日志级别档位一并移除，这里清掉历史遗留键，避免旧值留在 dbus 里造成误解。
dbus remove ss_basic_hy2_udp >/dev/null 2>&1
dbus remove ss_basic_hy2_log_level >/dev/null 2>&1
dbus remove ss_runtime_hy2_udp_unsupported >/dev/null 2>&1
dbus remove ss_runtime_hy2_server_udp >/dev/null 2>&1
rm -f /tmp/hysteria.log >/dev/null 2>&1
# 旧版本生成器固定写入 true；升级后延续原行为，避免新增开关改变已验证配置。
[ -z "$ss_basic_hy2_fast_open" ] && dbus set ss_basic_hy2_fast_open=1
[ -z "$ss_basic_hy2_lazy" ] && dbus set ss_basic_hy2_lazy=1
# BBR standard 会按官方默认省略 congestion/bandwidth，需要独立模式键才能与新的 Brutal 默认区分。
# 旧的非空 JSON 由页面和生成器按 bandwidth/congestion 推断，不在安装阶段覆盖用户配置。
[ -z "$ss_basic_hy2_cc_mode" ] && [ -z "$ss_basic_hy2_global_json" ] && dbus set ss_basic_hy2_cc_mode=brutal
[ -z "$ss_acl_default_mode" ] && [ -n "$ss_basic_mode" ] && dbus set ss_acl_default_mode="$ss_basic_mode"
[ -z "$ss_acl_default_mode" ] && [ -z "$ss_basic_mode" ] && dbus set ss_acl_default_mode=1
[ -z "$ss_acl_default_port" ] && dbus set ss_acl_default_port=all
[ "$ss_basic_v2ray_network" == "ws_hd" ] && dbus set ss_basic_v2ray_network="ws"

# 移除一些没用的值
dbus remove ss_basic_version
# 死键：全项目无人读取（真键是 ss_foreign_dns），历史版本误写，清掉避免误导
dbus remove ss_dns_foreign

# 离线安装时设置软件中心内储存的版本号和连接
CUR_VERSION=`cat /koolshare/ss/version`
dbus set ss_basic_version_local="$CUR_VERSION"
dbus set softcenter_module_shadowsocks_install="4"
dbus set softcenter_module_shadowsocks_version="$CUR_VERSION"
dbus set softcenter_module_shadowsocks_title="Shadowsocks"
dbus set softcenter_module_shadowsocks_description="Shadowsocks for merlin armv7l 380"
dbus set softcenter_module_shadowsocks_home_url="Main_Ss_Content.asp"


echo_date 一点点清理工作...
rm -rf /tmp/shadowsocks* >/dev/null 2>&1
dbus set ss_basic_install_status="0"
echo_date 科学上网插件安装成功！

if [ "$ss_basic_enable" == "1" ];then
	echo_date 重启科学上网插件！
	dbus set ss_basic_action=1
	sh /koolshare/ss/ssconfig.sh restart
fi
echo_date 更新完毕，请等待网页自动刷新！
