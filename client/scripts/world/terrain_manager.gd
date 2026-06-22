extends Node3D
## 地形管理器 — Phase 2
## 使用 MapGenerator 的数据生成 3D 地形区块
## 类似 MC 的区块加载/卸载

# ---------- 地形区块配置 ----------
@export var chunk_size: float = 16.0
@export var view_distance: int = 4
@export var block_scale: float = 1.0

# ---------- 子节点 ----------
@onready var chunk_container: Node3D = $Chunks

# ---------- 引用 ----------
var _map_gen: Node = null
var _player_ref: Node3D = null
var loaded_chunks: Dictionary = {}

# 区块网格材质
var _grass_material: Material = null
var _dirt_material: Material = null
var _stone_material: Material = null
var _water_material: Material = null

func _ready() -> void:
	await get_tree().root.ready
	_player_ref = get_tree().get_first_node_in_group("player")
	_map_gen = get_node("/root/MapGenerator")
	_init_materials()

func _init_materials() -> void:
	# 创建简易材质
	_grass_material = _make_terrain_material(Color(0.3, 0.6, 0.2))
	_dirt_material = _make_terrain_material(Color(0.5, 0.35, 0.2))
	_stone_material = _make_terrain_material(Color(0.5, 0.5, 0.45))
	_water_material = _make_terrain_material(Color(0.1, 0.3, 0.7, 0.6))

func _make_terrain_material(color: Color) -> Material:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

func _process(_delta: float) -> void:
	if _player_ref == null:
		return
	
	var player_chunk = world_to_chunk(_player_ref.global_position)
	
	# 加载周围区块
	for x in range(-view_distance, view_distance + 1):
		for z in range(-view_distance, view_distance + 1):
			var cp = player_chunk + Vector2i(x, z)
			if not loaded_chunks.has(cp):
				load_chunk(cp)
	
	# 卸载远处区块
	var to_unload: Array = []
	for cp in loaded_chunks.keys():
		if cp.distance_squared_to(player_chunk) > (view_distance + 1) * (view_distance + 1):
			to_unload.append(cp)
	for cp in to_unload:
		unload_chunk(cp)

func world_to_chunk(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / chunk_size)),
		int(floor(world_pos.z / chunk_size))
	)

func load_chunk(chunk_pos: Vector2i) -> void:
	"""从 MapGenerator 获取数据并生成 3D 网格"""
	if not _map_gen or not _map_gen.has_method("generate_chunk"):
		# 备选：生成空白区块
		_create_empty_chunk(chunk_pos)
		return
	
	var biome_map = _map_gen._generate_biome_map() if _map_gen.has_method("_generate_biome_map") else {}
	var chunk_data = _map_gen.generate_chunk(chunk_pos.x, chunk_pos.y, biome_map)
	
	if chunk_data.is_empty() or not chunk_data.has("blocks"):
		_create_empty_chunk(chunk_pos)
		return
	
	# 创建区块节点
	var chunk = Node3D.new()
	chunk.name = "Chunk_%d_%d" % [chunk_pos.x, chunk_pos.y]
	chunk.position = Vector3(chunk_pos.x * chunk_size, 0, chunk_pos.y * chunk_size)
	chunk_container.add_child(chunk)
	loaded_chunks[chunk_pos] = chunk
	
	# 生成地形方块
	_build_chunk_mesh(chunk, chunk_data)

func _build_chunk_mesh(chunk: Node3D, data: Dictionary) -> void:
	"""为区块创建方块网格"""
	var blocks = data.get("blocks", [])
	if blocks.is_empty():
		return
	
	var scale = block_scale
	
	for x in range(blocks.size()):
		var row = blocks[x]
		for z in range(row.size()):
			var block = row[z]
			var h = block.get("height", 0.0) * 10  # 高度放大
			var is_water = block.get("is_water", false)
			
			var surface_type = block.get("surface", "grass")
			
			# 选择材质
			var mat = _grass_material
			if is_water:
				mat = _water_material
			elif surface_type == "stone" or surface_type == "magma_stone":
				mat = _stone_material
			elif surface_type == "sand" or surface_type == "sandstone":
				mat = _stone_material
			
			# 创建地形方块
			var box = MeshInstance3D.new()
			box.mesh = BoxMesh.new()
			box.mesh.size = Vector3(scale, max(h, 0.5) if not is_water else 0.3, scale)
			box.mesh.material = mat
			box.position = Vector3(x * scale + scale/2, (h if not is_water else -0.2) / 2, z * scale + scale/2)
			chunk.add_child(box)
			
			# 如果高于地表，加一个"柱子"做 subsurface
			if h > 1.0 and not is_water:
				var pillar = MeshInstance3D.new()
				pillar.mesh = BoxMesh.new()
				pillar.mesh.size = Vector3(scale * 0.8, h - 1.0, scale * 0.8)
				pillar.mesh.material = _dirt_material
				pillar.position = Vector3(x * scale + scale/2, - (h - 1.0) / 2, z * scale + scale/2)
				chunk.add_child(pillar)
	
	# 放置树木标记
	for tree in data.get("trees", []):
		var pos = tree.get("position", Vector3())
		var trunk = MeshInstance3D.new()
		trunk.mesh = CylinderMesh.new()
		trunk.mesh.top_radius = 0.1
		trunk.mesh.bottom_radius = 0.15
		trunk.mesh.height = 2.0
		trunk.position = Vector3(pos.x - chunk.position.x, pos.y, pos.z - chunk.position.z)
		var tree_mat = StandardMaterial3D.new()
		tree_mat.albedo_color = Color(0.3, 0.2, 0.1)
		trunk.mesh.material = tree_mat
		chunk.add_child(trunk)

func _create_empty_chunk(chunk_pos: Vector2i) -> void:
	"""创建空白区块（占位）"""
	var chunk = Node3D.new()
	chunk.name = "Chunk_%d_%d" % [chunk_pos.x, chunk_pos.y]
	chunk.position = Vector3(chunk_pos.x * chunk_size, 0, chunk_pos.y * chunk_size)
	chunk_container.add_child(chunk)
	loaded_chunks[chunk_pos] = chunk

func unload_chunk(chunk_pos: Vector2i) -> void:
	"""卸载区块并回收显存"""
	if not loaded_chunks.has(chunk_pos):
		return
	
	var chunk = loaded_chunks[chunk_pos]
	if not is_instance_valid(chunk):
		loaded_chunks.erase(chunk_pos)
		return
	
	# 递归释放所有 MeshInstance3D 的资源
	_free_mesh_resources(chunk)
	
	chunk.queue_free()
	loaded_chunks.erase(chunk_pos)

func _free_mesh_resources(node: Node) -> void:
	"""递归释放网格资源，防止显存泄漏"""
	for child in node.get_children():
		if child is MeshInstance3D:
			if child.mesh:
				child.mesh = null
		_free_mesh_resources(child)
