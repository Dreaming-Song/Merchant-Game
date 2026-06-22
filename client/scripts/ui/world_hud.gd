extends CanvasLayer
## 大世界 HUD — 显示当前地貌/时辰/附近地标

class_name WorldHUD

@onready var biome_label: Label = $BiomeLabel
@onready var time_label: Label = $TimeLabel
@onready var poi_label: Label = $POILabel
@onready var compass: Control = $Compass

# 外部引用（由场景注入）
var biome_manager: BiomeManager
var day_night: DayNightCycle
var poi_system: POISystem
var player: Node3D

func _ready() -> void:
	# 找引用
	if not biome_manager:
		biome_manager = get_tree().get_first_node_in_group("biome_manager")
	if not day_night:
		day_night = get_tree().get_first_node_in_group("day_night")
	if not poi_system:
		poi_system = get_tree().get_first_node_in_group("poi_system")
	if not player:
		player = get_tree().get_first_node_in_group("player")

func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	
	# 更新地貌信息
	if biome_manager and player:
		var biome = biome_manager.get_biome_at(player.global_position)
		biome_label.text = "🏔️ %s" % biome.name
		biome_label.modulate = biome.fog_color  # 用地貌颜色染色
	
	# 更新时间信息
	if day_night:
		time_label.text = "⏰ %s (%s) 第%d日" % [
			day_night.get_time_string(),
			day_night.get_day_name(),
			day_night.day_count
		]
	
	# 更新最近地标
	if poi_system:
		var info = poi_system.get_nearest_poi_info()
		if not info.is_empty():
			var icon = "🗺️" if info.discovered else "❓"
			poi_label.text = "%s %s (%.0fm)" % [icon, info.name, info.distance]
		else:
			poi_label.text = ""
