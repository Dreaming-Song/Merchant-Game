extends Control
## 战斗伤害指示器 — 在3D世界位置显示浮动伤害数字
##
## 自动监听从场景中敌人发出的伤害信号
## 支持普通伤害、暴击、治疗三种样式

class_name DamageIndicator

var _label_pool: Array[Label] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_damage(world_pos: Vector3, damage: int, color: Color = Color(1.0, 0.3, 0.2)) -> void:
	var label = _get_label()
	label.text = "-%d" % damage
	label.modulate = color
	label.add_theme_font_size_override("font_size", 20)
	
	var camera = get_viewport().get_camera_3d()
	if not camera: return
	var screen_pos = camera.unproject_position(world_pos)
	screen_pos += Vector2(randf_range(-30, 30), randf_range(-20, 20))
	label.position = screen_pos - Vector2(20, 10)
	label.visible = true
	
	var tween = create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -40), 0.8)
	tween.tween_property(label, "modulate", Color(color.r, color.g, color.b, 0), 0.8)
	tween.tween_callback(_return_label.bind(label))

func show_heal(world_pos: Vector3, amount: int) -> void:
	show_damage(world_pos, amount, Color(0.3, 1.0, 0.3))

func show_critical(world_pos: Vector3, damage: int) -> void:
	var label = _get_label()
	label.text = "-%d‼️" % damage
	label.modulate = Color(1.0, 0.8, 0.1)
	label.add_theme_font_size_override("font_size", 28)
	
	var camera = get_viewport().get_camera_3d()
	if not camera: return
	var screen_pos = camera.unproject_position(world_pos)
	screen_pos += Vector2(randf_range(-20, 20), randf_range(-15, 15))
	label.position = screen_pos - Vector2(30, 15)
	label.visible = true
	
	var tween = create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -60), 1.0)
	tween.tween_property(label, "modulate", Color(1, 1, 0, 0), 1.0)
	tween.tween_callback(_return_label.bind(label))

func _get_label() -> Label:
	for l in _label_pool:
		if not l.visible: return l
	var label = Label.new()
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = false
	add_child(label)
	_label_pool.append(label)
	return label

func _return_label(label: Label) -> void:
	label.visible = false
	label.text = ""
	label.add_theme_font_size_override("font_size", 20)
