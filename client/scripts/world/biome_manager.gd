extends Node
## 🌍 群系生态管理器（9大陆群系 + 海域）— 群岛式世界
##
## 新增海域系统：噪声生成大陆轮廓，海域环绕分布
## 大陆之间由海洋隔开，形成群岛地貌
##
## 海域层级：
##   - shallow_ocean（浅海/沙滩过渡带）
##   - deep_ocean（深海）

# class_name BiomeManager — 已通过 autoload 注册

# ==================== 群系标记 ====================
enum BiomeTag {
	GREEN,      # 青色
	RED,        # 赤色
	WHITE,      # 白色
	PURPLE,     # 紫色
	YELLOW,     # 金色
	OCEAN,      # 海域
}

# ==================== 数据结构 ====================
class TerrainProfile:
	var base_height: float
	var height_amplitude: float
	var roughness: float
	var water_level: float
	var water_chance: float

class TreeType:
	var name: String
	var scene: String
	var density: float
	var min_height: float
	var max_height: float

class TreeDistribution:
	var tree_types: Array[TreeType] = []
	var total_density: float

class BiomeData:
	var name: String
	var tag: BiomeTag
	var description: String
	var is_ocean: bool          # 是否为海域
	
	var ground_color: Color
	var fog_color: Color
	var fog_density: float
	var ambient_color: Color
	var sky_tint: Color
	
	var terrain: TerrainProfile
	
	var vegetation_density: float
	var grass_color: Color
	var grass_height: float
	
	var trees: TreeDistribution
	
	var spawn_pool: Array[String] = []
	var special_resources: Array[String] = []
	
	var building_materials: Array[String] = []
	
	var mob_spawns: Array[Dictionary] = []
	
	func _init():
		# 注意：不能使用 Array[String]() 语法，改用空数组 + 后续类型推导
		pass
	var danger_level: float
	
	var wind_strength: float
	var particle_effect: String
	var music_track: String

var _biomes: Dictionary = {}

# 噪声采样器
var _noise_biome: FastNoiseLite     # 群系分布
var _noise_land: FastNoiseLite      # 大陆/海洋掩码
var _noise_detail: FastNoiseLite    # 细节

func _ready() -> void:
	_noise_biome = FastNoiseLite.new()
	_noise_biome.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise_biome.seed = randi()
	_noise_biome.frequency = 0.008
	
	_noise_land = FastNoiseLite.new()
	_noise_land.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise_land.seed = randi() + 999
	_noise_land.frequency = 0.006    # 更大尺度的陆地形状
	
	_noise_detail = FastNoiseLite.new()
	_noise_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise_detail.seed = randi() + 555
	_noise_detail.frequency = 0.02
	
	_register_biomes()
	print("🌍 已注册 %d 个群系（含海域）" % _biomes.size())

# ==================== 注册全部10个群系（含海域） ====================

func _register_biomes() -> void:
	# ===== 0. 海域 🌊（注册到第一位，方便兜底） =====
	_biomes["ocean"] = _make_biome({
		"name": "无尽海域",
		"tag": BiomeTag.OCEAN,
		"desc": "浩瀚无垠的灵海，水中有上古遗族和珍稀海产",
		"is_ocean": true,
		"ground": Color(0.08, 0.15, 0.25),
		"fog": Color(0.15, 0.25, 0.35), "fog_d": 0.20,
		"ambient": Color(0.12, 0.20, 0.30),
		"sky": Color(0.20, 0.30, 0.40),
		"veg": 0.0, "grass_c": Color(0.0, 0.0, 0.0), "grass_h": 0.0,
		"danger": 0.5, "wind": 0.5, "particle": "ocean_wave",
		"music": "res://assets/audio/bgm_ocean.ogg",
		"terrain": [-3.0, 0.5, 0.1, -0.5, 1.0],   # 水面下
		"trees": [0.0, []],
		"spawn": ["herb_seaweed", "ore_coral", "chest_sunken", "encounter_sea", "pearl_oyster"],
		"special": ["spirit_pearl", "sea_essence", "ancient_compass"],
		"build": ["coral_stone", "sea_brick", "shell_tile"],
		"mobs": [["sea_serpent", 20, 15, 35], ["water_spirit", 30, 10, 25], ["giant_crab", 25, 12, 28], ["ancient_kraken", 5, 35, 55]],
	})

	# ===== 1. 青翠竹林 🎋 =====
	_biomes["bamboo_forest"] = _make_biome({
		"name": "青翠竹林",
		"tag": BiomeTag.GREEN,
		"desc": "竹林幽静，灵草遍地，修行者的起点",
		"ground": Color(0.25, 0.45, 0.20),
		"fog": Color(0.65, 0.75, 0.55), "fog_d": 0.12,
		"ambient": Color(0.50, 0.55, 0.40),
		"sky": Color(0.60, 0.70, 0.55),
		"veg": 0.7, "grass_c": Color(0.35, 0.55, 0.25), "grass_h": 0.3,
		"danger": 0.1, "wind": 0.3, "particle": "bamboo_leaves",
		"music": "res://assets/audio/bgm_bamboo.ogg",
		"terrain": [0.0, 1.0, 0.2, -1.0, 0.0],
		"trees": [0.6, [["竹", "tree_bamboo", 0.8, 3, 8], ["灵竹", "tree_spirit_bamboo", 0.2, 5, 12]]],
		"spawn": ["herb_spirit_grass", "herb_jade_flower", "ore_copper", "chest_common", "tree_wood"],
		"special": ["herb_spirit_grass", "tree_spirit_wood"],
		"build": ["thatch", "bamboo", "wood"],
		"mobs": [["spirit_rabbit", 50, 1, 5], ["bamboo_slime", 30, 1, 8]],
	})

	# ===== 2. 落霞枫林 🍁 =====
	_biomes["maple_forest"] = _make_biome({
		"name": "落霞枫林",
		"tag": BiomeTag.RED,
		"desc": "枫叶似火，古观隐于林间",
		"ground": Color(0.55, 0.25, 0.15),
		"fog": Color(0.80, 0.50, 0.30), "fog_d": 0.10,
		"ambient": Color(0.70, 0.35, 0.20),
		"sky": Color(0.80, 0.55, 0.35),
		"veg": 0.6, "grass_c": Color(0.60, 0.30, 0.18), "grass_h": 0.25,
		"danger": 0.3, "wind": 0.5, "particle": "maple_leaves",
		"music": "res://assets/audio/bgm_maple.ogg",
		"terrain": [2.0, 3.0, 0.4, -1.0, 0.05],
		"trees": [0.5, [["枫树", "tree_maple", 0.7, 4, 10], ["古枫", "tree_ancient_maple", 0.15, 8, 16], ["红杉", "tree_redwood", 0.15, 5, 12]]],
		"spawn": ["herb_flame_flower", "ore_iron", "chest_rare", "encounter_wild", "tree_wood"],
		"special": ["herb_flame_flower", "maple_sap"],
		"build": ["wood", "red_brick", "stone"],
		"mobs": [["maple_fox", 40, 5, 12], ["wild_boar", 30, 5, 15], ["spirit_crow", 20, 8, 15]],
	})

	# ===== 3. 寒雪山巅 ❄️ =====
	_biomes["snow_peak"] = _make_biome({
		"name": "寒雪山巅",
		"tag": BiomeTag.WHITE,
		"desc": "终年积雪，灵兽出没，唯强者可至",
		"ground": Color(0.85, 0.88, 0.92),
		"fog": Color(0.90, 0.92, 0.95), "fog_d": 0.25,
		"ambient": Color(0.75, 0.80, 0.90),
		"sky": Color(0.85, 0.88, 0.95),
		"veg": 0.1, "grass_c": Color(0.70, 0.75, 0.80), "grass_h": 0.1,
		"danger": 0.6, "wind": 0.8, "particle": "snow",
		"music": "res://assets/audio/bgm_snow.ogg",
		"terrain": [8.0, 6.0, 0.7, -2.0, 0.0],
		"trees": [0.08, [["雪松", "tree_snow_pine", 0.7, 2, 5], ["冰晶树", "tree_ice_crystal", 0.3, 3, 7]]],
		"spawn": ["herb_ice_lotus", "ore_silver", "chest_legendary", "tree_wood"],
		"special": ["herb_ice_lotus", "ice_crystal", "snow_silk"],
		"build": ["stone", "ice_brick", "crystal"],
		"mobs": [["snow_wolf", 40, 15, 25], ["ice_golem", 20, 20, 35], ["frost_spirit", 25, 15, 30]],
	})

	# ===== 4. 幽暗沼泽 🪷 =====
	_biomes["swamp"] = _make_biome({
		"name": "幽暗沼泽",
		"tag": BiomeTag.PURPLE,
		"desc": "毒雾弥漫，危机四伏，却藏有远古遗宝",
		"ground": Color(0.20, 0.18, 0.12),
		"fog": Color(0.30, 0.45, 0.25), "fog_d": 0.40,
		"ambient": Color(0.25, 0.30, 0.20),
		"sky": Color(0.30, 0.35, 0.25),
		"veg": 0.4, "grass_c": Color(0.18, 0.28, 0.15), "grass_h": 0.5,
		"danger": 0.7, "wind": 0.1, "particle": "swamp_firefly",
		"music": "res://assets/audio/bgm_swamp.ogg",
		"terrain": [-1.0, 1.5, 0.5, 0.0, 0.4],
		"trees": [0.3, [["枯木", "tree_deadwood", 0.6, 3, 6], ["毒藤树", "tree_poison_vine", 0.25, 2, 5], ["幽光菇", "tree_glow_mushroom", 0.15, 1, 3]]],
		"spawn": ["herb_toadstool", "herb_ghost_flower", "ore_ancient", "chest_cursed", "encounter_elite", "tree_wood"],
		"special": ["herb_ghost_flower", "swamp_essence", "ancient_relic"],
		"build": ["stone", "ancient_brick", "moss_stone"],
		"mobs": [["swamp_crocodile", 30, 18, 30], ["poison_frog", 40, 12, 22], ["ghost_wisp", 20, 20, 35]],
	})

	# ===== 5. 灵焰火山 🌋 =====
	_biomes["volcano"] = _make_biome({
		"name": "灵焰火山",
		"tag": BiomeTag.RED,
		"desc": "地心灵焰涌动，神兽蛰伏于岩浆深处",
		"ground": Color(0.35, 0.15, 0.08),
		"fog": Color(0.60, 0.25, 0.10), "fog_d": 0.22,
		"ambient": Color(0.50, 0.20, 0.10),
		"sky": Color(0.60, 0.30, 0.15),
		"veg": 0.02, "grass_c": Color(0.20, 0.08, 0.03), "grass_h": 0.1,
		"danger": 0.9, "wind": 0.6, "particle": "volcano_ash",
		"music": "res://assets/audio/bgm_volcano.ogg",
		"terrain": [5.0, 8.0, 0.8, -3.0, 0.0],
		"trees": [0.02, [["焦木", "tree_charred", 0.7, 1, 3], ["熔岩树", "tree_lava", 0.3, 2, 5]]],
		"spawn": ["herb_fire_root", "ore_gold", "chest_epic", "encounter_boss", "tree_wood"],
		"special": ["herb_fire_root", "lava_core", "phoenix_feather"],
		"build": ["stone", "magma_brick", "obsidian"],
		"mobs": [["lava_elemental", 30, 25, 40], ["fire_serpent", 25, 28, 45], ["magma_golem", 20, 30, 50]],
	})

	# ===== 6. 桃花源 🌸 =====
	_biomes["peach_blossom"] = _make_biome({
		"name": "桃花源",
		"tag": BiomeTag.GREEN,
		"desc": "落英缤纷，灵泉潺潺，宛如人间仙境",
		"ground": Color(0.40, 0.55, 0.35),
		"fog": Color(0.75, 0.70, 0.65), "fog_d": 0.08,
		"ambient": Color(0.55, 0.50, 0.45),
		"sky": Color(0.70, 0.65, 0.60),
		"veg": 0.8, "grass_c": Color(0.45, 0.60, 0.30), "grass_h": 0.2,
		"danger": 0.2, "wind": 0.4, "particle": "petal_fall",
		"music": "res://assets/audio/bgm_peach.ogg",
		"terrain": [1.0, 2.0, 0.25, -0.5, 0.15],
		"trees": [0.7, [["桃树", "tree_peach", 0.75, 3, 7], ["灵桃", "tree_spirit_peach", 0.15, 4, 9], ["柳树", "tree_willow", 0.1, 3, 6]]],
		"spawn": ["herb_spirit_grass", "herb_jade_flower", "ore_copper", "ore_iron", "chest_common", "chest_rare", "tree_wood"],
		"special": ["peach_fruit", "spirit_water", "silk_petal"],
		"build": ["wood", "bamboo", "jade", "silk"],
		"mobs": [["peach_spirit", 35, 8, 18], ["jade_deer", 30, 5, 15], ["butterfly_fairy", 20, 10, 20]],
	})

	# ===== 7. 星辰沙漠 ✨ =====
	_biomes["stellar_desert"] = _make_biome({
		"name": "星辰沙漠",
		"tag": BiomeTag.PURPLE,
		"desc": "沙海中的古老战场，星辰碎片散落其中",
		"ground": Color(0.65, 0.58, 0.40),
		"fog": Color(0.55, 0.50, 0.60), "fog_d": 0.05,
		"ambient": Color(0.50, 0.45, 0.55),
		"sky": Color(0.50, 0.45, 0.65),
		"veg": 0.05, "grass_c": Color(0.50, 0.45, 0.25), "grass_h": 0.1,
		"danger": 0.8, "wind": 0.7, "particle": "sand_storm",
		"music": "res://assets/audio/bgm_stellar.ogg",
		"terrain": [1.0, 5.0, 0.3, -5.0, 0.0],
		"trees": [0.05, [["仙人掌", "tree_cactus", 0.6, 1, 4], ["星辉树", "tree_starlight", 0.4, 2, 6]]],
		"spawn": ["ore_gold", "ore_silver", "ore_ancient", "chest_legendary", "chest_epic", "encounter_elite", "encounter_boss"],
		"special": ["star_shard", "desert_rose", "ancient_core"],
		"build": ["stone", "crystal", "sandstone", "star_metal"],
		"mobs": [["sand_worm", 30, 25, 40], ["scorpion_king", 25, 28, 42], ["stellar_phantom", 20, 30, 48], ["ancient_golem", 10, 35, 55]],
	})

	# ===== 8. 雷暴平原 ⚡ =====
	_biomes["thunder_plains"] = _make_biome({
		"name": "雷暴平原",
		"tag": BiomeTag.YELLOW,
		"desc": "天雷滚滚，灵气狂暴，是淬炼肉身的最佳场所",
		"ground": Color(0.30, 0.28, 0.15),
		"fog": Color(0.35, 0.32, 0.20), "fog_d": 0.18,
		"ambient": Color(0.30, 0.28, 0.20),
		"sky": Color(0.35, 0.30, 0.25),
		"veg": 0.3, "grass_c": Color(0.28, 0.45, 0.15), "grass_h": 0.15,
		"danger": 0.95, "wind": 1.0, "particle": "lightning_sparks",
		"music": "res://assets/audio/bgm_thunder.ogg",
		"terrain": [2.0, 4.0, 0.45, -0.5, 0.08],
		"trees": [0.15, [["铁木", "tree_ironwood", 0.6, 3, 8], ["雷击木", "tree_lightning_struck", 0.3, 2, 5], ["紫电竹", "tree_thunder_bamboo", 0.1, 4, 10]]],
		"spawn": ["ore_gold", "ore_ancient", "chest_epic", "chest_legendary", "encounter_elite", "encounter_boss"],
		"special": ["thunder_core", "lightning_essence", "ironwood_bark"],
		"build": ["stone", "thunder_brick", "ironwood", "crystal"],
		"mobs": [["thunder_beast", 30, 30, 50], ["lightning_elemental", 25, 32, 48], ["storm_titan", 10, 40, 60], ["electric_wisp", 25, 28, 40]],
	})

	# ===== 9. 和风平原 🌾 =====
	_biomes["wind_plains"] = _make_biome({
		"name": "和风平原",
		"tag": BiomeTag.GREEN,
		"desc": "微风拂过金黄色的麦浪，宁静祥和的田园之地",
		"ground": Color(0.55, 0.60, 0.30),
		"fog": Color(0.70, 0.72, 0.58), "fog_d": 0.08,
		"ambient": Color(0.60, 0.62, 0.45),
		"sky": Color(0.65, 0.72, 0.60),
		"veg": 0.9, "grass_c": Color(0.58, 0.65, 0.28), "grass_h": 0.4,
		"danger": 0.15, "wind": 0.6, "particle": "wind_ripple",
		"music": "res://assets/audio/bgm_wind_plains.ogg",
		"terrain": [0.5, 1.5, 0.15, -0.5, 0.10],
		"trees": [0.2, [["银杏", "tree_ginkgo", 0.5, 4, 10], ["垂柳", "tree_weeping_willow", 0.3, 3, 7], ["果树", "tree_fruit", 0.2, 2, 5]]],
		"spawn": ["herb_spirit_grass", "ore_copper", "ore_iron", "chest_common", "tree_wood"],
		"special": ["wheat_grain", "wind_essence", "ginkgo_leaf"],
		"build": ["wood", "thatch", "clay_brick", "stone"],
		"mobs": [["wind_fawn", 40, 1, 8], ["field_rabbit", 35, 1, 5], ["scarecrow_sprite", 15, 5, 12]],
	})


# ==================== 辅助构造 ====================

func _make_biome(d: Dictionary) -> BiomeData:
	var b = BiomeData.new()
	b.name = d.get("name", "")
	b.tag = d.get("tag", BiomeTag.GREEN)
	b.description = d.get("desc", "")
	b.is_ocean = d.get("is_ocean", false)
	b.ground_color = d.get("ground", Color.GRAY)
	b.fog_color = d.get("fog", Color.GRAY)
	b.fog_density = d.get("fog_d", 0.1)
	b.ambient_color = d.get("ambient") if d.get("ambient") is Color else Color.GRAY
	b.sky_tint = d.get("sky") if d.get("sky") is Color else Color.GRAY
	b.vegetation_density = d.get("veg") if typeof(d.get("veg")) in [TYPE_FLOAT, TYPE_INT] else 0.5
	b.grass_color = d.get("grass_c") if d.get("grass_c") is Color else Color.GREEN
	b.grass_height = d.get("grass_h") if typeof(d.get("grass_h")) in [TYPE_FLOAT, TYPE_INT] else 0.3
	b.danger_level = d.get("danger") if typeof(d.get("danger")) in [TYPE_FLOAT, TYPE_INT] else 0.0
	b.wind_strength = d.get("wind") if typeof(d.get("wind")) in [TYPE_FLOAT, TYPE_INT] else 0.3
	b.particle_effect = d.get("particle") if d.get("particle") is String else ""
	b.music_track = d.get("music") if d.get("music") is String else ""
	
	var tp = d.get("terrain") if d.get("terrain") is Array else [0, 1, 0.3, -1, 0]
	b.terrain = TerrainProfile.new()
	b.terrain.base_height = tp[0]
	b.terrain.height_amplitude = tp[1]
	b.terrain.roughness = tp[2]
	b.terrain.water_level = tp[3]
	b.terrain.water_chance = tp[4]
	
	var tr = d.get("trees", [0.3, []])
	b.trees = TreeDistribution.new()
	b.trees.total_density = tr[0]
	# tree_types 已在 TreeDistribution 类中初始化为空 Array[TreeType]
	for tt in tr[1]:
		var t = TreeType.new()
		t.name = tt[0]
		t.scene = tt[1]
		t.density = tt[2]
		t.min_height = tt[3]
		t.max_height = tt[4]
		b.trees.tree_types.append(t)
	
	b.spawn_pool.clear()
	var _spawn = d.get("spawn")
	if _spawn is Array:
		for item in _spawn:
			b.spawn_pool.append(item)
	b.special_resources.clear()
	var _special = d.get("special")
	if _special is Array:
		for item in _special:
			b.special_resources.append(item)
	b.building_materials.clear()
	var _build = d.get("build")
	if _build is Array:
		for item in _build:
			b.building_materials.append(item)
	
	b.mob_spawns.clear()
	var mobs_data = d.get("mobs")
	if mobs_data is Array:
		for ms in mobs_data:
			b.mob_spawns.append({"id": ms[0], "weight": ms[1], "min_level": ms[2], "max_level": ms[3]})
	
	return b


# ==================== 公共接口 ====================

func get_biome_at(world_pos: Vector3) -> BiomeData:
	return _biomes.get(_sample_biome_map(world_pos.x, world_pos.z), _biomes["ocean"])

func get_biome_name_at(world_pos: Vector3) -> String:
	return _sample_biome_map(world_pos.x, world_pos.z)

func get_biome_by_name(name: String) -> BiomeData:
	return _biomes.get(name, _biomes["ocean"])

func get_biome_names() -> PackedStringArray:
	var names: PackedStringArray
	for key in _biomes.keys():
		names.append(key)
	return names

func get_vegetation_density_at(world_pos: Vector3) -> float:
	return get_biome_at(world_pos).vegetation_density

func get_spawn_pool_at(world_pos: Vector3) -> Array[String]:
	return get_biome_at(world_pos).spawn_pool

func get_tree_distribution_at(world_pos: Vector3) -> TreeDistribution:
	return get_biome_at(world_pos).trees

func get_building_materials_at(world_pos: Vector3) -> Array[String]:
	return get_biome_at(world_pos).building_materials

func get_mob_spawns_at(world_pos: Vector3) -> Array[Dictionary]:
	return get_biome_at(world_pos).mob_spawns

func get_danger_level_at(world_pos: Vector3) -> float:
	return get_biome_at(world_pos).danger_level

func get_terrain_profile_at(world_pos: Vector3) -> TerrainProfile:
	return get_biome_at(world_pos).terrain

func get_biome_tag_at(world_pos: Vector3) -> int:
	return get_biome_at(world_pos).tag

## 判断某位置是否为海域
func is_ocean_at(world_pos: Vector3) -> bool:
	return get_biome_at(world_pos).is_ocean


# ==================== 核心采样 ====================
## 在原有9群系环状布局中，自然嵌入海域
## 海域通过噪声随机分布 + 距离权重控制
## 海岸线形状不规则，形成湖泊/内海/海湾

func _sample_biome_map(x: float, z: float) -> String:
	var dist = sqrt(x * x + z * z)
	
	# 安全区：半径25内为竹林（无海域）
	if dist < 25.0:
		return "bamboo_forest"
	
	# ---- 海域判定 ----
	# 使用独立噪声产生自然水域分布
	var ocean_noise = _noise_land.get_noise_2d(x, z)
	
	# 远离中心时海域概率逐渐增加（不影响主大陆连续性）
	var ocean_chance = 0.12 + clamp((dist - 40.0) / 300.0, 0.0, 0.15)
	
	# 细节噪声让水域边缘不规则
	var detail = _noise_detail.get_noise_2d(x, z) * 0.08
	
	if ocean_noise + detail < -ocean_chance * 2.0:
		return "ocean"
	
	# ---- 群系选择（同原有逻辑） ----
	var n1 = _noise_biome.get_noise_2d(x * 0.5, z * 0.5)
	var n2 = _noise_biome.get_noise_2d(x * 1.2 + 100.0, z * 1.2 + 200.0)
	var combined = n1 * 0.7 + n2 * 0.3
	var biome_index = int((combined + 1.0) * 4.0)
	
	var available: Array[String]
	
	if dist < 50.0:
		available = ["bamboo_forest", "maple_forest", "wind_plains", "peach_blossom"]
	elif dist < 90.0:
		available = ["maple_forest", "snow_peak", "swamp", "peach_blossom", "wind_plains"]
	elif dist < 150.0:
		available = ["snow_peak", "swamp", "volcano", "stellar_desert", "wind_plains"]
	else:
		available = ["volcano", "stellar_desert", "thunder_plains"]
	
	return available[biome_index % available.size()]
