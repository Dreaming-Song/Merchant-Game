extends CanvasLayer
## ⚡ 雷劫总管理器 — 管理三阶段渡劫全流程
##
## 触发流程：
##   突破检测 → 创建管理器 → 阶段1:天雷闪避 → 
##   阶段2:五行抗雷 → 阶段3:心魔幻境 → 结算 → 突破成功/失败
##
## 挂载方式：由 realm_system 在需要渡劫时动态创建

class_name TribulationManager

# ==================== 外部依赖 ====================
const RealmSystem = preload("res://scripts/cultivation/realm_system.gd")

# ==================== 信号 ====================
signal tribulation_started(realm_level: int)
signal tribulation_phase_changed(phase: int, phase_name: String)
signal tribulation_completed(success: bool, rating: String, rewards: Dictionary)
signal tribulation_failed(reason: String)

# ==================== 常量 ====================
const PHASE_NAMES = {
	1: "⚡ 天雷闪避",
	2: "🛡️ 五行抗雷",
	3: "👻 心魔幻境",
}

# 境界对应的雷劫配置
# [总波数, 同时落雷数, 预警时间(秒), 伤害]
const REALM_TRIBULATION_CONFIG = {
	3: {  # 金丹→元婴 (一九→三九)
		"waves": 3, "max_strikes": 2, "warning_time": 1.2, 
		"base_damage": 30, "element_rounds": 2, "demon_hp_mult": 1.0,
		"rating_thresholds": {"tian": 90, "di": 60, "ren": 30},
	},
	4: {  # 元婴→化神 (三九→六九)
		"waves": 6, "max_strikes": 3, "warning_time": 1.0,
		"base_damage": 50, "element_rounds": 3, "demon_hp_mult": 1.3,
		"rating_thresholds": {"tian": 85, "di": 55, "ren": 25},
	},
	5: {  # 化神→大乘 (六九→九九)
		"waves": 9, "max_strikes": 4, "warning_time": 0.8,
		"base_damage": 80, "element_rounds": 4, "demon_hp_mult": 1.6,
		"rating_thresholds": {"tian": 80, "di": 50, "ren": 20},
	},
	7: {  # 渡劫→飞升 (九九→灭世)
		"waves": 12, "max_strikes": 5, "warning_time": 0.6,
		"base_damage": 120, "element_rounds": 5, "demon_hp_mult": 2.0,
		"rating_thresholds": {"tian": 75, "di": 45, "ren": 15},
	},
}

# ==================== 状态 ====================
var _phase_scores: Dictionary = {}  # phase -> score% (0-100)
var _current_phase: int = 1
var _current_realm: int = 0
var _target_realm: int = 0
var _target_realm_name: String = ""
var _player: Node = null
var _config: Dictionary = {}
var _is_running: bool = false
var _rating: String = "ren"

# ==================== 引用 ====================
var _phase_dodge: Node = null
var _phase_element: Node = null
var _phase_demon: Node = null
var _tribulation_hud: Node = null

# ==================== 初始化 ====================

func _init(player: Node, current_realm: int, target_realm: int, target_name: String) -> void:
	_player = player
	_current_realm = current_realm
	_target_realm = target_realm
	_target_realm_name = target_name
	_config = _get_config_for_realm(current_realm)
	name = "TribulationManager"

func _ready() -> void:
	# CanvasLayer 默认不阻隔鼠标事件，无需设置 mouse_filter
	_phase_scores = {1: 0, 2: 0, 3: 0}
	_is_running = true
	
	# 创建HUD
	_tribulation_hud = preload("res://scripts/effects/tribulation_hud.gd").new(self)
	add_child(_tribulation_hud)
	
	# 通知开始
	tribulation_started.emit(_current_realm)
	print("""
╔══════════════════════════════════╗
║    🌩️ 天劫降临！                     ║
║    %s → %s             ║
║   渡劫开始！                         ║
╚══════════════════════════════════╝
	""" % [RealmSystem.get_realm_data(_current_realm).name, _target_realm_name])

# ==================== 配置获取 ====================

static func _get_config_for_realm(realm: int) -> Dictionary:
	"""根据当前境界获取雷劫配置"""
	# 金丹(3)及以上触发
	var config = REALM_TRIBULATION_CONFIG.get(realm, REALM_TRIBULATION_CONFIG[3])
	return config.duplicate()

static func needs_tribulation(realm: int) -> bool:
	"""该境界突破是否需要渡劫"""
	return realm >= 3  # 金丹及以上

# ==================== 阶段流程控制 ====================

func start_tribulation() -> void:
	"""从阶段1开始"""
	call_deferred("_start_phase_1")

func _start_phase_1() -> void:
	"""⚡ 天雷闪避"""
	_current_phase = 1
	tribulation_phase_changed.emit(1, PHASE_NAMES[1])
	
	_phase_dodge = preload("res://scripts/effects/tribulation_phase_dodge.gd").new(self, _player, _config)
	add_child(_phase_dodge)
	
	_phase_dodge.phase_completed.connect(_on_phase_1_completed)
	_phase_dodge.phase_failed.connect(_on_phase_failed.bind("天雷闪避失败"))
	_phase_dodge.start()

func _on_phase_1_completed(score: float) -> void:
	"""阶段1完成"""
	_phase_scores[1] = score
	
	if _phase_dodge:
		_phase_dodge.queue_free()
		_phase_dodge = null
	
	# 简单过渡 → 进入阶段2
	await get_tree().create_timer(1.0).timeout
	_start_phase_2()

func _start_phase_2() -> void:
	"""🛡️ 五行抗雷"""
	_current_phase = 2
	tribulation_phase_changed.emit(2, PHASE_NAMES[2])
	
	_phase_element = preload("res://scripts/effects/tribulation_phase_element.gd").new(self, _player, _config)
	add_child(_phase_element)
	
	_phase_element.phase_completed.connect(_on_phase_2_completed)
	_phase_element.phase_failed.connect(_on_phase_failed.bind("五行抗雷失败"))
	_phase_element.start()

func _on_phase_2_completed(score: float) -> void:
	"""阶段2完成"""
	_phase_scores[2] = score
	
	if _phase_element:
		_phase_element.queue_free()
		_phase_element = null
	
	await get_tree().create_timer(1.0).timeout
	_start_phase_3()

func _start_phase_3() -> void:
	"""👻 心魔幻境 — 根据前两阶段失误动态调整心魔强度"""
	_current_phase = 3
	tribulation_phase_changed.emit(3, PHASE_NAMES[3])
	
	# 计算前两阶段的"失误指数"：0.0=完美，1.0=全崩
	var phase1_score = _phase_scores.get(1, 100.0)
	var phase2_score = _phase_scores.get(2, 100.0)
	var avg_score = (phase1_score + phase2_score) / 2.0
	# 分数越低 => 失误越多 => 心魔越强
	# 平均分100→心魔倍率0.8x, 平均分0→心魔倍率2.5x
	var weakness_factor = 0.8 + (1.0 - avg_score / 100.0) * 1.7
	weakness_factor = clamp(weakness_factor, 0.8, 2.5)
	
	# 将动态系数合并到config
	var demon_config = _config.duplicate()
	demon_config["demon_hp_mult"] = _config.get("demon_hp_mult") or 1.0 * weakness_factor
	demon_config["demon_attack_speed"] = 1.0 + (weakness_factor - 0.8) * 0.5  # 攻击越快
	demon_config["weakness_factor"] = weakness_factor
	
	print("👻 心魔强度计算: 前两阶段均分=%.0f%%, 心魔倍率=%.2f" % [avg_score, weakness_factor])
	
	_phase_demon = preload("res://scripts/effects/tribulation_phase_demon.gd").new(self, _player, demon_config)
	add_child(_phase_demon)
	
	_phase_demon.phase_completed.connect(_on_phase_3_completed)
	_phase_demon.phase_failed.connect(_on_phase_failed.bind("心魔未破"))
	_phase_demon.start()

func _on_phase_3_completed(score: float) -> void:
	"""阶段3完成"""
	_phase_scores[3] = score
	
	if _phase_demon:
		_phase_demon.queue_free()
		_phase_demon = null
	
	_on_all_phases_completed()

# ==================== 结算 ====================

func _on_all_phases_completed() -> void:
	"""三阶段全部完成 → 结算"""
	var overall = (_phase_scores[1] + _phase_scores[2] + _phase_scores[3]) / 3.0
	_rating = _calculate_rating(overall)
	
	var rewards = _calculate_rewards(_rating)
	
	_is_running = false
	tribulation_completed.emit(true, _rating, rewards)
	
	# 显示结算界面
	_show_result_screen(true, _rating, rewards)

func _on_phase_failed(reason: String) -> void:
	"""某阶段失败 → 渡劫失败"""
	_is_running = false
	tribulation_failed.emit(reason)
	_show_result_screen(false, "failed", {})
	
	# 清理所有阶段
	for phase in [_phase_dodge, _phase_element, _phase_demon]:
		if phase:
			phase.queue_free()

func _calculate_rating(score: float) -> String:
	"""计算渡劫评价"""
	var thresholds = _config.get("rating_thresholds", {"tian": 90, "di": 60, "ren": 30})
	if score >= thresholds["tian"]: return "tian"
	elif score >= thresholds["di"]: return "di"
	else: return "ren"

func _calculate_rewards(rating: String) -> Dictionary:
	"""根据评价计算奖励"""
	var base = {
		"hp_bonus": 100,
		"attack_bonus": 5,
		"speed_bonus": 0.02,
		"xp_bonus": 500,
	}
	
	match rating:
		"tian":
			base["hp_bonus"] = 300
			base["attack_bonus"] = 20
			base["speed_bonus"] = 0.08
			base["xp_bonus"] = 2000
			base["title"] = "天选之人"
		"di":
			base["hp_bonus"] = 150
			base["attack_bonus"] = 10
			base["speed_bonus"] = 0.04
			base["xp_bonus"] = 1000
		"ren":
			base["hp_bonus"] = 50
			base["attack_bonus"] = 3
			base["speed_bonus"] = 0.01
			base["xp_bonus"] = 300
	
	return base

# ==================== 结算界面 ====================

func _show_result_screen(success: bool, rating: String, rewards: Dictionary) -> void:
	"""显示渡劫结果"""
	var result = preload("res://scripts/effects/tribulation_result_screen.gd").new(success, rating, rewards, _phase_scores, _target_realm_name)
	add_child(result)
	result.result_dismissed.connect(_on_result_dismissed)

func _on_result_dismissed(accepted: bool) -> void:
	"""玩家关掉结算界面"""
	if accepted:
		# 通知 realm_system 突破成功
		var realm_sys = get_node("/root/GameManager/RealmSystem") if has_node("/root/GameManager/RealmSystem") else null
		if realm_sys:
			realm_sys.force_breakthrough(_target_realm)
		
		# 应用奖励
		_apply_rewards()
	
	# 清理自身
	queue_free()

func _apply_rewards() -> void:
	"""将奖励应用到玩家"""
	if not _player or not is_instance_valid(_player):
		return
	
	var rewards = _calculate_rewards(_rating)
	
	if _player.has_method("modify_max_hp"):
		_player.modify_max_hp(rewards["hp_bonus"])
	if _player.has_method("modify_attack"):
		_player.modify_attack(rewards["attack_bonus"])
	if _player.has_method("modify_speed"):
		_player.modify_speed(rewards["speed_bonus"])
	
	print("🎉 渡劫奖励已应用! HP+%d ATK+%d SPD+%.0f%%" % [rewards["hp_bonus"], rewards["attack_bonus"], rewards["speed_bonus"]*100])

# ==================== 查询接口 ====================

func get_current_phase() -> int:
	return _current_phase

func get_config() -> Dictionary:
	return _config

func get_score(phase: int) -> float:
	return _phase_scores.get(phase, 0.0)
