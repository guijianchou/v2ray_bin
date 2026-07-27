#! /bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

eval `dbus export ss`
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
mkdir -p /koolshare/ss
mkdir -p /tmp/ss_backup

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

if [ "$ss_basic_enable" == "1" ];then
	echo_date 先关闭科学上网插件，保证文件更新成功!
	sh /koolshare/ss/ssconfig.sh stop
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
# 这两个键的网页默认值写在 <option ... selected> 里，而后端读到空值时会落到"关闭"分支。
# 不在这里补默认值的话，首装后界面显示"默认/关闭"、实际生效却是另一回事（DNS劫持尤其明显：
# 界面写着"默认（劫持UDP/53）"，chromecast 却走 *) 分支打印"DNS劫持功能未开启"），
# 而本脚本收尾会自动 restart 插件，用户在点过一次"提交"之前一直处于这个错位状态。
[ -z "$ss_basic_dns_hijack" ] && dbus set ss_basic_dns_hijack=1
[ -z "$ss_basic_udp_sync" ] && dbus set ss_basic_udp_sync=0
# Hysteria2 的透明UDP入站默认关：hy2 是QUIC协议、加解密开销远大于TCP类协议，
# 把UDP也压到同一条隧道上，弱路由器更容易先撞CPU上限。要用请在界面上显式打开。
[ -z "$ss_basic_hy2_udp" ] && dbus set ss_basic_hy2_udp=0
# 旧版本生成器固定写入 true；升级后延续原行为，避免新增开关改变已验证配置。
[ -z "$ss_basic_hy2_fast_open" ] && dbus set ss_basic_hy2_fast_open=1
[ -z "$ss_basic_hy2_lazy" ] && dbus set ss_basic_hy2_lazy=1
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
