extends Node
## 世界存档系统 — 类似 MC/泰拉/饥荒的"世界文件夹"模式
##
## 目录结构：
##   user://worlds/
##   └── WorldName/
##       ├── world.json          # 世界元信息（名称、种子、创建时间）
##       ├── player_data.json    # 玩家数据（物品、修为、境界）
##       └── world_state.json    # 世界状态（宝箱、建筑、已采集资源）
##
## 生命周期：
##   WorldManager 创建/删除世界
##   进入世界时 load_world() → GameManager 分发数据
##   退出世界时 save_world() → 所有数据写回硬盘

class_name WorldSaveSystem

signal world_saved(world_name: String)
signal world_loaded(world_name: String)

const WORLDS_DIR: String = "user://worlds/"

func _ready() -> void:
	DirAccess.make_dir_recursive(WORLDS_DIR)

# ==================== 世界管理 ====================

func create_world(name: String, seed: int) -> bool:
	"""创建新世界文件夹"""
	var dir_path = WORLDS_DIR + name
	if DirAccess.dir_exists_absolute(dir_path):
		return false  # 已存在
	
	DirAccess.make_dir_recursive(dir_path)
	
	# 写入世界元信息
	var meta = {
		"name": name,
		"seed": seed,
		"created": Time.get_unix_time_from_system(),
		"last_played": Time.get_unix_time_from_system(),
		"play_time": 0.0,
		"version": "0.2.0",
		"game_mode": "survival",  # survival / creative / hardcore
		"player_count": 0,
	}
	_save_json(dir_path + "/world.json", meta)
	
	# 写入空初始数据
	_save_json(dir_path + "/player_data.json", {
		"inventory": [],
		"equipment": {},
		"realm": {"level": 0, "xp": 0},
		"cultivation": {"points": 0, "schools": {}},
		"player_pos": [0, 5, 0],
		"player_rot": [0, 0, 0],
		"hp": 100,
		"mp": 50,
	})
	_save_json(dir_path + "/world_state.json", {
		"buildings": [],
		"chests": {},
		"gathered_resources": {},
		"killed_enemies": {},
		"game_time": 0.0,
	})
	
	print("🌍 世界已创建: %s (seed=%d)" % [name, seed])
	return true

func delete_world(name: String) -> bool:
	"""删除世界文件夹"""
	var dir_path = WORLDS_DIR + name
	if not DirAccess.dir_exists_absolute(dir_path):
		return false
	os_shell_delete(dir_path)
	print("🗑️ 世界已删除: " + name)
	return true

func os_shell_delete(path: String) -> void:
	"""递归删除文件夹"""
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name == "." or file_name == "..":
				file_name = dir.get_next()
				continue
			var full_path = path + "/" + file_name
			if dir.current_is_dir():
				os_shell_delete(full_path)
			else:
				DirAccess.remove_absolute(full_path)
			file_name = dir.get_next()
		dir.list_dir_end()
	DirAccess.remove_absolute(path)

func rename_world(old_name: String, new_name: String) -> bool:
	"""重命名世界"""
	var old_path = WORLDS_DIR + old_name
	var new_path = WORLDS_DIR + new_name
	if not DirAccess.dir_exists_absolute(old_path) or DirAccess.dir_exists_absolute(new_path):
		return false
	return DirAccess.rename_absolute(old_path, new_path) == OK

# ==================== 世界列表 ====================

func list_worlds() -> Array[Dictionary]:
	"""列出所有世界"""
	var result: Array[Dictionary] = []
	var dir = DirAccess.open(WORLDS_DIR)
	if not dir:
		return result
	
	dir.list_dir_begin()
	var name = dir.get_next()
	while name != "":
		if name == "." or name == "..":
			name = dir.get_next()
			continue
		if dir.current_is_dir():
			var meta = _load_json(WORLDS_DIR + name + "/world.json")
			if not meta.is_empty():
				result.append({
					"name": meta.get("name", name),
					"seed": meta.get("seed", 0),
					"created": meta.get("created", 0),
					"last_played": meta.get("last_played", 0),
					"play_time": meta.get("play_time", 0.0),
					"version": meta.get("version", "未知"),
					"game_mode": meta.get("game_mode", "survival"),
				})
		name = dir.get_next()
	dir.list_dir_end()
	
	# 按最后游玩时间排序（最新的在前）
	result.sort_custom(func(a, b): return a.last_played > b.last_played)
	return result

func get_world_info(name: String) -> Dictionary:
	"""获取单个世界的信息"""
	return _load_json(WORLDS_DIR + name + "/world.json")

# ==================== 读写世界数据 ====================

func save_world(name: String, player_data: Dictionary, world_state: Dictionary) -> bool:
	"""保存世界"""
	var dir_path = WORLDS_DIR + name
	if not DirAccess.dir_exists_absolute(dir_path):
		return false
	
	# 更新元信息
	var meta = _load_json(dir_path + "/world.json")
	meta["last_played"] = Time.get_unix_time_from_system()
	meta["play_time"] = meta.get("play_time", 0.0) + player_data.get("_delta_time", 0.0)
	meta["player_count"] = player_data.get("_player_count", 1)
	_save_json(dir_path + "/world.json", meta)
	
	# 玩家数据（去掉临时字段）
	var clean_player = player_data.duplicate()
	clean_player.erase("_delta_time")
	clean_player.erase("_player_count")
	_save_json(dir_path + "/player_data.json", clean_player)
	
	# 世界状态
	_save_json(dir_path + "/world_state.json", world_state)
	
	world_saved.emit(name)
	print("💾 世界已保存: " + name)
	return true

func load_world(name: String) -> Dictionary:
	"""加载世界"""
	var dir_path = WORLDS_DIR + name
	if not DirAccess.dir_exists_absolute(dir_path):
		return {}
	
	var result = {
		"meta": _load_json(dir_path + "/world.json"),
		"player_data": _load_json(dir_path + "/player_data.json"),
		"world_state": _load_json(dir_path + "/world_state.json"),
	}
	
	world_loaded.emit(name)
	print("📂 世界已加载: " + name)
	return result

# ==================== 工具 ====================

func _save_json(path: String, data: Dictionary) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var text = file.get_as_text()
	file.close()
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		push_error("JSON解析失败: " + path)
		return {}
	return json.data
