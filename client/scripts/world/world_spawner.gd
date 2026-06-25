extends Node
## 🌍 大世界生态生成器 — 群系感知的资源/树木/怪物生成
##
## 依赖 BiomeManager，根据玩家所在群系生成对应的：
## - 采集资源（草药/矿石/宝箱）
## - 树木（群系专属树种）
## - 野怪（群系怪物表）
## 远离时回收（chunk 化管理）
const BiomeManager = preload("res://scripts/world/biome_manager.gd")
const DayNightCycle = preload("res://scripts/world/day_night_cycle.gd")
const ResourceNode = preload("res://scripts/entities/resource_node.gd")
const Enemy = preload("res://scripts/combat/enemy.gd")
const EnemyType = preload("res://scripts/combat/enemy.gd").EnemyType

# class_name WorldSpawner — 已通过 autoload 注册

@export var player_ref: Node3D
@export var spawn_radius: float = 80.0
@export var despawn_radius: float = 100.0
@export var max_spawns_total: int = 300

# 资源预制体映射
const RESOURCE_PREFABS: Dictionary = {
	# 草药
	"herb_spirit_grass":    "res://assets/prefabs/herb_spirit_grass.tscn",
	"herb_jade_flower":     "res://assets/prefabs/herb_jade_flower.tscn",
	"herb_flame_flower":    "res://assets/prefabs/herb_flame_flower.tscn",
	"herb_ice_lotus":       "res://assets/prefabs/herb_ice_lotus.tscn",
	"herb_toadstool":       "res://assets/prefabs/herb_toadstool.tscn",
	"herb_ghost_flower":    "res://assets/prefabs/herb_ghost_flower.tscn",
	"herb_fire_root":       "res://assets/prefabs/herb_fire_root.tscn",
	# 新增草药
	"herb_peach_blossom":   "res://assets/prefabs/herb_peach_blossom.tscn",
	"herb_star_flower":     "res://assets/prefabs/herb_star_flower.tscn",
	"herb_thunder_grass":   "res://assets/prefabs/herb_thunder_grass.tscn",
	# 矿石
	"ore_copper":           "res://assets/prefabs/ore_copper.tscn",
	"ore_iron":             "res://assets/prefabs/ore_iron.tscn",
	"ore_silver":           "res://assets/prefabs/ore_silver.tscn",
	"ore_gold":             "res://assets/prefabs/ore_gold.tscn",
	"ore_ancient":          "res://assets/prefabs/ore_ancient.tscn",
	# 宝箱
	"chest_common":         "res://assets/prefabs/chest_common.tscn",
	"chest_rare":           "res://assets/prefabs/chest_rare.tscn",
	"chest_epic":           "res://assets/prefabs/chest_epic.tscn",
	"chest_legendary":      "res://assets/prefabs/chest_legendary.tscn",
	"chest_cursed":         "res://assets/prefabs/chest_cursed.tscn",
	# 遭遇
	"encounter_wild":       "res://assets/prefabs/encounter_wild.tscn",
	"encounter_elite":      "res://assets/prefabs/encounter_elite.tscn",
	"encounter_boss":       "res://assets/prefabs/encounter_boss.tscn",
	# 🌲 树木
	"tree_bamboo":          "res://assets/prefabs/tree_bamboo.tscn",
	"tree_spirit_bamboo":   "res://assets/prefabs/tree_spirit_bamboo.tscn",
	"tree_maple":           "res://assets/prefabs/tree_maple.tscn",
	"tree_ancient_maple":   "res://assets/prefabs/tree_ancient_maple.tscn",
	"tree_redwood":         "res://assets/prefabs/tree_redwood.tscn",
	"tree_snow_pine":       "res://assets/prefabs/tree_snow_pine.tscn",
	"tree_ice_crystal":     "res://assets/prefabs/tree_ice_crystal.tscn",
	"tree_deadwood":        "res://assets/prefabs/tree_deadwood.tscn",
	"tree_poison_vine":     "res://assets/prefabs/tree_poison_vine.tscn",
	"tree_glow_mushroom":   "res://assets/prefabs/tree_glow_mushroom.tscn",
	"tree_charred":         "res://assets/prefabs/tree_charred.tscn",
	"tree_lava":            "res://assets/prefabs/tree_lava.tscn",
	"tree_peach":           "res://assets/prefabs/tree_peach.tscn",
	"tree_spirit_peach":    "res://assets/prefabs/tree_spirit_peach.tscn",
	"tree_willow":          "res://assets/prefabs/tree_willow.tscn",
	"tree_cactus":          "res://assets/prefabs/tree_cactus.tscn",
	"tree_starlight":       "res://assets/prefabs/tree_starlight.tscn",
	"tree_ironwood":        "res://assets/prefabs/tree_ironwood.tscn",
	"tree_lightning_struck":"res://assets/prefabs/tree_lightning_struck.tscn",
	"tree_thunder_bamboo":  "res://assets/prefabs/tree_thunder_bamboo.tscn",
	"tree_wood":            "res://assets/prefabs/tree_wood.tscn",  # 通用木材
}

# 已生成的物体列表
var _active_spawns: Array[Node3D] = []
var _spawn_grid: Dictionary = {}      # "chunk_x,chunk_z" → [节点列表]
var _chunk_size: float = 20.0

@onready var _biome_manager: BiomeManager = %BiomeManager if has_node("%BiomeManager") else null

func _ready() -> void:
	if not _biome_manager:
		_biome_manager = BiomeManager.new()
		add_child(_biome_manager)
	
	# 🌙 连接昼夜系统
	_day_night = get_node("/root/DayNightCycle") if has_node("/root/DayNightCycle") else null
	if _day_night:
		_day_night.time_changed.connect(_on_time_changed)
		_is_night = _day_night.is_night()
	
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.timeout.connect(_refresh_spawns)
	add_child(timer)
	timer.start()
	
	# 额外：快速刷怪循环（每5秒）
	var enemy_timer = Timer.new()
	enemy_timer.wait_time = 5.0
	enemy_timer.timeout.connect(_try_spawn_enemies)
	add_child(enemy_timer)
	enemy_timer.start()

func _refresh_spawns() -> void:
	if not player_ref:
		return
	
	var player_pos = player_ref.global_position
	var player_chunk = _world_to_chunk(player_pos.x, player_pos.z)
	
	_despawn_far_objects(player_pos)
	_spawn_nearby_objects(player_pos, player_chunk)


# ==================== 生成逻辑 ====================

func _spawn_nearby_objects(player_pos: Vector3, player_chunk: Vector2i) -> void:
	# 海域不生成任何东西
	if _is_ocean_at(player_pos):
		return
	
	var pool = _get_biome_spawn_pool(player_pos)
	var tree_pool = _get_biome_tree_pool(player_pos)
	if pool.is_empty() and tree_pool.is_empty():
		return
	
	# 获取当前群系信息
	var biome = _get_current_biome(player_pos)
	var chunks_around = _get_chunks_in_radius(player_chunk, 3)
	
	for chunk_key in chunks_around:
		if _spawn_grid.has(chunk_key):
			continue
		
		var parts = chunk_key.split(",")
		var cx = int(parts[0])
		var cz = int(parts[1])
		
		# 资源生成（1~3 个）
		var resource_count = randi_range(1, 3)
		for _i in range(resource_count):
			if _active_spawns.size() >= max_spawns_total:
				return
			
			var local_x = randf_range(-_chunk_size / 2, _chunk_size / 2)
			var local_z = randf_range(-_chunk_size / 2, _chunk_size / 2)
			var world_x = cx * _chunk_size + local_x
			var world_z = cz * _chunk_size + local_z
			
			# 根据群系危险等级控制资源/怪物比例
			var danger = biome.danger_level if biome else 0.5
			var is_resource = randf() > danger * 0.4
			
			if is_resource and not pool.is_empty():
				var res_type = pool[randi() % pool.size()]
				_spawn_resource(res_type, Vector3(world_x, 0, world_z), chunk_key)
		
		# 🌲 树木生成（根据群系树木密度）
		var tree_density = biome.trees.total_density if biome else 0.3
		var tree_count = 0
		if tree_density > 0 and randf() < tree_density:
			tree_count = randi_range(0, int(tree_density * 3))
		
		for _i in range(tree_count):
			if _active_spawns.size() >= max_spawns_total:
				return
			
			var tx = cx * _chunk_size + randf_range(-_chunk_size / 2, _chunk_size / 2)
			var tz = cz * _chunk_size + randf_range(-_chunk_size / 2, _chunk_size / 2)
			var tree_type = _pick_tree_type(tree_pool)
			if tree_type:
				_spawn_tree(tree_type, Vector3(tx, 0, tz), chunk_key)


func _spawn_resource(res_type: String, pos: Vector3, chunk_key: String) -> void:
	var resource_map = {
		"herb_spirit_grass": {"id": "herb_spirit_grass", "name": "灵草", "gathers": 3},
		"herb_jade_flower": {"id": "herb_jade_flower", "name": "玉花", "gathers": 2},
		"herb_flame_flower": {"id": "herb_flame_flower", "name": "焰花", "gathers": 2},
		"herb_ice_lotus": {"id": "herb_ice_lotus", "name": "冰莲", "gathers": 1},
		"herb_toadstool": {"id": "herb_toadstool", "name": "毒菇", "gathers": 2},
		"herb_ghost_flower": {"id": "herb_ghost_flower", "name": "鬼花", "gathers": 1},
		"herb_fire_root": {"id": "herb_fire_root", "name": "火根", "gathers": 2},
		"herb_peach_blossom": {"id": "herb_peach_blossom", "name": "桃花", "gathers": 3},
		"herb_star_flower": {"id": "herb_star_flower", "name": "星华", "gathers": 1},
		"herb_thunder_grass": {"id": "herb_thunder_grass", "name": "雷草", "gathers": 2},
		"ore_copper": {"id": "ore_copper", "name": "铜矿", "gathers": 5},
		"ore_iron": {"id": "ore_iron", "name": "铁矿", "gathers": 4},
		"ore_silver": {"id": "ore_silver", "name": "银矿", "gathers": 3},
		"ore_gold": {"id": "ore_gold", "name": "金矿", "gathers": 2},
		"ore_ancient": {"id": "ore_ancient", "name": "古矿", "gathers": 1},
		"chest_common": {"id": "chest_common", "name": "普通宝箱", "gathers": -1},
		"chest_rare": {"id": "chest_rare", "name": "稀有宝箱", "gathers": -1},
		"chest_epic": {"id": "chest_epic", "name": "史诗宝箱", "gathers": -1},
		"chest_legendary": {"id": "chest_legendary", "name": "传说宝箱", "gathers": -1},
		"chest_cursed": {"id": "chest_cursed", "name": "诅咒宝箱", "gathers": -1},
	}
	
	var res_info = resource_map.get(res_type)
	if not res_info:
		# 可能是树木类型，调用旧逻辑兜底
		return
	
	var node = ResourceNode.new()
	node.name = "Resource_%s_%d" % [res_type.replace("_", ""), randi()]
	node.global_position = pos
	node.resource_id = res_info.get("id", "")
	node.resource_name = res_info.get("name", "")
	node.max_gathers = res_info.get("gathers", 1)
	node.current_gathers = res_info.get("gathers", 1)
	node.respawn_time = 30.0
	node.set_meta("chunk", chunk_key)
	node.set_meta("biome_res_type", res_type)
	
	var col = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(0.8, 0.8, 0.8)
	node.add_child(col)
	
	add_child(node)
	_active_spawns.append(node)
	_register_in_grid(chunk_key, node)


func _spawn_tree(tree_type: Dictionary, pos: Vector3, chunk_key: String) -> void:
	var tree_name = tree_type.get("name") or "树"
	var tree_scene = tree_type.get("scene") or ""
	
	# 先用 ResourceNode 简化处理
	var node = ResourceNode.new()
	node.name = "Tree_%s_%d" % [tree_name, randi()]
	node.global_position = pos
	node.resource_id = "tree_" + tree_name.to_lower()
	node.resource_name = tree_name
	node.max_gathers = randi_range(3, 6)
	node.current_gathers = node.max_gathers
	node.respawn_time = 60.0
	node.set_meta("chunk", chunk_key)
	node.set_meta("is_tree", true)
	node.set_meta("tree_scene", tree_scene)
	
	var height = randf_range(
		tree_type.get("min_height") or 2.0,
		tree_type.get("max_height") or 6.0
	)
	node.set_meta("tree_height", height)
	node.scale = Vector3(1.0, height / 3.0, 1.0)
	
	var col = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(1.0, height, 1.0)
	node.add_child(col)
	
	add_child(node)
	_active_spawns.append(node)
	_register_in_grid(chunk_key, node)


func _spawn_object_legacy(res_type: String, pos: Vector3, chunk_key: String) -> void:
	var placeholder = Area3D.new()
	placeholder.name = "Spawn_%s_%d" % [res_type.replace("_", ""), randi()]
	placeholder.global_position = pos
	placeholder.set_meta("res_type", res_type)
	placeholder.set_meta("chunk", chunk_key)
	add_child(placeholder)
	_active_spawns.append(placeholder)
	_register_in_grid(chunk_key, placeholder)

# ==================== 回收逻辑 ====================

func _register_in_grid(chunk_key: String, node: Node3D) -> void:
	if not _spawn_grid.has(chunk_key):
		_spawn_grid[chunk_key] = []
	_spawn_grid[chunk_key].append(node)


func _get_biome_spawn_pool(player_pos: Vector3) -> Array[String]:
	if _biome_manager:
		return _biome_manager.get_spawn_pool_at(player_pos)
	return []


func _get_biome_tree_pool(player_pos: Vector3) -> Array[Dictionary]:
	if _biome_manager:
		var dist = _biome_manager.get_tree_distribution_at(player_pos)
		return dist.tree_types
	return []


func _get_current_biome(player_pos: Vector3):
	if _biome_manager:
		return _biome_manager.get_biome_at(player_pos)
	return null

## 判断位置是否为海域
func _is_ocean_at(pos: Vector3) -> bool:
	if _biome_manager and _biome_manager.has_method("is_ocean_at"):
		return _biome_manager.is_ocean_at(pos)
	return false


func _pick_tree_type(tree_pool: Array[Dictionary]) -> Dictionary:
	if tree_pool.is_empty():
		return {}
	
	# 按 density 权重随机
	var total_weight = 0.0
	for tt in tree_pool:
		total_weight += tt.get("density") or 1.0
	
	var roll = randf() * total_weight
	var cumulative = 0.0
	for tt in tree_pool:
		cumulative += tt.get("density") or 1.0
		if roll <= cumulative:
			return tt
	
	return tree_pool[0]


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
			chunks.append("%d,%d" % [cx, cz])
	return chunks


# ==================== 调试接口 ====================

func get_active_spawn_count() -> int:
	return _active_spawns.size()

# ==================== 妖兽自动生成 ====================

## 群系 → 妖兽类型映射
## 五行对应：木(青龙)→竹林/桃林, 金(白虎)→枫林/雷暴, 火(朱雀)→火山, 水(玄武)→雪峰/沼泽, 土(麒麟)→星辰沙漠
const BIOME_ENEMY_MAP: Dictionary = {
	# 🌿 青龙 — 木属性
	"bamboo_forest":    {"normal": EnemyType.GREEN_SERPENT, "elite": EnemyType.VENOMOUS_WYRM, "level": Vector2(5, 20)},
	"peach_blossom":    {"normal": EnemyType.GREEN_SERPENT, "elite": EnemyType.VENOMOUS_WYRM, "level": Vector2(15, 30)},
	
	# ⚔️ 白虎 — 金属性
	"maple_forest":     {"normal": EnemyType.BLADE_CUB,     "elite": EnemyType.SABER_TIGER,   "level": Vector2(10, 25)},
	"thunder_plains":   {"normal": EnemyType.BLADE_CUB,     "elite": EnemyType.SABER_TIGER,   "level": Vector2(25, 45)},
	
	# 🔥 朱雀 — 火属性
	"volcano":          {"normal": EnemyType.FLAME_SPARROW, "elite": EnemyType.SCORCH_BIRD,   "level": Vector2(20, 40)},
	
	# 💧 玄武 — 水属性
	"snow_peak":        {"normal": EnemyType.ICE_TURTLE,    "elite": EnemyType.FROST_TORTOISE,"level": Vector2(15, 35)},
	"swamp":            {"normal": EnemyType.ICE_TURTLE,    "elite": EnemyType.FROST_TORTOISE,"level": Vector2(20, 40)},
	
	# 🏔️ 麒麟 — 土属性
	"stellar_desert":   {"normal": EnemyType.STONE_BEAST,   "elite": EnemyType.ROCK_ARMOR,    "level": Vector2(25, 50)},
	"wind_plains":      {"normal": EnemyType.STONE_BEAST,   "elite": EnemyType.ROCK_ARMOR,    "level": Vector2(5, 15)},
}

# 通用野怪（无对应群系时）
const FALLBACK_ENEMIES: Array = [
	EnemyType.SPIRIT_WOLF,
	EnemyType.MIST_APE,
	EnemyType.FLAME_BOAR,
	EnemyType.IRON_TORTOISE,
]

var _enemy_spawn_timer: float = 0.0
var _max_enemies_per_chunk: int = 4
var _elite_chance: float = 0.05  # 5%概率变精英

# 🌙 夜晚威胁系统
var _day_night: DayNightCycle = null
var _is_night: bool = false
const NIGHT_SPAWN_MULT: float = 2.5       # 夜晚刷怪量 ×2.5
const NIGHT_ELITE_CHANCE: float = 0.20    # 夜晚精英率 20%
const NIGHT_AGGRO_RANGE_MULT: float = 1.8 # 夜晚怪物索敌范围 ×1.8

func _try_spawn_enemies() -> void:
	"""尝试在当前群系刷怪"""
	if not player_ref or not _biome_manager: return
	
	# 🌙 夜晚刷新率提高
	if _is_night and randf() > 0.4:
		return  # 夜晚每 tick 60% 概率触发，比白天更密集
	elif not _is_night and randf() > 0.6:
		return  # 白天 40%
	
	var player_pos = player_ref.global_position
	var biome_key = _biome_manager.get_biome_at(player_pos)
	var enemy_config = BIOME_ENEMY_MAP.get(biome_key, null)
	
	# 检查已存在的敌人数 — 夜晚允许更多
	var density_limit = 0.3 if not _is_night else 0.6  # 夜晚上限翻倍
	var current_enemies = _count_nearby_enemies(player_pos, spawn_radius)
	if current_enemies >= max_spawns_total * density_limit:
		return
	
	if enemy_config:
		# 群系专属刷怪
		_spawn_biome_enemies(player_pos, enemy_config)
	else:
		# 通用野怪
		_spawn_fallback_enemies(player_pos)

## 🌙 昼夜切换监听
func _on_time_changed(_hour: float) -> void:
	if not _day_night:
		return
	var was_night = _is_night
	_is_night = _day_night.is_night()
	
	# 刚入夜/刚天亮时，清除远处怪物模拟"妖兽出没/退散"
	if _is_night != was_night:
		print("🌙 夜晚降临，妖兽开始活跃！" if _is_night else "☀️ 天亮了，妖兽退散")
		if not _is_night:
			# 白天来临：远处怪物退散（近处的保留）
			_despawn_night_enemies()

func _spawn_biome_enemies(player_pos: Vector3, config: Dictionary) -> void:
	"""生成群系对应妖兽"""
	var normal_type = config["normal"]
	var elite_type = config["elite"]
	var lv_range = config["level"]
	
	# 🌙 夜晚刷怪量 × 2.5，精英率提升到 20%
	var count = randi_range(2, 4)
	if _is_night:
		count = ceil(count * NIGHT_SPAWN_MULT)
		count = randi_range(count, count + 2)
	
	for i in range(count):
		var offset = Vector3(
			randf_range(-25, 25),
			0,
			randf_range(-25, 25)
		)
		var spawn_pos = player_pos + offset
		
		# 检查这块区域是否有太多怪了
		var chunk_key = _world_to_chunk(spawn_pos.x, spawn_pos.z)
		var chunk_enemies = _get_chunk_enemy_count(chunk_key)
		if chunk_enemies >= _max_enemies_per_chunk:
			continue
		
		# 🌙 夜晚精英率更高，等级 +3~+5
		var current_elite_chance = NIGHT_ELITE_CHANCE if _is_night else _elite_chance
		var is_elite = randf() < current_elite_chance
		var enemy_type = elite_type if is_elite else normal_type
		var level = randi_range(lv_range[0], lv_range[1])
		if _is_night:
			level += randi_range(3, 5)
		
		_spawn_single_enemy(enemy_type, spawn_pos, level, is_elite)

func _spawn_fallback_enemies(player_pos: Vector3) -> void:
	"""生成通用野怪"""
	if not _is_night and randf() > 0.6: return  # 白天 60% 概率不生成
	if _is_night and randf() > 0.3: return       # 夜晚 30% 概率不生成（更多怪）
	var enemy_type = FALLBACK_ENEMIES[randi() % FALLBACK_ENEMIES.size()]
	var offset = Vector3(randf_range(-30, 30), 0, randf_range(-30, 30))
	var spawn_pos = player_pos + offset
	var level = randi_range(3, 12)
	if _is_night:
		level += randi_range(3, 6)
	# 夜晚通用野怪精英率提升
	var current_elite_chance = NIGHT_ELITE_CHANCE if _is_night else 0.03
	var is_elite = randf() < current_elite_chance
	_spawn_single_enemy(enemy_type, spawn_pos, level, is_elite)

func _spawn_single_enemy(enemy_type: int, position: Vector3, level: int, is_elite: bool) -> Node3D:
	"""实例化单个妖兽"""
	var enemy = Enemy.new()
	enemy.enemy_type = enemy_type
	enemy.level = level
	enemy.is_elite = is_elite
	enemy.global_position = position
	add_child(enemy)
	_active_spawns.append(enemy)
	
	var chunk_key = _world_to_chunk(position.x, position.z)
	var key_str = "%d,%d" % [chunk_key.x, chunk_key.y]
	if not _spawn_grid.has(key_str):
		_spawn_grid[key_str] = []
	_spawn_grid[key_str].append(enemy)
	
	return enemy

func _count_nearby_enemies(center: Vector3, radius: float) -> int:
	"""统计附近活跃敌人数"""
	var count = 0
	for e in _active_spawns:
		if e is Enemy and e.is_alive:
			if e.global_position.distance_to(center) <= radius:
				count += 1
	return count

func _get_chunk_enemy_count(chunk: Vector2i) -> int:
	"""获取某区块的敌人数"""
	var key = "%d,%d" % [chunk.x, chunk.y]
	var nodes = _spawn_grid.get(key, [])
	var alive = 0
	for n in nodes:
		if is_instance_valid(n) and n is Enemy and n.is_alive:
			alive += 1
	return alive

func _despawn_far_objects(player_pos: Vector3) -> void:
	"""回收远离玩家的对象"""
	var to_remove: Array[Node] = []
	for obj in _active_spawns:
		if not is_instance_valid(obj):
			to_remove.append(obj)
			continue
		if obj.global_position.distance_to(player_pos) > despawn_radius:
			if obj is Enemy and obj.is_alive:
				obj.queue_free()
			to_remove.append(obj)
	
	for obj in to_remove:
		_active_spawns.erase(obj)
	
	# 清理网格引用
	for key in _spawn_grid.keys():
		_spawn_grid[key] = _spawn_grid[key].filter(func(n): return is_instance_valid(n))

## 手动触发附近刷新（供外部调用）
func force_refresh_enemies() -> void:
	_try_spawn_enemies()

## 🌙 天亮时：清除远处怪物（模拟妖兽退散）
func _despawn_night_enemies() -> void:
	if not player_ref: return
	var player_pos = player_ref.global_position
	var keep_radius = 30.0  # 保留附近30米内的怪（玩家正在打的）
	var to_remove: Array[Node] = []
	for e in _active_spawns:
		if not is_instance_valid(e) or not (e is Enemy):
			continue
		if e.is_alive and e.global_position.distance_to(player_pos) > keep_radius:
			e.queue_free()
			to_remove.append(e)
	for obj in to_remove:
		_active_spawns.erase(obj)
	# 清理网格
	for key in _spawn_grid.keys():
		_spawn_grid[key] = _spawn_grid[key].filter(func(n): return is_instance_valid(n))
	print("☀️ 退散远处妖兽 %d 只" % to_remove.size())

## 获取当前所有妖兽信息
func get_enemy_info() -> Array[Dictionary]:
	var info = []
	for e in _active_spawns:
		if e is Enemy and e.is_alive:
			info.append({
				"name": e.get_enemy_name(),
				"type": e.enemy_type,
				"level": e.level,
				"is_elite": e.is_elite,
				"position": e.global_position,
				"hp": e.hp,
				"max_hp": e.max_hp,
			})
	return info

func get_chunk_count() -> int:
	return _spawn_grid.size()
