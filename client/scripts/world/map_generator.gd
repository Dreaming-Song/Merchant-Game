extends Node
## 地图生成器 — 参考MC地形生成 + 修仙世界特色
##
## 生成流程：
##   海拔图(Perlin) → 生物群系 → 树木/矿石/灵脉分布
##   → 地表建筑(遗迹/洞府) → 怪物出生点
##
## 世界种子决定一切随机

class_name MapGenerator

# ==================== 生物群系 ====================
enum Biome {
	PLAINS,      # 草原 — 新手出生地，资源均衡
	FOREST,      # 森林 — 木材丰富，野兽出没
	MOUNTAIN,    # 山脉 — 矿物丰富，地形陡峭
	DESERT,      # 荒漠 — 缺木多矿，炎热
	SWAMP,       # 沼泽 — 草药丰富，有毒气
	SNOWLAND,    # 雪原 — 寒冰资源，稀有矿
	BAMBOO,      # 竹林 — 灵木产地，宁静
	SPIRIT_VEIN, # 灵脉 — 灵石丰富，高阶区域
	VOLCANO,     # 火山 — 火灵宝地，极度危险
	LAKE,        # 湖泊 — 水产资源
	RUINS,       # 遗迹 — 上古遗址，宝物众多
}

static func get_biome_name(b: int) -> String:
	match b:
		Biome.PLAINS:      return "草原"
		Biome.FOREST:      return "森林"
		Biome.MOUNTAIN:    return "山脉"
		Biome.DESERT:      return "荒漠"
		Biome.SWAMP:       return "沼泽"
		Biome.SNOWLAND:    return "雪原"
		Biome.BAMBOO:      return "竹林"
		Biome.SPIRIT_VEIN: return "灵脉"
		Biome.VOLCANO:     return "火山"
		Biome.LAKE:        return "湖泊"
		Biome.RUINS:       return "遗迹"
	return "未知"

static func get_biome_color(b: int) -> Color:
	match b:
		Biome.PLAINS:      return Color(0.45, 0.75, 0.35)  # 绿
		Biome.FOREST:      return Color(0.20, 0.55, 0.15)  # 深绿
		Biome.MOUNTAIN:    return Color(0.50, 0.45, 0.35)  # 灰棕
		Biome.DESERT:      return Color(0.80, 0.70, 0.40)  # 沙黄
		Biome.SWAMP:       return Color(0.35, 0.50, 0.30)  # 暗绿
		Biome.SNOWLAND:    return Color(0.85, 0.85, 0.95)  # 白
		Biome.BAMBOO:      return Color(0.55, 0.80, 0.35)  # 翠绿
		Biome.SPIRIT_VEIN: return Color(0.50, 0.30, 1.00)  # 紫
		Biome.VOLCANO:     return Color(0.80, 0.20, 0.10)  # 红
		Biome.LAKE:        return Color(0.20, 0.40, 0.80)  # 蓝
		Biome.RUINS:       return Color(0.60, 0.50, 0.30)  # 古铜
	return Color.WHITE

# ==================== 配置 ====================
var world_seed: int = 0
var world_size: int = 1024       # 世界大小（方块单位）
var chunk_size: int = 16         # 区块大小

## 生物群系数据
static func get_biome_data(b: int) -> Dictionary:
	match b:
		Biome.PLAINS:
			return {
				"name": "草原", "height_range": [0.0, 0.2],
				"surface_block": "grass", "subsurface_block": "dirt",
				"trees": {"wood": 0.02},
				"ores": {"stone": 0.8},
				"herbs": {"herb_common": 0.05},
				"danger_level": 0,
				"monster_pool": ["wild_boar", "spirit_rabbit"],
			}
		Biome.FOREST:
			return {
				"name": "森林", "height_range": [0.1, 0.3],
				"surface_block": "grass", "subsurface_block": "dirt",
				"trees": {"wood": 0.15, "spirit_wood": 0.02},
				"ores": {"stone": 0.6, "iron_ore": 0.05},
				"herbs": {"herb_common": 0.08, "herb_qi": 0.03},
				"danger_level": 1,
				"monster_pool": ["wolf", "bear", "spirit_deer"],
			}
		Biome.MOUNTAIN:
			return {
				"name": "山脉", "height_range": [0.4, 0.9],
				"surface_block": "stone", "subsurface_block": "stone",
				"trees": {"wood": 0.03},
				"ores": {"stone": 0.9, "iron_ore": 0.12, "gold_ore": 0.05, "spirit_ore": 0.03},
				"herbs": {"herb_qi": 0.04},
				"danger_level": 2,
				"monster_pool": ["mountain_giant", "eagle", "rock_golem"],
			}
		Biome.DESERT:
			return {
				"name": "荒漠", "height_range": [0.0, 0.15],
				"surface_block": "sand", "subsurface_block": "sandstone",
				"trees": {},
				"ores": {"stone": 0.4, "iron_ore": 0.08, "gold_ore": 0.08},
				"herbs": {"herb_qi": 0.02},
				"danger_level": 2,
				"monster_pool": ["scorpion", "sand_worm", "cactus_golem"],
			}
		Biome.SWAMP:
			return {
				"name": "沼泽", "height_range": [-0.2, 0.1],
				"surface_block": "mud", "subsurface_block": "clay",
				"trees": {"wood": 0.06},
				"ores": {"stone": 0.3},
				"herbs": {"herb_common": 0.1, "herb_qi": 0.06, "herb_spirit": 0.02},
				"danger_level": 2,
				"monster_pool": ["poison_frog", "snake", "swamp_spirit"],
			}
		Biome.SNOWLAND:
			return {
				"name": "雪原", "height_range": [0.2, 0.5],
				"surface_block": "snow", "subsurface_block": "permafrost",
				"trees": {"wood": 0.02},
				"ores": {"stone": 0.7, "iron_ore": 0.1, "spirit_ore": 0.05, "spirit_crystal": 0.01},
				"herbs": {"herb_spirit": 0.03},
				"danger_level": 3,
				"monster_pool": ["ice_wolf", "snow_ghost", "frost_dragon"],
			}
		Biome.BAMBOO:
			return {
				"name": "竹林", "height_range": [0.1, 0.25],
				"surface_block": "grass", "subsurface_block": "dirt",
				"trees": {"spirit_wood": 0.2},
				"ores": {"stone": 0.4, "spirit_stone": 0.05},
				"herbs": {"herb_qi": 0.05, "herb_spirit": 0.03},
				"danger_level": 1,
				"monster_pool": ["panda", "spirit_monkey"],
			}
		Biome.SPIRIT_VEIN:
			return {
				"name": "灵脉", "height_range": [0.2, 0.6],
				"surface_block": "spirit_grass", "subsurface_block": "spirit_stone",
				"trees": {"spirit_wood": 0.08},
				"ores": {"spirit_ore": 0.2, "spirit_stone": 0.15, "spirit_jade": 0.05, "spirit_crystal": 0.02},
				"herbs": {"herb_spirit": 0.08, "herb_celestial": 0.02},
				"danger_level": 4,
				"monster_pool": ["spirit_beast", "guardian_golem", "ancient_spirit"],
			}
		Biome.VOLCANO:
			return {
				"name": "火山", "height_range": [0.5, 1.0],
				"surface_block": "magma_stone", "subsurface_block": "obsidian",
				"trees": {},
				"ores": {"gold_ore": 0.15, "spirit_jade": 0.08, "celestial_iron": 0.02},
				"herbs": {},
				"danger_level": 5,
				"monster_pool": ["fire_giant", "lava_worm", "phoenix"],
			}
		Biome.LAKE:
			return {
				"name": "湖泊", "height_range": [-0.5, -0.1],
				"surface_block": "water", "subsurface_block": "sand",
				"trees": {},
				"ores": {"stone": 0.2},
				"herbs": {"herb_qi": 0.03},
				"danger_level": 0,
				"monster_pool": ["water_spirit", "fish"],
			}
		Biome.RUINS:
			return {
				"name": "遗迹", "height_range": [0.1, 0.3],
				"surface_block": "ancient_stone", "subsurface_block": "stone",
				"trees": {},
				"ores": {"stone": 0.5, "spirit_stone": 0.1, "spirit_jade": 0.05},
				"herbs": {"herb_spirit": 0.05},
				"danger_level": 3,
				"monster_pool": ["undead_warrior", "ancient_golem", "guardian_spirit"],
				"has_structure": true,
				"structure_pool": ["ruin_temple", "ancient_altar", "secret_room"],
			}
	return {}

# ==================== 地图地形生成 ====================

## 生成世界地图
## 返回 {chunks: {chunk_key: chunk_data}}
func generate_world() -> Dictionary:
	var world_data = {
		"seed": world_seed,
		"size": world_size,
		"chunks": {},
		"biome_map": {},
		"spawn_point": Vector3(0, 0, 0),
	}
	
	# 1. 生成生物群系图
	world_data.biome_map = _generate_biome_map()
	
	# 2. 生成初始区块（出生点附近）
	var spawn_chunks = _generate_spawn_area()
	for key in spawn_chunks.keys():
		world_data["chunks"][key] = spawn_chunks[key]
	
	# 3. 确定出生点
	world_data.spawn_point = _find_spawn_point(world_data)
	
	return world_data

## 生成指定的单个区块（按需加载）
func generate_chunk(cx: int, cz: int, biome_map: Dictionary) -> Dictionary:
	var chunk_data = {
		"cx": cx, "cz": cz,
		"blocks": [],       # 方块数据
		"trees": [],        # 树木位置
		"ores": [],         # 矿石位置
		"herbs": [],        # 草药位置
		"structures": [],   # 建筑结构
		"monsters": [],     # 怪物出生点
		"biome": Biome.PLAINS,
	}
	
	# 获取生物群系
	var biome = _get_chunk_biome(cx, cz, biome_map)
	chunk_data["biome"] = biome
	var biome_info = get_biome_data(biome)
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(str(world_seed) + "_" + str(cx) + "_" + str(cz))
	
	# 生成地形
	var height_map = _generate_height_map(cx, cz, biome, rng)
	chunk_data["blocks"] = height_map
	
	# 放置树木
	if biome_info.get("trees", {}).size() > 0:
		chunk_data["trees"] = _place_features(chunk_data, biome_info.get("trees", {}), rng)
	
	# 放置矿石
	if biome_info.get("ores", {}).size() > 0:
		chunk_data["ores"] = _place_ores(chunk_data, biome_info.get("ores", {}), rng)
	
	# 放置草药
	if biome_info.get("herbs", {}).size() > 0:
		chunk_data["herbs"] = _place_features(chunk_data, biome_info.get("herbs", {}), rng)
	
	# 放置建筑结构
	if biome_info.get("has_structure") or false and rng.randf() < 0.3:
		var struct_type = biome_info.get("structure_pool", [])[rng.randi() % biome_info.get("structure_pool", []).size()]
		chunk_data["structures"].append({
			"type": struct_type,
			"position": _find_structure_pos(chunk_data, rng),
		})
	
	# 放置怪物出生点
	var monster_count = rng.randi_range(2, 5 + biome_info.get("danger_level", 0) * 2)
	for i in range(monster_count):
		var monster_type = biome_info.get("monster_pool", [])[rng.randi() % biome_info.get("monster_pool", []).size()]
		var x = rng.randi_range(chunk_size * cx, chunk_size * (cx + 1) - 1)
		var z = rng.randi_range(chunk_size * cz, chunk_size * (cz + 1) - 1)
		var y = _get_height(height_map, x, z)
		chunk_data["monsters"].append({
			"type": monster_type,
			"position": Vector3(x, y, z),
		})
	
	return chunk_data

# ==================== 内部生成方法 ====================

func _generate_biome_map() -> Dictionary:
	"""使用噪声生成生物群系分布 — 连续平滑过渡"""
	var biome_map = {}
	var chunks_per_side = world_size / chunk_size
	
	# 温度 + 湿度 双轴决定生物群系
	for cx in range(-chunks_per_side, chunks_per_side + 1):
		for cz in range(-chunks_per_side, chunks_per_side + 1):
			var center_x = cx * chunk_size + chunk_size / 2
			var center_z = cz * chunk_size + chunk_size / 2
			
			# 温度 (0~1): 纬度 + 海拔 + 随机
			var temp = _noise_2d_norm(center_x, center_z, 0.005)
			# 湿度 (0~1)
			var moisture = _noise_2d_norm(center_x, center_z, 0.008)
			# 海拔
			var elevation = _noise_2d_norm(center_x, center_z, 0.003)
			
			var biome = _biome_from_climate(temp, moisture, elevation)
			biome_map["%d_%d" % [cx, cz]] = biome
	
	return biome_map

func _biome_from_climate(temp: float, moisture: float, elevation: float) -> int:
	"""根据温湿海拔确定生物群系"""
	# 高海拔
	if elevation > 0.75:
		if temp > 0.6: return Biome.VOLCANO
		elif temp > 0.3: return Biome.MOUNTAIN
		else: return Biome.SNOWLAND
	
	# 低洼（水）
	if elevation < 0.2 and moisture > 0.6:
		return Biome.LAKE if moisture > 0.8 else Biome.SWAMP
	
	# 根据温湿
	if temp > 0.7:  # 热
		if moisture > 0.6: return Biome.FOREST
		elif moisture > 0.3: return Biome.PLAINS
		else: return Biome.DESERT
	elif temp > 0.4:  # 温
		if moisture > 0.7: return Biome.FOREST
		elif moisture > 0.5: return Biome.BAMBOO
		elif moisture > 0.2: return Biome.PLAINS
		else: return Biome.RUINS
	else:  # 冷
		if moisture > 0.6: return Biome.SNOWLAND
		elif moisture > 0.3: return Biome.SPIRIT_VEIN
		else: return Biome.MOUNTAIN

func _get_chunk_biome(cx: int, cz: int, biome_map: Dictionary) -> int:
	var key = "%d_%d" % [cx, cz]
	return biome_map.get(key, Biome.PLAINS)

func _generate_height_map(cx: int, cz: int, biome: int, rng: RandomNumberGenerator) -> Array:
	"""使用噪声生成真实地形高度"""
	var biome_info = get_biome_data(biome)
	var height_range = biome_info.get("height_range", [0.0, 0.5])
	var base_height = (height_range[0] + height_range[1]) * 0.5
	var height_amp = (height_range[1] - height_range[0]) * 0.5
	var blocks = []
	
	var start_x = cx * chunk_size
	var start_z = cz * chunk_size
	
	# 主地形噪声
	var terrain_scale = 0.02
	# 细节噪声
	var detail_scale = 0.05
	
	for x in range(chunk_size):
		var row = []
		for z in range(chunk_size):
			var wx = start_x + x
			var wz = start_z + z
			
			# 主地形
			var main_noise = _noise_2d(wx, wz, terrain_scale)
			# 细节起伏
			var detail_noise = _noise_2d(wx, wz, detail_scale) * 0.3
			# 组合
			var noise_val = main_noise + detail_noise
			var h = base_height + noise_val * height_amp
			h = clamp(h, -0.5, 1.0)
			
			# 水面检测
			var is_water = h < 0.0
			
			row.append({
				"height": h,
				"surface": "water" if is_water else biome_info.get("surface_block", "grass"),
				"subsurface": "sand" if is_water else biome_info.get("subsurface_block", "dirt"),
				"is_water": is_water,
			})
		blocks.append(row)
	
	return blocks

func _get_height(height_map: Array, x: int, z: int) -> float:
	"""从高度图获取某点高度"""
	if height_map.is_empty():
		return 0
	var lx = x % chunk_size
	var lz = z % chunk_size
	if lx < 0: lx += chunk_size
	if lz < 0: lz += chunk_size
	if lx < height_map.size() and lz < height_map[0].size():
		return height_map[lx][lz].height
	return 0

func _place_features(chunk: Dictionary, feature_rates: Dictionary, rng: RandomNumberGenerator) -> Array:
	"""放置树木/草药等地面特征"""
	var features = []
	var cx = chunk["cx"] * chunk_size
	var cz = chunk["cz"] * chunk_size
	
	for feat_id in feature_rates.keys():
		var rate = feature_rates[feat_id]
		var count = int(chunk_size * chunk_size * rate)
		
		for i in range(count):
			var x = rng.randi_range(cx, cx + chunk_size - 1)
			var z = rng.randi_range(cz, cz + chunk_size - 1)
			var y = _get_height(chunk["blocks"], x, z) * 10 + 1
			
			features.append({
				"type": feat_id,
				"position": Vector3(x, y, z),
				"rotation": rng.randf() * 360,
			})
	
	return features

func _place_ores(chunk: Dictionary, ore_rates: Dictionary, rng: RandomNumberGenerator) -> Array:
	"""放置矿脉（在地下）"""
	var ores = []
	var cx = chunk["cx"] * chunk_size
	var cz = chunk["cz"] * chunk_size
	
	for ore_id in ore_rates.keys():
		var rate = ore_rates[ore_id]
		var count = int(chunk_size * chunk_size * rate * 0.5)  # 矿密度减半
		
		for i in range(count):
			var x = rng.randi_range(cx, cx + chunk_size - 1)
			var z = rng.randi_range(cz, cz + chunk_size - 1)
			var surface_height = _get_height(chunk["blocks"], x, z) * 10
			var y = rng.randf_range(-5, surface_height - 1)  # 地下
			
			ores.append({
				"type": ore_id,
				"position": Vector3(x, y, z),
				"vein_size": rng.randi_range(1, 5),
			})
	
	return ores

func _find_structure_pos(chunk: Dictionary, rng: RandomNumberGenerator) -> Vector3:
	var cx = chunk["cx"] * chunk_size
	var cz = chunk["cz"] * chunk_size
	var x = rng.randi_range(cx + 2, cx + chunk_size - 3)
	var z = rng.randi_range(cz + 2, cz + chunk_size - 3)
	var y = _get_height(chunk["blocks"], x, z) * 10
	return Vector3(x, y, z)

func _generate_spawn_area() -> Dictionary:
	"""生成出生点附近的区块（中心 3x3 区块）"""
	var chunks = {}
	for cx in range(-1, 2):
		for cz in range(-1, 2):
			var biome_map = _generate_biome_map()
			var key = "%d_%d" % [cx, cz]
			chunks[key] = generate_chunk(cx, cz, biome_map)
	return chunks

func _find_spawn_point(world_data: Dictionary) -> Vector3:
	"""找到第一个草原区块的中心位置"""
	for key in world_data.get("chunks", {}).keys():
		var chunk = world_data.get("chunks", {}).get(key, {})
		var biome_info = get_biome_data(chunk["biome"])
		if biome_info.get("danger_level", 0) == 0:
			var cx = chunk["cx"] * chunk_size + chunk_size / 2
			var cz = chunk["cz"] * chunk_size + chunk_size / 2
			var y = _get_height(chunk["blocks"], cx, cz) * 10
			return Vector3(cx, y + 1, cz)
	return Vector3(0, 1, 0)

# ==================== 程序化噪声生成 ====================

var _noise_cache: Dictionary = {}  # 缓存已计算的位置噪声值

## 获取 2D Perlin-风格噪声值（使用 Godot 内置 FastNoiseLite 或简单实现）
func _noise_2d(x: float, y: float, scale: float = 0.01) -> float:
	"""返回 -1~1 的噪声值"""
	var key = "%s_%.1f_%.1f_%.3f" % [world_seed, x, y, scale]
	if _noise_cache.has(key):
		return _noise_cache[key]
	
	# 用 hash 模拟 Perlin 效果（多频叠加）
	var val = 0.0
	var amp = 1.0
	var freq = scale
	var max_val = 0.0
	for i in range(4):  # 4 层 octaves
		var h = hash(str(world_seed) + "_n_" + str(int(x * freq)) + "_" + str(int(y * freq)))
		var n = (h % 20000 - 10000) / 10000.0
		val += n * amp
		max_val += amp
		amp *= 0.5
		freq *= 2.0
	
	val = val / max_val  # 归一化到 -1~1
	_noise_cache[key] = val
	return val

## 获取 2D 噪声值（0~1 范围）
func _noise_2d_norm(x: float, y: float, scale: float = 0.01) -> float:
	return (_noise_2d(x, y, scale) + 1.0) * 0.5

## 清空噪声缓存（世界切换时调用）
func clear_noise_cache() -> void:
	_noise_cache.clear()

# ==================== 区块管理 ====================

## 获取玩家附近需要加载的区块列表
func get_visible_chunks(player_pos: Vector3, view_distance: int = 4) -> Array[Array]:
	var px = int(player_pos.x / chunk_size)
	var pz = int(player_pos.z / chunk_size)
	var visible: Array[Array] = []
	
	for cx in range(px - view_distance, px + view_distance + 1):
		for cz in range(pz - view_distance, pz + view_distance + 1):
			visible.append([cx, cz])
	
	return visible

## 根据境界调整世界范围（修为越高，世界越广）
static func get_world_radius_for_realm(realm: int) -> int:
	match realm:
		0: return 128    # 凡人：小范围
		1: return 256    # 练气
		2: return 512    # 筑基
		3: return 1024   # 金丹
		4: return 2048   # 元婴
		5: return 4096   # 化神+
	return 128
