extends Node
class_name BossArenaManager

## 🏯 神兽秘境管理器
## 管理5个独立BOSS秘境空间：场景加载/卸载/传送/状态

const BossArenaWorld = preload("res://scripts/combat/boss_arena_world.gd")

# ==================== 信号 ====================
signal arena_entered(boss_key: String, player: Node)
signal arena_exited(boss_key: String, player: Node)
signal boss_defeated_in_arena(boss_key: String)
signal arena_state_changed(boss_key: String, new_state: int)

# ==================== 秘境状态 ====================
enum ArenaState {
	AVAILABLE,    # 可挑战
	IN_PROGRESS,  # 战斗中
	CLEARED,      # 已通关
	COOLDOWN,     # 冷却中
}

var arena_states: Dictionary = {}  # boss_key -> ArenaState
var arena_cooldown_timers: Dictionary = {}  # boss_key -> 剩余秒数

# ==================== 场景引用 ====================
# 当前加载的秘境场景实例
var _loaded_arenas: Dictionary = {}  # boss_key -> BossArenaWorld
# 玩家所在秘境映射
var _player_arena_map: Dictionary = {}  # player_id (str) -> boss_key
# 世界根节点（秘境场景挂载到此节点下）
var _world_root: Node3D = null

# ==================== 秘境配置 ====================
const ARENA_CONFIG = {
	"azure_dragon": {
		"name": "青龙秘境 · 万木春",
		"element": "木",
		"color": Color("#2a7a5a"),
		"ground_color": Color("#1a4a2a"),
		"fog_color": Color("#1a3a2a"),
		"ambient_color": Color("#1a3a2a"),
		"decorations": ["tree", "vine"],
		"arena_radius": 30.0,
		"boss_spawn": Vector3(0, 1, 0),
		"player_spawn": Vector3(0, 1, -20),
		"exit_position": Vector3(0, 1, 22),
	},
	"white_tiger": {
		"name": "白虎秘境 · 万兵谷",
		"element": "金",
		"color": Color("#f0f0f8"),
		"ground_color": Color("#5a5a4a"),
		"fog_color": Color("#3a3a3a"),
		"ambient_color": Color("#4a4a3a"),
		"decorations": ["sword", "stone_pillar"],
		"arena_radius": 35.0,
		"boss_spawn": Vector3(0, 1, 0),
		"player_spawn": Vector3(0, 1, -22),
		"exit_position": Vector3(0, 1, 24),
	},
	"vermilion_bird": {
		"name": "朱雀秘境 · 焚天窟",
		"element": "火",
		"color": Color("#d83a20"),
		"ground_color": Color("#4a1a0a"),
		"fog_color": Color("#3a1a0a"),
		"ambient_color": Color("#4a1a0a"),
		"decorations": ["lava", "stone_pillar"],
		"arena_radius": 28.0,
		"boss_spawn": Vector3(0, 1, 0),
		"player_spawn": Vector3(0, 1, -18),
		"exit_position": Vector3(0, 1, 20),
	},
	"black_warrior": {
		"name": "玄武秘境 · 寒冰渊",
		"element": "水",
		"color": Color("#2a5a8a"),
		"ground_color": Color("#1a2a3a"),
		"fog_color": Color("#1a2a3a"),
		"ambient_color": Color("#1a2a3a"),
		"decorations": ["ice", "crystal"],
		"arena_radius": 32.0,
		"boss_spawn": Vector3(0, 1, 0),
		"player_spawn": Vector3(0, 1, -20),
		"exit_position": Vector3(0, 1, 22),
	},
	"golden_qilin": {
		"name": "麒麟秘境 · 镇岳台",
		"element": "土",
		"color": Color("#d4b828"),
		"ground_color": Color("#4a3a1a"),
		"fog_color": Color("#3a2a1a"),
		"ambient_color": Color("#4a3a1a"),
		"decorations": ["stone_pillar", "crystal"],
		"arena_radius": 35.0,
		"boss_spawn": Vector3(0, 1, 0),
		"player_spawn": Vector3(0, 1, -22),
		"exit_position": Vector3(0, 1, 24),
	},
}

# ==================== 初始化 ====================

func _ready() -> void:
	# 加入组供UI查找
	add_to_group("arena_manager")
	
	# 初始化所有秘境状态
	for boss_key in ARENA_CONFIG:
		arena_states[boss_key] = ArenaState.AVAILABLE
		arena_cooldown_timers[boss_key] = 0.0
	
	# 查找世界根节点（作为秘境场景的挂载点）
	_world_root = get_tree().get_first_node_in_group("world_root")
	if not _world_root:
		_world_root = get_tree().current_scene
	
	print("🏯 BossArenaManager 就绪！5个独立秘境等待加载")

func _process(delta: float) -> void:
	# 冷却计时
	for boss_key in arena_cooldown_timers.keys():
		if arena_cooldown_timers[boss_key] > 0:
			arena_cooldown_timers[boss_key] -= delta
			if arena_cooldown_timers[boss_key] <= 0:
				arena_states[boss_key] = ArenaState.AVAILABLE
				arena_state_changed.emit(boss_key, ArenaState.AVAILABLE)
				print("🏯 %s 秘境冷却结束，可再次挑战！" % ARENA_CONFIG[boss_key]["name"])

# ==================== 核心功能：场景式加载/卸载 ====================

## 使用传送令牌进入秘境 — 加载独立场景
func enter_arena(boss_key: String, player: Node) -> bool:
	if not ARENA_CONFIG.has(boss_key):
		print("❌ 未知秘境: %s" % boss_key)
		return false
	
	var state = arena_states.get(boss_key, ArenaState.AVAILABLE)
	if state == ArenaState.COOLDOWN:
		print("❌ %s 冷却中（剩余%d秒）" % [ARENA_CONFIG[boss_key]["name"], int(arena_cooldown_timers[boss_key])])
		_send_message_to_player(player, "⚠️ %s 冷却中，还需%d秒" % [ARENA_CONFIG[boss_key]["name"], int(arena_cooldown_timers[boss_key])])
		return false
	if state == ArenaState.IN_PROGRESS:
		print("❌ %s 已被其他人挑战" % ARENA_CONFIG[boss_key]["name"])
		_send_message_to_player(player, "⚠️ 该秘境已被挑战中")
		return false
	
	var player_id = str(player.get_instance_id())
	
	# ========== 1. 加载秘境场景 ==========
	var arena_world = _load_arena_scene(boss_key)
	if not arena_world:
		print("❌ 秘境场景加载失败!")
		return false
	
	# ========== 2. 记录状态 ==========
	_player_arena_map[player_id] = boss_key
	_loaded_arenas[boss_key] = arena_world
	arena_states[boss_key] = ArenaState.IN_PROGRESS
	arena_state_changed.emit(boss_key, ArenaState.IN_PROGRESS)
	
	# ========== 3. 传送玩家 ==========
	_teleport_player_to_arena(arena_world, player)
	
	# ========== 4. 连接退出信号 ==========
	if not arena_world.player_request_exit.is_connected(_on_player_request_exit):
		arena_world.player_request_exit.connect(_on_player_request_exit)
	
	# ========== 5. 通知BOSS管理器生成BOSS ==========
	var boss_manager = get_tree().get_first_node_in_group("boss_manager")
	if boss_manager and boss_manager.has_method("spawn_boss_in_arena"):
		boss_manager.spawn_boss_in_arena(boss_key)
	
	arena_entered.emit(boss_key, player)
	_show_entry_effect(ARENA_CONFIG[boss_key]["name"], ARENA_CONFIG[boss_key]["color"])
	print("🏯 玩家进入【%s】！秘境场景已加载" % ARENA_CONFIG[boss_key]["name"])
	return true

## 离开秘境 — 卸载独立场景
func exit_arena(player: Node) -> bool:
	var player_id = str(player.get_instance_id())
	var boss_key = _player_arena_map.get(player_id, "")
	if boss_key.is_empty():
		print("❌ 玩家不在任何秘境中")
		return false
	
	# ========== 1. 传送回主世界 ==========
	_teleport_player_back(player)
	
	# ========== 2. 清理状态 ==========
	_player_arena_map.erase(player_id)
	
	# 如果是通关后离开，不重置；否则恢复可用
	if arena_states.get(boss_key) != ArenaState.CLEARED:
		arena_states[boss_key] = ArenaState.AVAILABLE
		arena_state_changed.emit(boss_key, ArenaState.AVAILABLE)
	
	# ========== 3. 卸载秘境场景 ==========
	_unload_arena_scene(boss_key)
	
	arena_exited.emit(boss_key, player)
	print("🏯 玩家离开【%s】，秘境场景已卸载" % ARENA_CONFIG[boss_key]["name"])
	return true

## 加载秘境场景（独立加载）
func _load_arena_scene(boss_key: String) -> BossArenaWorld:
	"""实例化一个独立的秘境场景并挂载到世界树下"""
	var cfg = ARENA_CONFIG[boss_key]
	
	# 秘境界限偏移（每个秘境在不同位置，互不重叠）
	var offset_index = 0
	for key in ARENA_CONFIG.keys():
		if key == boss_key: break
		offset_index += 1
	var offset = Vector3(offset_index * 500, 0, 0)  # 每个秘境间距500单位
	
	# 创建秘境实例（代码生成场景，就像加载.tscn一样）
	var arena = BossArenaWorld.new(boss_key, cfg, offset)
	
	# 挂载到世界根节点（相当于"加载"了一个场景）
	if _world_root:
		_world_root.add_child(arena)
	else:
		add_child(arena)
	
	print("🏯 场景已加载: %s @ %s" % [cfg["name"], offset])
	return arena

## 卸载秘境场景
func _unload_arena_scene(boss_key: String) -> void:
	"""从场景树移除秘境实例"""
	var arena = _loaded_arenas.get(boss_key)
	if not arena:
		return
	
	# 断开信号
	if arena.player_request_exit.is_connected(_on_player_request_exit):
		arena.player_request_exit.disconnect(_on_player_request_exit)
	
	# 清理并移除
	arena.clear_arena()
	_loaded_arenas.erase(boss_key)
	
	print("🏯 场景已卸载: %s" % ARENA_CONFIG[boss_key]["name"])

# ==================== 传送逻辑 ====================

func _teleport_player_to_arena(arena: BossArenaWorld, player: Node) -> void:
	"""传送玩家到秘境出生点"""
	var spawn_pos = arena.get_player_spawn()
	player.global_position = spawn_pos
	
	# 保存玩家原来位置以便传送回来
	var player_id = str(player.get_instance_id())
	player.set_meta("pre_arena_position", player.global_position)
	
	print("🏯 玩家传送至秘境 @ %s" % spawn_pos)

func _teleport_player_back(player: Node) -> void:
	"""传送回主世界"""
	var prev_pos = player.get_meta("pre_arena_position", Vector3(0, 10, 0))
	player.global_position = prev_pos
	print("🏯 玩家已传送回主世界 @ %s" % prev_pos)

# ==================== 出口传送门回调 ====================

func _on_player_request_exit(player: Node) -> void:
	"""玩家走到出口传送门"""
	var boss_key = _player_arena_map.get(str(player.get_instance_id()), "")
	if boss_key.is_empty():
		return
	
	print("🏯 玩家使用出口传送门离开秘境")
	exit_arena(player)

# ==================== BOSS击败回调 ====================

func on_boss_defeated(boss_key: String) -> void:
	"""BOSS在秘境中被击败"""
	if not ARENA_CONFIG.has(boss_key): return
	
	arena_states[boss_key] = ArenaState.CLEARED
	arena_state_changed.emit(boss_key, ArenaState.CLEARED)
	boss_defeated_in_arena.emit(boss_key)
	
	print("""
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    🏆 %s · 讨伐成功！
    宝箱已生成在秘境中
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	""" % ARENA_CONFIG[boss_key]["name"])

## 玩家离开后启动冷却
func start_arena_cooldown(boss_key: String, cooldown_seconds: float = 300.0) -> void:
	if not ARENA_CONFIG.has(boss_key): return
	arena_states[boss_key] = ArenaState.COOLDOWN
	arena_cooldown_timers[boss_key] = cooldown_seconds
	arena_state_changed.emit(boss_key, ArenaState.COOLDOWN)
	print("🏯 【%s】冷却%d秒" % [ARENA_CONFIG[boss_key]["name"], int(cooldown_seconds)])

# ==================== 界面反馈 ====================

func _show_entry_effect(name: String, color: Color) -> void:
	"""进入秘境时的屏幕特效"""
	print("""
╔══════════════════════════════════╗
║        🏯 进入秘境                ║
║        %s
╚══════════════════════════════════╝
	""" % name)

func _send_message_to_player(player: Node, text: String) -> void:
	"""发送消息给玩家"""
	if player.has_method("send_message"):
		player.send_message(text)
	else:
		print("📨 %s" % text)

# ==================== 查询接口 ====================

## 获取玩家当前秘境
func get_player_arena(player: Node) -> String:
	return _player_arena_map.get(str(player.get_instance_id()), "")

## 获取秘境状态
func get_arena_state(boss_key: String) -> int:
	return arena_states.get(boss_key, ArenaState.AVAILABLE)

## 获取秘境配置
func get_arena_config(boss_key: String) -> Dictionary:
	return ARENA_CONFIG.get(boss_key, {})

## 检查是否可使用传送令牌
func can_use_pass(boss_key: String) -> bool:
	var state = arena_states.get(boss_key, ArenaState.AVAILABLE)
	return state == ArenaState.AVAILABLE

## 获取所有秘境信息（供UI面板使用）
func get_all_arena_info() -> Array[Dictionary]:
	var info = []
	for boss_key in ARENA_CONFIG:
		var config = ARENA_CONFIG[boss_key]
		info.append({
			"key": boss_key,
			"name": config["name"],
			"element": config["element"],
			"color": config["color"],
			"state": arena_states.get(boss_key, ArenaState.AVAILABLE),
			"cooldown": arena_cooldown_timers.get(boss_key, 0.0),
		})
	return info

## 获取区域节点引用
func get_loaded_arena(boss_key: String) -> BossArenaWorld:
	return _loaded_arenas.get(boss_key, null)

## 秘境场景是否已加载
func is_arena_loaded(boss_key: String) -> bool:
	return _loaded_arenas.has(boss_key) and is_instance_valid(_loaded_arenas[boss_key])
