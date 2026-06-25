extends Node
## 资源视觉生成器 — 为 ResourceNode 创建程式化 3D 模型
##
## 用法：ResourceVisuals.create_visual(resource_type, parent_node)
## 支持类型：herb / ore / tree / crystal / chest / flower

class_name ResourceVisuals

# ==================== 资源配置 ====================
const RESOURCE_VISUALS: Dictionary = {
	"herb_spirit_grass": {"type": "herb", "color": Color(0.2, 0.85, 0.2), "size": 0.5, "glow": false},
	"herb_jade_flower":  {"type": "flower", "color": Color(0.3, 1.0, 0.5), "size": 0.6, "glow": true},
	"herb_flame_flower": {"type": "flower", "color": Color(1.0, 0.3, 0.1), "size": 0.5, "glow": true},
	"herb_ice_lotus":    {"type": "flower", "color": Color(0.3, 0.6, 1.0), "size": 0.5, "glow": true},
	"herb_toadstool":    {"type": "mushroom", "color": Color(0.9, 0.3, 0.5), "size": 0.4, "glow": false},
	"herb_ghost_flower": {"type": "flower", "color": Color(0.6, 0.3, 0.9), "size": 0.4, "glow": true},
	"herb_fire_root":    {"type": "herb", "color": Color(0.8, 0.2, 0.0), "size": 0.5, "glow": true},
	"ore_copper":        {"type": "crystal", "color": Color(0.8, 0.5, 0.2), "size": 0.8, "glow": false},
	"ore_iron":          {"type": "crystal", "color": Color(0.6, 0.5, 0.4), "size": 0.9, "glow": false},
	"ore_silver":        {"type": "crystal", "color": Color(0.7, 0.7, 0.8), "size": 0.7, "glow": true},
	"ore_gold":          {"type": "crystal", "color": Color(1.0, 0.8, 0.1), "size": 0.6, "glow": true},
	"ore_ancient":       {"type": "crystal", "color": Color(0.2, 0.4, 0.6), "size": 1.0, "glow": true},
	"chest_common":      {"type": "chest", "color": Color(0.5, 0.3, 0.1), "size": 0.8, "glow": false},
	"chest_rare":        {"type": "chest", "color": Color(0.3, 0.5, 0.8), "size": 0.8, "glow": true},
	"chest_epic":        {"type": "chest", "color": Color(0.6, 0.2, 0.8), "size": 0.9, "glow": true},
	"tree_wood":         {"type": "tree", "color": Color(0.2, 0.5, 0.1), "size": 2.0, "glow": false},
	"tree_spirit_wood":  {"type": "tree", "color": Color(0.3, 0.8, 0.4), "size": 2.5, "glow": true},
}

# ==================== 主入口 ====================

static func create_visual(resource_type: String, parent: Node3D) -> MeshInstance3D:
	"""为 ResourceNode 创建视觉 + 返回主 MeshInstance3D 引用"""
	var config = RESOURCE_VISUALS.get(resource_type, {"type": "herb", "color": Color.GREEN, "size": 0.5, "glow": false})
	
	match config.get("type", ""):
		"herb": return _create_herb(parent, config)
		"flower": return _create_flower(parent, config)
		"mushroom": return _create_mushroom(parent, config)
		"crystal": return _create_crystal(parent, config)
		"tree": return _create_tree(parent, config)
		"chest": return _create_chest(parent, config)
		_:
			var box = _add_mesh(parent, BoxMesh.new(), config.get("color", Color.WHITE), config.get("size", 1.0))
			box.position.y = config.get("size", 1.0) / 2
			return box

static func get_config(resource_type: String) -> Dictionary:
	return RESOURCE_VISUALS.get(resource_type, {})

# ==================== 草药 ====================

static func _create_herb(parent: Node3D, config: Dictionary) -> MeshInstance3D:
	"""小草：茎 + 叶子"""
	var size = config.get("size", 1.0)
	var color = config.get("color", Color.WHITE)
	
	# 茎（细圆柱）
	var stem = _add_mesh(parent, CylinderMesh.new(), Color(0.3, 0.5, 0.2), 0.04, size * 0.6)
	stem.position.y = size * 0.3
	
	# 叶子（2片交叉的薄片）
	for i in range(3):
		var leaf = _add_mesh(parent, BoxMesh.new(), color, 0.3 * size, 0.02, 0.15 * size)
		leaf.position.y = size * 0.5
		leaf.rotation_degrees.y = i * 60.0
		leaf.rotation_degrees.z = -30.0
	
	# 发光（如果是稀有）
	if config.get("glow", false):
		_add_glow(parent, color, size * 0.3)
	
	return stem

# ==================== 花朵 ====================

static func _create_flower(parent: Node3D, config: Dictionary) -> MeshInstance3D:
	"""花朵：茎 + 花瓣 + 花心"""
	var size = config.get("size", 1.0)
	var color = config.get("color", Color.WHITE)
	
	# 茎
	var stem = _add_mesh(parent, CylinderMesh.new(), Color(0.2, 0.5, 0.15), 0.03, size * 0.7)
	stem.position.y = size * 0.35
	
	# 花瓣（5片）
	var petal_color = Color(color.r, color.g, color.b, 0.9)
	for i in range(5):
		var petal = _add_mesh(parent, BoxMesh.new(), petal_color, 0.25 * size, 0.02, 0.12 * size)
		petal.position.y = size * 0.7
		petal.rotation_degrees.y = i * 72.0
		petal.rotation_degrees.x = 30.0
	
	# 花心（小圆球）
	var center = _add_mesh(parent, SphereMesh.new(), Color.YELLOW, 0.06 * size)
	center.position.y = size * 0.72
	
	# 发光
	if config.get("glow", false):
		_add_glow(parent, color, size * 0.4)
	
	return stem

# ==================== 蘑菇 ====================

static func _create_mushroom(parent: Node3D, config: Dictionary) -> MeshInstance3D:
	"""蘑菇：伞盖 + 柄"""
	var size = config.get("size", 1.0)
	var color = config.get("color", Color.WHITE)
	
	# 柄
	var stem = _add_mesh(parent, CylinderMesh.new(), Color(0.9, 0.85, 0.7), 0.05, size * 0.4)
	stem.position.y = size * 0.2
	
	# 伞盖
	var cap = _add_mesh(parent, SphereMesh.new(), color, size * 0.3, size * 0.15)
	cap.position.y = size * 0.45
	cap.scale = Vector3(1.0, 0.4, 1.0)
	
	# 伞盖斑点
	if config.get("glow", false):
		for i in range(3):
			var dot = _add_mesh(parent, SphereMesh.new(), Color.WHITE, 0.04)
			dot.position = Vector3(
				randf_range(-0.12, 0.12) * size,
				size * 0.5,
				randf_range(-0.12, 0.12) * size
			)
	
	return stem

# ==================== 矿石晶体 ====================

static func _create_crystal(parent: Node3D, config: Dictionary) -> MeshInstance3D:
	"""晶体：主晶体 + 小晶体 + 底座"""
	var size = config.get("size", 1.0)
	var color = config.get("color", Color.WHITE)
	
	# 底座（扁石）
	var base = _add_mesh(parent, BoxMesh.new(), Color(0.3, 0.3, 0.25), size * 0.8, 0.1, size * 0.8)
	base.position.y = 0.05
	
	# 主晶体（多棱锥用圆柱+锥体组合）
	var crystal = _add_mesh(parent, CylinderMesh.new(), color, size * 0.15, size * 0.6)
	crystal.position.y = size * 0.35
	# 顶部锥体
	var tip = _add_mesh(parent, CylinderMesh.new(), Color(color.r * 1.2, color.g * 1.2, color.b * 1.2), size * 0.08, size * 0.3)
	tip.position.y = size * 0.7
	
	# 侧面小晶体（2~3个）
	for i in range(randi_range(1, 3)):
		var small = _add_mesh(parent, CylinderMesh.new(), color, size * 0.06, size * 0.2)
		small.position = Vector3(
			randf_range(-0.3, 0.3) * size,
			randf_range(0.15, 0.4) * size,
			randf_range(-0.3, 0.3) * size
		)
		small.rotation_degrees.z = randf_range(-30, 30)
		small.rotation_degrees.x = randf_range(-30, 30)
	
	# 发光
	if config.get("glow", false):
		_add_glow(parent, color, size * 0.5)
	
	return crystal

# ==================== 树木 ====================

static func _create_tree(parent: Node3D, config: Dictionary) -> MeshInstance3D:
	"""树木：树干 + 树冠"""
	var size = config.get("size", 1.0)
	var color = config.get("color", Color.WHITE)
	
	# 树干
	var trunk = _add_mesh(parent, CylinderMesh.new(), Color(0.4, 0.25, 0.1), size * 0.08, size * 0.7)
	trunk.position.y = size * 0.35
	
	# 树冠（多层球体）
	var canopy_color = color
	var canopy_radius = size * 0.3
	var canopy = _add_mesh(parent, SphereMesh.new(), canopy_color, canopy_radius)
	canopy.position.y = size * 0.75
	
	# 第二层树冠
	var canopy2 = _add_mesh(parent, SphereMesh.new(), Color(canopy_color.r * 0.9, canopy_color.g, canopy_color.b * 0.9), canopy_radius * 0.7)
	canopy2.position = Vector3(0.15 * size, size * 0.65, 0.1 * size)
	
	var canopy3 = _add_mesh(parent, SphereMesh.new(), Color(canopy_color.r * 1.1, canopy_color.g * 1.1, canopy_color.b * 0.9), canopy_radius * 0.6)
	canopy3.position = Vector3(-0.12 * size, size * 0.95, -0.08 * size)
	
	# 发光
	if config.get("glow", false):
		_add_glow(parent, Color(0.5, 1.0, 0.5), size * 0.4)
	
	return trunk

# ==================== 宝箱 ====================

static func _create_chest(parent: Node3D, config: Dictionary) -> MeshInstance3D:
	"""宝箱：箱体 + 箱盖 + 锁扣"""
	var size = config.get("size", 1.0)
	var color = config.get("color", Color.WHITE)
	
	# 箱体
	var body = _add_mesh(parent, BoxMesh.new(), color, size * 0.7, size * 0.3, size * 0.5)
	body.position.y = size * 0.15
	
	# 箱盖（顶部三角形）
	var lid = _add_mesh(parent, BoxMesh.new(), Color(color.r * 1.1, color.g * 1.1, color.b * 1.1), size * 0.72, size * 0.1, size * 0.52)
	lid.position.y = size * 0.35
	lid.rotation_degrees.x = -15.0
	
	# 金色边框
	var trim = _add_mesh(parent, BoxMesh.new(), Color(1.0, 0.8, 0.1), size * 0.74, 0.02, 0.02)
	trim.position.y = size * 0.3
	var trim2 = _add_mesh(parent, BoxMesh.new(), Color(1.0, 0.8, 0.1), 0.02, 0.02, size * 0.54)
	trim2.position.y = size * 0.3
	
	# 锁扣
	var lock = _add_mesh(parent, SphereMesh.new(), Color.YELLOW, size * 0.06)
	lock.position.y = size * 0.36
	lock.position.z = size * 0.2
	
	# 发光
	if config.get("glow", false):
		_add_glow(parent, Color(1.0, 0.8, 0.2), size * 0.5)
	
	return body

# ==================== 工具方法 ====================

static func _add_mesh(parent: Node3D, primitive: PrimitiveMesh, color: Color, size_x: float = 1.0, size_y: float = 1.0, size_z: float = 1.0) -> MeshInstance3D:
	"""添加一个网格实例到父节点"""
	var mi = MeshInstance3D.new()
	
	# 设置网格尺寸
	if primitive is BoxMesh:
		primitive.size = Vector3(size_x, size_y, size_z)
	elif primitive is CylinderMesh:
		primitive.top_radius = size_x
		primitive.bottom_radius = size_x
		primitive.height = size_y
	elif primitive is SphereMesh:
		primitive.radius = size_x
		primitive.height = size_y
	
	# 材质
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.1
	mat.roughness = 0.6
	
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	primitive.material = mat
	mi.mesh = primitive
	parent.add_child(mi)
	
	return mi

static func _add_glow(parent: Node3D, color: Color, radius: float) -> void:
	"""添加发光光晕（半透明球体）"""
	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(color.r, color.g, color.b, 0.15)
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.emission = color
	glow_mat.emission_energy_multiplier = 2.0
	glow_mat.metallic = 0.0
	glow_mat.roughness = 1.0
	
	var glow = MeshInstance3D.new()
	glow.mesh = SphereMesh.new()
	glow.mesh.radius = radius
	glow.mesh.height = radius * 2
	glow.mesh.material = glow_mat
	glow.position.y = radius * 0.5
	parent.add_child(glow)

static func add_idle_animation(parent: Node3D, resource_type: String) -> void:
	"""添加闲置动画（微摆动/呼吸/旋转）"""
	var config = RESOURCE_VISUALS.get(resource_type, {})
	var tween = parent.create_tween().set_loops()
	tween.set_parallel(true)
	
	match config.get("type") or "":
		"herb", "flower", "mushroom":
			# 微摆动
			tween.tween_property(parent, "rotation_degrees", Vector3(randf_range(-2, 2), 0, randf_range(-2, 2)), 1.5)
			tween.tween_property(parent, "rotation_degrees", Vector3.ZERO, 1.5).set_delay(1.5)
		
		"crystal":
			# 呼吸式缩放
			tween.tween_property(parent, "scale", Vector3(1.0, 1.05, 1.0), 2.0)
			tween.tween_property(parent, "scale", Vector3.ONE, 2.0).set_delay(2.0)
		
		"tree":
			# 树冠微摇
			pass  # 树太大不动

static func add_gather_particles(parent: Node3D, resource_type: String) -> void:
	"""添加采集粒子效果（WorldSpawner 中调用）"""
	var config = RESOURCE_VISUALS.get(resource_type, {})
	if not config:
		return
	
	# 用 GPUParticles3D
	var particles = GPUParticles3D.new()
	particles.one_shot = true
	particles.emitting = false
	particles.lifetime = 0.5
	
	# 粒子材质
	var particle_mat = ParticleProcessMaterial.new()
	particle_mat.color = Color(config.get("color", Color.WHITE).r, config.get("color", Color.WHITE).g, config.get("color", Color.WHITE).b, 0.8)
	particle_mat.velocity_min = 1.0
	particle_mat.velocity_max = 3.0
	particle_mat.spread = 180.0
	particle_mat.gravity = Vector3(0, 2, 0)
	particle_mat.scale_min = 0.05
	particle_mat.scale_max = 0.2
	particle_mat.direction = Vector3.UP
	
	particles.process_material = particle_mat
	particles.amount = 8
	particles.position.y = 0.5
	
	parent.add_child(particles)
	
	# 保存引用，供 ResourceNode._play_gather_effect() 调用
	parent.set_meta("_gather_particles", particles)
