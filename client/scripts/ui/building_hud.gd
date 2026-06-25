extends Control
## 建造模式 HUD 覆盖层
## 显示当前选中的方块名、破坏进度条

class_name BuildingHUD

var _block_name_label: Label
var _break_progress_bar: ProgressBar
var _building_mode = null  # BuildingMode

func _ready() -> void:
	# 动态创建子节点（没有 .tscn）
	_create_ui_elements()
	
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # 不拦截点击
	
	# 监听建造模式
	# 用组查找获取玩家（兼容不同场景结构）
	var player = get_tree().get_first_node_in_group("player") if get_tree() else null
	if player and player.has_node("BuildingMode"):
		_building_mode = player.get_node("BuildingMode")
		_building_mode.building_mode_toggled.connect(_on_mode_toggled)
		_building_mode.block_placed.connect(_on_block_placed)
		_building_mode.block_broken.connect(_on_block_broken)

func _create_ui_elements() -> void:
	"""手动创建 Label 和 ProgressBar"""
	# ——— 方块名标签（左上角） ———
	_block_name_label = Label.new()
	_block_name_label.name = "BlockName"
	_block_name_label.position = Vector2(12, 12)
	_block_name_label.add_theme_font_size_override("font_size", 16)
	_block_name_label.modulate = Color(0.9, 1.0, 0.85)
	_block_name_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_block_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_block_name_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_block_name_label)
	
	# ——— 破坏进度条（十字线下方） ———
	_break_progress_bar = ProgressBar.new()
	_break_progress_bar.name = "BreakProgress"
	_break_progress_bar.size = Vector2(180, 12)
	_break_progress_bar.position = Vector2(
		get_viewport_rect().size.x / 2.0 - 90,
		get_viewport_rect().size.y / 2.0 + 30
	)
	_break_progress_bar.max_value = 100.0
	_break_progress_bar.value = 0.0
	_break_progress_bar.visible = false
	_break_progress_bar.modulate = Color(0.9, 0.3, 0.3)
	add_child(_break_progress_bar)
	
	# 窗口大小变化时更新位置
	resized.connect(_on_resized)

func _on_resized() -> void:
	if _break_progress_bar:
		_break_progress_bar.position = Vector2(
			size.x / 2.0 - 90,
			size.y / 2.0 + 30
		)

func _process(delta: float) -> void:
	if not visible or not _building_mode:
		return
	
	var info = _building_mode.get_selected_info()
	
	# 更新方块名
	if _block_name_label:
		var item_id = info.get("item_id") or ""
		var name_str = "未知方块"
		if not item_id.is_empty():
			var db = get_node("/root/ItemDatabase") if has_node("/root/ItemDatabase") else null
			if db and db.has_method("get_item_name"):
				name_str = db.get_item_name(item_id)
			else:
				name_str = item_id
		_block_name_label.text = "🔨 %s" % name_str
	
	# 更新破坏进度
	if _break_progress_bar:
		var progress = info.get("break_progress") or 0.0
		_break_progress_bar.value = progress * 100.0
		_break_progress_bar.visible = progress > 0.01

func _on_mode_toggled(active: bool) -> void:
	visible = active

func _on_block_placed(piece_type: int, position: Vector3) -> void:
	modulate = Color(0.8, 1.0, 0.8)
	await get_tree().create_timer(0.15).timeout
	modulate = Color.WHITE

func _on_block_broken(position: Vector3) -> void:
	modulate = Color(1.0, 0.8, 0.8)
	await get_tree().create_timer(0.15).timeout
	modulate = Color.WHITE
