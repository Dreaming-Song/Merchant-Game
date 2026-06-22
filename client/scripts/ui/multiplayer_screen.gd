extends Control
## 联机界面 — 主持游戏 / 加入游戏
##
## 类似 Minecraft 的"对局域网开放" + 泰拉的"加入游戏"

class_name MultiplayerScreen

signal back_to_menu()

var _host_port_input: LineEdit
var _max_players_input: LineEdit
var _join_ip_input: LineEdit
var _join_port_input: LineEdit
var _status_label: Label

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 0.95)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	add_child(bg)
	
	# 居中容器
	var center = VBoxContainer.new()
	center.anchors_preset = Control.PRESET_CENTER
	center.offset_top = -250
	center.offset_bottom = 250
	center.offset_left = -300
	center.offset_right = 300
	center.add_theme_constant_override("separation", 10)
	add_child(center)
	
	# 标题
	var title = Label.new()
	title.text = "🔗 联机模式"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	center.add_child(title)
	
	center.add_child(HSeparator.new())
	
	# ==== 主持游戏 ====
	var host_label = Label.new()
	host_label.text = "🏠 主持游戏（开启 LAN 服务器）"
	host_label.add_theme_font_size_override("font_size", 18)
	host_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.5))
	center.add_child(host_label)
	
	var host_grid = GridContainer.new()
	host_grid.columns = 2
	host_grid.add_theme_constant_override("h_separation", 8)
	host_grid.add_theme_constant_override("v_separation", 6)
	
	host_grid.add_child(Label.new()._ready_set_text("端口:"))
	_host_port_input = LineEdit.new()
	_host_port_input.text = "4242"
	_host_port_input.placeholder_text = "默认 4242"
	host_grid.add_child(_host_port_input)
	
	host_grid.add_child(Label.new()._ready_set_text("最大玩家数:"))
	_max_players_input = LineEdit.new()
	_max_players_input.text = "4"
	_max_players_input.placeholder_text = "2~8"
	host_grid.add_child(_max_players_input)
	
	center.add_child(host_grid)
	
	var host_btn = Button.new()
	host_btn.text = "🏠 主持此世界"
	host_btn.custom_minimum_size = Vector2(0, 44)
	host_btn.pressed.connect(_on_host)
	center.add_child(host_btn)
	
	center.add_child(HSeparator.new())
	
	# ==== 加入游戏 ====
	var join_label = Label.new()
	join_label.text = "🔗 加入联机世界"
	join_label.add_theme_font_size_override("font_size", 18)
	join_label.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))
	center.add_child(join_label)
	
	var join_grid = GridContainer.new()
	join_grid.columns = 2
	join_grid.add_theme_constant_override("h_separation", 8)
	join_grid.add_theme_constant_override("v_separation", 6)
	
	join_grid.add_child(Label.new()._ready_set_text("主机 IP:"))
	_join_ip_input = LineEdit.new()
	_join_ip_input.placeholder_text = "例如 192.168.1.100"
	_join_ip_input.text = "127.0.0.1"
	join_grid.add_child(_join_ip_input)
	
	join_grid.add_child(Label.new()._ready_set_text("端口:"))
	_join_port_input = LineEdit.new()
	_join_port_input.text = "4242"
	_join_port_input.placeholder_text = "默认 4242"
	join_grid.add_child(_join_port_input)
	
	center.add_child(join_grid)
	
	var join_btn = Button.new()
	join_btn.text = "🔗 加入游戏"
	join_btn.custom_minimum_size = Vector2(0, 44)
	join_btn.pressed.connect(_on_join)
	center.add_child(join_btn)
	
	center.add_child(HSeparator.new())
	
	# 状态提示
	_status_label = Label.new()
	_status_label.text = ""
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.3))
	center.add_child(_status_label)
	
	# 返回按钮
	var back_btn = Button.new()
	back_btn.text = "⬅ 返回"
	back_btn.custom_minimum_size = Vector2(0, 40)
	back_btn.pressed.connect(_on_back)
	center.add_child(back_btn)

func _ready_set_text(text: String) -> Label:
	text = text
	return self

func _on_host() -> void:
	"""创建主机"""
	var net = get_node("/root/NetworkManager")
	if not net:
		_status_label.text = "❌ NetworkManager 未加载"
		return
	
	var port = int(_host_port_input.text.strip_edges())
	var max_p = int(_max_players_input.text.strip_edges())
	
	if port < 1024 or port > 65535:
		_status_label.text = "⚠️ 端口范围 1024~65535"
		return
	
	if max_p < 2 or max_p > 8:
		_status_label.text = "⚠️ 玩家数 2~8"
		return
	
	# 确保有当前世界
	var wm = get_node("/root/WorldManager")
	if not wm or wm.current_world.is_empty():
		_status_label.text = "⚠️ 请先选择世界"
		return
	
	net.connected.connect(_on_net_connected.bind("host"))
	net.connection_error.connect(_on_net_error)
	
	if net.host_game(port, max_p):
		_status_label.text = "🔄 正在创建主机..."
	else:
		_status_label.text = "❌ 主机创建失败"

func _on_join() -> void:
	"""加入游戏"""
	var net = get_node("/root/NetworkManager")
	if not net:
		_status_label.text = "❌ NetworkManager 未加载"
		return
	
	var ip = _join_ip_input.text.strip_edges()
	var port = int(_join_port_input.text.strip_edges())
	
	if ip.is_empty():
		_status_label.text = "⚠️ 请输入主机 IP"
		return
	
	if port < 1024 or port > 65535:
		_status_label.text = "⚠️ 端口范围 1024~65535"
		return
	
	net.connected.connect(_on_net_connected.bind("join"))
	net.connection_error.connect(_on_net_error)
	
	if net.join_game(ip, port):
		_status_label.text = "🔄 正在连接 %s:%d..." % [ip, port]
	else:
		_status_label.text = "❌ 连接失败"

func _on_net_connected(source: String) -> void:
	_status_label.text = "✅ %s 成功！正在进入游戏..." % ("主机创建" if source == "host" else "连接")
	
	# 断开信号（避免重复）
	var net = get_node("/root/NetworkManager")
	if net:
		net.connected.disconnect(_on_net_connected)
		net.connection_error.disconnect(_on_net_error)
	
	# 进入游戏场景（如果还在主菜单）
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_net_error(msg: String) -> void:
	_status_label.text = "❌ 错误: " + msg
	
	var net = get_node("/root/NetworkManager")
	if net:
		net.connected.disconnect(_on_net_connected)
		net.connection_error.disconnect(_on_net_error)

func _on_back() -> void:
	back_to_menu.emit()
