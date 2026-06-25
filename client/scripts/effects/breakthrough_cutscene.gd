extends CanvasLayer
## 🌟 突破动画演出 — 全屏境界突破过场
##
## 流程：暗屏(0.5s) → 粒子漩涡(1.5s) → 闪白(0.3s) → 
##       境界名显圣(2s) → 光圈扩散 → 渐亮恢复

class_name BreakthroughCutscene

# ==================== 信号 ====================
signal cutscene_started(realm_name: String)
signal cutscene_finished(realm_name: String)

# ==================== 境界颜色 ====================
const REALM_COLORS = {
	0: Color(0.8, 0.8, 0.8),      # 凡人 - 灰白
	1: Color(0.5, 0.8, 1.0),      # 练气 - 淡蓝
	2: Color(0.3, 1.0, 0.5),      # 筑基 - 翠绿
	3: Color(1.0, 0.8, 0.2),      # 金丹 - 金色
	4: Color(1.0, 0.4, 0.8),      # 元婴 - 粉紫
	5: Color(1.0, 0.3, 0.2),      # 化神 - 赤红
	6: Color(0.6, 0.3, 1.0),      # 大乘 - 紫
	7: Color(0.2, 0.5, 1.0),      # 渡劫 - 冰蓝
	8: Color(1.0, 0.9, 0.5),      # 飞升 - 金白
}

func play_breakthrough(realm_name: String, realm_level: int, callback: Callable = func(): pass) -> void:
	"""播放突破动画"""
	cutscene_started.emit(realm_name)
	
	# 获取主视口大小
	var viewport = get_viewport()
	var size = viewport.get_visible_rect().size
	
	# ----- 1. 暗屏层 -----
	var dark = ColorRect.new()
	dark.name = "DarkOverlay"
	dark.color = Color(0, 0, 0, 1)
	dark.anchors_preset = Control.PRESET_FULL_RECT
	dark.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dark)
	
	# 0.5s 渐暗 + 轻微缩放（呼吸感）
	var t1 = create_tween()
	t1.tween_property(dark, "color", Color(0, 0, 0, 0.8), 0.5)
	await t1.finished
	
	# ----- 2. 粒子漩涡 -----
	var swirl = _create_swirl_particles(REALM_COLORS[realm_level], size)
	add_child(swirl)
	
	# 漩涡动画 1.5s
	var t2 = create_tween()
	t2.tween_property(swirl, "modulate", Color(1, 1, 1, 1), 0.3)
	t2.tween_property(swirl, "rotation_degrees", 360, 1.2).as_relative()
	await t2.finished
	
	# ----- 3. 闪白 -----
	dark.color = Color(1, 1, 1, 0.9)
	await get_tree().create_timer(0.15).timeout
	
	# 清理漩涡
	swirl.queue_free()
	
	# ----- 4. 境界名显圣 -----
	dark.color = Color(0, 0, 0, 0.7)
	
	var realm_label = _create_realm_label(realm_name, REALM_COLORS[realm_level], size)
	add_child(realm_label)
	
	# 境界名动画：放大 + 发光
	var t3 = create_tween()
	t3.tween_property(realm_label, "scale", Vector2(1, 1), 0.8).from(Vector2(0.3, 0.3)).set_trans(Tween.TRANS_ELASTIC)
	t3.parallel().tween_property(realm_label, "modulate", Color(1, 1, 1, 1), 0.6)
	await get_tree().create_timer(1.5).timeout
	
	# ----- 5. 光晕扩散 -----
	var halo = _create_halo(REALM_COLORS[realm_level], size)
	add_child(halo)
	
	var t4 = create_tween()
	t4.tween_property(halo, "scale", Vector2(3, 3), 0.8).set_trans(Tween.TRANS_QUINT)
	t4.parallel().tween_property(halo, "modulate", Color(1, 1, 1, 0), 0.8)
	await t4.finished
	
	# ----- 6. 渐亮恢复 -----
	var t5 = create_tween()
	t5.tween_property(dark, "color", Color(0, 0, 0, 0), 0.5)
	t5.parallel().tween_property(realm_label, "modulate", Color(1, 1, 1, 0), 0.5)
	await t5.finished
	
	# 清理
	dark.queue_free()
	realm_label.queue_free()
	halo.queue_free()
	
	callback.call()
	cutscene_finished.emit(realm_name)

# ==================== 粒子漩涡 ====================

func _create_swirl_particles(color: Color, size: Vector2) -> Node2D:
	"""创建漩涡粒子系统"""
	var swirl = Node2D.new()
	swirl.name = "SwirlParticles"
	swirl.position = size / 2
	
	# 用多个旋转圆圈模拟漩涡
	for i in range(6):
		var ring = ColorRect.new()
		ring.color = Color(color.r, color.g, color.b, 0.15)
		ring.size = Vector2(60 + i * 40, 60 + i * 40)
		ring.position = -ring.size / 2
		ring.material = _make_glow_material(color, 0.3)
		swirl.add_child(ring)
		
		# 每个环独立旋转
		var tw = create_tween()
		tw.tween_property(ring, "rotation", (6 - i) * TAU * 2, 1.5).as_relative()
		tw.parallel().tween_property(ring, "modulate", Color(1, 1, 1, 0), 1.5)
	
	return swirl

# ==================== 境界名标签 ====================

func _create_realm_label(realm_name: String, color: Color, size: Vector2) -> Control:
	"""创建境界名显示控件"""
	var container = Control.new()
	container.name = "RealmLabelContainer"
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 境界名
	var label = Label.new()
	label.text = realm_name
	label.add_theme_font_size_override("font_size", 56)
	label.add_theme_color_override("font_color", color)
	label.modulate = Color(1, 1, 1, 0)
	label.position = size / 2 - Vector2(120, 30)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(label)
	
	# 副标题
	var sub = Label.new()
	sub.text = "✨ 突破成功 ✨"
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9, 0.7))
	sub.position = size / 2 - Vector2(80, 10)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(sub)
	
	# 发光边框
	var glow = ColorRect.new()
	glow.color = Color(color.r, color.g, color.b, 0.3)
	glow.size = Vector2(300, 90)
	glow.position = size / 2 - Vector2(150, 30)
	glow.material = _make_glow_material(color, 0.5)
	container.add_child(glow)
	
	return container

# ==================== 光晕 ====================

func _create_halo(color: Color, size: Vector2) -> ColorRect:
	"""创建扩散光晕"""
	var halo = ColorRect.new()
	halo.name = "Halo"
	halo.color = Color(color.r, color.g, color.b, 0.6)
	halo.size = Vector2(200, 200)
	halo.position = size / 2 - Vector2(100, 100)
	halo.material = _make_glow_material(color, 0.8)
	return halo

# ==================== 材质工具 ====================

func _make_glow_material(color: Color, alpha: float) -> Material:
	"""创建发光材质"""
	var mat = StandardMaterial3D.new() if false else CanvasItemMaterial.new()
	# 2D 模式下用 modulate 就够了
	return null

# ==================== 静态调用 ====================

static func trigger(realm_name: String, realm_level: int) -> void:
	"""便捷静态调用 — 创建临时实例并播放"""
	var inst = load("res://scripts/effects/breakthrough_cutscene.gd").new()
	var root = Engine.get_main_loop().current_scene
	root.add_child(inst)
	inst.play_breakthrough(realm_name, realm_level, func():
		inst.queue_free()
	)
