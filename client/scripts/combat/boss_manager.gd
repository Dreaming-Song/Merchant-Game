extends Node
## 五行神兽管理器 — 管理5只世界BOSS的生成/复活/通告
##
## 挂载场景树任意节点，自动管理所有 BOSS 生命周期
## 依赖：WorldBoss 类、BiomeManager、POISystem

class_name BossManager

# ==================== 信号 ====================
signal boss_spawned(boss_name: String, boss_type: int, location: Vector3)
signal boss_killed(boss_name: String, boss_type: int, killer_id: String)
signal boss_despawned(boss_name: String)

# ==================== BOSS 生成配置 ====================
const BOSS_SPAWN_CONFIGS: Array[Dictionary] = [
	{"type": WorldBoss.BossType.AZURE_DRAGON,   "scene": "res://assets/prefabs/boss_azure_dragon.tscn"},
	{"type": WorldBoss.BossType.WHITE_TIGER,     "scene": "res://assets/prefabs/boss_white_tiger.tscn"},
	{"type": WorldBoss.BossType.VERMILION_BIRD,  "scene": "res://assets/prefabs/boss_vermilion_bird.tscn"},
	{"type": WorldBoss.BossType.BLACK_WARRIOR,   "scene": "res://assets/prefabs/boss_black_warrior.tscn"},
	{"type": WorldBoss.BossType.GOLDEN_QILIN,    "scene": "res://assets/prefabs/boss_golden_qilin.tscn"},
]

# ==================== BOSS 状态 ====================
struct BossStatus:
	var boss_type: int
	var instance: WorldBoss           # 场景中的实例（alive时有效）
	var is_alive: bool
	var defeat_time: float            # 上次击败游戏内时间（hour）
	var respawn_days: int             # 复活所需游戏天数
	var spawn_position: Vector3       # 生成坐标
	var notification_sent: bool       # 是否已发出苏醒通告

var _boss_statuses: Dictionary = {}  # boss_type → BossStatus
var _active_bosses: Array[WorldBoss] = []

# 外部引用
@export var day_night_cycle: DayNightCycle
@export var biome_manager: BiomeManager
@export var poi_system: POISystem

func _ready() -> void:
	_initialize_bosses()
	
	# 定期检查复活状态
	var timer = Timer.new()
	timer.wait_time = 10.0
	timer.timeout.connect(_check_respawns)
	add_child(timer)
	timer.start()
	
	# 如果有时钟，监听天数变化
	if day_night_cycle:
		day_night_cycle.midnight.connect(_on_midnight)

func _initialize_bosses() -> void:
	"""初始化所有 BOSS 状态"""
	for config in BOSS_SPAWN_CONFIGS:
		var bt = config.type
		var bconfig = WorldBoss.get_boss_config(bt)
		
		var status = BossStatus.new()
		status.boss_type = bt
		status.is_alive = false
		status.defeat_time = -999.0  # 从未被击败
		status.respawn_days = _get_respawn_days(bt)
		status.spawn_position = bconfig.spawn_position
		status.notification_sent = false
		
		_boss_statuses[bt] = status
		
		print("🏯 已注册 %s（%s）" % [bconfig.title, bconfig.name])
	
	# 初始：生成 2 只 BOSS（青龙+麒麟），其余未激活
	_spawn_boss(WorldBoss.BossType.AZURE_DRAGON)
	_spawn_boss(WorldBoss.BossType.GOLDEN_QILIN)

# ==================== BOSS 生成 ====================

func _spawn_boss(boss_type: int) -> WorldBoss:
	"""实例化一只 BOSS 到场景中"""
	var config = WorldBoss.get_boss_config(boss_type)
	if config.is_empty():
		return null
	
	var status = _boss_statuses.get(boss_type)
	if not status:
		return null
	
	# 如果 BOSS 已激活，不重复生成
	if status.is_alive and status.instance and is_instance_valid(status.instance):
		return status.instance
	
	# 用代码创建 BOSS 节点（实际项目用预制体加载）
	var boss = WorldBoss.new()
	boss.boss_type = boss_type
	boss.name = "Boss_%s" % config.name
	boss.global_position = config.spawn_position
	
	# 多人模式检测
	var player_count = get_tree().get_nodes_in_group("player").size()
	boss.team_mode = player_count > 1
	
	# 注册信号
	boss.boss_damaged.connect(_on_boss_damaged.bind(boss_type))
	boss.boss_phase_changed.connect(_on_boss_phase_changed.bind(boss_type))
	boss.boss_defeated.connect(_on_boss_defeated.bind(boss_type))
	boss.boss_ability.connect(_on_boss_ability.bind(boss_type))
	
	add_child(boss)
	
	# 更新状态
	status.instance = boss
	status.is_alive = true
	status.notification_sent = false
	_active_bosses.append(boss)
	
	# 向全服通告
	var notification = "🌏【天地异象】五行神兽·%s（%s）已现身于「%s」！" % [
		config.title, config.name, _get_biome_display_name(config.spawn_biome)
	]
	boss_spawned.emit(config.name, boss_type, config.spawn_position)
	print(notification)
	
	# 同步到 POI 系统（BOSS 区域作为临时地标）
	if poi_system:
		var poi_id = "boss_%s" % config.name
		poi_system.register_poi(poi_id, config.title, "五行神兽·%s 盘踞之处" % config.name,
			config.spawn_position, POISystem.POIType.BOSS, 40.0)
	
	return boss

# ==================== 复活检查 ====================

func _check_respawns() -> void:
	"""检查是否有 BOSS 需要复活"""
	for bt in _boss_statuses.keys():
		var status = _boss_statuses[bt]
		
		# 活着的跳过
		if status.is_alive:
			continue
		
		# 检查复活条件
		if _should_respawn(status):
			_spawn_boss(bt)

func _should_respawn(status: BossStatus) -> bool:
	"""判断是否满足复活条件"""
	if not day_night_cycle:
		return false
	
	# 计算自上次击败经过了多少天
	var days_since_defeat = day_night_cycle.day_count - status.defeat_time
	return days_since_defeat >= status.respawn_days

func _get_respawn_days(boss_type: int) -> int:
	"""每种 BOSS 的复活天数"""
	match boss_type:
		WorldBoss.BossType.AZURE_DRAGON:   return 1   # 青龙 1天
		WorldBoss.BossType.WHITE_TIGER:     return 2   # 白虎 2天
		WorldBoss.BossType.VERMILION_BIRD:  return 1   # 朱雀 1天
		WorldBoss.BossType.BLACK_WARRIOR:   return 3   # 玄武 3天
		WorldBoss.BossType.GOLDEN_QILIN:    return 2   # 麒麟 2天
	return 2

# ==================== 事件回调 ====================

func _on_boss_damaged(boss_name: String, damage: int, current_hp: int, max_hp: int, phase: int, boss_type: int) -> void:
	"""BOSS 受伤"""
	# HP 阈值通告
	var hp_ratio = float(current_hp) / max_hp
	if hp_ratio <= 0.25 and not _boss_statuses[boss_type].notification_sent:
		var config = WorldBoss.get_boss_config(boss_type)
		print("⚠️ %s 濒临绝境！剩余 %.0f%% 生命值" % [config.name, hp_ratio * 100])
		_boss_statuses[boss_type].notification_sent = true
		# 但还是要允许再次触发
		_boss_statuses[boss_type].notification_sent = false

func _on_boss_phase_changed(boss_name: String, phase: int, boss_type: int) -> void:
	"""BOSS 阶段转换"""
	var config = WorldBoss.get_boss_config(boss_type)
	if phase == 2:
		var msg = "🔥 %s 进入狂暴状态！技能全面升级！" % config.name
		print(msg)

func _on_boss_defeated(boss_name: String, boss_type: int) -> void:
	"""BOSS 被击败"""
	var config = WorldBoss.get_boss_config(boss_type)
	var status = _boss_statuses.get(boss_type)
	if not status:
		return
	
	status.is_alive = false
	status.defeat_time = day_night_cycle.day_count if day_night_cycle else 0
	
	# 从活跃列表移除
	_active_bosses.erase(status.instance)
	
	# 全服通告
	var msg = "💀💀💀 五行神兽·%s（%s）已被击败！%d天后重生！" % [
		config.title, config.name, status.respawn_days
	]
	boss_killed.emit(config.name, boss_type, "player")
	print(msg)
	
	# 更新 POI 状态
	if poi_system:
		var poi_id = "boss_%s" % config.name
		# 标记为已攻略
		poi_system.mark_discovered(poi_id)

func _on_boss_ability(boss_name: String, ability_name: String, boss_type: int) -> void:
	"""BOSS 释放技能"""
	pass  # 可在 HUD 显示技能名称

func _on_midnight() -> void:
	"""子时检查：唤醒第二天才复活的 BOSS"""
	for bt in _boss_statuses.keys():
		var status = _boss_statuses[bt]
		if not status.is_alive:
			if _should_respawn(status):
				# 延迟几秒生成，有仪式感
				await get_tree().create_timer(3.0).timeout
				_spawn_boss(bt)

# ==================== 公共接口 ====================

## 获取所有 BOSS 状态
func get_all_boss_status() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for bt in _boss_statuses.keys():
		var s = _boss_statuses[bt]
		var config = WorldBoss.get_boss_config(bt)
		result.append({
			"boss_type": bt,
			"name": config.name,
			"title": config.title,
			"element": config.element,
			"is_alive": s.is_alive,
			"hp": s.instance.hp if s.instance and is_instance_valid(s.instance) else 0,
			"max_hp": config.max_hp,
			"respawn_days": s.respawn_days,
			"defeat_day": s.defeat_time,
			"position": s.spawn_position,
			"spawn_biome": config.spawn_biome,
		})
	return result

## 手动唤醒指定 BOSS
func force_spawn(boss_type: int) -> bool:
	var boss = _spawn_boss(boss_type)
	return boss != null

## 获取活跃 BOSS 数量
func get_active_boss_count() -> int:
	var count = 0
	for s in _boss_statuses.values():
		if s.is_alive:
			count += 1
	return count

# ==================== 辅助 ====================

func _get_biome_display_name(biome_key: String) -> String:
	match biome_key:
		"bamboo_forest":  return "青翠竹林"
		"maple_forest":   return "落霞枫林"
		"snow_peak":      return "寒雪山巅"
		"swamp":          return "幽暗沼泽"
		"volcano":        return "灵焰火山"
	return biome_key
