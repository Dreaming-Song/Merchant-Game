extends Node
## 交互探测器 — 持续扫描玩家前方可交互对象
##
## 自动检测交互目标，发出信号供 HUD 和 Controller 使用
## 支持：可采集物、NPC、可交互物体、战斗目标

# class_name InteractionDetector — 已通过 autoload 注册

signal target_changed(target: Dictionary)  # 检测到新目标
signal target_lost()                        # 目标丢失
signal interaction_performed(target: Dictionary)  # 交互已执行

# ==================== 配置 ====================
@export var scan_radius: float = 5.0
@export var scan_interval: float = 0.1  # 每秒10次
@export var highlight_material: Material = null  # 高亮材质

# ==================== 状态 ====================
var current_target: Dictionary = {}  # 当前检测到的目标
var player: Node3D = null
var camera: Camera3D = null
var _scan_timer: float = 0.0

# Area3D 触发器模式（备用方案，比射线更可靠）
var _proximity_areas: Array[Area3D] = []

func _ready() -> void:
	# 自动找玩家（延迟到下一帧确保 Player._ready() 已注册组）
	call_deferred("_find_player")

func _find_player() -> void:
	player = get_tree().get_first_node_in_group("player")
	if not player:
		var gm = get_node("/root/GameManager") if has_node("/root/GameManager") else null
		if gm and gm.player:
			player = gm.player
		else:
			# 如果还找不到，过一会再试（场景可能还没加载完）
			await get_tree().process_frame
			player = get_tree().get_first_node_in_group("player")
			if not player and gm and gm.player:
				player = gm.player

func setup(p_camera: Camera3D) -> void:
	camera = p_camera

func _process(delta: float) -> void:
	if not camera or not player:
		return
	
	_scan_timer += delta
	if _scan_timer < scan_interval:
		return
	_scan_timer = 0.0
	
	_do_scan()

## 执行射线扫描
func _do_scan() -> void:
	var space_state = camera.get_world_3d().direct_space_state
	var ray_origin = camera.global_position
	var ray_end = ray_origin - camera.global_transform.basis.z * scan_radius
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	
	var new_target: Dictionary = {}
	
	if not result.is_empty():
		var collider = result.get("collider") or null
		if collider:
			new_target = _analyze_target(collider, result.get("position") or Vector3.ZERO)
	
	# 额外：检测附近的 NPC（自动招呼）
	if new_target.is_empty():
		var nearby_npcs = get_tree().get_nodes_in_group("npc")
		var closest_npc = null
		var closest_dist = scan_radius * 2
		for npc in nearby_npcs:
			if not is_instance_valid(npc):
				continue
			var dist = player.global_position.distance_to(npc.global_position)
			if dist < closest_dist and dist < 3.0:
				closest_dist = dist
				closest_npc = npc
		if closest_npc:
			new_target = _analyze_target(closest_npc, closest_npc.global_position)
	
	# 检测变化
	if new_target.is_empty() and not current_target.is_empty():
		_clear_highlight()
		current_target = {}
		target_lost.emit()
	elif not new_target.is_empty():
		var changed = new_target.get("id") or "" != current_target.get("id") or ""
		if changed:
			_clear_highlight()
			current_target = new_target
			_apply_highlight()
			target_changed.emit(current_target)

## 分析碰撞物类型，返回统一格式的目标信息
func _analyze_target(collider: Node, hit_pos: Vector3) -> Dictionary:
	var info: Dictionary = {
		"id": collider.get_instance_id(),
		"node": collider,
		"position": hit_pos,
		"name": collider.name,
		"distance": player.global_position.distance_to(collider.global_position),
	}
	
	# 判断类型
	if collider.has_method("gather"):
		info["type"] = "gatherable"
		info["action"] = "采集"
		info["resource_type"] = collider.get("resource_type") or "wood"
		info["hint"] = collider.get("hint_name") or collider.name
		info["icon"] = "🌿"
	elif collider.has_method("interact"):
		info["type"] = "interactable"
		info["action"] = "交互"
		info["hint"] = collider.get("hint_name") or collider.name
		info["icon"] = "⚡"
	elif collider.is_in_group("npc"):
		info["type"] = "npc"
		info["action"] = "对话"
		info["hint"] = collider.get("display_name") or collider.name
		info["icon"] = "💬"
	elif collider.is_in_group("enemies") or collider.has_method("take_damage"):
		info["type"] = "enemy"
		info["action"] = "攻击"
		info["hint"] = collider.get("enemy_name") or collider.name
		info["icon"] = "⚔️"
	elif collider.is_in_group("interactables"):
		info["type"] = "interactable"
		info["action"] = "打开"
		info["hint"] = collider.get("chest_name") or collider.name
		info["icon"] = "🎁"
	elif collider.has_method("open") or collider.has_method("toggle"):
		info["type"] = "door"
		info["action"] = "开门"
		info["hint"] = collider.name
		info["icon"] = "🚪"
	else:
		info["type"] = "unknown"
		info["action"] = ""
		info["hint"] = ""
		info["icon"] = ""
	
	return info

## 获取交互对应的快捷键提示文本（由 InputHandler 提供）
func get_action_hint() -> String:
	var ih = get_node("/root/InputHandler") if has_node("/root/InputHandler") else null
	if ih and ih.has_method("get_action_hint"):
		return ih.get_action_hint("interact")
	return "E"

## 执行当前目标的交互
func perform_interaction(player_controller: Node) -> Dictionary:
	"""执行交互，返回结果"""
	var result = {"success": false, "reason": "无可交互目标"}
	
	if current_target.is_empty():
		return result
	
	var node = current_target.get("node") or null
	if not node or not is_instance_valid(node):
		current_target = {}
		target_lost.emit()
		return result
	
	var action = current_target.get("action") or ""
	match current_target.get("type") or "":
		"gatherable":
			if node.has_method("gather"):
				node.gather(player_controller)
				result.success = true
				result.action = "gather"
		
		"interactable":
			if node.has_method("interact"):
				node.interact(player_controller)
				result.success = true
				result.action = "interact"
		
		"npc":
			if node.has_method("interact"):
				node.interact(player_controller)
				result.success = true
				result.action = "talk"
			else:
				result.success = true
				result.action = "talk"
			result.npc = node
		
		"enemy":
			result.success = true
			result.action = "attack"
		
		"door":
			if node.has_method("open"):
				node.open()
			elif node.has_method("toggle"):
				node.toggle()
			result.success = true
			result.action = "toggle"
	
	if result.success:
		interaction_performed.emit(current_target)
	
	return result

## 高亮当前目标（轮廓描边效果）
func _apply_highlight() -> void:
	var node = current_target.get("node") or null
	if not node or not is_instance_valid(node):
		return
	if node is MeshInstance3D and highlight_material:
		# 保存原始材质
		if not node.get_meta("_original_material", null):
			node.set_meta("_original_material", node.material_override)
		node.material_override = highlight_material
	elif node is Node3D:
		# 简单高亮：设置发光的 modulation 或添加光环
		pass

func _clear_highlight() -> void:
	var node = current_target.get("node") or null
	if not node or not is_instance_valid(node):
		return
	if node is MeshInstance3D:
		var orig = node.get_meta("_original_material", null)
		if orig:
			node.material_override = orig
			node.remove_meta("_original_material")

func get_current_target() -> Dictionary:
	return current_target.duplicate()
