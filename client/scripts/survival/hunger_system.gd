extends Node
## 饥饿系统 — 凡人需要吃饭，修仙者靠辟谷
##
## 饥荒式生存压力核心：
##   - 随时间/活动消耗饥饿值
##   - 饥饿归零 → 扣血（虚弱）
##   - 吃东西恢复饥饿
##   - 辟谷功法降低消耗速度，大成完全辟谷

class_name HungerSystem

signal hunger_changed(current: float, max_hunger: float)
signal starvation_started()     # 饥饿归零开始扣血
signal starvation_ended()       # 吃了东西解除

# ==================== 基础配置 ====================
const BASE_HUNGER_MAX: float = 100.0
const BASE_DRAIN_PER_SEC: float = 0.8      # 凡人每秒钟消耗
const STARVATION_DAMAGE_PER_SEC: float = 3.0  # 饥饿扣血速度
const HEAVY_ACTIVITY_MULT: float = 2.5      # 战斗/飞行时消耗加倍

# ==================== 状态 ====================
var current_hunger: float = BASE_HUNGER_MAX
var max_hunger: float = BASE_HUNGER_MAX

# 辟谷效果 (0.0 = 凡人, 1.0 = 完全辟谷)
var fasting_level: float = 0.0

var is_starving: bool = false
var _starvation_timer: float = 0.0

# ==================== 活动追踪 ====================
enum Activity { IDLE, WALK, SPRINT, FLY, FIGHT }
var _current_activity: int = Activity.IDLE
var _activity_timer: float = 0.0

func _ready() -> void:
	name = "HungerSystem"
	current_hunger = max_hunger

func _process(delta: float) -> void:
	# 辟谷 >= 1.0 不消耗任何饥饿
	if fasting_level >= 1.0:
		return
	
	# 计算实际消耗速度
	var drain = _calc_drain_rate(delta)
	
	# 应用辟谷减免
	var effective_drain = drain * (1.0 - fasting_level)
	
	current_hunger = max(0.0, current_hunger - effective_drain)
	
	# 饥饿归零 → 扣血
	if current_hunger <= 0.0:
		if not is_starving:
			is_starving = true
			starvation_started.emit()
	else:
		if is_starving:
			is_starving = false
			starvation_ended.emit()
	
	hunger_changed.emit(current_hunger, max_hunger)

# ==================== 消耗计算 ====================

func _calc_drain_rate(delta: float) -> float:
	match _current_activity:
		Activity.IDLE:
			return BASE_DRAIN_PER_SEC * delta * 0.5
		Activity.WALK:
			return BASE_DRAIN_PER_SEC * delta
		Activity.SPRINT:
			return BASE_DRAIN_PER_SEC * delta * 1.8
		Activity.FLY:
			return BASE_DRAIN_PER_SEC * delta * HEAVY_ACTIVITY_MULT
		Activity.FIGHT:
			return BASE_DRAIN_PER_SEC * delta * HEAVY_ACTIVITY_MULT
		_:
			return BASE_DRAIN_PER_SEC * delta

# ==================== 公共接口 ====================

## 吃东西恢复饥饿
func eat(amount: float) -> void:
	current_hunger = min(max_hunger, current_hunger + amount)
	hunger_changed.emit(current_hunger, max_hunger)

## 设置当前活动（影响消耗速度）
func set_activity(activity: int) -> void:
	_current_activity = activity

## 设置辟谷等级 (0.0~1.0)
func set_fasting_level(level: float) -> void:
	fasting_level = clamp(level, 0.0, 1.0)

## 获取饥饿值百分比 (0.0 ~ 1.0)
func get_hunger_ratio() -> float:
	return current_hunger / max_hunger if max_hunger > 0 else 0.0

## 获取当前饥饿消耗效率文本
func get_drain_description() -> String:
	if fasting_level >= 1.0:
		return "辟谷大成，不食五谷"
	elif fasting_level >= 0.8:
		return "仅需少量灵气"
	elif fasting_level >= 0.5:
		return "半辟谷状态"
	elif fasting_level >= 0.2:
		return "初窥辟谷"
	else:
		return "凡人食量"

## 获取饥饿状态文本
func get_hunger_status() -> String:
	var ratio = get_hunger_ratio()
	if ratio <= 0:
		return "饥饿濒死"
	elif ratio < 0.2:
		return "极度饥饿"
	elif ratio < 0.4:
		return "很饿"
	elif ratio < 0.6:
		return "有点饿"
	elif ratio < 0.8:
		return "微饿"
	else:
		return "饱食"

# ==================== 存档 ====================

func get_save_data() -> Dictionary:
	return {
		"current_hunger": current_hunger,
		"max_hunger": max_hunger,
		"fasting_level": fasting_level,
	}

func load_save_data(data: Dictionary) -> void:
	current_hunger = data.get("current_hunger") or BASE_HUNGER_MAX
	max_hunger = data.get("max_hunger") or BASE_HUNGER_MAX
	fasting_level = data.get("fasting_level") or 0.0
