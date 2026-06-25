extends Control
## 🎭 表情轮盘 — 按 B 打开，选择和发送表情
##
## 展示：6 个表情按钮（挥手/作揖/跳舞/打坐/剑诀/欢呼）
## 选择后：播放玩家动画 + 粒子特效 + 附近玩家可见

class_name EmoteUI

signal emote_selected(emote_id: String, emote_name: String)

var is_open: bool = false

# 表情定义
const EMOTES = [
	{ "id": "wave",  "icon": "👋", "name": "挥手",    "anim": "wave" },
	{ "id": "bow",   "icon": "🙏", "name": "作揖",    "anim": "bow" },
	{ "id": "dance", "icon": "💃", "name": "跳舞",    "anim": "dance" },
	{ "id": "sit",   "icon": "🧘", "name": "打坐",    "anim": "sit" },
	{ "id": "sword", "icon": "⚔️", "name": "剑诀",    "anim": "sword_sign" },
	{ "id": "cheer", "icon": "🎉", "name": "欢呼",    "anim": "cheer" },
]

var _buttons: Array[Button] = []
var _bg: ColorRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()

func _build_ui() -> void:
	"""构建表情轮盘 UI"""
	# 半透明背景（点击关闭）
	_bg = ColorRect.new()
	_bg.name = "EmoteBG"
	_bg.color = Color(0, 0, 0, 0.3)
	_bg.anchors_preset = Control.PRESET_FULL_RECT
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_bg.gui_input.connect(_on_bg_click)
	add_child(_bg)
	
	# 标题
	var title = Label.new()
	title.text = "🎭 选择表情"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	title.anchors_preset = Control.PRESET_TOP_WIDE
	title.offset_top = 60
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	
	# 表情网格（3x2）
	var grid = GridContainer.new()
	grid.name = "EmoteGrid"
	grid.columns = 3
	grid.anchors_preset = Control.PRESET_CENTER
	grid.offset_top = -80
	grid.custom_minimum_size = Vector2(320, 200)
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	add_child(grid)
	
	for emote in EMOTES:
		var btn = Button.new()
		btn.text = "%s\n%s" % [emote.icon, emote.name]
		btn.custom_minimum_size = Vector2(96, 80)
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_constant_override("outline_size", 0)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		# 按钮样式
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.25, 0.85)
		style.set_border_width_all(1)
		style.border_color = Color(0.4, 0.4, 0.6, 0.5)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", style)
		
		var hover = style.duplicate()
		hover.bg_color = Color(0.3, 0.3, 0.5, 0.9)
		hover.border_color = Color(0.8, 0.7, 1.0, 0.8)
		btn.add_theme_stylebox_override("hover", hover)
		
		btn.pressed.connect(_on_emote_pressed.bind(emote.id, emote.name))
		grid.add_child(btn)
		_buttons.append(btn)
	
	# 关闭提示（动态按键）
	var hint = Label.new()
	var ih = get_node("/root/InputHandler") if has_node("/root/InputHandler") else null
	var close_key = "B"
	if ih and ih.has_method("get_action_hint"):
		close_key = ih.get_action_hint("toggle_emote")
	hint.text = "按 %s 或 ESC 关闭" % close_key
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	hint.anchors_preset = Control.PRESET_BOTTOM_WIDE
	hint.offset_bottom = -40
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)

func toggle() -> void:
	is_open = not is_open
	visible = is_open

func open() -> void:
	is_open = true
	visible = true

func close() -> void:
	is_open = false
	visible = false

func _on_emote_pressed(emote_id: String, emote_name: String) -> void:
	"""选中表情"""
	emote_selected.emit(emote_id, emote_name)
	close()

func _on_bg_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			close()
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
		close()
