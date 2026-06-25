extends StaticBody3D
## 可开启的宝箱/容器
##
## 按 E 打开，显示物品列表（或弹出背包 UI）
## 支持：锁定/解锁、随机战利品、动画开启

class_name ChestInteractable

signal chest_opened(chest_id: String)
signal chest_looted(chest_id: String)

# ==================== 配置 ====================
@export var chest_name: String = "宝箱"
@export var is_locked: bool = false
@export var lock_difficulty: int = 1  # 开锁难度
@export var loot_table: Array[Dictionary] = []  # 战利品表
@export var fixed_loot: Array[Dictionary] = []  # 固定掉落
@export var is_once_only: bool = true  # 只能开一次
@export var open_animation_time: float = 0.5

# ==================== 状态 ====================
var is_opened: bool = false
var is_open: bool = false  # 当前盖子弹起状态
var _original_rotation: Vector3

func _ready() -> void:
	add_to_group("interactables")
	_original_rotation = rotation

# ==================== 交互接口 ====================

func interact(player: Node) -> void:
	"""玩家交互"""
	if is_once_only and is_opened:
		print("⚠️ %s 已经被打开了" % chest_name)
		return
	
	if is_locked:
		_try_unlock(player)
		return
	
	_open_chest(player)

func _try_unlock(player: Node) -> void:
	"""尝试开锁"""
	# TODO: 集成开锁小游戏
	var gm = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	var player_level = gm.realm.get_current_realm() if gm else 0
	
	if player_level >= lock_difficulty:
		print("🔓 开锁成功！")
		is_locked = false
		_open_chest(player)
	else:
		print("🔒 境界不足，无法开锁（需要 %d 级）" % lock_difficulty)

func _open_chest(player: Node) -> void:
	"""打开宝箱"""
	is_opened = true
	is_open = true
	chest_opened.emit(name)
	
	# 开启动画（盖子旋转）
	var tween = create_tween()
	tween.tween_property(self, "rotation", _original_rotation + Vector3(-0.5, 0, 0), open_animation_time)
	
	# 生成物品
	var items = _generate_loot()
	
	# 添加到玩家背包
	var gm = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	if gm and gm.inventory:
		for item in items:
			var added = gm.inventory.add_item(item.get("id", ""), item.get("count", 1))
			print("🎁 获得: %s × %d" % [item.get("name", ""), added])
	
	chest_looted.emit(name)

func _generate_loot() -> Array[Dictionary]:
	"""生成战利品列表"""
	var result: Array[Dictionary] = []
	
	# 固定掉落
	for item in fixed_loot:
		result.append(item)
	
	# 随机掉落
	for entry in loot_table:
		if randf() <= entry.get("chance") or 1.0:
			var count = randi_range(entry.get("min_count") or 1, entry.get("max_count") or 1)
			result.append({"id": entry.id, "name": entry.get("name") or entry.id, "count": count})
	
	return result

# ==================== HUD 提示 ====================

func get_hint_name() -> String:
	if is_opened:
		return "%s（已开启）" % chest_name
	elif is_locked:
		return "%s（🔒）" % chest_name
	return chest_name

func get_locked() -> bool:
	return is_locked
