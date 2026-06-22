extends Node
## 昼夜循环系统 — 时间流动 + 光照/天空/氛围渐变
##
## 用法：挂载到 World 节点
## 影响：DirectionalLight 角度、Sky 颜色、雾效、环境光

class_name DayNightCycle

# ==================== 时间参数 ====================
@export var full_day_duration: float = 600.0  # 一整天现实秒数（10分钟=一天）
@export var start_hour: float = 8.0          # 初始时间（8:00 天亮）
@export var time_scale: float = 1.0          # 时间流速倍率

# 内部状态
var current_hour: float = 8.0                # 当前时间 0~24
var day_count: int = 1                       # 天数

# 引用
@onready var sun: DirectionalLight3D = get_tree().get_first_node_in_group("sun")
@onready var world_env: WorldEnvironment = get_tree().get_first_node_in_group("world_environment")

# ==================== 时间事件信号 ====================
signal sunrise                     # 日出 (5:00)
signal sunset                      # 日落 (18:00)
signal midnight                    # 子时 (0:00)
signal time_changed(hour: float)   # 每刻变化

func _ready() -> void:
	current_hour = start_hour
	
	# 自动搜索 sun 和 env（如果没手动赋值）
	if not sun:
		sun = get_tree().get_first_node_in_group("sun")
	if not world_env:
		world_env = get_tree().get_first_node_in_group("world_environment")
	
	_update_scene()

func _process(delta: float) -> void:
	# 时间流逝
	var delta_hour = (delta * time_scale) / full_day_length() * 24.0
	current_hour = fmod(current_hour + delta_hour, 24.0)
	
	# 天计数
	if current_hour < delta_hour:
		day_count += 1
	
	# 触发事件
	_check_time_events()
	
	# 更新场景
	_update_scene()

# ==================== 场景更新 ====================

func _update_scene() -> void:
	if not sun:
		return
	
	# 1. 太阳角度：6点=地平线，12点=天顶，18点=地平线另一侧
	var sun_angle = _hour_to_sun_angle(current_hour)
	sun.rotation_degrees.x = sun_angle
	
	# 2. 光照强度 + 颜色
	var day_factor = _day_factor(current_hour)  # 0=黑夜 ~ 1=正午
	sun.light_energy = lerpf(0.05, 1.2, day_factor)
	
	var warm = Color(1.0, 0.85, 0.6)   # 黄昏暖色
	var cool = Color(0.9, 0.95, 1.0)   # 正午冷色
	var night = Color(0.1, 0.1, 0.3)   # 深夜蓝色
	sun.light_color = _blend_time_colors(warm, cool, night, current_hour)
	
	# 3. 天空颜色（如果有 WorldEnvironment）
	if world_env and world_env.environment:
		var env = world_env.environment
		
		# 雾颜色
		var fog_day = Color(0.7, 0.75, 0.8)
		var fog_night = Color(0.05, 0.05, 0.1)
		env.fog_color = fog_night.lerp(fog_day, day_factor)
		env.fog_density = lerpf(0.005, 0.02, 1.0 - day_factor * 0.8)
		
		# 环境光
		var amb_day = Color(0.4, 0.45, 0.5)
		var amb_night = Color(0.02, 0.02, 0.05)
		env.ambient_light_color = amb_night.lerp(amb_day, day_factor)

# ==================== 辅助 ====================

func _hour_to_sun_angle(hour: float) -> float:
	# 6点=0度(地平线)，12点=90度(头顶)，18点=180度
	return (hour - 6.0) / 12.0 * 180.0

func _day_factor(hour: float) -> float:
	# 返回 0.0(深夜) ~ 1.0(正午)
	if hour < 5.0 or hour >= 19.0:
		return 0.0
	elif hour < 7.0:
		return (hour - 5.0) / 2.0  # 5~7 渐亮
	elif hour < 17.0:
		return 1.0                  # 7~17 白天
	else:
		return 1.0 - (hour - 17.0) / 2.0  # 17~19 渐暗

func _blend_time_colors(warm: Color, cool: Color, night: Color, hour: float) -> Color:
	if hour < 5.0 or hour >= 20.0:
		return night
	elif hour < 7.0:
		return night.lerp(warm, (hour - 5.0) / 2.0)    # 晨光暖色
	elif hour < 9.0:
		return warm.lerp(cool, (hour - 7.0) / 2.0)     # 变冷
	elif hour < 16.0:
		return cool                                      # 正午
	elif hour < 18.0:
		return cool.lerp(warm, (hour - 16.0) / 2.0)    # 黄昏暖色
	else:
		return warm.lerp(night, (hour - 18.0) / 2.0)   # 入夜

func full_day_length() -> float:
	return full_day_duration

func _check_time_events() -> void:
	var prev = current_hour - (get_process_delta_time() * time_scale) / full_day_length() * 24.0
	if current_hour >= 5.0 and prev < 5.0:
		sunrise.emit()
	elif current_hour >= 18.0 and prev < 18.0:
		sunset.emit()
	elif current_hour >= 0.0 and prev >= 23.5:
		midnight.emit()
	
	time_changed.emit(current_hour)

# ==================== 公共接口 ====================

func get_time_string() -> String:
	var h = int(current_hour)
	var m = int((current_hour - h) * 60)
	return "%02d:%02d" % [h, m]

func get_day_name() -> String:
	var names = ["子时", "丑时", "寅时", "卯时", "辰时", "巳时",
				 "午时", "未时", "申时", "酉时", "戌时", "亥时"]
	return names[int(current_hour / 2) % 12]

func is_night() -> bool:
	return current_hour < 5.0 or current_hour >= 19.0
