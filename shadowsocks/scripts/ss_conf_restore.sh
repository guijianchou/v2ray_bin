#!/bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'

remove_first(){
	confs2=`dbus list ss | cut -d "=" -f 1 | sed '/version\|ssserver_\|ssid_\|ss_basic_state_china\|ss_basic_state_foreign/d'`
	for conf in $confs2
	do
		echo_date 移除$conf
		dbus remove $conf
	done
}

remove_first

echo_date 检测到ss备份文件...
# 头部直接拼接(原先sed的 '1 i\\n' 会插入字面量"n"，导致执行临时脚本时报 n: not found)
{
	echo '#!/bin/sh'
	echo 'source /koolshare/scripts/base.sh'
	echo ''
	< /tmp/ss_conf_backup.txt sed -e '/^ss/!d' -e '/_webtest_\|ssid_\|ssserver_\|_ping_\|ss_node_table\|_state_/d' -e 's/=/=\"/' -e 's/$/\"/g' -e 's/^/dbus set /'
} > /tmp/ss_conf_backup_tmp.sh
echo_date 开始恢复配置...
chmod +x /tmp/ss_conf_backup_tmp.sh
sh /tmp/ss_conf_backup_tmp.sh
sleep 1
dbus set ss_basic_enable="0"
[ -z "`dbus get ss_basic_hy2_udp`" ] && dbus set ss_basic_hy2_udp=0
[ -z "`dbus get ss_basic_hy2_fast_open`" ] && dbus set ss_basic_hy2_fast_open=1
[ -z "`dbus get ss_basic_hy2_lazy`" ] && dbus set ss_basic_hy2_lazy=1
dbus set ss_basic_version_local=`cat /koolshare/ss/version` 
echo_date 配置恢复成功！

echo_date 一点点清理工作...
rm -rf /tmp/ss_conf_*
echo_date 完成！
