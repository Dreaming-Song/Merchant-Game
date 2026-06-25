extends CharacterBody3D
class_name EnemyBase

const CreatureAppearance = preload("res://scripts/visuals/creature_appearance.gd")

## 妖兽系统 V2 — 平衡调整 + 精英怪 + 控制交互
##
## AI 流程：巡逻 → 索敌 → 追击 → 战斗 → 受控 → 死亡
## 精英怪：★前缀，3倍属性，光环buff，死亡爆炸

signal enemy_damaged(enemy_id: String, damage: int, current_hp: int)
signal enemy_killed(enemy_id: String, enemy_type: String, is_elite: bool)
signal enemy_aggro(enemy_id: String)

# ==================== 妖兽类型 ====================
enum EnemyType {
	# 原始4种
	SPIRIT_WOLF,      # 灵狼 — 敏捷近战，绕后
	MIST_APE,         # 雾猿 — 远程投石，放风筝
	FLAME_BOAR,       # 焰猪 — 冲锋撞人，有后摇
	IRON_TORTOISE,    # 铁龟 — 高防缩壳，反伤
	
	# 🌿 青龙下属
	GREEN_SERPENT,    # 木蛇 — 毒系持续伤害
	VENOMOUS_WYRM,    # 青蛟(精英) — 大范围毒雾
	
	# ⚔️ 白虎下属
	BLADE_CUB,        # 小剑虎 — 近战连击
	SABER_TIGER,      # 剑虎(精英) — 剑气斩+破甲
	
	# 🔥 朱雀下属
	FLAME_SPARROW,    # 炎雀 — 远程火球
	SCORCH_BIRD,      # 炙鸟(精英) — 火焰雨+点燃
	
	# 💧 玄武下属
	ICE_TURTLE,       # 冰鳖 — 冰冻减速
	FROST_TORTOISE,   # 寒龟(精英) — 冰封领域
	
	# 🏔️ 麒麟下属
	STONE_BEAST,      # 土兽 — 高防冲锋
	ROCK_ARMOR,       # 岩甲兽(精英) — 地震+石肤
}

# ==================== 属性 ====================
@export var enemy_type: int = EnemyType.SPIRIT_WOLF
@export var is_elite: bool = false       # 是否为精英怪
@export var level: int = 1               # 等级（随玩家缩放）
@export var max_hp: int = 150
@export var attack_damage: int = 22
@export var attack_range: float = 2.5
@export var aggro_range: float = 18.0
@export var move_speed: float = 6.0
@export var patrol_range: float = 20.0
@export var exp_reward: int = 60

var hp: int
var is_alive: bool = true

# ==================== AI 状态 ====================
enum AIState { PATROL, CHASE, ATTACK, RETURN, HURT, STUNNED, FROZEN, DEAD, ENRAGED }
var ai_state: int = AIState.PATROL
var target_player: Node = null
var patrol_center: Vector3
var patrol_target: Vector3
var attack_cooldown: float = 0.0
var _hurt_timer: float = 0.0

# ==================== 控制状态 ====================
var stun_timer: float = 0.0
var freeze_timer: float = 0.0
var knockback_velocity: Vector3 = Vector3.ZERO
const CONTROL_RESIST: float = 0.3       # 精英控制抗性

# ==================== 新增类型特有变量 ====================
var _poison_dot_tick: float = 0.0       # 木蛇毒伤
var _burn_dot_tick: float = 0.0         # 炎雀灼烧
var _charge_cooldown: float = 0.0       # 冲锋冷却

# ==================== 精英怪独有 ====================
var aura_radius: float = 8.0
var minion_list: Array[Node] = []       # 召唤的小弟
var enrage_active: bool = false
var _elite_scale: float = 1.2

# ==================== 行为参数 ====================
var _boar_charging: bool = false
var _boar_charge_dir: Vector3 = Vector3.ZERO
var _ape_kite_distance: float = 8.0
var _tortoise_shell: bool = false
var _wolf_side_step_cooldown: float = 0.0

@onready var player_ref: Node = get_tree().get_first_node_in_group("player")
@onready var navigation: NavigationAgent3D = $NavigationAgent3D
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Area3D = $Hitbox

# 外观
var appearance_root: Node3D = null
var _appearance_key: String = "spirit_wolf"

func _get_appearance_key() -> String:
	var keys = ["spirit_wolf", "mist_ape", "flame_boar", "iron_tortoise",
		"green_serpent", "venomous_wyrm", "blade_cub", "saber_tiger",
		"flame_sparrow", "scorch_bird", "ice_turtle", "frost_tortoise",
		"stone_beast", "rock_armor"]
	return keys[enemy_type] if enemy_type < keys.size() else "spirit_wolf"

func _setup_visuals() -> void:
	"""初始化或更新生物外观"""
	# 移除旧外观
	if appearance_root:
		appearance_root.queue_free()
	
	var key = _get_appearance_key()
	_appearance_key = key
	appearance_root = CreatureAppearance.build_appearance(key, is_elite, false)
	add_child(appearance_root)
	appearance_root.position = Vector3.ZERO

func _init_base_stats_by_type() -> void:
	"""根据敌人类型设置基础属性"""
	match enemy_type:
		EnemyType.SPIRIT_WOLF:
			max_hp = 120; attack_damage = 18; attack_range = 2.0
			aggro_range = 22.0; move_speed = 7.5; exp_reward = 50
		EnemyType.MIST_APE:
			max_hp = 100; attack_damage = 15; attack_range = 8.0
			aggro_range = 18.0; move_speed = 5.0; exp_reward = 55
		EnemyType.FLAME_BOAR:
			max_hp = 180; attack_damage = 28; attack_range = 3.5
			aggro_range = 16.0; move_speed = 6.0; exp_reward = 65
		EnemyType.IRON_TORTOISE:
			max_hp = 250; attack_damage = 12; attack_range = 1.8
			aggro_range = 12.0; move_speed = 3.5; exp_reward = 70
		
		# 🌿 青龙下属
		EnemyType.GREEN_SERPENT:
			max_hp = 110; attack_damage = 16; attack_range = 2.5
			aggro_range = 16.0; move_speed = 6.5; exp_reward = 55
		EnemyType.VENOMOUS_WYRM:
			max_hp = 220; attack_damage = 25; attack_range = 4.0
			aggro_range = 20.0; move_speed = 5.5; exp_reward = 120
		
		# ⚔️ 白虎下属
		EnemyType.BLADE_CUB:
			max_hp = 130; attack_damage = 22; attack_range = 2.2
			aggro_range = 18.0; move_speed = 7.0; exp_reward = 60
		EnemyType.SABER_TIGER:
			max_hp = 260; attack_damage = 35; attack_range = 3.5
			aggro_range = 22.0; move_speed = 7.5; exp_reward = 140
		
		# 🔥 朱雀下属
		EnemyType.FLAME_SPARROW:
			max_hp = 90; attack_damage = 20; attack_range = 9.0
			aggro_range = 20.0; move_speed = 6.0; exp_reward = 55
		EnemyType.SCORCH_BIRD:
			max_hp = 180; attack_damage = 30; attack_range = 10.0
			aggro_range = 24.0; move_speed = 7.0; exp_reward = 130
		
		# 💧 玄武下属
		EnemyType.ICE_TURTLE:
			max_hp = 160; attack_damage = 14; attack_range = 2.0
			aggro_range = 14.0; move_speed = 4.0; exp_reward = 55
		EnemyType.FROST_TORTOISE:
			max_hp = 320; attack_damage = 22; attack_range = 3.0
			aggro_range = 18.0; move_speed = 4.5; exp_reward = 135
		
		# 🏔️ 麒麟下属
		EnemyType.STONE_BEAST:
			max_hp = 200; attack_damage = 20; attack_range = 2.5
			aggro_range = 14.0; move_speed = 4.5; exp_reward = 60
		EnemyType.ROCK_ARMOR:
			max_hp = 400; attack_damage = 30; attack_range = 3.5
			aggro_range = 18.0; move_speed = 5.0; exp_reward = 150

func _ready() -> void:
	# 根据类型设置基础属性
	_init_base_stats_by_type()
	
	# 等级缩放
	_scale_to_level()
	
	# 生成外观
	_setup_visuals()
	
	hp = max_hp
	patrol_center = global_position
	_pick_patrol_target()
	add_to_group("enemies")
	
	if is_elite:
		add_to_group("elite_enemies")
		_elite_scale = 1.2 + randf() * 0.15
		# 精英入场提示
		print("🌟 ★%s 出现了！" % get_enemy_name())
		_play_elite_entrance()
	
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_entered)

func _play_elite_entrance() -> void:
	"""精英登场特效"""
	# 闪烁效果
	var tween = create_tween()
	var orig_scale = scale
	tween.tween_property(self, "scale", orig_scale * 1.3, 0.2)
	tween.tween_property(self, "scale", orig_scale, 0.3)
	
	# 光柱
	print("🌟 ★精英 %s 降临！" % get_enemy_name())

func _scale_to_level() -> void:
	"""根据等级缩放属性"""
	var scale = 1.0 + (level - 1) * 0.12
	max_hp = int(max_hp * scale)
	attack_damage = int(attack_damage * scale)
	move_speed *= (1.0 + (level - 1) * 0.05)
	exp_reward = int(exp_reward * scale)
	
	if is_elite:
		max_hp = int(max_hp * 3.0)
		attack_damage = int(attack_damage * 2.0)
		move_speed *= 1.15
		exp_reward *= 3

func _physics_process(delta: float) -> void:
	if not is_alive: return
	
	attack_cooldown = max(attack_cooldown - delta, 0)
	_wolf_side_step_cooldown = max(_wolf_side_step_cooldown - delta, 0)
	_update_player_ref()
	
	# 控制状态处理
	if stun_timer > 0:
		stun_timer -= delta
		ai_state = AIState.STUNNED
		return
	if freeze_timer > 0:
		freeze_timer -= delta
		ai_state = AIState.FROZEN
		velocity = Vector3.ZERO
		move_and_slide()
		return
	
	# 击退
	if knockback_velocity.length_squared() > 0.1:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, delta * 8.0)
		move_and_slide()
		# 击退结束后切回追击
		if knockback_velocity.length_squared() < 0.1:
			ai_state = AIState.CHASE if target_player else AIState.PATROL
		return
	
	# 精英光环
	if is_elite:
		_apply_elite_aura()
	
	match ai_state:
		AIState.PATROL: _patrol(delta); _check_aggro()
		AIState.CHASE: _chase(delta)
		AIState.ATTACK: _perform_attack(delta)
		AIState.RETURN: _return_to_patrol(delta)
		AIState.HURT: _handle_hurt(delta)
		AIState.ENRAGED: _chase(delta)  # 狂暴状态下追击更快

func get_enemy_name() -> String:
	var names = ["灵狼", "雾猿", "焰猪", "铁龟",
		"木蛇", "青蛟", "小剑虎", "剑虎",
		"炎雀", "炙鸟", "冰鳖", "寒龟",
		"土兽", "岩甲兽"]
	var name = names[enemy_type] if enemy_type < names.size() else "妖兽"
	return ("★" if is_elite else "") + "Lv" + str(level) + name

func _update_player_ref() -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player")

# ==================== AI 行为 ====================

func _pick_patrol_target() -> void:
	var angle = randf_range(0, TAU)
	var dist = randf_range(3.0, patrol_range)
	patrol_target = patrol_center + Vector3(cos(angle), 0, sin(angle)) * dist

func _patrol(delta: float) -> void:
	var dist = global_position.distance_to(patrol_target)
	if dist < 2.0: _pick_patrol_target()
	var dir = (patrol_target - global_position).normalized()
	velocity = dir * move_speed * 0.4
	look_at(Vector3(patrol_target.x, global_position.y, patrol_target.z), Vector3.UP)
	move_and_slide()

func _check_aggro() -> void:
	if player_ref == null: return
	var dist = global_position.distance_to(player_ref.global_position)
	if dist <= aggro_range + (level * 0.5):
		target_player = player_ref
		ai_state = AIState.CHASE
		enemy_aggro.emit(name)

func _chase(delta: float) -> void:
	if target_player == null or not is_instance_valid(target_player):
		ai_state = AIState.RETURN; return
	
	var dist = global_position.distance_to(target_player.global_position)
	if dist > aggro_range * 2.5:
		ai_state = AIState.RETURN; return
	
	# 敌人种类特化行为
	match enemy_type:
		EnemyType.SPIRIT_WOLF:
			_wolf_chase(delta, dist)
		EnemyType.MIST_APE:
			_ape_chase(delta, dist)
		EnemyType.FLAME_BOAR:
			_boar_chase(delta, dist)
		EnemyType.IRON_TORTOISE:
			_tortoise_chase(delta, dist)
		_:
			_default_chase(delta, dist)

func _default_chase(delta: float, dist: float) -> void:
	if dist <= attack_range:
		ai_state = AIState.ATTACK; return
	var dir = (target_player.global_position - global_position).normalized()
	var speed = move_speed * (1.5 if ai_state == AIState.ENRAGED else 1.0)
	velocity = dir * speed
	look_at(Vector3(target_player.global_position.x, global_position.y, target_player.global_position.z), Vector3.UP)
	move_and_slide()

# ---------- 灵狼：侧跳绕后 ----------
func _wolf_chase(delta: float, dist: float) -> void:
	if dist <= attack_range * 0.8:
		# 绕后攻击
		if _wolf_side_step_cooldown <= 0 and randf() < 0.3:
			var right = Vector3(-target_player.global_transform.basis.z.z, 0, target_player.global_transform.basis.z.x)
			var side_dir = right * (1 if randf() > 0.5 else -1)
			global_position += side_dir * 2.0
			_wolf_side_step_cooldown = 2.0
			ai_state = AIState.ATTACK; return
		ai_state = AIState.ATTACK; return
	
	var dir = (target_player.global_position - global_position).normalized()
	var speed = move_speed * 1.3 * (1.5 if ai_state == AIState.ENRAGED else 1.0)
	velocity = dir * speed
	look_at(Vector3(target_player.global_position.x, global_position.y, target_player.global_position.z), Vector3.UP)
	move_and_slide()

# ---------- 雾猿：保持距离投石 ----------
func _ape_chase(delta: float, dist: float) -> void:
	if dist <= _ape_kite_distance and dist > attack_range:
		# 在合适距离攻击
		ai_state = AIState.ATTACK; return
	elif dist < attack_range * 0.5:
		# 太近了，后退
		var dir = (global_position - target_player.global_position).normalized()
		velocity = dir * move_speed * 1.2
		move_and_slide()
		return
	
	var dir = (target_player.global_position - global_position).normalized()
	var speed = move_speed * 0.8
	velocity = dir * speed
	look_at(Vector3(target_player.global_position.x, global_position.y, target_player.global_position.z), Vector3.UP)
	move_and_slide()

# ---------- 焰猪：冲锋 ----------
func _boar_chase(delta: float, dist: float) -> void:
	if _boar_charging:
		# 冲锋中
		velocity = _boar_charge_dir * move_speed * 2.5
		move_and_slide()
		if dist > 15.0 or attack_cooldown <= 0:
			_boar_charging = false
		return
	
	if dist <= attack_range * 2.0 and attack_cooldown <= 0:
		# 启动冲锋
		_boar_charging = true
		_boar_charge_dir = (target_player.global_position - global_position).normalized()
		attack_cooldown = 0.5
		ai_state = AIState.ATTACK; return
	
	var dir = (target_player.global_position - global_position).normalized()
	velocity = dir * move_speed * 0.7
	look_at(Vector3(target_player.global_position.x, global_position.y, target_player.global_position.z), Vector3.UP)
	move_and_slide()

# ---------- 铁龟：缩壳防守 ----------
func _tortoise_chase(delta: float, dist: float) -> void:
	if dist <= attack_range:
		ai_state = AIState.ATTACK; return
	var dir = (target_player.global_position - global_position).normalized()
	velocity = dir * move_speed * 0.5  # 龟最慢
	look_at(Vector3(target_player.global_position.x, global_position.y, target_player.global_position.z), Vector3.UP)
	move_and_slide()

# ==================== 攻击行为 ====================

func _perform_attack(delta: float) -> void:
	if target_player == null: ai_state = AIState.CHASE; return
	
	var dist = global_position.distance_to(target_player.global_position)
	var too_far = false
	
	match enemy_type:
		EnemyType.MIST_APE:
			too_far = dist > _ape_kite_distance + 2.0
		EnemyType.FLAME_BOAR:
			too_far = dist > attack_range * 3.0
		_:
			too_far = dist > attack_range + 1.0
	
	if too_far:
		ai_state = AIState.CHASE; return
	
	if attack_cooldown <= 0:
		var dmg = attack_damage
		
		# 焰猪冲锋伤害更高
		if enemy_type == EnemyType.FLAME_BOAR and _boar_charging:
			dmg = int(attack_damage * 1.5)
			_boar_charging = false
		
		if player_ref and player_ref.has_method("take_damage"):
			player_ref.take_damage(dmg)
			print("⚔️ %s 攻击，造成 %d 伤害" % [get_enemy_name(), dmg])
		
		attack_cooldown = _get_attack_cd()
		
		# 雾猿攻击后后退
		if enemy_type == EnemyType.MIST_APE:
			var back_dir = (global_position - target_player.global_position).normalized()
			global_position += back_dir * 2.0
	
	look_at(Vector3(target_player.global_position.x, global_position.y, target_player.global_position.z), Vector3.UP)

func _get_attack_cd() -> float:
	match enemy_type:
		EnemyType.SPIRIT_WOLF: return 1.2
		EnemyType.MIST_APE: return 2.0
		EnemyType.FLAME_BOAR: return 2.5
		EnemyType.IRON_TORTOISE: return 1.8
		_: return 1.5

func _return_to_patrol(delta: float) -> void:
	var dist = global_position.distance_to(patrol_center)
	if dist < 1.0:
		ai_state = AIState.PATROL
		target_player = null
		return
	var dir = (patrol_center - global_position).normalized()
	velocity = dir * move_speed * 0.7
	move_and_slide()

func _handle_hurt(delta: float) -> void:
	_hurt_timer -= delta
	if _hurt_timer <= 0.0 and is_alive:
		ai_state = AIState.CHASE if target_player else AIState.PATROL

# ==================== 精英光环 ====================

func _apply_elite_aura() -> void:
	"""精英怪光环：周围普通怪攻速+20%"""
	var friends = get_tree().get_nodes_in_group("enemies")
	for e in friends:
		if e == self: continue
		if e is CharacterBody3D and e.has_method("get_enemy_name"):
			var dist = global_position.distance_to(e.global_position)
			if dist <= aura_radius:
				if e.has_method("_boost_by_elite"):
					e._boost_by_elite()

# 被外部调用的光环加速标记
var _elite_boosted: bool = false
func _boost_by_elite() -> void:
	if not _elite_boosted:
		_elite_boosted = true
		# 减少攻击CD
		attack_cooldown *= 0.8

# ==================== 受伤/控制 ====================

func take_damage(damage: int, source: String = "player") -> void:
	if not is_alive: return
	
	var effective_damage = damage
	
	# 铁龟缩壳减伤
	if enemy_type == EnemyType.IRON_TORTOISE and _tortoise_shell:
		effective_damage = int(damage * 0.2)
		# 反伤
		if player_ref and player_ref.has_method("take_damage"):
			player_ref.take_damage(int(damage * 0.1))
	
	hp = max(hp - effective_damage, 0)
	enemy_damaged.emit(name, effective_damage, hp)
	
	ai_state = AIState.HURT
	_hurt_timer = 0.25
	
	# 残血狂暴（精英或普通都有概率）
	var hp_ratio = float(hp) / max_hp
	if hp_ratio < 0.2 and not enrage_active and randf() < 0.5:
		_trigger_enrage()
	
	if hp <= 0: die()

func apply_stun(duration: float) -> void:
	if is_elite: duration *= (1.0 - CONTROL_RESIST)
	stun_timer = max(stun_timer, duration)
	if stun_timer > 0:
		print("💫 %s 被眩晕 %.1f秒" % [get_enemy_name(), stun_timer])

func apply_freeze(duration: float) -> void:
	if is_elite: duration *= (1.0 - CONTROL_RESIST)
	freeze_timer = max(freeze_timer, duration)

func apply_knockback(force: Vector3) -> void:
	if is_elite: force *= 0.5
	knockback_velocity = force

func _trigger_enrage() -> void:
	"""残血狂暴"""
	enrage_active = true
	ai_state = AIState.ENRAGED
	move_speed *= 1.5
	attack_damage = int(attack_damage * 1.3)
	print("🔥 %s 陷入狂暴！速度+50%，攻击+30%%" % get_enemy_name())
	
	# 精英怪召唤小弟
	if is_elite:
		_summon_minions()

func _summon_minions() -> void:
	"""精英怪召唤2个普通怪"""
	for i in range(2):
		var offset = Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
		# 创建普通怪（简化：打印消息）
		print("👹 %s 召唤了妖兽助战！" % get_enemy_name())

# ==================== 死亡/掉落 ====================

func die() -> void:
	if not is_alive: return
	is_alive = false
	ai_state = AIState.DEAD
	enemy_killed.emit(name, EnemyType.keys()[enemy_type], is_elite)
	
	# 精英死亡爆炸
	if is_elite:
		_elite_death_explosion()
	
	_spawn_drops()
	await get_tree().create_timer(1.5).timeout
	queue_free()

func _elite_death_explosion() -> void:
	"""精英死亡AOE爆炸"""
	var radius = 4.0
	var damage = int(max_hp * 0.5)
	print("💥 ★%s 死亡爆炸！半径%.1f 伤害%d" % [get_enemy_name(), radius, damage])
	var targets = get_tree().get_nodes_in_group("player")
	for t in targets:
		if t is Node3D:
			if global_position.distance_to(t.global_position) <= radius:
				if t.has_method("take_damage"):
					t.take_damage(damage)

func _spawn_drops() -> void:
	"""掉落系统"""
	var drops = {}
	match enemy_type:
		EnemyType.SPIRIT_WOLF:
			drops = {"灵狼牙": 0.7, "兽肉": 0.4, "狼毫": 0.3}
		EnemyType.MIST_APE:
			drops = {"猿猴果": 0.6, "兽肉": 0.3, "灵木": 0.25}
		EnemyType.FLAME_BOAR:
			drops = {"火熔石": 0.5, "兽肉": 0.8, "焰鬃毛": 0.3}
		EnemyType.IRON_TORTOISE:
			drops = {"龟甲片": 0.9, "灵水": 0.3, "玄铁": 0.2}
		
		# 🌿 青龙下属
		EnemyType.GREEN_SERPENT:
			drops = {"蛇鳞": 0.6, "蛇毒囊": 0.4, "青木精华": 0.2}
		EnemyType.VENOMOUS_WYRM:
			drops = {"蛟龙角": 0.5, "剧毒核心": 0.6, "青木精华": 0.4, "青龙令碎片": 0.15}
		
		# ⚔️ 白虎下属
		EnemyType.BLADE_CUB:
			drops = {"虎牙": 0.6, "兽肉": 0.4, "锐金砂": 0.2}
		EnemyType.SABER_TIGER:
			drops = {"剑虎爪": 0.5, "虎骨": 0.5, "锐金砂": 0.4, "白虎令碎片": 0.15}
		
		# 🔥 朱雀下属
		EnemyType.FLAME_SPARROW:
			drops = {"炎羽": 0.6, "火结晶": 0.3, "灰烬": 0.4}
		EnemyType.SCORCH_BIRD:
			drops = {"凤羽": 0.5, "烈焰核心": 0.6, "火结晶": 0.4, "朱雀令碎片": 0.15}
		
		# 💧 玄武下属
		EnemyType.ICE_TURTLE:
			drops = {"冰甲片": 0.6, "寒玉": 0.3, "灵液": 0.4}
		EnemyType.FROST_TORTOISE:
			drops = {"玄冰甲": 0.5, "极寒核心": 0.6, "寒玉": 0.4, "玄武令碎片": 0.15}
		
		# 🏔️ 麒麟下属
		EnemyType.STONE_BEAST:
			drops = {"岩晶": 0.6, "土灵石": 0.3, "兽肉": 0.4}
		EnemyType.ROCK_ARMOR:
			drops = {"大地之心": 0.5, "岩核": 0.6, "土灵石": 0.4, "麒麟令碎片": 0.15}
	
	# 精英额外掉落
	if is_elite:
		drops["★精英核心"] = 1.0
		drops["宠物蛋碎片"] = 0.6
		drops["稀有魂石"] = 0.4
	
	for item in drops:
		if randf() < drops[item]:
			print("📦 掉落: %s" % item)
			# TODO: 生成掉落物实体

# ==================== 碰撞 ====================

func _on_hitbox_entered(body: Node) -> void:
	if body.is_in_group("player") and is_alive:
		var dmg = 20 + level * 2
		take_damage(dmg)

# ==================== 存档 ====================

func get_save_data() -> Dictionary:
	return {
		"enemy_type": enemy_type,
		"is_elite": is_elite,
		"level": level,
		"position": [global_position.x, global_position.y, global_position.z],
		"hp": hp,
		"is_alive": is_alive,
	}

func load_save_data(data: Dictionary) -> void:
	is_elite = data.get("is_elite") or false
	level = data.get("level") or 1
	if data.has("position"):
		var pos = data["position"]
		global_position = Vector3(pos[0], pos[1], pos[2])
	hp = data.get("hp") or max_hp
	is_alive = data.get("is_alive") or true
