extends CharacterBody3D
## 灵宠系统 V2 — 跟随 + 战斗 + 骑乘 + 孵化
##
## 功能：
## - 跟随玩家、空闲表情、喂食互动、技能解锁
## - 载人飞行/陆地骑乘
## - 战斗辅助：自动攻击附近敌人
## - 从孵化台孵化后自动认主

signal pet_level_up(pet_name: String, new_level: int)
signal skill_unlocked(pet_name: String, skill_name: String)
signal pet_attack(pet_name: String, damage: int, target_name: String)
signal pet_mount_changed(pet_name: String, is_mounted: bool)

# ==================== 灵宠类型 ====================
enum PetType { CRANE, FOX, PANDA, PIXIU, 
	AZURE_DRAGON, WHITE_TIGER, VERMILION_BIRD, BLACK_WARRIOR, GOLDEN_QILIN }

# ==================== 类型映射 ====================
class PetTypeMap:
	static func get_type(name: String) -> int:
		match name:
			"crane": return PetType.CRANE
			"fox": return PetType.FOX
			"panda": return PetType.PANDA
			"pixiu": return PetType.PIXIU
			"azure_dragon": return PetType.AZURE_DRAGON
			"white_tiger": return PetType.WHITE_TIGER
			"vermilion_bird": return PetType.VERMILION_BIRD
			"black_warrior": return PetType.BLACK_WARRIOR
			"golden_qilin": return PetType.GOLDEN_QILIN
		return PetType.CRANE

# ==================== 属性 ====================
@export var pet_type: int = PetType.CRANE
@export var pet_name: String = "灵宠"

# 基础属性（根据类型不同）
@export var move_speed: float = 8.0
@export var follow_distance: float = 3.0
@export var stop_distance: float = 1.5
@export var level: int = 1
@export var exp: int = 0
@export var exp_to_next: int = 100
@export var loyalty: int = 50

# 战斗属性
@export var pet_attack_damage: int = 10
@export var pet_attack_range: float = 2.5
@export var pet_attack_cooldown: float = 1.5
@export var pet_max_hp: int = 200
@export var pet_hp: int = 200

# 养成
var hunger: int = 100
var unlocked_skills: Array = []
var is_mount_mode: bool = false
var is_riding: bool = false

# ==================== 节点 ====================
@onready var player: Node3D = null
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# 外观
var appearance_root: Node3D = null
var _pet_key: String = "crane"

func _get_pet_key() -> String:
	var keys = ["crane", "fox", "panda", "pixiu",
		"azure_dragon", "white_tiger", "vermilion_bird", "black_warrior", "golden_qilin"]
	return keys[pet_type] if pet_type < keys.size() else "crane"

func _setup_pet_visuals() -> void:
	"""初始化灵宠外观"""
	if appearance_root:
		appearance_root.queue_free()
	
	var key = _get_pet_key()
	_pet_key = key
	appearance_root = CreatureAppearance.build_appearance(key, false, false)
	add_child(appearance_root)
	appearance_root.position = Vector3.ZERO

# AI 状态
enum PetState { FOLLOW, IDLE, EATING, FLYING_MOUNT, GROUND_MOUNT, BATTLE }
var current_state: int = PetState.FOLLOW

# 战斗
var _attack_cooldown: float = 0.0
var _current_target: Node = null
var _idle_emote_timer: float = 0.0
var _idle_emote_interval: float = 6.0

# ==================== 类型配置 ====================
static func get_pet_config(p_type: int) -> Dictionary:
	match p_type:
		PetType.CRANE:
			return {"name": "仙鹤", "speed": 8.0, "atk": 8, "hp": 150, "desc": "优雅飞行坐骑"}
		PetType.FOX:
			return {"name": "灵狐", "speed": 7.0, "atk": 12, "hp": 180, "desc": "采集辅助+低战"}
		PetType.PANDA:
			return {"name": "竹熊", "speed": 5.0, "atk": 25, "hp": 400, "desc": "坦克肉盾"}
		PetType.PIXIU:
			return {"name": "貔貅", "speed": 7.5, "atk": 20, "hp": 300, "desc": "战力增幅"}
		PetType.AZURE_DRAGON:
			return {"name": "青龙", "speed": 10.0, "atk": 35, "hp": 500, "desc": "木系神兽·治愈"}
		PetType.WHITE_TIGER:
			return {"name": "白虎", "speed": 12.0, "atk": 45, "hp": 450, "desc": "金系神兽·锐利"}
		PetType.VERMILION_BIRD:
			return {"name": "朱雀", "speed": 14.0, "atk": 40, "hp": 350, "desc": "火系神兽·涅槃"}
		PetType.BLACK_WARRIOR:
			return {"name": "玄武", "speed": 4.0, "atk": 20, "hp": 800, "desc": "水系神兽·铁壁"}
		PetType.GOLDEN_QILIN:
			return {"name": "麒麟", "speed": 9.0, "atk": 50, "hp": 600, "desc": "土系神兽·全才"}
		_: return {"name": "灵宠", "speed": 8.0, "atk": 10, "hp": 200}

func _ready() -> void:
	var cfg = get_pet_config(pet_type)
	move_speed = cfg.get("speed") or 8.0
	pet_attack_damage = cfg.get("atk") or 10
	pet_max_hp = cfg.get("hp") or 200
	pet_hp = pet_max_hp
	
	# 生成程序化外观
	_setup_pet_visuals()
	
	add_to_group("pets")
	player = get_tree().get_first_node_in_group("player")
	move_speed += level * 0.4
	_idle_emote_interval = randf_range(4.0, 10.0)
	
	# 初始技能
	match pet_type:
		PetType.AZURE_DRAGON: unlocked_skills.append("木灵治愈")
		PetType.WHITE_TIGER: unlocked_skills.append("金刃突击")
		PetType.VERMILION_BIRD: unlocked_skills.append("火羽飞射")
		PetType.BLACK_WARRIOR: unlocked_skills.append("玄冰壁垒")
		PetType.GOLDEN_QILIN: unlocked_skills.append("祥瑞之光")

func _physics_process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return
	
	_attack_cooldown = max(_attack_cooldown - delta, 0)
	_update_idle_emote(delta)
	
	# 载人模式用玩家的输入
	if is_mount_mode and is_riding:
		_handle_mount_controls(delta)
		return
	
	# 战斗模式
	if current_state == PetState.BATTLE and _current_target:
		_battle_behavior(delta)
		return
	
	# 跟随模式下自动索敌
	if current_state != PetState.FOLLOW:
		current_state = PetState.FOLLOW
	
	if current_state == PetState.FOLLOW:
		_update_follow(delta)
		# 自动战斗检测
		_auto_detect_enemy()

# ===================== 跟随 =====================

func _update_follow(delta: float) -> void:
	if player == null: return
	var dist = global_position.distance_to(player.global_position)
	
	if dist > follow_distance:
		var target_dir = (player.global_position - global_position).normalized()
		target_dir.y = 0
		if target_dir.length() > 0:
			var target_pos = global_position + target_dir * move_speed * delta
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(global_position, target_pos)
			var result = space_state.intersect_ray(query)
			if result.is_empty():
				global_position = target_pos
			else:
				target_dir = target_dir.rotated(Vector3.UP, randf_range(-1.0, 1.0))
				global_position += target_dir * move_speed * delta * 0.5
		
		var look_target = player.global_position
		look_target.y = global_position.y
		look_at(look_target, Vector3.UP)

# ===================== 战斗 =====================

func _auto_detect_enemy() -> void:
	"""自动检测附近的敌人"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest = null
	var nearest_dist = 15.0  # 索敌范围
	
	for e in enemies:
		if not e.has_method("is_alive") or not e.is_alive:
			continue
		var dist = global_position.distance_to(e.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = e
	
	if nearest and player:
		var player_dist = player.global_position.distance_to(nearest.global_position)
		if player_dist < 12.0:  # 玩家也靠近时才参战
			_current_target = nearest
			current_state = PetState.BATTLE
			print("⚔️ %s 进入战斗！目标: %s" % [pet_name, nearest.get_enemy_name() if nearest.has_method("get_enemy_name") else "?"])

func _battle_behavior(delta: float) -> void:
	"""战斗行为"""
	if _current_target == null or not is_instance_valid(_current_target) or (_current_target.has_method("is_alive") and not _current_target.is_alive):
		_current_target = null
		current_state = PetState.FOLLOW
		return
	
	var dist = global_position.distance_to(_current_target.global_position)
	
	# 追击敌人
	if dist > pet_attack_range:
		var dir = (_current_target.global_position - global_position).normalized()
		velocity = dir * move_speed * 1.2
		move_and_slide()
	else:
		# 攻击
		if _attack_cooldown <= 0:
			_perform_pet_attack()
	
	look_at(Vector3(_current_target.global_position.x, global_position.y, _current_target.global_position.z), Vector3.UP)

func _perform_pet_attack() -> void:
	"""宠物攻击"""
	if _current_target == null: return
	
	var dmg = pet_attack_damage + int(level * 1.5)
	
	# 类型特化
	match pet_type:
		PetType.PANDA: dmg = int(dmg * 1.3)
		PetType.WHITE_TIGER: dmg = int(dmg * 1.5)
		PetType.GOLDEN_QILIN: dmg = int(dmg * 1.2)
	
	if _current_target.has_method("take_damage"):
		_current_target.take_damage(dmg)
		pet_attack.emit(pet_name, dmg, _current_target.name)
		print("🐾 %s 攻击 %s，造成 %d 伤害" % [pet_name, _current_target.name, dmg])
		
		# 神兽技能
		_cast_pet_ability(_current_target)
	
	_attack_cooldown = pet_attack_cooldown / (1.0 + level * 0.05)

func _cast_pet_ability(target: Node) -> void:
	"""释放宠物技能（概率触发）"""
	if randf() > 0.3: return  # 30%概率
	
	match pet_type:
		PetType.AZURE_DRAGON:
			if "木灵治愈" in unlocked_skills and player:
				player.heal(20 + level * 2)
				print("💚 %s 释放【木灵治愈】" % pet_name)
		PetType.WHITE_TIGER:
			if "金刃突击" in unlocked_skills:
				target.take_damage(int(pet_attack_damage * 0.5))
				print("⚡ %s 释放【金刃突击】" % pet_name)
		PetType.VERMILION_BIRD:
			if "火羽飞射" in unlocked_skills:
				target.take_damage(int(pet_attack_damage * 0.3))
				print("🔥 %s 释放【火羽飞射】" % pet_name)
		PetType.BLACK_WARRIOR:
			if "玄冰壁垒" in unlocked_skills:
				pet_hp = min(pet_hp + 30, pet_max_hp)
				print("🛡️ %s 释放【玄冰壁垒】" % pet_name)
		PetType.GOLDEN_QILIN:
			if "祥瑞之光" in unlocked_skills and player:
				player.heal(30 + level * 3)
				pet_hp = min(pet_hp + 20, pet_max_hp)
				print("✨ %s 释放【祥瑞之光】" % pet_name)
		_:
			pass

# ===================== 骑乘 =====================

func _handle_mount_controls(delta: float) -> void:
	if player == null: return
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var camera = player.get_node("CameraPivot/Camera3D") if player.has_node("CameraPivot/Camera3D") else null
	var forward = -camera.global_transform.basis.z if camera else -player.global_transform.basis.z
	var right = camera.global_transform.basis.x if camera else player.global_transform.basis.x
	
	var fly_dir = (forward * input_dir.y + right * input_dir.x).normalized()
	
	if pet_type == PetType.CRANE or pet_type == PetType.AZURE_DRAGON or pet_type == PetType.VERMILION_BIRD:
		# 飞行骑乘
		velocity = fly_dir * move_speed * 1.5
		if Input.is_action_pressed("jump"):
			velocity.y += 5.0
		if Input.is_key_pressed(KEY_CTRL):
			velocity.y -= 5.0
	else:
		# 陆地骑乘
		velocity = fly_dir * move_speed * (1.0 if not input_dir else 1.0)
		velocity.y = -9.8 * delta if is_on_floor() else velocity.y - 9.8 * delta
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = 5.0
	
	move_and_slide()
	
	# 同步玩家位置
	if player.get_parent() != self:
		player.reparent(self)
	player.global_position = global_position + Vector3(0, 1.5, -0.5)

func can_mount() -> bool:
	return "载人飞行" in unlocked_skills or pet_type in [
		PetType.AZURE_DRAGON, PetType.WHITE_TIGER, 
		PetType.VERMILION_BIRD, PetType.BLACK_WARRIOR, PetType.GOLDEN_QILIN,
		PetType.PIXIU, PetType.PANDA
	]

func toggle_mount() -> bool:
	if not can_mount(): return false
	
	is_mount_mode = not is_mount_mode
	is_riding = is_mount_mode
	
	if is_mount_mode:
		current_state = PetState.FLYING_MOUNT if pet_type in [PetType.CRANE, PetType.AZURE_DRAGON, PetType.VERMILION_BIRD] else PetState.GROUND_MOUNT
	else:
		current_state = PetState.FOLLOW
		if player.get_parent() == self:
			player.reparent(get_tree().current_scene)
	
	pet_mount_changed.emit(pet_name, is_mount_mode)
	return true

# ===================== 空闲表情 =====================

func _update_idle_emote(delta: float) -> void:
	if current_state == PetState.FLYING_MOUNT or current_state == PetState.GROUND_MOUNT:
		return
	
	_idle_emote_timer += delta
	if _idle_emote_timer < _idle_emote_interval: return
	_idle_emote_timer = 0.0
	_idle_emote_interval = randf_range(5.0, 12.0)
	
	if player and global_position.distance_to(player.global_position) > 8.0: return
	
	var emotes = ["look_around", "scratch", "stretch", "happy_jump", "sniff"]
	var emote = emotes[randi() % emotes.size()]
	if animation_player and animation_player.has_animation(emote):
		if not animation_player.is_playing():
			animation_player.play(emote)
	if emote == "happy_jump" and appearance_root:
		appearance_root.modulate = Color(1.2, 1.2, 1.0)
		get_tree().create_timer(0.3).timeout.connect(func():
			if is_instance_valid(appearance_root): appearance_root.modulate = Color.WHITE)

# ===================== 喂食互动 =====================

func feed(food_type: int) -> Dictionary:
	var result = {"loyalty_change": 0, "message": ""}
	if hunger <= 0:
		result["message"] = pet_name + "已经饱了"
		return result
	hunger = max(hunger - 20, 0)
	
	if food_type in [1, 2]:  # 喜欢的食物
		loyalty = min(loyalty + 10, 100)
		exp += 30
		result["loyalty_change"] = 10
		result["message"] = pet_name + "很喜欢！亲密度+10"
	else:
		loyalty = min(loyalty + 3, 100)
		exp += 10
		result["loyalty_change"] = 3
		result["message"] = pet_name + "吃了一些"
	
	_check_level_up()
	_check_skill_unlock()
	return result

func _check_level_up() -> void:
	while exp >= exp_to_next:
		exp -= exp_to_next
		level += 1
		exp_to_next = int(exp_to_next * 1.5)
		move_speed += 0.3
		pet_attack_damage += 2
		pet_max_hp += 20
		pet_hp = pet_max_hp
		pet_level_up.emit(pet_name, level)

func _check_skill_unlock() -> void:
	var thresholds = [
		{"loyalty": 30, "skill": "跟随加速"},
		{"loyalty": 50, "skill": "采集助手"},
		{"loyalty": 70, "skill": "载人飞行"},
		{"loyalty": 90, "skill": "辅助战斗"},
	]
	for t in thresholds:
		if loyalty >= t["loyalty"] and not (t["skill"] in unlocked_skills):
			unlocked_skills.append(t["skill"])
			skill_unlocked.emit(pet_name, t["skill"])
			if t["skill"] == "载人飞行":
				is_mount_mode = true

# ===================== 宠物受伤 =====================

func pet_take_damage(damage: int) -> void:
	pet_hp = max(pet_hp - damage, 0)
	if pet_hp <= 0:
		_pet_die()

func _pet_die() -> void:
	print("💔 %s 战败了，5秒后复活..." % pet_name)
	visible = false
	await get_tree().create_timer(5.0).timeout
	pet_hp = pet_max_hp
	visible = true
	print("💚 %s 复活！" % pet_name)

# ===================== 信息 =====================

func get_pet_info() -> Dictionary:
	return {
		"name": pet_name, "type": pet_type, "level": level, "exp": exp,
		"exp_to_next": exp_to_next, "loyalty": loyalty, "hunger": hunger,
		"skills": unlocked_skills, "can_mount": can_mount(),
		"hp": pet_hp, "max_hp": pet_max_hp, "atk": pet_attack_damage,
		"config": get_pet_config(pet_type),
	}

# ===================== 存档 =====================

func get_save_data() -> Dictionary:
	return {
		"pet_type": pet_type, "pet_name": pet_name,
		"level": level, "exp": exp, "loyalty": loyalty, "hunger": hunger,
		"unlocked_skills": unlocked_skills, "pet_hp": pet_hp,
	}

func load_save_data(data: Dictionary) -> void:
	pet_type = data.get("pet_type") or PetType.CRANE
	pet_name = data.get("pet_name") or "灵宠"
	level = data.get("level") or 1
	exp = data.get("exp") or 0
	loyalty = data.get("loyalty") or 50
	hunger = data.get("hunger") or 100
	unlocked_skills = data.get("unlocked_skills") or []
	pet_hp = data.get("pet_hp") or pet_max_hp
	
	var cfg = get_pet_config(pet_type)
	pet_attack_damage = cfg.get("atk") or 10 + level * 2
	pet_max_hp = cfg.get("hp") or 200 + level * 20
