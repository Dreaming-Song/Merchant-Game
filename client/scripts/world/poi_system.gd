extends Node
## 地标/兴趣点系统 — 世界中的可探索地点
##
## 功能：
## - 注册地标（宗门、遗迹、秘境入口等）
## - 玩家接近时触发发现/提示
## - 记录已发现/未发现状态
## - 小地图标记（预留接口）

class_name POISystem

# ==================== 地标数据结构 ====================
struct POIData:
	var id: String               # 唯一标识
	var name: String             # 显示名称
	var description: String      # 描述文本
	var position: Vector3        # 世界坐标
	var type: POIType            # 类型
	var discover_radius: float   # 发现半径
	var discovered: bool         # 是否已发现
	var icon_path: String        # 图标路径

enum POIType {
	TEMPLE,      # 宗门/道观
	RUINS,       # 上古遗迹
	SECRET,      # 秘境入口
	VILLAGE,     # 村落
	SPRING,      # 灵泉
	BOSS,        # BOSS区域
	LANDMARK,    # 自然奇观
	PORTAL,      # 传送阵
}

# ==================== 信号 ====================
signal poi_discovered(poi_id: String, poi_name: String)
signal poi_approached(poi_id: String, distance: float)

# 存储
var _all_pois: Dictionary = {}       # id → POIData
var _discovered_pois: Array[String] = []
var _nearest_poi: String = ""

@export var player_ref: Node3D
@export var discover_check_interval: float = 1.0  # 每1秒检测一次

func _ready() -> void:
	_register_default_pois()
	
	var timer = Timer.new()
	timer.wait_time = discover_check_interval
	timer.timeout.connect(_check_discovery)
	add_child(timer)
	timer.start()

# ==================== 默认地标注册 ====================

func _register_default_pois() -> void:
	# 新手区域
	register_poi("bamboo_village", "青竹村", "竹林中的宁静村落，修行者的起点",
		Vector3(0, 0, 0), POIType.VILLAGE, 20.0)
	
	register_poi("spirit_spring", "灵泉", "清澈的灵泉，饮用可恢复灵力",
		Vector3(15, 0, -10), POIType.SPRING, 10.0)
	
	# 中层区域
	register_poi("maple_temple", "落霞观", "枫林深处的古老道观，传闻有高人隐居",
		Vector3(-40, 0, 30), POIType.TEMPLE, 25.0)
	
	register_poi("ancient_ruins", "上古遗迹", "残破的石阵中隐藏着失传的功法",
		Vector3(50, 0, -20), POIType.RUINS, 30.0)
	
	register_poi("swamp_gate", "沼泽秘境入口", "幽暗沼泽深处，通往未知秘境的门户",
		Vector3(-60, 0, -50), POIType.SECRET, 20.0)
	
	# 高级区域
	register_poi("snow_peak_palace", "寒雪宫", "雪山之巅的仙宫，唯有强者可至",
		Vector3(20, 0, 80), POIType.TEMPLE, 35.0)
	
	register_poi("volcano_core", "灵焰火山口", "地心灵焰涌动之地，传闻有神兽守护",
		Vector3(-80, 0, 60), POIType.BOSS, 40.0)
	
	register_poi("celestial_portal", "天穹传送阵", "上古传送阵，可通往未知领域",
		Vector3(100, 0, -80), POIType.PORTAL, 25.0)
	
	# 隐藏
	register_poi("hidden_cave", "隐龙窟", "瀑布后的隐秘洞穴，藏有绝世珍宝",
		Vector3(30, 0, -45), POIType.SECRET, 8.0)
	
	print("🏛️ 已注册 %d 个地标" % _all_pois.size())

# ==================== 公共接口 ====================

func register_poi(id: String, name: String, desc: String, 
				  pos: Vector3, type: POIType, radius: float) -> void:
	var poi = POIData.new()
	poi.id = id
	poi.name = name
	poi.description = desc
	poi.position = pos
	poi.type = type
	poi.discover_radius = radius
	poi.discovered = false
	poi.icon_path = "res://assets/icons/poi_%s.png" % POIType.keys()[type].to_lower()
	_all_pois[id] = poi

## 获取已发现的地标列表
func get_discovered_pois() -> Array[POIData]:
	var result: Array[POIData] = []
	for poi_id in _discovered_pois:
		result.append(_all_pois[poi_id])
	return result

## 获取最近的地标信息（用于 HUD 提示）
func get_nearest_poi_info() -> Dictionary:
	if _nearest_poi.is_empty() or not _all_pois.has(_nearest_poi):
		return {}
	var poi = _all_pois[_nearest_poi]
	return {
		"id": poi.id,
		"name": poi.name,
		"description": poi.description,
		"distance": _distance_to(poi.position),
		"discovered": poi.discovered,
	}

## 手动标记地标为已发现
func mark_discovered(poi_id: String) -> void:
	if _all_pois.has(poi_id) and not _all_pois[poi_id].discovered:
		_all_pois[poi_id].discovered = true
		_discovered_pois.append(poi_id)
		poi_discovered.emit(poi_id, _all_pois[poi_id].name)

## 获取地标总数/已发现数
func get_progress() -> Dictionary:
	return {
		"total": _all_pois.size(),
		"discovered": _discovered_pois.size(),
	}

func get_all_pois() -> Dictionary:
	return _all_pois.duplicate()

# ==================== 内部检测 ====================

func _check_discovery() -> void:
	if not player_ref:
		return
	
	var nearest_id = ""
	var nearest_dist = INF
	
	for poi_id in _all_pois.keys():
		var poi = _all_pois[poi_id]
		var dist = _distance_to(poi.position)
		
		# 更新最近地标
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_id = poi_id
		
		# 检测是否进入发现范围
		if not poi.discovered and dist < poi.discover_radius:
			mark_discovered(poi_id)
			print("🗺️ 发现新地标: %s （距离 %.1f）" % [poi.name, dist])
	
	# 更新最近地标
	if nearest_id != _nearest_poi:
		_nearest_poi = nearest_id
		if nearest_id:
			poi_approached.emit(nearest_id, nearest_dist)

func _distance_to(pos: Vector3) -> float:
	if not player_ref:
		return INF
	return player_ref.global_position.distance_to(pos)
