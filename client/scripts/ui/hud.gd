extends CanvasLayer
## 基础 HUD - Phase 2
## 显示血量、法力、法术冷却、灵宠信息、上下文交互提示

@onready var hp_bar: ProgressBar = $TopBar/HpBar
@onready var mp_bar: ProgressBar = $TopBar/MpBar
@onready var hp_label: Label = $TopBar/HpBar/Label
@onready var mp_label: Label = $TopBar/MpBar/Label
@onready var spell_container: Container = $BottomBar/SpellContainer
@onready var pet_info_label: Label = $TopBar/PetInfo

# 法术槽位 UI 预制体
@onready var spell_slot_scene: PackedScene = preload("res://scenes/ui/spell_slot.tscn")

# 迷雾地图 HUD
@onready var minimap_hud: Control = $MinimapHUD if has_node("MinimapHUD") else _create_minimap()
@onready var boss_hud: Control = $BossHUD if has_node("BossHUD") else _create_boss_hud()
@onready var damage_indicator: Control = $DamageIndicator if has_node("DamageIndicator") else _create_damage_indicator()

# ==================== 交互提示（动态创建） ====================
var interaction_container: CenterContainer  # 屏幕中央的交互提示容器
var interaction_icon: Label
var interaction_key: Label
var interaction_text: Label
var interaction_progress: TextureProgressBar  # 采集进度条

var player_ref: Node
var magic_system_ref: Node
var pet_ref: Node
var detector: Node
var input_handler: Node

func _ready() -> void:
	player_ref = get_tree().get_first_node_in_group("player")
	magic_system_ref = get_node_or_null("/root/MagicSystem")
	pet_ref = get_tree().get_first_node_in_group("pets")
	detector = get_node_or_null("/root/InteractionDetector")
	input_handler = get_node_or_null("/root/InputHandler")
	
	# 创建交互提示 UI
	_build_interaction_hud()
	
	# 连接探测器信号
	if detector and detector.has_signal("target_changed"):
		detector.target_changed.connect(_on_target_changed)
		detector.target_lost.connect(_on_target_lost)
	
	# 初始化法术槽
	_init_spell_slots()
	
	# 输入模式切换提示
	if input_handler and input_handler.has_signal("input_mode_changed"):
		input_handler.input_mode_changed.connect(_on_input_mode_changed)
		# 立即显示当前模式
		_on_input_mode_changed(input_handler.current_mode)

func _build_interaction_hud() -> void:
	"""在屏幕中央底部创建交互提示"""
	interaction_container = CenterContainer.new()
	interaction_container.name = "InteractionPrompt"
	interaction_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interaction_container.visible = false  # 默认隐藏
	add_child(interaction_container)
	
	# 锚定到底部中央
	interaction_container.anchors_preset = Control.PRESET_CENTER_BOTTOM
	interaction_container.offset_bottom = -40
	interaction_container.custom_minimum_size = Vector2(400, 60)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	interaction_container.add_child(hbox)
	
	# 图标
	interaction_icon = Label.new()
	interaction_icon.add_theme_font_size_override("font_size", 28)
	interaction_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(interaction_icon)
	
	# 按键提示（带背景框）
	interaction_key = Label.new()
	interaction_key.add_theme_font_size_override("font_size", 20)
	interaction_key.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	interaction_key.add_theme_stylebox_override("normal", _make_key_style())
	interaction_key.custom_minimum_size = Vector2(40, 36)
	interaction_key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(interaction_key)
	
	# 动作文字
	interaction_text = Label.new()
	interaction_text.add_theme_font_size_override("font_size", 22)
	interaction_text.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	interaction_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(interaction_text)

func _make_key_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.6, 0.6, 0.8, 0.9)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style

func _on_target_changed(target: Dictionary) -> void:
	"""探测到新目标时更新交互提示"""
	var icon = target.get("icon", "❓")
	var action = target.get("action", "交互")
	var hint = target.get("hint", "")
	var dist = target.get("distance", 999)
	
	# 获取按键提示
	var key = "E"
	if input_handler and input_handler.has_method("get_action_hint"):
		key = input_handler.get_action_hint("interact")
	
	interaction_icon.text = icon
	interaction_key.text = key
	interaction_text.text = "%s %s" % [action, hint]
	
	# 距离着色（超出范围变红）
	if dist > 4.5:
		interaction_text.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		interaction_text.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	interaction_container.visible = true

func _on_target_lost() -> void:
	"""目标丢失时隐藏提示"""
	interaction_container.visible = false

# ==================== 迷雾地图 ====================

func _create_minimap() -> Control:
	"""动态创建迷雾地图 HUD"""
	var mm = preload("res://scripts/ui/minimap_hud.gd").new()
	mm.name = "MinimapHUD"
	add_child(mm)
	return mm

func _create_boss_hud() -> Control:
	var hud = preload("res://scripts/ui/boss_hud.gd").new()
	hud.name = "BossHUD"
	hud.visible = false
	add_child(hud)
	return hud

func _create_damage_indicator() -> Control:
	var di = preload("res://scripts/ui/damage_indicator.gd").new()
	di.name = "DamageIndicator"
	add_child(di)
	return di

# ==================== 原有功能 ====================

func _process(_delta: float) -> void:
	if player_ref == null:
		return
	
	_update_hp_mp()
	_update_spell_cooldowns()
	_update_pet_info()

func _init_spell_slots() -> void:
	"""创建法术快捷键UI"""
	if magic_system_ref == null:
		return
	var spells = magic_system_ref.get_unlocked_spells()
	var keys = ["1", "2", "3", "4", "5"]
	for i in range(spells.size()):
		var slot = spell_slot_scene.instantiate()
		slot.setup(spells[i].get("name", ""), keys[i], spells[i].get("type", 0))
		spell_container.add_child(slot)

func _update_hp_mp() -> void:
	"""更新血量和法力条"""
	if player_ref.has_method("get_hp_ratio"):
		hp_bar.value = player_ref.get_hp_ratio() * 100
		hp_label.text = "%d/%d" % [player_ref.get_hp(), player_ref.get_max_hp()]

	if player_ref.has_method("get_mp_ratio"):
		mp_bar.value = player_ref.get_mp_ratio() * 100
		mp_label.text = "%d/%d" % [player_ref.get_mp(), player_ref.get_max_mp()]

func _update_spell_cooldowns() -> void:
	"""更新法术冷却显示"""
	if magic_system_ref == nil:
		return
	for slot in spell_container.get_children():
		if slot.has_method("update_cooldown"):
			var spell_type = slot.get("spell_type", 0) if slot.has_method("get") else 0
			var ratio = magic_system_ref.get_spell_cooldown_ratio(spell_type)
			slot.update_cooldown(ratio)

func _update_pet_info() -> void:
	"""更新灵宠信息"""
	if pet_ref == null:
		pet_info_label.text = ""
		return
	var info = pet_ref.get_pet_info()
	pet_info_label.text = "%s Lv.%d ❤️%d" % [info.name, info.level, info.loyalty]

func _on_input_mode_changed(mode: int) -> void:
	"""输入模式切换时更新 HUD 提示文本"""
	var input_hint = $InputModeHint if has_node("InputModeHint") else null
	if not input_hint:
		# 动态创建
		input_hint = Label.new()
		input_hint.name = "InputModeHint"
		input_hint.add_theme_font_size_override("font_size", 14)
		input_hint.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 0.8))
		input_hint.anchors_preset = Control.PRESET_TOP_RIGHT
		input_hint.offset_top = 8
		input_hint.offset_right = -8
		add_child(input_hint)
	
	match mode:
		0: input_hint.text = "⌨️ 键鼠"
		1: input_hint.text = "🎮 手柄"
		2: input_hint.text = "👆 触屏"
	
	input_hint.show()
	# 3秒后淡出
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(input_hint):
		input_hint.hide()

func show_interaction_hint(text: String) -> void:
	"""保留旧接口兼容"""
	interaction_text.text = text
	interaction_container.visible = true
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(interaction_container):
		interaction_container.visible = false

func show_notification(text: String, color: Color = Color.WHITE) -> void:
	"""显示浮动通知"""
	# TODO: 实现通知动画
	pass
