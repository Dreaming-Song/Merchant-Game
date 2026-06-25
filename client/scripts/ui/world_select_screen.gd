extends Control
## 世界选择界面 — 主菜单的核心画面
##
## 类似 Minecraft 的世界选择界面：
##   ┌──────────────────────────────┐
##   │        选择世界              │
##   │                              │
##   │  📂 灵境大陆  seed:12345     │
##   │     生存 | 2小时 | 2026-06-22│
##   │     [进入] [删除] [重命名]   │
##   │                              │
##   │  📂 新手村试炼  seed:67890   │
##   │     生存 | 30分钟 | 2026-06-21│
##   │     [进入] [删除] [重命名]   │
##   │                              │
##   │  ┌─────────────────────┐     │
##   │  │  ✨ 创建新世界       │     │
##   │  │  🔗 加入联机世界     │     │
##   │  │  ⚙️ 设置             │     │
##   │  └─────────────────────┘     │
##   └──────────────────────────────┘

class_name WorldSelectScreen

signal world_selected(world_name: String)
signal create_new_world()
signal join_multiplayer()
signal settings_requested()

var _world_list: VBoxContainer
var _world_data: Array = []

func _ready() -> void:
	_build_ui()
	_refresh_list()

func _build_ui() -> void:
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 0.95)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	add_child(bg)
	
	# 居中容器
	var center = VBoxContainer.new()
	center.anchors_preset = Control.PRESET_CENTER
	center.offset_top = -300
	center.offset_bottom = 300
	center.offset_left = -350
	center.offset_right = 350
	center.add_theme_constant_override("separation", 10)
	add_child(center)
	
	# 标题
	var title = Label.new()
	title.text = "🌍 选择世界"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	center.add_child(title)
	
	# 说明
	var subtitle = Label.new()
	subtitle.text = "选择一个世界进入，或创建新的冒险"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	center.add_child(subtitle)
	
	# 分割线
	center.add_child(HSeparator.new())
	
	# 世界列表（滚动区域）
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(600, 300)
	center.add_child(scroll)
	
	_world_list = VBoxContainer.new()
	_world_list.add_theme_constant_override("separation", 8)
	_world_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_world_list)
	
	# 分割线
	center.add_child(HSeparator.new())
	
	# 底部按钮
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	
	var create_btn = _make_button("✨ 创建新世界", Color(0.2, 0.6, 0.3))
	create_btn.pressed.connect(_on_create)
	btn_row.add_child(create_btn)
	
	var join_btn = _make_button("🔗 加入联机", Color(0.2, 0.4, 0.7))
	join_btn.pressed.connect(_on_join)
	btn_row.add_child(join_btn)
	
	var settings_btn = _make_button("⚙️ 设置", Color(0.3, 0.3, 0.3))
	settings_btn.pressed.connect(_on_settings)
	btn_row.add_child(settings_btn)
	
	center.add_child(btn_row)

func _make_button(text: String, color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(180, 48)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_stylebox_override("normal", _make_btn_style(color, 0.8))
	btn.add_theme_stylebox_override("hover", _make_btn_style(color, 1.0))
	btn.add_theme_stylebox_override("pressed", _make_btn_style(color.darkened(0.2), 1.0))
	return btn

func _make_btn_style(color: Color, alpha: float) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, alpha)
	style.set_border_width_all(1)
	style.border_color = Color(1, 1, 1, 0.2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

# ==================== 刷新世界列表 ====================

func _refresh_list() -> void:
	"""从 SaveSystem 读取世界列表"""
	for child in _world_list.get_children():
		child.queue_free()
	
	var wm = get_node("/root/WorldManager") if has_node("/root/WorldManager") else null
	if not wm:
		var empty = Label.new()
		empty.text = "⚠️ WorldManager 未加载"
		_world_list.add_child(empty)
		return
	
	_world_data = wm.list_worlds()
	
	if _world_data.is_empty():
		var empty = Label.new()
		empty.text = "还没有世界，点击「创建新世界」开始冒险！"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		empty.add_theme_font_size_override("font_size", 16)
		empty.custom_minimum_size = Vector2(0, 200)
		_world_list.add_child(empty)
		return
	
	for w in _world_data:
		_world_list.add_child(_create_world_card(w))

func _create_world_card(world_info: Dictionary) -> PanelContainer:
	"""创建单个世界的卡片"""
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_card_style())
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.custom_minimum_size = Vector2(0, 80)
	panel.add_child(hbox)
	
	# 图标
	var icon = Label.new()
	icon.text = "📂" if world_info.get("game_mode") or "" != "hardcore" else "💀"
	icon.add_theme_font_size_override("font_size", 32)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.custom_minimum_size = Vector2(50, 0)
	hbox.add_child(icon)
	
	# 信息
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	var mode_icon = "🟢" if world_info.get("game_mode") or "survival" == "survival" else "🔴" if world_info.get("game_mode") == "hardcore" else "🟡"
	name_label.text = "%s %s  (seed: %d)" % [mode_icon, world_info.get("name") or "?", world_info.get("seed") or 0]
	name_label.add_theme_font_size_override("font_size", 18)
	info_vbox.add_child(name_label)
	
	var meta_label = Label.new()
	var play_time = world_info.get("play_time") or 0.0
	var hours = int(play_time / 3600)
	var mins = int(int(play_time) % 3600 / 60)
	var created = _format_time(world_info.get("created") or 0)
	meta_label.text = "模式: %s | 游玩: %dh%02dm | 创建: %s" % [
		world_info.get("game_mode") or "survival", hours, mins, created
	]
	meta_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	meta_label.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(meta_label)
	
	hbox.add_child(info_vbox)
	
	# 操作按钮
	var btn_vbox = VBoxContainer.new()
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var enter_btn = Button.new()
	enter_btn.text = "进入"
	enter_btn.custom_minimum_size = Vector2(80, 36)
	enter_btn.pressed.connect(_on_enter_world.bind(world_info.get("name") or ""))
	btn_vbox.add_child(enter_btn)
	
	var del_btn = Button.new()
	del_btn.text = "删除"
	del_btn.custom_minimum_size = Vector2(80, 36)
	del_btn.pressed.connect(_on_delete_world.bind(world_info.get("name") or ""))
	btn_vbox.add_child(del_btn)
	
	hbox.add_child(btn_vbox)
	
	return panel

func _make_card_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.15, 0.8)
	style.set_border_width_all(1)
	style.border_color = Color(0.2, 0.25, 0.3, 0.5)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

func _format_time(unix_time: float) -> String:
	var dt = Time.get_datetime_dict_from_unix_time(int(unix_time))
	return "%d-%02d-%02d" % [dt.year, dt.month, dt.day]

# ==================== 操作回调 ====================

func _on_enter_world(name: String) -> void:
	world_selected.emit(name)

func _on_create() -> void:
	create_new_world.emit()

func _on_join() -> void:
	join_multiplayer.emit()

func _on_settings() -> void:
	settings_requested.emit()

func _on_delete_world(name: String) -> void:
	var wm = get_node("/root/WorldManager") if has_node("/root/WorldManager") else null
	if wm:
		wm.delete_world(name)
	_refresh_list()
