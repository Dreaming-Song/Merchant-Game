extends Control
## 对话面板 — NPC对话界面
##
## 支持：多轮对话、选项分支、任务接取/交付
## 通过 UIManager 打开/关闭

class_name DialoguePanel

signal dialogue_ended()

var _current_npc: Node = null
var _current_node_id: String = ""
var _dialogue_data: Dictionary = {}

# UI 控件（动态创建）
var _speaker_label: Label
var _portrait_rect: TextureRect
var _text_label: Label
var _options_container: VBoxContainer

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	"""创建对话面板 UI"""
	# 半透明背景
	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.6)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	add_child(bg)
	
	# 对话窗口
	var panel = Panel.new()
	panel.anchors_preset = Control.PRESET_CENTER_BOTTOM
	panel.offset_top = -200
	panel.offset_bottom = -20
	panel.offset_left = -300
	panel.offset_right = 300
	add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	
	# 发言人
	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 18)
	_speaker_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
	vbox.add_child(_speaker_label)
	
	# 对话文本
	_text_label = Label.new()
	_text_label.add_theme_font_size_override("font_size", 16)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size = Vector2(500, 80)
	vbox.add_child(_text_label)
	
	# 选项容器
	_options_container = VBoxContainer.new()
	_options_container.add_theme_constant_override("separation", 6)
	vbox.add_child(_options_container)
	
	# 关闭按钮（动态按键）
	var close_hint = Label.new()
	var ih = get_node("/root/InputHandler") if has_node("/root/InputHandler") else null
	var close_key = "B"
	if ih and ih.has_method("is_gamepad_mode") and ih.is_gamepad_mode():
		close_key = "B"
	close_hint.text = "按 ESC 或 %s 关闭对话" % close_key
	close_hint.add_theme_font_size_override("font_size", 12)
	close_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(close_hint)

func start_dialogue(npc: Node) -> void:
	"""开始与 NPC 对话"""
	_current_npc = npc
	_speaker_label.text = npc.get("display_name") or npc.name if npc else "??? "
	
	# 获取对话数据
	if npc and npc.has_method("get_dialogue"):
		_dialogue_data = npc.get_dialogue()
		_current_node_id = _dialogue_data.get("start_node") or "greeting"
		_show_node(_current_node_id)
	else:
		# 默认对话
		_text_label.text = "你好，旅者！"
		_clear_options()
		_add_option("再见", "_end_dialogue")

func _show_node(node_id: String) -> void:
	"""显示对话节点"""
	_current_node_id = node_id
	var node_data = _dialogue_data.get("nodes", {}).get(node_id, {})
	if node_data.is_empty():
		_text_label.text = "……"
		_add_option("（离开）", "_end_dialogue")
		return
	
	_text_label.text = node_data.get("text") or "……"
	_clear_options()
	
	# 选项
	var options = node_data.get("options") or []
	for opt in options:
		var text = opt.get("text") or "继续"
		var next = opt.get("next") or ""
		var condition = opt.get("condition") or ""
		
		# 检查条件
		if not condition.is_empty():
			if not _check_condition(condition):
				continue
		
		# 如果是任务相关，显示特殊标记
		var prefix = ""
		if opt.has("quest_start"):
			prefix = "📋 "
		elif opt.has("quest_complete"):
			prefix = "✅ "
		
		_add_option(prefix + text, "_on_option_selected", {"next": next, "data": opt})

func _on_option_selected(data: Dictionary) -> void:
	var next = data.get("next") or ""
	var opt = data.get("data", {})
	
	# 触发任务事件
	if opt.has("quest_start"):
		var qs = get_node("/root/QuestSystem") if has_node("/root/QuestSystem") else null
		if qs and qs.has_method("accept_quest"):
			qs.accept_quest(opt["quest_start"])
	
	if opt.has("quest_complete"):
		var qs = get_node("/root/QuestSystem") if has_node("/root/QuestSystem") else null
		if qs and qs.has_method("complete_quest"):
			qs.complete_quest(opt["quest_complete"])
	
	if opt.has("action"):
		var action = opt["action"]
		match action:
			"open_shop":
				_open_shop()
			"open_crafting":
				_open_crafting()
			"heal_player":
				_heal_player()
			"teleport":
				_teleport_player(opt.get("target") or "")
	
	if next == "_end" or next.is_empty():
		_end_dialogue()
	else:
		_show_node(next)

func _check_condition(condition: String) -> bool:
	# 简单条件检查
	if condition.begins_with("quest_active:"):
		var quest_id = condition.trim_prefix("quest_active:")
		var qs = get_node("/root/QuestSystem") if has_node("/root/QuestSystem") else null
		return qs != null and qs.has_method("is_quest_active") and qs.is_quest_active(quest_id)
	
	if condition.begins_with("quest_completed:"):
		var quest_id = condition.trim_prefix("quest_completed:")
		var qs = get_node("/root/QuestSystem") if has_node("/root/QuestSystem") else null
		return qs != null and qs.has_method("is_quest_completed") and qs.is_quest_completed(quest_id)
	
	if condition.begins_with("has_item:"):
		var item_id = condition.trim_prefix("has_item:")
		var gm = get_node("/root/GameManager") if has_node("/root/GameManager") else null
		return gm != null and gm.has_method("has_item") and gm.has_item(item_id, 1)
	
	if condition.begins_with("realm:"):
		var min_realm = int(condition.trim_prefix("realm:"))
		var gm = get_node("/root/GameManager") if has_node("/root/GameManager") else null
		return gm != null and gm.realm.get_current_realm() >= min_realm
	
	return true

func _add_option(text: String, method: String, bind_data: Dictionary = {}) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 36)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	if bind_data.is_empty():
		btn.pressed.connect(Callable(self, method))
	else:
		btn.pressed.connect(Callable(self, method).bind(bind_data))
	
	_options_container.add_child(btn)

func _clear_options() -> void:
	for child in _options_container.get_children():
		child.queue_free()

func _end_dialogue() -> void:
	dialogue_ended.emit()
	_current_npc = null
	_current_node_id = ""
	_dialogue_data = {}
	visible = false

# ==================== 特殊操作 ====================

func _open_shop() -> void:
	var ui = get_node("/root/UIManager") if has_node("/root/UIManager") else null
	if ui:
		ui.open_panel("shop")

func _open_crafting() -> void:
	var ui = get_node("/root/UIManager") if has_node("/root/UIManager") else null
	if ui:
		ui.open_panel("crafting")

func _heal_player() -> void:
	var pc = get_tree().get_first_node_in_group("player_controller")
	if pc and pc.has_method("heal"):
		pc.heal(9999)

func _teleport_player(target_id: String) -> void:
	var gm = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	if gm and gm.has_method("teleport_to"):
		gm.teleport_to(target_id)
