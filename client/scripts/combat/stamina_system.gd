extends Node
## ⚡ 体力系统 — 塞尔达风格体力管理
##
## 体力用于：奔跑、闪避、蓄力攻击、攀爬
## 自动恢复 + 耗尽惩罚（喘息）

class_name StaminaSystem

# ==================== 配置 ====================
const MAX_STAMINA: float = 100.0
const WHEEL_COUNT: int = 5          # 5圈体力（类似塞尔达）
const STAMINA_PER_WHEEL: float = MAX_STAMINA / WHEEL_COUNT

# 消耗配置
const SPRINT_COST_PER_SEC: float = 15.0      # 奔跑每秒
const DODGE_COST: float = 20.0               # 闪避一次
const HEAVY_ATTACK_COST: float = 25.0        # 蓄力重击
const SPIN_ATTACK_COST_PER_SEC: float = 18.0 # 回旋斩每秒
const JUMP_COST: float = 5.0                 # 跳跃

# 恢复配置
const REGEN_RATE: float = 20.0               # 每秒恢复
const REGEN_DELAY: float = 1.2               # 停止消耗后延迟恢复
const EXHAUSTED_REGEN_DELAY: float = 2.5     # 体力耗尽后延迟

# 耗尽惩罚
const EXHAUSTED_SPEED_MULT: float = 0.5      # 耗尽时移速减半
const EXHAUSTED_TIME: float = 1.5            # 喘息时间

# ==================== 状态 ====================
var current_stamina: float = MAX_STAMINA
var is_exhausted: bool = false
var exhausted_timer: float = 0.0

var _regen_timer: float = 0.0
var _last_use_time: float = 0.0

# ==================== 信号 ====================
signal stamina_changed(current: float, max_stamina: float)
signal stamina_exhausted()
signal stamina_recovered()

func _process(delta: float) -> void:
	# 耗尽状态计时
	if is_exhausted:
		exhausted_timer -= delta
		if exhausted_timer <= 0:
			is_exhausted = false
			stamina_recovered.emit()
		return  # 耗尽时不能恢复
	
	# 恢复延迟
	var delay = REGEN_DELAY
	_regen_timer -= delta
	if _regen_timer <= 0:
		current_stamina = min(current_stamina + REGEN_RATE * delta, MAX_STAMINA)
		stamina_changed.emit(current_stamina, MAX_STAMINA)

# ==================== 消耗接口 ====================

func try_consume(amount: float) -> bool:
	"""尝试消耗体力，返回是否成功"""
	if is_exhausted:
		return false
	
	if current_stamina < amount:
		# 体力不够 → 耗尽
		_exhaust()
		return false
	
	current_stamina -= amount
	_regen_timer = REGEN_DELAY
	_last_use_time = Time.get_ticks_msec()
	stamina_changed.emit(current_stamina, MAX_STAMINA)
	return true

func has_stamina(amount: float) -> bool:
	"""检查是否有足够体力（不消耗）"""
	return current_stamina >= amount and not is_exhausted

func get_stamina_ratio() -> float:
	return current_stamina / MAX_STAMINA

func get_wheel_count() -> int:
	return int(ceil(current_stamina / STAMINA_PER_WHEEL))

func reset() -> void:
	current_stamina = MAX_STAMINA
	is_exhausted = false
	exhausted_timer = 0.0
	_regen_timer = 0.0
	stamina_changed.emit(current_stamina, MAX_STAMINA)

# ==================== 内部 ====================

func _exhaust() -> void:
	is_exhausted = true
	exhausted_timer = EXHAUSTED_TIME
	current_stamina = 0
	stamina_changed.emit(current_stamina, MAX_STAMINA)
	stamina_exhausted.emit()
