extends CharacterBody3D
## 五行神兽 · BOSS 单位 — Phase 4 世界首领
##
## 每只神兽对应一个地貌，拥有：
## - 2 阶段变身（HP<50% 进入 Phase 2）
## - 专属五行技能
## - 全服通告 + 稀有掉落
## - 击败后冷却刷新（游戏天数）

class_name WorldBoss

# ==================== 五行神兽枚举 ====================
enum BossType {
	AZURE_DRAGON,    # 青龙 · 木 — 竹林
	WHITE_TIGER,     # 白虎 · 金 — 雪山
	VERMILION_BIRD,  # 朱雀 · 火 — 火山
	BLACK_WARRIOR,   # 玄武 · 水 — 沼泽
	GOLDEN_QILIN,    # 麒麟 · 土 — 枫林/中央
}

enum Phase { ONE, TWO_TRANSITION, TWO }

# ==================== 信号 ====================
signal boss_damaged(boss_name: String, damage: int, current_hp: int, max_hp: int, phase: int)
signal boss_phase_changed(boss_name: String, phase: int)
signal boss_defeated(boss_name: String, boss_type: int)
signal boss_aggro(boss_name: String, player_id: String)
signal boss_ability(boss_name: String, ability_name: String)

# ==================== 导出属性 ====================
@export var boss_type: int = BossType.AZURE_DRAGON
@export var team_mode: bool = false  # 多人模式时血量翻倍

# ==================== BOSS 配置表 ====================
static func get_boss_config(t: int) -> Dictionary:
	match t:
		BossType.AZURE_DRAGON:
			return {
				"name": "青龙",
				"title": "东方木德·青龙",
				"element": "木",
				"color": Color(0.2, 0.8, 0.3),
				"max_hp": 5000,
				"attack_damage": 40,
				"move_speed": 5.0,
				"aggro_range": 30.0,
				"attack_range": 6.0,
				"spawn_biome": "bamboo_forest",
				"spawn_position": Vector3(15, 0, 20),
				"abilities_phase1": ["藤蔓缠绕", "木灵吐息", "治愈之雨"],
				"abilities_phase2": ["风暴召唤", "万木同根"],
				"phase2_hp_ratio": 0.50,
				"drops": [
					{"item": "青龙鳞", "prob": 1.0, "min_count": 1, "max_count": 3},
					{"item": "木灵珠", "prob": 0.7, "min_count": 1, "max_count": 1},
					{"item": "生命之种", "prob": 0.3, "min_count": 1, "max_count": 1},
				],
				"exp_reward": 5000,
			}
		BossType.WHITE_TIGER:
			return {
				"name": "白虎",
				"title": "西方金德·白虎",
				"element": "金",
				"color": Color(0.9, 0.9, 0.95),
				"max_hp": 5500,
				"attack_damage": 55,
				"move_speed": 7.0,
				"aggro_range": 35.0,
				"attack_range": 5.0,
				"spawn_biome": "snow_peak",
				"spawn_position": Vector3(20, 0, 85),
				"abilities_phase1": ["裂爪斩", "金属尖刺", "虎啸震"],
				"abilities_phase2": ["金刚不坏", "刃雨"],
				"phase2_hp_ratio": 0.50,
				"drops": [
					{"item": "白虎牙", "prob": 1.0, "min_count": 1, "max_count": 3},
					{"item": "金灵珠", "prob": 0.7, "min_count": 1, "max_count": 1},
					{"item": "白虎战纹", "prob": 0.3, "min_count": 1, "max_count": 1},
				],
				"exp_reward": 5500,
			}
		BossType.VERMILION_BIRD:
			return {
				"name": "朱雀",
				"title": "南方火德·朱雀",
				"element": "火",
				"color": Color(1.0, 0.3, 0.1),
				"max_hp": 4500,
				"attack_damage": 60,
				"move_speed": 8.0,
				"aggro_range": 40.0,
				"attack_range": 8.0,
				"spawn_biome": "volcano",
				"spawn_position": Vector3(-80, 5, 60),
				"abilities_phase1": ["烈焰吐息", "火雨流星", "炽羽飞射"],
				"abilities_phase2": ["涅槃重生", "烈焰领域"],
				"phase2_hp_ratio": 0.50,
				"drops": [
					{"item": "朱雀羽", "prob": 1.0, "min_count": 1, "max_count": 3},
					{"item": "火灵珠", "prob": 0.7, "min_count": 1, "max_count": 1},
					{"item": "涅槃火种", "prob": 0.3, "min_count": 1, "max_count": 1},
				],
				"exp_reward": 5000,
			}
		BossType.BLACK_WARRIOR:
			return {
				"name": "玄武",
				"title": "北方水德·玄武",
				"element": "水",
				"color": Color(0.1, 0.3, 0.6),
				"max_hp": 7000,
				"attack_damage": 35,
				"move_speed": 3.0,
				"aggro_range": 25.0,
				"attack_range": 7.0,
				"spawn_biome": "swamp",
				"spawn_position": Vector3(-60, 0, -50),
				"abilities_phase1": ["水龙卷", "玄冰护盾", "冰刺囚牢"],
				"abilities_phase2": ["怒涛海啸", "绝对零度"],
				"phase2_hp_ratio": 0.50,
				"drops": [
					{"item": "玄武甲", "prob": 1.0, "min_count": 1, "max_count": 2},
					{"item": "水灵珠", "prob": 0.7, "min_count": 1, "max_count": 1},
					{"item": "玄冰晶核", "prob": 0.3, "min_count": 1, "max_count": 1},
				],
				"exp_reward": 6000,
			}
		BossType.GOLDEN_QILIN:
			return {
				"name": "麒麟",
				"title": "中央土德·麒麟",
				"element": "土",
				"color": Color(0.85, 0.7, 0.2),
				"max_hp": 6000,
				"attack_damage": 50,
				"move_speed": 6.0,
				"aggro_range": 32.0,
				"attack_range": 6.0,
				"spawn_biome": "maple_forest",
				"spawn_position": Vector3(-40, 0, 30),
				"abilities_phase1": ["陨石投掷", "地裂震荡", "石铠护体"],
				"abilities_phase2": ["山崩地裂", "大地治愈"],
				"phase2_hp_ratio": 0.50,
				"drops": [
					{"item": "麒麟角", "prob": 1.0, "min_count": 1, "max_count": 2},
					{"item": "土灵珠", "prob": 0.7, "min_count": 1, "max_count": 1},
					{"item": "厚土之源", "prob": 0.3, "min_count": 1, "max_count": 1},
				],
				"exp_reward": 6000,
			}
	return {}

# ==================== 运行状态 ====================
var config: Dictionary
var hp: int
var max_hp: int
var phase: int = Phase.ONE
var is_alive: bool = true
var is_invulnerable: bool = false  # 阶段过渡时无敌

# AI 状态
enum AIState { IDLE, PATROL, CHASE, ABILITY, HURT, DEAD }
var ai_state: int = AIState.IDLE
var target_player: Node = null
var ability_cooldown: float = 0.0
var phase_transition_playing: bool = false

@onready var player_ref: Node = get_tree().get_first_node_in_group("player")
@onready var hitbox: Area3D = $Hitbox
var threat_system: ThreatSystem = null

func _ready() -> void:
	config = get_boss_config(boss_type)
	max_hp = config.max_hp
	if team_mode:
		max_hp = int(max_hp * 1.5)  # 多人模式 1.5 倍血量
	hp = max_hp
	
	add_to_group("world_bosses")
	add_to_group("enemies")
	
	# 连接信号
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_entered)
	
	# 初始通告
	print("🐉【天地异象】%s（%s）已降临！" % [config.title, config.name])
	boss_aggro.emit(config.name, "world")
	
	# 初始化仇恨系统
	threat_system = ThreatSystem.new()
	threat_system.setup(self)
	add_child(threat_system)
	
	# 激活BOSS血条UI（单人/房主自动激活）
	_bind_boss_hud()
	
func _bind_boss_hud() -> void:
	"""绑定BOSS血条UI"""
	var ui = get_node("/root/UIManager") if has_node("/root/UIManager") else null
	if ui and ui.has_node("HUD") and ui.get_node("HUD").has_node("BossHUD"):
		var boss_hud = ui.get_node("HUD/BossHUD")
		if boss_hud.has_method("activate"):
			boss_hud.activate(self)

func _physics_process(delta: float) -> void:
	if not is_alive or phase_transition_playing:
		# 但死亡时仍需同步
		if not is_alive:
			_sync_state()
		return
	
	_update_player_ref()
	ability_cooldown = max(ability_cooldown - delta, 0)
	
	match ai_state:
		AIState.IDLE:
			_check_aggro()
		AIState.CHASE:
			_chase(delta)
		AIState.ABILITY:
			pass
		AIState.HURT:
			pass
	
	# 多人状态同步
	_sync_state()

# ==================== AI 行为 ====================

func _update_player_ref() -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player")

func _check_aggro() -> void:
	if player_ref == null:
		return
	var dist = global_position.distance_to(player_ref.global_position)
	if dist <= config.aggro_range:
		target_player = player_ref
		ai_state = AIState.CHASE
		boss_aggro.emit(config.name, player_ref.name)
		print("🐉 %s 被激怒了！" % config.name)

func _chase(delta: float) -> void:
	if target_player == null or not is_instance_valid(target_player):
		ai_state = AIState.IDLE
		return
	
	var dist = global_position.distance_to(target_player.global_position)
	
	# 超出范围则归位
	if dist > config.aggro_range * 2.0:
		ai_state = AIState.IDLE
		target_player = null
		return
	
	# 进入攻击范围，放技能
	if dist <= config.attack_range + 2.0:
		if ability_cooldown <= 0:
			_use_ability()
		else:
			# 面向玩家等待
			look_at(Vector3(target_player.global_position.x, global_position.y, target_player.global_position.z), Vector3.UP)
			# 缓慢逼近
			var dir = (target_player.global_position - global_position).normalized()
			velocity = dir * config.move_speed * 0.3
			move_and_slide()
		return
	
	# 追击
	var dir = (target_player.global_position - global_position).normalized()
	velocity = dir * config.move_speed
	look_at(Vector3(target_player.global_position.x, global_position.y, target_player.global_position.z), Vector3.UP)
	move_and_slide()

# ==================== 技能系统 ====================

func _use_ability() -> void:
	"""随机释放一个当前阶段的技能"""
	var abilities = config.abilities_phase2 if phase == Phase.TWO else config.abilities_phase1
	if abilities.is_empty():
		return
	
	var ability = abilities[randi() % abilities.size()]
	ai_state = AIState.ABILITY
	boss_ability.emit(config.name, ability)
	print("🐉 %s 释放技能：%s！" % [config.name, ability])
	
	# 技能效果（简化版：按技能名分发）
	match ability:
		# ---- Phase 1 技能 ----
		"藤蔓缠绕":
			_area_damage(25, 8.0, 1.5)
		"木灵吐息":
			_cone_damage(35, 10.0)
		"治愈之雨":
			_heal_self(200)
		"裂爪斩":
			_area_damage(40, 5.0, 2.0)
		"金属尖刺":
			_projectile_attack(30)
		"虎啸震":
			_area_stun(3.0, 8.0)
		"烈焰吐息":
			_cone_damage(45, 12.0)
		"火雨流星":
			_area_damage(50, 10.0, 3.0)
		"炽羽飞射":
			_projectile_attack(35)
		"水龙卷":
			_area_damage(30, 7.0, 2.0)
		"玄冰护盾":
			_shield_self(500, 5.0)
		"冰刺囚牢":
			_area_stun(2.0, 6.0)
		"陨石投掷":
			_area_damage(45, 8.0, 2.5)
		"地裂震荡":
			_area_stun(2.5, 9.0)
		"石铠护体":
			_shield_self(300, 4.0)
		
		# ---- Phase 2 技能 ----
		"风暴召唤":
			_area_damage(60, 12.0, 3.0)
		"万木同根":
			_heal_self(500)
		"金刚不坏":
			_shield_self(800, 6.0)
		"刃雨":
			_area_damage(55, 10.0, 2.5)
		"涅槃重生":
			_revive_self(0.15)
		"烈焰领域":
			_area_damage(40, 8.0, 5.0)  # DOT 区域
		"怒涛海啸":
			_area_damage(65, 14.0, 3.0)
		"绝对零度":
			_area_stun(4.0, 10.0)
		"山崩地裂":
			_area_damage(70, 12.0, 3.5)
		"大地治愈":
			_heal_self(800)
	
	# CD 根据阶段不同
	ability_cooldown = 2.5 if phase == Phase.TWO else 3.5
	await get_tree().create_timer(0.5).timeout
	ai_state = AIState.CHASE

# ==================== 技能效果 ====================

func _area_damage(damage: int, radius: float, delay: float) -> void:
	"""范围伤害（延迟后生效，给玩家反应时间）"""
	print("⚡ %s 蓄力中... %.1f秒后爆发！" % [config.name, delay])
	await get_tree().create_timer(delay).timeout
	# 检测范围内所有玩家/实体
	var hit_targets = get_tree().get_nodes_in_group("player")
	for target in hit_targets:
		if target is Node3D:
			var dist = target.global_position.distance_to(global_position)
			if dist <= radius:
				if target.has_method("take_damage"):
					target.take_damage(damage)
					print("💥 %s 受到 %d 点伤害" % [target.name, damage])

func _cone_damage(damage: int, range: float) -> void:
	"""锥形范围伤害（前方扇形）"""
	var hit_targets = get_tree().get_nodes_in_group("player")
	for target in hit_targets:
		if target is Node3D:
			var dist = target.global_position.distance_to(global_position)
			if dist <= range:
				# 简单的前方检测
				var to_target = (target.global_position - global_position).normalized()
				var forward = -global_transform.basis.z
				var angle = forward.angle_to(to_target)
				if angle < 1.0:  # ~60度扇形
					if target.has_method("take_damage"):
						target.take_damage(damage)
						print("🔥 %s 被吐息命中，受到 %d 点伤害" % [target.name, damage])

func _projectile_attack(damage: int) -> void:
	"""远程弹射攻击"""
	if target_player:
		if target_player.has_method("take_damage"):
			target_player.take_damage(damage)
			print("🏹 远程攻击命中 %s，%d 伤害" % [target_player.name, damage])

func _heal_self(amount: int) -> void:
	"""自我治疗"""
	hp = min(hp + amount, max_hp)
	print("💚 %s 恢复了 %d 生命值" % [config.name, amount])

func _shield_self(amount: int, duration: float) -> void:
	"""生成护盾（无敌+回血效果模拟）"""
	is_invulnerable = true
	print("🛡️ %s 获得护盾，持续 %.1f秒" % [config.name, duration])
	await get_tree().create_timer(duration).timeout
	is_invulnerable = false
	print("🛡️ %s 护盾消失" % config.name)

func _area_stun(duration: float, radius: float) -> void:
	"""范围眩晕"""
	print("🌀 %s 震荡波！" % config.name)
	var hit_targets = get_tree().get_nodes_in_group("player")
	for target in hit_targets:
		if target is Node3D:
			var dist = target.global_position.distance_to(global_position)
			if dist <= radius:
				print("💫 %s 被眩晕 %.1f秒" % [target.name, duration])

func _revive_self(hp_ratio: float) -> void:
	"""涅槃重生（朱雀专属）"""
	print("🔥 %s 涅槃重生！" % config.name)
	hp = int(max_hp * hp_ratio)
	print("💚 %s 恢复至 %d 生命值" % [config.name, hp])

# ==================== 受伤/阶段转换 ====================

func take_damage(damage: int, source: String = "player", player_id: String = "") -> void:
	if not is_alive or is_invulnerable:
		return
	
	if phase == Phase.TWO_TRANSITION:
		return
	
	hp = max(hp - damage, 0)
	boss_damaged.emit(config.name, damage, hp, max_hp, phase)
	
	# 多人仇恨系统
	if not player_id.is_empty() and threat_system:
		threat_system.add_threat(player_id, damage)
		# 根据仇恨切换目标
		var top = threat_system.get_top_threat()
		if top.player_id and not top.player_id.is_empty():
			var players = get_tree().get_nodes_in_group("player")
			for p in players:
				if str(p.get_instance_id()) == top.player_id or p.name == top.player_id:
					target_player = p
					break
	
	# 受击反馈
	ai_state = AIState.HURT
	await get_tree().create_timer(0.2).timeout
	if ai_state == AIState.HURT:
		ai_state = AIState.CHASE
	
	if phase == Phase.ONE and hp <= max_hp * config.phase2_hp_ratio:
		_enter_phase_two()
	
	if hp <= 0:
		_die()

func _enter_phase_two() -> void:
	"""进入第二阶段"""
	phase = Phase.TWO_TRANSITION
	phase_transition_playing = true
	is_invulnerable = true
	
	print("🔥🔥🔥 %s 进入第二阶段！" % config.name)
	boss_phase_changed.emit(config.name, 2)
	
	# 转换动画 + 霸气亮相
	await get_tree().create_timer(2.0).timeout
	
	phase = Phase.TWO
	is_invulnerable = false
	phase_transition_playing = false
	
	# 释放一个见面礼
	if config.abilities_phase2.size() > 0:
		var first_ability = config.abilities_phase2[0]
		# 不等待直接进入战斗
		ability_cooldown = 0.0
	
	print("🔥 %s 第二阶段已激活！技能升级！" % config.name)

func _die() -> void:
	"""死亡"""
	if not is_alive:
		return
	is_alive = false
	ai_state = AIState.DEAD
	
	print("💀💀💀 %s（%s）被击败！" % [config.title, config.name])
	boss_defeated.emit(config.name, boss_type)
	
	# 掉落
	_spawn_drops()
	
	# 死亡动画后消失
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _spawn_drops() -> void:
	"""生成掉落物"""
	for drop in config.drops:
		var count = 0
		for _i in range(drop.get("max_count", 1)):
			if randf() < drop.get("prob", 0.0):
				count += 1
		if count > 0:
			print("📦 掉落：%s × %d" % [drop.get("item", "unknown"), count])
			# TODO: 实际生成掉落物实体在地面上

# ==================== 多人 RPC 同步 ====================

@rpc("any_peer", "unreliable")
func sync_boss_state(hp_val: int, phase_val: int, pos_x: float, pos_y: float, pos_z: float, alive: bool) -> void:
	"""接收BOSS状态同步（客户端）"""
	hp = hp_val
	phase = phase_val
	global_position = Vector3(pos_x, pos_y, pos_z)
	is_alive = alive

func _sync_state() -> void:
	"""发送BOSS状态给所有客户端（仅房主调用）"""
	var net = get_node("/root/NetworkManager") if has_node("/root/NetworkManager") else null
	if net and net.is_host():
		rpc("sync_boss_state", hp, phase, global_position.x, global_position.y, global_position.z, is_alive)

# ==================== 碰撞检测 ====================

func _on_hitbox_entered(body: Node) -> void:
	if body.is_in_group("player") and is_alive:
		take_damage(20)  # 默认攻击力，实际应从玩家读取

# ==================== 存档接口 ====================

func get_save_data() -> Dictionary:
	return {
		"boss_type": boss_type,
		"position": [global_position.x, global_position.y, global_position.z],
		"hp": hp,
		"max_hp": max_hp,
		"phase": phase,
		"is_alive": is_alive,
	}

func load_save_data(data: Dictionary) -> void:
	boss_type = data.get("boss_type", boss_type)
	if data.has("position"):
		var pos = data["position"]
		if pos is Array and pos.size() >= 3:
			global_position = Vector3(pos[0], pos[1], pos[2])
	hp = data.get("hp", max_hp)
	max_hp = data.get("max_hp", max_hp)
	phase = data.get("phase", Phase.ONE)
	is_alive = data.get("is_alive", true)
	config = get_boss_config(boss_type)
