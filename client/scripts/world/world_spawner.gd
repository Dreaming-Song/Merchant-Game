extends Node
## 大世界资源生成器 — 在地图上随机分布草药、矿石、宝箱、遭遇点

const ResourceNode = preload("res://scripts/entities/resource_node.gd")
##
## 用法：挂载到 World 节点，依赖 BiomeManager
## 玩家靠近时实例化，远离时回收（避免场景爆炸）

class_name WorldSpawner

@export var player_ref: Node3D          # 玩家引用，用于距离判定
@export var spawn_radius: float = 80.0  # 以玩家为中心生成半径
@export var despawn_radius: float = 100.0
@export var max_spawns_total: int = 200 # 场景最大物体数

# 资源预制体映射（路径 → PackedScene，实际开发中预加载）
const RESOURCE_PREFABS: Dictionary = {
	"herb_spirit_grass":    "res://assets/prefabs/herb_spirit_grass.tscn",
	"herb_jade_flower":     "res://assets/prefabs/herb_jade_flower.tscn",
	"herb_flame_flower":    "res://assets/prefabs/herb_flame_flower.tscn",
	"herb_ice_lotus":       "res://assets/prefabs/herb_ice_lotus.tscn",
	"herb_toadstool":       "res://assets/prefabs/herb_toadstool.tscn",
	"herb_ghost_flower":    "res://assets/prefabs/herb_ghost_flower.tscn",
	"herb_fire_root":       "res://assets/prefabs/herb_fire_root.tscn",
	"ore_copper":           "res://assets/prefabs/ore_copper.tscn",
	"ore_iron":             "res://assets/prefabs/ore_iron.tscn",
	"ore_silver":           "res://assets/prefabs/ore_silver.tscn",
	"ore_gold":             "res://assets/prefabs/ore_gold.tscn",
	"ore_ancient":          "res://assets/prefabs/ore_ancient.tscn",
	"chest_common":         "res://assets/prefabs/chest_common.tscn",
	"chest_rare":           "res://assets/prefabs/chest_rare.tscn",
	"chest_epic":           "res://assets/prefabs/chest_epic.tscn",
	"chest_legendary":      "res://assets/prefabs/chest_legendary.tscn",
	"chest_cursed":         "res://assets/prefabs/chest_cursed.tscn",
	"encounter_wild":       "res://assets/prefabs/encounter_wild.tscn",
	"encounter_elite":      "res://assets/prefabs/encounter_elite.tscn",
	"encounter_boss":       "res://assets/prefabs/encounter_boss.tscn",
}

# 已生成的资源列表
var _active_spawns: Array[Node3D] = []
var _spawn_grid: Dictionary = {}      # "chunk_x,chunk_z" → [节点列表]
var _chunk_size: float = 20.0

@onready var _biome_manager: BiomeManager = %BiomeManager if has_node("%BiomeManager") else null

func _ready() -> void:
	if not _biome_manager:
		_biome_manager = BiomeManager.new()
		add_child(_biome_manager)
	
	# 启动定期刷新（每 2 秒检查一次）
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.timeout.connect(_refresh_spawns)
	add_child(timer)
	timer.start()

func _refresh_spawns() -> void:
	if not player_ref:
		return
	
	var player_pos = player_ref.global_position
	var player_chunk = _world_to_chunk(player_pos.x, player_pos.z)
	
	# 1. 回收远离玩家的
	_despawn_far_objects(player_pos)
	
	# 2. 生成附近缺少的
	_spawn_nearby_objects(player_pos, player_chunk)

func _spawn_nearby_objects(player_pos: Vector3, player_chunk: Vector2i) -> void:
	var pool = _get_biome_spawn_pool(player_pos)
	if pool.is_empty():
		return
	
	# 在玩家周围的 chunks 里补 spawn
	var chunks_around = _get_chunks_in_radius(player_chunk, 3)
	
	for chunk_key in chunks_around:
		if _spawn_grid.has(chunk_key):
			continue  # 已经有数据了
		
		# 解析 chunk 坐标
		var parts = chunk_key.split(",")
		var cx = int(parts[0])
		var cz = int(parts[1])
		
		# 每个 chunk 生成 1~3 个物体
		var count = randi_range(1, 3)
		for i in range(count):
			if _active_spawns.size() >= max_spawns_total:
				return
			
			# 随机位置（chunk 内）
			var local_x = randf_range(-_chunk_size / 2, _chunk_size / 2)
			var local_z = randf_range(-_chunk_size / 2, _chunk_size / 2)
			var world_x = cx * _chunk_size + local_x
			var world_z = cz * _chunk_size + local_z
			
			# 从 pool 随机选一个资源类型
			var res_type = pool[randi() % pool.size()]
			_spawn_object(res_type, Vector3(world_x, 0, world_z), chunk_key)

func _spawn_object(res_type: String, pos: Vector3, chunk_key: String) -> void:
	"""生成资源实体 — ResourceNode 自动创建视觉"""
	# 映射资源类型到 ResourceNode 参数
	var resource_map = {
		"herb_spirit_grass": {"id": "herb_spirit_grass", "name": "灵草", "gathers": 3},
		"herb_jade_flower": {"id": "herb_jade_flower", "name": "玉花", "gathers": 2},
		"herb_flame_flower": {"id": "herb_flame_flower", "name": "焰花", "gathers": 2},
		"herb_ice_lotus": {"id": "herb_ice_lotus", "name": "冰莲", "gathers": 1},
		"herb_toadstool": {"id": "herb_toadstool", "name": "毒菇", "gathers": 2},
		"herb_ghost_flower": {"id": "herb_ghost_flower", "name": "鬼花", "gathers": 1},
		"herb_fire_root": {"id": "herb_fire_root", "name": "火根", "gathers": 2},
		"ore_copper": {"id": "ore_copper", "name": "铜矿", "gathers": 5},
		"ore_iron": {"id": "ore_iron", "name": "铁矿", "gathers": 4},
		"ore_silver": {"id": "ore_silver", "name": "银矿", "gathers": 3},
		"ore_gold": {"id": "ore_gold", "name": "金矿", "gathers": 2},
		"ore_ancient": {"id": "ore_ancient", "name": "古矿", "gathers": 1},
		"chest_common": {"id": "chest_common", "name": "普通宝箱", "gathers": -1},
		"chest_rare": {"id": "chest_rare", "name": "稀有宝箱", "gathers": -1},
		"chest_epic": {"id": "chest_epic", "name": "史诗宝箱", "gathers": -1},
		"tree_wood": {"id": "tree_wood", "name": "木材", "gathers": 5},
		"tree_spirit_wood": {"id": "tree_spirit_wood", "name": "灵木", "gathers": 3},
	}
	
	var res_info = resource_map.get(res_type)
	if not res_info:
		# 回退到旧逻辑
		_spawn_object_legacy(res_type, pos, chunk_key)
		return
	
	# 创建 ResourceNode 实体（视觉自动在 _ready 中生成）
	var node = ResourceNode.new()
	node.name = "Spawn_%s_%d" % [res_type.replace("_", ""), randi()]
	node.global_position = pos
	
	# 设置 ResourceNode 属性（视觉自动在 _ready 中由 ResourceVisuals 生成）
	node.resource_id = res_info.id
	node.resource_name = res_info.name
	node.max_gathers = res_info.gathers
	node.current_gathers = res_info.gathers
	node.respawn_time = 30.0
	
	# 附加元数据
	node.set_meta("chunk", chunk_key)
	
	# 添加碰撞（ResourceNode 需要）
	var col = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(0.8, 0.8, 0.8)
	node.add_child(col)
	
	add_child(node)
	_active_spawns.append(node)
	
	if not _spawn_grid.has(chunk_key):
		_spawn_grid[chunk_key] = []
	_spawn_grid[chunk_key].append(node)

func _spawn_object_legacy(res_type: String, pos: Vector3, chunk_key: String) -> void:
	"""旧逻辑占位——保留用于没有匹配的资源"""
	var placeholder = Area3D.new()
	placeholder.name = "Spawn_%s_%d" % [res_type.replace("_", ""), randi()]
	placeholder.global_position = pos
	placeholder.set_meta("res_type", res_type)
	placeholder.set_meta("chunk", chunk_key)
	add_child(placeholder)
	_active_spawns.append(placeholder)
	if not _spawn_grid.has(chunk_key):
		_spawn_grid[chunk_key] = []
	_spawn_grid[chunk_key].append(placeholder)

func _despawn_far_objects(player_pos: Vector3) -> void:
	var to_remove: Array[Node3D] = []
	
	for obj in _active_spawns:
		var dist = obj.global_position.distance_to(player_pos)
		if dist > despawn_radius:
			var chunk = obj.get_meta("chunk", "")
			if _spawn_grid.has(chunk):
				_spawn_grid[chunk].erase(obj)
			to_remove.append(obj)
	
	for obj in to_remove:
		_active_spawns.erase(obj)
		obj.queue_free()
	
	# 🔧 M1: 清理空 chunk key，允许重新生成
	var empty_chunks: Array[String] = []
	for chunk_key in _spawn_grid.keys():
		if _spawn_grid[chunk_key].is_empty():
			empty_chunks.append(chunk_key)
	for chunk_key in empty_chunks:
		_spawn_grid.erase(chunk_key)

func _get_biome_spawn_pool(player_pos: Vector3) -> Array[String]:
	if _biome_manager:
		return _biome_manager.get_spawn_pool_at(player_pos)
	return []

func _world_to_chunk(x: float, z: float) -> Vector2i:
	return Vector2i(
		int(floor(x / _chunk_size)),
		int(floor(z / _chunk_size))
	)

func _get_chunks_in_radius(center: Vector2i, radius: int) -> Array[String]:
	var chunks: Array[String] = []
	for dx in range(-radius, radius + 1):
		for dz in range(-radius, radius + 1):
			var cx = center.x + dx
			var cz = center.y + dz
			var key = "%d,%d" % [cx, cz]
			chunks.append(key)
	return chunks

# ==================== 调试接口 ====================

func get_active_spawn_count() -> int:
	return _active_spawns.size()

func get_chunk_count() -> int:
	return _spawn_grid.size()
