extends Node
## 建造模式 — MC风格方块放置/破坏
##
## 按 B 进入建造模式，显示半透明预览方块
## 左键放置，右键长按破坏（带裂纹效果）

class_name BuildingMode

# ==================== 信号（给 HUD/UI 用） ====================
signal building_mode_toggled(active: bool)
signal block_placed(piece_type: int, position: Vector3)
signal block_broken(position: Vector3)

# 程序化音效资源 (运行时加载)
var _sfx_place_wav: AudioStreamWAV = null
var _sfx_break_wav: AudioStreamWAV = null
var _sfx_player: AudioStreamPlayer = null

# ==================== 引用 ====================
var _building_system: BuildingSystem
var _player: Node3D
var _camera: Camera3D
var _inventory: Node

# ==================== 状态 ====================
var is_building_mode: bool = false
var _selected_piece_type: int = BuildingSystem.PieceType.WALL
var _selected_tier: int = 0
var _selected_item_id: String = ""

# ==================== 预览 ====================
var _ghost_block: MeshInstance3D = null
var _target_pos: Vector3 = Vector3.ZERO
var _target_normal: Vector3 = Vector3.ZERO
var _can_place: bool = false
var _can_break: bool = false
var _breaking_pos: Vector3 = Vector3.ZERO
var _break_progress: float = 0.0
var _is_breaking: bool = false

# ==================== 参数 ====================
var _build_range: float = 8.0
var _break_time: float = 1.5  # 徒手破坏时间
var _ray_length: float = 10.0
var _ghost_alpha: float = 0.4
var _grid_size: float = 1.0

# ==================== 材质 ====================
var _ghost_material_valid: StandardMaterial3D
var _ghost_material_invalid: StandardMaterial3D

# ==================== 初始化 ====================
func _ready() -> void:
	_building_system = get_node("/root/GameManager/BuildingSystem") if has_node("/root/GameManager/BuildingSystem") else null
	
	# 创建幽灵材质
	_ghost_material_valid = StandardMaterial3D.new()
	_ghost_material_valid.albedo_color = Color(0.3, 1.0, 0.3, _ghost_alpha)
	_ghost_material_valid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_material_valid.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	_ghost_material_invalid = StandardMaterial3D.new()
	_ghost_material_invalid.albedo_color = Color(1.0, 0.3, 0.3, _ghost_alpha)
	_ghost_material_invalid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_material_invalid.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# 创建预览方块
	_ghost_block = MeshInstance3D.new()
	_ghost_block.name = "BuildingGhost"
	_ghost_block.mesh = BoxMesh.new()
	_ghost_block.mesh.size = Vector3.ONE * _grid_size
	_ghost_block.mesh.material = _ghost_material_valid
	_ghost_block.visible = false
	add_child(_ghost_block)
	
	# 加载程序化音效
	_load_sfx()

# ==================== 程序化音效 ====================
func _load_sfx() -> void:
	"""加载程序化生成的两个 WAV 音效"""
	var place_path = "res://assets/sounds/block_place.wav"
	var break_path = "res://assets/sounds/block_break.wav"
	
	if ResourceLoader.exists(place_path):
		_sfx_place_wav = load(place_path) as AudioStreamWAV
	if ResourceLoader.exists(break_path):
		_sfx_break_wav = load(break_path) as AudioStreamWAV
	
	# 创建音频播放器
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "BuildingSFX"
	add_child(_sfx_player)

func _play_sfx(type: String) -> void:
	"""播放音效: 'place' 或 'break'"""
	if not _sfx_player:
		return
	match type:
		"place":
			_sfx_player.stream = _sfx_place_wav
		"break":
			_sfx_player.stream = _sfx_break_wav
	
	if _sfx_player.stream:
		_sfx_player.play()

# ==================== 建造模式开关 ====================

func toggle_building_mode(player: Node3D, camera: Camera3D) -> bool:
	"""切换建造模式开关"""
	if _player:
		_exit_building_mode()
		return false
	
	_enter_building_mode(player, camera)
	return true

func _enter_building_mode(player: Node3D, camera: Camera3D) -> void:
	_player = player
	_camera = camera
	is_building_mode = true
	
	# 获取建筑系统引用
	if not _building_system:
		_building_system = get_node("/root/GameManager/BuildingSystem") if has_node("/root/GameManager/BuildingSystem") else null
	
	# 获取背包引用
	_inventory = get_node("/root/GameManager/Inventory") if has_node("/root/GameManager/Inventory") else null
	
	# 默认选中第一件建筑
	_auto_select_building()
	
	# 确保方块容器存在
	_ensure_block_container()
	
	# 显示预览
	_ghost_block.visible = true
	
	# 显示鼠标（方便点击）
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	building_mode_toggled.emit(true)
	print("🏗️ 进入建造模式")

func _exit_building_mode() -> void:
	is_building_mode = false
	_ghost_block.visible = false
	
	# 如果正在破坏，取消
	if _is_breaking:
		_cancel_breaking()
	
	# 恢复鼠标
	if not _is_any_panel_open():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	building_mode_toggled.emit(false)
	print("🏗️ 退出建造模式")

# ==================== 每帧更新 ====================

func _process(delta: float) -> void:
	if not is_building_mode or not _player or not _camera:
		return
	
	_update_raycast()
	_update_ghost()
	
	# 处理破坏进度
	if _is_breaking:
		_break_progress += delta / _break_time
		if _break_progress >= 1.0:
			_do_break()
			# 破坏后看下一个目标
			_is_breaking = false
			_break_progress = 0.0

func _update_raycast() -> void:
	"""从玩家视角发射射线，检测目标方块位置"""
	var center = _camera.get_viewport().get_visible_rect().size / 2.0
	var from = _camera.project_ray_origin(center)
	var dir = _camera.project_ray_normal(center)
	var to = from + dir * _ray_length
	
	var space_state = _player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [_player]
	query.collide_with_areas = false
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_pos = result.position
		var normal = result.normal
		var grid_hit = _building_system._snap_to_grid(hit_pos) if _building_system else hit_pos.snapped(Vector3.ONE)
		
		_target_normal = normal
		
		# 放置位置 = 点击的面往法线方向偏移一个格子
		var place_pos = _building_system._snap_to_grid(hit_pos + normal * (_grid_size * 0.5)) if _building_system else \
			(hit_pos + normal * (_grid_size * 0.5)).snapped(Vector3.ONE)
		
		_target_pos = place_pos
		
		# 检查是否可以放置
		var dist = _player.global_position.distance_to(place_pos)
		var piece_exists = _building_system and not _building_system.get_piece_at(place_pos).is_empty()
		
		_can_place = dist <= _build_range and not piece_exists
		_can_break = dist <= _build_range and piece_exists
		_breaking_pos = grid_hit
	else:
		_can_place = false
		_can_break = false
		_target_pos = from + dir * _ray_length

func _update_ghost() -> void:
	"""更新预览方块位置和颜色"""
	if not _ghost_block:
		return
	
	if _can_place:
		_ghost_block.global_position = _target_pos + Vector3(0.5, 0.5, 0.5) * _grid_size
		_ghost_block.visible = true
		_ghost_block.mesh.material = _ghost_material_valid
	else:
		_ghost_block.visible = false

# ==================== 放置方块 ====================

func try_place() -> bool:
	"""尝试在当前目标位置放置方块"""
	if not _can_place or not _building_system or _selected_item_id.is_empty():
		return false
	
	# 检查背包是否有该物品
	if _inventory and not _inventory.has_item(_selected_item_id, 1):
		print("❌ 背包中没有 %s" % _selected_item_id)
		return false
	
	# 放置方块
	var result = _building_system.try_place(_selected_piece_type, _selected_tier, _target_pos)
	
	if result.get("success", false):
		# 消耗物品
		if _inventory:
			_inventory.remove_item(_selected_item_id, 1)
		
		# 在场景中创建方块视觉
		_create_block_visual(_selected_piece_type, _selected_tier, _target_pos)
		_play_sfx("place")
		
		block_placed.emit(_selected_piece_type, _target_pos)
		return true
	
	return false

func _create_block_visual(piece_type: int, tier: int, pos: Vector3) -> void:
	"""在场景中创建带碰撞的方块Mesh"""
	# 防重复：该位置已有方块节点
	_ensure_block_container()
	var block_name = "Block_%d_%d_%d" % [int(pos.x), int(pos.y), int(pos.z)]
	if _block_container.has_node(block_name):
		return  # 已存在，跳过
	
	# 使用 StaticBody3D 提供碰撞
	var block = StaticBody3D.new()
	block.name = block_name
	block.position = pos + Vector3(0.5, 0.5, 0.5)  # 中心对齐
	
	# ————— 碰撞形状 —————
	var shape: CollisionShape3D
	match piece_type:
		BuildingSystem.PieceType.WALL, BuildingSystem.PieceType.DOOR:
			shape = CollisionShape3D.new()
			shape.shape = BoxShape3D.new()
			shape.shape.size = Vector3(1.0, 1.0, 0.15)
		BuildingSystem.PieceType.FLOOR:
			shape = CollisionShape3D.new()
			shape.shape = BoxShape3D.new()
			shape.shape.size = Vector3(1.0, 0.15, 1.0)
		BuildingSystem.PieceType.FOUNDATION:
			shape = CollisionShape3D.new()
			shape.shape = BoxShape3D.new()
			shape.shape.size = Vector3(1.0, 0.3, 1.0)
		BuildingSystem.PieceType.PILLAR:
			shape = CollisionShape3D.new()
			shape.shape = CylinderShape3D.new()
			shape.shape.radius = 0.15
			shape.shape.height = 1.0
		BuildingSystem.PieceType.ROOF:
			shape = CollisionShape3D.new()
			shape.shape = BoxShape3D.new()
			shape.shape.size = Vector3(1.0, 0.5, 1.0)
		_:
			shape = CollisionShape3D.new()
			shape.shape = BoxShape3D.new()
			shape.shape.size = Vector3.ONE
	block.add_child(shape)
	
	# ————— 可视Mesh —————
	var mesh = MeshInstance3D.new()
	match piece_type:
		BuildingSystem.PieceType.WALL, BuildingSystem.PieceType.DOOR:
			mesh.mesh = BoxMesh.new()
			mesh.mesh.size = Vector3(1.0, 1.0, 0.15)
		BuildingSystem.PieceType.FLOOR:
			mesh.mesh = BoxMesh.new()
			mesh.mesh.size = Vector3(1.0, 0.15, 1.0)
		BuildingSystem.PieceType.ROOF:
			mesh.mesh = PrismMesh.new()
			mesh.mesh.size = Vector3(1.0, 0.5, 1.0)
		BuildingSystem.PieceType.PILLAR:
			mesh.mesh = CylinderMesh.new()
			mesh.mesh.top_radius = 0.1
			mesh.mesh.bottom_radius = 0.15
			mesh.mesh.height = 1.0
		BuildingSystem.PieceType.FOUNDATION:
			mesh.mesh = BoxMesh.new()
			mesh.mesh.size = Vector3(1.0, 0.3, 1.0)
		_:
			mesh.mesh = BoxMesh.new()
			mesh.mesh.size = Vector3.ONE
	
	# 材质颜色（按等级） + 程序化纹理
	var tier_data = BuildingSystem.get_tier_data(tier)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = tier_data.color
	mat.albedo_texture = _generate_block_texture(piece_type)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.uv1_scale = Vector3(1.0, 1.0, 1.0)
	mat.metallic = float(tier) / 8.0 * 0.5
	mat.roughness = 0.8 - float(tier) / 8.0 * 0.4
	mesh.mesh.material = mat
	
	block.add_child(mesh)
	
	# 添加到场景方块容器
	_ensure_block_container()
	_block_container.add_child(block)
	block.owner = _block_container.owner if _block_container.owner else block

func _create_prism_mesh() -> PrismMesh:
	"""创建屋顶棱柱Mesh"""
	var prism = PrismMesh.new()
	prism.size = Vector3(1.0, 0.5, 1.0)
	return prism

# ==================== 破坏方块 ====================

func start_break() -> void:
	"""开始破坏方块（按住右键）"""
	if not _can_break or _breaking_pos == Vector3.ZERO:
		return
	
	_is_breaking = true
	_break_progress = 0.0
	
	# 获取当前方块的基础破坏时间
	var piece = _building_system.get_piece_at(_breaking_pos)
	if not piece.is_empty():
		var tier = piece.get("tier", 0)
		_break_time = 1.0 + tier * 0.5  # 高等级更慢

func cancel_break() -> void:
	"""取消破坏"""
	_cancel_breaking()

func _cancel_breaking() -> void:
	_is_breaking = false
	_break_progress = 0.0

func _do_break() -> void:
	"""执行破坏"""
	if not _building_system:
		return
	
	var result = _building_system.demolish(_breaking_pos)
	if result.get("success", false):
		# 移除场景中的Mesh
		_remove_block_visual(_breaking_pos)
		_spawn_break_particles(_breaking_pos)
		block_broken.emit(_breaking_pos)
		_play_sfx("break")
		print("💥 破坏方块于 (%d, %d, %d)" % [int(_breaking_pos.x), int(_breaking_pos.y), int(_breaking_pos.z)])

func _remove_block_visual(pos: Vector3) -> void:
	"""移除场景中的方块（StaticBody3D + MeshInstance3D）"""
	var name = "Block_%d_%d_%d" % [int(pos.x), int(pos.y), int(pos.z)]
	# 优先在方块容器中找
	var existing = null
	if _block_container and is_instance_valid(_block_container):
		existing = _block_container.get_node(name) if _block_container.has_node(name) else null
	if not existing:
		existing = get_tree().root.get_node(name) if get_tree().root.has_node(name) else null
	if existing:
		existing.queue_free()

func _spawn_break_particles(pos: Vector3) -> void:
	"""破坏粒子：生成几个小碎片飞散"""
	var colors = [Color(0.6, 0.4, 0.2), Color(0.5, 0.35, 0.15), Color(0.4, 0.3, 0.1)]
	for i in range(6):
		var frag = MeshInstance3D.new()
		frag.name = "BreakFragment_%d" % i
		frag.position = pos + Vector3(0.5, 0.5, 0.5)
		
		var box = BoxMesh.new()
		box.size = Vector3(0.08, 0.08, 0.08)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = colors[i % colors.size()]
		box.material = mat
		frag.mesh = box
		
		# 随机速度
		var dir = Vector3(
			randf_range(-1.0, 1.0),
			randf_range(0.3, 1.0),
			randf_range(-1.0, 1.0)
		).normalized() * randf_range(1.5, 3.5)
		
		# 用 TemporaryFragment 节点处理物理和自销毁
		var temp = Node3D.new()
		temp.name = "TempParticle_%d" % i
		temp.add_child(frag)
		temp.set_script(preload("res://scripts/effects/temporary_fragment.gd"))
		if temp.has_method("init"):
			temp.init(dir, 0.8)
		add_child(temp)

# ==================== 方块选择 ====================

func select_building(piece_type: int, item_id: String) -> void:
	"""选择要建造的方块类型"""
	_selected_piece_type = piece_type
	_selected_item_id = item_id
	
	# 获取物品的等级
	if _inventory:
		var item_data = _inventory.get_item_data(item_id)
		if item_data:
			_selected_tier = item_data.get("tier", 0)
	
	# 更新预览方块形状
	_update_ghost_mesh()

func _update_ghost_mesh() -> void:
	"""根据选择的方块类型更新预览Mesh"""
	if not _ghost_block:
		return
	
	match _selected_piece_type:
		BuildingSystem.PieceType.WALL:
			var box = BoxMesh.new()
			box.size = Vector3(1.0, 1.0, 0.15)
			_ghost_block.mesh = box
		BuildingSystem.PieceType.FLOOR:
			var box = BoxMesh.new()
			box.size = Vector3(1.0, 0.15, 1.0)
			_ghost_block.mesh = box
		_:
			var box = BoxMesh.new()
			box.size = Vector3.ONE
			_ghost_block.mesh = box

func _auto_select_building() -> void:
	"""自动选中背包中第一个建筑物品"""
	if not _inventory:
		return
	
	for i in range(_inventory.get_slot_count()):
		var slot = _inventory.get_slot(i)
		if slot and not slot.item_id.is_empty():
			var item_data = _inventory.get_item_data(slot.item_id)
			if item_data and item_data.get("category", -1) == ItemDatabase.ItemCategory.BUILDING:
				var piece_type = item_data.get("piece_type", BuildingSystem.PieceType.WALL)
				select_building(piece_type, slot.item_id)
				return

# ==================== 鼠标输入 ====================

func _input(event: InputEvent) -> void:
	if not is_building_mode:
		return
	
	# 左键放置
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		try_place()
	
	# 右键开始/结束破坏
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			start_break()
		else:
			cancel_break()
	
	# 滚轮切换方块
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		_cycle_building(event.button_index == MOUSE_BUTTON_WHEEL_DOWN)

func _cycle_building(forward: bool) -> void:
	"""滚轮循环切换建筑类型"""
	if not _inventory:
		return
	
	var building_items: Array[Dictionary] = []
	for i in range(_inventory.get_slot_count()):
		var slot = _inventory.get_slot(i)
		if slot and not slot.item_id.is_empty():
			var item_data = _inventory.get_item_data(slot.item_id)
			if item_data and item_data.get("category", -1) == ItemDatabase.ItemCategory.BUILDING:
				building_items.append({"slot": slot, "data": item_data})
	
	if building_items.size() == 0:
		return
	
	# 找到当前选中索引
	var current_idx = -1
	for i in range(building_items.size()):
		if building_items[i].slot.item_id == _selected_item_id:
			current_idx = i
			break
	
	# 切换到下一个/上一个
	if forward:
		current_idx = (current_idx + 1) % building_items.size()
	else:
		current_idx = (current_idx - 1 + building_items.size()) % building_items.size()
	
	var target = building_items[current_idx]
	var piece_type = target.data.get("piece_type", BuildingSystem.PieceType.WALL)
	select_building(piece_type, target.slot.item_id)
	print("🔨 切换至: %s" % target.data.get("name", "未知"))

# ==================== 辅助 ====================

func _is_any_panel_open() -> bool:
	var ui = get_node("/root/UIManager") if has_node("/root/UIManager") else null
	if ui and ui.has_method("is_any_panel_open"):
		return ui.is_any_panel_open()
	return false

func get_break_progress() -> float:
	return _break_progress if _is_breaking else 0.0

func get_selected_info() -> Dictionary:
	return {
		"piece_type": _selected_piece_type,
		"item_id": _selected_item_id,
		"target_pos": _target_pos,
		"can_place": _can_place,
		"can_break": _can_break,
		"break_progress": _break_progress if _is_breaking else 0.0,
	}

## 确保方块容器节点存在
var _block_container: Node = null
func _ensure_block_container() -> void:
	if _block_container and is_instance_valid(_block_container):
		return
	_block_container = get_tree().root.get_node("BuiltBlocks") if get_tree().root.has_node("BuiltBlocks") else null
	if not _block_container:
		_block_container = Node3D.new()
		_block_container.name = "BuiltBlocks"
		_block_container.top_level = false
		get_tree().root.add_child(_block_container)

## 程序化生成方块纹理（无需外部图片）
static func _generate_block_texture(piece_type: int) -> ImageTexture:
	var size = 64
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# 基础色 — 让纹理自带微明暗，最终仍会被 tier_color 覆盖
	var light: Color = Color(1.0, 1.0, 1.0)
	var dark: Color = Color(0.7, 0.7, 0.7)
	
	match piece_type:
		BuildingSystem.PieceType.WALL:
			# 砖墙图案：交错排砖
			var brick_h = size / 8
			var brick_w = size / 4
			for row in range(8):
				var offset = (brick_w / 2) if row % 2 == 0 else 0
				for col in range(4):
					var x0 = col * brick_w + offset
					var y0 = row * brick_h
					var c = dark if (row + col) % 2 == 0 else light
					for x in range(brick_w - 1):
						for y in range(brick_h - 1):
							var px = x0 + x
							var py = y0 + y
							if px < size and py < size:
								img.set_pixel(px, py, c)
					# 砖缝（较暗）
					for x in range(brick_w):
						if x0 + x < size:
							img.set_pixel(x0 + x, y0 + brick_h - 2, Color(0.2, 0.15, 0.1))
		
		BuildingSystem.PieceType.FLOOR:
			# 木地板：纵向木板条
			var plank_w = size / 8
			for i in range(8):
				var x0 = i * plank_w
				var c = light if i % 2 == 0 else dark
				for x in range(plank_w - 1):
					for y in range(size):
						var px = x0 + x
						var noise = 0.05 * sin(y * 0.3 + i * 1.2)
						var final_c = Color(
							clamp(c.r + noise, 0.0, 1.0),
							clamp(c.g + noise * 0.7, 0.0, 1.0),
							clamp(c.b + noise * 0.5, 0.0, 1.0)
						)
						img.set_pixel(px, y, final_c)
				# 木板缝隙
				for y in range(size):
					img.set_pixel(x0 + plank_w - 1, y, Color(0.15, 0.1, 0.05))
		
		BuildingSystem.PieceType.FOUNDATION:
			# 碎石/鹅卵石：随机斑点
			for x in range(size):
				for y in range(size):
					var noise = sin(x * 0.3) * cos(y * 0.25) * 0.15
					var c = Color(0.6 + noise, 0.58 + noise, 0.55 + noise)
					img.set_pixel(x, y, c)
			# 随机石子
			for _i in range(40):
				var sx = randi() % size
				var sy = randi() % size
				for dx in range(-2, 3):
					for dy in range(-2, 3):
						var px = sx + dx
						var py = sy + dy
						if px >= 0 and px < size and py >= 0 and py < size:
							img.set_pixel(px, py, Color(0.45, 0.4, 0.35))
		
		BuildingSystem.PieceType.ROOF:
			# 瓦片图案：半圆叠瓦
			var tile_r = 6
			for row in range(0, size, tile_r * 2):
				var offset_x = tile_r if (row / (tile_r * 2)) as int % 2 == 1 else 0
				for col in range(offset_x, size, tile_r * 2):
					for dx in range(-tile_r, tile_r):
						for dy in range(-tile_r, 0):
							if dx * dx + dy * dy < tile_r * tile_r:
								var px = col + dx
								var py = row + dy + tile_r
								if px >= 0 and px < size and py >= 0 and py < size:
									img.set_pixel(px, py, light)
					# 瓦片下缘阴影
					for dx in range(-tile_r, tile_r):
						var px = col + dx
						var py = row + tile_r
						if px >= 0 and px < size and py >= 0 and py < size:
							img.set_pixel(px, py, Color(0.3, 0.25, 0.2))
		
		BuildingSystem.PieceType.PILLAR:
			# 大理石纹：流动条纹
			for x in range(size):
				for y in range(size):
					var noise = sin(x * 0.2 + y * 0.15) * cos(x * 0.1 - y * 0.2) * 0.1
					var c = Color(0.85 + noise, 0.82 + noise, 0.78 + noise)
					img.set_pixel(x, y, c)
			# 细纹
			for _i in range(15):
				var bx = randi() % size
				var by = randi() % size
				var angle = randf() * PI
				for t in range(20):
					var px = bx + int(cos(angle) * t)
					var py = by + int(sin(angle) * t)
					if px >= 0 and px < size and py >= 0 and py < size:
						img.set_pixel(px, py, Color(0.6, 0.58, 0.55))
		
		_:
			# 默认：细砂纹理
			for x in range(size):
				for y in range(size):
					var noise = sin(x * 0.5 + y * 0.3) * 0.08
					var c = Color(0.75 + noise, 0.72 + noise, 0.68 + noise)
					img.set_pixel(x, y, c)
	
	return ImageTexture.create_from_image(img)
