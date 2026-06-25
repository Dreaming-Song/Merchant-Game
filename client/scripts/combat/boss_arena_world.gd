extends Node3D
## 🏯 秘境场景 — 独立加载/卸载的BOSS竞技场
##
## 每个神兽秘境都是一个独立的自包含场景：
## - 地面 + 元素法阵 + 围墙 + 装饰 + 出口传送门
## - 区域环境：雾/光/氛围
## - WorldEnvironment 覆盖
## - 使用后从场景树移除

class_name BossArenaWorld

# ==================== 秘境配置引用 ====================
var boss_key: String = ""
var config: Dictionary = {}

# ==================== 子节点引用 ====================
var ground: MeshInstance3D
var element_circle: MeshInstance3D
var walls: Array[MeshInstance3D] = []
var decorations: Array[MeshInstance3D] = []
var exit_portal: Area3D
var boss_spawn_point: Marker3D
var player_spawn_point: Marker3D
var env: WorldEnvironment

# ==================== 信号 ====================
signal player_request_exit(player: Node)

# ==================== 颜色调色板 ====================
const ELEMENT_COLORS = {
	"木": Color("#2a8a5a"),
	"金": Color("#e0d8c0"),
	"火": Color("#d83a20"),
	"水": Color("#2a5a8a"),
	"土": Color("#b09840"),
}

const FOG_COLORS = {
	"木": Color("#1a3a2a"),
	"金": Color("#3a3a3a"),
	"火": Color("#3a1a0a"),
	"水": Color("#1a2a3a"),
	"土": Color("#3a2a1a"),
}

func _init(p_boss_key: String, p_config: Dictionary, position: Vector3) -> void:
	boss_key = p_boss_key
	config = p_config
	global_position = position
	name = "Arena_%s" % boss_key

func _ready() -> void:
	_build_arena()

# ==================== 构建竞技场 ====================

func _build_arena() -> void:
	_add_world_environment()
	_add_ground()
	_add_element_circle()
	_add_walls()
	_add_decorations()
	_add_spawn_points()
	_add_exit_portal()

func _add_world_environment() -> void:
	"""创建独立的WorldEnvironment覆盖主世界环境"""
	env = WorldEnvironment.new()
	env.name = "ArenaEnvironment"
	
	var world_env = Environment.new()
	
	# 雾 — 秘境专属颜色
	var fog_color = FOG_COLORS.get(config["element"], Color("#1a1a2a"))
	world_env.background_mode = Environment.BG_SKY
	world_env.background_color = fog_color
	world_env.fog_enabled = true
	world_env.fog_density = 0.005
	world_env.fog_color = fog_color
	
	# 环境光
	world_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world_env.ambient_light_color = config["ambient_color"]
	world_env.ambient_light_energy = 0.6
	
	# 辉光 (秘境氛围)
	world_env.glow_enabled = true
	world_env.glow_intensity = 0.3
	world_env.glow_hdr_threshold = 0.8
	world_env.glow_bloom = 0.2
	
	env.environment = world_env
	add_child(env)

func _add_ground() -> void:
	"""圆形竞技场地面"""
	var radius = config.get("arena_radius") or 30.0
	var ground_color = config.get("ground_color") or Color("#3a3a2a")
	
	# 大圆盘地面
	var ground_mesh = CylinderMesh.new()
	ground_mesh.top_radius = radius
	ground_mesh.bottom_radius = radius
	ground_mesh.height = 0.5
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = ground_color
	mat.metallic = 0.3
	mat.roughness = 0.8
	
	ground = MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = ground_mesh
	ground.material_override = mat
	ground.position.y = -0.25
	add_child(ground)
	
	# 外圈环形光带（边界提示）
	var ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = radius - 0.5
	ring_mesh.outer_radius = radius
	ring_mesh.ring_count = 32
	
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = config["color"]
	ring_mat.emission_enabled = true
	ring_mat.emission = config["color"] * 0.4
	ring_mat.emission_energy_multiplier = 0.3
	
	var ring = MeshInstance3D.new()
	ring.name = "RingBorder"
	ring.mesh = ring_mesh
	ring.material_override = ring_mat
	ring.position.y = 0.1
	add_child(ring)

func _add_element_circle() -> void:
	"""中心五行法阵图案"""
	var element = config["element"]
	var color = ELEMENT_COLORS.get(element, Color.WHITE)
	
	# 圆环阵
	for i in range(3):
		var ring = TorusMesh.new()
		ring.inner_radius = 1.0 + i * 0.8
		ring.outer_radius = 1.2 + i * 0.8
		ring.ring_count = 16
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.5 - i * 0.1
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.alpha = 0.4 - i * 0.1
		
		var ring_mesh = MeshInstance3D.new()
		ring_mesh.mesh = ring
		ring_mesh.material_override = mat
		ring_mesh.position.y = 0.2
		ring_mesh.rotation.x = deg_to_rad(90)
		add_child(ring_mesh)
	
	# 元素符号（使用文字Mesh或Cube组合）
	# 简化：中心光柱
	var pillar = CylinderMesh.new()
	pillar.top_radius = 0.15
	pillar.bottom_radius = 0.3
	pillar.height = 2.0
	
	var pillar_mat = StandardMaterial3D.new()
	pillar_mat.albedo_color = color
	pillar_mat.emission_enabled = true
	pillar_mat.emission = color
	pillar_mat.emission_energy_multiplier = 0.8
	pillar_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pillar_mat.alpha = 0.6
	
	var pillar_mesh = MeshInstance3D.new()
	pillar_mesh.mesh = pillar
	pillar_mesh.material_override = pillar_mat
	pillar_mesh.position.y = 1.0
	add_child(pillar_mesh)

func _add_walls() -> void:
	"""边界墙 — 半透明元素墙"""
	var radius = config.get("arena_radius") or 30.0
	var wall_height = 6.0
	var color = config["color"]
	var segments = 16
	
	for i in range(segments):
		var angle = i * TAU / segments
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		
		var wall = BoxMesh.new()
		wall.size = Vector3(radius * 0.15, wall_height, radius * 0.15)
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.alpha = 0.15
		mat.emission_enabled = true
		mat.emission = color * 0.3
		
		var wall_instance = MeshInstance3D.new()
		wall_instance.mesh = wall
		wall_instance.material_override = mat
		wall_instance.position = Vector3(x, wall_height * 0.5, z)
		add_child(wall_instance)
		walls.append(wall_instance)

func _add_decorations() -> void:
	"""元素装饰物"""
	var deco_list = config.get("decorations") or []
	var radius = config.get("arena_radius") or 30.0
	var color = config["color"]
	
	var deco_count = randi_range(8, 16)
	for i in range(deco_count):
		var angle = randf() * TAU
		var dist = randf_range(3.0, radius - 2.0)
		var pos = Vector3(cos(angle) * dist, 0.5, sin(angle) * dist)
		
		var deco_type = deco_list[i % deco_list.size()]
		var deco = _create_decoration(deco_type, color)
		if deco:
			deco.position = pos
			deco.rotation.y = randf() * TAU
			add_child(deco)
			decorations.append(deco)

func _create_decoration(deco_type: String, color: Color) -> MeshInstance3D:
	"""根据装饰类型创建小物件"""
	match deco_type:
		"tree":
			var trunk = CylinderMesh.new()
			trunk.top_radius = 0.1; trunk.bottom_radius = 0.2; trunk.height = 1.5
			var tree = MeshInstance3D.new(); tree.mesh = trunk
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color("#4a3a2a")
			tree.material_override = mat
			return tree
		"vine":
			var vine = CylinderMesh.new()
			vine.top_radius = 0.05; vine.bottom_radius = 0.08; vine.height = 1.0
			var v = MeshInstance3D.new(); v.mesh = vine
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color("#2a6a3a")
			v.material_override = mat
			return v
		"sword":
			var blade = BoxMesh.new()
			blade.size = Vector3(0.05, 0.6, 0.15)
			var sword = MeshInstance3D.new(); sword.mesh = blade
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color("#c0c0c8")
			mat.metallic = 0.8
			sword.material_override = mat
			return sword
		"stone_pillar":
			var pillar = CylinderMesh.new()
			pillar.top_radius = 0.2; pillar.bottom_radius = 0.25; pillar.height = 2.0
			var p = MeshInstance3D.new(); p.mesh = pillar
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color("#7a7a6a")
			p.material_override = mat
			return p
		"lava":
			var pool = CylinderMesh.new()
			pool.top_radius = 0.4; pool.bottom_radius = 0.5; pool.height = 0.1
			var l = MeshInstance3D.new(); l.mesh = pool
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color("#ff4400")
			mat.emission_enabled = true
			mat.emission = Color("#ff2200")
			l.material_override = mat
			return l
		"ice":
			var crystal = CylinderMesh.new()
			crystal.top_radius = 0.0; crystal.bottom_radius = 0.2; crystal.height = 0.8
			var ic = MeshInstance3D.new(); ic.mesh = crystal
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color("#aaddff")
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.alpha = 0.7
			ic.material_override = mat
			return ic
		"crystal":
			var crystal = CylinderMesh.new()
			crystal.top_radius = 0.0; crystal.bottom_radius = 0.15; crystal.height = 1.0
			var cr = MeshInstance3D.new(); cr.mesh = crystal
			var mat = StandardMaterial3D.new()
			mat.albedo_color = color.lightened(0.3)
			mat.emission_enabled = true
			mat.emission = color * 0.5
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.alpha = 0.6
			cr.material_override = mat
			return cr
		_:
			return null

func _add_spawn_points() -> void:
	"""生成点标记"""
	# BOSS出生点
	boss_spawn_point = Marker3D.new()
	boss_spawn_point.name = "BossSpawn"
	boss_spawn_point.position = config.get("boss_spawn") or Vector3(0, 1, 0)
	add_child(boss_spawn_point)
	
	# 玩家出生点
	player_spawn_point = Marker3D.new()
	player_spawn_point.name = "PlayerSpawn"
	player_spawn_point.position = config.get("player_spawn") or Vector3(0, 1, -20)
	add_child(player_spawn_point)

func _add_exit_portal() -> void:
	"""出口传送门"""
	var radius = config.get("arena_radius") or 30.0
	var exit_pos = config.get("exit_position") or Vector3(0, 1, radius * 0.7)
	
	exit_portal = Area3D.new()
	exit_portal.name = "ExitPortal"
	exit_portal.position = exit_pos
	
	# 传送门外观
	var portal_mesh = CylinderMesh.new()
	portal_mesh.top_radius = 0.8
	portal_mesh.bottom_radius = 0.8
	portal_mesh.height = 3.0
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = config["color"]
	mat.emission_enabled = true
	mat.emission = config["color"] * 0.8
	mat.emission_energy_multiplier = 0.6
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.alpha = 0.4
	
	var portal_mesh_instance = MeshInstance3D.new()
	portal_mesh_instance.mesh = portal_mesh
	portal_mesh_instance.material_override = mat
	portal_mesh_instance.position.y = 1.5
	exit_portal.add_child(portal_mesh_instance)
	
	# 碰撞体
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 1.0
	shape.height = 3.0
	collision.shape = shape
	collision.position.y = 1.5
	exit_portal.add_child(collision)
	
	# "出口"标签（用Sprite3D或Label3D）
	var label = Label3D.new()
	label.text = "🚪 离开秘境"
	label.font_size = 24
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1, 1, 0.8, 0.9)
	label.position.y = 3.5
	exit_portal.add_child(label)
	
	# 连接信号 — 玩家进入传送门
	exit_portal.body_entered.connect(_on_exit_portal_entered)
	
	add_child(exit_portal)

# ==================== 出口传送门逻辑 ====================

func _on_exit_portal_entered(body: Node) -> void:
	"""玩家碰到出口传送门"""
	if body.is_in_group("player"):
		player_request_exit.emit(body)

# ==================== 清理 ====================

func clear_arena() -> void:
	"""从场景树移除前清理"""
	# 断开所有信号
	if exit_portal and exit_portal.body_entered.is_connected(_on_exit_portal_entered):
		exit_portal.body_entered.disconnect(_on_exit_portal_entered)
	
	# 移出场景树
	if get_parent():
		get_parent().remove_child(self)
	
	queue_free()

# ==================== 工具 ====================

func get_boss_spawn() -> Vector3:
	return boss_spawn_point.global_position if boss_spawn_point else global_position

func get_player_spawn() -> Vector3:
	return player_spawn_point.global_position if player_spawn_point else global_position + Vector3(0, 0, -20)
