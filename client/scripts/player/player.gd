extends CharacterBody3D
## 主场景玩家节点 — 轻量包装，实际逻辑在 PlayerController
##
## 用于场景中的物理碰撞和可见性
## 所有游戏逻辑委托给 PlayerController（通过 GameManager 访问）

# HP/MP 委托访问
var current_hp: float = 100.0
var max_hp: float = 100.0
var current_mp: float = 50.0
var max_mp: float = 50.0

func _ready() -> void:
	add_to_group("player")

func take_damage(amount: int) -> void:
	var pc = _get_pc()
	if pc and pc.has_method("take_damage"):
		pc.take_damage(amount)

func heal(amount: int) -> void:
	var pc = _get_pc()
	if pc and pc.has_method("heal"):
		pc.heal(amount)

func _get_pc():
	var gm = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	# 先试 GameManager.player 属性
	if gm and gm.player:
		return gm.player.get_node_or_null("PlayerController") if gm.player.has_node("PlayerController") else null
	# 回退：场景树搜索（组注册可能在 _ready 之后）
	return get_tree().get_first_node_in_group("player_controller")
