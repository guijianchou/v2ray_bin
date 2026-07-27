<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta HTTP-EQUIV="Pragma" CONTENT="no-cache"/>
<meta HTTP-EQUIV="Expires" CONTENT="-1"/>
<link rel="shortcut icon" href="images/favicon.png"/>
<link rel="icon" href="images/favicon.png"/>
<title>【Shadowsocks】</title>
<link rel="stylesheet" type="text/css" href="index_style.css"/>
<link rel="stylesheet" type="text/css" href="form_style.css"/>
<link rel="stylesheet" type="text/css" href="usp_style.css"/>
<link rel="stylesheet" type="text/css" href="css/element.css">
<link rel="stylesheet" type="text/css" href="/device-map/device-map.css">
<link rel="stylesheet" type="text/css" href="/res/shadowsocks.css">
<link rel="stylesheet" type="text/css" href="/res/layer/theme/default/layer.css">
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/validator.js"></script>
<script type="text/javascript" src="/js/jquery.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/switcherplugin/jquery.iphone-switch.js"></script>
<script type="text/javascript" src="/client_function.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script type="text/javascript" src="/res/ss-menu.js"></script>
<script type="text/javascript" src="/dbconf?p=ss&v=<% uptime(); %>"></script>
<script>
var isMenuopen = 0;
var _responseLen;
var noChange = 0;
var noChange2 = 0;
var node_global_max = 0;
var myid;
var checkss = 0;
var poped = 0;
var x = 5;
var refreshRate;

function init() {
	show_menu(menu_hook);
	update_ss_ui(db_ss);
	loadAllConfigs();
	decode_show();
	toggle_func();
	version_show();
	hook_event();
	detect();
	refresh_udp_runtime();
	setTimeout("get_ss_status_data()", 500);
}

function hide_elem(){
	E("head_illustrate").style.display = "none";
	E("ss_switch_show").style.display = "none";
	E("ss_status1").style.display = "none";
	E("tablets").style.display = "none";
	E("tablet_1").style.display = "none";
	E("apply_button").style.display = "none";
	E("ss_switch_show").style.display = "none";
}

function detect(){
	var jff2_scripts="<% nvram_get("jffs2_scripts"); %>";
	var sw_mode="<% nvram_get("sw_mode"); %>";
	var dnsfilter_enable="<% nvram_get("dnsfilter_enable"); %>";
	var fw_version="<% nvram_get("extendno"); %>";
	var fw_version=parseFloat("<% nvram_get("extendno"); %>".split("X")[1]).toFixed(1);
	if(jff2_scripts != 1){ //没有开启 JFFS scripts选项
		hide_elem();
		E("warn_msg_1").style.display = "";
		$('#warn_msg_1').html('<h2><font color="#FF9900">错误！</font></h2><h2>【Shadowsocks】插件不可用！因为你没有开启Enable JFFS custom scripts and configs选项！</h2><h2>请前往【系统管理】-<a href="Advanced_System_Content.asp"><u><em>【系统设置】</em></u></a>开启此选项再使用软件中心！！</h2>');
	}
	if(sw_mode != 1){ //使用的不是路由模式
		hide_elem();
		E("warn_msg_1").style.display = "";
		$('#warn_msg_1').html('<h2><font color="#FF9900">错误！</font></h2><h2>【Shadowsocks】插件不可用！因为你的设备工作在非路由模式下！</h2><h2>请前往【系统管理】-<a href="Advanced_OperationMode_Content.asp"><u><em>【操作模式】</em></u></a>中选择无线路由器模式！才能正常使用本插件！</h2>');
	}
	if(dnsfilter_enable == 1){ //开启了DNSFilter
		hide_elem();
		E("warn_msg_1").style.display = "";
		$('#warn_msg_1').html('<h2><font color="#FF9900">错误！</font></h2><h2>【Shadowsocks】插件不可用！因为开启了DNS过滤！</h2><h2>请前往【智能网络卫士】-<a href="DNSFilter.asp"><u><em>【DNS Filtering】</em></u></a>中关闭DNS过滤！才能正常使用本插件！</h2>');
	}
	if(fw_version < 7.2){ //固件版本过低，不兼容
		hide_elem();
		E("warn_msg_1").style.display = "";
		$('#warn_msg_1').html('<h2><font color="#FF9900">错误！</font></h2><h2>【Shadowsocks】插件不可用！因为你的固件版本低于X7.2！</h2><h2>请更新最新固件！</h2>');
	}
}

function hook_event() {
	$("#mode_state").attr("cursor", "pointer");
	$("#mode_state").click(
	function() {
		pop_111();
	});
	
	$("#ss_basic_enable").click(
	function() {
		if (!E("ss_basic_enable").checked && db_ss["ss_basic_enable"] == 1) {
			save();
		}
	});
}

function pop_111() {
	require(['/res/layer/layer.js'], function(layer) {
		layer.open({
			type: 2,
			shade: .7,
			scrollbar: 0,
			title: '国内外分流信息:ip111.cn',
			area: ['750px', '480px'],
			//offset: ['355px', '368px'],
			fixed: false, //不固定
			maxmin: true,
			shadeClose: 1,
			id: 'LAY_layuipro',
			btnAlign: 'c',
			content: ['http://ip111.cn/', 'no'],
		});
	});
}

function pop_help() {
	require(['/res/layer/layer.js'], function(layer) {
		layer.open({
			type: 1,
			title: false,
			closeBtn: false,
			area: '600px;',
			//offset: ['355px', '443px'],
			shade: 0.8,
			shadeClose: 1,
			scrollbar: false,
			id: 'LAY_layuipro',
			btn: ['关闭窗口'],
			btnAlign: 'c',
			moveType: 1,
			content: '<div style="padding: 50px; line-height: 22px; background-color: #393D49; color: #fff; font-weight: 300;">\
				<b>梅林固件 - Shadowsocks 插件 - ' + db_ss["ss_basic_version_local"] + '</b><br><br>\
				<color style="color: red;">重要提示:此插件向后维护 xray/trojan/hysteria2 等功能更新，版本更新。</color><br><br>\
				<a target="_blank" href="https://github.com/guijianchou/v2ray_bin_lite"><u>本插件</u></a>是支持<a target="_blank" href="https://github.com/shadowsocks/shadowsocks-libev"><u>SS（含SS2022）</u></a>、<a target="_blank" href="https://github.com/XTLS/Xray-core"><u>Xray（VMess、VLESS、Trojan、Trojan-Go）</u></a>、<a target="_blank" href="https://github.com/apernet/hysteria/"><u>Hysteria2</u></a> 多协议客户端的科学上网工具；游戏模式（全量UDP加速）仅支持SS协议节点，其它协议可通过「同步UDP与TCP」按需代理QUIC与游戏端口。<br>				本插件仅支持Merlin AM380 2.6.36.4内核的固件，请不要用于其它固件安装。<br>\
				● 服务器一键搭建脚本：<a style="color:#e7bd16" target="_blank" href="https://github.com/guijianchou/v2ray_bin_lite/wiki"><u> 搭建和优化详细教程</u></a><br>\
				● 插件安装包下载地址：下载最新版的<a style="color:#e7bd16" target="_blank" href="https://github.com/guijianchou/v2ray_bin_lite/releases"><u> shadowsocks.tar.gz </u></a>安装包, 保存下来的文件名不要有空格<br><br>\
				我们的征途是星辰大海 ^_^</div>'
		});
	});
}

function pop_node_add() {
	require(['/res/layer/layer.js'], function(layer) {
		layer.open({
			type: 0,
			shade: 0.8,
			title: '警告',
			time: 0,
			//area: ['390px', '330px'],
			maxmin: true,
			content: '你尚未添加任何节点信息！<br /> 点击下面按钮添加节点信息！',
			btn: ['手动添加', '恢复配置'],
			yes: function() {
				$("#show_btn1_1").trigger("click");
				setTimeout("pop_tip()", 600);
				//layer.closeAll();
				layer.msg('请选择需要添加的节点类型', {
					shade: 0.2,
					time: 20000, //20s后自动关闭
					area: ['450px'],
					btn: ['添加SS节点', '添加V2Ray节点', '添加Trojan/Hysteria2/AnyTLS节点'],
					btnAlign: 'c',
					btn1: function(index, layero) {
						setTimeout("Add_profile();", 300);
						setTimeout("tabclickhandler(0);", 320);
						layer.closeAll();
					},
					btn2: function(index, layero) {
						setTimeout("Add_profile();", 300);
						setTimeout("tabclickhandler(3);", 320);
					},
					btn3: function(index, layero) {
						setTimeout("Add_profile();", 300);
						setTimeout("tabclickhandler(4);", 320);
					}
				});
			},
			btn2: function() {
				$("#show_btn6").trigger("click");
			},
		});
		poped = 1;
	});
}

function pop_tip(){
	layer.tips('以后需要添加节点，可以点击此按钮！', '#add_ss_node', {
		tips: [1, '#3595CC'],
		time: 5000
	});
}

function isJSON(str) {
	if (typeof str == 'string' && str) {
		try {
			var obj = JSON.parse(str);
			if (typeof obj == 'object' && obj) {
				return true;
			} else {
				return false;
			}
		} catch (e) {
			console.log('error：' + str + '!!!' + e);
			return false;
		}
	}
	//console.log('It is not a string!')
}

function makeHy2Bandwidth(label, valueId) {
	var value = E(valueId) ? $.trim(E(valueId).value) : "";
	if (!value) {
		return "";
	}
	if (!/^[1-9][0-9]*$/.test(value)) {
		alert("错误！Hysteria2 " + label + "带宽必须是正整数！");
		return false;
	}
	return value + " mbps";
}

function loadHy2Bandwidth(value, valueId) {
	if (!value) {
		return;
	}
	var match = String(value).match(/^\s*([0-9]+(?:\.[0-9]+)?)\s*([a-zA-Z]+)\s*$/);
	if (match && /^(mbps|mb|m)$/i.test(match[2])) {
		E(valueId).value = match[1];
	} else {
		E(valueId).value = value;
	}
}

function isValidHy2IPv4(host) {
	var octets = host.split(".");
	if (octets.length != 4) {
		return false;
	}
	for (var i = 0; i < octets.length; i++) {
		if (!/^(?:0|[1-9][0-9]{0,2})$/.test(octets[i]) || parseInt(octets[i], 10) > 255) {
			return false;
		}
	}
	return true;
}

function isValidHy2ServerHost(host) {
	if (!host || host.length > 254) {
		return false;
	}
	if (host.charAt(0) == "[" || host.charAt(host.length - 1) == "]") {
		if (!/^\[[0-9A-Fa-f:.]+\]$/.test(host)) {
			return false;
		}
		var ipv6 = host.substring(1, host.length - 1);
		if (ipv6.indexOf(".") != -1) {
			var ipv4Separator = ipv6.lastIndexOf(":");
			var ipv4Tail = ipv6.substring(ipv4Separator + 1);
			if (ipv4Separator == -1 || !isValidHy2IPv4(ipv4Tail)) {
				return false;
			}
			ipv6 = ipv6.substring(0, ipv4Separator) + ":0:0";
		}
		if (ipv6.indexOf(":") == -1 || ipv6.indexOf(":::") != -1) {
			return false;
		}
		var compressed = ipv6.indexOf("::") != -1;
		if (compressed && ipv6.indexOf("::") != ipv6.lastIndexOf("::")) {
			return false;
		}
		var ipv6Parts = ipv6.split(":");
		var groupCount = 0;
		for (var i = 0; i < ipv6Parts.length; i++) {
			if (!ipv6Parts[i]) {
				continue;
			}
			if (ipv6Parts[i].length > 4 || !/^[0-9A-Fa-f]+$/.test(ipv6Parts[i])) {
				return false;
			}
			groupCount++;
		}
		return compressed ? groupCount < 8 : groupCount == 8;
	}
	if (host.indexOf(":") != -1) {
		return false;
	}
	var domain = host.charAt(host.length - 1) == "." ? host.substring(0, host.length - 1) : host;
	if (!domain || domain.length > 253) {
		return false;
	}
	if (/^[0-9.]+$/.test(domain)) {
		return isValidHy2IPv4(domain);
	}
	var labels = domain.split(".");
	for (var k = 0; k < labels.length; k++) {
		if (labels[k].length < 1 || labels[k].length > 63 || !/^[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?$/.test(labels[k])) {
			return false;
		}
	}
	return true;
}

function validateHy2Endpoint() {
	if (!E("ss_basic_trojan_binary") || E("ss_basic_trojan_binary").value != "Hysteria2") {
		return true;
	}
	var server = E("ss_basic_server") ? $.trim(E("ss_basic_server").value) : "";
	var auth = E("ss_basic_password") ? $.trim(E("ss_basic_password").value) : "";
	var portSpec = E("ss_basic_port") ? $.trim(E("ss_basic_port").value) : "";
	if (!server || !auth) {
		alert("错误！Hysteria2 服务器地址和认证密码不能为空！");
		return false;
	}
	if (!isValidHy2ServerHost(server)) {
		alert("错误！Hysteria2 服务器地址必须是合法域名、IPv4 或方括号 IPv6，如 example.com、1.2.3.4、[2001:db8::1]！");
		return false;
	}
	if (!/^[0-9]+(?:-[0-9]+)?(?:,[0-9]+(?:-[0-9]+)?)*$/.test(portSpec)) {
		alert("错误！Hysteria2 端口必须是单端口或逗号分隔的端口段，如 443,20000-50000！");
		return false;
	}
	var ranges = portSpec.split(",");
	for (var i = 0; i < ranges.length; i++) {
		var bounds = ranges[i].split("-");
		var start = parseInt(bounds[0], 10);
		var end = bounds.length == 2 ? parseInt(bounds[1], 10) : start;
		if (start < 1 || start > 65535 || end < start || end > 65535) {
			alert("错误！Hysteria2 端口范围必须递增，且所有端点都在 1-65535！");
			return false;
		}
	}
	E("ss_basic_server").value = server;
	E("ss_basic_port").value = portSpec;
	return true;
}

function validateHy2GlobalJson() {
	if (!validateHy2Endpoint()) {
		return false;
	}
	var obj = {};
	var obfsType = E("ss_basic_hy2_obfs_type") ? E("ss_basic_hy2_obfs_type").value : "";
	var obfsPassword = E("ss_basic_hy2_obfs_password") ? $.trim(E("ss_basic_hy2_obfs_password").value) : "";
	var geckoMin = E("ss_basic_hy2_gecko_min") ? $.trim(E("ss_basic_hy2_gecko_min").value) : "";
	var geckoMax = E("ss_basic_hy2_gecko_max") ? $.trim(E("ss_basic_hy2_gecko_max").value) : "";
	var congestionType = E("ss_basic_hy2_congestion_type") ? E("ss_basic_hy2_congestion_type").value : "";
	var bbrProfile = E("ss_basic_hy2_bbr_profile") ? E("ss_basic_hy2_bbr_profile").value : "";
	var bandwidthUp = makeHy2Bandwidth("上行", "ss_basic_hy2_bandwidth_up_value");
	var bandwidthDown = makeHy2Bandwidth("下行", "ss_basic_hy2_bandwidth_down_value");
	var switches = [
		["ss_basic_hy2_udp", "UDP"],
		["ss_basic_hy2_fast_open", "fastOpen"],
		["ss_basic_hy2_lazy", "lazy"]
	];

	if (bandwidthUp === false || bandwidthDown === false) {
		return false;
	}
	for (var i = 0; i < switches.length; i++) {
		var switchValue = E(switches[i][0]) ? E(switches[i][0]).value : "";
		if (switchValue != "0" && switchValue != "1") {
			alert("错误！Hysteria2 " + switches[i][1] + " 开关值不合法！");
			return false;
		}
	}
	if (obfsType != "" && obfsType != "salamander" && obfsType != "gecko") {
		alert("错误！Hysteria2 混淆类型不合法！");
		return false;
	}
	if (congestionType != "" && congestionType != "bbr" && congestionType != "reno") {
		alert("错误！Hysteria2 拥塞控制类型不合法！");
		return false;
	}
	if (congestionType == "bbr" && bbrProfile != "standard" && bbrProfile != "conservative" && bbrProfile != "aggressive") {
		alert("错误！Hysteria2 BBR 模式不合法！");
		return false;
	}

	if (obfsType) {
		if (!obfsPassword) {
			alert("错误！启用 Hysteria2 混淆时必须填写混淆密码！");
			return false;
		}
		var passwordBytes = unescape(encodeURIComponent(obfsPassword)).length;
		if (passwordBytes < 4) {
			alert("错误！Hysteria2 混淆密码至少需要 4 字节！");
			return false;
		}
		obj.obfs = { type: obfsType };
		obj.obfs[obfsType] = { password: obfsPassword };
		if (obfsType == "gecko") {
			if (geckoMin) {
				if (!/^[1-9][0-9]*$/.test(geckoMin)) {
					alert("错误！Gecko 最小包大小必须是正整数！");
					return false;
				}
				obj.obfs.gecko.minPacketSize = parseInt(geckoMin, 10);
			}
			if (geckoMax) {
				if (!/^[1-9][0-9]*$/.test(geckoMax)) {
					alert("错误！Gecko 最大包大小必须是正整数！");
					return false;
				}
				obj.obfs.gecko.maxPacketSize = parseInt(geckoMax, 10);
			}
			var effectiveMin = obj.obfs.gecko.minPacketSize || 512;
			var effectiveMax = obj.obfs.gecko.maxPacketSize || 1200;
			if (effectiveMax < effectiveMin) {
				alert("错误！Gecko 最大包大小不能小于最小包大小！");
				return false;
			}
			if (effectiveMax > 2048) {
				alert("错误！Gecko 最大包大小不能超过 2048！");
				return false;
			}
		}
	}
	if (congestionType) {
		obj.congestion = { type: congestionType };
		if (congestionType == "bbr") {
			obj.congestion.bbrProfile = bbrProfile || "standard";
		}
	}
	if (bandwidthUp || bandwidthDown) {
		obj.bandwidth = {};
		if (bandwidthUp) {
			obj.bandwidth.up = bandwidthUp;
		}
		if (bandwidthDown) {
			obj.bandwidth.down = bandwidthDown;
		}
	}
	E("ss_basic_hy2_global_json").value = Object.keys(obj).length ? JSON.stringify(obj, null, 2) : "";
	var text = E("ss_basic_hy2_global_json").value;
	if (!text) {
		return true;
	}
	try {
		obj = JSON.parse(text);
		var allowed = {
			"obfs": true,
			"congestion": true,
			"bandwidth": true
		};
		if (!obj || Object.prototype.toString.call(obj) != "[object Object]" || Object.keys(obj).length == 0) {
			alert("错误！Hysteria2设定必须是包含 obfs、congestion 或 bandwidth 的 JSON 对象！");
			return false;
		}
		for (var key in obj) {
			if (!allowed[key]) {
				alert("错误！Hysteria2设定目前只支持 obfs、congestion、bandwidth 三个顶层字段！");
				return false;
			}
		}
		E("ss_basic_hy2_global_json").value = JSON.stringify(obj, null, 2);
		return true;
	} catch (e) {
		alert("错误！Hysteria2设定不是正确的 JSON 格式！");
		return false;
	}
}

function loadHy2GlobalForm() {
	var el = E("ss_basic_hy2_global_json");
	if (!el || !el.value) {
		return;
	}
	try {
		var obj = JSON.parse(el.value);
		if (obj.obfs && obj.obfs.type) {
			E("ss_basic_hy2_obfs_type").value = obj.obfs.type;
			if (obj.obfs[obj.obfs.type] && obj.obfs[obj.obfs.type].password) {
				E("ss_basic_hy2_obfs_password").value = obj.obfs[obj.obfs.type].password;
			}
			if (obj.obfs.type == "gecko" && obj.obfs.gecko) {
				E("ss_basic_hy2_gecko_min").value = obj.obfs.gecko.minPacketSize || "";
				E("ss_basic_hy2_gecko_max").value = obj.obfs.gecko.maxPacketSize || "";
			}
		}
		if (obj.congestion && obj.congestion.type) {
			E("ss_basic_hy2_congestion_type").value = obj.congestion.type;
			E("ss_basic_hy2_bbr_profile").value = obj.congestion.bbrProfile || "standard";
		}
		if (obj.bandwidth) {
			loadHy2Bandwidth(obj.bandwidth.up, "ss_basic_hy2_bandwidth_up_value");
			loadHy2Bandwidth(obj.bandwidth.down, "ss_basic_hy2_bandwidth_down_value");
		}
		updateHy2GlobalForm();
	} catch (e) {
		console.log("Hysteria2 global config parse error: " + e);
	}
}

function updateHy2GlobalForm() {
	var obfsType = E("ss_basic_hy2_obfs_type").value;
	var congestionType = E("ss_basic_hy2_congestion_type").value;
	showhide("ss_basic_hy2_obfs_password_span", !!obfsType);
	showhide("ss_basic_hy2_gecko_span", obfsType == "gecko");
	showhide("ss_basic_hy2_bbr_profile_span", congestionType == "bbr");
}

function save() {
	var node_sel = E("ssconf_basic_node").value
	if (!node_sel) {
		alert("你尚未定义任何节点，提交失败！");
		return false
	}
	//stop check status
	checkss = 10001;
	E("ss_state2").innerHTML = "国外连接 - <span class='ss-chip ss-chip-idle'>Waiting...</span>";
	E("ss_state3").innerHTML = "国内连接 - <span class='ss-chip ss-chip-idle'>Waiting...</span>";
	//remove blank before string
	E("ss_basic_server").value = $.trim($("#ss_basic_server").val());
	E("ss_basic_port").value = $.trim($("#ss_basic_port").val());
	E("ss_basic_password").value = $.trim($("#ss_basic_password").val());
	if (!validateHy2GlobalJson()) {
		return false;
	}
	// Game端口语法检查（仅代理QUIC+Game档）：非法则阻止保存并提示
	if (E("ss_basic_udp_sync").value == "3") {
		if (!check_game_port_input()) {
			alert("Game Port 格式错误！\n应为单端口或端口段（低-高），多个用英文逗号隔开，如：27015,7777-7778\n端口范围 1-65535，总槽位不超过15（端口段占2个槽位）。\n不能有前导零：请写 7777 而不是 07777（07777 会被 iptables 按八进制当成 4095）。");
			E("ss_basic_udp_sync_game_port").focus();
			return false;
		}
	}
	//define dbus object to save
	var dbus = {};
	//key define
	var params_input = ["ssconf_basic_node", "ss_basic_mode", "ss_basic_server", "ss_basic_port", "ss_basic_method", "ss_basic_koolgame_udp", "ss_basic_ss_v2ray_plugin", "ss_basic_ss_v2ray_plugin_opts", "ss_basic_rss_protocol", "ss_basic_naive_protocol","ss_basic_naive_user","ss_basic_rss_protocol_param", "ss_basic_rss_obfs", "ss_basic_rss_obfs_param", "ssconf_basic_test_node", "ssconf_basic_test_domain", "ss_dns_china", "ss_dns_china_user", "ss_foreign_dns", "ss_dns2socks_user", "ss_chinadns_user", "ss_chinadns1_user",  "ss_sstunnel_user", "ss_direct_user", "ss_basic_rule_update", "ss_basic_rule_update_time", "ss_acl_default_port", "ss_acl_default_mode", "ss_basic_v2ray_uuid", "ss_basic_v2ray_alterid","ss_basic_v2ray_protocol", "ss_basic_v2ray_security", "ss_basic_v2ray_network", "ss_basic_v2ray_headtype_tcp", "ss_basic_v2ray_headtype_kcp", "ss_basic_v2ray_network_host", "ss_basic_v2ray_serviceName", "ss_basic_v2ray_network_path", "ss_basic_v2ray_network_tlshost", "ss_basic_trojan_sni", "ss_basic_trojan_binary", "ss_basic_trojan_network", "ss_basic_fingerprint", "ss_basic_v2ray_network_flow", "ss_basic_v2ray_network_security", "ss_basic_v2ray_mux_concurrency", "ss_basic_xray_publicKey", "ss_basic_xray_shortId",	"ss_reboot_check", "ss_basic_week", "ss_basic_day", "ss_basic_inter_min", "ss_basic_inter_hour", "ss_basic_inter_day", "ss_basic_inter_pre", "ss_basic_time_hour", "ss_basic_time_min", "ss_basic_tri_reboot_time", "ss_basic_tri_reboot_policy", "ss_basic_dnsmasq_fastlookup", "ss_basic_server_resolver", "ss_basic_server_resolver_user", "ss_basic_udp_sync", "ss_basic_udp_sync_game_port", "ss_basic_dns_hijack", "ss_basic_hy2_udp", "ss_basic_hy2_fast_open", "ss_basic_hy2_lazy"];
	var params_check = ["ss_basic_enable", "ss_basic_gfwlist_update", "ss_basic_chnroute_update", "ss_basic_cdn_update", "ss_basic_v2ray_use_json", "ss_basic_v2ray_mux_enable","ss_basic_allowinsecure", "ss_basic_fragment"];
	var params_base64_a = ["ss_dnsmasq", "ss_wan_white_ip", "ss_wan_white_domain", "ss_wan_black_ip", "ss_wan_black_domain"];
	var params_base64_b = ["ss_basic_password", "ss_basic_custom", "ss_basic_hy2_global_json"];
	// collect data from input
	for (var i = 0; i < params_input.length; i++) {
		if (E(params_input[i])) {
			dbus[params_input[i]] = E(params_input[i]).value;
		}
	}
	// collect data from checkbox
	for (var i = 0; i < params_check.length; i++) {
		dbus[params_check[i]] = E(params_check[i]).checked ? '1' : '0';
	}
	// data need base64 encode:format a with "."
	for (var i = 0; i < params_base64_a.length; i++) {
		if (!E(params_base64_a[i]).value || E(params_base64_a[i]).value.indexOf(".") != -1) {
			dbus[params_base64_a[i]] = Base64.encode(E(params_base64_a[i]).value);
		} else {
			//乱码了或者格式不对！
			console.log("格式不正确")
			dbus[params_base64_a[i]] = "";
		}
	}
	// data need base64 encode, format b with plain text
	for (var i = 0; i < params_base64_b.length; i++) {
		dbus[params_base64_b[i]] = Base64.encode(E(params_base64_b[i]).value);
	}
	// for v2ray json, we need to process first: parse vmess:// format, encode json format
	if(E('ss_basic_v2ray_json').value.indexOf("vmess://") != -1){
		var vmess_node = JSON.parse(Base64.decode(E('ss_basic_v2ray_json').value.split("//")[1]));
		dbus["ss_basic_server"] = vmess_node.add;
		dbus["ssconf_basic_server_" + node_sel] = vmess_node.add;
		dbus["ss_basic_port"] = vmess_node.port;
		dbus["ssconf_basic_port_" + node_sel] = vmess_node.port;
		dbus["ss_basic_v2ray_protocol"] = "vmess";
		dbus["ssconf_basic_v2ray_protocol_" + node_sel] = "vmess";
		dbus["ss_basic_v2ray_uuid"] = vmess_node.id;
		dbus["ssconf_basic_v2ray_uuid_" + node_sel] = vmess_node.id;
		dbus["ss_basic_v2ray_security"] = "auto";
		dbus["ssconf_basic_v2ray_security_" + node_sel] = "auto";
		dbus["ss_basic_v2ray_alterid"] = vmess_node.aid;
		dbus["ssconf_basic_v2ray_alterid_" + node_sel] = vmess_node.aid;
		dbus["ss_basic_v2ray_network"] = vmess_node.net;
		dbus["ssconf_basic_v2ray_network_" + node_sel] = vmess_node.net;
		if(vmess_node.net == "tcp"){
			dbus["ss_basic_v2ray_headtype_tcp"] = vmess_node.type;
			dbus["ssconf_basic_v2ray_headtype_tcp_" + node_sel] = vmess_node.type;
		}else if(vmess_node.net == "kcp"){
			dbus["ss_basic_v2ray_headtype_kcp"] = vmess_node.type;
			dbus["ssconf_basic_v2ray_headtype_kcp_" + node_sel] = vmess_node.type;
		}
		dbus["ss_basic_v2ray_network_host"] = vmess_node.host;
		dbus["ss_basic_v2ray_network_tlshost"] = vmess_node.tlshost;
		dbus["ss_basic_v2ray_network_flow"] = vmess_node.flow;
		dbus["ssconf_basic_v2ray_network_host_" + node_sel] = vmess_node.host;
		dbus["ssconf_basic_v2ray_network_tlshost_" + node_sel] = vmess_node.tlshost;
		dbus["ssconf_basic_v2ray_network_flow_" + node_sel] = vmess_node.flow;
		dbus["ss_basic_v2ray_network_path"] = vmess_node.path;
		dbus["ssconf_basic_v2ray_network_path_" + node_sel] = vmess_node.path;
		if(vmess_node.tls == "tls"){
			dbus["ss_basic_v2ray_network_security"] = "tls";
			dbus["ssconf_basic_v2ray_network_security_" + node_sel] = "tls";
		}else{
			dbus["ss_basic_v2ray_network_security"] = "none";
			dbus["ssconf_basic_v2ray_network_security_" + node_sel] = "none";
		}
		dbus["ss_basic_allowinsecure"] = 1;
		dbus["ssconf_basic_allowinsecure_" + node_sel] = 1;
		dbus["ss_basic_fragment"] = 1;
		dbus["ssconf_basic_fragment_" + node_sel] = 1;
		dbus["ss_basic_v2ray_mux_enable"] = 1;
		dbus["ssconf_basic_v2ray_mux_enable_" + node_sel] = 1;
		dbus["ss_basic_v2ray_mux_concurrency"] = 8;
		dbus["ssconf_basic_v2ray_mux_concurrency_" + node_sel] = 8;
		dbus["ss_basic_v2ray_use_json"] = 0;
		dbus["ssconf_basic_v2ray_use_json_" + node_sel] = 0;
		dbus["ss_basic_v2ray_json"] = "";
		dbus["ssconf_basic_v2ray_json_" + node_sel] = "";
	}else{
		if (E("ss_basic_v2ray_use_json").checked == true){
			if(isJSON(E('ss_basic_v2ray_json').value)){
				if(E('ss_basic_v2ray_json').value.indexOf("outbound") != -1){
					dbus["ss_basic_v2ray_json"] = Base64.encode(pack_js(E('ss_basic_v2ray_json').value));
					dbus["ssconf_basic_v2ray_json_" + node_sel] = Base64.encode(pack_js(E('ss_basic_v2ray_json').value));
					var param_v2 = ["server", "port", "v2ray_uuid", "v2ray_security", "v2ray_alterid", "v2ray_protocol", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_host","v2ray_network_path","v2ray_network_tlshost", "v2ray_network_flow", "v2ray_network_security", "allowinsecure","fragment","v2ray_mux_enable", "v2ray_mux_concurrency","fingerprint","xray_publicKey", "xray_shortId"];
					for (var i = 0; i < param_v2.length; i++) {
						dbus["ss_basic_" + param_v2[i]] = "";
						dbus["ssconf_basic_" + param_v2[i] + "_" + node_sel] = "";
					}
				}else{
					alert("错误！你的json配置文件有误！\n正确格式请参考:https://www.v2ray.com/chapter_02/01_overview.html");
					return false;
				}
			}else{
				alert("错误！检测到你输入的v2ray配置不是标准json格式！");
				return false;
			}
		}
	}
	// node data: write node data under using from the main pannel incase of data change
	var params = ["server", "mode", "port", "method", "ss_v2ray_plugin", "ss_v2ray_plugin_opts", "rss_protocol","naive_protocol", "naive_user","rss_protocol_param", "rss_obfs", "rss_obfs_param", "koolgame_udp", "v2ray_uuid", "v2ray_alterid", "v2ray_protocol", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_serviceName", "v2ray_network_host","v2ray_network_path", "v2ray_network_tlshost", "v2ray_network_flow", "v2ray_network_security", "v2ray_mux_concurrency","trojan_sni", "trojan_binary", "trojan_network", "fingerprint","xray_publicKey", "xray_shortId"];
	for (var i = 0; i < params.length; i++) {
		dbus["ssconf_basic_" + params[i] + "_" + node_sel] = E("ss_basic_" + params[i]).value;
	}
	// node data: checkbox
	dbus["ssconf_basic_v2ray_use_json_" + node_sel] = E("ss_basic_v2ray_use_json").checked ? '1' : '0';
	dbus["ssconf_basic_allowinsecure_" + node_sel] = E("ss_basic_allowinsecure").checked ? '1' : '0';
	dbus["ssconf_basic_fragment_" + node_sel] = E("ss_basic_fragment").checked ? '1' : '0';
	dbus["ssconf_basic_v2ray_mux_enable_" + node_sel] = E("ss_basic_v2ray_mux_enable").checked ? '1' : '0';
	// node data: base64
	dbus["ssconf_basic_password_" + node_sel] = Base64.encode(E("ss_basic_password").value);
	// collect values in acl table
	maxid = parseInt($("#ACL_table > tbody > tr:eq(-2) > td:nth-child(2) > input").attr("id").split("_")[3]);
	if(maxid){
		for ( var i = 1; i <= maxid; ++i ) {
			if (E("ss_acl_name_" + i)){
				dbus["ss_acl_name_" + i] = E("ss_acl_name_" + i).value;
				dbus["ss_acl_mode_" + i] = E("ss_acl_mode_" + i).value;
				dbus["ss_acl_port_" + i] = E("ss_acl_port_" + i).value;
			}
		}
	}
	// adjust some value when switch node between ss ssr xray koolgame
	if (typeof(db_ss["ssconf_basic_rss_protocol_" + node_sel]) != "undefined"){
			var remove_ssr = [ "ss_v2ray_plugin", "ss_v2ray_plugin_opts", "koolgame_udp","naive_protocol", "naive_user","v2ray_protocol", "v2ray_use_json", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host","v2ray_network_tlshost","v2ray_network_flow", "v2ray_network_security", "allowinsecure","fragment","v2ray_mux_enable", "v2ray_mux_concurrency", "v2ray_json", "trojan_sni", "trojan_binary", "trojan_network","fingerprint","xray_publicKey","xray_shortId"];
			//console.log("use ssr");
			dbus["ss_basic_type"] = "1"
			dbus["ssconf_basic_type_" + node_sel] = "1"
			for (var i = 0; i < remove_ssr.length; i++) {
				dbus["ss_basic_" + remove_ssr[i]] = "";
				dbus["ssconf_basic_" + remove_ssr[i] + "_" + node_sel] = "";
			}
	} else if (typeof(db_ss["ssconf_basic_koolgame_udp_" + node_sel]) != "undefined"){
			var remove_gamev2 = [ "ss_v2ray_plugin", "ss_v2ray_plugin_opts","naive_protocol", "naive_user", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "v2ray_protocol", "v2ray_use_json", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network","v2ray_network_tlshost", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_flow","v2ray_network_security","allowinsecure", "fragment", "v2ray_mux_enable", "v2ray_mux_concurrency", "v2ray_json", "trojan_sni", "trojan_binary", "trojan_network","fingerprint","xray_publicKey","xray_shortId"];
			//console.log("use gamev2");
			dbus["ss_basic_type"] = "2"
			dbus["ssconf_basic_type_" + node_sel] = "2"
			for (var i = 0; i < remove_gamev2.length; i++) {
				dbus["ss_basic_" + remove_gamev2[i]] = "";
				dbus["ssconf_basic_" + remove_gamev2[i] + "_" + node_sel] = "";
			}
	} else if (typeof(db_ss["ssconf_basic_naive_protocol_" + node_sel]) != "undefined"){
			var remove_naive = [ "ss_v2ray_plugin", "ss_v2ray_plugin_opts", "koolgame_udp", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "v2ray_protocol", "v2ray_use_json", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network","v2ray_network_tlshost", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_flow","v2ray_network_security","allowinsecure", "fragment","v2ray_mux_enable", "v2ray_mux_concurrency", "v2ray_json", "trojan_sni", "trojan_binary", "trojan_network","fingerprint","xray_publicKey","xray_shortId"];
			//console.log("use NaiveProxy");
			dbus["ss_basic_type"] = "5"
			dbus["ssconf_basic_type_" + node_sel] = "5"
			for (var i = 0; i < remove_naive.length; i++) {
				dbus["ss_basic_" + remove_naive[i]] = "";
				dbus["ssconf_basic_" + remove_naive[i] + "_" + node_sel] = "";
			}		
	} else if (typeof(db_ss["ssconf_basic_v2ray_use_json_" + node_sel]) != "undefined"){
			var remove_v2ray = [ "naive_protocol", "naive_user", "koolgame_udp", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "trojan_sni", "trojan_binary", "trojan_network"];
			//console.log("use v2ray");
			dbus["ss_basic_type"] = "3"
			dbus["ssconf_basic_type_" + node_sel] = "3"
			for (var i = 0; i < remove_v2ray.length; i++) {
				dbus["ss_basic_" + remove_v2ray[i]] = "";
				dbus["ssconf_basic_" + remove_v2ray[i] + "_" + node_sel] = "";
			}
	} else if (typeof(db_ss["ssconf_basic_trojan_binary_" + node_sel])  != "undefined") {
			    var remove_trojan = [ "koolgame_udp","naive_protocol", "naive_user", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "v2ray_protocol", "v2ray_use_json", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_network_tlshost", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_security", "v2ray_network_flow", "v2ray_json","xray_publicKey","xray_shortId"];
                //console.log("use trojan");
                dbus["ss_basic_type"] = "4"
                dbus["ssconf_basic_type_" + node_sel] = "4"
                for (var i = 0; i < remove_trojan.length; i++) {
                    dbus["ss_basic_" + remove_trojan[i]] = "";
                    dbus["ssconf_basic_" + remove_trojan[i] + "_" + node_sel] = "";
                }
	} else {
				var remove_ss = [ "koolgame_udp","naive_protocol", "naive_user", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "v2ray_protocol", "v2ray_use_json", "v2ray_uuid", "v2ray_alterid", "v2ray_security", "v2ray_network", "v2ray_network_host", "v2ray_network_tlshost", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_network_path", "v2ray_network_host", "v2ray_network_flow","v2ray_network_security", "v2ray_mux_enable", "v2ray_mux_concurrency", "v2ray_json","trojan_sni", "trojan_binary","trojan_network","fingerprint","allowinsecure","fragment","xray_publicKey","xray_shortId"];
				//console.log("use ss");
				dbus["ss_basic_type"] = "0"
				dbus["ssconf_basic_type_" + node_sel] = "0"
				for (var i = 0; i < remove_ss.length; i++) {
					dbus["ss_basic_" + remove_ss[i]] = "";
					dbus["ssconf_basic_" + remove_ss[i] + "_" + node_sel] = "";
				}
	} 

	if (E("ss_basic_enable").checked) {
		if (E("ss_basic_mode").value == "1") {
			db_ss["ss_basic_action"] = "1";
		} else if (E("ss_basic_mode").value == "2") {
			db_ss["ss_basic_action"] = "2";
		} else if (E("ss_basic_mode").value == "3") {
			db_ss["ss_basic_action"] = "3";
		} else if (E("ss_basic_mode").value == "5") {
			db_ss["ss_basic_action"] = "5";
		} else if (E("ss_basic_mode").value == "6") {
			db_ss["ss_basic_action"] = "6";
		}
	} else {
		db_ss["ss_basic_action"] = "0";
	}
	// 对象db_ss是已经存在skipd中的，对象dbus是要存进去的
	// 1 做一个检测，把dbus中与db_ss相同的值给剔除掉
	// 2 并且，如果一个field在db_ss中是没有（undefined），并且在dbus中是空值（""）的话，也需要剔除掉
	// 3 两次剔除后剩下的对象用于提交，减少skipd数据写入量
	// console.log("db_ss:", db_ss);
	// console.log("dbus:", dbus);
	var post_dbus = {};
	for (var key in dbus) {
		//console.log(key);
		if(db_ss[key] && dbus[key] && db_ss[key] == dbus[key]){
			//console.log("0", key, db_ss[key], dbus[key]);
			continue;
		}else if(db_ss[key] == undefined && (dbus[key] == "")){
			//console.log("1", key, db_ss[key], dbus[key]);
			continue;
		}else{
			//console.log("2", key, db_ss[key], dbus[key]);
			post_dbus[key] = dbus[key];
		}
	}
	console.log("post_dbus", post_dbus);
	post_dbus["SystemCmd"] = "ss_config.sh";
	post_dbus["action_mode"] = " Refresh ";
	post_dbus["current_page"] = "Main_Ss_Content.asp";
	push_data(post_dbus);
}

function push_data(obj) {
	$.ajax({
		type: "POST",
		url: '/applydb.cgi?p=ss',
		contentType: "application/x-www-form-urlencoded",
		dataType: 'text',
		data: $.param(obj),
		success: function(response) {
			showSSLoadingBar();
			noChange2 = 0;
			setTimeout("get_realtime_log();", 500);
		}
	});
}

function decode_show() {
	var temp_ss = ["ss_dnsmasq", "ss_wan_white_ip", "ss_wan_white_domain", "ss_wan_black_ip", "ss_wan_black_domain", "ss_basic_custom", "ss_basic_hy2_global_json"];
	for (var i = 0; i < temp_ss.length; i++) {
		var el = E(temp_ss[i]);
		if (!el) {
			continue;
		}
		el.value = Base64.decode(el.value || "");
	}
	loadHy2GlobalForm();
}

function update_ss_ui(obj) {
	//console.log("test2", obj);
	var node_sel = obj["ssconf_basic_node"];
	for (var field in obj) {
		//console.log("test3", field);
		var el = E(field);

		if (el != null && el.getAttribute("type") == "checkbox") {
			//console.log("param_check", el.id);
			if (obj[field] != "1") {
				el.checked = false;
			} else {
				el.checked = true;
			}
			continue;
		}

		if (el != null) {
		//console.log("param_others", el.id);
			el.value = obj[field];
		}
	}
	E("ss_basic_password").value = Base64.decode(E("ss_basic_password").value);
	E("ss_basic_v2ray_json").value = do_js_beautify(Base64.decode(E("ss_basic_v2ray_json").value));
}

// UDP代理状态指示：显示后端回写的"本次实际生效"状态，而不是用户在下拉框里选的档位。
// 两者会不一致——档位可能被节点核心能力、内核TPROXY探测、fwmark/table310冲突就地降级，
// 这些降级只改运行时变量、不写 ss_basic_udp_sync，所以只回显下拉框等于把偏差原样搬到界面上。
// 数据来源：ssconfig.sh 的 write_udp_runtime_state()，在全部降级判定与 hook 下发之后回写 dbus。
// 运行时快照：由 refresh_udp_runtime() 从 /dbconf?p=ss_runtime 拉取并覆盖。
// 【注意前缀是 ss_runtime 不是 ss_runtime_udp】——DNS 那条链路的状态键也在这个前缀下，
// 一次拉全。谁把它改窄成 ss_runtime_udp，DNS 那一行会永久停在"未知"。
// 不能直接用 db_ss —— 那是页面载入那一刻的快照，而提交后本页既不 reload 也不重取 dbus
// （push_data -> get_realtime_log -> hideSSLoadingBar 就结束了），于是用户改完档位点提交，
// 看到的还是上一次运行的状态，恰好是他唯一会盯着这行看的时刻。
var udp_runtime = null;
var udp_poll_tick = 0;

function udp_rt(key) {
	if (udp_runtime && typeof(udp_runtime[key]) != "undefined") return udp_runtime[key];
	if (typeof(db_ss) != "undefined" && typeof(db_ss[key]) != "undefined") return db_ss[key];
	return undefined;
}

// 从 dbus 重新拉取 ss_runtime_* 后重绘。/dbconf?p=<前缀> 会返回一段
// "var db_<前缀> = {...}" 的 JS（get_ss_status_data 拉 ss_basic_enable 用的就是这个机制）。
// 前缀取 ss_runtime 而不是 ss_runtime_udp：DNS 那条链路也有运行时状态要显示，一次拉全。
function refresh_udp_runtime() {
	$.ajax({
		type: "get",
		url: "/dbconf?p=ss_runtime",
		dataType: "script",
		success: function() {
			if (typeof(db_ss_runtime) != "undefined") udp_runtime = db_ss_runtime;
			update_udp_indicator();
			update_dns_indicator();
		},
		error: function() { update_udp_indicator(); update_dns_indicator(); }
	});
}

// UDP代理状态指示：显示后端回写的"本次实际生效"状态，而不是用户在下拉框里选的档位。
// 两者会不一致——档位可能被节点核心能力、内核TPROXY探测、fwmark/table310冲突就地降级，
// 这些降级只改运行时变量、不写 ss_basic_udp_sync。
// 显示两段信息：
//   档位段  <- ss_runtime_udp_state  由 ssconfig.sh write_udp_runtime_state 回写（配置层）
//   实测段  <- ss_runtime_udp_probe  由 ss/cru/udp.sh 回写（运行层，此刻立起来了没有）
// 其中 probe=pass 是"仅代理QUIC"档的正常态：该档只代理 UDP/443，没有非443 UDP 可查，
// 按设计跳过本项检查，绝不能显示成红色失败。
function update_udp_indicator() {
	if (!E("ss_state4")) return;
	var udp_state = udp_rt("ss_runtime_udp_state");
	var udp_text  = udp_rt("ss_runtime_udp_text");
	var probe     = udp_rt("ss_runtime_udp_probe");
	var probe_txt = udp_rt("ss_runtime_udp_probe_text");
	var probe_at  = udp_rt("ss_runtime_udp_probe_time");

	function esc(s) {
		return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
	}
	function chip(cls, label) {
		return '<span class="ss-chip ss-chip-' + cls + '">' + esc(label) + '</span>';
	}

	if (typeof(udp_state) == "undefined" || udp_state == "") {
		$("#ss_state4").html("UDP代理 " + chip("idle", "未知") +
			'<span class="ss-chip-note">应用一次配置后自动刷新</span>').attr("title", "");
		return;
	}
	// 档位（配置层）：[芯片文案, 芯片样式]
	var udp_map = {
		"off":             ["关闭",      "idle"],
		"disabled":        ["未启用",    "idle"],
		"quic":            ["仅QUIC",    "ok"],
		"quic_game":       ["QUIC+Game", "ok"],
		"full":            ["全量UDP",   "ok"],
		"game":            ["游戏模式",  "ok"],
		// 【能力不支持(黄) vs 环境故障(红)】这两类要分开，原来一律标红是误导：
		//   node   —— hy2 的UDP开关没勾 / naive、anytls 本插件没配透明UDP入站
		//   plugin —— hy2 构建不认 udpTProxy / SIP003 simple-obfs 没有UDP通路
		//     这两类链路本身是好的，是【这个节点或协议提供不了UDP加速】，
		//     用户换个节点、勾个开关就解决了，标红会让人以为插件坏了。
		//   kernel —— 内核不接受TPROXY / fwmark 0x07 被占 / 路由表310被占
		//     这才是真故障：换节点也没用，必须红灯。
		"degraded_node":   ["节点不支持UDP加速", "warn"],
		"degraded_plugin": ["传输层不支持UDP",   "warn"],
		"degraded_kernel": ["内核/环境故障",     "crit"]
	};
	// 实测（运行层）：[芯片文案, 芯片样式]。off 不出芯片——档位本来就关着，再挂一枚是噪音。
	// pass 用 skip 样式（空心点）：它既不是绿灯也不是故障，是"本档只代理QUIC/443，
	// 没有非443 UDP 可查"，必须和 ok 在视觉上区分开，否则用户会以为检测过了。
	// warn：链路本身是好的，但配置多半有问题 —— 目前唯一来源是「Game端口疑似填错」
	// （该端口零命中，同时兜底链在放行境外非443 UDP）。它不是故障、也不该是绿灯。
	// 注意这里【故意没有 unsupported】：那种情况配置层芯片已经写明"节点不支持UDP加速"，
	// 实测层再挂一枚同义芯片是噪音。与 off 不出芯片是同一个道理。
	var probe_map = {
		"pass": ["非443UDP不适用", "skip"],
		"ok":   ["链路就绪",       "ok"],
		"flow": ["有流量",         "ok"],
		"warn": ["Game端口疑似填错", "warn"],
		"fail": ["异常",           "crit"]
	};
	var udp_hit = udp_map[udp_state] || ["未知", "idle"];
	var html = "UDP代理 " + chip(udp_hit[1], udp_hit[0]);
	if (probe_map[probe]) html += chip(probe_map[probe][1], probe_map[probe][0]);

	// 只有需要用户动手的两种情况才把原因摊在行内；其余留给 tooltip，避免状态条变成一堵字墙
	if (udp_state.indexOf("degraded") == 0 && udp_text) {
		// 说明文字的颜色跟着芯片的严重度走：能力不支持是黄的，环境故障才是红的
		var deg_cls = (udp_hit[1] == "crit") ? "ss-chip-note-crit" : "ss-chip-note-warn";
		html += '<span class="ss-chip-note ' + deg_cls + '">' + esc(udp_text) + '</span>';
	} else if (probe == "fail" && probe_txt) {
		html += '<span class="ss-chip-note ss-chip-note-crit">' + esc(probe_txt) + '</span>';
	} else if (probe == "warn" && probe_txt) {
		// warn 的文案里带着"下一步该跑什么命令"，必须摊在行内，收进 tooltip 就等于没有
		html += '<span class="ss-chip-note ss-chip-note-warn">' + esc(probe_txt) + '</span>';
	}

	var tip = (udp_text || "");
	if (probe_txt) tip = tip + (tip ? "\n" : "") + "实测：" + probe_txt + (probe_at ? " @" + probe_at : "");
	// 芯片自带颜色，清掉早期版本留下的行内 color，免得盖住芯片配色
	$("#ss_state4").html(html).attr("title", tip).css("color", "");
}

// DNS劫持状态指示：与 UDP 那行严格对称。
// 存在的理由：ss_basic_dns_hijack 是用户的请求值，而【全部强制】档有两条静默回退路径 ——
// ①53 改道规则没能完整写入 ②本机 dnsmasq 未就绪（含 dnsmasq-fastlookup 替换后起不来）。
// 两种情况都会退回【默认】档，此前界面上完全看不出来：下拉框照旧显示"全部"，
// 用户以为 DoT/DoH 正在被拦、白名单可靠生效，实际并没有。
// 数据来源：ssconfig.sh 的 write_dns_runtime_state()，在 chromecast 里按实际走到的分支回写。
function update_dns_indicator() {
	if (!E("ss_state5")) return;
	var st = udp_rt("ss_runtime_dns_state");
	var txt = udp_rt("ss_runtime_dns_text");

	function esc(s) {
		return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
	}
	if (typeof(st) == "undefined" || st == "") {
		$("#ss_state5").html('DNS劫持 <span class="ss-chip ss-chip-idle">未知</span>' +
			'<span class="ss-chip-note">应用一次配置后自动刷新</span>').attr("title", "");
		return;
	}
	// [芯片文案, 芯片样式]。fallback_default 是唯一需要用户采取行动的状态，
	// 用 crit 并把原因摊在行内 —— 它意味着用户选了"全部"但实际没生效。
	var map = {
		"off":              ["关闭",     "idle"],
		"default":          ["默认",     "ok"],
		"all":              ["全部强制", "ok"],
		"fallback_default": ["已回退",   "crit"]
	};
	var hit = map[st] || ["未知", "idle"];
	var html = 'DNS劫持 <span class="ss-chip ss-chip-' + hit[1] + '">' + esc(hit[0]) + '</span>';

	// dnsmasq-fastlookup 的【实际】状态。用户反馈过"开了替换也检测不出来" ——
	// 此前界面上确实无处可看：档位是请求值，是否真的挂上取决于 mount_dnsmasq 的 --test
	// 预检（不兼容会静默放弃替换、只打一行日志）。want_but_off 就是那个差异，标红。
	var fl = udp_rt("ss_runtime_dns_fastlookup");
	if (fl == "on") {
		html += '<span class="ss-chip ss-chip-ok">fastlookup</span>';
	} else if (fl == "want_but_off") {
		html += '<span class="ss-chip ss-chip-crit">fastlookup未生效</span>' +
			'<span class="ss-chip-note ss-chip-note-crit">已选替换但实际未挂载，多为与当前dnsmasq配置不兼容（--test未通过）</span>';
	}

	// 7913 解析器有没有国内仲裁。这是"直连网页偶尔卡顿"的结构性成因所在：
	// 纯隧道型解析器在隧道抖动时没有国内上游可退，不在 gfwlist/cdn 列表里的域名会解析超时。
	// 只在「全部强制」档提示 —— 该档把所有客户端都拉进这条链路，影响面最大。
	var arb = udp_rt("ss_runtime_dns_arbiter");
	if (st == "all" && arb == "tunnel_only") {
		html += '<span class="ss-chip ss-chip-warn">7913无国内仲裁</span>' +
			'<span class="ss-chip-note">隧道抖动时非gfwlist/cdn域名会解析超时（表现为直连网页偶尔卡顿）；' +
			'把【国外DNS方案】改为 ChinaDNS-NG 或 chinadns1 可从根上消除</span>';
	}

	if (st == "fallback_default" && txt) {
		html += '<span class="ss-chip-note ss-chip-note-crit">' + esc(txt) + '</span>';
	}
	$("#ss_state5").html(html).attr("title", txt || "").css("color", "");
}

function is_ss_node() {
	// 游戏模式仅限SS协议(ss-libev)：SSR/koolgame/naive/v2ray/trojan节点及SS2022(经xray运行)均不支持
	var node_sel = E("ssconf_basic_node").value;
	if (typeof(db_ss["ssconf_basic_rss_protocol_" + node_sel]) != "undefined") return false;
	if (typeof(db_ss["ssconf_basic_koolgame_udp_" + node_sel]) != "undefined") return false;
	if (typeof(db_ss["ssconf_basic_naive_protocol_" + node_sel]) != "undefined") return false;
	if (typeof(db_ss["ssconf_basic_v2ray_use_json_" + node_sel]) != "undefined") return false;
	if (typeof(db_ss["ssconf_basic_trojan_binary_" + node_sel]) != "undefined") return false;
	var mth = db_ss["ssconf_basic_method_" + node_sel];
	if (typeof(mth) == "undefined" && E("ss_basic_method")) mth = E("ss_basic_method").value;
	if (mth && (mth.indexOf("2022-") == 0 || mth == "none")) return false;
	return true;
}

// Game端口语法检查（与后端 validate_game_ports 同规则）：单端口或"低-高"段，逗号分隔，
// 端口1-65535，multiport总槽位≤15（端口段占2），首位必须1-9不允许前导零。
// 前导零必须在这里就拦住：iptables 的 xtables_strtoul 以 base 0 解析端口，07777 会被当成
// 八进制 4095 静默生效，08/09 则让 iptables 直接拒绝规则。parseInt(x,10) 看不出这个差别，
// 所以判断只能落在正则形状上，且必须与后端正则保持一致。
function game_port_syntax_ok(gp) {
	if (!/^[1-9]\d{0,4}(-[1-9]\d{0,4})?(,[1-9]\d{0,4}(-[1-9]\d{0,4})?)*$/.test(gp)) return false;
	var segs = gp.split(","), slots = 0;
	for (var gi = 0; gi < segs.length; gi++) {
		var pr = segs[gi].split("-");
		var lo = parseInt(pr[0], 10);
		var hi = pr.length > 1 ? parseInt(pr[1], 10) : lo;
		if (!(lo >= 1 && lo <= 65535 && hi >= 1 && hi <= 65535 && lo <= hi)) return false;
		slots += (pr.length > 1 ? 2 : 1);
	}
	return slots <= 15;
}

// Game端口失焦即时校验：非法时红框+行内提示；合法时去空格规范化写回。保存时复用。
function check_game_port_input() {
	var el = E("ss_basic_udp_sync_game_port");
	if (!el) return true;
	var tip = E("ss_basic_udp_sync_game_port_tip");
	var gp = el.value.replace(/\s+/g, "");
	el.value = gp;
	var ok = (gp == "" || game_port_syntax_ok(gp));
	el.style.borderColor = ok ? "" : "#F46";
	if (tip) tip.style.display = ok ? "none" : "";
	return ok;
}

// 节点【对话框】里正在编辑的那个节点是不是 SS 协议。
// 不能用 is_ss_node() —— 那读的是 ssconf_basic_node，即"当前生效节点"；
// 而"添加节点"时对话框里的节点还不存在，它的 ssconf_basic_*_<n> 键在 db_ss 里查不到，
// 于是 is_ss_node() 实际是拿【旧的生效节点】在判断：当前生效节点若是
// Hysteria2/V2Ray 之类，即便你正在添加的是 SS 节点，游戏模式也会被错误置灰。
// 对话框的类型由 tabclickhandler 写进 save_flag / #vpnc_type，这才是该看的东西。
function is_ss_node_dialog() {
	var t = (typeof(save_flag) != "undefined" && save_flag) ? save_flag : (E("vpnc_type") ? E("vpnc_type").value : "");
	// save_flag 取值：shadowsocks / shadowsocksR / gameV2 / naive / v2ray / trojan
	if (t != "shadowsocks") return false;
	// SS2022 与 none 经 xray 运行（type 3），同样不支持游戏模式
	var m = E("ss_node_table_method");
	if (m && m.value && (m.value.indexOf("2022-") == 0 || m.value == "none")) return false;
	return true;
}

function set_game_option(sel, ok) {
	if (!sel) return;
	for (var i = 0; i < sel.options.length; i++) {
		if (sel.options[i].value == "3") sel.options[i].disabled = !ok;
	}
	if (!ok && sel.value == "3") sel.value = "2";
}

function apply_game_mode_limit() {
	// 两处 select 的判断依据【不同】，此前共用 is_ss_node() 是错的：
	//   主界面的模式    -> 看【当前生效节点】
	//   节点对话框的模式 -> 看【对话框里正在编辑的节点】
	set_game_option(E("ss_basic_mode"), is_ss_node());
	set_game_option(E("ss_node_table_mode"), is_ss_node_dialog());
}

function verifyFields(r) {
	// some variable
	var node_sel = E("ssconf_basic_node").value;
	apply_game_mode_limit();
	var ssmode = E("ss_basic_mode").value;
    var ss_on = false;
    var ssr_on = false;
    var koolgame_on = false;
    var v2ray_on = false;
    var trojan_on = false;
	var naive_on = false;
	if (typeof(db_ss["ssconf_basic_rss_protocol_" + node_sel]) != "undefined"){
        ssr_on = true;
		$("#server_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(2)">服务器</a>');
		$("#port_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(3)">服务器端口</a>');
	}else if(typeof(db_ss["ssconf_basic_koolgame_udp_" + node_sel]) != "undefined"){
		$("#server_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(2)">服务器</a>');
		$("#port_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(3)">服务器端口</a>');
	}else if(typeof(db_ss["ssconf_basic_naive_protocol_" + node_sel]) != "undefined"){
		naive_on = true;
		$("#server_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(2)">服务器</a>');
		$("#port_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(3)">服务器端口</a>');		
		$("#port_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(3)">服务器端口</a>');
		$("#port_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(3)">服务器端口</a>');		
	}else if(typeof(db_ss["ssconf_basic_v2ray_use_json_" + node_sel]) != "undefined"){
		v2ray_on = true;
		$("#server_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(51)"><font color="#ffcc00">地址（address）</font></a>');
		$("#port_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(50)"><font color="#ffcc00">端口（port）</font></a>');
	}else if (typeof(db_ss["ssconf_basic_trojan_binary_" + node_sel])  != "undefined") {
		trojan_on = true;
		$("#server_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(2)">服务器</a>');
        $("#port_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(3)">服务器端口</a>');			
	}else{
		ss_on = true;
		$("#server_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(2)">服务器</a>');
		$("#port_th").html('<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(3)">服务器端口</a>');
	}
	
	// pop out node add
	if (node_global_max == 0 && poped == 0) {
		pop_node_add();
	}

	//basic pannel status show
	if (db_ss["ss_basic_mode"] == "0") {
		$("#mode_state").html("运行状态");
	} else if (db_ss["ss_basic_mode"] == "1") {
		$("#mode_state").html("运行状态【gfwlist模式】");
	} else if (db_ss["ss_basic_mode"] == "2") {
		$("#mode_state").html("运行状态【大陆白名单模式】");
	} else if (db_ss["ss_basic_mode"] == "3") {
		$("#mode_state").html("运行状态【游戏模式】");
	} else if (db_ss["ss_basic_mode"] == "5") {
		$("#mode_state").html("运行状态【全局模式】");
	} else if (db_ss["ss_basic_mode"] == "6") {
		$("#mode_state").html("运行状态【回国模式】");
	}

	update_udp_indicator();
	update_dns_indicator();

	//ss-libev
	showhide("ss_v2ray_plugin", ss_on);
	showhide("ss_v2ray_plugin_opts", (ss_on && E("ss_basic_ss_v2ray_plugin").value != "0"));
	//ssr-libev
	showhide("ss_basic_rss_protocol_param_tr", (ssr_on));
	showhide("ss_basic_rss_protocol_tr", (ssr_on));
	showhide("ss_basic_rss_obfs_tr", (ssr_on));
	showhide("ss_basic_ticket_tr", (ssr_on));
	//koolgame
	showhide("ss_koolgame_udp_tr", koolgame_on);
	//naive
	showhide("ss_naive_protocol_tr", naive_on);
	showhide("ss_naive_user_tr", naive_on);
	showhide("ss_naive_binary_update_tr", naive_on);
	//v2ray
	var json_on = E("ss_basic_v2ray_use_json").checked == true;
	var json_off = E("ss_basic_v2ray_use_json").checked == false;
	var http_on = E("ss_basic_v2ray_network").value == "tcp" && E("ss_basic_v2ray_headtype_tcp").value == "http";
	var serviceName_on = E("ss_basic_v2ray_network").value == "grpc";
	//trojan-go also need use ws paramter
	var host_on = E("ss_basic_v2ray_network").value == "ws" || E("ss_basic_v2ray_network").value == "h2" || http_on || E("ss_basic_trojan_network").value == "1" ;
	var path_on = E("ss_basic_v2ray_network").value == "ws" || E("ss_basic_v2ray_network").value == "h2" || E("ss_basic_trojan_network").value == "1" || E("ss_basic_v2ray_network").value == "kcp";
	var trojan_binary_on = E("ss_basic_trojan_binary").value;
	var trojango_on = trojan_binary_on == "Trojan-Go";
	var hy2_on = trojan_binary_on == "Hysteria2";
	var tls_on =  E("ss_basic_v2ray_network_security").value == "tls";
	var reality_on = E("ss_basic_v2ray_protocol").value == "vless" && E("ss_basic_v2ray_network_security").value == "reality";
	var vision_on = E("ss_basic_v2ray_protocol").value == "vless" && E("ss_basic_v2ray_network").value == "tcp" &&  (E("ss_basic_v2ray_network_security").value == "tls" || E("ss_basic_v2ray_network_security").value == "reality");
		
	showhide("pass_tr", (!v2ray_on));
	showhide("method_tr", (!v2ray_on) && (!trojan_on) && (!naive_on));
	showhide("server_tr", (json_off));
	showhide("port_tr", (json_off));
	showhide("v2ray_use_json_basic_tr", v2ray_on);
	showhide("v2ray_uuid_basic_tr", (v2ray_on && json_off));
	showhide("v2ray_alterid_basic_tr", (v2ray_on && json_off && E("ss_basic_v2ray_protocol").value == "vmess"));
	showhide("v2ray_protocol_basic_tr", (v2ray_on && json_off));
	showhide("v2ray_security_basic_tr", (v2ray_on && json_off));
	showhide("xray_publicKey_basic_tr", (v2ray_on && json_off && reality_on));
	showhide("xray_shortId_basic_tr", (v2ray_on && json_off && reality_on));
	showhide("v2ray_network_basic_tr", (v2ray_on && json_off));
	showhide("v2ray_headtype_tcp_basic_tr", (v2ray_on && json_off && E("ss_basic_v2ray_network").value == "tcp"));
	showhide("v2ray_headtype_kcp_basic_tr", (v2ray_on && json_off && E("ss_basic_v2ray_network").value == "kcp"));
	showhide("v2ray_serviceName_basic_tr", (v2ray_on && json_off && serviceName_on));
	showhide("v2ray_network_host_basic_tr", ((v2ray_on && json_off && host_on) || (trojan_on && trojango_on && host_on)));
	showhide("v2ray_network_path_basic_tr", ((v2ray_on && json_off && path_on) || (trojan_on && trojango_on && path_on)));
	showhide("v2ray_network_tlshost_basic_tr", (v2ray_on && json_off && (tls_on || reality_on)));
	showhide("v2ray_network_flow_basic_tr", (v2ray_on && json_off && (vision_on || reality_on)));
	showhide("vision_flow_opt_basic" , (v2ray_on && json_off && (vision_on || reality_on)));
	
	showhide("v2ray_network_security_basic_tr", (v2ray_on && json_off));
	showhide("v2ray_mux_enable_basic_tr", ((trojan_on && trojango_on)|| (v2ray_on && json_off)));
	showhide("v2ray_mux_concurrency_basic_tr", (((trojan_on && trojango_on) || (v2ray_on && json_off)) && E("ss_basic_v2ray_mux_enable").checked));
	showhide("v2ray_json_basic_tr", (v2ray_on && json_on));
	showhide("v2ray_binary_update_tr", v2ray_on);
	//trojan Hysteria2
	showhide("trojan_binary_basic_tr", trojan_on);
	showhide("trojan_network_basic_tr", (trojan_on && trojango_on));
	showhide("trojan_sni_basic_tr", trojan_on);
	showhide("ss_hysteria_binary_update_tr", (trojan_on && hy2_on));
	//mixed variables
	showhide("allowinsecure_basic_tr", ((trojan_on && !trojango_on) || (v2ray_on && json_off && tls_on)));
	showhide("fragment_basic_tr", ((trojan_on && trojan_binary_on == "Trojan" ) || (v2ray_on && json_off )));
	showhide("fingerprint_basic_tr", (trojan_on && trojango_on) || (v2ray_on && json_off));
	
	// dns pannel
	showhide("dns_plan_foreign", !koolgame_on);
	//node add/edit pannel
	if (save_flag == "shadowsocks") {
		E('allowinsecure_tr').style.display = "none";
		E('fragment_tr').style.display = "none";
		showhide("ss_v2ray_plugin_support", ($("#ss_node_table_mode").val() != "3"));
		showhide("ss_v2ray_plugin_opts_support", ($("#ss_node_table_mode").val() != "3" && $("#ss_node_table_ss_v2ray_plugin").val() != "0"));
	}
	else if (save_flag == "trojan") {
		E('trojan_sni_tr').style.display = "";
		E('trojan_binary_tr').style.display = "";

		var trojan_binary_off_1 = E("ss_node_table_trojan_binary").value;
		var trojango_on_1 = trojan_binary_off_1 == "Trojan-Go";
		var anytls_on_1 = trojan_binary_off_1 == "AnyTLS";

		if (trojan_binary_off_1 == "Trojan" ) {
			E('allowinsecure_tr').style.display = "";
			E('fragment_tr').style.display = "";
			E('v2ray_mux_enable_tr').style.display = "none";
			E('v2ray_mux_concurrency_tr').style.display = "none";
		}else if (trojan_binary_off_1 == "Hysteria2" || anytls_on_1) {
			E('allowinsecure_tr').style.display = "";
			E('fragment_tr').style.display = "none";
			E('v2ray_mux_enable_tr').style.display = "none";
			E('v2ray_mux_concurrency_tr').style.display = "none";
		}
		else{
			E('allowinsecure_tr').style.display = "none";
			E('fragment_tr').style.display = "none";
			E('v2ray_mux_enable_tr').style.display = "";
			E('v2ray_mux_concurrency_tr').style.display = "";
			showhide("v2ray_mux_concurrency_tr", (E("ss_node_table_v2ray_mux_enable").checked));
		}
		
		showhide("trojan_network_tr", trojango_on_1);
		showhide("fingerprint_tr", trojango_on_1);
		var host_on_4 = E("ss_node_table_trojan_network").value == "1" ;
		var path_on_4 = E("ss_node_table_trojan_network").value == "1" ;	

//		showhide("method_tr", trojango_on_1);
//		showhide("ss_v2ray_plugin", trojango_on_1);
//		showhide("ss_v2ray_plugin_opts", trojango_on_1);
		showhide("v2ray_network_host_tr", (trojango_on_1 && host_on_4));
		showhide("v2ray_network_path_tr", (trojango_on_1 && path_on_4));
		showhide("allowinsecure_tr", !trojango_on_1);
		showhide("fragment_tr", trojan_binary_off_1 == "Trojan");
	}
	else if (save_flag == "v2ray") {
		if(E("ss_node_table_v2ray_use_json").checked){
			E('ss_server_support_tr').style.display = "none";
			E('ss_port_support_tr').style.display = "none";
			E('v2ray_uuid_tr').style.display = "none";
			E('v2ray_alterid_tr').style.display = "none";
			E('v2ray_protocol_tr').style.display = "none";
			E('v2ray_security_tr').style.display = "none";
			E('v2ray_network_tr').style.display = "none";
			E('v2ray_headtype_tcp_tr').style.display = "none";
			E('v2ray_headtype_kcp_tr').style.display = "none";
			E('v2ray_serviceName_tr').style.display = "none";
			E('v2ray_network_path_tr').style.display = "none";
			E('v2ray_network_host_tr').style.display = "none";
			E('v2ray_network_tlshost_tr').style.display = "none";
			E('v2ray_network_flow_tr').style.display = "none";
			E('v2ray_network_security_tr').style.display = "none";
			E('fragment_tr').style.display = "none";
			E('v2ray_mux_enable_tr').style.display = "none";
			E('v2ray_mux_concurrency_tr').style.display = "none";
			E('fingerprint_tr').style.display = "none";
			E('v2ray_json_tr').style.display = "";
		}else{
			E('ss_server_support_tr').style.display = "";
			E('ss_port_support_tr').style.display = "";
			E('v2ray_uuid_tr').style.display = "";
			E('v2ray_alterid_tr').style.display = "";
			E('v2ray_protocol_tr').style.display = "";
			E('v2ray_security_tr').style.display = "";
			E('v2ray_network_tr').style.display = "";
			E('v2ray_headtype_tcp_tr').style.display = "";
			E('v2ray_headtype_kcp_tr').style.display = "";
			E('v2ray_serviceName_tr').style.display = "";
			E('v2ray_network_path_tr').style.display = "";
			E('v2ray_network_host_tr').style.display = "";
			E('v2ray_network_tlshost_tr').style.display = "";
			E('v2ray_network_flow_tr').style.display = "";
			E('v2ray_network_security_tr').style.display = "";
			E('allowinsecure_tr').style.display = "";
			E('fragment_tr').style.display = "";
			E('v2ray_mux_enable_tr').style.display = "";
			E('v2ray_mux_concurrency_tr').style.display = "";
			E('v2ray_json_tr').style.display = "none";
			var http_on_2 = E("ss_node_table_v2ray_network").value == "tcp" && E("ss_node_table_v2ray_headtype_tcp").value == "http";
			var serviceName_on_2 = E("ss_node_table_v2ray_network").value == "grpc";
			var host_on_2 = E("ss_node_table_v2ray_network").value == "ws" || E("ss_node_table_v2ray_network").value == "h2" || http_on_2;
			var path_on_2 = E("ss_node_table_v2ray_network").value == "ws" || E("ss_node_table_v2ray_network").value == "h2" || E("ss_node_table_v2ray_network").value == "kcp" ;
			var tls_on_2 = E("ss_node_table_v2ray_network_security").value == "tls" ;
			var reality_on_2 = E("ss_node_table_v2ray_protocol").value == "vless" && E("ss_node_table_v2ray_network_security").value == "reality";
			var vision_on_2 = E("ss_node_table_v2ray_protocol").value == "vless" && E("ss_node_table_v2ray_network").value == "tcp" && (E("ss_node_table_v2ray_network_security").value == "tls" || E("ss_node_table_v2ray_network_security").value == "reality");	

			showhide("v2ray_headtype_tcp_tr", (E("ss_node_table_v2ray_network").value == "tcp"));
			showhide("v2ray_headtype_kcp_tr", (E("ss_node_table_v2ray_network").value == "kcp"));
			showhide("v2ray_serviceName_tr", serviceName_on_2);
			showhide("v2ray_network_host_tr", host_on_2);
			showhide("v2ray_network_tlshost_tr", tls_on_2 || reality_on_2);
			showhide("allowinsecure_tr", tls_on_2);
//			showhide("fragment_tr", tls_on_2);
			showhide("v2ray_network_flow_tr", vision_on_2 || reality_on_2);
			showhide("vision_flow_opt" , vision_on_2 || reality_on_2);
			showhide("v2ray_network_path_tr", path_on_2);
			showhide("v2ray_mux_concurrency_tr", (E("ss_node_table_v2ray_mux_enable").checked));
			showhide("v2ray_json_tr", (E("ss_node_table_v2ray_use_json").checked));
			showhide("v2ray_alterid_tr", (E("ss_node_table_v2ray_protocol").value == "vmess"));
			showhide("fingerprint_tr", true);
			showhide("xray_publicKey_tr", reality_on_2);
			showhide("xray_shortId_tr", reality_on_2);
		}
	}
	__ss_reboot_check=db_ss["ss_reboot_check"];
	if (__ss_reboot_check == "0") {
		E('_ss_basic_day_pre').style.display="none";
		E('_ss_basic_week_pre').style.display="none";
		E('_ss_basic_time_pre').style.display="none";
		E('_ss_basic_inter_pre').style.display="none";
		E('_ss_basic_custom_pre').style.display="none";
		E('_ss_basic_send_text').style.display="none";
	} else if(__ss_reboot_check	== "1")	{
		E('_ss_basic_week_pre').style.display="none";
		E('_ss_basic_day_pre').style.display="none";
		E('_ss_basic_time_pre').style.display="inline";
		E('_ss_basic_inter_pre').style.display="none";
		E('_ss_basic_custom_pre').style.display="none";
		E('_ss_basic_send_text').style.display="inline";
	} else if(__ss_reboot_check	== "2")	{
		E('_ss_basic_week_pre').style.display="inline";
		E('_ss_basic_day_pre').style.display="none";
		E('_ss_basic_time_pre').style.display="inline";
		E('_ss_basic_inter_pre').style.display="none";
		E('_ss_basic_custom_pre').style.display="none";
		E('_ss_basic_send_text').style.display="inline";
	} else if(__ss_reboot_check	== "3")	{
		E('_ss_basic_week_pre').style.display="none";
		E('_ss_basic_day_pre').style.display="inline";
		E('_ss_basic_time_pre').style.display="inline";
		E('_ss_basic_inter_pre').style.display="none";
		E('_ss_basic_custom_pre').style.display="none";
		E('_ss_basic_send_text').style.display="inline";
	} else if(__ss_reboot_check	== "4")	{
		E('_ss_basic_week_pre').style.display="none";
		E('_ss_basic_day_pre').style.display="none";
		E('_ss_basic_time_pre').style.display="none";
		E('_ss_basic_inter_pre').style.display="inline";
		E('_ss_basic_custom_pre').style.display="none";
		E('_ss_basic_send_text').style.display="inline";
		__ss_basic_inter_pre=db_ss["ss_basic_inter_pre"];
		if (__ss_basic_inter_pre ==	"1") {
			E('ss_basic_inter_min').style.display="inline";
			E('ss_basic_inter_hour').style.display="none";
			E('ss_basic_inter_day').style.display="none";
			E('_ss_basic_time_pre').style.display="none";
			E('_ss_basic_inter_pre').style.display="inline";
			E('_ss_basic_send_text').style.display="inline";
		} else if(__ss_basic_inter_pre == "2") {
			E('ss_basic_inter_min').style.display="none";
			E('ss_basic_inter_hour').style.display="inline";
			E('ss_basic_inter_day').style.display="none";
			E('_ss_basic_time_pre').style.display="none";
			E('_ss_basic_inter_pre').style.display="inline";
			E('_ss_basic_send_text').style.display="inline";
		} else if(__ss_basic_inter_pre == "3") {
			E('ss_basic_inter_min').style.display="none";
			E('ss_basic_inter_hour').style.display="none";
			E('ss_basic_inter_day').style.display="inline";
			E('_ss_basic_time_pre').style.display="inline";
			E('_ss_basic_inter_pre').style.display="inline";
			E('_ss_basic_send_text').style.display="inline";
		}
	} else if(__ss_reboot_check	== "5")	{
		E('_ss_basic_week_pre').style.display="none";
		E('_ss_basic_day_pre').style.display="none";
		E('_ss_basic_time_pre').style.display="inline";
		E('_ss_basic_inter_pre').style.display="none";
		E('_ss_basic_custom_pre').style.display="inline";
		E('_ss_basic_send_text').style.display="inline";
		E('ss_basic_time_hour').style.display="none";
	}
	
	refresh_acl_table();
}

// 分组表头的空组自动隐藏。
// "账号设置"那一页有 61 个设置行、其中 34 行按节点类型条件隐藏（update_visibility 里
// 「账号设置」原有 6 个分组表头，现只保留「节点」一个（真机反馈：其余是噪音）。
// 原先这里有个 update_group_headers()：从一个 .ss-group 往下扫到下一个 .ss-group，
// 中间没有可见行就把表头也隐藏，用来避免"空组留下孤立表头"。
// 【为什么删掉它】它挂在 update_visibility() 上，而 update_visibility 的 12 个调用点
// 全都发生在 tablet_1（账号设置）已经隐藏的时候（其它页签的 handler 与控件事件）。
// 那一刻 tablet_1 里所有行的 offsetParent 都是 null，于是它把仅存的「节点」表头
// 也判成空组、写上行内 display:none；而切回「账号设置」没有任何代码重算 ——
// 结果是用户点一次别的页签再回来，唯一该保留的标题就永久消失了。
// 只剩一个分组之后这套机制也没有存在意义：「节点」组下面紧跟节点选择与模式选择两行，
// 全项目没有任何 showhide 引用它们，该组不可能为空。
function update_visibility() {
	apply_game_mode_limit();
	var a = E("ss_basic_rule_update").value == "1";
	var e = E("ss_dns_china").value == "12";
	var f = E("ss_foreign_dns").value;
	var g = E("ss_basic_tri_reboot_time").value;
	var h = E("ss_basic_server_resolver").value == "12";
	showhide("ss_basic_rule_update_time", a);
	showhide("update_choose", a);
	showhide("ss_basic_udp_sync_game_port_tr", E("ss_basic_udp_sync").value == "3");
	showhide("ss_dns_china_user", e);
	showhide("ss_basic_server_resolver_user", h);
	showhide("ss_chinadns_user", (f == "2"));
	showhide("ss_dns2socks_user", (f == "3"));
	showhide("ss_sstunnel_user", (f == "4"));
	showhide("ss_chinadns1_user", (f == "5"));
	showhide("ss_direct_user", (f == "8"));
	showhide("ss_basic_tri_reboot_time_note", (g != "0"));
	showhide("ss_basic_tri_reboot_policy", (g != "0"));
	if(f == "6"){
		$("#ss_foreign_dns_note").html('DNS over HTTPS (DoH)，<a href="https://cloudflare-dns.com/zh-Hans/" target="_blank"><em>cloudflare服务</em></a>，拒绝一切污染~');
	}else if(f == "7"){
		$("#ss_foreign_dns_note").html('v2ray_dns只有启用v2ray节点的时能使用');
	}else{
		$("#ss_foreign_dns_note").html('');
	}
}

function generate_lan_list(){
	ipaddr="<% nvram_get("lan_ipaddr"); %>";
	var ips = ipaddr.split(".");
	ip = ips[0] + "." + ips[1] + "." + ips[2] + ".";
	for (var i = 2; i < 255; i++) {
		$("#ss_acl_ip").append("<option value='" + ip + i + "'>" + ip + i + "</option>");
	}
}

function ssconf_node2obj(node_sel) {
	//alert(1)
	var p = "ssconf_basic";
	var obj = {};
	var params2 = ["password", "v2ray_json", "server", "mode", "port", "password", "method", "ss_v2ray_plugin", "ss_v2ray_plugin_opts", "koolgame_udp", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "v2ray_uuid", "v2ray_alterid", "v2ray_protocol", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp",  "v2ray_serviceName","v2ray_network_path", "v2ray_network_host", "v2ray_network_tlshost", "v2ray_network_flow","allowinsecure","fragment","v2ray_mux_enable", "v2ray_network_security", "v2ray_mux_concurrency", "v2ray_use_json", "trojan_binary", "trojan_network", "trojan_sni","naive_protocol", "naive_user","fingerprint","xray_publicKey","xray_shortId"];

	for (var i = 0; i < params2.length; i++) {
		obj["ss_basic_" + params2[i]] = db_ss[p + "_" + params2[i] + "_" + node_sel] || "";
	}
//	var xy = db_ss[p + "_" + "v2ray_protocol" + "_" + node_sel];
//	if(xy=="vless"){
//		$("#use_uuid_on").text("用户id（id）")
//	}else if(xy=="vmess"){
//		$("#use_uuid_on").text("用户id（id）")
//	}else if(xy=="trojan"){
//		$("#use_uuid_on").text("密码")
//	}else{
//		$("#use_uuid_on").text("用户id（id）")
//	}
	
	var trojan_binary = db_ss[p + "_" + "trojan_binary" + "_" + node_sel]
	if(trojan_binary=="Trojan-Go"){
		obj["ss_basic_" + "trojan_binary"] = "Trojan-Go"
	}else if(trojan_binary=="Hysteria2"){
		obj["ss_basic_" + "trojan_binary"] = "Hysteria2"
	}else if(trojan_binary=="AnyTLS"){
		obj["ss_basic_" + "trojan_binary"] = "AnyTLS"
	}else{
		obj["ss_basic_" + "trojan_binary"] = "Trojan"
	}
	
	obj["ssconf_basic_node"] = node_sel;
	//console.log("test", obj);
	return obj;
}


//使用中节点改变
function protocol_change_on(xy){
	//alert(2)
//	if(xy=="vless"){
//		$("#use_uuid_on").text("用户id（id）")
//	}else if(xy=="vmess"){
//		$("#use_uuid_on").text("用户id（id）")
//	}else if(xy=="trojan"){
//		$("#use_uuid_on").text("密码")
//	}else{
//		$("#use_uuid_on").text("用户id（id）")
//	}
	if (xy == "vless") {
		E("ss_basic_v2ray_alterid").value = "";
	}
	verifyFields();
}

//非使用中节点改变
function protocol_change_off(xy){
	//alert(3)
//	if(xy=="vless"){
//		$("#use_uuid_off").text("用户id（id）")
//	}else if(xy=="vmess"){
//		$("#use_uuid_off").text("用户id（id）")
//	}else if(xy=="trojan"){
//		$("#use_uuid_off").text("密码")
//	}else{
//		$("#use_uuid_off").text("用户id（id）")
//	}
	if (xy == "vless") {
		E("ss_node_table_v2ray_alterid").value = "";
	}
	verifyFields();
}



//非使用中节点改变
function trojan_change_off(xy){
    if (xy == "Trojan-Go") {
        E("ss_node_table_trojan_binary").value = "Trojan-Go";
    } else if (xy == "Hysteria2") {
        E("ss_node_table_trojan_binary").value = "Hysteria2";
    } else if (xy == "AnyTLS") {
        E("ss_node_table_trojan_binary").value = "AnyTLS";
    } else {
        E("ss_node_table_trojan_binary").value = "Trojan";
    }
	if (xy == "Trojan" || xy == "Hysteria2" || xy == "AnyTLS") {
        E("ss_node_table_v2ray_network_path").value = "";
        E("ss_node_table_v2ray_network_host").value = "";
        E("ss_node_table_fingerprint").value = "";
    }
    verifyFields();
}

function network_change_off(xy){
	if(xy=="1"){
		E("ss_node_table_trojan_network").value = "1";
	}else{
		E("ss_node_table_trojan_network").value = "0";
	}
	verifyFields();
}
function flow_change_off(xy){
	if (xy != "tcp") {
		E("ss_node_table_v2ray_network_flow").value = "";
	}else if (xy == "tcp" || xy == "grpc" ) {
		E("ss_node_table_v2ray_network_path").value = "";
		E("ss_node_table_v2ray_network_host").value = "";
	}
	verifyFields();
}
function reality_change_off(xy){
	if (xy != "reality") {
		E("ss_node_table_xray_publicKey").value = "";
		E("ss_node_table_xray_shortId").value = "";
	}
	verifyFields();
}

function ss_node_sel(s) {
	if(!s){
		var node_sel = E("ssconf_basic_node").value;
		var obj = ssconf_node2obj(node_sel);
		update_ss_ui(obj);
	}
	verifyFields();
}

function getAllConfigs() {
	var dic = {};
	for (var field in db_ss) {
		names = field.split("ssconf_basic_name_");
		dic[names[names.length - 1]] = 'ok';
	}
	confs = {};
	//console.log("456", dic)
	var p = "ssconf_basic";
	for (var field in dic) {
		if (isNaN(field)){
			continue;
		}
		var obj = {};
		//节点名
		if (typeof db_ss[p + "_name_" + field] == "undefined") {
			obj["name"] = '节点' + field;
		} else {
			obj["name"] = db_ss[p + "_name_" + field];
		}
		if (typeof db_ss[p + "_webtest_" + field] == "undefined") {
			obj["webtest"] = '';
		} else if (db_ss[p + "_webtest_" + field] == "failed") {
			obj["webtest"] = '<font color="#FFCC00">failed</font>';
		} else if (db_ss[p + "_webtest_" + field] == "timeout") {
			obj["webtest"] = '<font color="#FF9900">timeout</font>';
		} else {
			var wt = db_ss[p + "_webtest_" + field];

			if (wt.indexOf("[S]") != -1) {
				obj["webtest"] = '<font color="#00FFCC">' + wt + '</font>';
			} else if (wt.indexOf("[A]") != -1) {
				obj["webtest"] = '<font color="#7CFC00">' + wt + '</font>';
			} else if (wt.indexOf("[B]") != -1) {
				obj["webtest"] = '<font color="#FFFF00">' + wt + '</font>';
			} else if (wt.indexOf("[C]") != -1) {
				obj["webtest"] = '<font color="#FFA500">' + wt + '</font>';
			} else if (wt.indexOf("[D]") != -1) {
				obj["webtest"] = '<font color="#FF6666">' + wt + '</font>';
			} else {
				obj["webtest"] = wt;
			}
		}
		//空值为0
		if (typeof db_ss[p + "_use_lb_" + field] == "undefined") {
			obj["use_lb"] = '0';
		} else {
			obj["use_lb"] = db_ss[p + "_use_lb_" + field];
		}
		
		if (typeof db_ss[p + "_server_" + field] == "undefined") {
			if(db_ss[p + "_v2ray_use_json_" + field] ==  "1"){
				obj["server"] = "v2ray json";
			}else{
				obj["server"] = '';
			}
		} else {
			obj["server"] = db_ss[p + "_server_" + field];
		}

		if (typeof db_ss[p + "_port_" + field] == "undefined") {
			if(db_ss[p + "_v2ray_use_json_" + field] ==  "1"){
				obj["port"] = "json";
			}else{
				obj["port"] = '';
			}
		} else {
			obj["port"] = db_ss[p + "_port_" + field];
		}

		if (typeof db_ss[p + "_method_" + field] == "undefined") {
			if(db_ss[p + "_v2ray_use_json_" + field] ==  "0"){
				obj["method"] = db_ss[p + "_v2ray_security_" + field];
			}else if(db_ss[p + "_v2ray_use_json_" + field] ==  "1"){
				obj["method"] = "v2ray json";
			}else{
				obj["method"] = '';
			}
		} else {
			obj["method"] = db_ss[p + "_method_" + field];
		}

		var params = ["password", "mode", "ss_v2ray_plugin", "ss_v2ray_plugin_opts", "koolgame_udp", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "group", "weight", "lbmode", "v2ray_uuid", "v2ray_alterid", "v2ray_protocol", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_serviceName", "v2ray_network_path", "v2ray_network_host", "v2ray_network_tlshost" ,"trojan_sni", "trojan_binary", "trojan_network", "v2ray_network_flow", "v2ray_network_security", "v2ray_mux_concurrency", "v2ray_json", "v2ray_use_json", "v2ray_mux_enable","allowinsecure","fragment","naive_protocol", "naive_user","fingerprint", "xray_publicKey","xray_shortId"];
		for (var i = 0; i < params.length; i++) {
			var ofield = p + "_" + params[i] + "_" + field;
			if (typeof db_ss["ssconf_basic_mode_" + field] == "undefined") {
				obj[params[i]] = '';
			}else{
				obj[params[i]] = db_ss[ofield];
			}
		}
		if (obj != null) {
			var node_i = parseInt(field);
			if (node_i > node_global_max) {
				node_global_max = node_i;
			}
			obj["node"] = field;
			confs[field] = obj;
		}
	}
	//console.log(confs)
	return confs;
}

function loadBasicOptions(confs) {
	var option = $("#ssconf_basic_node");
	var option2 = $("#ssconf_basic_test_node");

	option.find('option').remove().end();
	option2.find('option').remove().end();

	option2.append($("<option>", {
		value: 0,
		text: "全部节点"
	}));
	for (var field in confs) {
		var c = confs[field];
		if (c.rss_protocol) {  //判断节点为SSR
			if (c.group) {
				option.append($("<option>", {
					value: field,
					text: "【SSR】" + c.group + " - " + c.name
				}));
			} else {
				option.append($("<option>", {
					value: field,
					text: "【SSR】" + c.name
				}));
			}
		} else if (c.koolgame_udp == "0" || c.koolgame_udp == "1") {  //判断节点为koolgame
				option.append($("<option>", {
					value: field,
					text: "【koolgame】" + c.name
				}));
		} else if (c["v2ray_protocol"] || c["v2ray_use_json"] == "0" || c["v2ray_use_json"] == "1") { //判断节点为v2ray
					option.append($("<option>", {
						value: field,
						text: "【V2Ray】" + c.name
					}));
		} else if (c["trojan_binary"]) { // 其余为 Trojan 节点
                    option.append($("<option>", {
                        value: field,
                        text: "【" + c.trojan_binary + "】" + c.name
                    }));
		} else if (c["naive_protocol"]) { // 其余为 Naive 节点
                    option.append($("<option>", {
                        value: field,
                        text: "【Naive】" + c.name
                    }));				
					
		} else  {  //判断节点为SS 
					option.append($("<option>", {
						value: field,
						text: "【SS】" + c.name
					}));
		}

		option2.append($("<option>", {
			value: field,
			text: c.name
		}));
	}
	if (node_global_max > 0) {
		var node_sel = "1";
		if (typeof db_ss.ssconf_basic_node != "undefined") {
			node_sel = db_ss.ssconf_basic_node;
		}
		option.val(node_sel);
		ss_node_sel();
	}else{
		ss_node_sel("1");
	}
}

function loadAllConfigs() {
	confs = getAllConfigs();
	loadBasicOptions(confs);
}

function updateSs_node_listView() {
	$.ajax({
		url: '/dbconf?p=ss',
		dataType: 'html',
		error: function(xhr) {},
		success: function(response) {
			$.globalEval(response);
			loadAllConfigs();
		}
	});
}

function Add_profile() { //点击节点页面内添加节点动作
	checkTime = 2001; //停止节点页面刷新
	tabclickhandler(0); //默认显示添加ss节点
	E("ss_node_table_name").value = "";
	E("ss_node_table_server").value = "";
	E("ss_node_table_port").value = "";
	E("ss_node_table_password").value = "";
	E("ss_node_table_method").value = "none";
	E("ss_node_table_mode").value = "1";
	E("ss_node_table_ss_v2ray_plugin").value = "0"
	E("ss_node_table_ss_v2ray_plugin_opts").value = "";
	E("ss_node_table_rss_protocol").value = "origin";
	E("ss_node_table_naive_protocol").value = "https";
	E("ss_node_table_naive_user").value = "";
	E("ss_node_table_rss_protocol_param").value = "";
	E("ss_node_table_rss_obfs").value = "plain";
	E("ss_node_table_rss_obfs_param").value = "";
	E("ss_node_table_koolgame_udp").value = "0";
	E("ss_node_table_v2ray_uuid").value = "";
	E("ss_node_table_v2ray_alterid").value = "";
	E("ss_node_table_v2ray_network").value = "tcp";
	E("ss_node_table_v2ray_json").value = "";
	E("ss_node_table_v2ray_serviceName").value = "";
	E("ss_node_table_v2ray_network_path").value = "";
	E("ss_node_table_v2ray_network_flow").value = "";
	E("ss_node_table_v2ray_network_tlshost").value = "";
	E("ss_node_table_xray_publicKey").value = "";
	E("ss_node_table_xray_shortId").value = "";
	E("ss_node_table_trojan_sni").value = "";
	E("ss_node_table_trojan_binary").value = "Trojan";
	E("ss_node_table_trojan_network").value = "0";
	E("ss_node_table_fingerprint").value = "";
	E("ss_node_table_v2ray_network_security").value = "none";
	E("ss_node_table_v2ray_headtype_tcp").value = "none";
	E("ssTitle").style.display = "";
	E("ssrTitle").style.display = "none";
	E("gamev2Title").style.display = "none";
	E("v2rayTitle").style.display = "";
	E("trojanTitle").style.display = "";
	E("naiveTitle").style.display = "none";
	E("add_node").style.display = "";
	E("edit_node").style.display = "none";
	E("continue_add").style.display = "";
	E("ss_node_table_v2ray_protocol").value = "vmess";
	$("#vpnc_settings").fadeIn(200);
	$("#use_uuid_off").text("用户id（id）");
	$("#v2rayTitle").html("添加V2Ray配置");
	$("#ss_node_table_v2ray_mux_enable").prop("checked",false);
	$("#ss_node_table_allowinsecure").prop("checked",false);
	$("#ss_node_table_fragment").prop("checked",false);
	$("#continue_add_box").prop("checked",false);
	E("ss_node_table_v2ray_mux_concurrency").value = "";
}

function cancel_add_rule() { //点击添加节点面板上的返回
	E("vpnc_settings").style.display = "none";
}

var save_flag = ""; //type of Saving profile
function tabclickhandler(_type) {
	E('ssTitle').className = "vpnClientTitle_td_unclick";
	E('ssrTitle').className = "vpnClientTitle_td_unclick";
	E('gamev2Title').className = "vpnClientTitle_td_unclick";
	E('v2rayTitle').className = "vpnClientTitle_td_unclick";
	E('trojanTitle').className = "vpnClientTitle_td_unclick";
	E('naiveTitle').className = "vpnClientTitle_td_unclick";
	if (_type == 0) {
		save_flag = "shadowsocks";
		E("vpnc_type").value = "shadowsocks";
		E('ssTitle').className = "vpnClientTitle_td_click";
		E('v2ray_use_json_tr').style.display = "none";
		E('ss_name_support_tr').style.display = "";
		E('ss_server_support_tr').style.display = "";
		E('ss_port_support_tr').style.display = "";
		E('ss_passwd_support_tr').style.display = "";
		E('ss_method_support_tr').style.display = "";
		E('ssr_protocol_tr').style.display = "none";
		E('ssr_protocol_param_tr').style.display = "none";
		E('ssr_obfs_tr').style.display = "none";
		E('ssr_obfs_param_tr').style.display = "none";
		E('gameV2_udp_tr').style.display = "none";
		E('v2ray_uuid_tr').style.display = "none";
		E('v2ray_alterid_tr').style.display = "none";
		E('v2ray_protocol_tr').style.display = "none";
		E('v2ray_security_tr').style.display = "none";
		E('xray_publicKey_tr').style.display = "none";
		E('xray_shortId_tr').style.display = "none";
		E('v2ray_network_tr').style.display = "none";
		E('v2ray_headtype_tcp_tr').style.display = "none";
		E('v2ray_headtype_kcp_tr').style.display = "none";
		E('v2ray_serviceName_tr').style.display = "none";		
		E('v2ray_network_path_tr').style.display = "none";
		E('v2ray_network_host_tr').style.display = "none";
		E('v2ray_network_flow_tr').style.display = "none";
		E('v2ray_network_tlshost_tr').style.display = "none";
		E('v2ray_network_security_tr').style.display = "none";
		E('allowinsecure_tr').style.display = "none";
		E('fragment_tr').style.display = "none";
		E('v2ray_mux_enable_tr').style.display = "none";
		E('v2ray_mux_concurrency_tr').style.display = "none";
		E('v2ray_json_tr').style.display = "none";
		E('trojan_sni_tr').style.display = "none";
		E('trojan_binary_tr').style.display = "none";
		E('trojan_network_tr').style.display = "none";
		E('fingerprint_tr').style.display = "none";
		E('naive_protocol_tr').style.display = "none";
		E('naive_user_tr').style.display = "none";
		showhide("ss_v2ray_plugin_support", ($("#ss_node_table_mode").val() != "3"));
		showhide("ss_v2ray_plugin_opts_support", ($("#ss_node_table_mode").val() != "3" && $("#ss_node_table_ss_v2ray_plugin").val() != "0"));
	} else if (_type == 1) {
		save_flag = "shadowsocksR";
		E("vpnc_type").value = "shadowsocksR";
		E('ssrTitle').className = "vpnClientTitle_td_click";
		E('v2ray_use_json_tr').style.display = "none";
		E('ss_name_support_tr').style.display = "";
		E('ss_server_support_tr').style.display = "";
		E('ss_port_support_tr').style.display = "";
		E('ss_passwd_support_tr').style.display = "";
		E('ss_method_support_tr').style.display = "";
		E('ss_v2ray_plugin_support').style.display = "none";
		E('ss_v2ray_plugin_opts_support').style.display = "none";
		E('ssr_protocol_tr').style.display = "";
		E('ssr_protocol_param_tr').style.display = "";
		E('ssr_obfs_tr').style.display = "";
		E('ssr_obfs_param_tr').style.display = "";
		E('gameV2_udp_tr').style.display = "none";
		E('v2ray_uuid_tr').style.display = "none";
		E('v2ray_alterid_tr').style.display = "none";
		E('v2ray_protocol_tr').style.display = "none";
		E('v2ray_security_tr').style.display = "none";
		E('xray_publicKey_tr').style.display = "none";
		E('xray_shortId_tr').style.display = "none";
		E('v2ray_network_tr').style.display = "none";
		E('v2ray_headtype_tcp_tr').style.display = "none";
		E('v2ray_headtype_kcp_tr').style.display = "none";
		E('v2ray_serviceName_tr').style.display = "none";	
		E('v2ray_network_path_tr').style.display = "none";
		E('v2ray_network_host_tr').style.display = "none";
		E('v2ray_network_tlshost_tr').style.display = "none";
		E('v2ray_network_security_tr').style.display = "none";
		E('allowinsecure_tr').style.display = "none";
		E('fragment_tr').style.display = "none";
		E('v2ray_mux_enable_tr').style.display = "none";
		E('v2ray_mux_concurrency_tr').style.display = "none";
		E('v2ray_json_tr').style.display = "none";
		E('trojan_sni_tr').style.display = "none";
		E('trojan_binary_tr').style.display = "none";
		E('trojan_network_tr').style.display = "none";
		E('fingerprint_tr').style.display = "none";
		E('naive_protocol_tr').style.display = "none";
		E('naive_user_tr').style.display = "none";
	} else if (_type == 2) {
		save_flag = "gameV2";
		E("vpnc_type").value = "gameV2";
		E('gamev2Title').className = "vpnClientTitle_td_click";
		E('v2ray_use_json_tr').style.display = "none";
		E('ss_name_support_tr').style.display = "";
		E('ss_server_support_tr').style.display = "";
		E('ss_port_support_tr').style.display = "";
		E('ss_passwd_support_tr').style.display = "";
		E('ss_method_support_tr').style.display = "";
		E('ss_v2ray_plugin_support').style.display = "none";
		E('ss_v2ray_plugin_opts_support').style.display = "none";
		E('ssr_protocol_tr').style.display = "none";
		E('ssr_protocol_param_tr').style.display = "none";
		E('ssr_obfs_tr').style.display = "none";
		E('ssr_obfs_param_tr').style.display = "none";
		E('gameV2_udp_tr').style.display = "";
		E('v2ray_uuid_tr').style.display = "none";
		E('v2ray_alterid_tr').style.display = "none";
		E('v2ray_protocol_tr').style.display = "none";
		E('v2ray_security_tr').style.display = "none";
		E('xray_publicKey_tr').style.display = "none";
		E('xray_shortId_tr').style.display = "none";
		E('v2ray_network_tr').style.display = "none";
		E('v2ray_headtype_tcp_tr').style.display = "none";
		E('v2ray_headtype_kcp_tr').style.display = "none";
		E('v2ray_serviceName_tr').style.display = "none";	
		E('v2ray_network_path_tr').style.display = "none";
		E('v2ray_network_host_tr').style.display = "none";
		E('v2ray_network_tlshost_tr').style.display = "none";
		E('v2ray_network_security_tr').style.display = "none";
		E('allowinsecure_tr').style.display = "none";
		E('fragment_tr').style.display = "none";
		E('v2ray_mux_enable_tr').style.display = "none";
		E('v2ray_mux_concurrency_tr').style.display = "none";
		E('v2ray_json_tr').style.display = "none";
		E('trojan_sni_tr').style.display = "none";
		E('trojan_binary_tr').style.display = "none";
		E('trojan_network_tr').style.display = "none";
		E('fingerprint_tr').style.display = "none";
		E('naive_protocol_tr').style.display = "none";
		E('naive_user_tr').style.display = "none";
	} else if (_type == 5) {
		save_flag = "naive";
		E("vpnc_type").value = "naive";
		E('naiveTitle').className = "vpnClientTitle_td_click";
		E('v2ray_use_json_tr').style.display = "none";
		E('ss_name_support_tr').style.display = "";
		E('naive_protocol_tr').style.display = "";
		E('ss_method_support_tr').style.display = "none";
		E('ss_server_support_tr').style.display = "";
		E('ss_port_support_tr').style.display = "";
		E('naive_user_tr').style.display = "";
		E('ss_passwd_support_tr').style.display = "";
		E('ss_v2ray_plugin_support').style.display = "none";
		E('ss_v2ray_plugin_opts_support').style.display = "none";
		E('ssr_protocol_tr').style.display = "none";
		E('ssr_protocol_param_tr').style.display = "none";
		E('ssr_obfs_tr').style.display = "none";
		E('ssr_obfs_param_tr').style.display = "none";
		E('gameV2_udp_tr').style.display = "none";
		E('v2ray_uuid_tr').style.display = "none";
		E('v2ray_alterid_tr').style.display = "none";
		E('v2ray_protocol_tr').style.display = "none";
		E('v2ray_security_tr').style.display = "none";
		E('xray_publicKey_tr').style.display = "none";
		E('xray_shortId_tr').style.display = "none";
		E('v2ray_network_tr').style.display = "none";
		E('v2ray_headtype_tcp_tr').style.display = "none";
		E('v2ray_headtype_kcp_tr').style.display = "none";
		E('v2ray_serviceName_tr').style.display = "none";	
		E('v2ray_network_path_tr').style.display = "none";
		E('v2ray_network_host_tr').style.display = "none";
		E('v2ray_network_tlshost_tr').style.display = "none";
		E('v2ray_network_security_tr').style.display = "none";
		E('allowinsecure_tr').style.display = "none";
		E('fragment_tr').style.display = "none";
		E('v2ray_mux_enable_tr').style.display = "none";
		E('v2ray_mux_concurrency_tr').style.display = "none";
		E('v2ray_json_tr').style.display = "none";
		E('trojan_sni_tr').style.display = "none";
		E('trojan_binary_tr').style.display = "none";
		E('trojan_network_tr').style.display = "none";	
		E('fingerprint_tr').style.display = "none";	
	} else if (_type == 3) {
		save_flag = "v2ray";
		E("vpnc_type").value = "v2ray";
		E('v2rayTitle').className = "vpnClientTitle_td_click";
		E('v2ray_use_json_tr').style.display = "";
		E('ss_name_support_tr').style.display = "";
		E('ss_passwd_support_tr').style.display = "none";
		E('ss_method_support_tr').style.display = "none";
		E('ss_v2ray_plugin_support').style.display = "none";
		E('ss_v2ray_plugin_opts_support').style.display = "none";
		E('ssr_protocol_tr').style.display = "none";
		E('ssr_protocol_param_tr').style.display = "none";
		E('ssr_obfs_tr').style.display = "none";
		E('ssr_obfs_param_tr').style.display = "none";
		E('gameV2_udp_tr').style.display = "none";
		E('trojan_sni_tr').style.display = "none";
		E('trojan_binary_tr').style.display = "none";
		E('trojan_network_tr').style.display = "none";
		E('naive_protocol_tr').style.display = "none";
		E('naive_user_tr').style.display = "none";
		if(E("ss_node_table_v2ray_use_json").checked){
			E('ss_server_support_tr').style.display = "none";
			E('ss_port_support_tr').style.display = "none";
			E('v2ray_uuid_tr').style.display = "none";
			E('v2ray_alterid_tr').style.display = "none";
			E('v2ray_protocol_tr').style.display = "none";
			E('v2ray_security_tr').style.display = "none";
			E('v2ray_network_tr').style.display = "none";
			E('v2ray_headtype_tcp_tr').style.display = "none";
			E('v2ray_headtype_kcp_tr').style.display = "none";
			E('xray_publicKey_tr').style.display = "none";
			E('xray_shortId_tr').style.display = "none";
			E('v2ray_serviceName_tr').style.display = "none";	
			E('v2ray_network_path_tr').style.display = "none";
			E('v2ray_network_host_tr').style.display = "none";
			E('v2ray_network_tlshost_tr').style.display = "none";
			E('v2ray_network_flow_tr').style.display = "none";
			E('v2ray_network_security_tr').style.display = "none";
			E('allowinsecure_tr').style.display = "none";
			E('fragment_tr').style.display = "none";
			E('v2ray_mux_enable_tr').style.display = "none";
			E('v2ray_mux_concurrency_tr').style.display = "none";
			E('v2ray_json_tr').style.display = "";
			E('fingerprint_tr').style.display = "none";
		}else{
			E('ss_server_support_tr').style.display = "";
			E('ss_port_support_tr').style.display = "";
			E('v2ray_uuid_tr').style.display = "";
			E('v2ray_alterid_tr').style.display = "";
			E('v2ray_protocol_tr').style.display = "";
			E('v2ray_security_tr').style.display = "";
			E('v2ray_network_tr').style.display = "";
			E('v2ray_headtype_tcp_tr').style.display = "";
			E('v2ray_headtype_kcp_tr').style.display = "";
			E('xray_publicKey_tr').style.display = "";
			E('xray_shortId_tr').style.display = "";
			E('v2ray_serviceName_tr').style.display = "";	
			E('v2ray_network_path_tr').style.display = "";
			E('v2ray_network_host_tr').style.display = "";
			E('v2ray_network_tlshost_tr').style.display = "";
			E('v2ray_network_flow_tr').style.display = "";
			E('v2ray_network_security_tr').style.display = "";
			E('allowinsecure_tr').style.display = "";
			E('fragment_tr').style.display = "";
			E('v2ray_mux_enable_tr').style.display = "";
			E('v2ray_mux_concurrency_tr').style.display = "";
			E('v2ray_json_tr').style.display = "none";
			var http_on_2 = E("ss_node_table_v2ray_network").value == "tcp" && E("ss_node_table_v2ray_headtype_tcp").value == "http";
			var host_on_2 = E("ss_node_table_v2ray_network").value == "ws" || E("ss_node_table_v2ray_network").value == "h2" || http_on_2;
			var serviceName_on_2 =  E("ss_node_table_v2ray_network").value == "grpc";
			var path_on_2 = E("ss_node_table_v2ray_network").value == "ws" || E("ss_node_table_v2ray_network").value == "h2" || E("ss_node_table_v2ray_network").value == "kcp";
			var tlshost_on_2 = E("ss_node_table_v2ray_network_security").value == "tls";
			var visionhost_on_2 = E("ss_node_table_v2ray_protocol").value == "vless" && E("ss_node_table_v2ray_network").value == "tcp" && (E("ss_node_table_v2ray_network_security").value == "tls" || E("ss_node_table_v2ray_network_security").value == "reality");	
			var realityhost_on_2 = E("ss_node_table_v2ray_protocol").value == "vless" && E("ss_node_table_v2ray_network_security").value == "reality";
			showhide("v2ray_headtype_tcp_tr", (E("ss_node_table_v2ray_network").value == "tcp"));
			showhide("v2ray_headtype_kcp_tr", (E("ss_node_table_v2ray_network").value == "kcp"));
			showhide("v2ray_network_host_tr", host_on_2);
			showhide("v2ray_serviceName_tr", serviceName_on_2);
			showhide("v2ray_network_path_tr", path_on_2);
			showhide("v2ray_network_tlshost_tr", tlshost_on_2 || realityhost_on_2);
			showhide("xray_publicKey_tr", realityhost_on_2);
			showhide("xray_shortId_tr", realityhost_on_2);
			showhide("v2ray_network_flow_tr", visionhost_on_2 || realityhost_on_2);
			showhide("vision_flow_opt", visionhost_on_2 || realityhost_on_2);
			showhide("allowinsecure_tr", tlshost_on_2 );
//			showhide("fragment_tr", (xtlshost_on_2 || tlshost_on_2 ));			
			showhide("v2ray_mux_concurrency_tr", (E("ss_node_table_v2ray_mux_enable").checked));
			showhide("v2ray_json_tr", (E("ss_node_table_v2ray_use_json").checked));
			showhide("v2ray_alterid_tr", (E("ss_node_table_v2ray_protocol").value == "vmess"));
			showhide("fingerprint_tr", true);
		}
	}else if (_type == 4) {
	    // 添加 Trojan 节点的界面
	    save_flag = "trojan";
        E("vpnc_type").value = "trojan";
        E('trojanTitle').className = "vpnClientTitle_td_click";

        // 显示别名、地址、端口和密码（公用 ss 的）
        E('ss_name_support_tr').style.display = "";
		E('ss_server_support_tr').style.display = "";
		E('ss_port_support_tr').style.display = "";
		E('ss_passwd_support_tr').style.display = "";
		E('trojan_binary_tr').style.display = "";
	//	E('trojan_network_tr').style.display = "";
		E('trojan_sni_tr').style.display = "";

		var trojan_binary_off_3 = E("ss_node_table_trojan_binary").value;
		var trojango_on_3 = trojan_binary_off_3 == "Trojan-Go";
		var anytls_on_3 = trojan_binary_off_3 == "AnyTLS";

		if(trojan_binary_off_3 == "Trojan" ){
			E('allowinsecure_tr').style.display = "";
			E('fragment_tr').style.display = "";
			E('v2ray_mux_enable_tr').style.display = "none";
			E('v2ray_mux_concurrency_tr').style.display = "none";
		}	
		else if(trojan_binary_off_3 == "Hysteria2" || anytls_on_3){
			E('allowinsecure_tr').style.display = "";
			E('fragment_tr').style.display = "none";
			E('v2ray_mux_enable_tr').style.display = "none";
			E('v2ray_mux_concurrency_tr').style.display = "none";
		}
		else{
			E('allowinsecure_tr').style.display = "none";
			E('fragment_tr').style.display = "none";
			E('v2ray_mux_enable_tr').style.display = "";
			E('v2ray_mux_concurrency_tr').style.display = "";
			showhide("v2ray_mux_concurrency_tr", (E("ss_node_table_v2ray_mux_enable").checked));
		}

		showhide("trojan_network_tr", trojango_on_3);
		showhide("fingerprint_tr", trojango_on_3);
		var host_on_3 = E("ss_node_table_trojan_network").value == "1" ;
		var path_on_3 = E("ss_node_table_trojan_network").value == "1" ;
		showhide("v2ray_network_host_tr", (trojango_on_3 && host_on_3));
		showhide("v2ray_network_path_tr", (trojango_on_3 && path_on_3));
//		showhide("ss_method_support_tr", trojango_on_3 );
//		showhide("ss_v2ray_plugin_support", trojango_on_3 );
//		showhide("ss_v2ray_plugin_opts_support", trojango_on_3 );
		
        // 不显示 ss 相关条目
        E('v2ray_use_json_tr').style.display = "none";
		E('ss_method_support_tr').style.display = "none";
		E('ss_v2ray_plugin_support').style.display = "none";
		E('ss_v2ray_plugin_opts_support').style.display = "none";
		E('ssr_protocol_tr').style.display = "none";
		E('ssr_protocol_param_tr').style.display = "none";
		E('ssr_obfs_tr').style.display = "none";
		E('ssr_obfs_param_tr').style.display = "none";
		E('gameV2_udp_tr').style.display = "none";
		// 不显示 v2ray 相关条目
		E('v2ray_protocol_tr').style.display = "none";
        E('v2ray_uuid_tr').style.display = "none";
        E('v2ray_alterid_tr').style.display = "none";
        E('v2ray_security_tr').style.display = "none";
        E('v2ray_network_tr').style.display = "none";
        E('v2ray_headtype_tcp_tr').style.display = "none";
        E('v2ray_headtype_kcp_tr').style.display = "none";
		E('v2ray_serviceName_tr').style.display = "none";	
		E('xray_publicKey_tr').style.display = "none";
		E('xray_shortId_tr').style.display = "none";
    //   E('v2ray_network_path_tr').style.display = "none";
    //   E('v2ray_network_host_tr').style.display = "none";
		E('v2ray_network_security_tr').style.display = "none";
		E('v2ray_json_tr').style.display = "none";
		E('v2ray_network_tlshost_tr').style.display = "none";
		E('v2ray_network_flow_tr').style.display = "none";
		// 不显示 naive 相关条目	
		E('naive_protocol_tr').style.display = "none";
		E('naive_user_tr').style.display = "none";
	} 
	return save_flag;
	// 切换"添加SS/V2Ray/Trojan…"页签会改变 save_flag，也就改变了对话框里节点的类型，
	// 必须重算游戏模式选项的可用性 —— 否则从非SS页签切到SS页签时它还是灰的。
	apply_game_mode_limit();
}

function add_ss_node_conf(flag) { //点击添加按钮动作
	var ns = {};
	var p = "ssconf_basic";
	node_global_max += 1;
	var params1 = ["mode", "name", "server", "port", "method", "ss_v2ray_plugin", "ss_v2ray_plugin_opts"]; //for ss
	var params2 = ["mode", "name", "server", "port", "method", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param"]; //for ssr
	var params3 = ["mode", "name", "server", "port", "method", "koolgame_udp"]; //for koolgame
	var params4_1 = ["mode", "name", "server", "port", "v2ray_uuid", "v2ray_alterid", "v2ray_protocol", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_serviceName", "v2ray_network_path", "v2ray_network_host", "v2ray_network_tlshost", "v2ray_network_flow", "v2ray_network_security", "v2ray_mux_concurrency","fingerprint","xray_publicKey", "xray_shortId"]; //for v2ray
	var params4_2 = ["v2ray_use_json", "v2ray_mux_enable","allowinsecure","fragment"]; //for v2ray
	var paramsTrojan = ["name", "server", "mode", "port","v2ray_network_path", "v2ray_network_host","trojan_sni","trojan_binary","trojan_network","allowinsecure","v2ray_mux_concurrency","fingerprint"]; //for trojan
	var params5 = ["mode", "name", "server", "port", "naive_protocol", "naive_user"]; //for naive
	
	if(!$.trim($('#ss_node_table_name').val())){
		alert("节点名不能为空！！");
		return false;
	}
	//for-trojan
/**	if($.trim($('#ss_node_table_v2ray_protocol').val())=="trojan"){
		if($.trim($('#ss_node_table_v2ray_network_security').val())=="none"){
			//alert("trojan必须填写[底层传输安全],如不清楚,默认请选择tls")
			E('ss_node_table_v2ray_network_security').value="tls"
		}
	}
**/	
	if (flag == 'shadowsocks') {
		for (var i = 0; i < params1.length; i++) {
			ns[p + "_" + params1[i] + "_" + node_global_max] = $.trim($('#ss_node_table' + "_" + params1[i]).val());
		}
		ns[p + "_password_" + node_global_max] = Base64.encode($.trim($("#ss_node_table_password").val()));
		ns[p + "_type_" + node_global_max] = "0";
	} else if (flag == 'shadowsocksR') {
		for (var i = 0; i < params2.length; i++) {
			ns[p + "_" + params2[i] + "_" + node_global_max] = $.trim($('#ss_node_table' + "_" + params2[i]).val());
		}
		ns[p + "_password_" + node_global_max] = Base64.encode($.trim($("#ss_node_table_password").val()));
		ns[p + "_type_" + node_global_max] = "1";
	} else if (flag == 'gameV2') {
		for (var i = 0; i < params3.length; i++) {
			ns[p + "_" + params3[i] + "_" + node_global_max] = $.trim($('#ss_node_table' + "_" + params3[i]).val());
		}
		ns[p + "_password_" + node_global_max] = Base64.encode($.trim($("#ss_node_table_password").val()));
		ns[p + "_type_" + node_global_max] = "2";
	} else if (flag == 'naive') {
		for (var i = 0; i < params5.length; i++) {
			ns[p + "_" + params5[i] + "_" + node_global_max] = $.trim($('#ss_node_table' + "_" + params5[i]).val());
		}
		ns[p + "_password_" + node_global_max] = Base64.encode($.trim($("#ss_node_table_password").val()));
		ns[p + "_type_" + node_global_max] = "5";		
	} else if (flag == 'v2ray') {
		//normal value
		for (var i = 0; i < params4_1.length; i++) {
			ns[p + "_" + params4_1[i] + "_" + node_global_max] = $.trim($('#ss_node_table' + "_" + params4_1[i]).val());
		}
		//checkbox value
		for (var i = 0; i < params4_2.length; i++) {
			ns[p + "_" + params4_2[i] + "_" + node_global_max] = E(("ss_node_table_" + params4_2[i])).checked ? '1' : '0';
		}
		//获取trojan
		/**if(ns[p+"_"+"v2ray_protocol"+ "_" + node_global_max]=="trojan"){
			if(ns[p+"_"+"v2ray_network_security"+ "_" + node_global_max]=="none"){
				alert("trojan必须填写[底层传输安全],如不清楚,默认请选择tls")
				return false
			}
		}**/
		//base64 value
		if($("#ss_node_table_v2ray_json").val()){
			if(E('ss_node_table_v2ray_json').value.indexOf("vmess://") != -1){
				var vmess_node = JSON.parse(Base64.decode(E('ss_node_table_v2ray_json').value.split("//")[1]));
				console.log("use v2ray vmess://")
				console.log(vmess_node)
				ns[p + "_server_" + node_global_max] = vmess_node.add;
				ns[p + "_port_" + node_global_max] = vmess_node.port;
				ns[p + "_v2ray_uuid_" + node_global_max] = vmess_node.id;
				ns[p + "_v2ray_security_" + node_global_max] = "auto";
				ns[p + "_v2ray_alterid_" + node_global_max] = vmess_node.aid;
				ns[p + "_v2ray_protocol_" + node_global_max] = "vmess";
				ns[p + "_v2ray_network_" + node_global_max] = vmess_node.net;
				if(vmess_node.net == "tcp"){
					ns[p + "_v2ray_headtype_tcp_" + node_global_max] = vmess_node.type;
				}else if(vmess_node.net == "kcp"){
					ns[p + "_v2ray_headtype_kcp_" + node_global_max] = vmess_node.type;
				}
				ns[p + "_v2ray_network_host_" + node_global_max] = vmess_node.host;
				ns[p + "_v2ray_network_tlshost_" + node_global_max] = vmess_node.tlshost;
				ns[p + "_v2ray_network_flow_" + node_global_max] = vmess_node.flow;
				ns[p + "_v2ray_network_path_" + node_global_max] = vmess_node.path;
				if(vmess_node.tls == "tls"){
					ns[p + "_v2ray_network_security_" + node_global_max] = "tls";
				}else{
					ns[p + "_v2ray_network_security_" + node_global_max] = "none";
				}	
				ns[p + "_allowinsecure_" + node_global_max] = 1;
				ns[p + "_v2ray_mux_enable_" + node_global_max] = 1;
				ns[p + "_v2ray_mux_concurrency_" + node_global_max] = 8;
				ns[p + "_v2ray_use_json_" + node_global_max] = 0;
				ns[p + "_v2ray_json_" + node_global_max] = "";
			}else{
				if (E("ss_node_table_v2ray_use_json").checked == true){
					if(isJSON(E('ss_node_table_v2ray_json').value)){
						if(E('ss_node_table_v2ray_json').value.indexOf("outbound") != -1){
							ns[p + "_v2ray_json_" + node_global_max] = Base64.encode(pack_js(E('ss_node_table_v2ray_json').value));
						}else{
							alert("错误！你的json配置文件有误！\n正确格式请参考:https://www.v2ray.com/chapter_02/01_overview.html");
							return false;
						}
					}else{
						alert("错误！检测到你输入的v2ray配置不是标准json格式！");
						return false;
					}
				}
			}
		}
		ns[p + "_type_" + node_global_max] = "3";
	}else if(flag == 'trojan') {
        for (var i = 0; i < paramsTrojan.length; i++) {
            ns[p + "_" + paramsTrojan[i] + "_" + node_global_max] = $('#ss_node_table' + "_" + paramsTrojan[i]).val();
        }
		//checkbox value
		for (var i = 1; i < params4_2.length; i++) {
			ns[p + "_" + params4_2[i] + "_" + node_global_max] = E(("ss_node_table_" + params4_2[i])).checked ? '1' : '0';
		}
        ns[p + "_password_" + node_global_max] = Base64.encode($("#ss_node_table_password").val());
        ns[p + "_type_" + node_global_max] = "4";
    }
	$.ajax({
		url: '/applydb.cgi?p=ssconf_basic',
		contentType: "application/x-www-form-urlencoded",
		dataType: 'text',
		data: $.param(ns),
		success: function(response) {
			refresh_table();
			//尝试将table拉动到最下方
			E("ss_node_table_server").value = "";
			if ((E("continue_add_box").checked) == false) { //不选择连续添加的时候，清空其他数据
				E("ss_node_table_name").value = "";
				E("ss_node_table_port").value = "";
				E("ss_node_table_password").value = "";
				E("ss_node_table_method").value = "none";
				E("ss_node_table_mode").value = "1";
				E("ss_node_table_ss_v2ray_plugin").value = "0"
				E("ss_node_table_ss_v2ray_plugin_opts").value = "";
				E("ss_node_table_rss_protocol").value = "origin";
				E("ss_node_table_naive_protocol").value = "https";
				E("ss_node_table_naive_user").value = "";
				E("ss_node_table_rss_protocol_param").value = "";
				E("ss_node_table_rss_obfs").value = "plain";
				E("ss_node_table_rss_obfs_param").value = "";
				E("ss_node_table_koolgame_udp").value = "0";
				E("ss_node_table_v2ray_uuid").value = "";
				E("ss_node_table_v2ray_alterid").value = "";
				E("ss_node_table_v2ray_protocol").value = "vmess";
				E("ss_node_table_v2ray_json").value = "";	
				E("ss_node_table_trojan_binary").value = "Trojan";		
				E("ss_node_table_trojan_network").value = "0";		
				E("ss_node_table_trojan_sni").value = "";	
				E("ss_node_table_v2ray_network_tlshost").value = ""; 
				E("ss_node_table_v2ray_network_flow").value = "";
				E("ss_node_table_allowinsecure").value = "0";
				E("ss_node_table_fragment").value = "0";
				E("ss_node_table_v2ray_mux_enable").value = "0";
				E("ss_node_table_fingerprint").value = "";	
				E("ss_node_table_xray_publicKey").value = "";
				E("ss_node_table_xray_shortId").value = "";				
				cancel_add_rule();
			}
		}
	});
}

function refresh_table() {
	$.ajax({
		url: '/dbconf?p=ss',
		dataType: 'html',
		error: function(xhr) {},
		success: function(response) {
			$.globalEval(response);
			$("#ss_node_list_table_main").find("tr:gt(0)").remove();
			$('#ss_node_list_table_main tr:last').after(refresh_html());
		}
	});
}

function refresh_html() {
	browser_compatibility1();
	confs = getAllConfigs();
	var n = 0;
	for (var i in confs) {
		n++;
	} //获取节点的数目
	if (n > 13.5) { //当节点数目大于13个的时候，显示为overflow，节点可以滚动
		$("#ss_node_list_table_th")[0].style.top = '';
		$("#ss_node_list_table_td")[0].style.top = '';
		$("#ss_node_list_table_btn")[0].style.top = '';
		$("#ss_node_list_table_th")[0].style.display = '';
		$("#ss_node_list_table_th")[0].style.width = '748px';
		$("#ss_node_list_table_th")[0].style.position = '';
		$("#ss_node_list_table_td")[0].style.width = '749px';
		$("#ss_node_list_table_td")[0].style.height = '520px';
		$("#ss_node_list_table_td")[0].style.overflow = 'hidden';
		$("#ss_node_list_table_td")[0].style.position = '';
		$("#hide_when_folw")[0].style.display = 'none'
		$("#ss_node_list_table_main")[0].style["width"] = '748px';
		$("#ss_node_list_table_main")[0].style["height"] = '520px';
		$("#ss_node_list_table_main")[0].style["overflow-x"] = 'hidden';
		$("#ss_node_list_table_main")[0].style["overflow-y"] = 'scroll';
		$("#ss_node_list_table_main")[0].style["padding-right"] = '30px';
		$("#ss_node_list_table_btn")[0].style.width = '748px';
		$("#ss_node_list_table_btn")[0].style.position = '';
		$("#ss_node_list_table_btn")[0].style.margin = '5px 0px 0px 0px';
	} else { //当节点数量小于等于13个的是否，显示为absolute，节点不可滚动
		$("#ss_node_list_table_th")[0].style.top = '';
		$("#ss_node_list_table_td")[0].style.top = '';
		$("#ss_node_list_table_btn")[0].style.top = '';
		$("#ss_node_list_table_th")[0].style.display = 'none';
		$("#ss_node_list_table_td")[0].style.width = '748px';
		$("#ss_node_list_table_td")[0].style.height = '';
		$("#ss_node_list_table_td")[0].style.overflow = '';
		$("#ss_node_list_table_td")[0].style.position = '';
		$("#ss_node_list_table_main")[0].style["height"] = '';
		$("#ss_node_list_table_main")[0].style["overflow-x"] = '';
		$("#ss_node_list_table_main")[0].style["overflow-y"] = '';
		$("#ss_node_list_table_main")[0].style["padding-right"] = '';
		$("#hide_when_folw")[0].style.display = ''
		$("#ss_node_list_table_btn")[0].style.position = '';
		$("#ss_node_list_table_btn")[0].style.margin = '5px 0px 0px 0px';
	}
	var html = '';
	for (var field in confs) {
		var c = confs[field];
		html = html + '<tr style="height:40px">';
		if (c["mode"] == 1) {
			html = html + '<td style="width:40px"><img style="margin:-4px -4px -4px -4px;" src="/res/gfw.png"/></td>';
		} else if (c["mode"] == 2) {
			html = html + '<td style="width:40px"><img style="margin:-4px -4px -4px -4px;" src="/res/chn.png"/></td>';
		} else if (c["mode"] == 3) {
			html = html + '<td style="width:40px"><img style="margin:-4px -4px -4px -4px;" src="/res/game.png"/></td>';
		} else if (c["mode"] == 4) {
			html = html + '<td style="width:40px"><img style="margin:-4px -4px -4px -4px;" src="/res/gameV2.png"/></td>';
		} else if (c["mode"] == 5) {
			html = html + '<td style="width:40px"><img style="margin:-4px -4px -4px -4px;" src="/res/all.png"/></td>';
		} else {
			html = html + '<td style="width:40px"></td>';
		}
		html = html + '<td style="width:150px;text-align:left;" id="ss_node_name_' + c["node"] + '">' + c["name"] + '</td>';
		html = html + '<td style="width:120px;text-align:left;" id="ss_node_server_' + c["node"] + '"> ' + c["server"] + '</td>';
		html = html + '<td id="ss_node_port_' + c["node"] + '" style="width:61px;">' + c["port"] + '</td>';
		if (c["mode"] == 4) {
			html = html + '<td id="ss_node_webtest_' + c["node"] + '" style="width:86px;color:#FFCC33;text-align:center;">不支持</td>';
		} else {
			html = html + '<td id="ss_node_webtest_' + c["node"] + '" style="width:86px;text-align:center;">' + c["webtest"] + '</td>';
		}
		html = html + '<td style="width:33px;">'
		html = html + '<input style="margin:-2px 0px -4px -2px;" id="dd_node_' + c["node"] + '" class="edit_btn" type="button" onclick="return edit_conf_table(this);" value="">'
		html = html + '</td>';
		html = html + '<td style="width:33px;">'
		if ((c["node"]) == db_ss["ssconf_basic_node"] && db_ss["ss_basic_enable"] =="1") {
			html = html + '<input style="margin:-2px 0px -4px -2px;" id="td_node_' + c["node"] + '" class="remove_btn" type="button" onclick="remove_running_node(this);" value="">'
		} else {
			html = html + '<input style="margin:-2px 0px -4px -2px;" id="td_node_' + c["node"] + '" class="remove_btn" type="button" onclick="return remove_conf_table(this);" value="">'
		}
		html = html + '</td>';
		html = html + '<td style="width:65px;">'
		if ((c["node"]) == db_ss["ssconf_basic_node"] && db_ss["ss_basic_enable"] =="1") {
			if (c["rss_protocol"]) {
				html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #f072a5;width:66px;cursor:pointer;" onclick="apply_Running_node(this);" value="运行中">'
			} else if (c["naive_protocol"]) {//判断节点为naive
				html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #a4f072;width:66px;cursor:pointer;" onclick="apply_Running_node(this);" value="运行中">'
			} else if (c["koolgame_udp"] == "0" || c["koolgame_udp"] == "1") {
					html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #33CC33;width:66px;cursor:pointer;" onclick="apply_Running_node(this);" value="运行中">'
			} else if(c["v2ray_protocol"] || c["v2ray_use_json"] == "0" || c["v2ray_use_json"] == "1") { //判断节点为v2ray
					if(c["v2ray_protocol"] == "vmess") {	//vmess
						html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #9900CC;width:66px;cursor:pointer;" onclick="apply_Running_node(this);" value="运行中">'
						}else if(c["v2ray_protocol"] == "vless") {	//vless
						html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #3c45f6;width:66px;cursor:pointer;" onclick="apply_Running_node(this);" value="运行中">'
						} else {
						html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #9900CC;width:66px;cursor:pointer;" onclick="apply_Running_node(this);" value="运行中">'
						}
			} else if (c["trojan_binary"]) {  // Trojan 节点
				if (c["trojan_binary"] == "Trojan") { //trojan
					html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #e2c628;width:66px;cursor:pointer;" onclick="apply_Running_node(this);" value="运行中">'
				} else if (c["trojan_binary"] == "Trojan-Go") { //trojan go
					html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #FF5733;width:66px;cursor:pointer;" onclick="apply_Running_node(this);" value="运行中">'
				} else if (c["trojan_binary"] == "Hysteria2") { // Hysteria2
					html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #FFBC00;width:66px;cursor:pointer;" onclick="apply_Running_node(this);" value="运行中">'
				} else if (c["trojan_binary"] == "AnyTLS") { // AnyTLS
					html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #8dbf8b;width:66px;cursor:pointer;" onclick="apply_Running_node(this);" value="运行中">'
				}
			} else { //其余节点为SS
						html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #00CCFF;width:66px;cursor:pointer;" onclick="apply_Running_node(this);" value="运行中">'
				  }
		} else {
			if (c["rss_protocol"]) {
				html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #f072a5;width:66px;cursor:pointer;" onclick="apply_this_ss_node(this);" value="应用">'
			} else if (c["naive_protocol"]) {//判断节点为naive
					html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #a4f072;width:66px;cursor:pointer;" onclick="apply_this_ss_node(this);" value="应用">'	
			} else if (c["koolgame_udp"] == "0" || c["koolgame_udp"] == "1") {
					html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #33CC33;width:66px;cursor:pointer;" onclick="apply_this_ss_node(this);" value="应用">'
			} else if(c["v2ray_protocol"] || c["v2ray_use_json"] == "0" || c["v2ray_use_json"] == "1") { //判断节点为v2ray
						if(c["v2ray_protocol"] == "vmess") {	//vmess
						html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #9900CC;width:66px;cursor:pointer;" onclick="apply_this_ss_node(this);" value="应用">'
						}else if(c["v2ray_protocol"] == "vless")  {	//vless
						html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #3c45f6;width:66px;cursor:pointer;" onclick="apply_this_ss_node(this);" value="应用">'
						} else {
						html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #9900CC;width:66px;cursor:pointer;" onclick="apply_this_ss_node(this);" value="应用">'
						}
			} else if(c["trojan_binary"]){  // Trojan 节点
					if(c["trojan_binary"] == "Trojan") { //trojan
						html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #e2c628;width:66px;cursor:pointer;" onclick="apply_this_ss_node(this);" value="应用">'
					} else if(c["trojan_binary"] == "Trojan-Go") { //trojan go
						html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #FF5733;width:66px;cursor:pointer;" onclick="apply_this_ss_node(this);" value="应用">'
					} else if(c["trojan_binary"] == "Hysteria2") { // Hysteria2
						html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #FFBC00;width:66px;cursor:pointer;" onclick="apply_this_ss_node(this);" value="应用">'
					} else if(c["trojan_binary"] == "AnyTLS") { // AnyTLS
						html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #8dbf8b;width:66px;cursor:pointer;" onclick="apply_this_ss_node(this);" value="应用">'
					}
			} else { // 其余为SS
						html = html + '<input id="apply_ss_node_' + c["node"] + '" type="button" class="ss_btn" style="color: #00CCFF;width:66px;cursor:pointer;" onclick="apply_this_ss_node(this);" value="应用">'
					}
		}
		html = html + '</td>';
		html = html + '</tr>';
	}
	return html;
}
var node_nu;

function apply_Running_node() {
	alert("这个节点正在运行，你要干嘛？")
	return false;
}

function remove_running_node() {
	alert("这个节点正在运行，无法删除！")
	return false;
}

function apply_this_ss_node(s) { //应用此节点
	$('.show-btn1').addClass('active');
	$('.show-btn1_1').removeClass('active');
	cancel_add_rule(); //隐藏节点编辑面板
	E("tablets").style.display = "";
	E("tablet_1").style.display = "";
	E("apply_button").style.display = "";
	E("ss_node_list_table_th").style.display = "none";
	E("ss_node_list_table_td").style.display = "none";
	E("ss_node_list_table_btn").style.display = "none";
	confs = getAllConfigs();
	var option = $("#ssconf_basic_node");
	option.find('option').remove().end();
	for (var field in confs) {
		var c = confs[field];
		if (c.rss_protocol) {
			option.append($("<option>", {
				value: field,
				text: "【SSR】" + c.name
			}));
		} else if (c.koolgame_udp == "0" || c.koolgame_udp == "1") { //判断节点为 koolgame
				option.append($("<option>", {
					value: field,
					text: "【koolgame】" + c.name
				}));
		} else if (c.naive_protocol) { //判断节点为 naive
				option.append($("<option>", {
					value: field,
					text: "【Naive】" + c.name
				}));		
		} else if(c["v2ray_protocol"] || c["v2ray_use_json"] == "0" || c["v2ray_use_json"] == "1") { //判断节点为v2ray
					option.append($("<option>", {
						value: field,
						text: "【V2Ray】" + c.name
					}));
		} else if (c["trojan_binary"]){  // Trojan 节点
                    option.append($("<option>", {
                        value: field,
                        text: "【" + c.trojan_binary + "】" + c.name
                    }));
				} else { //判断节点为SS 
					option.append($("<option>", {
						value: field,
						text: "【SS】" + c.name
					}));
		} 
	}
	
	if (node_global_max > 0) {
		var node_sel = "1";
		if (typeof db_ss.ssconf_basic_node != "undefined") {
			node_sel = db_ss.ssconf_basic_node;
		}
		option.val(node_sel);
	}

	checkTime = 2001; //停止节点页面刷新
	//ss_node_info_return();
	var node = $(s).attr("id");
	var nodes = node.split("_");
	node = nodes[nodes.length - 1];
	var node_sel = node;
	var obj = ssconf_node2obj(node_sel);
	E("ssconf_basic_node").value = node;
	update_ss_ui(obj);
	verifyFields();
	setTimeout("save();", 500);
}

function remove_conf_table(o) { //删除节点功能
	var id = $(o).attr("id");
	var ids = id.split("_");
	var p = "ssconf_basic";
	id = ids[ids.length - 1];
	var ns = {};
	var params = ["name", "server", "server_ip", "mode", "port", "password", "method", "rss_protocol", "naive_protocol", "naive_user", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "ss_v2ray_plugin", "ss_v2ray_plugin_opts", "koolgame_udp", "ping", "webtest", "use_lb", "lbmode", "weight", "group", "v2ray_uuid", "v2ray_alterid", "v2ray_protocol", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp","v2ray_serviceName","v2ray_network_path", "v2ray_network_host", "v2ray_network_tlshost","v2ray_network_flow", "v2ray_network_security", "v2ray_mux_concurrency", "v2ray_json", "v2ray_use_json", "v2ray_mux_enable","allowinsecure","fragment", "type","trojan_sni","trojan_binary", "trojan_network","fingerprint","xray_publicKey", "xray_shortId"];
	for (var i = 0; i < params.length; i++) {
		ns[p + "_" + params[i] + "_" + id] = "";
	}
	$.ajax({
		url: '/applydb.cgi?use_rm=1&p=ssconf_basic',
		contentType: "application/x-www-form-urlencoded",
		dataType: 'text',
		data: $.param(ns),
		error: function(xhr) {
			console.log("error in posting config of table");
		},
		success: function(response) {
			refresh_table();
		}
	});
}

function edit_conf_table(o) { //编辑节点功能，显示编辑面板
	var id = $(o).attr("id");
	var ids = id.split("_");
	var p = "ssconf_basic";
	confs = getAllConfigs();
	id = ids[ids.length - 1];
	var c = confs[id];
	var params1_base64 = ["password"];
	var params1_check = ["v2ray_use_json", "v2ray_mux_enable","allowinsecure","fragment"];
	var params1_input = ["name", "server", "mode", "port", "method", "ss_v2ray_plugin", "ss_v2ray_plugin_opts", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param", "koolgame_udp", "v2ray_uuid", "v2ray_alterid", "v2ray_protocol", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp","v2ray_serviceName", "v2ray_network_path", "v2ray_network_host", "v2ray_network_tlshost", "v2ray_network_flow", "v2ray_network_security", "v2ray_mux_concurrency", "trojan_sni", "fingerprint", "naive_protocol", "naive_user","xray_publicKey", "xray_shortId"];
	if(c["v2ray_json"]){
		E("ss_node_table_v2ray_json").value = do_js_beautify(Base64.decode(c["v2ray_json"]));
	}
	for (var i = 0; i < params1_base64.length; i++) {
		if(c[params1_base64[i]]){
			E("ss_node_table_" + params1_base64[i]).value = Base64.decode(c[params1_base64[i]]);
		}
	}
// First reset all checkboxes to unchecked
for (var i = 0; i < params1_check.length; i++) {
    var checkbox = E("ss_node_table_" + params1_check[i]);
    if (checkbox) {
        checkbox.checked = false;  // Reset to unchecked
    }
}

// Then set checkbox states based on values
for (var i = 0; i < params1_check.length; i++) {
    if (c[params1_check[i]]) {
        var checkbox = E("ss_node_table_" + params1_check[i]);
        if (checkbox) {
            checkbox.checked = c[params1_check[i]] == "1";
        }
    }
}
// First clear all inputs
for (var i = 0; i < params1_input.length; i++) {
    E("ss_node_table_" + params1_input[i]).value = "";
}

// Then set values from data
for (var i = 0; i < params1_input.length; i++) {
    if(c[params1_input[i]]){
        E("ss_node_table_" + params1_input[i]).value = c[params1_input[i]];
    }
}
	//编辑时恢复文字
	protocol_change_off(c["v2ray_protocol"])
	trojan_change_off(c["trojan_binary"])
	network_change_off(c["trojan_network"])
	flow_change_off(c["v2ray_network"])
	reality_change_off(c["v2ray_network_security"])
	E("cancelBtn").style.display = "";
	E("add_node").style.display = "none";
	E("edit_node").style.display = "";
	E("continue_add").style.display = "none";

    E("ssTitle").style.display = "none";
    E("ssrTitle").style.display = "none";
    E("gamev2Title").style.display = "none";
    E("v2rayTitle").style.display = "none";
    E("trojanTitle").style.display = "none";
    E("naiveTitle").style.display = "none";

	if (c["rss_protocol"]) { //判断节点为SSR
		$("#vpnc_settings").fadeIn(200);
		E("ssrTitle").style.display = "";
		$("#ssrTitle").html("编辑SSR账号");
		tabclickhandler(1);
	} else if (c["naive_protocol"]) { //判断节点为naive
			$("#vpnc_settings").fadeIn(200);
			E("naiveTitle").style.display = "";
			$("#naiveTitle").html("编辑Naive账号");
			tabclickhandler(5);
	} else if (c["koolgame_udp"] == "0" || c["koolgame_udp"] == "1") { //判断节点为koolgame
			$("#vpnc_settings").fadeIn(200);
			E("gamev2Title").style.display = "";
			$("#gamev2Title").html("编辑koolgame账号");
			tabclickhandler(2);			
	} else if(c["v2ray_protocol"] || c["v2ray_use_json"] == "0" || c["v2ray_use_json"] == "1") { //判断节点为v2ray
				$("#vpnc_settings").fadeIn(200);
				E("v2rayTitle").style.display = "";
				$("#v2rayTitle").html("编辑v2ray账号");
				tabclickhandler(3);
	} else if(c["trojan_binary"] == "Trojan" || c["trojan_binary"] == "Hysteria2" || c["trojan_binary"] == "Trojan-Go" || c["trojan_binary"] == "AnyTLS" ) { // Trojan 节点
                $("#vpnc_settings").fadeIn(200);
                E("trojanTitle").style.display = "";
                $("#trojanTitle").html("编辑Trojan账号");
                tabclickhandler(4);
	} else  { //判断节点为SS 
				$("#vpnc_settings").fadeIn(200);
                E("ssTitle").style.display = "";
				$("#ssTitle").html("编辑SS账号");
				tabclickhandler(0);
	}

	myid = id;
}

function edit_ss_node_conf(flag) { //编辑节点功能，数据重写
	var ns = {};
	var p = "ssconf_basic";
	var params1 = ["name", "server", "mode", "port", "method", "ss_v2ray_plugin", "ss_v2ray_plugin_opts"]; //for ss
	var params2 = ["name", "server", "mode", "port", "method", "rss_protocol", "rss_protocol_param", "rss_obfs", "rss_obfs_param"]; //for ssr
	var params3 = ["name", "server", "mode", "port", "method", "koolgame_udp"]; //for koolgame
	var params4_1 = ["mode", "name", "server", "port", "v2ray_uuid", "v2ray_alterid", "v2ray_protocol", "v2ray_security", "v2ray_network", "v2ray_headtype_tcp", "v2ray_headtype_kcp", "v2ray_serviceName","v2ray_network_path", "v2ray_network_host", "v2ray_network_tlshost", "v2ray_network_flow", "v2ray_network_security", "v2ray_mux_concurrency","fingerprint","xray_publicKey", "xray_shortId"]; //for v2ray
	var params4_2 = ["v2ray_use_json", "v2ray_mux_enable","allowinsecure","fragment"]; //for v2ray
	var paramsTrojan = ["name", "server", "mode", "port","trojan_binary", "trojan_network", "v2ray_network_path", "v2ray_network_host", "trojan_sni", "fingerprint", "allowinsecure","fragment", "v2ray_mux_concurrency"]; //for trojan
	var params5 = ["name", "server", "mode", "port", "naive_protocol", "naive_user"]; //for naive
	if (flag == 'shadowsocks') {
		for (var i = 0; i < params1.length; i++) {
			ns[p + "_" + params1[i] + "_" + myid] = $('#ss_node_table' + "_" + params1[i]).val();
		}
		ns[p + "_password_" + myid] = Base64.encode($("#ss_node_table_password").val());
		ns[p + "_type_" + myid] = "0";
	} else if (flag == 'shadowsocksR') {
		for (var i = 0; i < params2.length; i++) {
			ns[p + "_" + params2[i] + "_" + myid] = $('#ss_node_table' + "_" + params2[i]).val();
		}
		ns[p + "_password_" + myid] = Base64.encode($("#ss_node_table_password").val());
		ns[p + "_type_" + myid] = "1";
	} else if (flag == 'gameV2') {
		for (var i = 0; i < params3.length; i++) {
			ns[p + "_" + params3[i] + "_" + myid] = $('#ss_node_table' + "_" + params3[i]).val();
		}
		ns[p + "_password_" + myid] = Base64.encode($("#ss_node_table_password").val());
		ns[p + "_type_" + myid] = "2";
	} else if (flag == 'naive') {
		for (var i = 0; i < params5.length; i++) {
			ns[p + "_" + params5[i] + "_" + myid] = $('#ss_node_table' + "_" + params5[i]).val();
		}
		ns[p + "_password_" + myid] = Base64.encode($("#ss_node_table_password").val());
		ns[p + "_type_" + myid] = "5";
	} else if (flag == 'v2ray') {
		//normal value
		for (var i = 0; i < params4_1.length; i++) {
			ns[p + "_" + params4_1[i] + "_" + myid] = $('#ss_node_table' + "_" + params4_1[i]).val();
		}
		//checkbox value
		for (var i = 0; i < params4_2.length; i++) {
			ns[p + "_" + params4_2[i] + "_" + myid] = E(("ss_node_table_" + params4_2[i])).checked ? '1' : '0';
		}
		//VMESS
		//if($("#ss_node_table_v2ray_json").val()){
		//	ns[p + "_v2ray_json_" + myid] = Base64.encode($("#ss_node_table_v2ray_json").val());
		//}
		if($("#ss_node_table_v2ray_json").val()){
			if(E('ss_node_table_v2ray_json').value.indexOf("vmess://") != -1){
				var vmess_node = JSON.parse(Base64.decode(E('ss_node_table_v2ray_json').value.split("//")[1]));
				console.log("use v2ray vmess://");
				console.log(vmess_node);
				ns["ssconf_basic_server_" + myid] = vmess_node.add;
				ns["ssconf_basic_port_" + myid] = vmess_node.port;
				ns["ssconf_basic_v2ray_uuid_" + myid] = vmess_node.id;
				ns["ssconf_basic_v2ray_security_" + myid] = "auto";
				ns["ssconf_basic_v2ray_alterid_" + myid] = vmess_node.aid;
				ns["ssconf_basic_v2ray_protocol_" + myid] = "vmess";
				ns["ssconf_basic_v2ray_network_" + myid] = vmess_node.net;
				if(vmess_node.net == "tcp"){
					ns["ssconf_basic_v2ray_headtype_tcp_" + myid] = vmess_node.type;
				}else if(vmess_node.net == "kcp"){
					ns["ssconf_basic_v2ray_headtype_kcp_" + myid] = vmess_node.type;
				}
				ns["ssconf_basic_v2ray_network_host_" + myid] = vmess_node.host;
				ns["ssconf_basic_v2ray_network_tlshost_" + myid] = vmess_node.tlshost;
				ns["ssconf_basic_v2ray_network_flow_" + myid] = vmess_node.flow;
				ns["ssconf_basic_v2ray_network_path_" + myid] = vmess_node.path;
				if(vmess_node.tls == "tls"){
					ns["ssconf_basic_v2ray_network_security_" + myid] = "tls";
				}else{
					ns["ssconf_basic_v2ray_network_security_" + myid] = "none";
				}
				ns["ssconf_basic_allowinsecure_" + myid] = 1;
				ns["ssconf_basic_v2ray_mux_enable_" + myid] = 1;
				ns["ssconf_basic_v2ray_mux_concurrency_" + myid] = 8;
				ns["ssconf_basic_v2ray_use_json_" + myid] = 0;
				ns["ssconf_basic_v2ray_json_" + myid] = "";
			}else{
				console.log("use v2ray json");
				ns["ssconf_basic_v2ray_json_" + myid] = Base64.encode(pack_js(E('ss_node_table_v2ray_json').value));
			}
		}
		ns[p + "_type_" + myid] = "3";
	}else if (flag == 'trojan') {
		for (var i = 0; i < paramsTrojan.length; i++) {
			ns[p + "_" + paramsTrojan[i] + "_" + myid] = $('#ss_node_table' + "_" + paramsTrojan[i]).val();
		}
		//checkbox value
		for (var i = 1; i < params4_2.length; i++) {
			ns[p + "_" + params4_2[i] + "_" + myid] = E(("ss_node_table_" + params4_2[i])).checked ? '1' : '0';
		}
		ns[p + "_password_" + myid] = Base64.encode($("#ss_node_table_password").val());
	    ns[p + "_type_" + myid] = "4";
	} 
	$.ajax({
		url: '/applydb.cgi?p=ssconf_basic',
		contentType: "application/x-www-form-urlencoded",
		dataType: 'text',
		data: $.param(ns),
		error: function(xhr) {
			console.log("error in posting config of table");
		},
		success: function(response) {
			refresh_table();
			E("ss_node_table_name").value = "";
			E("ss_node_table_port").value = "";
			E("ss_node_table_server").value = "";
			E("ss_node_table_password").value = "";
			E("ss_node_table_method").value = "none";
			E("ss_node_table_mode").value = "1";
			E("ss_node_table_ss_v2ray_plugin").value = "0"
			E("ss_node_table_ss_v2ray_plugin_opts").value = "";
			E("ss_node_table_rss_protocol").value = "origin";
			E("ss_node_table_naive_protocol").value = "https";
			E("ss_node_table_naive_user").value = "";
			E("ss_node_table_rss_protocol_param").value = "";
			E("ss_node_table_rss_obfs").value = "plain";
			E("ss_node_table_rss_obfs_param").value = "";
			E("ss_node_table_koolgame_udp").value = "0";
			E("ss_node_table_v2ray_uuid").value = "";
			E("ss_node_table_v2ray_alterid").value = "";
			E("ss_node_table_v2ray_protocol").value = "vmess";
			E("ss_node_table_v2ray_json").value = "";
			E("ss_node_table_trojan_binary").value = "Trojan";		
			E("ss_node_table_trojan_network").value = "0";	
			E("ss_node_table_trojan_sni").value = "";
			E("ss_node_table_fingerprint").value = "";
			E("ss_node_table_v2ray_network_tlshost").value = "";
			E("ss_node_table_v2ray_network_flow").value = "";				
			E("ss_node_table_allowinsecure").value = "0";
			E("ss_node_table_fragment").value = "0";
			E("ss_node_table_v2ray_mux_enable").value = "0";
			E("ss_node_table_xray_publicKey").value = "";
			E("ss_node_table_xray_shortId").value = "";		
		}
	});
	updateSs_node_listView();
	$("#vpnc_settings").fadeOut(200);
}


function download_SS_node() {
	location.href = 'ss_conf_backup.txt';
}

function upload_ss_backup() {
	if (E('ss_file').value == "") return false;
	global_ss_node_refresh = false;
	E('ss_file_info').style.display = "none";
	E('loadingicon').style.display = "block";
	document.form.enctype = "multipart/form-data";
	document.form.encoding = "multipart/form-data";
	document.form.action = "/ssupload.cgi?a=/tmp/ss_conf_backup.txt";
	document.form.submit();
}


function upload_ok(isok) {
	var info = E('ss_file_info');
	if (isok == 1) {
		info.innerHTML = "上传完成";
		setTimeout("restore_ss_conf();", 1200);
	} else {
		info.innerHTML = "上传失败";
	}
	info.style.display = "block";
	E('loadingicon').style.display = "none";
}

function restore_ss_conf() {
	checkTime = 2001; //停止可能在进行的刷新
	db_ss["ss_basic_action"] = "9";
	var dbus = {};
	dbus["SystemCmd"] = "ss_conf_restore.sh";
	dbus["action_mode"] = " Refresh ";
	dbus["current_page"] = "Main_Ss_Content.asp";
	push_data(dbus);
}

function remove_SS_node() {
	checkTime = 2001; //停止可能在进行的刷新
	db_ss["ss_basic_action"] = "10";
	var dbus = {};
	dbus["SystemCmd"] = "ss_conf_remove.sh";
	dbus["action_mode"] = " Refresh ";
	dbus["current_page"] = "Main_Ss_Content.asp";
	push_data(dbus);
}

function web_test() {
	checkTime = 2001; //停止可能在进行的刷新
	var dbus = {};
	dbus["SystemCmd"] = "ss_webtest.sh";
	dbus["action_mode"] = " Refresh ";
	dbus["current_page"] = "Main_Ss_Content.asp";
	dbus["ssconf_basic_test_node"] = E("ssconf_basic_test_node").value;
	dbus["ssconf_basic_test_domain"] = E("ssconf_basic_test_domain").value;
	$.ajax({
		type: "POST",
		url: '/applydb.cgi?p=ss',
		contentType: "application/x-www-form-urlencoded",
		dataType: 'text',
		data: $.param(dbus),
		success: function(response) {
			checkTime = 0;
			refresh_ss_node_list_webtest();
			alert("请等待片刻，测试结果将自动显示在对应节点列表!");
		}
	});
}

function remove_test() {
	checkTime = 2001; //停止可能在进行的刷新
	var dbus = {};
	dbus["SystemCmd"] = "ss_webtest_remove.sh";
	dbus["action_mode"] = " Refresh ";
	dbus["current_page"] = "Main_Ss_Content.asp";
	$.ajax({
		type: "POST",
		url: '/applydb.cgi?p=ss',
		contentType: "application/x-www-form-urlencoded",
		dataType: 'text',
		data: $.param(dbus),
		success: function(response) {
			alert("请等待片刻，如果结果未清空，请手动刷新页面!");
			setTimeout("refresh_table()", 1000);
		}
	});
}

var checkTime = 0;

function refresh_ss_node_list_webtest() {
	if (checkTime < 200) {
		checkTime++;
		refresh_table();
		setTimeout("refresh_ss_node_list_webtest()", 3000);
	}
	if (checkTime > 2) {
		confs = getAllConfigs();
		var n = 0;
		for (var i in confs) {
			n++;
		}
		var webtest_flag = 0;
		for (var field in confs) {
			var c = confs[field].webtest;
			if (c != "") {
				webtest_flag++;
			}
		}
		if (webtest_flag == n) {
			checkTime = 2001;
		}
	}
}

function updatelist(action) {
	db_ss["ss_basic_action"] = "8";
	var dbus = {};
	dbus["SystemCmd"] = "ss_rule_update.sh";
	dbus["action_mode"] = " Refresh ";
	dbus["current_page"] = "Main_Ss_Content.asp";
	dbus["ss_basic_update_action"] = action;
	dbus["ss_basic_rule_update"] = E("ss_basic_rule_update").value;
	dbus["ss_basic_rule_update_time"] = E("ss_basic_rule_update_time").value;
	dbus["ss_basic_gfwlist_update"] = E("ss_basic_gfwlist_update").checked ? '1' : '0';
	dbus["ss_basic_chnroute_update"] = E("ss_basic_chnroute_update").checked ? '1' : '0';
	dbus["ss_basic_cdn_update"] = E("ss_basic_cdn_update").checked ? '1' : '0';
	push_data(dbus);
}

function version_show() {
	$.ajax({
		url: 'https://raw.githubusercontent.com/guijianchou/v2ray_bin_lite/main/380_armv5_packge/config.json.js',
		type: 'GET',
		dataType: 'json',
		success: function(res) {
			if (typeof(res["version"]) != "undefined" && res["version"].length > 0) {
				if (res["version"] == db_ss["ss_basic_version_local"]) {
					$("#ss_version_show").html("<a class='hintstyle' href='javascript:void(12);' onclick='openssHint(12)'><i>当前版本：" + db_ss['ss_basic_version_local'] + "</i></a>");
				} else {
					if (typeof(db_ss["ss_basic_version_local"]) != "undefined") {
					    if (res["version"] > db_ss["ss_basic_version_local"]) {
						    // 主界面的"检查并更新"按钮已移除，这里把"有新版本"并进版本号一起显示，
						    // 只报信息不提供入口；升级请走软件中心。
						    $("#ss_version_show").html("<a class='hintstyle' href='javascript:void(12);' onclick='openssHint(12)'><i>当前版本：" + db_ss['ss_basic_version_local'] + "（有新版本 " + res.version + "，请到软件中心升级）</i></a>");
					    }
					} else {
						$("#ss_version_show").html("<a class='hintstyle' href='javascript:void(12);' onclick='openssHint(12)'><i>当前版本：未知</i></a>");
					}
				}
			}
		}
	});
}

function get_ss_status_data() {
	if (checkss < 10000) {
		checkss++;
		$.ajax({
			type: "get",
			url: "/dbconf?p=ss_basic_enable",
			dataType: "script",
			success: function() {
				if (db_ss_basic_enable['ss_basic_enable'] == "1") {
					$.ajax({
						url: '/ss_status',
						dataType: "html",
						success: function(response) {
							console.log(response)
							var arr = JSON.parse(response);
							if (arr[0] == "" || arr[1] == "") {
								E("ss_state2").innerHTML = "国外连接 - <span class='ss-chip ss-chip-idle'>Waiting for first refresh...</span>";
								E("ss_state3").innerHTML = "国内连接 - <span class='ss-chip ss-chip-idle'>Waiting for first refresh...</span>";
							} else {
								E("ss_state2").innerHTML = arr[0];
								E("ss_state3").innerHTML = arr[1];
							}
						}
					});
				} else {
					E("ss_state2").innerHTML = "国外连接 - <span class='ss-chip ss-chip-idle'>Waiting...</span>";
					E("ss_state3").innerHTML = "国内连接 - <span class='ss-chip ss-chip-idle'>Waiting...</span>";
				}
				// UDP 那行跟着状态栏一起活着：cru/udp.sh 每5分钟重算一次，这里每约第4轮
				// （20~30秒）取一次就够，不必每轮都拉。
				if ((++udp_poll_tick % 4) == 1) refresh_udp_runtime();
				refreshRate = Math.floor(Math.random() * 4000) + 4000;
				setTimeout("get_ss_status_data();", refreshRate);
			}

		});
	}else{
		E("ss_state2").innerHTML = "国外连接 - <span class='ss-chip ss-chip-idle'>Waiting...</span>";
		E("ss_state3").innerHTML = "国内连接 - <span class='ss-chip ss-chip-idle'>Waiting...</span>";
	}
}


function toggle_func() {
	var ssmode = E("ss_basic_mode").value;
	$('.show-btn1').addClass('active');
	$(".show-btn1").click(
		function() {
			$('.show-btn1').addClass('active');
			$('.show-btn1_1').removeClass('active');
			$('.show-btn2').removeClass('active');
			$('.show-btn3').removeClass('active');
			$('.show-btn4').removeClass('active');
			$('.show-btn5').removeClass('active');
			$('.show-btn6').removeClass('active');
			$('.show-btn7').removeClass('active');
			E("tablet_1").style.display = "";
			E("tablet_2").style.display = "none";
			E("tablet_3").style.display = "none";
			E("tablet_4").style.display = "none";
			E("tablet_5").style.display = "none";
			E("tablet_6").style.display = "none";
			E("tablet_7").style.display = "none";
			E("apply_button").style.display = "";
			verifyFields();
			ss_node_info_return();
		});
	$(".show-btn1_1").click(
		function() {
			$('.show-btn1').removeClass('active');
			$('.show-btn1_1').addClass('active');
			$('.show-btn2').removeClass('active');
			$('.show-btn3').removeClass('active');
			$('.show-btn4').removeClass('active');
			$('.show-btn5').removeClass('active');
			$('.show-btn6').removeClass('active');
			$('.show-btn7').removeClass('active');
			E("tablet_1").style.display = "none";
			E("tablet_2").style.display = "none";
			E("tablet_3").style.display = "none";
			E("tablet_4").style.display = "none";
			E("tablet_5").style.display = "none";
			E("tablet_6").style.display = "none";
			E("tablet_7").style.display = "none";
			E("apply_button").style.display = "none";
			E("ss_node_list_table_td").style.display = "";
			E("ss_node_list_table_btn").style.display = "";
			refresh_table();
		});
	$(".show-btn2").click(
		//dns pannel
		function() {
			$('.show-btn1').removeClass('active');
			$('.show-btn1_1').removeClass('active');
			$('.show-btn2').addClass('active');
			$('.show-btn3').removeClass('active');
			$('.show-btn4').removeClass('active');
			$('.show-btn5').removeClass('active');
			$('.show-btn6').removeClass('active');
			$('.show-btn7').removeClass('active');
			E("tablet_1").style.display = "none";
			E("tablet_2").style.display = "";
			E("tablet_3").style.display = "none";
			E("tablet_4").style.display = "none";
			E("tablet_5").style.display = "none";
			E("tablet_6").style.display = "none";
			E("tablet_7").style.display = "none";
			E("apply_button").style.display = "";
			update_visibility();
			ss_node_info_return();
		});
	$(".show-btn3").click(
		// black_white list panel
		function() {
			$('.show-btn1').removeClass('active');
			$('.show-btn1_1').removeClass('active');
			$('.show-btn2').removeClass('active');
			$('.show-btn3').addClass('active');
			$('.show-btn4').removeClass('active');
			$('.show-btn5').removeClass('active');
			$('.show-btn6').removeClass('active');
			$('.show-btn7').removeClass('active');
			E("tablet_1").style.display = "none";
			E("tablet_2").style.display = "none";
			E("tablet_3").style.display = "";
			E("tablet_4").style.display = "none";
			E("tablet_5").style.display = "none";
			E("tablet_6").style.display = "none";
			E("tablet_7").style.display = "none";
			showhide("ss_wan_black_ip_tr", (ssmode != "5"));
			showhide("ss_wan_black_domain_tr", (ssmode != "5"));
			E("apply_button").style.display = "";
			ss_node_info_return();
		});
	$(".show-btn4").click(
		//rule manage
		function() {
			$('.show-btn1').removeClass('active');
			$('.show-btn1_1').removeClass('active');
			$('.show-btn2').removeClass('active');
			$('.show-btn3').removeClass('active');
			$('.show-btn4').addClass('active');
			$('.show-btn5').removeClass('active');
			$('.show-btn6').removeClass('active');
			$('.show-btn7').removeClass('active');
			E("tablet_1").style.display = "none";
			E("tablet_2").style.display = "none";
			E("tablet_3").style.display = "none";
			E("tablet_4").style.display = "";
			E("tablet_5").style.display = "none";
			E("tablet_6").style.display = "none";
			E("tablet_7").style.display = "none";
			E("apply_button").style.display = "none";
			update_visibility();
			ss_node_info_return();
		});
	$(".show-btn5").click(
		function() {
			$('.show-btn1').removeClass('active');
			$('.show-btn1_1').removeClass('active');
			$('.show-btn2').removeClass('active');
			$('.show-btn3').removeClass('active');
			$('.show-btn4').removeClass('active');
			$('.show-btn5').addClass('active');
			$('.show-btn6').removeClass('active');
			$('.show-btn7').removeClass('active');
			E("tablet_1").style.display = "none";
			E("tablet_2").style.display = "none";
			E("tablet_3").style.display = "none";
			E("tablet_4").style.display = "none";
			E("tablet_5").style.display = "";
			E("tablet_6").style.display = "none";
			E("tablet_7").style.display = "none";
			E("apply_button").style.display = "";
			ss_node_info_return();
			setTimeout("showDropdownClientList('setClientIP', 'ip', 'all', 'ClientList_Block', 'pull_arrow', 'online');", 1000);
			refresh_acl_table();
			update_visibility();
		});
	$(".show-btn6").click(
		function() {
			$('.show-btn1').removeClass('active');
			$('.show-btn1_1').removeClass('active');
			$('.show-btn2').removeClass('active');
			$('.show-btn3').removeClass('active');
			$('.show-btn4').removeClass('active');
			$('.show-btn5').removeClass('active');
			$('.show-btn6').addClass('active');
			$('.show-btn7').removeClass('active');
			E("tablet_1").style.display = "none";
			E("tablet_2").style.display = "none";
			E("tablet_3").style.display = "none";
			E("tablet_4").style.display = "none";
			E("tablet_5").style.display = "none";
			E("tablet_6").style.display = "";
			E("tablet_7").style.display = "none";
			E("apply_button").style.display = "";
			update_visibility();
			ss_node_info_return();
		});
	$(".show-btn7").click(
		function() {
			$('.show-btn1').removeClass('active');
			$('.show-btn1_1').removeClass('active');
			$('.show-btn2').removeClass('active');
			$('.show-btn3').removeClass('active');
			$('.show-btn4').removeClass('active');
			$('.show-btn5').removeClass('active');
			$('.show-btn6').removeClass('active');
			$('.show-btn7').addClass('active');
			E("tablet_1").style.display = "none";
			E("tablet_2").style.display = "none";
			E("tablet_3").style.display = "none";
			E("tablet_4").style.display = "none";
			E("tablet_5").style.display = "none";
			E("tablet_6").style.display = "none";
			E("tablet_7").style.display = "";
			E("apply_button").style.display = "none";
			E("log_content").style.display = "";
			ss_node_info_return();
			get_log();
		});
	$("#update_log").click(
		function() {
			window.open("https://github.com/hq450/fancyss/blob/master/fancyss_arm/Changelog.txt");
		});
	$("#log_content2").click(
		function() {
			x = -1;
		});
}

function ss_node_info_return() {
	cancel_add_rule();
	E("ss_node_list_table_th").style.display = "none";
	E("ss_node_list_table_td").style.display = "none";
	E("ss_node_list_table_btn").style.display = "none";
	checkTime = 2001;
}

function get_log() {
	$.ajax({
		url: '/cmdRet_check.htm',
		dataType: 'html',

		error: function(xhr) {
			setTimeout("get_log();", 1000);
		},
		success: function(response) {
			var retArea = E("log_content1");
			if (response.search("XU6J03M6") != -1) {
				retArea.value = response.replace("XU6J03M6", " ");
				return true;
			}
			if (_responseLen == response.length) {
				noChange++;
			} else {
				noChange = 0;
			}

			if (noChange > 5) {
				//retArea.value = "当前日志文件为空";
				return false;
			} else {
				setTimeout("get_log();", 200);
			}

			retArea.value = response;
			_responseLen = response.length;
		}
	});
}

function get_realtime_log() {
	$.ajax({
		url: '/cmdRet_check.htm',
		dataType: 'html',
		error: function(xhr) {
			setTimeout("get_realtime_log();", 1000);
		},
		success: function(response) {
			var retArea = E("log_content3");
			if (response.search("XU6J03M6") != -1) {
				retArea.value = response.replace("XU6J03M6", " ");
				E("ok_button").style.display = "";
				retArea.scrollTop = retArea.scrollHeight;
				x = 5;
				// 脚本跑完了，此刻 dbus 里的 ss_runtime_udp_* 才是本次应用的结果。
				// 必须重新拉一次：本页提交后不 reload，db_ss 还是载入时的旧快照。
				refresh_udp_runtime();
				count_down_close();
				return true;
			} else {
				E("ok_button").style.display = "none";
			}
			if (_responseLen == response.length) {
				noChange++;
			} else {
				noChange = 0;
			}
			if (noChange > 1000) {
				return false;
			} else {
				setTimeout("get_realtime_log();", 250);
			}
			retArea.value = response.replace("XU6J03M6", " ");
			retArea.scrollTop = retArea.scrollHeight;
			_responseLen = response.length;
		},
		error: function() {
			setTimeout("get_realtime_log();", 500);
		}
	});
}

function count_down_close() {
	if (x == "0") {
		hideSSLoadingBar();
	}
	if (x < 0) {
		E("ok_button1").value = "手动关闭"
		return false;
	}
	E("ok_button1").value = "自动关闭（" + x + "）"
		--x;
	setTimeout("count_down_close();", 1000);
}

function reload_Soft_Center() {
	location.href = "/Main_Soft_center.asp";
}

function getACLConfigs() {
	var dict = {};
	acl_node_max = 0;
	for (var field in db_ss) {
		names = field.split("_");
		dict[names[names.length - 1]] = 'ok';
	}
	acl_confs = {};
	var p = "ss_acl";
	var params = ["ip", "port", "mode"];
	for (var field in dict) {
		var obj = {};
		if (typeof db_ss[p + "_name_" + field] == "undefined") {
			obj["name"] = db_ss[p + "_ip_" + field];
		} else {
			obj["name"] = db_ss[p + "_name_" + field];
		}
		for (var i = 0; i < params.length; i++) {
			var ofield = p + "_" + params[i] + "_" + field;
			if (typeof db_ss[ofield] == "undefined") {
				obj = null;
				break;
			}
			obj[params[i]] = db_ss[ofield];
		}
		if (obj != null) {
			var node_a = parseInt(field);
			if (node_a > acl_node_max) {
				acl_node_max = node_a;
			}
			obj["acl_node"] = field;
			acl_confs[field] = obj;
		}
	}
	return acl_confs;
}

function addTr() {
	var acls = {};
	var p = "ss_acl";
	acl_node_max += 1;
	var params = ["ip", "name", "port", "mode"];
	for (var i = 0; i < params.length; i++) {
		acls[p + "_" + params[i] + "_" + acl_node_max] = $('#' + p + "_" + params[i]).val();
	}
	$.ajax({
		url: '/applydb.cgi?p=ss_acl',
		contentType: "application/x-www-form-urlencoded",
		dataType: 'text',
		data: $.param(acls),
		success: function(response) {
			confs = getAllConfigs();
			refresh_acl_table();
			E("ss_acl_name").value = ""
			E("ss_acl_ip").value = ""
		}
	});
	aclid = 0;
}

function delTr(o) {
	var id = $(o).attr("id");
	var ids = id.split("_");
	var p = "ss_acl";
	id = ids[ids.length - 1];
	var acls = {};
	var params = ["ip", "name", "port", "mode"];
	for (var i = 0; i < params.length; i++) {
		acls[p + "_" + params[i] + "_" + id] = "";
	}
	$.ajax({
		url: '/applydb.cgi?use_rm=1&p=ss_acl',
		contentType: "application/x-www-form-urlencoded",
		dataType: 'text',
		data: $.param(acls),
		success: function(response) {
			refresh_acl_table();
		}
	});
}

function refresh_acl_table(q) {
	$.ajax({
		url: '/dbconf?p=ss',
		dataType: 'html',
		error: function(xhr) {},
		success: function(response) {
			$.globalEval(response);
			$("#ACL_table").find("tr:gt(1)").remove();
			$('#ACL_table tr:last').after(refresh_acl_html());
			//write defaut rule mode when switching ss mode
			if (typeof db_ss["ss_acl_default_mode"] != "undefined") {
				if (E("ss_basic_mode").value == 1 && db_ss["ss_acl_default_mode"] == 1 || db_ss["ss_acl_default_mode"] == 0) {
					$('#ss_acl_default_mode').val(db_ss["ss_acl_default_mode"]);
				}
				if (E("ss_basic_mode").value == 2 && db_ss["ss_acl_default_mode"] == 2 || db_ss["ss_acl_default_mode"] == 0) {
					$('#ss_acl_default_mode').val(db_ss["ss_acl_default_mode"]);
				}
				if (E("ss_basic_mode").value == 3 && db_ss["ss_acl_default_mode"] == 3 || db_ss["ss_acl_default_mode"] == 0) {
					$('#ss_acl_default_mode').val(db_ss["ss_acl_default_mode"]);
				}
				if (E("ss_basic_mode").value == 5 && db_ss["ss_acl_default_mode"] == 5 || db_ss["ss_acl_default_mode"] == 0) {
					$('#ss_acl_default_mode').val(db_ss["ss_acl_default_mode"]);
				}
			}
			//write default rule port
			if (typeof db_ss["ss_acl_default_port"] != "undefined") {
				$('#ss_acl_default_port').val(db_ss["ss_acl_default_port"]);
			} else {
				$('#ss_acl_default_port').val("all");
			}
			//write dynamic table value
			for (var i = 1; i < acl_node_max + 1; i++) {
				$('#ss_acl_mode_' + i).val(db_ss["ss_acl_mode_" + i]);
				$('#ss_acl_port_' + i).val(db_ss["ss_acl_port_" + i]);
				$('#ss_acl_name_' + i).val(db_ss["ss_acl_name_" + i]);
			}
			//set default rule port to all when game mode enabled
			set_default_port();
			//after table generated and value filled, set default value for first line_image1
			$('#ss_acl_mode').val("1");
			$('#ss_acl_port').val("80,443");
		}
	});
}

function set_mode_1() {
	//set the first line of the table, if mode is gfwlist mode or game mode,set the port to all
	if ($('#ss_acl_mode').val() == 0 || $('#ss_acl_mode').val() == 3) {
		$("#ss_acl_port").val("all");
		E("ss_acl_port").readOnly = true;
		E("ss_acl_port").title = "不可更改，游戏模式下默认全端口";
	} else if ($('#ss_acl_mode').val() == 1) {
		$("#ss_acl_port").val("80,443");
		E("ss_acl_port").readOnly = true;
		E("ss_acl_port").title = "";
	} else if ($('#ss_acl_mode').val() == 2 || $('#ss_acl_mode').val() == 5) {
		$("#ss_acl_port").val("22,80,443");
		E("ss_acl_port").readOnly = false;
		E("ss_acl_port").title = "";
	}
}

function set_mode_2(o) {
	var id2 = $(o).attr("id");
	var ids2 = id2.split("_");
	id2 = ids2[ids2.length - 1];
	if ($(o).val() == 0 || $(o).val() == 3) {
		$("#ss_acl_port_" + id2).val("all");
		//E("ss_acl_port_" + id2).disabled=true;
	} else if ($(o).val() == 1) {
		$("#ss_acl_port_" + id2).val("80,443");
		//E("ss_acl_port_" + id2).disabled=false;
	} else if ($(o).val() == 2) {
		$("#ss_acl_port_" + id2).val("22,80,443");
		//E("ss_acl_port_" + id2).disabled=false;
	}
}

function set_default_port() {
	if ($('#ss_acl_default_mode').val() == 3) {
		$("#ss_acl_default_port").val("all");
		E("ss_acl_default_port").readOnly = true;
		E("ss_acl_default_port").title = "不可更改，游戏模式下默认全端口";
	} else {
		E("ss_acl_default_port").readOnly = false;
		E("ss_acl_default_port").title = "";
	}
}

function refresh_acl_html() {
	acl_confs = getACLConfigs();
	var n = 0;
	for (var i in acl_confs) {
		n++;
	} //获取节点的数目
	var code = '';
	for (var field in acl_confs) {
		var ac = acl_confs[field];
		code = code + '<tr>';
		code = code + '<td>' + ac["ip"] + '</td>';
		code = code + '<td>';
		code = code + '<input type="text" placeholder="' + ac["acl_node"] + '号机" id="ss_acl_name_' + ac["acl_node"] + '" name="ss_acl_name_' + ac["acl_node"] + '" class="input_option_2" maxlength="50" style="width:140px;" placeholder="" />';
		code = code + '</td>';
		code = code + '<td>';
		code = code + '<select id="ss_acl_mode_' + ac["acl_node"] + '" name="ss_acl_mode_' + ac["acl_node"] + '" style="width:160px;margin:0px 0px 0px 2px;" class="input_option_2" onchange="set_mode_2(this);">';
		if ($("#ss_basic_mode").val() == 6) {
			code = code + '<option value="0">不通过代理</option>';
			code = code + '<option value="6">回国模式</option>';
		} else {
			code = code + '<option value="0">不通过代理</option>';
			code = code + '<option value="1">gfwlist模式</option>';
			code = code + '<option value="2">大陆白名单模式</option>';
			if (is_ss_node()) code = code + '<option value="3">游戏模式</option>';
			code = code + '<option value="5">全局代理模式</option>';
			code = code + '<option value="6">回国模式</option>';
		}
		code = code + '</select>'
		code = code + '</td>';
		code = code + '<td>';
		if (ac["mode"] == 3) {
			code = code + '<input type="text" id="ss_acl_port_' + ac["acl_node"] + '" name="ss_acl_port_' + ac["acl_node"] + '" class="input_option_2" maxlength="50" style="width:140px;" title="不可更改，游戏模式下默认全端口" readonly = "readonly" />';
		} else if (ac["mode"] == 0) {
			code = code + '<input type="text" id="ss_acl_port_' + ac["acl_node"] + '" name="ss_acl_port_' + ac["acl_node"] + '" class="input_option_2" maxlength="50" style="width:140px;" title="不可更改，不通过SS下默认全端口" readonly = "readonly" />';
		} else {
			code = code + '<input type="text" id="ss_acl_port_' + ac["acl_node"] + '" name="ss_acl_port_' + ac["acl_node"] + '" class="input_option_2" maxlength="50" style="width:140px;" placeholder="" />';
		}
		code = code + '</td>';
		code = code + '<td>';
		code = code + '<input style="margin: -3px 0px -5px 6px;" id="acl_node_' + ac["acl_node"] + '" class="remove_btn" type="button" onclick="delTr(this);" value="">'
		code = code + '</td>';
		code = code + '</tr>';
	}
	code = code + '<tr>';
	if (n == 0) {
		code = code + '<td>所有主机</td>';
	} else {
		code = code + '<td>其它主机</td>';
	}
	code = code + '<td>默认规则</td>';
	ssmode = E("ss_basic_mode").value;
	if (n == 0) {
		if (ssmode == 0) {
			code = code + '<td>SS关闭</td>';
		} else if (ssmode == 1) {
			code = code + '<td>gfwlist模式</td>';
		} else if (ssmode == 2) {
			code = code + '<td>大陆白名单模式</td>';
		} else if (ssmode == 3) {
			code = code + '<td>游戏模式</td>';
		} else if (ssmode == 5) {
			code = code + '<td>全局模式</td>';
		} else if (ssmode == 6) {
			code = code + '<td>回国模式</td>';
		}
	} else {
		code = code + '<td>';
		code = code + '<select id="ss_acl_default_mode" name="ss_acl_default_mode" style="width:160px;margin:0px 0px 0px 2px;" class="input_option_2" onchange="set_default_port();">';
		if (ssmode == 0) {
			code = code + '<td>SS关闭</td>';
		} else if (ssmode == 1) {
			code = code + '<option value="0">不通过代理</option>';
			code = code + '<option value="1" selected>gfwlist模式</option>';
		} else if (ssmode == 2) {
			code = code + '<option value="0">不通过代理</option>';
			code = code + '<option value="2" selected>大陆白名单模式</option>';
		} else if (ssmode == 3) {
			code = code + '<option value="0">不通过代理</option>';
			code = code + '<option value="3" selected>游戏模式</option>';
		} else if (ssmode == 5) {
			code = code + '<option value="0">不通过代理</option>';
			code = code + '<option value="5" selected>全局代理模式</option>';
		} else if (ssmode == 6) {
			code = code + '<option value="0">不通过代理</option>';
			code = code + '<option value="6" selected>回国模式</option>';
		}
		code = code + '</select>';
		code = code + '</td>';
	}
	code = code + '<td>';
	code = code + '<input type="text" id="ss_acl_default_port" name="ss_acl_default_port" class="input_option_2" maxlength="50" style="width:140px;" placeholder="" />';
	code = code + '</td>';
	code = code + '<td>';
	code = code + '</td>';
	code = code + '</tr>';
	return code;

}

function setClientIP(ip, name, mac) {
	E("ss_acl_ip").value = ip;
	E("ss_acl_name").value = name;
	hideClients_Block();
}

function pullLANIPList(obj) {
	var element = E('ClientList_Block');
	var isMenuopen = element.offsetWidth > 0 || element.offsetHeight > 0;
	if (isMenuopen == 0) {
		obj.src = "/images/arrow-top.gif";
		element.style.display = 'block';
	} else{
		hideClients_Block();
	}
}

function hideClients_Block() {
	E("pull_arrow").src = "/images/arrow-down.gif";
	E('ClientList_Block').style.display = 'none';
	validator.validIPForm(document.form.ss_acl_ip, 0);
}

function get_proc_status() {
	noChange3 = 0;
	now_get_status();
	setTimeout("write_proc_status();", 500);
	$("#detail_status").fadeIn(200);
}

function close_proc_status() {
	$("#detail_status").fadeOut(200);
}

function now_get_status() {
	$.ajax({
		url: 'apply.cgi?current_page=Main_Ss_Content.asp&next_page=Main_Ss_Content.asp&group_id=&modified=0&action_mode=+Refresh+&action_script=&action_wait=&first_time=&preferred_lang=CN&SystemCmd=ss_proc_status.sh&firmver=3.0.0.4',
		dataType: 'html'
	});
}

var noChange3 = 0;
function write_proc_status() {
	E("proc_status").value = ""
	$.ajax({
		url: '/res/ss_proc_status.htm',
		dataType: 'html',
		error: function(xhr) {
			setTimeout("write_proc_status();", 1400);
		},
		success: function(response) {
			var retArea = E("proc_status");
			if (response.search("XU6J03M6") != -1) {
				retArea.value = response.replace("XU6J03M6", " ");
				//retArea.scrollTop = retArea.scrollHeight;
				return true;
			} else {}
			if (_responseLen == response.length) {
				noChange3++;
			} else {
				noChange3 = 0;
			}
			if (noChange3 > 100) {
				return false;
			} else {
				setTimeout("write_proc_status();", 500);
			}
			retArea.value = response.replace("XU6J03M6", " ");
			//retArea.scrollTop = retArea.scrollHeight;
			_responseLen = response.length;
		}
	});
}

function ss_binary_update(binary_update){
	db_ss["ss_basic_action"] = "15";
	var dbus = {};
	dbus["SystemCmd"] = "ss_v2ray_xray.sh";
	dbus["ss_binary_update"] = binary_update;
	dbus["action_mode"] = " Refresh ";
	dbus["current_page"] = "Main_Ss_Content.asp";
	var varinfo = "";
 	if (binary_update == 2) {
		varinfo = '<li>为了避免不必要的问题，请保证路由器和服务器上的Xray版本一致！</li><br /><li>你确定要更新Xray二进制吗？</li>';
	} else if (binary_update == 3) {
		varinfo = '<li>为了避免不必要的问题，请保证路由器和服务器上的NaiveProxy版本一致！</li><br /><li>你确定要更新naive二进制吗？</li>';
	} else if (binary_update == 4) {
		varinfo = '<li>为了避免不必要的问题，请保证路由器和服务器上的Hysteria2版本一致！</li><br /><li>你确定要更新Hysteria2二进制吗？</li>';
	} else {
		return false;
	}
	require(['/res/layer/layer.js'], function(layer) {
		layer.confirm(varinfo, {
			shade: 0.8,
		}, function(index) {
			$("#log_content3").attr("rows", "20");
			push_data(dbus);
			layer.close(index);
			return true;
		}, function(index) {
			layer.close(index);
			return false;
		});
	});
}

function status_onchange(){
    var __ss_reboot_check="";
    var ___ss_basic_inter_pre="";
    __ss_reboot_check=E("ss_reboot_check").value;
    ___ss_basic_inter_pre=E("ss_basic_inter_pre").value;
    //alert(__ss_reboot_check)
    if (__ss_reboot_check == "0") {
        E('_ss_basic_day_pre').style.display="none";
        E('_ss_basic_week_pre').style.display="none";
        E('_ss_basic_time_pre').style.display="none";
        E('_ss_basic_inter_pre').style.display="none";
        E('_ss_basic_custom_pre').style.display="none";
        E('_ss_basic_send_text').style.display="none";
    } else if(__ss_reboot_check == "1"){
        E('_ss_basic_week_pre').style.display="none";
        E('_ss_basic_day_pre').style.display="none";
        E('_ss_basic_time_pre').style.display="inline";
        E('_ss_basic_inter_pre').style.display="none";
        E('_ss_basic_custom_pre').style.display="none";
        E('_ss_basic_send_text').style.display="inline";
        E('ss_basic_time_hour').style.display="inline";
    } else if(__ss_reboot_check == "2"){
        E('_ss_basic_week_pre').style.display="inline";
        E('_ss_basic_day_pre').style.display="none";
        E('_ss_basic_time_pre').style.display="inline";
        E('_ss_basic_inter_pre').style.display="none";
        E('_ss_basic_custom_pre').style.display="none";
        E('ss_basic_time_hour').style.display="inline";
        E('_ss_basic_send_text').style.display="inline";
    } else if(__ss_reboot_check == "3"){
        E('_ss_basic_week_pre').style.display="none";
        E('_ss_basic_day_pre').style.display="inline";
        E('_ss_basic_time_pre').style.display="inline";
        E('_ss_basic_inter_pre').style.display="none";
        E('_ss_basic_custom_pre').style.display="none";
        E('ss_basic_time_hour').style.display="inline";
        E('_ss_basic_send_text').style.display="inline";
    } else if(__ss_reboot_check == "4"){
        E('_ss_basic_week_pre').style.display="none";
        E('_ss_basic_day_pre').style.display="none";
        E('_ss_basic_time_pre').style.display="none";
        E('_ss_basic_inter_pre').style.display="inline";
        E('_ss_basic_custom_pre').style.display="none";
        E('_ss_basic_send_text').style.display="inline";
        if (___ss_basic_inter_pre == "1") {
            E('ss_basic_inter_min').style.display="inline";
            E('ss_basic_inter_hour').style.display="none";
            E('ss_basic_inter_day').style.display="none";
            E('_ss_basic_time_pre').style.display="none";
            E('_ss_basic_inter_pre').style.display="inline";
            E('_ss_basic_send_text').style.display="inline";
        } else if(___ss_basic_inter_pre == "2"){
            E('ss_basic_inter_min').style.display="none";
            E('ss_basic_inter_hour').style.display="inline";
            E('ss_basic_inter_day').style.display="none";
            E('_ss_basic_time_pre').style.display="none";
            E('_ss_basic_inter_pre').style.display="inline";
            E('_ss_basic_send_text').style.display="inline";
        } else if(___ss_basic_inter_pre == "3"){
            E('ss_basic_inter_min').style.display="none";
            E('ss_basic_inter_hour').style.display="none";
            E('ss_basic_inter_day').style.display="inline";
            E('_ss_basic_time_pre').style.display="inline";
            E('_ss_basic_inter_pre').style.display="inline";
            E('_ss_basic_send_text').style.display="inline";
            E('ss_basic_time_hour').style.display="inline";
        }
    } else if(__ss_reboot_check == "5"){
        E('_ss_basic_week_pre').style.display="none";
        E('_ss_basic_day_pre').style.display="none";
        E('_ss_basic_time_pre').style.display="inline";
        E('_ss_basic_inter_pre').style.display="none";
        E('_ss_basic_custom_pre').style.display="inline";
        E('_ss_basic_send_text').style.display="inline";
        E('ss_basic_time_hour').style.display="none";
    }
}
function inter_pre_onchange(){
    var __ss_basic_inter_pre="";
    __ss_basic_inter_pre=E("ss_basic_inter_pre").value;
    if (__ss_basic_inter_pre == "1") {
        E('ss_basic_inter_min').style.display="inline";
        E('ss_basic_inter_hour').style.display="none";
        E('ss_basic_inter_day').style.display="none";
        E('_ss_basic_time_pre').style.display="none";
        E('_ss_basic_inter_pre').style.display="inline";
        E('_ss_basic_send_text').style.display="inline";
    } else if(__ss_basic_inter_pre == "2"){
        E('ss_basic_inter_min').style.display="none";
        E('ss_basic_inter_hour').style.display="inline";
        E('ss_basic_inter_day').style.display="none";
        E('_ss_basic_time_pre').style.display="none";
        E('_ss_basic_inter_pre').style.display="inline";
        E('_ss_basic_send_text').style.display="inline";
    } else if(__ss_basic_inter_pre == "3"){
        E('ss_basic_inter_min').style.display="none";
        E('ss_basic_inter_hour').style.display="none";
        E('ss_basic_inter_day').style.display="inline";
        E('_ss_basic_time_pre').style.display="inline";
        E('_ss_basic_inter_pre').style.display="inline";
        E('_ss_basic_send_text').style.display="inline";
    }
}

function set_cron(action) {
	var dbus = {};
	dbus["SystemCmd"] = "ss_reboot_job.sh";
	dbus["action_mode"] = " Refresh ";
	dbus["current_page"] = "Main_Ss_Content.asp";
	dbus["ss_basic_reboot_action"] = action;
	if(action == 1){
		//设定定时重启
		db_ss["ss_basic_action"] = "16";
		var cron_params1 = ["ss_reboot_check", "ss_basic_week", "ss_basic_day", "ss_basic_inter_min", "ss_basic_inter_hour", "ss_basic_inter_day", "ss_basic_inter_pre", "ss_basic_custom", "ss_basic_time_hour", "ss_basic_time_min"]; //for ss
		for (var i = 0; i < cron_params1.length; i++) {
			dbus[cron_params1[i]] = E(cron_params1[i]).value;
		}
		
		if (!E("ss_basic_custom").value) {
			dbus["ss_basic_custom"] = "";
		} else {
			dbus["ss_basic_custom"] = Base64.encode(E("ss_basic_custom").value);
		}
	}else if(action == 2){
		//设定触发重启
		db_ss["ss_basic_action"] = "17";
		var cron_params2 = ["ss_basic_tri_reboot_time", "ss_basic_tri_reboot_policy"]; //for ss
		for (var i = 0; i < cron_params2.length; i++) {
			dbus[cron_params2[i]] = E(cron_params2[i]).value;
		}
	}
	push_data(dbus);
}

</script>
</head>
<body onload="init();">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<div id="LoadingBar" class="popup_bar_bg">
<table cellpadding="5" cellspacing="0" id="loadingBarBlock" class="loadingBarBlock"  align="center">
	<tr>
		<td height="100">
		<div id="loading_block3" style="margin:10px auto;margin-left:10px;width:85%; font-size:12pt;"></div>
		<div id="loading_block2" style="margin:10px auto;width:95%;"></div>
		<div id="log_content2" style="margin-left:15px;margin-right:15px;margin-top:10px;overflow:hidden">
			<textarea cols="63" rows="21" wrap="on" readonly="readonly" id="log_content3" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" style="border:1px solid #000;width:99%; font-family:'Lucida Console'; font-size:11px;background:#000;color:#FFFFFF;outline: none;padding-left:3px;padding-right:22px;overflow-x:hidden"></textarea>
		</div>
		<div id="ok_button" class="apply_gen" style="background: #000;display: none;">
			<input id="ok_button1" class="button_gen" type="button" onclick="hideSSLoadingBar()" value="确定">
		</div>
		</td>
	</tr>
</table>
</div>
<iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" action="/applydb.cgi?p=ss" target="hidden_frame">
<input type="hidden" name="current_page" value="Main_Ss_Content.asp"/>
<input type="hidden" name="next_page" value="Main_Ss_Content.asp"/>
<input type="hidden" name="group_id" value=""/>
<input type="hidden" name="modified" value="0"/>
<input type="hidden" name="action_mode" value=""/>
<input type="hidden" name="action_script" value=""/>
<input type="hidden" name="action_wait" value="6"/>
<input type="hidden" name="first_time" value=""/>
<input type="hidden" id="vpnc_type" name="vpnc_type" value="">
<input type="hidden" id="ss_online_action" name="ss_online_action" value="" />
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>"/>
<input type="hidden" name="SystemCmd" value=""/>
<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>"/>
<table class="content" align="center" cellpadding="0" cellspacing="0">
	<tr>
		<td width="17">&nbsp;</td>
		<!--=====Beginning of Main Menu=====-->
		<td valign="top" width="202">
			<div id="mainMenu"></div>
			<div id="subMenu"></div>
		</td>
		<td valign="top">
			<div id="tabMenu" class="submenuBlock"></div>
			<!--=====Beginning of Main Content=====-->
			<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0" id="table_for_all" style="display: block;">
				<tr>
					<td align="left" valign="top">
						<div>
							<table width="760px" border="0" cellpadding="5" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
								<tr>
									<td bgcolor="#4D595D" colspan="3" valign="top">
										<div>&nbsp;</div>
										<div class="formfonttitle">梅林固件 - Shadowsocks 插件</div>
										<div style="float:right; width:15px; height:25px;margin-top:-20px">
											<img id="return_btn" onclick="reload_Soft_Center();" align="right" style="cursor:pointer;position:absolute;margin-left:-30px;margin-top:-25px;" title="返回软件中心" src="/images/backprev.png" onMouseOver="this.src='/images/backprevclick.png'" onMouseOut="this.src='/images/backprev.png'"></img>
										</div>
										<div style="margin-left:5px;margin-top:10px;margin-bottom:10px"><img src="/images/New_ui/export/line_export.png"></div>
										<div class="SimpleNote" id="head_illustrate"><a target="_blank" href="https://github.com/guijianchou/v2ray_bin_lite" ><em><u>本插件</u></em></a>是支持<a href="https://github.com/shadowsocks/shadowsocks-libev" target="_blank"><em><u>SS（含SS2022）</u></em></a>, <a target="_blank" href="https://github.com/XTLS/Xray-core"><em><u>Xray (VMess, VLESS, Trojan, Trojan-Go)</u></em></a>, <a target="_blank" href="https://github.com/apernet/hysteria/"><em><u>Hysteria2</u></em></a> 的科学上网工具; 游戏模式仅支持SS协议节点, 其它协议可用「同步UDP与TCP」按需代理QUIC与游戏端口。</div>
										<div style="margin-top: 0px;text-align: center;font-size: 18px;margin-bottom: 0px;" class="formfontdesc" id="cmdDesc"></div>
										<!-- this is the popup area for status -->
										<div id="detail_status"  class="content_status" style="box-shadow: 3px 3px 10px #000;margin-top: 0px;display: none;">
											<div class="user_title">【Shadowsocks】状态检测</div>
											<div style="margin-left:15px"><i>&nbsp;&nbsp;目前本功能支持ss相关进程状态和iptables表状态检测。</i></div>
											<div id="user_tr" style="margin: 10px 10px 10px 10px;width:98%;text-align:center;overflow:hidden">
												<textarea cols="63" rows="36" wrap="off" id="proc_status" style="width:98%;padding-left:13px;padding-right:33px;border:0px solid #222;font-family:'Lucida Console'; font-size:11px;background: transparent;color:#FFFFFF;outline: none;overflow-x:hidden;" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
											</div>
											<div style="margin-top:5px;padding-bottom:10px;width:100%;text-align:center;">
												<input class="button_gen" type="button" onclick="close_proc_status();" value="返回主界面">	
											</div>	
										</div>
										<!-- end of the popouparea -->
										<div id="ss_switch_show">
											<table style="margin:0px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" id="ss_switch_table">
												<thead>
												<tr>
													<td colspan="2">开关</td>
												</tr>
												</thead>
												<tr>
												<th id="ss_switch"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(10)">Shadowsocks 开关</a></th>
													<td colspan="2">
														<div class="switch_field" style="display:table-cell;float: left;">
															<label for="ss_basic_enable">
																<input id="ss_basic_enable" class="switch" type="checkbox" style="display: none;">
																<div class="switch_container" >
																	<div class="switch_bar"></div>
																	<div class="switch_circle transition_style">
																		<div></div>
																	</div>
																</div>
															</label>
														</div>
														<div id="ss_version_show" style="display:inline-block;vertical-align:middle;margin-left:18px;padding: 5.5px 0px;">
															<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(12)">
																<i>当前版本：<% dbus_get_def("ss_basic_version_local", "未知"); %></i>
															</a>
														</div>
														<!--<div style="display:table-cell;float: left;margin-left:270px;position: absolute;padding: 5.5px 0px;">
															<a type="button" class="ss_btn" target="_blank" href="https://github.com/hq450/fancyss/blob/master/fancyss_arm/Changelog.txt">更新日志</a>
														</div>
														<div style="display:table-cell;float: left;margin-left:350px;position: absolute;padding: 5.5px 0px;">
															<a type="button" class="ss_btn" href="javascript:void(0);" onclick="pop_help()">插件帮助</a>
														</div>-->
														<div style="display:inline-block;vertical-align:middle;margin-left:14px;padding: 5.5px 0px;">
															<a type="button" class="ss_btn" href="javascript:void(0);" onclick="pop_help()">插件帮助</a>
														</div>
													</td>
												</tr>
                                    		</table>
                                    	</div>
                                    	<div id="ss_status1">
											<table style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" >
												<tr id="ss_state">
												<th id="mode_state" width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(0)">SS运行状态</a></th>
											<td>
												<div class="ss-status-layout">
													<div class="ss-status-lines">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(0)">
															<span id="ss_state2">国外连接 - <span class="ss-chip ss-chip-idle">Waiting...</span></span>
															<br/>
															<span id="ss_state3">国内连接 - <span class="ss-chip ss-chip-idle">Waiting...</span></span>
														</a>
														<br/>
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(116)">
															<span id="ss_state4">UDP代理 - <span class="ss-chip ss-chip-idle">Waiting...</span></span>
														</a>
														<br/>
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(106)">
															<span id="ss_state5">DNS劫持 - <span class="ss-chip ss-chip-idle">Waiting...</span></span>
														</a>
													</div>
													<div class="ss-status-actions">
														<a type="button" class="ss_btn" style="cursor:pointer" onclick="pop_111(3)" href="javascript:void(0);">分流检测</a>
														<a type="button" class="ss_btn" style="cursor:pointer" onclick="get_proc_status(3)" href="javascript:void(0);">详细状态</a>
													</div>
												</div>
											</td>
												</tr>
											</table>
										</div>
										<div id="tablets">
											<table style="margin:10px 0px 0px 0px;border-collapse:collapse" width="100%" height="37px">
												<tr width="235px">
													<td colspan="4" cellpadding="0" cellspacing="0" style="padding:0" border="1" bordercolor="#000">
														<input id="show_btn1" class="show-btn1" style="cursor:pointer" type="button" value="账号设置" />
														<input id="show_btn1_1" class="show-btn1_1" style="cursor:pointer" type="button" value="节点管理" />
														<input id="show_btn2" class="show-btn2" style="cursor:pointer" type="button" value="全局设定" />
														<input id="show_btn3" class="show-btn3" style="cursor:pointer" type="button" value="黑白名单" />
												<input id="show_btn4" class="show-btn4" style="cursor:pointer" type="button" value="更新管理" />
														<input id="show_btn5" class="show-btn5" style="cursor:pointer" type="button" value="访问控制" />
														<input id="show_btn6" class="show-btn6" style="cursor:pointer" type="button" value="附加功能" />
														<input id="show_btn7" class="show-btn7" style="cursor:pointer" type="button" value="查看日志" />
													</td>
												</tr>
											</table>
										</div>
										<div id="vpnc_settings"  class="contentM_qis" style="box-shadow: 3px 3px 10px #000;margin-top: 50px;">
											<table class="QISform_wireless" border=0 align="center" cellpadding="5" cellspacing="0">
												<tr style="height:32px;">
													<td>		
														<table width="100%" border="0" align="left" cellpadding="0" cellspacing="0" class="vpnClientTitle">
															<tr>
									  		<td width="33%" align="center" id="ssTitle" onclick="tabclickhandler(0);">添加SS配置</td>
									  		<td width="33%" align="center" id="v2rayTitle" onclick="tabclickhandler(3);">添加V2Ray配置</td>
											<td width="34%" align="center" id="trojanTitle" onclick="tabclickhandler(4);">添加Trojan配置</td>
											<!-- 旧协议入口已移除：以下仅在编辑存量节点时由 show_ss_config 显示 -->
											<td width="34%" align="center" id="ssrTitle" style="display:none;">SSR配置</td>
											<td width="34%" align="center" id="gamev2Title" style="display:none;">koolgame配置</td>
											<td width="34%" align="center" id="naiveTitle" style="display:none;">Naive配置</td>
															</tr>
														</table>
													</td>
												</tr>
												<tr>
													<td>
														<!-- vpnc_pptp/l2tp start  -->
														<div>
														<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" class="FormTable">
															<tr id="ss_node_table_mode_tr">
																<th>使用模式</th>
																<td>
																	<select id="ss_node_table_mode" name="ss_node_table_mode" class="input_option" style="width:350px;margin:0px 0px 0px 2px;" onchange="verifyFields(this, 1);">
																		<option value="1">【1】 gfwlist模式</option>
																		<option value="2">【2】 大陆白名单模式</option>
																		<option value="3">【3】 游戏模式</option>
																		<option value="5">【4】 全局代理模式</option>
																		<option value="6">【5】 回国模式</option>
																	</select>
																</td>
															</tr>
															<tr id="v2ray_use_json_tr" style="display: none;">
																<th width="35%">
																	使用json配置&nbsp;&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(27)"><font color="#ffcc00"><u>[说明]</u></font></a>
																</th>
																<td>
																	<input type="checkbox" id="ss_node_table_v2ray_use_json" name="ss_node_table_v2ray_use_json" onclick="verifyFields(this, 1);" >
																</td>
															</tr>
															<tr id="ss_name_support_tr" style="display: none;">
																<th>节点别名</th>
																<td>
																  	<input type="text" maxlength="64" id="ss_node_table_name" name="ss_node_table_name" value="" class="input_ss_table" style="width:342px;float:left;" autocorrect="off" autocapitalize="off"/>
																</td>
															</tr>
															<tr id="naive_protocol_tr" style="display: none;">
																<th width="35%">NaiveProxy 协议</th>
																<td>
																	<select id="ss_node_table_naive_protocol" name="ss_node_table_naive_protocol" style="width:350px;margin:0px 0px 0px 2px;" class="input_option" >
																		<option value="https">https</option>
																		<option value="quic">quic</option>
																	</select>
																</td>
															</tr>
															<tr id="v2ray_protocol_tr" style="display: none;">
																<th width="35%">协议protocol（vmess/vless）</th>
																<td>
																	<!-- <input type="text" name="ss_node_table_v2ray_protocol" id="ss_node_table_v2ray_protocol"  class="input_ss_table" style="width:342px;" maxlength="300" value=""/> -->
																	<select id="ss_node_table_v2ray_protocol" name="ss_node_table_v2ray_protocol" style="width:350px;margin:0px 0px 0px 2px;" class="input_option" onchange="protocol_change_off(this.value);">
																		<option value="vmess">vmess</option>
																		<option value="vless">vless</option>														
																	</select>
																</td>
															</tr>
															<tr id="trojan_binary_tr" style="display: none;">
																<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(108)">协议（Trojan/Trojan-Go/Hysteria2/AnyTLS）</a></th>
																<td>
																	<select id="ss_node_table_trojan_binary" name="ss_node_table_trojan_binary" style="width:350px;margin:0px 0px 0px 2px;" class="input_ss_table" onchange="trojan_change_off(this.value);">
																		<option value="Trojan" >Trojan</option>
																		<option value="Trojan-Go">Trojan-Go</option>
																		<option value="Hysteria2">Hysteria2</option>
																		<option value="AnyTLS">AnyTLS</option>
																	</select>
																</td>
															</tr>
															<tr id="ss_server_support_tr" style="display: none;">
																<th>服务器地址</th>
																<td>
																	<input type="text" maxlength="64" id="ss_node_table_server" name="ss_node_table_server" value="" class="input_ss_table" style="width:342px;float:left;" autocorrect="off" autocapitalize="off"/>
																</td>
															</tr>
															<tr id="ss_port_support_tr" style="display: none;">
																<th>服务器端口</th>
																<td>
																	<input type="text" maxlength="64" id="ss_node_table_port" name="ss_node_table_port" value="" class="input_ss_table" style="width:342px;float:left;" autocomplete="off" autocorrect="off" autocapitalize="off"/>
																</td>
															</tr>
															<tr id="naive_user_tr" style="display: none;">
																<th>账户</th>
																<td>
																  	<input type="text" maxlength="64" id="ss_node_table_naive_user" name="ss_node_table_naive_user" value="" class="input_ss_table" style="width:342px;float:left;" autocomplete="off" autocorrect="off" autocapitalize="off"/>
																</td>
															</tr>
															<tr id="ss_passwd_support_tr" style="display: none;">
																<th>密码</th>
																<td>
																	<input type="password" maxlength="64" id="ss_node_table_password" name="ss_node_table_password" value="" class="input_ss_table" style="width:342px;float:left;" autocomplete="off" autocorrect="off" autocapitalize="off" readonly onBlur="switchType(this, false);" onFocus="switchType(this, true);this.removeAttribute('readonly');"/>
																</td>
															</tr>
															<tr id="trojan_network_tr" style="display: none;">
																<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(119)">Trojan Go 混淆</a></th>
																<td>
																	<select id="ss_node_table_trojan_network" name="ss_node_table_trojan_network" style="width:350px;margin:0px 0px 0px 2px;" class="input_ss_table" onchange="network_change_off(this.value);">
																		<option value="0" selected >none</option>
																		<option value="1">websocket</option>
																	</select>
																</td>
															</tr>
															<tr id="ss_method_support_tr" style="display: none;">
																<th>加密方式</th>
																<td>
																	<select id="ss_node_table_method" name="ss_node_table_method" class="input_option" style="width:350px;margin:0px 0px 0px 2px;" onchange="verifyFields(this, 1);">
																		<option value="none" selected>none</option>
																		<option value="rc4">rc4</option>
																		<option value="rc4-md5">rc4-md5</option>
																		<option value="rc4-md5-6">rc4-md5-6</option>
																		<option value="aes-128-gcm">AEAD_AES_128_GCM</option>
																		<option value="aes-192-gcm">AEAD_AES_192_GCM</option>
																		<option value="aes-256-gcm">AEAD_AES_256_GCM</option>
																		<option value="aes-128-cfb">aes-128-cfb</option>
																		<option value="aes-192-cfb">aes-192-cfb</option>
																		<option value="aes-256-cfb">aes-256-cfb</option>
																		<option value="aes-128-ctr">aes-128-ctr</option>
																		<option value="aes-192-ctr">aes-192-ctr</option>
																		<option value="aes-256-ctr">aes-256-ctr</option>
																		<option value="camellia-128-cfb">camellia-128-cfb</option>
																		<option value="camellia-192-cfb">camellia-192-cfb</option>
																		<option value="camellia-256-cfb">camellia-256-cfb</option>
																		<option value="bf-cfb">bf-cfb</option>
																		<option value="cast5-cfb">cast5-cfb</option>
																		<option value="idea-cfb">idea-cfb</option>
																		<option value="rc2-cfb">rc2-cfb</option>
																		<option value="seed-cfb">seed-cfb</option>
																		<option value="salsa20">salsa20</option>
																		<option value="chacha20">chacha20</option>
																		<option value="chacha20-ietf">chacha20-ietf</option>
																		<option value="chacha20-ietf-poly1305">chacha20-ietf-poly1305</option>
																		<option value="xchacha20-ietf-poly1305">xchacha20-ietf-poly1305</option>
																		<option value="2022-blake3-aes-128-gcm">2022-blake3-aes-128-gcm</option>
																		<option value="2022-blake3-aes-256-gcm">2022-blake3-aes-256-gcm</option>
																		<option value="2022-blake3-chacha20-poly1305">2022-blake3-chacha20-poly1305</option>																		
																	</select>
																</td>	
															</tr>
															<tr id="ss_v2ray_plugin_support" style="display: none;">
																<th>SIP003 plugin</th>
																<td>
																	<select name="ss_node_table_ss_v2ray_plugin" id="ss_node_table_ss_v2ray_plugin" class="input_option" style="width:350px;margin:0px 0px 0px 2px;" onchange="verifyFields(this, 1);">
																		<option value="0" selected>关闭</option>
																		
																		<option value="2">simple-obfs</option>																		
																	</select>
																</td>
															</tr>
															<tr id="ss_v2ray_plugin_opts_support" style="display: none;">
																<th>SIP003 plugin参数</th>
																<td>
																	<input type="text" name="ss_node_table_ss_v2ray_plugin_opts" id="ss_node_table_ss_v2ray_plugin_opts" placeholder="tls;host=cloudfront.com"  class="input_ss_table" style="width:342px;" maxlength="100" value=""/>
																</td>
															</tr>
															<tr id="ssr_protocol_tr" style="display: none;">
																<th width="35%"><a href="https://github.com/breakwa11/shadowsocks-rss/wiki/Server-Setup" target="_blank"><u>协议 (protocol)</u></a></th>
																<td>
																	<select id="ss_node_table_rss_protocol" name="ss_node_table_rss_protocol" style="width:350px;margin:0px 0px 0px 2px;" class="input_option">
																		<option value="origin" selected>origin</option>
																		<option value="verify_simple">verify_simple</option>
																		<option value="verify_sha1">verify_sha1</option>
																		<option value="auth_sha1">auth_sha1</option>
																		<option value="auth_sha1_v2">auth_sha1_v2</option>
																		<option value="auth_sha1_v4">auth_sha1_v4</option>
																		<option value="auth_aes128_md5">auth_aes128_md5</option>
																		<option value="auth_aes128_sha1">auth_aes128_sha1</option>
																		<option value="auth_chain_a">auth_chain_a</option>
																		<option value="auth_chain_b">auth_chain_b</option>
																		<option value="auth_chain_c">auth_chain_c</option>
																		<option value="auth_chain_d">auth_chain_d</option>
																		<option value="auth_chain_e">auth_chain_e</option>
																		<option value="auth_chain_f">auth_chain_f</option>
																	</select>
																</td>
															</tr>
															<tr id="ssr_protocol_param_tr" style="display: none;">
																<th width="35%"><a href="https://github.com/breakwa11/shadowsocks-rss/wiki/Server-Setup" target="_blank"><u>协议参数 (protocol_param)</u></a></th>
																<td>
																	<input type="text" maxlength="64" id="ss_node_table_rss_protocol_param" name="ss_node_table_rss_protocol_param" value="" class="input_ss_table" style="width:342px;float:left;" autocomplete="off" autocorrect="off" autocapitalize="off"/>
																</td>
															</tr>
															<tr id="ssr_obfs_tr" style="display: none;">
																<th width="35%"><a href="https://github.com/breakwa11/shadowsocks-rss/wiki/Server-Setup" target="_blank"><u>混淆 (obfs)</u></a></th>
																<td>
																	<select id="ss_node_table_rss_obfs" name="ss_node_table_rss_obfs" style="width:350px;margin:0px 0px 0px 2px;" class="input_option">
																		<option value="plain">plain</option>
																		<option value="http_simple">http_simple</option>
																		<option value="http_post">http_post</option>
																		<option value="tls1.2_ticket_auth">tls1.2_ticket_auth</option>
																	</select>
																</td>
															</tr>
															<tr id="ssr_obfs_param_tr" style="display: none;">
																<th width="35%"><a href="https://github.com/breakwa11/shadowsocks-rss/blob/master/ssr.md" target="_blank"><u>混淆参数 (obfs_param)</u></a></th>
																<td>
																	<input type="text" name="ss_node_table_rss_obfs_param" id="ss_node_table_rss_obfs_param" placeholder="cloudflare.com"  class="input_ss_table" style="width:342px;" maxlength="300" value=""/>
																</td>
															</tr>
															<tr id="gameV2_udp_tr" style="display: none;">
																<th width="35%">UDP通道</th>
																<td>
																	<select id="ss_node_table_koolgame_udp" name="ss_node_table_koolgame_udp" style="width:350px;margin:0px 0px 0px 2px;" class="input_option">
																		<option value="0">udp in udp</option>
																		<option value="1">udp in tcp</option>
																	</select>
																</td>
															</tr>
										      				<!--===================================v2ray===========================================-->			
															<tr id="v2ray_uuid_tr" style="display: none;">
																<th width="35%" id="use_uuid_off">用户id（id）</th>
																<td>
																	<input type="text" name="ss_node_table_v2ray_uuid" id="ss_node_table_v2ray_uuid"  class="input_ss_table" style="width:342px;" maxlength="300" value=""/>
																</td>
															</tr>															
															<tr id="v2ray_alterid_tr" style="display: none;">
																<th width="35%">额外ID (Alterld)</th>
																<td>
																	<input type="text" name="ss_node_table_v2ray_alterid" id="ss_node_table_v2ray_alterid"  class="input_ss_table" style="width:342px;" maxlength="300" value=""/>
																</td>
															</tr>																
															<tr id="v2ray_security_tr" style="display: none;">
																<th width="35%">加密方式 (security)</th>
																<td>
																	<select id="ss_node_table_v2ray_security" name="ss_node_table_v2ray_security" style="width:350px;margin:0px 0px 0px 2px;" class="input_option">
																		<option value="auto">自动</option>
																		<option value="aes-128-cfb">aes-128-cfb</option>
																		<option value="aes-128-gcm">aes-128-gcm</option>
																		<option value="chacha20-poly1305">chacha20-poly1305</option>
																		<option value="none">不加密</option>
																	</select>
																</td>
															</tr>
															<tr id="v2ray_network_tr" style="display: none;">
																<th width="35%">传输协议 (network)</th>
																<td>
																	<select id="ss_node_table_v2ray_network" name="ss_node_table_v2ray_network" style="width:350px;margin:0px 0px 0px 2px;" class="input_option" onchange="flow_change_off(this.value);">
																		<option value="tcp">tcp</option>
																		<option value="kcp">kcp</option>
																		<option value="ws">ws</option>
																		<option value="h2">h2</option>
																		<option value="grpc">grpc</option>
																	</select>
																</td>
															</tr>
															<tr id="v2ray_headtype_tcp_tr" style="display: none;">
																<th width="35%">tcp伪装类型 (type)</th>
																<td>
																	<select id="ss_node_table_v2ray_headtype_tcp" name="ss_node_table_v2ray_headtype_tcp" style="width:350px;margin:0px 0px 0px 2px;" class="input_option" onchange="verifyFields(this, 1);">
																		<option value="none">不伪装</option>
																		<option value="http">伪装http</option>
																	</select>
																</td>
															</tr>
															<tr id="v2ray_headtype_kcp_tr" style="display: none;">
																<th width="35%">kcp伪装类型 (type)</th>
																<td>
																	<select id="ss_node_table_v2ray_headtype_kcp" name="ss_node_table_v2ray_headtype_kcp" style="width:350px;margin:0px 0px 0px 2px;" class="input_option" onchange="verifyFields(this, 1);">
																		<option value="none">不伪装</option>
																		<option value="srtp">伪装视频通话(srtp)</option>
																		<option value="utp">伪装BT下载(uTP)</option>
																		<option value="wechat-video">伪装微信视频通话</option>
																	</select>
																</td>
															</tr>
															<tr id="v2ray_network_host_tr" style="display: none;">
																<th width="35%">伪装域名 (host)</th>
																<td>
																	<input type="text" name="ss_node_table_v2ray_network_host" id="ss_node_table_v2ray_network_host"  class="input_ss_table" placeholder="没有请留空" style="width:342px;" maxlength="300" value=""/>
																</td>
															</tr>
															<tr id="v2ray_serviceName_tr" style="display: none;">
																<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(120)">serviceName</a></th>
																<td>
																	<input type="text" name="ss_node_table_v2ray_serviceName" id="ss_node_table_v2ray_serviceName"  class="input_ss_table" placeholder="没有请留空" style="width:342px;" maxlength="300" value=""/>
																</td>
															</tr>															
															<tr id="v2ray_network_path_tr" style="display: none;">
																<th width="35%">路径 (path) | kcp seed</th>
																<td>
																	<input type="text" name="ss_node_table_v2ray_network_path" id="ss_node_table_v2ray_network_path"  class="input_ss_table" placeholder="没有请留空" style="width:342px;" maxlength="300" value=""/>
																</td>
															</tr>
															<tr id="v2ray_network_security_tr" style="display: none;">
																<th width="35%">底层传输安全</th>
																<td>
																	<select id="ss_node_table_v2ray_network_security" name="ss_node_table_v2ray_network_security" onchange="reality_change_off(this.value);" style="width:350px;margin:0px 0px 0px 2px;" class="input_option">
																		<option value="none">关闭</option>
																		<option value="tls">tls</option>
																		<option value="reality">reality</option>
																	</select>
																</td>
															</tr>
															<tr id="v2ray_network_flow_tr" style="display: none;">
																<th width="35%">流控 (flow)</th>
																<td>
																	<select id="ss_node_table_v2ray_network_flow" name="ss_node_table_v2ray_network_flow" onchange="verifyFields(this, 1);" style="width:350px;margin:0px 0px 0px 2px;" class="input_option">
																		<option value=""></option>
																		<optgroup label="xtls-vision" id="vision_flow_opt">
																			<option value="xtls-rprx-vision">xtls-rprx-vision</option>
																			<option value="xtls-rprx-vision-udp443">xtls-rprx-vision-udp443</option>
																		</optgroup>	
																	</select>
																</td>
															</tr>
															<tr id="v2ray_network_tlshost_tr" style="display: none;">
																<th width="35%">
																	<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(110)">tls/xtls域名 (SNI)</a>
																</th>
																<td>
																	<input type="text" name="ss_node_table_v2ray_network_tlshost" id="ss_node_table_v2ray_network_tlshost" class="input_ss_table"  placeholder="没有请留空"  style="width:342px;" maxlength="300" value="" />
																</td>
															</tr>
															<tr id="xray_publicKey_tr" style="display: none;">
																<th width="35%">
																	<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(113)">公钥 (publicKey)</a>
																</th>
																<td>
																	<input type="text" name="ss_node_table_xray_publicKey" id="ss_node_table_xray_publicKey" class="input_ss_table"  placeholder="没有请留空"  style="width:342px;" maxlength="300" value="" />
																</td>
															</tr>
															<tr id="xray_shortId_tr" style="display: none;">
																<th width="35%">
																	<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(115)">shortId</a>
																</th>
																<td>
																	<input type="text" name="ss_node_table_xray_shortId" id="ss_node_table_xray_shortId" class="input_ss_table"  placeholder="没有请留空"  style="width:342px;" maxlength="300" value="" />
																</td>
															</tr>
															<tr id="trojan_sni_tr" style="display: none;">
																<th width="35%">
																	<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(110)">tls/xtls域名 (SNI)</a>
																</th>
																<td>
																	<input type="text" name="ss_node_table_trojan_sni" id="ss_node_table_trojan_sni" class="input_ss_table"  placeholder="没有请留空"  style="width:342px;" maxlength="300" value="" />
																</td>
															</tr>
															<tr id="fingerprint_tr" style="display: none;">
																<th width="35%">
																	<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(114)">指纹 (fingerprint)</a>
																</th>															
																<td>
																	<select id="ss_node_table_fingerprint" name="ss_node_table_fingerprint" onchange="verifyFields(this, 1);" style="width:350px;margin:0px 0px 0px 2px;" class="input_option">
																		<option value="">关闭</option>
																		<option value="firefox">firefox</option>
																		<option value="chrome">chrome</option>
																		<option value="ios">ios</option>
																		<option value="safari">safari</option>
																		<option value="android">android</option>
																		<option value="edge">edge</option>
																		<option value="360">360</option>
																		<option value="qq">qq</option>
																		<option value="random">random</option>
																		<option value="randomized">randomized</option>
																	</select>
																</td>
															</tr>	
															<tr id="allowinsecure_tr" style="display: none;">
																<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(112)">允许不安全</a></th>
																<td>
																	<input type="checkbox" id="ss_node_table_allowinsecure" name="ss_node_table_allowinsecure" onclick="verifyFields(this, 1);" value="0">
																</td>
															</tr>	
															<tr id="fragment_tr" style="display: none;">
																<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(117)">开启片段</a></th>
																<td>
																	<input type="checkbox" id="ss_node_table_fragment" name="ss_node_table_fragment" onclick="verifyFields(this, 1);" value="0">
																</td>
															</tr>																													
															<tr id="v2ray_mux_enable_tr" style="display: none;">
																<th width="35%">多路复用 (Mux)</th>
																<td>
																	<input type="checkbox" id="ss_node_table_v2ray_mux_enable" name="ss_node_table_v2ray_mux_enable" onclick="verifyFields(this, 1);" value="0">
																</td>
															</tr>
															<tr id="v2ray_mux_concurrency_tr" style="display: none;">
																<th width="35%">Mux并发连接数</th>
																<td>
																	<input type="text" name="ss_node_table_v2ray_mux_concurrency" id="ss_node_table_v2ray_mux_concurrency"  class="input_ss_table" style="width:342px;" maxlength="300" value=""/>
																</td>
															</tr>
															<tr id="v2ray_json_tr" style="display: none;">
																<th width="35%">v2ray json</th>
																<td>
																	<textarea placeholder="# 此处填入v2ray json，内容可以是标准的也可以是压缩的
																	# 请保证你json内的outbound配置正确！！！
																	# ------------------------------------
																	# 同样支持vmess://链接填入，格式如下：
																	vmess://ew0KICAidiI6ICIyIiwNCiAgInBzIjogIjIzMyIsDQogICJhZGQiOiAiMjMzLjIzMy4yMzMuMjMzIiwNCiAgInBvcnQiOiAiMjMzIiwNCiAgImlkIjogImFlY2EzYzViLTc0NzktNDFjMy1hMWUzLTAyMjkzYzg2Y2EzOCIsDQogICJhaWQiOiAiMjMzIiwNCiAgIm5ldCI6ICJ3cyIsDQogICJ0eXBlIjogIm5vbmUiLA0KICAiaG9zdCI6ICJ3d3cuMjMzLmNvbSIsDQogICJwYXRoIjogIi8yMzMiLA0KICAidGxzIjogInRscyINCn0=" rows="32" style="width:99%; font-family:'Lucida Console'; font-size:12px;background:#475A5F;color:#FFFFFF;" id="ss_node_table_v2ray_json" name="ss_node_table_v2ray_json" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" title=""></textarea>
																</td>
															</tr>
															</table>
												 		</div>
													</td>
												</tr>

											</table>
											<div style="margin-top:5px;padding-bottom:10px;width:100%;text-align:center;">
												<input class="button_gen" style="margin-left: 160px;" type="button" onclick="cancel_add_rule();" id="cancelBtn" value="返回">
												<input id="add_node" class="button_gen" type="button" onclick="add_ss_node_conf(save_flag);" value="添加">
												<input id="edit_node" style="display: none;" class="button_gen" type="button" onclick="edit_ss_node_conf(save_flag);" value="修改">	
												<a id="continue_add" style="display: none;margin-left: 20px;"><input id="continue_add_box" type="checkbox"  />连续添加</a>
											</div>	
										      <!--===================================Ending of vpnc setting Content===========================================-->			
										</div>
										
										<!--=====bacic show =====-->
										<div id="tablet_1">
											<table style="margin:-1px 0px 0px 0px;" width="100%" border="0" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" >
												<tr class="ss-group"><td colspan="2">节点</td></tr>
												<tr id="node_select">
													<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(15)">节点选择</a></th>
													<td>
														<select id="ssconf_basic_node" name="ssconf_basic_node" style="width:auto;min-width:164px;max-width:300px;margin:0px 0px 0px 2px;" class="input_option" onchange="ss_node_sel();" ></select>
													</td>
												<!--== <th width="15%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(15)">分享节点</a></th>===-->
												</tr>
												<tr id="mode_select">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(1)">模式</a>
														</th>
													<td>
														<select id="ss_basic_mode" name="ss_basic_mode" style="width:164px;margin:0px 0px 0px 2px;" class="input_option" onchange="verifyFields(this, 1);" >
															<option value="1">【1】 gfwlist模式</option>
															<option value="2">【2】 大陆白名单模式</option>
															<option value="3">【3】 游戏模式</option>
															<option value="5">【4】 全局代理模式</option>
															<option value="6">【5】 回国模式</option>
														</select>
													</td>
												</tr>
												<tr id="v2ray_use_json_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(27)"><font color="#ffcc00">使用json配置</font></a>
													</th>
													<td>
														<input type="checkbox" id="ss_basic_v2ray_use_json" name="ss_basic_v2ray_use_json" onclick="verifyFields(this, 1);" value="0">
													</td>
												</tr>
												<tr id="ss_naive_protocol_tr" style="display: none;">
													<th width="35%">NaiveProxy 协议</th>
													<td>
														<select id="ss_basic_naive_protocol" name="ss_basic_naive_protocol" style="width:164px;margin:0px 0px 0px 2px;" class="input_option">
															<option value="https">https</option>
															<option value="quic">quic</option>
														</select>
													</td>
												</tr>								
												<tr id="v2ray_protocol_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(109)"><font color="#ffcc00">协议protocol（vmess/vless）</font></a>
													</th>
													<td>
														<!-- <input type="text" name="ss_basic_v2ray_protocol" id="ss_basic_v2ray_protocol"  class="input_ss_table" maxlength="300" value=""/>-->
														<select id="ss_basic_v2ray_protocol" name="ss_basic_v2ray_protocol" style="width:164px;margin:0px 0px 0px 2px;" class="input_option"  onchange="protocol_change_on(this.value);">
															<option value="vmess">vmess</option>
															<option value="vless">vless</option>
														<!--	<option value="trojan">trojan</option>-->
														</select>
													</td>
												</tr>
												<tr id="trojan_binary_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(108)"><font color="#ffcc00">协议（Trojan/Trojan-Go/Hysteria2/AnyTLS）</font></a>
													</th>
													<td>
														<select id="ss_basic_trojan_binary" name="ss_basic_trojan_binary" style="width:164px;margin:0px 0px 0px 2px;" class="input_option"  onchange="verifyFields(this, 1);">
															<option value="Trojan">Trojan</option>
															<option value="Trojan-Go">Trojan-Go</option>
															<option value="Hysteria2">Hysteria2</option>
															<option value="AnyTLS">AnyTLS</option>
														</select>
													</td>
												</tr>
												<tr id="server_tr">
													<th id="server_th" width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(2)">服务器</a></th>
													<td>
														<input type="text" class="input_ss_table" id="ss_basic_server" name="ss_basic_server" maxlength="100" value=""/>
													</td>
												</tr>
												<tr id="port_tr">
													<th id="port_th" width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(3)">服务器端口</a></th>
													<td>
														<input type="text" class="input_ss_table" id="ss_basic_port" name="ss_basic_port" maxlength="100" value="" />
													</td>
												</tr>
												<tr id="ss_naive_user_tr" style="display: none;">
													<th width="35%">账户</th>
													<td>
														<input type="text" name="ss_basic_naive_user" id="ss_basic_naive_user"  class="input_ss_table" maxlength="100" value="" />
													</td>
												</tr>
												<tr id="pass_tr">
													<th id="pass_th" width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(4)">密码</a></th>
													<td>
														<input type="password" name="ss_basic_password" id="ss_basic_password" class="input_ss_table" autocomplete="off" autocorrect="off" autocapitalize="off" maxlength="100" value="" readonly onBlur="switchType(this, false);" onFocus="switchType(this, true);this.removeAttribute('readonly');"/>
													</td>
												</tr>											
												<tr id="method_tr">
													<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(5)">加密方式</a></th>
													<td>
														<select id="ss_basic_method" name="ss_basic_method" style="width:300px;margin:0px 0px 0px 2px;" class="input_option" onchange="verifyFields(this, 1);">
															<option value="none" selected>none</option>
															<option value="rc4">rc4</option>
															<option value="rc4-md5">rc4-md5</option>
															<option value="rc4-md5-6">rc4-md5-6</option>
															<option value="aes-128-gcm">AEAD_AES_128_GCM</option>
															<option value="aes-192-gcm">AEAD_AES_192_GCM</option>
															<option value="aes-256-gcm">AEAD_AES_256_GCM</option>
															<option value="aes-128-cfb">aes-128-cfb</option>
															<option value="aes-192-cfb">aes-192-cfb</option>
															<option value="aes-256-cfb">aes-256-cfb</option>
															<option value="aes-128-ctr">aes-128-ctr</option>
															<option value="aes-192-ctr">aes-192-ctr</option>
															<option value="aes-256-ctr">aes-256-ctr</option>
															<option value="camellia-128-cfb">camellia-128-cfb</option>
															<option value="camellia-192-cfb">camellia-192-cfb</option>
															<option value="camellia-256-cfb">camellia-256-cfb</option>
															<option value="bf-cfb">bf-cfb</option>
															<option value="cast5-cfb">cast5-cfb</option>
															<option value="idea-cfb">idea-cfb</option>
															<option value="rc2-cfb">rc2-cfb</option>
															<option value="seed-cfb">seed-cfb</option>
															<option value="salsa20">salsa20</option>
															<option value="chacha20">chacha20</option>
															<option value="chacha20-ietf">chacha20-ietf</option>
															<option value="chacha20-ietf-poly1305">chacha20-ietf-poly1305</option>
															<option value="xchacha20-ietf-poly1305">xchacha20-ietf-poly1305</option>
															<option value="2022-blake3-aes-128-gcm">2022-blake3-aes-128-gcm</option>
															<option value="2022-blake3-aes-256-gcm">2022-blake3-aes-256-gcm</option>
															<option value="2022-blake3-chacha20-poly1305">2022-blake3-chacha20-poly1305</option>
														</select>
													</td>
												</tr>
												<tr id="ss_koolgame_udp_tr" >
													<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(6)">UDP通道</a></th>
													<td>
														<select id="ss_basic_koolgame_udp" name="ss_basic_koolgame_udp" style="width:164px;margin:0px 0px 0px 2px;" class="input_option" onchange="verifyFields(this, 1);" >
															<option value="0">udp in udp</option>
															<option value="1">udp in tcp</option>
														</select>
													</td>
												</tr>
												<tr id="ss_v2ray_plugin">
													<th width="35%">SIP003 plugin</th>
													<td>
														<select id="ss_basic_ss_v2ray_plugin" name="ss_basic_ss_v2ray_plugin" style="width:164px;margin:0px 0px 0px 2px;" class="input_option"  onchange="verifyFields(this, 1);" >
															<option class="content_input_fd" value="0">关闭</option>
																
															<option class="content_input_fd" value="2">simple-obfs</option>
														</select>
													</td>
												</tr>
												<tr id="ss_v2ray_plugin_opts">
													<th width="35%">SIP003 plugin参数</th>
													<td>
														<input type="text" name="ss_basic_ss_v2ray_plugin_opts" id="ss_basic_ss_v2ray_plugin_opts" placeholder="tls;host=cloudfront.com"  class="input_ss_table" style="width:300px;" maxlength="100" value=""/>
													</td>
												</tr>
												
												<tr id="ss_basic_rss_protocol_tr">
													<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(8)">协议 (protocol)</a></th>
													<td>
														<select id="ss_basic_rss_protocol" name="ss_basic_rss_protocol" style="width:164px;margin:0px 0px 0px 2px;" class="input_option" onchange="verifyFields(this, 1);" >
															<option class="content_input_fd" value="origin">origin</option>
															<option class="content_input_fd" value="verify_simple">verify_simple</option>
															<option class="content_input_fd" value="verify_sha1">verify_sha1</option>
															<option class="content_input_fd" value="auth_sha1">auth_sha1</option>
															<option class="content_input_fd" value="auth_sha1_v2">auth_sha1_v2</option>
															<option class="content_input_fd" value="auth_sha1_v4">auth_sha1_v4</option>
															<option value="auth_aes128_md5">auth_aes128_md5</option>
															<option value="auth_aes128_sha1">auth_aes128_sha1</option>
															<option value="auth_chain_a">auth_chain_a</option>
															<option value="auth_chain_b">auth_chain_b</option>
															<option value="auth_chain_c">auth_chain_c</option>
															<option value="auth_chain_d">auth_chain_d</option>
															<option value="auth_chain_e">auth_chain_e</option>
															<option value="auth_chain_f">auth_chain_f</option>
														</select>
														<span id="ss_basic_rss_protocol_alert" style="margin-left:5px;margin-top:-20px;margin-bottom:0px"></span>
													</td>
												</tr>
												<tr id="ss_basic_rss_protocol_param_tr">
													<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(54)">协议参数 (protocol_param)</a></th>
													<td>
														<input type="password" name="ss_basic_rss_protocol_param" id="ss_basic_rss_protocol_param" placeholder="id:password"  class="input_ss_table" maxlength="100" value="" readonly onBlur="switchType(this, false);" onFocus="switchType(this, true);this.removeAttribute('readonly');"/>
													</td>
												</tr>
												<tr id="ss_basic_rss_obfs_tr">
													<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(9)">混淆 (obfs)</a></th>
													<td>
														<select id="ss_basic_rss_obfs" name="ss_basic_rss_obfs" style="width:164px;margin:0px 0px 0px 2px;" class="input_option"  onchange="verifyFields(this, 1);" >
															<option class="content_input_fd" value="plain">plain</option>
															<option class="content_input_fd" value="http_simple">http_simple</option>
															<option class="content_input_fd" value="http_post">http_post</option>
															<option class="content_input_fd" value="tls1.2_ticket_auth">tls1.2_ticket_auth</option>
														</select>
														<span id="ss_basic_rss_obfs_alert" style="margin-left:5px;margin-top:-20px;margin-bottom:0px"></span>
													</td>
												</tr>
												<tr id="ss_basic_ticket_tr">
													<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(11)">混淆参数 (obfs_param)</a></th>
													<td>
														<input type="text" name="ss_basic_rss_obfs_param" id="ss_basic_rss_obfs_param" placeholder="cloudflare.com"  class="input_ss_table" maxlength="300" value=""/>
													</td>
												</tr>
										      	<!--===================================v2ray===========================================-->			
												<tr id="v2ray_uuid_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(49)"><font color="#ffcc00" id="use_uuid_on">用户id（id）</font></a>
													</th>
													<td>
														<input type="text" name="ss_basic_v2ray_uuid" id="ss_basic_v2ray_uuid"  class="input_ss_table" style="width:300px;" maxlength="300" value="" readonly onBlur="switchType(this, false);" onFocus="switchType(this, true);this.removeAttribute('readonly');"/>
													</td>
												</tr>															
												<tr id="v2ray_alterid_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(48)"><font color="#ffcc00">额外ID (Alterld)</font></a>
													</th>
													<td>
														<input type="text" name="ss_basic_v2ray_alterid" id="ss_basic_v2ray_alterid"  class="input_ss_table" maxlength="300" value=""/>
													</td>
												</tr>			
												<tr id="v2ray_security_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(47)"><font color="#ffcc00">加密方式 (security)</font></a>
													</th>
													<td>
														<select id="ss_basic_v2ray_security" name="ss_basic_v2ray_security" style="width:164px;margin:0px 0px 0px 2px;" class="input_option">
															<option value="none">不加密</option>
															<option value="auto">自动</option>
															<option value="aes-128-cfb">aes-128-cfb</option>
															<option value="aes-128-gcm">aes-128-gcm</option>
															<option value="chacha20-poly1305">chacha20-poly1305</option>
														</select>
													</td>
												</tr>
												<tr id="v2ray_network_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(35)"><font color="#ffcc00">传输协议 (network)</font></a>
													</th>
													<td>
														<select id="ss_basic_v2ray_network" name="ss_basic_v2ray_network" style="width:164px;margin:0px 0px 0px 2px;" class="input_option" onchange="verifyFields(this, 1);">
															<option value="tcp">tcp</option>
															<option value="kcp">kcp</option>
															<option value="ws">ws</option>
															<option value="h2">h2</option>
															<option value="grpc">grpc</option>
														</select>
													</td>
												</tr>
												<tr id="trojan_network_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(119)"><font color="#ffcc00">Trojan 混淆</font></a>
													</th>
													<td>
														<select id="ss_basic_trojan_network" name="ss_basic_trojan_network" style="width:164px;margin:0px 0px 0px 2px;" class="input_option"  onchange="verifyFields(this, 1);">
															<option value="0">none</option>
															<option value="1">websocket</option>
														</select>
													</td>
												</tr>
												<tr class="ss-sub" id="v2ray_headtype_tcp_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(36)"><font color="#ffcc00">tcp伪装类型 (type)</font></a>
													</th>
													<td>
														<select id="ss_basic_v2ray_headtype_tcp" name="ss_basic_v2ray_headtype_tcp" style="width:164px;margin:0px 0px 0px 2px;" class="input_option" onchange="verifyFields(this, 1);">
															<option value="none">不伪装</option>
															<option value="http">伪装http</option>
														</select>
													</td>
												</tr>
												<tr class="ss-sub" id="v2ray_headtype_kcp_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(37)"><font color="#ffcc00">kcp伪装类型 (type)</font></a>
													</th>
													<td>
														<select id="ss_basic_v2ray_headtype_kcp" name="ss_basic_v2ray_headtype_kcp" style="width:164px;margin:0px 0px 0px 2px;" class="input_option" onchange="verifyFields(this, 1);">
															<option value="none">不伪装</option>
															<option value="srtp">伪装视频通话(srtp)</option>
															<option value="utp">伪装BT下载(uTP)</option>
															<option value="wechat-video">伪装微信视频通话</option>
														</select>
													</td>
												</tr>
												<tr class="ss-sub" id="v2ray_network_host_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(28)"><font color="#ffcc00">伪装域名 (host)</font></a>
													</th>
													<td>
														<input type="text" name="ss_basic_v2ray_network_host" id="ss_basic_v2ray_network_host" class="input_ss_table" style="width:300px;" placeholder="没有请留空" maxlength="300" value=""/>
													</td>
												</tr>
												<tr class="ss-sub" id="v2ray_network_path_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(29)"><font color="#ffcc00">路径 (path) | kcp seed</font></a>
													</th>
													<td>
														<input type="text" name="ss_basic_v2ray_network_path" id="ss_basic_v2ray_network_path" class="input_ss_table" style="width:300px;" placeholder="没有请留空" maxlength="300" value=""/>
													</td>
												</tr>
												<tr class="ss-sub" id="v2ray_serviceName_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(120)"><font color="#ffcc00">服务名称 (ServiceName)</font></a>
													</th>
													<td>
														<input type="text" name="ss_basic_v2ray_serviceName" id="ss_basic_v2ray_serviceName" class="input_ss_table"  maxlength="300" value=""/>
													</td>
												</tr>
												<tr id="v2ray_network_security_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(30)"><font color="#ffcc00">底层传输安全</font></a>
													</th>
													<td>
														<select id="ss_basic_v2ray_network_security" name="ss_basic_v2ray_network_security" onchange="verifyFields(this, 1);" style="width:164px;margin:0px 0px 0px 2px;" class="input_option">
															<option value="none">关闭</option>
															<option value="tls">tls</option>
															<option value="reality">reality</option>
														</select>
													</td>
												</tr>
												<tr id="v2ray_network_flow_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);"onclick="openssHint(111)"><font color="#ffcc00">流控 (flow)</font></a>
													</th>
													<td>
														<select id="ss_basic_v2ray_network_flow" name="ss_basic_v2ray_network_flow" onchange="verifyFields(this, 1);" style="width:164px;margin:0px 0px 0px 2px;" class="input_option">
															<option value=""></option>
															<optgroup label="xtls-vision" id="vision_flow_opt_basic">
																<option value="xtls-rprx-vision">xtls-rprx-vision</option>
																<option value="xtls-rprx-vision-udp443">xtls-rprx-vision-udp443</option>
															</optgroup>	
														</select>
													</td>
												</tr>
												<tr id="xray_publicKey_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(113)"><font color="#ffcc00">公钥 (publicKey)</font></a>
													</th>
													<td>
														<input type="text" name="ss_basic_xray_publicKey" id="ss_basic_xray_publicKey" class="input_ss_table" style="width:300px;" placeholder="没有请留空" maxlength="300" value=""/>
													</td>
												</tr>
												<tr id="xray_shortId_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(115)"><font color="#ffcc00">shortId</font></a>
													</th>
													<td>
														<input type="text" name="ss_basic_xray_shortId" id="ss_basic_xray_shortId" class="input_ss_table" style="width:300px;" placeholder="没有请留空" maxlength="300" value=""/>
													</td>
												</tr>
												<tr id="v2ray_network_tlshost_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(110)"><font color="#ffcc00">tls/xtls域名 (SNI)</font></a>
													</th>
													<td>
														<input type="text" name="ss_basic_v2ray_network_tlshost" id="ss_basic_v2ray_network_tlshost" class="input_ss_table" style="width:300px;" placeholder="没有请留空" maxlength="300" value=""/>
													</td>
												</tr>

												<tr id="trojan_sni_basic_tr" style="display: none;">												
													<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(110)">tls/xtls域名 (SNI)</a></th>
													<td>
														<input type="text" name="ss_basic_trojan_sni" id="ss_basic_trojan_sni" class="input_ss_table"  style="width:300px;" placeholder="没有请留空" maxlength="300" value=""/>
													</td>
												</tr>
												<tr id="fingerprint_basic_tr" style="display: none;">
													<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(114)">指纹 (fingerprint)</a></th>							
													<td>
														<select id="ss_basic_fingerprint" name="ss_basic_fingerprint" onchange="verifyFields(this, 1);" style="width:164px;margin:0px 0px 0px 2px;" class="input_option">
															<option value="">关闭</option>
															<option value="firefox">firefox</option>
															<option value="chrome">chrome</option>
															<option value="ios">ios</option>
															<option value="safari">safari</option>
															<option value="android">android</option>
															<option value="edge">edge</option>
															<option value="360">360</option>
															<option value="qq">qq</option>
															<option value="random">random</option>
															<option value="randomized">randomized</option>
														</select>
													</td>
												</tr>
												<tr id="allowinsecure_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(112)">允许不安全</a>
													</th>
													<td>
														<input type="checkbox" id="ss_basic_allowinsecure" name="ss_basic_allowinsecure" onclick="verifyFields(this, 1);" value="0">
													</td>
												</tr>
												<tr id="fragment_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(117)">开启片段</a>
													</th>
													<td>
														<input type="checkbox" id="ss_basic_fragment" name="ss_basic_fragment" onclick="verifyFields(this, 1);" value="0">
													</td>
												</tr>
												<tr id="v2ray_mux_enable_basic_tr" style="display: none;">
													<th width="35%">
														<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(31)"><font color="#ffcc00">多路复用 (Mux)</font></a>
													</th>
													<td>
														<input type="checkbox" id="ss_basic_v2ray_mux_enable" name="ss_basic_v2ray_mux_enable" onclick="verifyFields(this, 1);" value="0">
													</td>
												</tr>
												<tr id="v2ray_mux_concurrency_basic_tr" style="display: none;">
													<th width="35%">
													<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(32)"><font color="#ffcc00">Mux并发连接数</font></a>
													</th>
													<td>
														<input type="text" name="ss_basic_v2ray_mux_concurrency" id="ss_basic_v2ray_mux_concurrency"  class="input_ss_table" maxlength="300" value=""/>
													</td>
												</tr>
												<tr id="v2ray_json_basic_tr" style="display: none;">
													<th width="35%">v2ray json</th>
													<td>
														<textarea  placeholder="# 此处填入v2ray json，内容可以是标准的也可以是压缩的
																	# 请保证你json内的outbound配置正确！！！
																	# ------------------------------------
																	# 同样支持vmess://链接填入，格式如下：
																	vmess://ew0KICAidiI6ICIyIiwNCiAgInBzIjogIjIzMyIsDQogICJhZGQiOiAiMjMzLjIzMy4yMzMuMjMzIiwNCiAgInBvcnQiOiAiMjMzIiwNCiAgImlkIjogImFlY2EzYzViLTc0NzktNDFjMy1hMWUzLTAyMjkzYzg2Y2EzOCIsDQogICJhaWQiOiAiMjMzIiwNCiAgIm5ldCI6ICJ3cyIsDQogICJ0eXBlIjogIm5vbmUiLA0KICAiaG9zdCI6ICJ3d3cuMjMzLmNvbSIsDQogICJwYXRoIjogIi8yMzMiLA0KICAidGxzIjogInRscyINCn0=" rows="40" style="width:99%; font-family:'Lucida Console'; font-size:12px;background:#475A5F;color:#FFFFFF;" id="ss_basic_v2ray_json" name="ss_basic_v2ray_json" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" title=""></textarea>
													</td>
												</tr>
												<tr id="v2ray_binary_update_tr" style="display: none;">
													<th width="35%">其它</th>
													<td>
														<a type="button" class="ss_btn" style="cursor:pointer" onclick="ss_binary_update(2)">更新XRay程序</V2R></a>
													</td>
												</tr>
												<tr id="ss_naive_binary_update_tr" style="display: none;">
													<th width="35%">其它</th>
													<td>
														<a type="button" class="ss_btn" style="cursor:pointer" onclick="ss_binary_update(3)">更新NaiveProxy程序</a>
													</td>
												</tr>	
												<tr id="ss_hysteria_binary_update_tr" style="display: none;">
													<th width="35%">其它</th>
													<td>
														<a type="button" class="ss_btn" style="cursor:pointer" onclick="ss_binary_update(4)">更新Hysteria2程序</a>
													</td>
												</tr>	
											</table>
										</div>
										<!-- 节点面板 -->
										<div id="ss_node_list_table_th" style="display: none; height:40px;margin:-1px 0px 0px 0px">
											<table style="margin:-1px 0px 0px 0px;table-layout:fixed;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable1">
												<tr height="40px">
													<th style="width:40px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(16)">模式</a></th>
													<th style="width:150px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(17)">节点名称</a></th>
													<th style="width:120px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(18)">服务器地址</a></th>
													<th style="width:61px;">端口</th>
													<th style="width:86px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(19)">延迟评分</a></th>
													<th style="width:33px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(21)">编辑</a></th>
													<th style="width:33px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(22)">删除</a></th>
													<th style="width:65px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(23)">使用</a></th>
												</tr>
											</table>
										</div>
										<div id="ss_node_list_table_td" style="display: none;">
											<div id="ss_node_list_table_main" style="width:748px;">
												<table id="ss_node_list_table" style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable1">
													<tr id="hide_when_folw" height="40px" style="display: none;">
														<th style="width:40px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(16)">模式</a></th>
														<th style="width:150px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(17)">节点名称</a></th>
														<th style="width:120px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(18)">服务器地址</a></th>
														<th style="width:61px;">端口</th>
														<th style="width:86px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(19)">延迟评分</a></th>
														<th style="width:33px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(21)">编辑</a></th>
														<th style="width:33px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(22)">删除</a></th>
														<th style="width:65px;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(23)">使用</a></th>
													</tr>
												</table>
											</div>
										</div>
										<div id="ss_node_list_table_btn" style="display: none;width: 100%;">
											<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<tr>
													<th style="width:20%;">延迟测试</th>
													<td>
														<select id="ssconf_basic_test_node" name="ssconf_basic_test_node" style="width:124px;margin:0px 0px 0px 2px;" class="input_option">
														</select>
														<select id="ssconf_basic_test_domain" name="ssconf_basic_test_domain" style="width:160px;margin:0px 0px 0px 2px;" class="input_option">
															<option class="content_input_fd" value="https://www.google.com.hk/">google</option>
															<option class="content_input_fd" value="https://www.gstatic.com/generate_204">gstatic</option>
														</select>
														<input class="ss_btn" style="cursor:pointer;" onClick="remove_test()" type="button" value="清空结果"/>
														<input class="ss_btn" style="cursor:pointer;" onClick="web_test()" type="button" value="开始测试"/>
													</td>
												</tr>
											</table>
											<table>
												<tr>
													<td>
														<div id="node_return_button" class="apply_gen" style="margin-left: 188px;;float: left;">
															<input id="add_ss_node" class="button_gen" onClick="Add_profile()" type="button" value="添加节点"/>
														</div>
													</td>
												</tr>
											</table>
										</div>
										<!--=====tablet_2=====-->
										<div id="tablet_2" style="display: none;">
											<table style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<tr id="dns_plan_china">
													<th width="20%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(25)">选择中国DNS</a></th>
													<td id="dns_plan_china_td">
														<select id="ss_dns_china" name="ss_dns_china" class="input_option" onclick="update_visibility();" >
															<option value="1" selected>运营商DNS【自动获取】</option>
															<option value="2">阿里DNS1【223.5.5.5】</option>
															<option value="3">阿里DNS2【223.6.6.6】</option>
															<option value="4">114DNS1【114.114.114.114】</option>
															<option value="5">114DNS1【114.114.115.115】</option>
															<option value="6">cnnic DNS【1.2.4.8】</option>
															<option value="7">cnnic DNS【210.2.4.8】</option>
															<option value="8">oneDNS1【117.50.11.11】</option>
															<option value="9">oneDNS2【117.50.22.22】</option>
															<option value="10">百度DNS【180.76.76.76】</option>
															<option value="11">DNSpod DNS【119.29.29.29】</option>
															<option value="12">自定义</option>
															<option value="13">SmartDNS</option>
														</select>
														<input type="text" class="input_ss_table" id="ss_dns_china_user" name="ss_dns_china_user" value="">
													</td>
												</tr>
												<tr id="dns_plan_foreign">
													<th width="20%">
														选择外国DNS&nbsp;&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(26)"><font color="#ffcc00"><u>[说明]</u></font></a>
													</th>
													<td>
														<div class="ss-foreign-dns-controls">
															<select id="ss_foreign_dns" name="ss_foreign_dns" class="input_option" onclick="update_visibility();" >
																<option value="3" selected="">dns2socks</option>
																<option value="4">ss-tunnel</option>
																<option value="1">cdns</option>
																<option value="5">chinadns1</option>
																<option value="2">chinadns2</option>
																<option value="6">https_dns_proxy</option>
																<option value="7">v2ray_dns</option>
																<option value="8">直连</option>
																<option value="9">SmartDNS</option>
																<option value="10">ChinaDNS-NG</option>
															</select>
															<input type="text" class="input_ss_table" id="ss_dns2socks_user" name="ss_dns2socks_user" style="width:160px" placeholder="需端口号如：8.8.8.8:53" value="8.8.8.8:53">
															<input type="text" class="input_ss_table" id="ss_chinadns1_user" name="ss_chinadns1_user" style="width:160px" placeholder="需端口号如：8.8.8.8:53" value="8.8.8.8:53">
															<input type="text" class="input_ss_table" id="ss_chinadns_user" name="ss_chinadns_user" style="width:160px" placeholder="需端口号如：8.8.8.8:53" value="8.8.8.8:53">
															<input type="text" class="input_ss_table" id="ss_sstunnel_user" name="ss_sstunnel_user" style="width:160px" placeholder="需端口号如：8.8.8.8:53" value="8.8.8.8:53">
															<input type="text" class="input_ss_table" id="ss_direct_user" name="ss_direct_user" style="width:160px" placeholder="需端口号如：8.8.8.8#53" value="8.8.8.8#53">
														</div>
														<span id="ss_foreign_dns_note"></span>
													</td>
												</tr>
												<tr>
													<th>DNS劫持（原chromecast功能）&nbsp;&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(106)"><font color="#ffcc00"><u>[说明]</u></font></a></th>
													<td>
														<select id="ss_basic_dns_hijack" name="ss_basic_dns_hijack" class="input_option" onchange="verifyFields(this, 1);">
															<!-- "关闭"选项已移除：不劫持会让黑白名单里的【域名】条目直接失效
															     （域名条目靠客户端经本机 dnsmasq 解析时写入 ipset 才生效），
															     属于把插件的核心分流能力关掉，没有保留的理由。
															     后端仍保留 0 的分支做兜底，且启动时会把历史存量的 0 迁移成 1。 -->
															<option value="1" selected>默认（劫持UDP/53，原chromecast）</option>
															<option value="2">全部（强制TCP/UDP-53+拦DoT/DoH，白名单可靠）</option>
														</select>
													</td>
												</tr>
												<tr>
													<th>节点域名解析DNS服务器&nbsp;&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(107)"><font color="#ffcc00"><u>[说明]</u></font></a></th>
													<td>
														<select id="ss_basic_server_resolver" name="ss_basic_server_resolver" class="input_option" onclick="update_visibility();" >
															<option value="1" selected>运营商DNS【自动获取】</option>
															<option value="2">阿里DNS1【223.5.5.5】</option>
															<option value="3">阿里DNS2【223.6.6.6】</option>
															<option value="4">114DNS1【114.114.114.114】</option>
															<option value="5">114DNS1【114.114.115.115】</option>
															<option value="6">cnnic DNS【1.2.4.8】</option>
															<option value="7">cnnic DNS【210.2.4.8】</option>
															<option value="8">oneDNS1【117.50.11.11】</option>
															<option value="9">oneDNS2【117.50.22.22】</option>
															<option value="10">百度DNS【180.76.76.76】</option>
															<option value="11">DNSpod DNS【119.29.29.29】</option>
															<option value="12">自定义</option>
														</select>
														<input type="text" class="input_ss_table" id="ss_basic_server_resolver_user" name="ss_basic_server_resolver_user" value="">
													</td>
												</tr>
												<tr>
												<th width="20%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(34)">自定义dnsmasq</a></th>
													<td>
														<textarea placeholder="# 填入自定义的dnsmasq设置，一行一个
# 例如hosts设置：
address=/weibo.com/2.2.2.2
# 防DNS劫持设置：
bogus-nxdomain=220.250.64.18" rows="8" style="width:99%; font-family:'Lucida Console'; font-size:12px;background:#475A5F;color:#FFFFFF;" id="ss_dnsmasq" name="ss_dnsmasq" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" title=""></textarea>
													</td>
												</tr>
												<tr>
													<th>同步UDP与TCP&nbsp;&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(116)"><font color="#ffcc00"><u>[说明]</u></font></a></th>
													<td>
														<select id="ss_basic_udp_sync" name="ss_basic_udp_sync" class="input_option" onchange="verifyFields(this, 1);update_visibility();">
															<option value="0">关闭</option>
															<option value="2">仅代理QUIC（低负载，推荐）</option>
															<option value="3">仅代理QUIC+Game（QUIC+自定义UDP端口）</option>
															<option value="1">全量UDP（高负载）</option>
														</select>
													</td>
												</tr>
												<tr id="ss_basic_udp_sync_game_port_tr" style="display:none;">
													<th>Game Port（UDP）<br><span style="color:#FC0;font-weight:normal;">仅QUIC+Game档生效</span></th>
													<td>
														<input type="text" id="ss_basic_udp_sync_game_port" name="ss_basic_udp_sync_game_port" class="input_option" style="width:250px;margin:0px 0px 0px 2px;" maxlength="100" placeholder="如 7777-7778,27015" autocomplete="off" onblur="check_game_port_input();" />
														<span id="ss_basic_udp_sync_game_port_tip" style="display:none;color:#F46;">格式错误：应如 27015,7777-7778（端口1-65535，总槽位≤15，段占2；不能有前导零，写 7777 而非 07777）</span>
														<span style="color:#FC0;">游戏的UDP端口，单端口或端口段（-），多个用,隔开；按国内外分流，境外服务器走代理。443无需填写（QUIC已默认代理，重复填写亦无碍）</span>
													</td>
												</tr>
												<tr>
											<th width="20%">Hysteria2设定&nbsp;&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(118)"><font color="#ffcc00"><u>[说明]</u></font></a><br><span style="color:#FC0;font-weight:normal;">默认不填</span></th>
													<td>
																							<!-- 改成 grid：原先用 <span style="width:70px"> + <br> 拼伪两栏，各行控件宽度不同时
									     纵向对不齐（真机问题3）。现在标签列与控件列各自成列，天然对齐。
									     gecko「包大小」那行原来是 <br id=..._gecko_br> + <span> 两个元素分别 showhide，
									     grid 下 <br> 无意义，已合并为「标签列+控件列」一行，JS 改为显隐标签列。 -->
									<div class="ss-hy2">
										<div class="ss-hy2-row">
											<span class="ss-hy2-k">混淆</span>
											<span class="ss-hy2-v">
												<select id="ss_basic_hy2_obfs_type" name="ss_basic_hy2_obfs_type" class="input_option" style="width:155px;" onchange="updateHy2GlobalForm();">
													<option value="">关闭</option>
													<option value="salamander">salamander</option>
													<option value="gecko">gecko</option>
												</select>
											</span>
										</div>
										<div id="ss_basic_hy2_obfs_password_span" class="ss-hy2-row" style="display:none;">
											<span class="ss-hy2-k">密码</span>
											<span class="ss-hy2-v">
												<input type="text" class="input_ss_table" id="ss_basic_hy2_obfs_password" name="ss_basic_hy2_obfs_password" style="width:190px;" placeholder="混淆密码" value="">
											</span>
										</div>
										<div id="ss_basic_hy2_gecko_span" class="ss-hy2-row" style="display:none;">
											<span class="ss-hy2-k">包大小</span>
											<span class="ss-hy2-v">
												<input type="text" class="input_ss_table" id="ss_basic_hy2_gecko_min" name="ss_basic_hy2_gecko_min" style="width:60px;" placeholder="512" value="">
												<label>-</label>
												<input type="text" class="input_ss_table" id="ss_basic_hy2_gecko_max" name="ss_basic_hy2_gecko_max" style="width:60px;" placeholder="1200" value="">
											</span>
										</div>
										<div class="ss-hy2-row">
											<span class="ss-hy2-k">拥塞控制</span>
											<span class="ss-hy2-v ss-hy2-nowrap">
												<select id="ss_basic_hy2_congestion_type" name="ss_basic_hy2_congestion_type" class="input_option" style="width:175px;" onchange="updateHy2GlobalForm();">
													<option value="">默认(bbr + standard)</option>
													<option value="bbr">bbr</option>
													<option value="reno">reno</option>
												</select>
												<span id="ss_basic_hy2_bbr_profile_span" class="ss-hy2-sub" style="display:none;">
													<label>BBR模式</label>
													<select id="ss_basic_hy2_bbr_profile" name="ss_basic_hy2_bbr_profile" class="input_option" style="width:140px;">
														<option value="standard">standard</option>
														<option value="conservative">conservative</option>
														<option value="aggressive">aggressive</option>
													</select>
												</span>
											</span>
										</div>
										<div class="ss-hy2-row">
											<span class="ss-hy2-k">带宽</span>
											<span class="ss-hy2-v">
												<label>上行</label>
												<input type="text" class="input_ss_table" id="ss_basic_hy2_bandwidth_up_value" name="ss_basic_hy2_bandwidth_up_value" style="width:70px;" placeholder="100" value="">
												<label>mbps</label>
												<label class="ss-hy2-gap">下行</label>
												<input type="text" class="input_ss_table" id="ss_basic_hy2_bandwidth_down_value" name="ss_basic_hy2_bandwidth_down_value" style="width:70px;" placeholder="200" value="">
												<label>mbps</label>
											</span>
										</div>
										<div class="ss-hy2-row">
											<span class="ss-hy2-k">UDP</span>
											<span class="ss-hy2-v ss-hy2-switch-row">
												<select id="ss_basic_hy2_udp" name="ss_basic_hy2_udp" class="input_option ss-hy2-switch" onchange="verifyFields(this, 1);">
													<option value="0" selected>关闭</option>
													<option value="1">打开</option>
												</select>
												<label class="ss-hy2-switch-note" for="ss_basic_hy2_udp">启用透明 UDP 代理，为「同步UDP与TCP」支持</label>
											</span>
										</div>
										<div class="ss-hy2-row">
											<span class="ss-hy2-k">fastOpen</span>
											<span class="ss-hy2-v">
												<select id="ss_basic_hy2_fast_open" name="ss_basic_hy2_fast_open" class="input_option ss-hy2-switch">
													<option value="0">关闭</option>
													<option value="1" selected>打开</option>
												</select>
											</span>
										</div>
										<div class="ss-hy2-row">
											<span class="ss-hy2-k">lazy</span>
											<span class="ss-hy2-v">
												<select id="ss_basic_hy2_lazy" name="ss_basic_hy2_lazy" class="input_option ss-hy2-switch">
													<option value="0">关闭</option>
													<option value="1" selected>打开</option>
												</select>
											</span>
										</div>
									</div>
									<textarea id="ss_basic_hy2_global_json" name="ss_basic_hy2_global_json" style="display:none;"></textarea>
													</td>
												</tr>
											</table>
										</div>
										<!--=====tablet_3=====-->
										<div id="tablet_3" style="display: none;">
											<table style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<tr id="ss_wan_white_ip_tr">
													<th width="20%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(38)">IP/CIDR白名单</a><br>
														<br>
														<font color="#ffcc00">添加不需要走代理的外网ip地址</font>
													</th>
													<td>
														<textarea placeholder="# 填入不需要走代理的外网ip地址，一行一个，格式（IP/CIDR）如下
2.2.2.2
3.3.3.3
4.4.4.4/24" cols="50" rows="5" id="ss_wan_white_ip" name="ss_wan_white_ip" style="width:99%; font-family:'Lucida Console'; font-size:12px;background:#475A5F;color:#FFFFFF;" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
													</td>
												</tr>
												<tr id="ss_wan_white_domain_tr">
													<th width="20%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(39)">域名白名单</a><br>
														<br>
														<font color="#ffcc00">添加不需要走代理的域名</font>
													</th>
													<td>
														<textarea placeholder="# 填入不需要走代理的域名，一行一个，格式如下：
google.com
facebook.com
# 需要清空电脑DNS缓存，才能立即看到效果。" cols="50" rows="5" id="ss_wan_white_domain" name="ss_wan_white_domain" style="width:99%; font-family:'Lucida Console'; font-size:12px;background:#475A5F;color:#FFFFFF;" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
													</td>
												</tr>
												<tr id="ss_wan_black_ip_tr">
													<th width="20%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(40)">IP/CIDR黑名单</a><br>
														<br>
														<font color="#ffcc00">添加需要强制走代理的外网ip地址</font>
													</th>
													<td>
														<textarea placeholder="# 填入需要强制走代理的外网ip地址，一行一个，格式（IP/CIDR）如下：
5.5.5.5
6.6.6.6
7.7.7.7/8" cols="50" rows="5" id="ss_wan_black_ip" name="ss_wan_black_ip" style="width:99%; font-family:'Lucida Console'; font-size:12px;background:#475A5F;color:#FFFFFF;" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
													</td>
												</tr>
												<tr id="ss_wan_black_domain_tr">
													<th width="20%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(41)">域名黑名单</a><br>
														<br>
														<font color="#ffcc00">添加需要强制走代理的域名</font>
													</th>
													<td>
														<textarea placeholder="# 填入需要强制走代理的域名，一行一个，格式如下：
baidu.com
taobao.com
# 需要清空电脑DNS缓存，才能立即看到效果。" cols="50" rows="5" id="ss_wan_black_domain" name="ss_wan_black_domain" style="width:99%; font-family:'Lucida Console'; font-size:12px;background:#475A5F;color:#FFFFFF;" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
													</td>
												</tr>
											</table>
										</div>
										<div id="tablet_4" style="display: none;">
											<table style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" >
												<tr  id="gfw_number">
													<th id="gfw_nu1" width="35%">gfwlist域名数量</th>
													<td id="gfw_nu2">
															<% nvram_get("ipset_numbers"); %>&nbsp;条，最后更新版本：
															<a href="https://github.com/qxzg/Actions/tree/master/fancyss_rules/gfwlist.conf" target="_blank">
																<i><% nvram_get("update_ipset"); %></i>
														</a>
													</td>
												</tr>
												<tr  id="chn_number">
													<th id="chn_nu1" width="35%">大陆白名单IP段数量</th>
												<td id="chn_nu2">
													<p>
														<% nvram_get("chnroute_numbers"); %>&nbsp;行，最后更新版本：
														<a href="https://github.com/qxzg/Actions/tree/master/fancyss_rules/chnroute.txt" target="_blank">
															<i><% nvram_get("update_chnroute"); %></i>
														</a>
													</p>
												</td>
												</tr>
												<tr  id="cdn_number">		
													<th id="cdn_nu1" width="35%">国内域名数量（cdn名单）</th>		
													<td id="cdn_nu2">		
														<p>		
														<% nvram_get("cdn_numbers"); %>&nbsp;条，最后更新版本：		
															<a href="https://github.com/qxzg/Actions/tree/master/fancyss_rules/cdn.txt" target="_blank">		
																<i><% nvram_get("update_cdn"); %></i>		
															</a>		
														</p>		
													</td>		
												</tr>
												<tr id="update_rules">
													<th width="35%"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(44)">规则定时更新任务</a></th>
													<td>
														<select id="ss_basic_rule_update" name="ss_basic_rule_update" class="input_option" onchange="update_visibility();" >
															<option value="0">禁用</option>
															<option value="1">开启</option>
														</select>
														<select id="ss_basic_rule_update_time" name="ss_basic_rule_update_time" class="input_option" title="选择规则列表自动更新时间，更新后将自动重启SS" onchange="update_visibility();" >
															<option value="0">00:00点</option>
															<option value="1">01:00点</option>
															<option value="2">02:00点</option>
															<option value="3">03:00点</option>
															<option value="4">04:00点</option>
															<option value="5">05:00点</option>
															<option value="6">06:00点</option>
															<option value="7">07:00点</option>
															<option value="8">08:00点</option>
															<option value="9">09:00点</option>
															<option value="10">10:00点</option>
															<option value="11">11:00点</option>
															<option value="12">12:00点</option>
															<option value="13">13:00点</option>
															<option value="14">14:00点</option>
															<option value="15">15:00点</option>
															<option value="16">16:00点</option>
															<option value="17">17:00点</option>
															<option value="18">18:00点</option>
															<option value="19">19:00点</option>
															<option value="20">20:00点</option>
															<option value="21">21:00点</option>
															<option value="22">22:00点</option>
															<option value="23">23:00点</option>
														</select>
															&nbsp;
															<a id="update_choose">
																<input type="checkbox" id="ss_basic_gfwlist_update" title="选择此项应用gfwlist自动更新">gfwlist
																<input type="checkbox" id="ss_basic_chnroute_update">chnroute
																<input type="checkbox" id="ss_basic_cdn_update">CDN
															</a>
															<a type="button" class="ss_btn" style="cursor:pointer" onclick="updatelist(1)">保存设置</a>
															<a type="button" class="ss_btn" style="cursor:pointer" onclick="updatelist(2)">立即更新</a>
													</td>
												</tr>
											</table>
										</div>
										<!--====LAN ACL=====-->
										<div id="tablet_5" style="display: none;">
											<table id="ACL_table" style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" >
													<tr>
														<th style="width:180px;">主机IP地址</th>
														<th style="width:160px;">主机别名</th>
														<th style="width:160px;">访问控制</th>
														<th style="width:160px;">目标端口</th>
														<th style="width:60px;">添加/删除</th>
													</tr>
													<tr>
												<td class="ss-acl-ip-cell">
													<div class="ss-acl-ip-control">
														<input type="text" maxlength="15" class="input_15_table" id="ss_acl_ip" name="ss_acl_ip" align="left" onkeypress="return validator.isIPAddr(this, event)" autocomplete="off" onClick="hideClients_Block();" autocorrect="off" autocapitalize="off">
												<span class="ss-acl-ip-trigger"><img id="pull_arrow" class="ss-acl-ip-arrow" src="images/arrow-down.gif" onclick="pullLANIPList(this);" title="<#select_IP#>" alt=""></span>
													</div>
													<div id="ClientList_Block" class="clientlist_dropdown"></div>
														</td>
														<td>
															<input type="text" id="ss_acl_name" name="ss_acl_name" class="input_ss_table" maxlength="50" style="width:140px;" placeholder="" />
														</td>
														<td>
															<select id="ss_acl_mode" name="ss_acl_mode" style="width:160px;margin:0px 0px 0px 2px;" class="input_option" onchange="set_mode_1(this);">
																<option value="0">不通过代理</option>
																<option value="1">gfwlist模式</option>
																<option value="2">大陆白名单模式</option>
																<option value="3">游戏模式</option>
																<option value="5">全局代理模式</option>
																<option value="6">回国模式</option>
															</select>
														</td>
														<td>
															<select id="ss_acl_port" name="ss_acl_port" style="width:100px;margin:0px 0px 0px 2px;" class="input_option">
																<option value="80,443">80,443</option>
																<option value="22,80,443">22,80,443</option>
																<option value="all">all</option>
															</select>
														</td>
														<td style="width:66px">
															<input style="margin-left: 6px;margin: -3px 0px -5px 6px;" type="button" class="add_btn" onclick="addTr()" value="" />
														</td>
													</tr>
											</table>
											<div id="ACL_note">
											<div><i>1&nbsp;&nbsp;默认状态下，所有局域网的主机都会走当前节点的模式（主模式），相当于即不启用局域网访问控制。</i></div>
											<div><i>2&nbsp;&nbsp;当你添加了主机，并设置默认规则为不通过SS，则只有添加的主机才会走相应的模式。</i></div>
											<div><i>3&nbsp;&nbsp;当你添加了主机，并设置默认规则为当前节点的模式，除了添加的主机才会走相应的模式，未添加的主机会走默认规则的模式。</i></div>
											<div><i>4&nbsp;&nbsp;如果使用了负载均衡，因为它不支持udp，所以不能控制单个主机走游戏模式。</i></div>
											</div>
										</div>
										<!--===== addon =====-->
										<div id="tablet_6" style="display: none;">
											<table style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" >
												<tr>
													<th style="width:20%;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(24)">导出SS配置</a></th>
													<td>
														<input type="button" class="ss_btn" style="cursor:pointer;" onclick="download_SS_node();" value="导出配置">
														<input type="button" class="ss_btn" style="cursor:pointer;" onclick="remove_SS_node();" value="清空配置">
													</td>
												</tr>
												<tr>
													<th style="width:20%;"><a class="hintstyle" href="javascript:void(0);" onclick="openssHint(24)">恢复SS配置（支持ss/ssr的json节点）</a></th>
													<td>
														<input style="color:#FFCC00;*color:#000;width: 200px;" id="ss_file" type="file" name="file"/>
														<img id="loadingicon" style="margin-left:5px;margin-right:5px;display:none;" src="/images/InternetScan.gif"/>
														<span id="ss_file_info" style="display:none;">完成</span>
														<input type="button" class="ss_btn" style="cursor:pointer;" onclick="upload_ss_backup();" value="恢复配置"/>
													</td>
												</tr>
												<tr>
													<th	width="20%">插件定时重启设定（实验）</th>
													<td>
														<select	id="ss_reboot_check" name="ss_reboot_check"	style="margin:0px 0px 0px 2px;"	class="input_option" onchange="status_onchange();" >
															<option	value="0" selected>关闭</option>
															<option	value="1">每天</option>
															<option	value="2">每周</option>
															<option	value="3">每月</option>
															<option	value="4">每隔</option>
															<option	value="5">自定义</option>
														</select>
														<span id="_ss_basic_week_pre" style="display: none;">
															<select	id="ss_basic_week" name="ss_basic_week"	style="margin:0px 0px 0px 2px;"	class="input_option" >
																<option	value="1">一</option>
																<option	value="2">二</option>
																<option	value="3">三</option>
																<option	value="4">四</option>
																<option	value="5">五</option>
																<option	value="6">六</option>
																<option	value="7">日</option>
															</select>
														</span>
														<span id="_ss_basic_day_pre" style="display: none;">
															<select	id="ss_basic_day" name="ss_basic_day" style="margin:0px	0px	0px	2px;" class="input_option" >
																<option	value="1">1日</option>
																<option	value="2">2日</option>
																<option	value="3">3日</option>
																<option	value="4">4日</option>
																<option	value="5">5日</option>
																<option	value="6">6日</option>
																<option	value="7">7日</option>
																<option	value="8">8日</option>
																<option	value="9">9日</option>
																<option	value="10">10日</option>
																<option	value="11">11日</option>
																<option	value="12">12日</option>
																<option	value="13">13日</option>
																<option	value="14">14日</option>
																<option	value="15">15日</option>
																<option	value="16">16日</option>
																<option	value="17">17日</option>
																<option	value="18">18日</option>
																<option	value="19">19日</option>
																<option	value="20">20日</option>
																<option	value="21">21日</option>
																<option	value="22">22日</option>
																<option	value="23">23日</option>
																<option	value="24">24日</option>
																<option	value="25">25日</option>
																<option	value="26">26日</option>
																<option	value="27">27日</option>
																<option	value="28">28日</option>
																<option	value="29">29日</option>
																<option	value="30">30日</option>
																<option	value="31">31日</option>
															</select>
														</span>
														<span id="_ss_basic_inter_pre" style="display: none;">
															<select	id="ss_basic_inter_min"	name="ss_basic_inter_min" style="margin:0px	0px	0px	2px;" class="input_option" >
																<option	value="1">1</option>
																<option	value="5">5</option>
																<option	value="10">10</option>
																<option	value="15">15</option>
																<option	value="20">20</option>
																<option	value="25">25</option>
																<option	value="30">30</option>
															</select>
															<select	id="ss_basic_inter_hour" name="ss_basic_inter_hour"	style="display:	none; margin:0px 0px 0px 2px;" class="input_option"	>
																<option	value="1">1</option>
																<option	value="2">2</option>
																<option	value="3">3</option>
																<option	value="4">4</option>
																<option	value="5">5</option>
																<option	value="6">6</option>
																<option	value="7">7</option>
																<option	value="8">8</option>
																<option	value="9">9</option>
																<option	value="10">10</option>
																<option	value="11">11</option>
																<option	value="12">12</option>
															</select>
															<select	id="ss_basic_inter_day"	name="ss_basic_inter_day" style="display: none;	margin:0px 0px 0px 2px;" class="input_option" >
																<option	value="1">1</option>
																<option	value="2">2</option>
																<option	value="3">3</option>
																<option	value="4">4</option>
																<option	value="5">5</option>
																<option	value="6">6</option>
																<option	value="7">7</option>
																<option	value="8">8</option>
																<option	value="9">9</option>
																<option	value="10">10</option>
																<option	value="11">11</option>
																<option	value="12">12</option>
																<option	value="13">13</option>
																<option	value="14">14</option>
																<option	value="15">15</option>
																<option	value="16">16</option>
																<option	value="17">17</option>
																<option	value="18">18</option>
																<option	value="19">19</option>
																<option	value="20">20</option>
																<option	value="21">21</option>
																<option	value="22">22</option>
																<option	value="23">23</option>
																<option	value="24">24</option>
																<option	value="25">25</option>
																<option	value="26">26</option>
																<option	value="27">27</option>
																<option	value="28">28</option>
																<option	value="29">29</option>
																<option	value="30">30</option>
															</select>
															<select	id="ss_basic_inter_pre"	name="ss_basic_inter_pre" style="margin:0px	0px	0px	2px;" class="input_option" onchange="inter_pre_onchange();"	>
																<option	value="1">分钟</option>
																<option	value="2">小时</option>
																<option	value="3">天</option>
															</select>
														</span>
														<span id="_ss_basic_custom_pre"	style="display:	none;">
															<input type="text" id="ss_basic_custom"	name="ss_basic_custom" class="input_6_table" maxlength="50"	title="填写说明：&#13;此处填写1-23之间任意小时&#13;小时间用逗号间隔，如：&#13;当天的8点、10点、15点则填入：8,10,15" placeholder="8,10,15" style="width:150px;" /> 小时
														</span>
														<span id="_ss_basic_time_pre" style="display: none;">
															<select	id="ss_basic_time_hour"	name="ss_basic_time_hour" style="margin:0px	0px	0px	2px;" class="input_option" >
																<option	value="0">0时</option>
																<option	value="1">1时</option>
																<option	value="2">2时</option>
																<option	value="3">3时</option>
																<option	value="4">4时</option>
																<option	value="5">5时</option>
																<option	value="6">6时</option>
																<option	value="7">7时</option>
																<option	value="8">8时</option>
																<option	value="9">9时</option>
																<option	value="10">10时</option>
																<option	value="11">11时</option>
																<option	value="12">12时</option>
																<option	value="13">13时</option>
																<option	value="14">14时</option>
																<option	value="15">15时</option>
																<option	value="16">16时</option>
																<option	value="17">17时</option>
																<option	value="18">18时</option>
																<option	value="19">19时</option>
																<option	value="20">20时</option>
																<option	value="21">21时</option>
																<option	value="22">22时</option>
																<option	value="23">23时</option>
															</select>
															<select	id="ss_basic_time_min" name="ss_basic_time_min"	style="margin:0px 0px 0px 2px;"	class="input_option" >
																<option	value="0">0分</option>
																<option	value="1">1分</option>
																<option	value="2">2分</option>
																<option	value="3">3分</option>
																<option	value="4">4分</option>
																<option	value="5">5分</option>
																<option	value="6">6分</option>
																<option	value="7">7分</option>
																<option	value="8">8分</option>
																<option	value="9">9分</option>
																<option	value="10">10分</option>
																<option	value="11">11分</option>
																<option	value="12">12分</option>
																<option	value="13">13分</option>
																<option	value="14">14分</option>
																<option	value="15">15分</option>
																<option	value="16">16分</option>
																<option	value="17">17分</option>
																<option	value="18">18分</option>
																<option	value="19">19分</option>
																<option	value="20">20分</option>
																<option	value="21">21分</option>
																<option	value="22">22分</option>
																<option	value="23">23分</option>
																<option	value="24">24分</option>
																<option	value="25">25分</option>
																<option	value="26">26分</option>
																<option	value="27">27分</option>
																<option	value="28">28分</option>
																<option	value="29">29分</option>
																<option	value="30">30分</option>
																<option	value="31">31分</option>
																<option	value="32">32分</option>
																<option	value="33">33分</option>
																<option	value="34">34分</option>
																<option	value="35">35分</option>
																<option	value="36">36分</option>
																<option	value="37">37分</option>
																<option	value="38">38分</option>
																<option	value="39">39分</option>
																<option	value="40">40分</option>
																<option	value="41">41分</option>
																<option	value="42">42分</option>
																<option	value="43">43分</option>
																<option	value="44">44分</option>
																<option	value="45">45分</option>
																<option	value="46">46分</option>
																<option	value="47">47分</option>
																<option	value="48">48分</option>
																<option	value="49">49分</option>
																<option	value="50">50分</option>
																<option	value="51">51分</option>
																<option	value="52">52分</option>
																<option	value="53">53分</option>
																<option	value="54">54分</option>
																<option	value="55">55分</option>
																<option	value="56">56分</option>
																<option	value="57">57分</option>
																<option	value="58">58分</option>
																<option	value="59">59分</option>
															</select>
														</span>
														<span id="_ss_basic_send_text" style="display: none;">重启插件</span>
														<a type="button" class="ss_btn" style="cursor:pointer" onclick="set_cron(1)">保存设置</a>
													</td>
												</tr>
												<tr>
													<th>插件触发重启设定（实验）</th>
													<td>
														<select	id="ss_basic_tri_reboot_time" name="ss_basic_tri_reboot_time" style="margin:0px	0px	0px	2px;" class="input_option" onclick="update_visibility();">
															<option	value="0" selected>关闭</option>
															<option	value="2">每隔2分钟</option>
															<option	value="5">每隔5分钟</option>
															<option	value="10">每隔10分钟</option>
															<option	value="15">每隔15分钟</option>
															<option	value="20">每隔20分钟</option>
															<option	value="25">每隔25分钟</option>
															<option	value="30">每隔30分钟</option>
														</select>
														<span id="ss_basic_tri_reboot_time_note">解析服务器IP，如果发生变更，则重启</span>
														<select	id="ss_basic_tri_reboot_policy" name="ss_basic_tri_reboot_policy" style="margin:0px 0px 0px 2px;" class="input_option" >
															<option	value="1" selected>整个插件</option>
															<option	value="2">dnsmasq</option>
														</select>
														<a type="button" class="ss_btn" style="cursor:pointer" onclick="set_cron(2)">保存设置</a>
													</td>
												</tr>
												<tr>
													<th>替换为dnsmasq-fastlookup&nbsp;&nbsp;<a class="hintstyle" href="javascript:void(0);" onclick="openssHint(105)"><font color="#ffcc00"><u>[说明]</u></font></a></th>
													<td>
														<select	id="ss_basic_dnsmasq_fastlookup" name="ss_basic_dnsmasq_fastlookup" style="margin:0px 0px 0px 2px;" class="input_option" onclick="update_visibility();">
															<option	value="0" selected>【0】不替换</option>
															<option	value="1">【1】插件开启后替换，插件关闭后恢复原版dnsmasq</option>
															<option	value="2">【2】在用到cdn.conf时替换，插件关闭后恢复原版dnsmasq</option>
															<option	value="3">【3】插件开启后替换，插件关闭后保持替换，不恢复原版dnsmasq</option>
														</select>
													</td>
												</tr>
											</table>
										</div>
										<!--log_content-->
										<div id="tablet_7" style="display: none;">
												<div id="log_content" style="margin-top:-1px;display:none;overflow:hidden;outline: 1px solid #222;">
													<textarea cols="63" rows="36" wrap="on" readonly="readonly" id="log_content1" style="width:97%; padding-left:4px; padding-right:37px; border:0px solid #222; font-family:'Lucida Console'; font-size:11px; background:#475A5F; color:#FFFFFF;outline:none;overflow-x:hidden;" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>
												</div>
										</div>		

										<div class="apply_gen" id="loading_icon">
											<img id="loadingIcon" style="display:none;" src="/images/InternetScan.gif">
										</div>
										<div id="apply_button" class="apply_gen">
											<input class="button_gen" type="button" onclick="save()" value="保存&应用">
											<!--<input class="button_gen" type="button" onclick="save(1)" value="保存">-->
										</div>
										<div id="warn_msg_1" style="display: none;text-align:center; line-height: 4em;"><i></i></div>
										<div id="warn_msg_2" style="display: none;text-align:center; line-height: 4em;"><i></i></div>
									</td>
								</tr>
							</table>
						</div>
					</td>
				</tr>
			</table>
		<!--=====End of Main Content=====-->
		</td>
		<td width="10" align="center" valign="top"></td>
	</tr>
</table>
</form>
<div id="footer"></div>
</body>
</html>
