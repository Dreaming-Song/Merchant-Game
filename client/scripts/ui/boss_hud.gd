extends Control
## BOSS 血条UI — 屏幕顶部大型BOSS血量显示
##
## 出现条件：玩家进入BOSS战斗范围
## 显示：BOSS名称 + 称号 + HP条 + 阶段指示 + 伤害数字

class_name BossHUD

signal combat_left()

var _container: MarginContainer
var _name_label: Label
var _title_label: Label
var _hp_bar: TextureProgressBar
var _hp_label: Label
var _phase_indicator: Label
var _damage_pool: Array[Label] = []
var _current_boss: Node = null
var _is_active: bool = false
var _in_combat: bool = false

func _ready() -> void:
	_build_ui()
	visible = false

func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_container = MarginContainer.new()
	_container.anchors_preset = Control.PRESET_TOP_WIDE
	_container.offset_top = 8
	_container.offset_left = 150
	_container.offset_right = -150
	_container.offset_bottom = 100
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	_container.add_child(vbox)
	
	var name_hbox = HBoxContainer.new()
	name_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	name_hbox.add_theme_constant_override("separation", 8)
	
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 12)
	_title_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9, 0.7))
	name_hbox.add_child(_title_label)
	
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 22)
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	_name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_name_label.add_theme_constant_override("outline_size", 4)
	name_hbox.add_child(_name_label)
	
	_phase_indicator = Label.new()
	_phase_indicator.add_theme_font_size_override("font_size", 14)
	_phase_indicator.add_theme_color_override("font_color", Color(1.0, 0.5, 0.1, 0.9))
	name_hbox.add_child(_phase_indicator)
	
	vbox.add_child(name_hbox)
	
	var hp_hbox = HBoxContainer.new()
	hp_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hp_hbox.add_theme_constant_override("separation", 8)
	
	_hp_bar = TextureProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(400, 20)
	_hp_bar.fill_mode = 0
	_hp_bar.tint_progress = Color(1.0, 0.2, 0.1)
	_hp_bar.tint_under = Color(0.2, 0.05, 0.05)
	_hp_bar.modulate = Color(1, 1, 1, 0.9)
	hp_hbox.add_child(_hp_bar)
	
	_hp_label = Label.new()
	_hp_label.add_theme_font_size_override("font_size", 14)
	_hp_label.add_theme_color_override("font_color", Color.WHITE)
	_hp_label.custom_minimum_size = Vector2(100, 0)
	hp_hbox.add_child(_hp_label)
	
	vbox.add_child(hp_hbox)

func activate(boss: Node) -> void:
	_current_boss = boss
	_is_active = true
	_in_combat = true
	visible = true
	
	if boss.has_method("get_boss_config") and boss.has("boss_type"):
		var config = boss.get_boss_config(boss.boss_type)
		_title_label.text = config.get("title", "未知首领")
		_name_label.text = "🐉 %s" % config.get("name", "")
		_phase_indicator.text = "⚡ Phase 1"
		
		var element = config.get("element", "木")
		match element:
			"木": _hp_bar.tint_progress = Color(0.2, 0.8, 0.3)
			"金": _hp_bar.tint_progress = Color(0.9, 0.9, 0.7)
			"火": _hp_bar.tint_progress = Color(1.0, 0.2, 0.1)
			"水": _hp_bar.tint_progress = Color(0.2, 0.4, 1.0)
			"土": _hp_bar.tint_progress = Color(0.8, 0.6, 0.2)
		
		if not boss.boss_damaged.is_connected(_on_boss_damaged):
			boss.boss_damaged.connect(_on_boss_damaged)
		if not boss.boss_phase_changed.is_connected(_on_phase_changed):
			boss.boss_phase_changed.connect(_on_phase_changed)
		if not boss.boss_defeated.is_connected(_on_boss_defeated):
			boss.boss_defeated.connect(_on_boss_defeated)
		
		_hp_bar.max_value = boss.max_hp if boss.has("max_hp") else 100
		_hp_bar.value = boss.hp if boss.has("hp") else 100
		_hp_label.text = "%d / %d" % [boss.hp, boss.max_hp]

func deactivate() -> void:
	_is_active = false
	_in_combat = false
	_current_boss = null
	visible = false

func _process(delta: float) -> void:
	if not _is_active or not _current_boss or not is_instance_valid(_current_boss):
		if visible: deactivate()
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if player and _current_boss is Node3D:
		var dist = player.global_position.distance_to(_current_boss.global_position)
		if dist > 60.0:
			_in_combat = false
			combat_left.emit()
			deactivate()

func _on_boss_damaged(name: String, damage: int, current_hp: int, max_hp_var: int, phase: int) -> void:
	_hp_bar.max_value = max_hp_var
	_hp_bar.value = current_hp
	_hp_label.text = "%d / %d" % [current_hp, max_hp_var]
	_spawn_damage_number(damage)

func _on_phase_changed(name: String, phase: int) -> void:
	_phase_indicator.text = "🔥 Phase 2" if phase == 2 else "⚡ Phase 1"

func _on_boss_defeated(name: String, boss_type: int) -> void:
	_hp_bar.value = 0
	_hp_label.text = "0 / %d" % _hp_bar.max_value
	_name_label.text = "💀 %s 已被击败！" % name
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(self): deactivate()

func _spawn_damage_number(damage: int) -> void:
	if damage <= 0: return
	var label = _get_damage_label()
	var is_crit = damage > 100
	label.text = "-%d%s" % [damage, "‼️" if is_crit else ""]
	label.modulate = Color(1.0, 0.8, 0.1) if is_crit else Color(1.0, 0.3, 0.2)
	label.add_theme_font_size_override("font_size", 28 if is_crit else 20)
	
	var screen_size = get_viewport_rect().size
	label.position = Vector2(screen_size.x * 0.5 + randf_range(-100, 100), screen_size.y * 0.3 + randf_range(-50, 50))
	label.visible = true
	
	var tween = create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -60), 1.0)
	tween.tween_property(label, "modulate", Color(1, 1, 1, 0), 1.0)
	tween.tween_callback(_return_damage_label.bind(label))

func _get_damage_label() -> Label:
	for l in _damage_pool:
		if not l.visible: return l
	var label = Label.new()
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = false
	add_child(label)
	_damage_pool.append(label)
	return label

func _return_damage_label(label: Label) -> void:
	label.visible = false
	label.text = ""
