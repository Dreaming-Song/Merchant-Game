extends Node3D
## 地形管理器 - Phase 1
## 负责加载/生成仙侠地形区块（山峦、溪流、竹林区域标记）

# ---------- 地形区块配置 ----------
@export var chunk_size: float = 64.0          # 每个区块 64x64
@export var view_distance: int = 3            # 可视范围（区块数）
@export var terrain_height: float = 20.0      # 最大地形高度

# 地形类型枚举
enum BiomeType { MOUNTAIN, RIVER, BAMBOO, FOREST, MEADOW }

# 区块数据
class ChunkData:
	var position: Vector2i
	var biome: int

# ---------- 子节点 ----------
@onready var chunk_container: Node3D = $Chunks

# ---------- 内部 ----------
var loaded_chunks: Dictionary = {}
var player_ref: Node3D

func _ready() -> void:
	# 等待玩家节点就绪
	await get_tree().root.ready
	player_ref = get_tree().get_first_node_in_group("player")

func _process(_delta: float) -> void:
	if player_ref == null:
		return

	# 计算玩家所在区块
	var player_chunk: Vector2i = world_to_chunk(player_ref.global_position)

	# 加载周围区块
	for x in range(-view_distance, view_distance + 1):
		for z in range(-view_distance, view_distance + 1):
			var chunk_pos: Vector2i = player_chunk + Vector2i(x, z)
			if not loaded_chunks.has(chunk_pos):
				load_chunk(chunk_pos)

	# 卸载远处的区块
	var to_unload: Array = []
	for chunk_pos in loaded_chunks.keys():
		if chunk_pos.distance_squared_to(player_chunk) > (view_distance + 1) * (view_distance + 1):
			to_unload.append(chunk_pos)
	for chunk_pos in to_unload:
		unload_chunk(chunk_pos)

func world_to_chunk(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / chunk_size)),
		int(floor(world_pos.z / chunk_size))
	)

func load_chunk(chunk_pos: Vector2i) -> void:
	"""加载区块 - TODO: 根据 biome 生成实际地形"""
	var chunk: Node3D = Node3D.new()
	chunk.name = "Chunk_%d_%d" % [chunk_pos.x, chunk_pos.y]
	chunk.position = Vector3(chunk_pos.x * chunk_size, 0, chunk_pos.y * chunk_size)
	chunk_container.add_child(chunk)
	loaded_chunks[chunk_pos] = chunk

	# TODO: Phase 1.2 - 实际生成地形网格
	# TODO: 放置树木、石头、草地实例
	# TODO: 溪流区域生成水面

func unload_chunk(chunk_pos: Vector2i) -> void:
	"""卸载区块"""
	if loaded_chunks.has(chunk_pos):
		loaded_chunks[chunk_pos].queue_free()
		loaded_chunks.erase(chunk_pos)

func get_biome_at(world_pos: Vector3) -> int:
	"""根据世界坐标获取地形类型 - TODO: 使用噪声图/高度图"""
	return BiomeType.BAMBOO  # 默认为竹林
