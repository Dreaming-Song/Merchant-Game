extends Node
## 主菜单控制器 — 管理世界选择/创建/加入的流程
##
## 启动流程：
##   1. 显示 WorldSelectScreen
##   2. 玩家选择世界 / 创建世界 / 加入别人
##   3. 进入世界 → 加载场景

class_name MainMenu

var _world_select: Node = null
var _create_dialog: Node = null

func _ready() -> void:
	_show_world_select()

func _show_world_select() -> void:
	"""显示世界选择界面"""
	if not _world_select:
		_world_select = preload("res://scripts/ui/world_select_screen.gd").new()
		_world_select.name = "WorldSelect"
		add_child(_world_select)
		
		_world_select.world_selected.connect(_on_world_selected)
		_world_select.create_new_world.connect(_on_create_world)
		_world_select.join_multiplayer.connect(_on_join_multiplayer)
		_world_select.settings_requested.connect(_on_settings)
	
	_world_select.visible = true

func _on_world_selected(world_name: String) -> void:
	"""选择了一个世界 → 进入游戏"""
	var wm = get_node("/root/WorldManager")
	if wm and wm.enter_world(world_name):
		_world_select.visible = false
		# 切换到游戏场景
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	else:
		print("⚠️ 进入世界失败: " + world_name)

func _on_create_world() -> void:
	"""打开创建世界弹窗"""
	if not _create_dialog:
		_create_dialog = preload("res://scripts/ui/create_world_dialog.gd").new()
		_create_dialog.name = "CreateWorldDialog"
		add_child(_create_dialog)
		_create_dialog.world_created.connect(_on_world_created)
	
	_create_dialog.popup_centered(Vector2(400, 300))

func _on_world_created(name: String, seed: int) -> void:
	"""世界已创建 → 自动进入"""
	var wm = get_node("/root/WorldManager")
	if wm and wm.create_world(name, seed):
		_on_world_selected(name)

func _on_join_multiplayer() -> void:
	"""打开联机界面"""
	if _world_select:
		_world_select.visible = false
	
	var mp_screen = preload("res://scripts/ui/multiplayer_screen.gd").new()
	mp_screen.name = "MultiplayerScreen"
	mp_screen.back_to_menu.connect(_on_multiplayer_back)
	add_child(mp_screen)

func _on_multiplayer_back() -> void:
	var mp = get_node_or_null("MultiplayerScreen")
	if mp:
		mp.queue_free()
	if _world_select:
		_world_select.visible = true

func _on_settings() -> void:
	"""打开设置"""
	var settings = get_node("/root/UIManager/SettingsPanel") if has_node("/root/UIManager/SettingsPanel") else null
	if settings:
		settings.visible = true
