<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta HTTP-EQUIV="Pragma" CONTENT="no-cache"/>
<meta HTTP-EQUIV="Expires" CONTENT="-1"/>
<link rel="shortcut icon" href="images/favicon.png"/>
<link rel="icon" href="images/favicon.png"/>
<title>软件中心 - Xray 本地聚合</title>

<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<link rel="stylesheet" type="text/css" href="css/element.css">
<link rel="stylesheet" type="text/css" href="/res/shadowsocks.css">

<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/validator.js"></script>
<script type="text/javascript" src="/js/jquery.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/switcherplugin/jquery.iphone-switch.js"></script>
<script type="text/javascript" src="/client_function.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script type="text/javascript" src="/res/ss-menu.js"></script>
<script type="text/javascript" src="/dbconf?p=ss&v=Wed, 04 Feb 2026 17:09:33 +0800(201072 secs since boot)"></script>

<style>
	.xagg_note { color:#FFCC00; }
	.small_btn { height: 26px; line-height: 26px; padding: 0 10px; border-radius: 4px; cursor: pointer; }
	.small_btn:active { transform: translateY(1px); }

	.mono {
		width: 99%;
		font-family: 'Lucida Console', Consolas, monospace;
		font-size: 12px;
		background: #111;
		color: #fff;
		border: 1px solid #000;
		padding: 8px 10px;
		outline: none;
	}

	.badge { display:inline-block; padding:2px 8px; border-radius:10px; background:#2b3a40; color:#fff; font-size:12px; margin-left:8px; }
	.badge_ok { background:#2b6b3a; }
	.badge_warn { background:#7a5b12; }

	.tbl_sm td, .tbl_sm th { padding: 6px 8px; }
	.chk { transform: scale(1.1); }

	/* 列表滚动 */
	.xagg-table-wrap{
		max-height: 420px;
		overflow-y: auto;
		overflow-x: hidden;
		border: 1px solid #6b8fa3;
	}

	/* 协议列显示（两行） */
	.xagg-proto{ line-height: 1.15; font-weight: bold; }
	.xagg-proto small{
		display:block;
		font-weight: normal;
		opacity: .85;
		margin-top: 4px;
	}
</style>

<script>
var confs = {};
var node_global_max = 0;

function E(id){ return document.getElementById(id); }

function init() {
	show_menu(menu_hook);
	buildNodeTable();
	refreshSelectedCount();
}

function base64DecodeMaybe(s){
	try { return Base64.decode(s); } catch(e){ return s; }
}
function isDefined(v){ return !(typeof v === "undefined" || v === null); }

function getAllConfigs() {
	var dic = {};
	for (var field in db_ss) {
		var names = field.split("ssconf_basic_name_");
		dic[names[names.length - 1]] = 'ok';
	}
	var out = {};
	var p = "ssconf_basic";

	for (var field in dic) {
		if (isNaN(field)) continue;

		var obj = {};
		obj.node = field;

		obj.name = (typeof db_ss[p + "_name_" + field] == "undefined") ? ("节点" + field) : db_ss[p + "_name_" + field];
		obj.server = (typeof db_ss[p + "_server_" + field] == "undefined") ? "" : db_ss[p + "_server_" + field];
		obj.port   = (typeof db_ss[p + "_port_" + field] == "undefined") ? "" : db_ss[p + "_port_" + field];

		// v2ray/xray 节点：v2ray_use_json 字段存在
		obj.v2ray = isDefined(db_ss[p + "_v2ray_use_json_" + field]);
		obj.v2ray_protocol = db_ss[p + "_v2ray_protocol_" + field] || ""; // vless/vmess
		obj.v2ray_network = db_ss[p + "_v2ray_network_" + field] || "tcp";
		obj.v2ray_network_security = db_ss[p + "_v2ray_network_security_" + field] || "none";

		obj.v2ray_uuid = db_ss[p + "_v2ray_uuid_" + field] || "";
		obj.v2ray_alterid = db_ss[p + "_v2ray_alterid_" + field] || "";
		obj.v2ray_security = db_ss[p + "_v2ray_security_" + field] || "auto";
		obj.v2ray_network_host = db_ss[p + "_v2ray_network_host_" + field] || "";
		obj.v2ray_network_path = db_ss[p + "_v2ray_network_path_" + field] || "";
		obj.v2ray_network_tlshost = db_ss[p + "_v2ray_network_tlshost_" + field] || "";
		obj.v2ray_network_flow = db_ss[p + "_v2ray_network_flow_" + field] || "";
		obj.v2ray_headtype_tcp = db_ss[p + "_v2ray_headtype_tcp_" + field] || "";
		obj.v2ray_headtype_kcp = db_ss[p + "_v2ray_headtype_kcp_" + field] || "";
		obj.v2ray_serviceName = db_ss[p + "_v2ray_serviceName_" + field] || "";

		obj.allowinsecure = db_ss[p + "_allowinsecure_" + field] || "0";
		obj.fingerprint = db_ss[p + "_fingerprint_" + field] || "";
		obj.xray_publicKey = db_ss[p + "_xray_publicKey_" + field] || "";
		obj.xray_shortId = db_ss[p + "_xray_shortId_" + field] || "";

		// trojan 节点：trojan_binary 字段存在
		obj.trojan = isDefined(db_ss[p + "_trojan_binary_" + field]);
		obj.trojan_binary = db_ss[p + "_trojan_binary_" + field] || ""; // Trojan / Trojan-Go / Hysteria2
		obj.trojan_sni = db_ss[p + "_trojan_sni_" + field] || "";

		obj.password_b64 = db_ss[p + "_password_" + field] || "";
		obj.password = obj.password_b64 ? base64DecodeMaybe(obj.password_b64) : "";

		// 仅展示可聚合：VLESS/VMESS/TROJAN（排除 Trojan-Go/Hysteria2）
		obj.support_xagg = false;
		obj.proto_label = "";

		if (obj.v2ray && (obj.v2ray_protocol === "vless" || obj.v2ray_protocol === "vmess")) {
			obj.support_xagg = true;
			obj.proto_label = obj.v2ray_protocol.toUpperCase();
		}
		if (obj.trojan && obj.trojan_binary === "Trojan") {
			obj.support_xagg = true;
			obj.proto_label = "Trojan";
			// trojan 默认 tcp tls（给协议列展示用）
			obj.v2ray_network = "tcp";
			obj.v2ray_network_security = "tls";
		}

		var node_i = parseInt(field, 10);
		if (node_i > node_global_max) node_global_max = node_i;

		out[field] = obj;
	}
	return out;
}

function protoCell(c){
	var proto = c.proto_label || "UNKNOWN";
	var net = (c.v2ray_network || "").toLowerCase();
	var sec = (c.v2ray_network_security || "").toLowerCase();
	var hint = [net, sec].filter(Boolean).join(" ");
	return '<div class="xagg-proto">' + proto + '<small>' + (hint || '&nbsp;') + '</small></div>';
}

function getSelectedNodes(){
	var ids = [];
	$("input[name='xagg_node_ck']:checked").each(function(){
		ids.push($(this).val());
	});
	return ids;
}

function refreshSelectedCount(){
	var n = getSelectedNodes().length;
	E("xagg_selected_cnt").innerHTML = n;
	E("xagg_selected_cnt").className = (n < 2) ? "badge badge_warn" : "badge badge_ok";
}

function buildNodeTable(){
	confs = getAllConfigs();

	var $tb = $("#xagg_node_table");
	$tb.find("tr:gt(0)").remove();

	var any = false;

	for (var k in confs){
		var c = confs[k];
		if (!c.support_xagg) continue;
		if (!c.server || c.server === "127.0.0.1") continue;

		any = true;

		var tr = '' +
			'<tr>' +
			'  <td style="width:55px; text-align:center;"><input class="chk" type="checkbox" name="xagg_node_ck" value="'+ c.node +'" onchange="refreshSelectedCount()"></td>' +
			'  <td>' + c.name + '</td>' +
			'  <td style="width:160px;">' + c.server + '</td>' +
			'  <td style="width:70px;">' + c.port + '</td>' +
			'  <td style="width:90px;">' + protoCell(c) + '</td>' +
			'</tr>';

		$tb.append(tr);
	}

	if (!any){
		$tb.append('<tr><td colspan="5" style="color:#FFCC00;">没有找到可用于聚合的节点（仅显示 VLESS/VMESS/TROJAN，且排除 127.0.0.1 / 空 server）。</td></tr>');
	}
}

function buildOutboundsFromSelection(selectedIds){
	var outbounds = [];
	for (var i=0; i<selectedIds.length; i++){
		var id = selectedIds[i];
		var c = confs[id];
		var tag = "xagg_" + (i+1);

		// VLESS / VMESS
		if (c.v2ray && (c.v2ray_protocol === "vless" || c.v2ray_protocol === "vmess")) {
			var ob = {
				tag: tag,
				protocol: c.v2ray_protocol,
				settings: {},
				streamSettings: {}
			};

			if (c.v2ray_protocol === "vmess"){
				ob.settings.vnext = [{
					address: c.server,
					port: parseInt(c.port, 10),
					users: [{
						id: c.v2ray_uuid,
						alterId: parseInt(c.v2ray_alterid || "0", 10),
						security: (c.v2ray_security || "auto")
					}]
				}];
			} else {
				var user = { id: c.v2ray_uuid, encryption: "none" };
				if (c.v2ray_network_flow && c.v2ray_network_flow !== "none"){
					user.flow = c.v2ray_network_flow;
				}
				ob.settings.vnext = [{
					address: c.server,
					port: parseInt(c.port, 10),
					users: [user]
				}];
			}

			ob.streamSettings.network = c.v2ray_network || "tcp";
			ob.streamSettings.security = (c.v2ray_network_security && c.v2ray_network_security !== "none") ? c.v2ray_network_security : "none";

			var sec = (c.v2ray_network_security || "");
			var tlsHost = c.v2ray_network_tlshost || c.v2ray_network_host || "";

			if (sec === "tls") {
				ob.streamSettings.tlsSettings = { allowInsecure: (c.allowinsecure === "1") };
				if (c.fingerprint && c.fingerprint !== "none") ob.streamSettings.tlsSettings.fingerprint = c.fingerprint;
				if (tlsHost) ob.streamSettings.tlsSettings.serverName = tlsHost;
			} else if (sec === "reality") {
				ob.streamSettings.realitySettings = {
					serverName: tlsHost,
					publicKey: c.xray_publicKey,
					shortId: c.xray_shortId,
					spiderX: ""
				};
				if (c.fingerprint && c.fingerprint !== "none") ob.streamSettings.realitySettings.fingerprint = c.fingerprint;
			}

			// ws / h2 / grpc / tcp http / kcp（轻量填充）
			if (ob.streamSettings.network === "ws") {
				ob.streamSettings.wsSettings = {
					path: c.v2ray_network_path || "/",
					headers: (c.v2ray_network_host ? { Host: c.v2ray_network_host } : {})
				};
			} else if (ob.streamSettings.network === "h2") {
				ob.streamSettings.httpSettings = {
					path: (c.v2ray_network_path ? [c.v2ray_network_path] : ["/"]),
					host: (c.v2ray_network_host ? [c.v2ray_network_host] : [])
				};
			} else if (ob.streamSettings.network === "grpc") {
				ob.streamSettings.grpcSettings = { multiMode: true, serviceName: c.v2ray_serviceName || "" };
				if (c.fingerprint && c.fingerprint !== "none") ob.streamSettings.grpcSettings.fingerprint = c.fingerprint;
			} else if (ob.streamSettings.network === "tcp" && c.v2ray_headtype_tcp === "http") {
				ob.streamSettings.tcpSettings = { header: { type: "http" } };
			} else if (ob.streamSettings.network === "kcp") {
				ob.streamSettings.kcpSettings = { header: { type: (c.v2ray_headtype_kcp || "none") } };
				if (c.v2ray_network_path) ob.streamSettings.kcpSettings.seed = c.v2ray_network_path;
			}

			outbounds.push(ob);
			continue;
		}

		// TROJAN（Xray 原生）
		if (c.trojan && c.trojan_binary === "Trojan") {
			var ob2 = {
				tag: tag,
				protocol: "trojan",
				settings: {
					servers: [{
						address: c.server,
						port: parseInt(c.port, 10),
						password: c.password
					}]
				},
				streamSettings: {
					network: "tcp",
					security: "tls",
					tlsSettings: {
						allowInsecure: (c.allowinsecure === "1")  
					}
				}
			};

			if (c.trojan_sni) ob2.streamSettings.tlsSettings.serverName = c.trojan_sni;
			if (c.fingerprint && c.fingerprint !== "none") ob2.streamSettings.tlsSettings.fingerprint = c.fingerprint;

			outbounds.push(ob2);
		}
	}
	return outbounds;
}

function gen_json(){
	var sel = getSelectedNodes();
	refreshSelectedCount();

	if (sel.length < 2){
		alert("至少选择 2 个节点才有聚合意义！");
		return false;
	}

	var outbounds = buildOutboundsFromSelection(sel);
	if (!outbounds || outbounds.length < 2){
		alert("选中的节点里可生成的 outbounds 少于 2 个（可能包含不支持的节点）。");
		return false;
	}

	var strategy = E("xagg_strategy").value || "leastPing";

	outbounds.unshift({
		tag: "xagg_meta",
		protocol: "blackhole",
		settings: {
			strategy: strategy
		}
	});

	var obj = { outbounds: outbounds };
	E("xagg_json").value = JSON.stringify(obj, null, 2);
	return true;
}

function copy_json(){
	var ta = E("xagg_json");
	if (!ta.value){
		alert("请先点击“生成JSON”");
		return false;
	}
	ta.select();
	ta.setSelectionRange(0, ta.value.length);

	if (navigator.clipboard && navigator.clipboard.writeText){
		navigator.clipboard.writeText(ta.value).then(function(){
			alert("已复制到剪贴板");
		}).catch(function(){
			document.execCommand("copy");
			alert("已复制到剪贴板");
		});
	} else {
		document.execCommand("copy");
		alert("已复制到剪贴板");
	}
	return true;
}

function select_all(v){
	$("input[name='xagg_node_ck']").prop("checked", v);
	refreshSelectedCount();
}
</script>
</head>

<body onload="init();">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<div id="LoadingBar" class="popup_bar_bg">
	<table cellpadding="5" cellspacing="0" id="loadingBarBlock" class="loadingBarBlock" align="center">
		<tr>
			<td height="100">
				<div id="loading_block3" style="margin:10px auto;margin-left:10px;width:85%; font-size:12pt;"></div>
				<div id="loading_block2" style="margin:10px auto;width:95%;"></div>
			</td>
		</tr>
	</table>
</div>

<iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>

<form method="POST" name="form" action="/applydb.cgi?p=ss" target="hidden_frame">
	<input type="hidden" name="current_page" value="Main_Xray_Aggregate.asp" />
	<input type="hidden" name="next_page" value="Main_Xray_Aggregate.asp" />
	<input type="hidden" name="group_id" value="" />
	<input type="hidden" name="modified" value="0" />
	<input type="hidden" name="action_mode" value="" />
	<input type="hidden" name="action_script" value="" />
	<input type="hidden" name="action_wait" value="" />
	<input type="hidden" name="first_time" value="" />
	<input type="hidden" name="preferred_lang" id="preferred_lang" value="CN"/>
	<input type="hidden" name="SystemCmd" value="" />
	<input type="hidden" name="firmver" value="3.0.0.4"/>

	<table class="content" align="center" cellpadding="0" cellspacing="0">
		<tr>
			<td width="17">&nbsp;</td>
			<td valign="top" width="202">
				<div id="mainMenu"></div>
				<div id="subMenu"></div>
			</td>
			<td valign="top">
				<div id="tabMenu" class="submenuBlock"></div>
				<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
					<tr>
						<td align="left" valign="top">
							<table width="760px" border="0" cellpadding="5" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
								<tr>
									<td bgcolor="#4D595D" colspan="3" valign="top">

										<div style="padding:10px 10px 0 10px;">
											<span class="xagg_note">说明：</span>
											选择多个节点生成 <span class="xagg_note">{ "outbounds": [...] }</span>。
											生成的 tag 为 xagg_1 / xagg_2 / ...（后端用此特征补全 routing/observatory）。
										</div>

										<div style="margin:10px 10px 0 10px;">
											<input class="small_btn" type="button" value="全选" onclick="select_all(true)">
											<input class="small_btn" type="button" value="全不选" onclick="select_all(false)">
											<input class="small_btn" type="button" value="生成JSON" onclick="gen_json()">
											<input class="small_btn" type="button" value="复制JSON" onclick="copy_json()">
											<span style="margin-left:12px;">
											<a class="hintstyle"
											   href="javascript:void(0);"
											   onclick="openssHint(211)"
											   style="margin-right:6px;color:#FFCC00;">
											   Xray 聚合策略:
											</a>

											  <select id="xagg_strategy"
													  class="input_option"
													  style="width:160px; vertical-align:middle;">
												<option value="leastPing">leastPing（推荐）</option>
												<option value="roundRobin">roundRobin</option>
												<option value="random">random</option>
											  </select>
											</span>

											<span id="xagg_selected_cnt" class="badge badge_warn">0</span>
											<span class="badge">已选节点</span>
										</div>

										<div style="margin:10px 10px 0 10px;" class="xagg-table-wrap">
											<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable tbl_sm" id="xagg_node_table">
												<tr>
													<th style="width:55px;">选择</th>
													<th>节点名</th>
													<th style="width:160px;">服务器</th>
													<th style="width:70px;">端口</th>
													<th style="width:90px;">协议</th>
												</tr>
											</table>
										</div>

										<div style="margin:10px 10px 10px 10px;">
											<textarea id="xagg_json" class="mono" rows="20" placeholder='点击“生成JSON”后，这里会输出：{ "outbounds": [ ... ] }，复制JSON后，再手动新建一个 v2ray 节点，勾选 “使用json配置”，粘贴 JSON 进去使用。用户还需要自行将各个服务器ip地址添加到IP/CIDR白名单！'></textarea>
										</div>

									</td>
								</tr>
							</table>
						</td>
						<td width="10" align="center" valign="top"></td>
					</tr>
				</table>
			</td>
		</tr>
	</table>
</form>

<div id="footer"></div>
</body>
</html>
