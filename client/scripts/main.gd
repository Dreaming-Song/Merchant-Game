extends Node
## 主场景容器 — 轻量级加载器
##
## 只管理场景本身的节点（地形/UI），子系统走 Autoload 或 GameManager

# 场景引用
@onready var player: CharacterBody3D = $Player
@onready var hud: CanvasLayer = $UI/HUD
@onready var terrain: Node3D = $World/TerrainManager

func _enter_tree() -> void:
	# 注册到 GameManager
	var gm = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	if gm and gm.has_method("set_player"):
		gm.set_player(player)

func _ready() -> void:
	print("🌏 灵境 v0.1.0 — 场景就绪")
