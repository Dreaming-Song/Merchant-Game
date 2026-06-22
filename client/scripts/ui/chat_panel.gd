extends Control
## 聊天面板 — 文字聊天 + 聊天气泡
##
## 支持：历史记录、发送消息、输入框自动聚焦
## 按 Enter 打开/关闭，/ 快速打开

class_name ChatPanel

signal message_sent(message: String)

# ==================== UI 控件（动态创建） ====================
var _history: RichTextLabel
var _input: LineEdit
var _container: VBoxContainer

var _is_open: bool = false
var _max_history: int = 100
var _history_lines: Array[String] = []

func _ready() -> void:
	_build_ui()
	_setup_signals()
	visible = false

func _build_ui() -> void:
	# 背景遮罩（仅接收输入事件不阻挡点击）
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 聊天历史（左下角）
	_history = RichTextLabel.new()
	_history.name = "ChatHistory"
	_history.anchors_preset = Control.PRESET_BOTTOM_LEFT
	_history.offset_left = 10
	_history.offset_bottom = -80
	_history.offset_right = 350
	_history.offset_top = -400
	_history.bbcode_enabled = true
	_history.fit_content_height = true
	_history.scroll_active = true
	_history.mouse_filter = Control.MOUSE_FILTER_PASS
	_history.add_theme_color_override("default_color", Color(1, 1, 1, 0.8))
	add_child(_history)
	
	# 输入框（左下角）
	_input = LineEdit.new()
	_input.name = "ChatInput"
	_input.anchors_preset = Control.PRESET_BOTTOM_LEFT
	_input.offset_left = 10
	_input.offset_bottom = -40
	_input.offset_right = 360
	_input.offset_top = -60
	_input.placeholder_text = "按 Enter 或 / 聊天..."
	_input.visible = false
	add_child(_input)

func _setup_signals() -> void:
	_input.text_submitted.connect(_on_input_submitted)
	_input.text_changed.connect(_on_input_text_changed)

# ==================== 输入处理 ====================

func _input(event: InputEvent) -> void:
	# Enter 切换聊天输入
	if event.is_action_pressed("ui_accept") and not _input.visible:
		if not _is_blocked_by_other_panels():
			_open_input()
		get_viewport().set_input_as_handled()
	
	# ESC 关闭输入
	if event.is_action_pressed("ui_cancel") and _input.visible:
		_close_input()
		get_viewport().set_input_as_handled()

func _is_blocked_by_other_panels() -> bool:
	"""检查是否有其他面板打开（防止在面板中按 Enter 弹聊天）"""
	var ui = get_node("/root/UIManager") if has_node("/root/UIManager") else null
	if ui and ui.has_method("is_any_panel_open"):
		return ui.is_any_panel_open()
	return false

func _open_input() -> void:
	_input.visible = true
	_input.grab_focus()
	_is_open = true

func _close_input() -> void:
	_input.text = ""
	_input.visible = false
	_input.release_focus()
	_is_open = false

# ==================== 发送消息 ====================

func _on_input_submitted(text: String) -> void:
	if text.strip_edges().is_empty():
		_close_input()
		return
	
	_send_message(text)
	_input.text = ""
	_close_input()

func _send_message(text: String) -> void:
	message_sent.emit(text)
	
	# 发送到网络
	var net = get_node("/root/NetworkManager") if has_node("/root/NetworkManager") else null
	if net and net.has_method("send_chat"):
		net.send_chat(text)
	
	# 本地显示
	var player_id = net.player_id if net else "我"
	add_message(player_id, text, Color(0.3, 1.0, 0.5))

func add_message(sender: String, text: String, color: Color = Color.WHITE) -> void:
	"""添加聊天消息到历史 + 显示聊天气泡"""
	var line = "[color=#%s]%s[/color]: %s" % [color.to_html(), sender, text]
	_history_lines.append(line)
	
	if _history_lines.size() > _max_history:
		_history_lines.pop_front()
	
	_history.clear()
	for l in _history_lines:
		_history.append_text(l + "\n")

func add_system_message(text: String) -> void:
	"""系统消息（黄色）"""
	add_message("系统", text, Color(1, 0.8, 0.2))

# ==================== 快速命令 ====================

func _on_input_text_changed(new_text: String) -> void:
	# / 快捷键
	if new_text == "/":
		_input.text = "/"
		_input.caret_column = 1
