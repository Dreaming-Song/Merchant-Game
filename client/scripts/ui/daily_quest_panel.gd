extends Control
## 📋 任务面板 — 按 J 打开
##
## 显示所有可接任务 + 进行中任务 + 每日任务进度
## 半透明背景，按 J/ESC 关闭

class_name DailyQuestPanel

signal closed()

const QuestSystem = preload("res://scripts/quest/quest_system.gd")

var _visible: bool = false
var quest_system_ref: Node = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	quest_system_ref = get_node("/root/QuestSystem") if has_node("/root/QuestSystem") else null
	_build_ui()

func _build_ui() -> void:
	"""构建任务面板 UI"""
	# 半透明背景
	var bg = ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.05, 0.05, 0.1, 0.85)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	
	# 主容器
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainContent"
	main_vbox.anchors_preset = Control.PRESET_CENTER
	main_vbox.custom_minimum_size = Vector2(500, 500)
	main_vbox.add_theme_constant_override("separation", 12)
	add_child(main_vbox)
	
	# 标题
	var title = Label.new()
	title.text = "📜 修行任务"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)
	
	# 按键提示（动态检测手柄/键盘）
	var hint = Label.new()
	var ih = get_node("/root/InputHandler") if has_node("/root/InputHandler") else null
	var close_key = "J"
	if ih and ih.has_method("get_action_hint"):
		close_key = ih.get_action_hint("toggle_quest")
	hint.text = "按 %s / ESC 关闭" % close_key
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(hint)
	
	# 分隔线
	var sep = HSeparator.new()
	main_vbox.add_child(sep)
	
	# 日常任务区
	var daily_title = Label.new()
	daily_title.text = "🌅 日常任务（每日刷新）"
	daily_title.add_theme_font_size_override("font_size", 18)
	daily_title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	main_vbox.add_child(daily_title)
	
	var daily_list = VBoxContainer.new()
	daily_list.name = "DailyList"
	daily_list.add_theme_constant_override("separation", 6)
	main_vbox.add_child(daily_list)
	
	# 分隔线
	var sep2 = HSeparator.new()
	main_vbox.add_child(sep2)
	
	# 可接任务
	var avail_title = Label.new()
	avail_title.text = "📌 可接任务"
	avail_title.add_theme_font_size_override("font_size", 18)
	avail_title.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	main_vbox.add_child(avail_title)
	
	var avail_list = VBoxContainer.new()
	avail_list.name = "AvailableList"
	avail_list.add_theme_constant_override("separation", 6)
	main_vbox.add_child(avail_list)
	
	# 分隔线
	var sep3 = HSeparator.new()
	main_vbox.add_child(sep3)
	
	# 进行中任务
	var active_title = Label.new()
	active_title.text = "⏳ 进行中"
	active_title.add_theme_font_size_override("font_size", 18)
	active_title.add_theme_color_override("font_color", Color(1, 0.8, 0.4))
	main_vbox.add_child(active_title)
	
	var active_list = VBoxContainer.new()
	active_list.name = "ActiveList"
	active_list.add_theme_constant_override("separation", 6)
	main_vbox.add_child(active_list)

func toggle() -> void:
	_visible = not _visible
	if _visible:
		_refresh()
		visible = true
	else:
		visible = false
		closed.emit()

func open() -> void:
	_visible = true
	_refresh()
	visible = true

func close() -> void:
	_visible = false
	visible = false
	closed.emit()

func _refresh() -> void:
	"""刷新所有任务显示"""
	if not quest_system_ref:
		return
	
	_draw_daily_quests()
	_draw_available_quests()
	_draw_active_quests()

func _draw_daily_quests() -> void:
	var list = get_node_or_null("MainContent/DailyList")
	if not list:
		return
	_clear_list(list)
	
	var quests = []
	if quest_system_ref.has_method("get_active_quests"):
		quests = quest_system_ref.get_active_quests()
	
	var has_daily = false
	for q in quests:
		var q_type = q.get("type", -1)
		if q_type == 2:  # QuestType.DAILY
			has_daily = true
			var entry = _make_quest_entry(q, Color(0.4, 0.8, 1.0))
			list.add_child(entry)
	
	if not has_daily:
		var label = Label.new()
		label.text = "暂无日常任务，休息一下吧 ☕"
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		list.add_child(label)

func _draw_available_quests() -> void:
	var list = get_node_or_null("MainContent/AvailableList")
	if not list:
		return
	_clear_list(list)
	
	var quests = []
	if quest_system_ref.has_method("get_available_quests"):
		quests = quest_system_ref.get_available_quests()
	
	if quests.is_empty():
		var label = Label.new()
		label.text = "暂无可用任务"
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		list.add_child(label)
	else:
		for q in quests:
			var entry = _make_quest_entry(q, Color(0.6, 1.0, 0.6))
			list.add_child(entry)

func _draw_active_quests() -> void:
	var list = get_node_or_null("MainContent/ActiveList")
	if not list:
		return
	_clear_list(list)
	
	var quests = []
	if quest_system_ref.has_method("get_active_quests"):
		quests = quest_system_ref.get_active_quests()
	
	if quests.is_empty():
		var label = Label.new()
		label.text = "当前没有进行中的任务"
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		list.add_child(label)
	else:
		for q in quests:
			var entry = _make_quest_entry(q, Color(1, 0.8, 0.4))
			list.add_child(entry)

func _make_quest_entry(q: Dictionary, color: Color) -> Control:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	
	var icon = Label.new()
	icon.text = q.get("icon") or "📌"
	icon.add_theme_color_override("font_color", color)
	icon.custom_minimum_size = Vector2(24, 0)
	hbox.add_child(icon)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	
	var name_label = Label.new()
	name_label.text = q.get("name") or "任务"
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", color)
	vbox.add_child(name_label)
	
	var step_desc = q.get("step_desc") or ""
	var step_progress = q.get("step_progress") or 0
	var step_target = q.get("step_target") or 0
	
	if step_desc:
		var desc_label = Label.new()
		if step_target > 0:
			desc_label.text = "  %s %d/%d" % [step_desc, step_progress, step_target]
		else:
			desc_label.text = "  %s" % step_desc
		desc_label.add_theme_font_size_override("font_size", 13)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		vbox.add_child(desc_label)
	
	hbox.add_child(vbox)
	return hbox

func _clear_list(list: Container) -> void:
	for child in list.get_children():
		child.queue_free()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	# ESC / 手柄 B 键关闭
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
		close()
