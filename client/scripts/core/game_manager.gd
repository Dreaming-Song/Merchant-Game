extends Node
## 游戏核心管理器 — 串联所有子系统的指挥中心
##
## 职责：
## 1. 初始化所有子系统（顺序依赖）
## 2. 管理游戏状态（运行中/暂停/存档）
## 3. 连接子系统间的信号通道
## 4. 全局游戏循环 tick

class_name GameManager

# ==================== 游戏状态 ====================
enum GameState {
	INIT,           # 初始化中
	MAIN_MENU,      # 主菜单
	LOADING,        # 加载中
	PLAYING,        # 游戏中
	PAUSED,         # 暂停
	SAVING,         # 存档中
	QUITTING,       # 退出中
}

var current_state: int = GameState.INIT
var game_time: float = 0.0          # 游戏总运行时间（秒）
var day_time: float = 0.0           # 白天时间（0~24000，MC式）
var world_data: Dictionary = {}     # 世界数据

# ==================== 引用所有子系统 ====================
var realm: RealmSystem
var cultivation: CultivationSystem
var inventory: InventorySystem
var crafting: CraftingSystem
var building: BuildingSystem
var skill_manager: SkillManager
var map_gen: MapGenerator
var player: Node3D

# ==================== 信号 ====================
signal game_state_changed(old_state: int, new_state: int)
signal game_initialized()
signal day_night_changed(is_day: bool, time: float)
signal player_died()
signal world_loaded(world_data: Dictionary)

func _ready() -> void:
	_initialize_systems()

func _process(delta: float) -> void:
	if current_state != GameState.PLAYING:
		return
	
	game_time += delta
	day_time = fmod(game_time * 0.5, 24000.0)  # 1秒=0.5游戏刻
	
	# 昼夜信号（每整刻触发一次）
	if int(day_time) % 100 == 0:
		day_night_changed.emit(day_time > 12000, day_time)

# ==================== 初始化管线 ====================

func _initialize_systems() -> void:
	print("🚀 游戏初始化开始...")
	current_state = GameState.INIT
	
	# 1. 境界系统（最底层，其他系统依赖它判断解锁）
	realm = RealmSystem.new()
	add_child(realm)
	print("  ✅ RealmSystem")
	
	# 2. 修行系统（流派等级、技能解锁）
	cultivation = CultivationSystem.new()
	add_child(cultivation)
	print("  ✅ CultivationSystem")
	
	# 3. 物品数据库（纯静态，无需初始化）
	print("  ✅ ItemDatabase (static)")
	
	# 4. 背包系统
	inventory = InventorySystem.new()
	add_child(inventory)
	print("  ✅ InventorySystem")
	
	# 5. 合成系统
	crafting = CraftingSystem.new()
	add_child(crafting)
	crafting._inventory = inventory  # 🔧 B2: 注入背包引用
	print("  ✅ CraftingSystem")
	
	# 6. 建筑系统
	building = BuildingSystem.new()
	add_child(building)
	print("  ✅ BuildingSystem")
	
	# 7. 技能管理器
	skill_manager = SkillManager.new()
	add_child(skill_manager)
	print("  ✅ SkillManager")
	
	# 8. 地图生成器
	map_gen = MapGenerator.new()
	add_child(map_gen)
	map_gen.world_seed = randi()
	print("  ✅ MapGenerator")
	
	# 连接信号通路
	_connect_signals()
	
	game_initialized.emit()
	print("🎮 游戏初始化完成！进入主菜单")
	current_state = GameState.MAIN_MENU

func _connect_signals() -> void:
	"""跨系统信号通道"""
	# 境界突破 → 解锁新合成配方
	realm.realm_changed.connect(_on_realm_changed)
	
	# 背包变更 → 更新HUD
	inventory.inventory_changed.connect(_on_inventory_changed)
	
	# 合成完成 → 更新背包
	crafting.item_crafted.connect(_on_item_crafted)
	
	# 建筑放置 → 消耗背包材料
	building.piece_placed.connect(_on_piece_placed)
	
	# 🔧 L5: 死亡信号暂不连接（player创建后由 set_player 连接）

## 🔧 设置玩家引用（由 PlayerController._ready 调用）
func set_player(player_node: Node3D) -> void:
	player = player_node
	building.player_ref = player_node  # 🔧 B3: 注入建筑系统的玩家引用
	player_died.connect(_on_player_died)  # 🔧 L5: 连接死亡信号
	print("👤 玩家引用注入完成")

func _on_player_died() -> void:
	print("💀 玩家阵亡，存档丢失！")
	# 死亡惩罚：掉一半修行点数
	if cultivation:
		var lost = cultivation.cultivation_points / 2
		cultivation.cultivation_points -= lost
		print("  失去 %d 修行点数" % lost)

# ==================== 游戏生命周期 ====================

## 开始新游戏
func start_new_game() -> void:
	current_state = GameState.LOADING
	
	# 生成世界
	world_data = map_gen.generate_world()
	world_loaded.emit(world_data)
	
	# 设置出生点
	var spawn = world_data.get("spawn_point", Vector3(0, 1, 0))
	print("🌍 世界生成完毕，出生点: (%d, %d, %d)" % [spawn.x, spawn.y, spawn.z])
	
	# 初始背包：送一套新手装备
	inventory.add_item("stone_axe", 1)
	inventory.add_item("stone_pickaxe", 1)
	inventory.add_item("wooden_sword", 1)
	inventory.add_item("torch", 8)
	inventory.add_item("herb_common", 5)
	
	# 给一些初始修行点数
	cultivation.cultivation_points = 3
	
	current_state = GameState.PLAYING
	game_state_changed.emit(GameState.LOADING, GameState.PLAYING)
	print("🎮 进入游戏！")

## 暂停/恢复
func toggle_pause() -> void:
	match current_state:
		GameState.PLAYING:
			current_state = GameState.PAUSED
			game_state_changed.emit(GameState.PLAYING, GameState.PAUSED)
		GameState.PAUSED:
			current_state = GameState.PLAYING
			game_state_changed.emit(GameState.PAUSED, GameState.PLAYING)

## 存档
func save_game() -> bool:
	"""保存到当前世界（由 WorldManager 管理）"""
	if current_state not in [GameState.PLAYING, GameState.PAUSED]:
		return false
	
	current_state = GameState.SAVING
	
	var wm = get_node("/root/WorldManager")
	if not wm or wm.current_world.is_empty():
		print("⚠️ 没有当前世界，无法存档")
		current_state = GameState.PLAYING
		return false
	
	var save_data = {
		"game_time": game_time,
		"world_seed": map_gen.world_seed if map_gen else 0,
		"realm": realm.get_save_data() if realm else {},
		"cultivation": cultivation.get_save_data() if cultivation else {},
		"inventory": inventory.get_save_data() if inventory else {},
		"building": building.get_save_data() if building else {},
	}
	
	var player_data = {
		"_delta_time": 0.0,
		"_player_count": 1,
		"inventory": save_data.inventory,
		"realm": save_data.realm,
		"cultivation": save_data.cultivation,
	}
	
	var world_state = {
		"game_time": game_time,
		"world_seed": save_data.world_seed,
		"building": save_data.building,
	}
	
	if wm.save_system and wm.save_system.has_method("save_world"):
		var ok = wm.save_system.save_world(wm.current_world, player_data, world_state)
		print("💾 WorldManager 存档 %s" % ["成功" if ok else "失败"])
	else:
		print("⚠️ 无 SaveSystem，存档失败")
	
	current_state = GameState.PLAYING
	return true

## 读档
func load_game() -> bool:
	"""从当前世界加载存档"""
	current_state = GameState.LOADING
	
	var wm = get_node("/root/WorldManager")
	if not wm or wm.current_world.is_empty():
		print("⚠️ 没有当前世界，无法读档")
		current_state = GameState.PLAYING
		return false
	
	var data = wm.save_system.load_world(wm.current_world) if wm.save_system else {}
	if data.is_empty():
		print("⚠️ 存档数据为空")
		current_state = GameState.PLAYING
		return false
	
	var player_data = data.get("player_data", {})
	var world_state = data.get("world_state", {})
	
	game_time = world_state.get("game_time", 0.0)
	
	if map_gen:
		var meta = data.get("meta", {})
		map_gen.world_seed = meta.get("seed", randi())
	
	# 恢复各系统
	if realm and player_data.has("realm"):
		realm.load_save_data(player_data.realm)
	if cultivation and player_data.has("cultivation"):
		cultivation.load_save_data(player_data.cultivation)
	if inventory and player_data.has("inventory"):
		inventory.load_save_data(player_data.inventory)
	if building and world_state.has("building"):
		building.load_save_data(world_state.building)
	
	# 恢复玩家位置
	var pos = player_data.get("player_pos", [0, 5, 0])
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = Vector3(pos[0], pos[1], pos[2])
	
	current_state = GameState.PLAYING
	game_state_changed.emit(GameState.LOADING, GameState.PLAYING)
	print("📂 读档完成！")
	return true

# ==================== 信号处理 ====================

func _on_realm_changed(old_realm: int, new_realm: int, name: String) -> void:
	print("🌟 境界突破！%s" % name)
	# 突破后自动解锁新技能
	if cultivation:
		var unlocks = realm.get_current_unlocks()
		for unlock in unlocks:
			print("  解锁: %s" % unlock)

func _on_inventory_changed(slot: int, item_id: String, count: int) -> void:
	pass  # HUD 会更新

func _on_item_crafted(recipe_id: String, result_id: String, count: int) -> void:
	var name = ItemDatabase.get_item_name(result_id)
	print("🛠️ 合成完成: %s × %d" % [name, count])

func _on_piece_placed(piece_id: String, piece_type: int, tier: int, pos: Vector3) -> void:
	pass  # 更新世界数据

# ==================== 玩家操作入口 ====================

## 采集资源
func gather_resource(resource_id: String, count: int = 1) -> void:
	var item_data = ItemDatabase.get_item(resource_id)
	if item_data.is_empty():
		return
	
	# 检查工具
	if item_data.get("gatherable", false):
		var needed_tool = item_data.get("gather_tool", "hand")
		var needed_tier = item_data.get("gather_tier", 0)
		var equipped_tool = inventory.get_equipped_tool()
		var tool_tier = ItemDatabase.get_tier(equipped_tool)
		
		if tool_tier < needed_tier:
			print("⚠️ 需要更高级的工具采集 %s（需%d级，当前%d级）" % 
				[item_data.name, needed_tier, tool_tier])
			return
		
		# 消耗工具耐久
		if not equipped_tool.is_empty():
			var tool_slot = _find_equipped_tool_slot()
			if tool_slot >= 0:
				inventory.use_durability(tool_slot, 1)
	
	# 实际添加物品
	var added = inventory.add_item(resource_id, count)
	if added > 0:
		# 获得少量修为
		var xp_gained = count * 2
		realm.add_cultivation_xp(xp_gained)
		cultivation.add_cultivation_xp(xp_gained)
		print("🌿 采集 %s × %d (+%d修为)" % [item_data.name, added, xp_gained])

func _find_equipped_tool_slot() -> int:
	var tool_id = inventory.get_equipped_tool()
	if tool_id.is_empty():
		return -1
	for i in range(inventory.get_all_slots().size()):
		var slot = inventory.get_slot(i)
		if slot.item_id == tool_id and slot.count > 0:
			return i
	return -1

## 建造建筑（支持工作站放置）
func place_building(item_id: String, position: Vector3) -> Dictionary:
	var item_data = ItemDatabase.get_item(item_id)
	if not item_data.get("buildable", false) and not item_data.get("placeable", false):
		return {"success": false, "reason": "该物品不可放置"}
	
	# 消耗背包中的建筑块
	if not inventory.has_item(item_id, 1):
		return {"success": false, "reason": "材料不足"}
	
	var piece_type = item_data.get("piece_type", 0)
	var piece_tier = item_data.get("piece_tier", 0)
	var result: Dictionary
	
	# ---- DST/Terraria风格：工作站类型检测 ----
	# 检查物品是否是工作站（category=station 或 result 命中工作站配方）
	var category = item_data.get("category", "")
	var is_station = (category == "station")
	
	if is_station:
		# 通过物品ID匹配工作站类型
		var station_type = _get_station_type(item_id)
		result = building.try_place_station(station_type, position)
	else:
		# 普通建筑块
		result = building.try_place(piece_type, piece_tier, position)
	
	if result.get("success", false):
		inventory.remove_item(item_id, 1)
	else:
		print("❌ 放置失败: %s" % result.get("reason", "未知"))
	
	return result

## 通过物品ID获取工作站类型
func _get_station_type(item_id: String) -> int:
	# 先用 ItemDatabase 的 place_type 字段匹配
	var item_data = ItemDatabase.get_item(item_id)
	var place_type = item_data.get("place_type", "")
	if not place_type.is_empty():
		return WorkstationStation.get_station_type_from_recipe(place_type)
	
	# 降级：硬编码匹配
	match item_id:
		"workbench":       return WorkstationStation.StationType.WORKBENCH
		"furnace":         return WorkstationStation.StationType.FURNACE
		"anvil":           return WorkstationStation.StationType.ANVIL
		"alchemy_furnace": return WorkstationStation.StationType.ALCHEMY_TABLE
		"loom":            return WorkstationStation.StationType.LOOM
		"spirit_furnace":  return WorkstationStation.StationType.SPIRIT_FURNACE
		"rune_table":      return WorkstationStation.StationType.RUNE_TABLE
	return WorkstationStation.StationType.WORKBENCH

## 合成物品
func craft_item(recipe_id: String, count: int = 1) -> Dictionary:
	return crafting.craft(recipe_id, count)

## 使用物品
func use_item(slot_index: int) -> Dictionary:
	var result = inventory.use_item(slot_index)
	if result.get("success", false):
		var effects = result.get("effects", {})
		# 🔧 B1: 用 .get() 替代点号语法
		var hp_restore = effects.get("hp_restore", 0)
		var mp_restore = effects.get("mp_restore", 0)
		var breakthrough_boost = effects.get("breakthrough_boost", 0)
		
		if hp_restore > 0:
			print("💚 恢复 %d 生命" % hp_restore)
			# 🔧 L4: 实际调用玩家治疗
			if player and player.has_method("heal"):
				player.heal(hp_restore)
		if mp_restore > 0:
			print("💙 恢复 %d 法力" % mp_restore)
			if skill_manager and skill_manager.has_method("restore_mp"):
				skill_manager.restore_mp(mp_restore)
		if breakthrough_boost > 0:
			var xp = breakthrough_boost * 500
			realm.add_cultivation_xp(xp)
			print("🌟 获得 %d 修为（突破助力）" % xp)
	return result

## 修行加点
func invest_cultivation(school_type: int, levels: int = 1) -> bool:
	return cultivation.invest_in_school(school_type, levels)

## 尝试境界突破
func try_breakthrough() -> bool:
	return realm.try_breakthrough(
		func(_item, _count): return inventory.has_item(_item, _count),
		func(_item, _count): inventory.remove_item(_item, _count)  # 🔧 B4: 消耗突破材料
	)
