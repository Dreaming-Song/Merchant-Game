extends Node
## 地貌管理器 — 为世界不同区域赋予视觉和生态特征
##
## 用法：挂载到 World 节点下，根据玩家位置动态切换 biome
## 每个 biome 定义：地面颜色、植被密度、氛围光、背景音乐

class_name BiomeManager

# ==================== 地貌定义 ====================
struct BiomeData:
	var name: String
	var ground_color: Color       # 地面色调
	var fog_color: Color          # 雾气颜色
	var fog_density: float        # 雾浓度 0.0~1.0
	var vegetation_density: float # 植被密度 0.0~1.0
	var ambient_color: Color      # 环境光颜色
	var music_track: String       # 背景音乐资源路径
	var spawn_pool: Array[String] # 该地貌可生成的资源列表

var _biomes: Dictionary = {}

func _ready() -> void:
	_register_biomes()

func _register_biomes() -> void:
	# ----- 青翠竹林 🎋 -----
	_biomes["bamboo_forest"] = BiomeData.new(
		"青翠竹林",
		Color(0.25, 0.45, 0.20),   # 深绿地面
		Color(0.65, 0.75, 0.55),   # 淡绿雾
		0.15,
		0.7,
		Color(0.50, 0.55, 0.40),
		"res://assets/audio/bgm_bamboo.ogg",
		["herb_spirit_grass", "herb_jade_flower", "ore_copper", "chest_common"]
	)
	
	# ----- 落霞枫林 🍁 -----
	_biomes["maple_forest"] = BiomeData.new(
		"落霞枫林",
		Color(0.55, 0.25, 0.15),   # 红褐地面
		Color(0.80, 0.50, 0.30),   # 橙红雾
		0.12,
		0.6,
		Color(0.70, 0.35, 0.20),
		"res://assets/audio/bgm_maple.ogg",
		["herb_flame_flower", "ore_iron", "chest_rare", "encounter_wild"]
	)
	
	# ----- 寒雪山巅 ❄️ -----
	_biomes["snow_peak"] = BiomeData.new(
		"寒雪山巅",
		Color(0.85, 0.88, 0.92),   # 雪白地面
		Color(0.90, 0.92, 0.95),   # 白雾
		0.25,
		0.1,
		Color(0.75, 0.80, 0.90),
		"res://assets/audio/bgm_snow.ogg",
		["herb_ice_lotus", "ore_silver", "chest_legendary"]
	)
	
	# ----- 幽暗沼泽 🪷 -----
	_biomes["swamp"] = BiomeData.new(
		"幽暗沼泽",
		Color(0.20, 0.18, 0.12),   # 深褐地面
		Color(0.30, 0.45, 0.25),   # 绿雾
		0.35,
		0.4,
		Color(0.25, 0.30, 0.20),
		"res://assets/audio/bgm_swamp.ogg",
		["herb_toadstool", "herb_ghost_flower", "ore_ancient", "chest_cursed", "encounter_elite"]
	)
	
	# ----- 灵焰火山 🌋 -----
	_biomes["volcano"] = BiomeData.new(
		"灵焰火山",
		Color(0.35, 0.15, 0.08),   # 焦黑地面
		Color(0.60, 0.25, 0.10),   # 红雾
		0.20,
		0.0,
		Color(0.50, 0.20, 0.10),
		"res://assets/audio/bgm_volcano.ogg",
		["herb_fire_root", "ore_gold", "chest_epic", "encounter_boss"]
	)
	
	print("🌍 已注册 %d 个地貌类型" % _biomes.size())

# ==================== 公共接口 ====================

## 根据世界坐标获取地貌数据
func get_biome_at(world_pos: Vector3) -> BiomeData:
	# 用噪声或区域标记决定地貌，这里用简化版：基于位置划分带状区域
	var biome_name = _sample_biome_map(world_pos.x, world_pos.z)
	return _biomes.get(biome_name, _biomes["bamboo_forest"])

## 获取所有地貌名称列表
func get_biome_names() -> PackedStringArray:
	var names: PackedStringArray
	for key in _biomes.keys():
		names.append(key)
	return names

## 获取当前地貌的植被密度（用于 LOD/实例化控制）
func get_vegetation_density_at(world_pos: Vector3) -> float:
	var biome = get_biome_at(world_pos)
	return biome.vegetation_density

## 获取当前地貌的资源掉落池
func get_spawn_pool_at(world_pos: Vector3) -> Array[String]:
	var biome = get_biome_at(world_pos)
	return biome.spawn_pool

# ==================== 内部逻辑 ====================

## 基于位置的简化地貌采样（可用噪声算法替换）
func _sample_biome_map(x: float, z: float) -> String:
	# 用角度和距离划分区域：以世界原点为中心
	var dist = sqrt(x * x + z * z)
	var angle = atan2(z, x)
	
	# 中心区域：竹林（新手村）
	if dist < 30.0:
		return "bamboo_forest"
	
	# 层状分布：按距离分圈
	if dist < 60.0:
		# 东北方向：枫林
		if angle > -0.5 and angle < 2.0:
			return "maple_forest"
		else:
			return "bamboo_forest"
	
	if dist < 100.0:
		# 西南方向：沼泽
		if angle < -1.0 or angle > 2.5:
			return "swamp"
		else:
			return "maple_forest"
	
	if dist < 150.0:
		# 北方：雪山
		if angle > 0.5 and angle < 2.0:
			return "snow_peak"
		else:
			return "volcano"
	
	# 边缘：火山
	return "volcano"
