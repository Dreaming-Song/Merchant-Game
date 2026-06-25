extends Node
## 🏛️ 地标/兴趣点系统 — 全群系可探索地点
##
## 功能：
## - 注册地标（宗门、遗迹、秘境入口等）
## - 玩家接近时触发发现/提示
## - 每个群系至少2~3个特色地标
## - 记录已发现/未发现状态
## - 小地图标记（预留接口）

class_name POISystem

# ==================== 地标数据结构 ====================
class POIData:
	var id: String
	var name: String
	var description: String
	var position: Vector3
	var type: POIType
	var discover_radius: float
	var discovered: bool
	var icon_path: String

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

var _all_pois: Dictionary = {}
var _discovered_pois: Array[String] = []
var _nearest_poi: String = ""

@export var player_ref: Node3D
@export var discover_check_interval: float = 1.0

func _ready() -> void:
	_register_all_pois()
	
	var timer = Timer.new()
	timer.wait_time = discover_check_interval
	timer.timeout.connect(_check_discovery)
	add_child(timer)
	timer.start()

# ==================== 全群系地标注册 ====================

func _register_all_pois() -> void:
	# ===== 🎋 青翠竹林 =====
	register_poi("bamboo_village", "青竹村", "竹林中的宁静村落，修行者的起点",
		Vector3(0, 0, 0), POIType.VILLAGE, 20.0)
	register_poi("spirit_spring", "灵泉", "清澈的灵泉，饮用可恢复灵力",
		Vector3(15, 0, -10), POIType.SPRING, 10.0)
	register_poi("bamboo_grove_altar", "竹海祭坛", "竹林深处的古老祭坛，月圆之夜会有异象",
		Vector3(25, 0, 15), POIType.LANDMARK, 15.0)
	register_poi("bamboo_maze", "翠竹迷宫", "天然形成的竹林迷宫，内有珍稀灵草",
		Vector3(-15, 0, 25), POIType.SECRET, 12.0)
	
	# ===== 🍁 落霞枫林 =====
	register_poi("maple_temple", "落霞观", "枫林深处的古老道观，传闻有高人隐居",
		Vector3(-40, 0, 30), POIType.TEMPLE, 25.0)
	register_poi("maple_creek", "枫溪", "枫叶飘落在溪水上，景色美不胜收",
		Vector3(-50, 0, 15), POIType.LANDMARK, 10.0)
	register_poi("red_leaves_pavilion", "红叶亭", "建于枫林最高处的观景亭，可俯瞰整片枫海",
		Vector3(-35, 3, 35), POIType.LANDMARK, 15.0)
	
	# ===== ❄️ 寒雪山巅 =====
	register_poi("snow_peak_palace", "寒雪宫", "雪山之巅的仙宫，唯有强者可至",
		Vector3(20, 0, 80), POIType.TEMPLE, 35.0)
	register_poi("frozen_lake", "冰封湖", "万年不化的冰湖，湖面如镜映照天光",
		Vector3(35, 0, 70), POIType.LANDMARK, 20.0)
	register_poi("ice_cave", "冰晶洞穴", "深藏于冰川下的蓝色洞穴，冰晶闪耀",
		Vector3(10, 0, 95), POIType.SECRET, 15.0)
	
	# ===== 🪷 幽暗沼泽 =====
	register_poi("swamp_gate", "沼泽秘境入口", "幽暗沼泽深处，通往未知秘境的门户",
		Vector3(-60, 0, -50), POIType.SECRET, 20.0)
	register_poi("willow_spring", "腐泉", "墨绿色的泉水，带有剧毒但也是炼药珍材",
		Vector3(-70, 0, -40), POIType.SPRING, 10.0)
	register_poi("ancient_tower", "沼泽古塔", "半沉于沼泽中的古塔，塔顶有微光不灭",
		Vector3(-50, 0, -60), POIType.RUINS, 25.0)
	
	# ===== 🌋 灵焰火山 =====
	register_poi("volcano_core", "灵焰火山口", "地心灵焰涌动之地，传闻有神兽守护",
		Vector3(-80, 0, 60), POIType.BOSS, 40.0)
	register_poi("lava_falls", "熔岩瀑布", "赤红的岩浆从峭壁倾泻而下，壮观至极",
		Vector3(-90, 3, 50), POIType.LANDMARK, 15.0)
	register_poi("obsidian_temple", "黑曜神殿", "完全由黑曜石建成的上古神殿，刀枪不入",
		Vector3(-70, 0, 70), POIType.TEMPLE, 30.0)
	
	# ===== 🌸 桃花源 🆕 =====
	register_poi("peach_village", "桃源村", "隐于桃花林中的村落，村民与世无争",
		Vector3(60, 0, -30), POIType.VILLAGE, 20.0)
	register_poi("peach_waterfall", "桃花瀑布", "瀑布从花海中倾泻，水雾中带着桃花香",
		Vector3(70, 0, -40), POIType.LANDMARK, 15.0)
	register_poi("spirit_peach_garden", "灵桃园", "种植着百年灵桃的仙家果园",
		Vector3(50, 0, -25), POIType.SPRING, 12.0)
	
	# ===== ✨ 星辰沙漠 🆕 =====
	register_poi("star_oasis", "星辉绿洲", "沙漠中的奇迹绿洲，夜晚水面映照漫天星辰",
		Vector3(100, 0, 60), POIType.SPRING, 20.0)
	register_poi("ancient_observatory", "古星辰台", "远古观星者留下的天文台，刻满星图",
		Vector3(120, 0, 50), POIType.RUINS, 25.0)
	register_poi("sand_gate", "沙渊之门", "沙漠深处的巨大石门，门后或许通往异界",
		Vector3(90, 0, 80), POIType.PORTAL, 20.0)
	register_poi("star_fragment_crater", "星辰陨坑", "远古星辰坠落形成的巨坑，充满奇异能量",
		Vector3(110, 0, 70), POIType.LANDMARK, 30.0)
	
	# ===== ⚡ 雷暴平原 🆕 =====
	register_poi("thunder_peak", "雷霆峰", "雷暴最密集的山峰，闪电几乎不间断劈落",
		Vector3(-100, 5, -70), POIType.LANDMARK, 25.0)
	register_poi("lightning_temple", "雷音寺", "建在雷暴中心的寺庙，以避雷阵法闻名",
		Vector3(-110, 0, -80), POIType.TEMPLE, 30.0)
	register_poi("arena_of_storms", "风暴竞技场", "上古雷修留下的试炼场，以天雷淬体",
		Vector3(-90, 0, -65), POIType.BOSS, 20.0)
	
	# ===== 五行神兽区域 =====
	register_poi("boss_青龙", "东方木德·青龙", "青翠竹林中的远古神兽",
		Vector3(15, 0, 20), POIType.BOSS, 40.0)
	register_poi("boss_白虎", "西方金德·白虎", "寒雪山巅的万兽之主",
		Vector3(20, 0, 85), POIType.BOSS, 40.0)
	register_poi("boss_朱雀", "南方火德·朱雀", "灵焰火山中的涅槃圣禽",
		Vector3(-80, 5, 60), POIType.BOSS, 40.0)
	register_poi("boss_玄武", "北方水德·玄武", "幽暗沼泽中的远古巨兽",
		Vector3(-60, 0, -50), POIType.BOSS, 40.0)
	register_poi("boss_麒麟", "中央土德·麒麟", "落霞枫林中的祥瑞之兽",
		Vector3(-40, 0, 30), POIType.BOSS, 40.0)
	
	# ===== 海域地标 🌊 =====
	register_poi("sunken_temple", "沉没神殿", "沉入海底的上古神殿，鱼群环绕其中",
		Vector3(45, -3, 40), POIType.RUINS, 25.0)
	register_poi("coral_reef", "珊瑚海", "五光十色的珊瑚群，盛产灵珠",
		Vector3(-30, -2, -35), POIType.LANDMARK, 20.0)
	register_poi("whale_graveyard", "鲸落之渊", "远古灵鲸的葬身之地，灵力浓郁",
		Vector3(80, -5, -20), POIType.SECRET, 30.0)
	register_poi("fishing_village", "渔歌村", "靠海而居的小渔村，以灵鱼为生",
		Vector3(25, 0, 40), POIType.VILLAGE, 15.0)
	
	# ===== 上古传送阵（全局连接） =====
	register_poi("celestial_portal", "天穹传送阵", "上古传送阵，可通往未知领域",
		Vector3(100, 0, -80), POIType.PORTAL, 25.0)
	
	# ===== 隐藏地点 =====
	register_poi("hidden_cave", "隐龙窟", "瀑布后的隐秘洞穴，藏有绝世珍宝",
		Vector3(30, 0, -45), POIType.SECRET, 8.0)
	
	print("🏛️ 已注册 %d 个地标（覆盖全部8个群系）" % _all_pois.size())


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


func get_discovered_pois() -> Array[POIData]:
	var result: Array[POIData] = []
	for poi_id in _discovered_pois:
		result.append(_all_pois[poi_id])
	return result


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


func mark_discovered(poi_id: String) -> void:
	if _all_pois.has(poi_id) and not _all_pois[poi_id].discovered:
		_all_pois[poi_id].discovered = true
		_discovered_pois.append(poi_id)
		poi_discovered.emit(poi_id, _all_pois[poi_id].name)


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
		
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_id = poi_id
		
		if not poi.discovered and dist < poi.discover_radius:
			mark_discovered(poi_id)
			print("🗺️ 发现新地标: %s （距离 %.1f）" % [poi.name, dist])
	
	if nearest_id != _nearest_poi:
		_nearest_poi = nearest_id
		if nearest_id:
			poi_approached.emit(nearest_id, nearest_dist)


func _distance_to(pos: Vector3) -> float:
	if not player_ref:
		return INF
	return player_ref.global_position.distance_to(pos)
