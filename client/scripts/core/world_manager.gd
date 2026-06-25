extends Node
## 世界管理器 — 管理世界创建/加载/生命周期
##
## 类似 Minecraft 的世界选择界面逻辑：
##   1. 启动游戏 → 显示世界列表
##   2. 选世界 / 新世界 / 加别人
##   3. 进入世界 → WorldManager 加载所有数据 → 分发
##   4. 离开世界 → WorldManager 保存所有数据

# class_name WorldManager — 已通过 autoload 注册

signal world_entered(world_name: String)
signal world_exited(world_name: String)

var current_world: String = ""
var save_system: Node = null
var game_manager: Node = null

func _ready() -> void:
	save_system = get_node("/root/SaveSystem") if has_node("/root/SaveSystem") else null
	game_manager = get_node("/root/GameManager") if has_node("/root/GameManager") else null

# ==================== 世界列表 ====================

func list_worlds() -> Array[Dictionary]:
	if save_system and save_system.has_method("list_worlds"):
		return save_system.list_worlds()
	return []

func get_world_info(name: String) -> Dictionary:
	if save_system and save_system.has_method("get_world_info"):
		return save_system.get_world_info(name)
	return {}

func create_world(name: String, seed: int = -1, game_mode: String = "survival") -> bool:
	"""创建世界"""
	if seed < 0:
		seed = randi()
	
	if save_system and save_system.has_method("create_world"):
		return save_system.create_world(name, seed)
	return false

func delete_world(name: String) -> bool:
	if save_system and save_system.has_method("delete_world"):
		return save_system.delete_world(name)
	return false

func rename_world(old_name: String, new_name: String) -> bool:
	if save_system and save_system.has_method("rename_world"):
		return save_system.rename_world(old_name, new_name)
	return false

# ==================== 进入/退出世界 ====================

func enter_world(name: String) -> bool:
	"""加载并进入一个世界"""
	if current_world != "":
		exit_world()
	
	var data = save_system.load_world(name) if save_system else {}
	if data.is_empty():
		return false
	
	current_world = name
	
	# 1. 设置地图种子
	var meta = data.get("meta", {})
	var seed = meta.get("seed", randi())
	_set_world_seed(seed)
	
	# 2. 恢复玩家数据
	var player_data = data.get("player_data", {})
	_restore_player(player_data)
	
	# 3. 恢复世界状态
	var world_state = data.get("world_state", {})
	_restore_world_state(world_state)
	
	# 4. 设置游戏模式
	_set_game_mode(meta.get("game_mode") or "survival")
	
	world_entered.emit(name)
	print("🚪 进入世界: %s (seed=%d)" % [name, seed])
	return true

func exit_world() -> bool:
	"""退出并保存当前世界"""
	if current_world == "":
		return false
	
	# 收集当前数据
	var player_data = _collect_player_data()
	var world_state = _collect_world_state()
	
	if save_system and save_system.has_method("save_world"):
		save_system.save_world(current_world, player_data, world_state)
	
	world_exited.emit(current_world)
	print("🚪 退出世界: " + current_world)
	current_world = ""
	return true

# ==================== 数据收集/恢复 ====================

func _collect_player_data() -> Dictionary:
	"""收集玩家当前数据"""
	var data = {
		"_delta_time": 0.0,
		"_player_count": 1,
		"hp": 100, "mp": 50,
		"player_pos": [0, 5, 0],
		"player_rot": [0, 0, 0],
	}
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		data.player_pos = [player.global_position.x, player.global_position.y, player.global_position.z]
		data.player_rot = [player.rotation.x, player.rotation.y, player.rotation.z]
		if player.has_method("get_hp"): data.hp = player.get_hp()
		if player.has_method("get_mp"): data.mp = player.get_mp()
	
	if game_manager:
		if game_manager.has_method("get_inventory_data"):
			data.inventory = game_manager.get_inventory_data()
		if game_manager.realm and game_manager.realm.has_method("get_save_data"):
			data.realm = game_manager.realm.get_save_data()
		if game_manager.cultivation and game_manager.cultivation.has_method("get_save_data"):
			data.cultivation = game_manager.cultivation.get_save_data()
	
	return data

func _collect_world_state() -> Dictionary:
	"""收集世界状态"""
	return {
		"game_time": game_manager.get("game_time") or 0.0 if game_manager else 0.0,
	}
	
func _restore_player(data: Dictionary) -> void:
	"""恢复玩家数据"""
	if not game_manager:
		return
	
	var pos = data.get("player_pos") or [0, 5, 0]
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = Vector3(pos[0], pos[1], pos[2])
	
	# 恢复库存/修为等
	if data.has("inventory") and game_manager.inventory:
		game_manager.inventory.load_save_data(data.get("inventory"))
	if data.has("realm") and game_manager.realm:
		game_manager.realm.load_save_data(data.get("realm"))
	if data.has("cultivation") and game_manager.cultivation:
		game_manager.cultivation.load_save_data(data.get("cultivation"))

func _restore_world_state(data: Dictionary) -> void:
	"""恢复世界状态"""
	if game_manager:
		game_manager.game_time = data.get("game_time") or 0.0

func _set_world_seed(seed: int) -> void:
	"""设置世界种子（通知 MapGenerator）"""
	var map_gen = get_node("/root/GameManager/MapGenerator") if has_node("/root/GameManager/MapGenerator") else null
	if map_gen and map_gen.has_method("set_seed"):
		map_gen.set_seed(seed)

func _set_game_mode(mode: String) -> void:
	"""设置游戏模式"""
	# survival / creative / hardcore
	pass
