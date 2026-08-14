#! /bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

sh /koolshare/ss/ssconfig.sh stop
sh /koolshare/scripts/ss_conf_remove.sh
sleep 1

# 如果dnsmasq是mounted状态，先恢复（精确匹配挂载点；惰性卸载不打断运行中的进程，由restart换血）
MOUNTED=$(mount | grep " on /usr/sbin/dnsmasq ")
if [ -n "$MOUNTED" ];then
	echo_date 恢复dnsmasq-fastlookup为原版dnsmasq
	umount -l /usr/sbin/dnsmasq 2>/dev/null || { killall dnsmasq >/dev/null 2>&1; umount /usr/sbin/dnsmasq >/dev/null 2>&1; }
	service restart_dnsmasq >/dev/null 2>&1
fi
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
rm -rf /koolshare/res/ss_udp_status.htm
rm -rf /koolshare/init.d/S89Socks5.sh

# remove start up command
# auto_start() 写的是 /jffs/scripts/ 下的 nat-start 与 wan-start，不是 /koolshare/scripts/：
#   nat-start  ← `sed -i '2a sh /koolshare/ss/ssconfig.sh'`
#   wan-start  ← `sed -i '2a sh /koolshare/scripts/ss_config.sh'`
# 上游这两行既写错了目录、又用 `ssconfig.sh` 去匹配 wan-start 里的 `ss_config.sh`
# （下划线对不上），结果卸载后两条钩子原样留在固件里，每次开机/拨号都去跑已被删掉的脚本。
# 保留对 /koolshare/scripts 的清理，兼容历史版本可能写在那里的残留。
sed -i '/ss_config.sh/d;/ssconfig.sh/d' /jffs/scripts/wan-start >/dev/null 2>&1
sed -i '/ss_config.sh/d;/ssconfig.sh/d' /jffs/scripts/nat-start >/dev/null 2>&1
sed -i '/ss_config.sh/d;/ssconfig.sh/d' /koolshare/scripts/wan-start >/dev/null 2>&1
sed -i '/ss_config.sh/d;/ssconfig.sh/d' /koolshare/scripts/nat-start >/dev/null 2>&1

# 运行时状态键（界面状态栏用）。这些键不属于用户配置，卸载后留着会让重装前的
# 旧状态显示在新装的界面上。
for k in ss_runtime_udp_state ss_runtime_udp_text ss_runtime_udp_probe \
         ss_runtime_udp_probe_text ss_runtime_udp_probe_time \
         ss_runtime_udp_probe_game_prev ss_runtime_udp_probe_game_prev_t \
         ss_runtime_dns_state ss_runtime_dns_text ss_runtime_dns_fastlookup \
         ss_runtime_dns_arbiter ss_runtime_dns_fallback \
         ss_runtime_hy2_udp_unsupported ss_runtime_hy2_server_udp \
         ss_basic_hy2_udp ss_basic_hy2_log_level; do
	dbus remove "$k" >/dev/null 2>&1
done
rm -f /tmp/hysteria.log >/dev/null 2>&1

dbus remove softcenter_module_shadowsocks_home_url
dbus remove softcenter_module_shadowsocks_install
dbus remove softcenter_module_shadowsocks_md5
dbus remove softcenter_module_shadowsocks_version

dbus remove ss_basic_enable
dbus remove ss_basic_version_local
dbus remove ss_basic_version_web
