extends Node
## 📢 世界事件调度器 — 驱动所有周期/随机世界事件
##
## 挂在场景树中，通过 DayNightCycle 的信号触发
## 事件类型：兽潮、秘境之门、游走宝箱、世界BOSS（委托给 BossManager）
const DayNightCycle = preload("res://scripts/world/day_night_cycle.gd")

# class_name WorldEventManager — 已通过 autoload 注册

# ==================== 事件类型枚举 ====================
enum EventType {
	BEAST_TIDE,       # 兽潮
	SECRET_REALM,     # 秘境之门
	WANDERING_CHEST,  # 游走宝箱
	METEOR_SHOWER,    # 流星雨（采集材料）
	SPIRIT_WELL,      # 灵泉涌现（回蓝区域）
}

# ==================== 信号 ====================
signal event_announced(event_type: int, title: String, description: String, duration: float)
signal event_started(event_type: int, event_id: String, data: Dictionary)
signal event_completed(event_type: int, event_id: String, success: bool)
signal event_cancelled(event_type: int, event_id: String, reason: String)

# ==================== 事件配置 ====================
const EVENT_CONFIGS = {
	EventType.BEAST_TIDE: {
		"name": "🌊 兽潮来袭",
		"description": "大量妖兽正在向你的位置聚集！",
		"cooldown_days": 1.5,        # 冷却（游戏天数）
		"duration": 120.0,           # 持续时间（秒）
		"min_player_level": 5,
		"announce_lead_time": 15.0,  # 提前预警时间（秒）
		"icon": "🌊",
		"color": Color(1.0, 0.3, 0.2),
	},
	EventType.SECRET_REALM: {
		"name": "🔮 秘境之门",
		"description": "一道秘境传送门在附近出现，踏入可获得稀有宝物！",
		"cooldown_days": 2.0,
		"duration": 180.0,
		"min_player_level": 10,
		"announce_lead_time": 5.0,
		"icon": "🔮",
		"color": Color(0.6, 0.3, 1.0),
	},
	EventType.WANDERING_CHEST: {
		"name": "🎁 游走宝箱",
		"description": "一只神秘的宝箱正在世界中游荡，快去追！",
		"cooldown_days": 0.5,
		"duration": 90.0,
		"min_player_level": 1,
		"announce_lead_time": 3.0,
		"icon": "🎁",
		"color": Color(1.0, 0.8, 0.2),
	},
	EventType.METEOR_SHOWER: {
		"name": "☄️ 流星雨",
		"description": "天降流星！采集流星碎片可获得稀有材料！",
		"cooldown_days": 1.0,
		"duration": 60.0,
		"min_player_level": 3,
		"announce_lead_time": 10.0,
		"icon": "☄️",
		"color": Color(0.3, 0.6, 1.0),
	},
	EventType.SPIRIT_WELL: {
		"name": "💧 灵泉涌现",
		"description": "一口灵泉在你附近涌现，靠近可恢复法力！",
		"cooldown_days": 0.3,
		"duration": 45.0,
		"min_player_level": 1,
		"announce_lead_time": 0,
		"icon": "💧",
		"color": Color(0.2, 0.8, 0.8),
	},
}

# ==================== 内部状态 ====================
var day_night_cycle: DayNightCycle = null
var boss_manager: Node = null
var biome_manager: Node = null
var world_spawner: Node = null

# 活跃事件
var _active_events: Dictionary = {}          # event_id → event_data
var _event_cooldowns: Dictionary = {}         # EventType → last_trigger_day (float)
var _pending_announcements: Array = []        # 待播报的事件
var _next_event_id: int = 0

# 定时器
var _tide_spawn_timer: Timer = null
var _event_check_timer: Timer = null

func _ready() -> void:
	day_night_cycle = get_node("/root/DayNightCycle") if has_node("/root/DayNightCycle") else null
	boss_manager = get_node("/root/BossManager") if has_node("/root/BossManager") else null
	biome_manager = get_node("/root/BiomeManager") if has_node("/root/BiomeManager") else null
	world_spawner = get_node("/root/WorldSpawner") if has_node("/root/WorldSpawner") else null
	
	# 连线时钟
	if day_night_cycle:
		day_night_cycle.time_changed.connect(_on_time_changed)
		day_night_cycle.midnight.connect(_on_midnight)
		day_night_cycle.sunrise.connect(_on_sunrise)
		day_night_cycle.sunset.connect(_on_sunset)
	
	# 事件检查定时器（每 30 秒检查一次）
	_event_check_timer = Timer.new()
	_event_check_timer.wait_time = 30.0
	_event_check_timer.timeout.connect(_check_pending_events)
	add_child(_event_check_timer)
	_event_check_timer.start()
	
	print("📢 世界事件管理器已启动")

# ==================== 时间驱动检查 ====================

func _on_time_changed(hour: float) -> void:
	"""每刻检查是否触发事件"""
	# 只在特定时间段尝试触发
	if not _is_good_time_for_event(hour):
		return
	
	# 有概率触发事件（每刻约 5% 概率）
	if randf() < 0.05:
		_try_trigger_random_event(hour)

func _on_midnight() -> void:
	"""子时特殊事件概率提升"""
	# 子时秘境概率翻倍
	if randf() < 0.3:
		await _try_trigger_event(EventType.SECRET_REALM)

func _on_sunrise() -> void:
	"""日出时灵泉涌现"""
	if randf() < 0.4:
		await _try_trigger_event(EventType.SPIRIT_WELL)

func _on_sunset() -> void:
	"""日落时兽潮概率提升"""
	if randf() < 0.25:
		await _try_trigger_event(EventType.BEAST_TIDE)

func _is_good_time_for_event(hour: float) -> bool:
	"""判断是否是适合触发事件的时段（避免干扰玩家休息）"""
	# 子时(0-2)不触发普通事件
	if hour >= 0 and hour < 2:
		return false
	return true

# ==================== 事件触发 ====================

func _try_trigger_random_event(hour: float) -> void:
	"""尝试触发一个随机事件"""
	var event_type = _pick_random_event()
	if event_type >= 0:
		await _try_trigger_event(event_type)

func _pick_random_event() -> int:
	"""根据权重随机选择事件类型"""
	var weights = {
		EventType.SPIRIT_WELL: 40,      # 灵泉最常见
		EventType.WANDERING_CHEST: 30,  # 宝箱常见
		EventType.METEOR_SHOWER: 15,    # 流星雨较少
		EventType.BEAST_TIDE: 10,       # 兽潮较少
		EventType.SECRET_REALM: 5,      # 秘境最稀有
	}
	
	var total_weight = 0
	for w in weights.values():
		total_weight += w
	
	var roll = randi() % total_weight
	var cumulative = 0
	for event_type in weights.keys():
		cumulative += weights[event_type]
		if roll < cumulative:
			return event_type
	
	return EventType.SPIRIT_WELL

func _try_trigger_event(event_type: int) -> bool:
	"""尝试触发指定事件（检查冷却等条件）"""
	# 检查是否在冷却中
	var config = EVENT_CONFIGS.get(event_type)
	if not config:
		return false
	
	# 冷却检查
	var last_day = _event_cooldowns.get(event_type, -999.0)
	if day_night_cycle:
		var days_since = day_night_cycle.day_count - last_day
		if days_since < config["cooldown_days"]:
			return false
	
	# 检查玩家等级
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var player_level = player.get("level") if player.has_method("get_level") else 1
		if player_level < config["min_player_level"]:
			return false
	
	# 检查是否已有同类事件活跃
	for eid in _active_events.keys():
		if _active_events[eid].get("event_type") == event_type:
			return false
	
	# 触发！
	await _trigger_event(event_type)
	return true

func _trigger_event(event_type: int) -> void:
	"""触发事件并开始流程"""
	var config = EVENT_CONFIGS[event_type]
	var event_id = "evt_%d_%d" % [event_type, _next_event_id]
	_next_event_id += 1
	
	# 获取触发位置（玩家附近）
	var player = get_tree().get_first_node_in_group("player")
	var origin = player.global_position if player else Vector3(0, 0, 0)
	var spawn_pos = _find_spawn_position(origin, event_type)
	
	# 记录冷却
	if day_night_cycle:
		_event_cooldowns[event_type] = day_night_cycle.day_count
	else:
		_event_cooldowns[event_type] = Time.get_unix_time_from_system() / 3600.0
	
	# 创建事件数据
	var event_data = {
		"event_id": event_id,
		"event_type": event_type,
		"name": config["name"],
		"description": config["description"],
		"duration": config["duration"],
		"position": spawn_pos,
		"start_time": Time.get_unix_time_from_system(),
		"end_time": Time.get_unix_time_from_system() + config["duration"],
		"announce_lead_time": config["announce_lead_time"],
		"phase": "announcing",  # announcing → active → completed
		"icon": config["icon"],
		"color": config["color"],
	}
	
	_active_events[event_id] = event_data
	
	print("📢 [事件] %s 即将在 %.1f秒后开始！" % [config["name"], config["announce_lead_time"]])
	
	# 发送公告
	event_announced.emit(event_type, config["name"], config["description"], config["duration"])
	
	# 延迟后正式开始
	if config["announce_lead_time"] > 0:
		await get_tree().create_timer(config["announce_lead_time"]).timeout
	
	if not _active_events.has(event_id):
		return  # 被取消
	
	event_data["phase"] = "active"
	event_started.emit(event_type, event_id, event_data)
	
	# 执行事件逻辑
	match event_type:
		EventType.BEAST_TIDE:
			_start_beast_tide(event_id, spawn_pos, config)
		EventType.SECRET_REALM:
			_start_secret_realm(event_id, spawn_pos, config)
		EventType.WANDERING_CHEST:
			_start_wandering_chest(event_id, spawn_pos, config)
		EventType.METEOR_SHOWER:
			_start_meteor_shower(event_id, spawn_pos, config)
		EventType.SPIRIT_WELL:
			_start_spirit_well(event_id, spawn_pos, config)
	
	# 计时器自动结束
	await get_tree().create_timer(config["duration"]).timeout
	
	if _active_events.has(event_id):
		_complete_event(event_id, true)

# ==================== 🐾 位置查找 ====================

func _find_spawn_position(origin: Vector3, event_type: int) -> Vector3:
	"""在玩家附近找合适的事件生成位置"""
	var distance = 20.0  # 默认 20 米外
	match event_type:
		EventType.BEAST_TIDE: distance = 30.0
		EventType.SECRET_REALM: distance = 25.0
		EventType.WANDERING_CHEST: distance = 15.0
		EventType.METEOR_SHOWER: distance = 50.0  # 稍远
		EventType.SPIRIT_WELL: distance = 10.0   # 很近
	
	var angle = randf_range(0, TAU)
	var pos = origin + Vector3(cos(angle), 0, sin(angle)) * distance
	pos.y = _get_ground_height(pos)
	return pos

func _get_ground_height(pos: Vector3) -> float:
	"""获取地面高度（简化版，用射线检测）"""
	var space = get_viewport().world_3d.direct_space_state
	if not space:
		return pos.y
	var query = PhysicsRayQueryParameters3D.create(pos + Vector3(0, 50, 0), pos + Vector3(0, -50, 0))
	var result = space.intersect_ray(query)
	if result:
		return result.position.y
	return pos.y

# ==================== 🌊 兽潮 ====================

func _start_beast_tide(event_id: String, center: Vector3, config: Dictionary) -> void:
	"""开始兽潮事件：多波妖兽围攻"""
	event_announced.emit(EventType.BEAST_TIDE, "⚠️ 兽潮已至！", "守住阵地！击败所有妖兽！", config["duration"])
	
	var waves = [
		{"count": 3, "delay": 0,  "types": [0, 0, 1]},    # 第一波：3只灵狼+雾猿
		{"count": 5, "delay": 20, "types": [0, 1, 1, 2, 2]},   # 第二波：5只混合
		{"count": 7, "delay": 45, "types": [0, 0, 1, 2, 2, 3, 1]},  # 第三波：7只精英混合
	]
	
	var total_killed = 0
	var total_to_kill = 0
	for wave in waves:
		total_to_kill += wave["count"]
	
	for wave in waves:
		await get_tree().create_timer(wave["delay"]).timeout
		if not _active_events.has(event_id):
			return
		
		var remaining = wave["count"]
		for i in range(wave["count"]):
			if not _active_events.has(event_id):
				return
			
			var etype = wave["types"][i] % 4  # 0=灵狼,1=雾猿,2=焰猪,3=铁龟
			_spawn_enemy(etype, center + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5)))
			remaining -= 1
		
		var wave_num = 1 + waves.find(wave)
		print("🌊 兽潮第 %d 波！(%d 只)" % [wave_num, wave["count"]])
		event_announced.emit(EventType.BEAST_TIDE, 
			"🌊 第 %d 波！" % wave_num,
			"%d 只妖兽出现！" % wave["count"],
			config["duration"] - wave["delay"])
	
	print("🌊 兽潮结束！")

func _spawn_enemy(enemy_type: int, position: Vector3) -> Node:
	"""生成一只妖兽"""
	if world_spawner and world_spawner.has_method("spawn_enemy"):
		return world_spawner.spawn_enemy(enemy_type, position)
	
	# 后备：直接创建
	var enemy = load("res://scripts/combat/enemy.gd").new()
	enemy.enemy_type = enemy_type
	enemy.global_position = position
	add_child(enemy)
	return enemy

# ==================== 🔮 秘境之门 ====================

func _start_secret_realm(event_id: String, position: Vector3, config: Dictionary) -> void:
	"""开始秘境事件：生成传送门 + 精英怪"""
	event_announced.emit(EventType.SECRET_REALM, 
		"🔮 秘境之门已开启！",
		"前往 %d,%d 进入秘境！" % [position.x, position.z],
		config["duration"])
	
	# 创建传送门视觉（简化版：标记位置）
	_create_event_marker(position, EventType.SECRET_REALM, config["duration"])
	
	# 生成守护精英怪
	var elites = [
		{"type": 1, "pos": position + Vector3(3, 0, 2)},
		{"type": 3, "pos": position + Vector3(-3, 0, -2)},
	]
	for elite in elites:
		var enemy = _spawn_enemy(elite["type"], elite["pos"])
		if enemy:
			# 强化精英怪
			enemy.max_hp = int(enemy.max_hp * 2.5)
			enemy.hp = enemy.max_hp
			enemy.attack_damage = int(enemy.attack_damage * 1.8)
			enemy.exp_reward = int(enemy.exp_reward * 3)
	
	# 提示玩家
	print("🔮 秘境传送门在 (%.0f, %.0f) 持续 %.0f 秒！" % [position.x, position.z, config["duration"]])

# ==================== 🎁 游走宝箱 ====================

func _start_wandering_chest(event_id: String, position: Vector3, config: Dictionary) -> void:
	"""开始游走宝箱事件"""
	event_announced.emit(EventType.WANDERING_CHEST,
		"🎁 游走宝箱出现了！",
		"它在世界中游荡，找到并打开它！",
		config["duration"])
	
	# 创建宝箱
	var chest = _create_wandering_chest(position)
	if not chest:
		return
	
	# 宝箱会随机移动（每 10 秒瞬移一次）
	var move_timer = Timer.new()
	move_timer.name = "ChestMove_%s" % event_id
	move_timer.wait_time = 10.0
	move_timer.timeout.connect(func():
		if not _active_events.has(event_id) or not is_instance_valid(chest):
			if is_instance_valid(move_timer):
				move_timer.queue_free()
			return
		# 瞬移到附近新位置
		var new_pos = _find_spawn_position(chest.global_position, EventType.WANDERING_CHEST)
		chest.global_position = new_pos
		print("🎁 宝箱移动到了 (%.0f, %.0f)" % [new_pos.x, new_pos.z])
	)
	add_child(move_timer)
	move_timer.start()
	
	# 事件结束时清理
	await get_tree().create_timer(config["duration"]).timeout
	if is_instance_valid(move_timer):
		move_timer.queue_free()
	if is_instance_valid(chest):
		chest.queue_free()

func _create_wandering_chest(position: Vector3) -> Node:
	"""创建游走宝箱"""
	# 尝试加载宝箱预制体
	var chest_scene = load("res://scenes/entities/wandering_chest.tscn") if ResourceLoader.exists("res://scenes/entities/wandering_chest.tscn") else null
	var chest = null
	
	if chest_scene:
		chest = chest_scene.instantiate()
	else:
		# 用代码创建简单宝箱（带互动组件）
		chest = load("res://scripts/entities/chest_interactable.gd").new() if ResourceLoader.exists("res://scripts/entities/chest_interactable.gd") else Node3D.new()
	
	chest.global_position = position
	chest.name = "WanderingChest"
	add_child(chest)
	return chest

# ==================== ☄️ 流星雨 ====================

func _start_meteor_shower(event_id: String, center: Vector3, config: Dictionary) -> void:
	"""开始流星雨事件：持续掉落流星碎片"""
	event_announced.emit(EventType.METEOR_SHOWER,
		"☄️ 流星雨降临！",
		"采集地面上的流星碎片可获得稀有材料！",
		config["duration"])
	
	# 每 5 秒掉落一颗流星
	var interval = 5.0
	var drops = int(config["duration"] / interval)
	
	for i in range(drops):
		if not _active_events.has(event_id):
			return
		
		await get_tree().create_timer(interval).timeout
		
		# 流星坠落地
		var pos = center + Vector3(randf_range(-15, 15), 20, randf_range(-15, 15))
		pos.y = _get_ground_height(pos)
		
		# 视觉特效：闪白
		_spawn_meteor_effect(pos)
		
		# 生成可采集的资源节点
		_spawn_meteor_resource(pos)
		
		print("☄️ 流星坠落！")

func _spawn_meteor_effect(position: Vector3) -> void:
	"""流星落地特效（简化为粒子）"""
	# 暂时用闪烁标记代替
	pass

func _spawn_meteor_resource(position: Vector3) -> void:
	"""生成流星碎片资源"""
	# 尝试使用资源节点
	var resource_scene = load("res://scripts/entities/resource_node.gd") if ResourceLoader.exists("res://scripts/entities/resource_node.gd") else null
	if resource_scene:
		var node = resource_scene.new()
		node.global_position = position
		node.name = "MeteorFragment"
		add_child(node)

# ==================== 💧 灵泉涌现 ====================

func _start_spirit_well(event_id: String, position: Vector3, config: Dictionary) -> void:
	"""开始灵泉事件：生成回蓝区域"""
	event_announced.emit(EventType.SPIRIT_WELL,
		"💧 灵泉涌现！",
		"靠近灵泉可快速恢复法力！",
		config["duration"])
	
	# 创建灵泉区域（Area3D）
	var well = Area3D.new()
	well.name = "SpiritWell_%s" % event_id
	well.global_position = position
	
	# 碰撞形状
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 4.0
	col.shape = shape
	well.add_child(col)
	
	# 视觉标记（发光球体）
	var mesh = MeshInstance3D.new()
	mesh.mesh = SphereMesh.new()
	mesh.mesh.radius = 0.5
	mesh.mesh.height = 1.0
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.8, 1.0, 0.6)
	mat.emission = Color(0.2, 0.6, 1.0)
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat
	mesh.global_position = position + Vector3(0, 0.5, 0)
	add_child(mesh)
	
	# 绑定回蓝逻辑
	well.body_entered.connect(func(body: Node):
		if body.is_in_group("player") and body.has_method("restore_mp"):
			# 进入范围开始回蓝
			var regen_timer = Timer.new()
			regen_timer.wait_time = 1.0
			regen_timer.autostart = true
			var on_tick = func():
				if not is_instance_valid(body) or not is_instance_valid(well):
					regen_timer.queue_free()
					return
				if body.global_position.distance_to(well.global_position) > 5.0:
					regen_timer.queue_free()
					return
				body.restore_mp(10)
			regen_timer.timeout.connect(on_tick)
			well.add_child(regen_timer)
	)
	
	add_child(well)
	
	# 事件结束清理
	await get_tree().create_timer(config["duration"]).timeout
	if is_instance_valid(well):
		well.queue_free()
	if is_instance_valid(mesh):
		mesh.queue_free()

# ==================== 🏁 事件完成/取消 ====================

func _complete_event(event_id: String, success: bool) -> void:
	"""完成事件"""
	var event_data = _active_events.get(event_id)
	if not event_data:
		return
	
	event_data["phase"] = "completed"
	var etype = event_data.get("event_type", -1)
	
	event_completed.emit(etype, event_id, success)
	_active_events.erase(event_id)
	
	print("📢 [事件] %s 已结束！" % event_data.get("name") or "未知")

func cancel_event(event_id: String, reason: String = "手动取消") -> void:
	"""手动取消事件"""
	var event_data = _active_events.get(event_id)
	if not event_data:
		return
	
	event_data["phase"] = "cancelled"
	event_cancelled.emit(event_data.get("event_type", -1), event_id, reason)
	_active_events.erase(event_id)
	
	print("📢 [事件] %s 已取消：%s" % [event_data.get("name") or "未知", reason])

# ==================== 🎨 事件标记 ====================

func _create_event_marker(position: Vector3, event_type: int, duration: float) -> void:
	"""创建事件地面标记"""
	var marker = MeshInstance3D.new()
	marker.mesh = QuadMesh.new()
	marker.rotation.x = -PI / 2  # 躺平在地上
	
	var color = EVENT_CONFIGS.get(event_type, {}).get("color") or Color.WHITE
	# 安全守卫：headless 下 color 可能不是 Color 类型
	if typeof(color) != TYPE_COLOR:
		color = Color.WHITE
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.3)
	mat.emission = color
	mat.emission_energy_multiplier = 1.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker.material = mat
	marker.global_position = position + Vector3(0, 0.1, 0)
	if is_inside_tree():
		add_child(marker)
	
	# 自动淡出消失
	var tween = create_tween()
	tween.tween_method(func(alpha: float):
		if is_instance_valid(marker) and marker.material:
			marker.material.emission_energy_multiplier = alpha * 2.0
			marker.material.albedo_color.a = alpha * 0.3
	, 1.0, 0.0, duration)
	
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(marker):
			marker.queue_free()
	)

# ==================== 🔍 检查待处理事件 ====================

func _check_pending_events() -> void:
	"""定期检查是否有待处理的事件"""
	# 清理过期事件（防止幽灵事件）
	var now = Time.get_unix_time_from_system()
	for event_id in _active_events.keys():
		var data = _active_events[event_id]
		if data.get("end_time") or 0 < now - 30:
			_complete_event(event_id, false)
			print("⚠️ 清理过期事件: %s" % event_id)

# ==================== 公共接口 ====================

func get_active_events() -> Array[Dictionary]:
	"""获取所有活跃事件"""
	var result: Array[Dictionary] = []
	for eid in _active_events.keys():
		var data = _active_events[eid].duplicate()
		data["remaining"] = max(0, data.get("end_time") or 0 - Time.get_unix_time_from_system())
		result.append(data)
	return result

func force_trigger_event(event_type: int) -> bool:
	"""强制触发事件（无视冷却）"""
	await _trigger_event(event_type)
	return true

func get_event_config(event_type: int) -> Dictionary:
	return EVENT_CONFIGS.get(event_type, {}).duplicate()
