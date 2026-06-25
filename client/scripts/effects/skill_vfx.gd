extends Node
## ⚡ 技能特效系统 — 为每个技能生成视觉粒子特效
##
## 挂在场景树上，SkillManager 调用 play_effect(skill_id, position, direction)
## 使用 Godot GPUParticles3D / CPUParticles2D 模拟修仙法术特效

class_name SkillVFX

# ==================== 特效预设 ====================
enum EffectStyle {
	FIRE_BALL,       # 火球 —— 橙红球体 + 拖尾
	FIRE_EXPLOSION,  # 火焰爆炸 —— 半球扩散
	ICE_BURST,       # 冰霜爆发 —— 白色晶体碎裂
	LIGHTNING_STRIKE,# 雷电 —— 闪电柱 + 闪白
	SWORD_SLASH,     # 剑气 —— 圆弧斩击波
	SWORD_RAIN,      # 万剑诀 —— 多道剑光从天而降
	HEALING_AURA,    # 治疗光环 —— 绿色波纹扩散
	WIND_SLASH,      # 风刃 —— 青色月牙
	POISON_CLOUD,    # 毒雾 —— 紫色烟雾翻涌
	EARTH_SHARD,     # 地刺 —— 黄色尖刺从地面升起
	SHADOW_STRIKE,   # 暗影突袭 —— 黑色残影
	HOLY_LIGHT,      # 圣光 —— 金色光柱
}

# ==================== 颜色方案 ====================
const ELEMENT_COLORS = {
	"金": Color(1.0, 0.85, 0.3),  # 金色/白
	"木": Color(0.3, 0.8, 0.3),    # 翠绿
	"水": Color(0.3, 0.6, 1.0),    # 冰蓝
	"火": Color(1.0, 0.3, 0.1),    # 炽红
	"土": Color(0.7, 0.5, 0.2),    # 土黄
	"雷": Color(0.6, 0.3, 1.0),    # 紫蓝
	"风": Color(0.3, 1.0, 0.8),    # 青绿
	"暗": Color(0.4, 0.1, 0.6),    # 暗紫
	"光": Color(1.0, 0.95, 0.7),   # 白金色
}

var _effect_nodes: Array[Node] = []

# ==================== 主接口 ====================

func play_skill_effect(skill_id: String, position: Vector3, direction: Vector3 = Vector3.FORWARD, 
					   target_position: Vector3 = Vector3.ZERO, element: String = "") -> void:
	"""根据技能 ID 播放对应特效"""
	var style = _skill_to_effect_style(skill_id)
	var color = ELEMENT_COLORS.get(element, Color.WHITE)
	_play_effect(style, position, direction, target_position, color, skill_id)

func play_element_effect(element: String, style: int, position: Vector3, 
						 direction: Vector3 = Vector3.FORWARD, duration: float = 1.0) -> Node:
	"""根据五行元素播放通用特效"""
	var color = ELEMENT_COLORS.get(element, Color.WHITE)
	return _play_effect(style, position, direction, Vector3.ZERO, color, "", duration)

func cleanup() -> void:
	"""清理所有残留特效"""
	for n in _effect_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_effect_nodes.clear()

# ==================== 技能 → 特效映射 ====================

func _skill_to_effect_style(skill_id: String) -> int:
	match skill_id:
		"fire_ball", "fire_wave":       return EffectStyle.FIRE_BALL
		"fire_explosion":               return EffectStyle.FIRE_EXPLOSION
		"frost_array", "ice_spike":     return EffectStyle.ICE_BURST
		"thunder_bolt":                 return EffectStyle.LIGHTNING_STRIKE
		"sword_slash", "sword_flurry":  return EffectStyle.SWORD_SLASH
		"sword_rain", "vengeful_sword": return EffectStyle.SWORD_RAIN
		"heal":                         return EffectStyle.HEALING_AURA
		"wind_blade":                   return EffectStyle.WIND_SLASH
		"poison_mist":                  return EffectStyle.POISON_CLOUD
		"earth_spike":                  return EffectStyle.EARTH_SHARD
		"shadow_assault":               return EffectStyle.SHADOW_STRIKE
		_:
			if "fire" in skill_id:    return EffectStyle.FIRE_BALL
			if "ice" in skill_id:     return EffectStyle.ICE_BURST
			if "thunder" in skill_id: return EffectStyle.LIGHTNING_STRIKE
			if "sword" in skill_id:   return EffectStyle.SWORD_SLASH
			return EffectStyle.FIRE_BALL

# ==================== 特效播放 ====================

func _play_effect(style: int, position: Vector3, direction: Vector3, 
				  target: Vector3, color: Color, skill_id: String,
				  duration: float = 1.5) -> Node:
	"""通用特效播放器"""
	var root_node: Node
	
	match style:
		EffectStyle.FIRE_BALL:
			root_node = _create_projectile(position, direction, color, "fire_trail", duration)
		EffectStyle.FIRE_EXPLOSION:
			root_node = _create_explosion(position, color, 3.0, duration)
		EffectStyle.ICE_BURST:
			root_node = _create_burst(position, color, 2.5, duration)
		EffectStyle.LIGHTNING_STRIKE:
			root_node = _create_lightning(target if target != Vector3.ZERO else position, color, duration)
		EffectStyle.SWORD_SLASH:
			root_node = _create_slash(position, direction, color, duration)
		EffectStyle.SWORD_RAIN:
			root_node = _create_sword_rain(target if target != Vector3.ZERO else position, color, duration)
		EffectStyle.HEALING_AURA:
			root_node = _create_healing_aura(position, color, duration)
		EffectStyle.WIND_SLASH:
			root_node = _create_projectile(position, direction, color, "wind", duration * 0.7)
		EffectStyle.POISON_CLOUD:
			root_node = _create_cloud(position, color, 4.0, duration)
		EffectStyle.EARTH_SHARD:
			root_node = _create_earth_spike(position, color, duration)
		EffectStyle.SHADOW_STRIKE:
			root_node = _create_shadow_strike(position, direction, color, duration)
		_:
			root_node = _create_burst(position, color, 1.0, duration)
	
	if root_node:
		_effect_nodes.append(root_node)
		# 自动清理
		var cleanup_timer = Timer.new()
		cleanup_timer.wait_time = duration + 0.5
		cleanup_timer.one_shot = true
		cleanup_timer.timeout.connect(func():
			if is_instance_valid(root_node):
				root_node.queue_free()
			_effect_nodes.erase(root_node)
		)
		root_node.add_child(cleanup_timer)
		cleanup_timer.start()
	
	return root_node

# ==================== 各特效实现 ====================

func _create_projectile(pos: Vector3, dir: Vector3, color: Color, trail_type: String, dur: float) -> Node3D:
	"""创建飞行弹道特效"""
	var proj = Node3D.new()
	proj.global_position = pos
	
	# 光球
	var ball = MeshInstance3D.new()
	ball.mesh = SphereMesh.new()
	ball.mesh.radius = 0.3
	ball.mesh.height = 0.6
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission = color
	mat.emission_energy_multiplier = 4.0
	ball.material = mat
	proj.add_child(ball)
	
	# 泛光外壳
	var glow = MeshInstance3D.new()
	glow.mesh = SphereMesh.new()
	glow.mesh.radius = 0.5
	glow.mesh.height = 1.0
	var gmat = StandardMaterial3D.new()
	gmat.albedo_color = Color(color.r, color.g, color.b, 0.3)
	gmat.emission = color
	gmat.emission_energy_multiplier = 2.0
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.material = gmat
	proj.add_child(glow)
	
	# 移动 tween
	if dir != Vector3.ZERO:
		var target_pos = pos + dir.normalized() * 10.0
		var tween = create_tween()
		tween.tween_property(proj, "global_position", target_pos, dur * 0.6).set_trans(Tween.TRANS_LINEAR)
		tween.tween_callback(func(): 
			# 到达后爆炸
			_create_burst(proj.global_position, color, 2.0, 0.5)
		)
	
	add_child(proj)
	return proj

func _create_explosion(pos: Vector3, color: Color, radius: float, dur: float) -> Node3D:
	"""创建爆炸特效"""
	var boom = Node3D.new()
	boom.global_position = pos
	
	# 爆炸球壳
	var shell = MeshInstance3D.new()
	shell.mesh = SphereMesh.new()
	shell.mesh.radius = 0.1
	shell.mesh.height = 0.2
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.6)
	mat.emission = color
	mat.emission_energy_multiplier = 5.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shell.material = mat
	boom.add_child(shell)
	
	# 扩散动画
	var tween = create_tween()
	tween.tween_property(shell, "mesh:radius", radius, dur * 0.4)
	tween.parallel().tween_property(shell, "mesh:height", radius * 2, dur * 0.4)
	tween.parallel().tween_method(func(a): 
		if is_instance_valid(shell) and shell.material:
			shell.material.albedo_color.a = a
			shell.material.emission_energy_multiplier = a * 5.0
	, 0.6, 0.0, dur * 0.6)
	
	add_child(boom)
	return boom

func _create_burst(pos: Vector3, color: Color, spread: float, dur: float) -> Node3D:
	"""创建碎片爆发特效"""
	var burst = Node3D.new()
	burst.global_position = pos
	
	# 多个小碎片飞溅
	for i in range(12):
		var shard = MeshInstance3D.new()
		shard.mesh = BoxMesh.new()
		shard.mesh.size = Vector3(0.1, 0.1, 0.1)
		var s_mat = StandardMaterial3D.new()
		s_mat.albedo_color = Color(color.r, color.g, color.b, 0.8)
		s_mat.emission = color
		s_mat.emission_energy_multiplier = 3.0
		shard.material = s_mat
		
		var angle = i * TAU / 12
		var dir = Vector3(cos(angle), randf_range(-0.5, 0.5), sin(angle)).normalized()
		var target = pos + dir * spread
		burst.add_child(shard)
		
		var tw = create_tween()
		tw.tween_property(shard, "global_position", target, dur * 0.5)
		tw.parallel().tween_property(shard, "rotation", Vector3(randf()*6, randf()*6, randf()*6), dur * 0.5)
		tw.tween_property(shard, "modulate", Color(1, 1, 1, 0), dur * 0.3)
	
	add_child(burst)
	return burst

func _create_lightning(pos: Vector3, color: Color, dur: float) -> Node3D:
	"""创建雷电柱特效"""
	var bolt = Node3D.new()
	bolt.global_position = pos
	
	# 闪电柱
	var pillar = MeshInstance3D.new()
	pillar.mesh = CylinderMesh.new()
	pillar.mesh.top_radius = 0.05
	pillar.mesh.bottom_radius = 0.3
	pillar.mesh.height = 8.0
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.7)
	mat.emission = color
	mat.emission_energy_multiplier = 6.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pillar.material = mat
	pillar.global_position = pos + Vector3(0, 4, 0)
	bolt.add_child(pillar)
	
	# 闪白闪烁
	var flash = DirectionalLight3D.new()
	flash.light_color = Color(color.r, color.g, color.b, 0.8)
	flash.light_energy = 0
	bolt.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "light_energy", 10.0, 0.05)
	tween.tween_property(flash, "light_energy", 0, 0.1)
	tween.tween_property(flash, "light_energy", 8.0, 0.05)
	tween.tween_property(flash, "light_energy", 0, 0.3)
	
	# 淡出
	var tween2 = create_tween()
	tween2.tween_interval(dur * 0.5)
	tween2.tween_property(mat, "albedo_color", Color(color.r, color.g, color.b, 0), dur * 0.5)
	tween2.parallel().tween_property(mat, "emission_energy_multiplier", 0, dur * 0.5)
	
	add_child(bolt)
	return bolt

func _create_slash(pos: Vector3, dir: Vector3, color: Color, dur: float) -> Node3D:
	"""创建剑气斩击特效"""
	var slash = Node3D.new()
	slash.global_position = pos
	
	# 半月形剑气
	var arc = MeshInstance3D.new()
	arc.mesh = _create_arc_mesh(1.5, 0.3, 16, color)
	arc.rotation = Vector3(0, atan2(dir.x, dir.z), PI/2)
	slash.add_child(arc)
	
	# 前进动画
	var tween = create_tween()
	tween.tween_property(slash, "global_position", pos + dir * 5.0, dur * 0.5)
	tween.parallel().tween_property(arc, "modulate", Color(1, 1, 1, 0), dur * 0.5).set_delay(dur * 0.2)
	
	add_child(slash)
	return slash

func _create_arc_mesh(radius: float, thickness: float, segments: int, color: Color) -> ArrayMesh:
	"""生成半月剑气网格"""
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	for i in range(segments + 1):
		var t = float(i) / segments * PI
		var p = Vector3(cos(t) * radius, sin(t) * radius * 0.3, 0)
		var p2 = p + Vector3(0, 0, thickness)
		st.set_color(color)
		st.add_vertex(p)
		st.add_vertex(p2)
	
	return st.commit()

func _create_sword_rain(pos: Vector3, color: Color, dur: float) -> Node3D:
	"""创建万剑诀特效"""
	var rain = Node3D.new()
	rain.global_position = pos
	
	for i in range(15):
		var sword = MeshInstance3D.new()
		sword.mesh = _create_sword_mesh(color)
		
		# 随机分布
		var offset = Vector3(randf_range(-4, 4), randf_range(8, 15), randf_range(-4, 4))
		sword.global_position = pos + offset
		sword.rotation = Vector3(PI/2 + randf_range(-0.1, 0.1), randf_range(0, TAU), 0)
		rain.add_child(sword)
		
		# 下落动画
		var ground_target = pos + Vector3(offset.x, 0, offset.z)
		var delay = randf_range(0, dur * 0.6)
		var fall_dur = randf_range(0.3, 0.6)
		
		var tw = create_tween()
		tw.tween_interval(delay)
		tw.tween_property(sword, "global_position", ground_target, fall_dur).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(sword, "rotation:x", PI + randf_range(-0.2, 0.2), fall_dur)
		
		# 落地特效
		tw.tween_callback(func():
			_create_burst(ground_target, color * 0.8, 0.5, 0.3)
		)
	
	add_child(rain)
	return rain

func _create_sword_mesh(color: Color) -> ArrayMesh:
	"""生成简易剑形网格"""
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 剑身（两个三角形组成菱形）
	var h = 0.8
	var w = 0.1
	var vertices = [
		Vector3(0, -h/2, 0),      # 尖
		Vector3(-w, 0, 0),        # 左
		Vector3(0, h/2, 0),       # 尾
		Vector3(w, 0, 0),         # 右
	]
	st.set_color(color * 1.2)
	st.add_vertex(vertices[0]); st.add_vertex(vertices[1]); st.add_vertex(vertices[2])
	st.add_vertex(vertices[0]); st.add_vertex(vertices[2]); st.add_vertex(vertices[3])
	
	return st.commit()

func _create_healing_aura(pos: Vector3, color: Color, dur: float) -> Node3D:
	"""创建治疗光环特效"""
	var aura = Node3D.new()
	aura.global_position = pos
	
	var ring = MeshInstance3D.new()
	ring.mesh = _create_ring_mesh(2.0, 0.1, color)
	ring.global_position = pos + Vector3(0, 0.1, 0)
	aura.add_child(ring)
	
	# 波纹扩散
	var tween = create_tween()
	tween.tween_property(ring, "scale", Vector3(3, 1, 3), dur * 0.6).set_trans(Tween.TRANS_QUINT)
	tween.parallel().tween_property(ring, "modulate", Color(1, 1, 1, 0), dur * 0.6)
	
	add_child(aura)
	return aura

func _create_ring_mesh(radius: float, width: float, color: Color) -> ArrayMesh:
	"""生成圆环网格"""
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	var segments = 24
	for i in range(segments + 1):
		var t = float(i) / segments * TAU
		var outer = Vector3(cos(t) * radius, 0, sin(t) * radius)
		var inner = Vector3(cos(t) * (radius - width), 0, sin(t) * (radius - width))
		st.set_color(color)
		st.add_vertex(outer)
		st.add_vertex(inner)
	
	return st.commit()

func _create_cloud(pos: Vector3, color: Color, radius: float, dur: float) -> Node3D:
	"""创建毒雾/云雾特效"""
	var cloud = Node3D.new()
	cloud.global_position = pos
	
	# 多个半透明球体组成雾团
	for i in range(10):
		var puff = MeshInstance3D.new()
		puff.mesh = SphereMesh.new()
		puff.mesh.radius = randf_range(0.5, 1.2)
		puff.mesh.height = puff.mesh.radius * 2
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(color.r, color.g, color.b, 0.15)
		mat.emission = color * 0.3
		mat.emission_energy_multiplier = 0.5
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		puff.material = mat
		puff.global_position = pos + Vector3(randf_range(-radius, radius), randf_range(0, 0.5), randf_range(-radius, radius))
		cloud.add_child(puff)
	
	add_child(cloud)
	return cloud

func _create_earth_spike(pos: Vector3, color: Color, dur: float) -> Node3D:
	"""创建地刺特效"""
	var spikes = Node3D.new()
	spikes.global_position = pos
	
	for i in range(5):
		var spike = MeshInstance3D.new()
		spike.mesh = CylinderMesh.new()
		spike.mesh.top_radius = 0
		spike.mesh.bottom_radius = 0.2
		spike.mesh.height = 0.1  # 初始高度
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(color.r, color.g, color.b, 0.9)
		mat.emission = color
		mat.emission_energy_multiplier = 2.0
		spike.material = mat
		
		var offset = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
		spike.global_position = pos + offset
		spikes.add_child(spike)
		
		# 刺出动画
		var tw = create_tween()
		tw.tween_interval(randf_range(0, 0.3))
		tw.tween_property(spike.mesh, "height", randf_range(0.5, 1.5), 0.2)
		tw.parallel().tween_property(spike, "position:y", 0, 0.2)
	
	add_child(spikes)
	return spikes

func _create_shadow_strike(pos: Vector3, dir: Vector3, color: Color, dur: float) -> Node3D:
	"""创建暗影突袭特效"""
	var shadow = Node3D.new()
	shadow.global_position = pos
	
	# 残影拖尾
	for i in range(5):
		var afterimage = MeshInstance3D.new()
		afterimage.mesh = BoxMesh.new()
		afterimage.mesh.size = Vector3(0.5, 1.8, 0.3)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(color.r, color.g, color.b, 0.2 - i * 0.03)
		mat.emission = color
		mat.emission_energy_multiplier = 0.5
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		afterimage.material = mat
		afterimage.global_position = pos - dir * (i * 0.5)
		shadow.add_child(afterimage)
		
		var tw = create_tween()
		tw.tween_interval(i * 0.05)
		tw.tween_property(afterimage, "modulate", Color(1, 1, 1, 0), 0.3)
	
	add_child(shadow)
	return shadow
