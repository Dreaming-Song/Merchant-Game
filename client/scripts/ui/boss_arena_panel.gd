extends Control
class_name BossArenaPanel
## 🏯 秘境状态面板 — 显示5个神兽秘境的挑战状态
##
## 快捷键：L 打开/关闭
## 显示每个秘境：名称、元素、状态(可挑战/战斗中/冷却中/已通关)
## 点击进入（检查背包是否有对应传送令牌）
# ==================== 类型预加载 ====================
const _BAMType = preload("res://scripts/combat/boss_arena_manager.gd")
const UIManager = preload("res://scripts/ui/ui_manager.gd")

# ==================== 元素图标 ====================
const ELEMENT_ICONS = {
	"木": "🌿",
	"金": "⚔️",
	"火": "🔥",
	"水": "💧",
	"土": "🗿",
}

const STATE_LABELS = {
	0: "✅ 可挑战",
	1: "⚔️ 战斗中",
	2: "🏆 已通关",
	3: "⏳ 冷却中",
}

const STATE_COLORS = {
	0: Color("#44ff44"),
	1: Color("#ff8844"),
	2: Color("#ffd700"),
	3: Color("#888888"),
}

# ==================== 节点引用 ====================
var _bg: ColorRect
var _title: Label
var _arena_container: VBoxContainer
var _arena_cards: Dictionary = {}  # boss_key -> Control (arena card)
var _close_btn: Button
var _in_arena_label: Label

# ==================== 外部引用 ====================
var _arena_manager: _BAMType = null
var _player: Node = null
var _ui_manager: UIManager = null

# ==================== 信号 ====================
signal panel_closed()

func _init() -> void:
	name = "BossArenaPanel"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	_build_ui()
	_connect_signals()

func _build_ui() -> void:
	"""构建面板UI"""
	# 半透明背景（全屏遮罩）
	_bg = ColorRect.new()
	_bg.name = "Background"
	_bg.color = Color(0, 0, 0, 0.6)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_bg.anchors_preset = Control.PRESET_FULL_RECT
	add_child(_bg)
	_bg.gui_input.connect(_on_bg_input)
	
	# 主面板容器 — 居中
	var panel = Panel.new()
	panel.name = "Panel"
	panel.anchors_preset = Control.PRESET_CENTER
	panel.custom_minimum_size = Vector2(600, 500)
	panel.size = Vector2(600, 500)
	panel.position = Vector2(-300, -250)
	add_child(panel)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainLayout"
	main_vbox.anchors_preset = Control.PRESET_FULL_RECT
	main_vbox.offset_left = 16
	main_vbox.offset_right = -16
	main_vbox.offset_top = 16
	main_vbox.offset_bottom = -16
	main_vbox.add_theme_constant_override("separation", 8)
	panel.add_child(main_vbox)
	
	# ========== 标题行 ==========
	var title_hbox = HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 8)
	
	_title = Label.new()
	_title.text = "🏯 五行秘境"
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", Color("#ffd700"))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title.size_flags_horizontal = SIZE_EXPAND_FILL
	title_hbox.add_child(_title)
	
	_close_btn = Button.new()
	_close_btn.text = "✕ 关闭 (L)"
	_close_btn.pressed.connect(_on_close)
	title_hbox.add_child(_close_btn)
	
	main_vbox.add_child(title_hbox)
	
	# ========== 分隔线 ==========
	var separator = HSeparator.new()
	main_vbox.add_child(separator)
	
	# ========== 秘境卡片列表 ==========
	_arena_container = VBoxContainer.new()
	_arena_container.name = "ArenaCards"
	_arena_container.size_flags_vertical = SIZE_EXPAND_FILL
	_arena_container.add_theme_constant_override("separation", 6)
	main_vbox.add_child(_arena_container)
	
	# ========== 底部信息 ==========
	_in_arena_label = Label.new()
	_in_arena_label.text = ""
	_in_arena_label.add_theme_font_size_override("font_size", 14)
	_in_arena_label.add_theme_color_override("font_color", Color("#88aaff"))
	_in_arena_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(_in_arena_label)
	
	# ========== 提示文字 ==========
	var hint = Label.new()
	hint.text = "💡 使用对应传送令牌进入秘境  |  按 L 关闭"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color("#888888"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(hint)

func _connect_signals() -> void:
	"""连接秘境管理器的信号"""
	_arena_manager = get_tree().get_first_node_in_group("arena_manager")
	if _arena_manager:
		if not _arena_manager.arena_state_changed.is_connected(_on_state_changed):
			_arena_manager.arena_state_changed.connect(_on_state_changed)

func _on_state_changed(boss_key: String, new_state: int) -> void:
	"""秘境状态变化时刷新卡片"""
	_update_card(boss_key)

# ==================== 刷新面板 ====================

## 打开面板时调用
func open() -> void:
	visible = true
	_refresh()

## 刷新所有秘境卡片
func _refresh() -> void:
	if not _arena_manager:
		_arena_manager = get_tree().get_first_node_in_group("arena_manager")
	
	_player = get_tree().get_first_node_in_group("player")
	
	# 清空已有卡片（保留标题等）
	for child in _arena_container.get_children():
		child.queue_free()
	_arena_cards.clear()
	
	# 获取所有秘境信息
	if _arena_manager:
		var all_info = _arena_manager.get_all_arena_info()
		for info in all_info:
			var card = _create_arena_card(info)
			_arena_container.add_child(card)
			_arena_cards[info["key"]] = card
	
	# 检查玩家当前是否在秘境中
	_update_in_arena_label()

func _update_in_arena_label() -> void:
	"""更新底部当前秘境信息"""
	if _arena_manager and _player:
		var current = _arena_manager.get_player_arena(_player)
		if not current.is_empty():
			var cfg = _arena_manager.get_arena_config(current)
			var arena_name = cfg.get("name", current)
			_in_arena_label.text = "📍 当前位于：%s  |  到出口传送门离开" % arena_name
		else:
			_in_arena_label.text = ""
	else:
		_in_arena_label.text = ""

# ==================== 创建秘境卡片 ====================

func _create_arena_card(info: Dictionary) -> Control:
	"""创建一个秘境卡片UI"""
	var card = Panel.new()
	card.name = "Card_%s" % info["key"]
	card.custom_minimum_size = Vector2(0, 72)
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	card_style.border_width_left = 3
	card_style.border_color = info["color"]
	card_style.corner_radius_top_left = 6
	card_style.corner_radius_top_right = 6
	card_style.corner_radius_bottom_left = 6
	card_style.corner_radius_bottom_right = 6
	card.add_theme_stylebox_override("panel", card_style)
	
	var hbox = HBoxContainer.new()
	hbox.anchors_preset = Control.PRESET_FULL_RECT
	hbox.offset_left = 12
	hbox.offset_right = -12
	hbox.offset_top = 8
	hbox.offset_bottom = -8
	hbox.add_theme_constant_override("separation", 12)
	card.add_child(hbox)
	
	# 元素图标
	var icon_label = Label.new()
	icon_label.text = ELEMENT_ICONS.get(info["element"], "❓")
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.custom_minimum_size = Vector2(50, 0)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon_label)
	
	# 中间信息
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	
	var name_label = Label.new()
	name_label.text = info["name"]
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	info_vbox.add_child(name_label)
	
	var state_label = Label.new()
	state_label.name = "StateLabel"
	state_label.text = STATE_LABELS.get(info["state"], "未知")
	state_label.add_theme_font_size_override("font_size", 14)
	state_label.add_theme_color_override("font_color", STATE_COLORS.get(info["state"], Color.GRAY))
	info_vbox.add_child(state_label)
	
	# 冷却倒计时标签
	var cooldown_label = Label.new()
	cooldown_label.name = "CooldownLabel"
	cooldown_label.add_theme_font_size_override("font_size", 12)
	cooldown_label.add_theme_color_override("font_color", Color("#ff8844"))
	cooldown_label.visible = info["state"] == 3  # COOLDOWN
	if info["state"] == 3:
		cooldown_label.text = "剩余 %d 秒" % int(info["cooldown"])
	info_vbox.add_child(cooldown_label)
	
	hbox.add_child(info_vbox)
	
	# 右侧操作按钮
	var btn_vbox = VBoxContainer.new()
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_vbox.add_theme_constant_override("separation", 4)
	
	var enter_btn = Button.new()
	enter_btn.name = "EnterBtn"
	enter_btn.text = _get_button_text(info)
	enter_btn.custom_minimum_size = Vector2(100, 36)
	enter_btn.disabled = info["state"] != 0  # 仅 AVAILABLE 可点击
	enter_btn.pressed.connect(_on_enter_arena.bind(info["key"], enter_btn))
	btn_vbox.add_child(enter_btn)
	
	# 令牌合成提示
	var pass_name = _get_pass_name(info["key"])
	var pass_hint = Label.new()
	pass_hint.name = "PassHint"
	pass_hint.text = "所需: %s" % pass_name
	pass_hint.add_theme_font_size_override("font_size", 10)
	pass_hint.add_theme_color_override("font_color", Color("#aaaaaa"))
	btn_vbox.add_child(pass_hint)
	
	hbox.add_child(btn_vbox)
	
	# 储存状态标签引用，方便后续更新
	card.set_meta("state_label", state_label)
	card.set_meta("cooldown_label", cooldown_label)
	card.set_meta("enter_btn", enter_btn)
	card.set_meta("pass_hint", pass_hint)
	card.set_meta("info", info)
	
	return card

# ==================== 更新单张卡片 ====================

func _update_card(boss_key: String) -> void:
	"""刷新指定秘境卡片的状态"""
	var card = _arena_cards.get(boss_key)
	if not card: return
	
	var state_label = card.get_meta("state_label") as Label
	var cooldown_label = card.get_meta("cooldown_label") as Label
	var enter_btn = card.get_meta("enter_btn") as Button
	# 刷新信息
	if not _arena_manager: return
	
	var info_list = _arena_manager.get_all_arena_info()
	var info = {}
	for i in info_list:
		if i["key"] == boss_key:
			info = i
			break
	
	if info.is_empty(): return
	
	var state = info["state"]
	state_label.text = STATE_LABELS.get(state, "未知")
	state_label.modulate = STATE_COLORS.get(state, Color.GRAY)
	
	# 冷却显示
	cooldown_label.visible = state == 3
	if state == 3:
		cooldown_label.text = "剩余 %d 秒" % int(info["cooldown"])
	
	# 按钮状态
	enter_btn.disabled = state != 0
	enter_btn.text = _get_button_text(info)
	
	# 边界颜色闪烁效果（战斗中）
	if state == 1:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.1, 0.1, 0.8)
		style.border_width_left = 3
		style.border_color = Color("#ff4400")
		style.corner_radius = 6
		card.add_theme_stylebox_override("panel", style)
	else:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
		style.border_width_left = 3
		style.border_color = info.get("color") or Color.GRAY
		style.corner_radius = 6
		card.add_theme_stylebox_override("panel", style)
	
	card.set_meta("info", info)

# ==================== 按钮交互 ====================

func _on_enter_arena(boss_key: String, btn: Button) -> void:
	"""点击进入秘境"""
	if not _arena_manager or not _player:
		_show_short_message("系统未就绪")
		return
	
	# 检查背包是否有对应传送令牌
	var pass_item_id = _get_pass_item_id(boss_key)
	var inventory = _get_player_inventory()
	
	if not inventory or not _has_item(inventory, pass_item_id):
		_show_short_message("需要 %s 才能进入！" % _get_pass_name(boss_key))
		return
	
	# 消耗一个令牌并进入
	if _consume_item(inventory, pass_item_id):
		var success = _arena_manager.enter_arena(boss_key, _player)
		if success:
			_show_short_message("🏯 传送至 %s！" % (_arena_manager.get_arena_config(boss_key).get("name") or ""))
			_update_in_arena_label()
		else:
			_show_short_message("❌ 进入秘境失败")
	else:
		_show_short_message("❌ 使用令牌失败")

func _on_close() -> void:
	"""关闭面板"""
	visible = false
	panel_closed.emit()

func _on_bg_input(event: InputEvent) -> void:
	"""点击背景关闭"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_close()

# ==================== 工具方法 ====================

func _get_button_text(info: Dictionary) -> String:
	match info["state"]:
		0: return "🚪 进入秘境"
		1: return "⚔️ 战斗中"
		2: return "🏆 已通关"
		3: return "⏳ 冷却中"
		_: return "未知"

func _get_pass_name(boss_key: String) -> String:
	match boss_key:
		"azure_dragon": return "青龙令"
		"white_tiger": return "白虎令"
		"vermilion_bird": return "朱雀令"
		"black_warrior": return "玄武令"
		"golden_qilin": return "麒麟令"
		_: return "未知令牌"

func _get_pass_item_id(boss_key: String) -> String:
	match boss_key:
		"azure_dragon": return "azure_pass"
		"white_tiger": return "tiger_pass"
		"vermilion_bird": return "bird_pass"
		"black_warrior": return "turtle_pass"
		"golden_qilin": return "qilin_pass"
		_: return ""

func _get_player_inventory() -> Node:
	"""获取玩家背包"""
	var gm = get_node("/root/GameManager")
	if gm and gm.has_method("get_inventory"):
		return gm.get_inventory()
	if gm and gm.has("inventory"):
		return gm.inventory
	return null

func _has_item(inventory: Node, item_id: String) -> bool:
	"""检查背包是否有某物品"""
	if inventory.has_method("has_item"):
		return inventory.has_item(item_id)
	if inventory.has_method("count_item"):
		return inventory.count_item(item_id) > 0
	return false

func _consume_item(inventory: Node, item_id: String) -> bool:
	"""从背包消耗一个物品"""
	if inventory.has_method("remove_item"):
		return inventory.remove_item(item_id, 1)
	if inventory.has_method("consume_item"):
		return inventory.consume_item(item_id, 1)
	return false

# ==================== 短时消息提示 ====================

var _msg_label: Label = null
var _msg_timer: float = 0.0

func _show_short_message(text: String) -> void:
	"""在面板内显示短暂提示"""
	if not _msg_label:
		_msg_label = Label.new()
		_msg_label.name = "ShortMessage"
		_msg_label.add_theme_font_size_override("font_size", 16)
		_msg_label.add_theme_color_override("font_color", Color("#ffcc00"))
		_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_msg_label.anchors_preset = Control.PRESET_CENTER
		_msg_label.position = Vector2(-150, 200)
		_msg_label.custom_minimum_size = Vector2(300, 40)
		add_child(_msg_label)
	
	_msg_label.text = text
	_msg_label.visible = true
	_msg_timer = 2.5
	
	# 如果进程循环还没跑，手动启动
	if not is_inside_tree(): return
	var tween = create_tween()
	tween.tween_property(_msg_label, "modulate:a", 0.0, 2.0).set_delay(0.5)

func _process(delta: float) -> void:
	# 冷却倒计时更新（每帧刷新）
	if not visible or not _arena_manager: return
	
	for boss_key in _arena_cards.keys():
		var card = _arena_cards[boss_key]
		if not card: continue
		
		var info = card.get_meta("info", {}) as Dictionary
		if info.is_empty(): continue
		
		# 冷却中更新倒计时
		if info["state"] == 3:
			var cd = _arena_manager.arena_cooldown_timers.get(boss_key, 0.0)
			var cooldown_label = card.get_meta("cooldown_label") as Label
			if cooldown_label and cd > 0:
				cooldown_label.text = "剩余 %d 秒" % int(cd)
		
		# 战斗进行中更新边框闪烁（简化：每帧更新）
		if info["state"] == 1:
			var phase = sin(Time.get_ticks_msec() * 0.005) * 0.3 + 0.7
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.15, 0.1, 0.1, 0.8)
			style.border_width_left = 3
			style.border_color = Color(1.0, 0.3, 0.0, phase)
			style.corner_radius = 6
			card.add_theme_stylebox_override("panel", style)
