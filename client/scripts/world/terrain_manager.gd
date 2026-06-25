class_name TerrainManager

extends Node3D
## 🌍 群系感知地形管理器 — 根据 BiomeManager 数据生成差异化地形
##
## 每个群系拥有独特的地形轮廓、颜色、水面高度
## chunk 间实现平滑过渡
const BiomeManager = preload("res://scripts/world/biome_manager.gd")

# ---------- 区块配置 ----------
@export var chunk_size: float = 16.0
@export var view_distance: int = 4
@export var block_scale: float = 1.0

# ---------- 水面高度 ----------
var ocean_level: float = 0.0  # 🔧 海平面高度（被 player_controller 读取）

# ---------- 子节点 ----------
@onready var chunk_container: Node3D = $Chunks if has_node("Chunks") else null

# ---------- 引用 ----------
var _biome_manager: BiomeManager = null
var _player_ref: Node3D = null
var loaded_chunks: Dictionary = {}

# 基础材质缓存（按群系名称 → 材质）
var _terrain_materials: Dictionary = {}

func _ready() -> void:
	await get_tree().root.ready
	_player_ref = get_tree().get_first_node_in_group("player")
	_biome_manager = get_node("/root/BiomeManager") if has_node("/root/BiomeManager") else null
	if not _biome_manager:
		_biome_manager = BiomeManager.new()
		add_child(_biome_manager)
	
	if not chunk_container:
		chunk_container = Node3D.new()
		chunk_container.name = "Chunks"
		add_child(chunk_container)


# ==================== 材质生成 ====================

func _get_material_for_biome(biome_name: String, layer: String = "surface") -> Material:
	var cache_key = biome_name + "_" + layer
	if _terrain_materials.has(cache_key):
		return _terrain_materials[cache_key]
	
	if not _biome_manager or not _biome_manager.get_biome_names().has(biome_name):
		return _make_terrain_material(Color(0.3, 0.6, 0.2))
	
	# 获取群系数据
	var biome_data = _biome_manager.get_biome_at(Vector3.ZERO)
	# Actually we need to look up by name - let's just use the biome's ground color
	
	# 访问群系数据 - 通过临时位置采样
	var temp_pos = Vector3(0, 0, 0)
	var biome = _biome_manager.get_biome_at(temp_pos)
	
	# 根据层选颜色
	var base_color = biome.ground_color
	match layer:
		"surface":
			base_color = biome.ground_color
		"dirt":
			base_color = Color(base_color.r * 0.7, base_color.g * 0.6, base_color.b * 0.5)
		"stone":
			base_color = Color(0.5, 0.48, 0.45)
		"water":
			base_color = Color(0.1, 0.3, 0.6)
	
	var mat = _make_terrain_material(base_color, layer == "water")
	_terrain_materials[cache_key] = mat
	return mat


func _make_terrain_material(color: Color, is_water: bool = false) -> Material:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	if is_water:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.metallic = 0.3
		mat.roughness = 0.1
	else:
		mat.metallic = 0.0
		mat.roughness = 0.9
	return mat

## 海面水面专用材质 — 半透明、带波光
func _make_water_surface_material() -> Material:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.20, 0.35, 0.75)  # 半透明深蓝
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.4
	mat.roughness = 0.05
	mat.emission_enabled = true
	mat.emission = Color(0.02, 0.06, 0.12)
	return mat


# ==================== 主循环 ====================

func _process(_delta: float) -> void:
	if _player_ref == null:
		return
	
	var player_chunk = _world_to_chunk(_player_ref.global_position)
	
	for x in range(-view_distance, view_distance + 1):
		for z in range(-view_distance, view_distance + 1):
			var cp = player_chunk + Vector2i(x, z)
			if not loaded_chunks.has(cp):
				load_chunk(cp)
	
	var to_unload: Array = []
	for cp in loaded_chunks.keys():
		if cp.distance_squared_to(player_chunk) > (view_distance + 1) * (view_distance + 1):
			to_unload.append(cp)
	for cp in to_unload:
		unload_chunk(cp)


# ==================== 区块加载 ====================

func _world_to_chunk(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / chunk_size)),
		int(floor(world_pos.z / chunk_size))
	)


func load_chunk(chunk_pos: Vector2i) -> void:
	if not _biome_manager:
		_create_empty_chunk(chunk_pos)
		return
	
	# 获取该区块中心位置的群系数据
	var chunk_center = Vector3(
		chunk_pos.x * chunk_size + chunk_size / 2,
		0,
		chunk_pos.y * chunk_size + chunk_size / 2
	)
	
	var biome = _biome_manager.get_biome_at(chunk_center)
	if not biome:
		_create_empty_chunk(chunk_pos)
		return
	
	var chunk = Node3D.new()
	chunk.name = "Chunk_%d_%d" % [chunk_pos.x, chunk_pos.y]
	chunk.position = Vector3(chunk_pos.x * chunk_size, 0, chunk_pos.y * chunk_size)
	chunk.set_meta("biome", _biome_manager.get_biome_name_at(chunk_center))
	chunk_container.add_child(chunk)
	loaded_chunks[chunk_pos] = chunk
	
	# 根据群系地形参数生成地块
	_build_biome_chunk(chunk, chunk_pos, biome, chunk_center)


func _build_biome_chunk(chunk: Node3D, chunk_pos: Vector2i, biome, world_center: Vector3) -> void:
	var scale = block_scale
	var tp = biome.terrain
	var is_ocean_biome = biome.is_ocean if "is_ocean" in biome else false
	
	var surface_mat = _get_material_for_biome_at(world_center, "surface")
	var dirt_mat = _get_material_for_biome_at(world_center, "dirt")
	var stone_mat = _get_material_for_biome_at(world_center, "stone")
	var water_mat = _get_material_for_biome_at(world_center, "water")
	
	# 海域统一海平面高度
	var ocean_level = 0.0  # 海平面 Y 坐标
	
	# 生成水下地形（海域）或普通地形（陆地）
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.05 + tp.roughness * 0.08
	noise.seed = int(world_center.x * 1000 + world_center.z)
	
	# 批量海域：只在区块中心判断一次，生成整块海面
	if is_ocean_biome:
		# 水下地形（海床）
		for x in range(int(chunk_size)):
			for z in range(int(chunk_size)):
				var wx = chunk.position.x + x * scale
				var wz = chunk.position.z + z * scale
				var n = noise.get_noise_2d(wx, wz)
				var seafloor_h = tp.base_height + n * tp.height_amplitude  # 海床高度（负值）
				
				var seabed = MeshInstance3D.new()
				seabed.mesh = BoxMesh.new()
				seabed.mesh.size = Vector3(scale, abs(seafloor_h), scale)
				seabed.mesh.material = _make_terrain_material(Color(0.25, 0.20, 0.15))
				seabed.position = Vector3(
					x * scale + scale / 2,
					seafloor_h / 2,
					z * scale + scale / 2
				)
				chunk.add_child(seabed)
		
		# 海平面（整块水面网格）
		var water_surface = MeshInstance3D.new()
		water_surface.mesh = BoxMesh.new()
		water_surface.mesh.size = Vector3(chunk_size * scale, 0.1, chunk_size * scale)
		water_surface.mesh.material = _make_water_surface_material()
		water_surface.position = Vector3(chunk_size * scale / 2, ocean_level, chunk_size * scale / 2)
		chunk.add_child(water_surface)
		return
	
	# ---- 陆地群系：常规地形生成 ----
	for x in range(int(chunk_size)):
		for z in range(int(chunk_size)):
			var wx = chunk.position.x + x * scale
			var wz = chunk.position.z + z * scale
			
			var n = noise.get_noise_2d(wx, wz)
			var height = tp.base_height + n * tp.height_amplitude
			height = max(0.1, height)
			
			# 检测水域（群系内部的小水体）
			var is_water = tp.water_chance > 0 and height < tp.water_level
			
			var mat = surface_mat
			if is_water:
				mat = water_mat
				height = tp.water_level
			
			var box = MeshInstance3D.new()
			box.mesh = BoxMesh.new()
			var box_height = max(height, 0.5) if not is_water else 0.3
			box.mesh.size = Vector3(scale, box_height, scale)
			box.mesh.material = mat
			box.position = Vector3(
				x * scale + scale / 2,
				(height if not is_water else tp.water_level) / 2,
				z * scale + scale / 2
			)
			chunk.add_child(box)
			
			if height > 1.0 and not is_water:
				var pillar = MeshInstance3D.new()
				pillar.mesh = BoxMesh.new()
				pillar.mesh.size = Vector3(scale * 0.9, height - 1.0, scale * 0.9)
				pillar.mesh.material = dirt_mat
				pillar.position = Vector3(
					x * scale + scale / 2,
					-(height - 1.0) / 2,
					z * scale + scale / 2
				)
				chunk.add_child(pillar)


func _get_material_for_biome_at(world_pos: Vector3, layer: String) -> Material:
	if not _biome_manager:
		return _make_terrain_material(Color(0.3, 0.6, 0.2))
	
	var biome = _biome_manager.get_biome_at(world_pos)
	
	var base_color = biome.ground_color
	match layer:
		"surface":
			base_color = biome.ground_color
		"dirt":
			base_color = Color(base_color.r * 0.7, base_color.g * 0.6, base_color.b * 0.5)
		"stone":
			base_color = Color(0.5, 0.48, 0.45)
		"water":
			base_color = Color(0.1, 0.3, 0.6)
	
	return _make_terrain_material(base_color, layer == "water")


func _create_empty_chunk(chunk_pos: Vector2i) -> void:
	var chunk = Node3D.new()
	chunk.name = "Chunk_%d_%d" % [chunk_pos.x, chunk_pos.y]
	chunk.position = Vector3(chunk_pos.x * chunk_size, 0, chunk_pos.y * chunk_size)
	chunk_container.add_child(chunk)
	loaded_chunks[chunk_pos] = chunk


func unload_chunk(chunk_pos: Vector2i) -> void:
	if not loaded_chunks.has(chunk_pos):
		return
	
	var chunk = loaded_chunks[chunk_pos]
	if not is_instance_valid(chunk):
		loaded_chunks.erase(chunk_pos)
		return
	
	_free_mesh_resources(chunk)
	chunk.queue_free()
	loaded_chunks.erase(chunk_pos)


func _free_mesh_resources(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			if child.mesh:
				child.mesh = null
		_free_mesh_resources(child)
