extends Control
## 🌩️ 雷劫HUD — 渡劫过程中的顶部状态显示
##
## 显示：天劫进度条、当前阶段、波次/分数、境界名

class_name TribulationHUD

const TribulationManager = preload("res://scripts/effects/tribulation_manager.gd")

var _manager: TribulationManager = null

# UI节点
var _bg_bar: ColorRect
var _progress_bar: TextureProgressBar
var _phase_label: Label
var _realm_label: Label
var _hint_label: Label

func _init(manager: TribulationManager) -> void:
	_manager = manager
	name = "TribulationHUD"
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	_build_ui()
	_connect_signals()

func _build_ui() -> void:
	# 顶部背景条
	_bg_bar = ColorRect.new()
	_bg_bar.name = "BgBar"
	_bg_bar.color = Color(0.05, 0.02, 0.1, 0.7)
	_bg_bar.anchors_preset = Control.PRESET_TOP_WIDE
	_bg_bar.offset_top = 0
	_bg_bar.offset_bottom = 55
	_bg_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_bar)
	
	# 进度条
	_progress_bar = TextureProgressBar.new()
	_progress_bar.name = "ProgressBar"
	_progress_bar.anchors_preset = Control.PRESET_TOP_WIDE
	_progress_bar.offset_top = 40
	_progress_bar.offset_left = 100
	_progress_bar.offset_right = -100
	_progress_bar.offset_bottom = 52
	_progress_bar.max_value = 3.0  # 三阶段
	_progress_bar.value = 1.0
	_progress_bar.tint_progress = Color("#8844ff")
	_progress_bar.tint_under = Color(0.1, 0.05, 0.15, 0.5)
	
	# 进度条纹理（空）
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.5, 0.2, 1.0, 0.4)
	style_fill.corner_radius = 4
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.05, 0.02, 0.1, 0.3)
	style_bg.corner_radius = 4
	_progress_bar.add_theme_stylebox_override("fill", style_fill)
	_progress_bar.add_theme_stylebox_override("background", style_bg)
	add_child(_progress_bar)
	
	# 阶段名称（左侧）
	_phase_label = Label.new()
	_phase_label.name = "PhaseLabel"
	_phase_label.text = "⚡ 天雷闪避"
	_phase_label.add_theme_font_size_override("font_size", 18)
	_phase_label.add_theme_color_override("font_color", Color("#ffcc44"))
	_phase_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_phase_label.add_theme_constant_override("outline_size", 2)
	_phase_label.anchors_preset = Control.PRESET_TOP_LEFT
	_phase_label.offset_left = 20
	_phase_label.offset_top = 8
	_phase_label.custom_minimum_size = Vector2(200, 30)
	add_child(_phase_label)
	
	# 境界名（右侧）
	_realm_label = Label.new()
	_realm_label.name = "RealmLabel"
	_realm_label.text = "🌩️ 渡劫期"
	_realm_label.add_theme_font_size_override("font_size", 16)
	_realm_label.add_theme_color_override("font_color", Color("#88aaff"))
	_realm_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_realm_label.add_theme_constant_override("outline_size", 2)
	_realm_label.anchors_preset = Control.PRESET_TOP_RIGHT
	_realm_label.offset_right = -20
	_realm_label.offset_top = 10
	_realm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_realm_label)
	
	# 底部提示
	_hint_label = Label.new()
	_hint_label.name = "HintLabel"
	_hint_label.text = ""
	_hint_label.add_theme_font_size_override("font_size", 14)
	_hint_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 0.6))
	_hint_label.anchors_preset = Control.PRESET_CENTER
	_hint_label.offset_top = 120
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hint_label)

func _connect_signals() -> void:
	if not _manager: return
	
	if not _manager.tribulation_phase_changed.is_connected(_on_phase_changed):
		_manager.tribulation_phase_changed.connect(_on_phase_changed)

func _on_phase_changed(phase: int, phase_name: String) -> void:
	"""阶段变化时更新HUD"""
	_phase_label.text = phase_name
	
	# 更新进度条
	if _progress_bar:
		_progress_bar.value = phase
	
	# 阶段颜色变化
	match phase:
		1:
			_phase_label.modulate = Color(1, 0.8, 0.2)  # 金色
			_set_progress_color(Color("#8844ff"))
		2:
			_phase_label.modulate = Color(0.3, 1.0, 0.5)  # 绿色
			_set_progress_color(Color("#22aa44"))
		3:
			_phase_label.modulate = Color(1.0, 0.3, 0.3)  # 红色
			_set_progress_color(Color("#cc2222"))
	
	# 闪烁动画
	var tween = create_tween()
	tween.tween_property(_phase_label, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(_phase_label, "scale", Vector2(1.0, 1.0), 0.2)

func _set_progress_color(color: Color) -> void:
	if _progress_bar:
		_progress_bar.tint_progress = color
		# 更新fill style颜色
		var style = StyleBoxFlat.new()
		style.bg_color = Color(color.r, color.g, color.b, 0.4)
		style.corner_radius = 4
		_progress_bar.add_theme_stylebox_override("fill", style)

func set_hint(text: String) -> void:
	if _hint_label:
		_hint_label.text = text

func shake() -> void:
	"""HUD震动效果"""
	var original_pos = position
	var tween = create_tween()
	tween.tween_method(func(offset):
		position = original_pos + Vector2(randf_range(-5, 5), randf_range(-3, 3))
	, 0, 0, 0.3)
	tween.tween_callback(func(): position = original_pos)
