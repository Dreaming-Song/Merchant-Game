extends CanvasLayer
## 基础 HUD - Phase 2
## 显示血量、法力、法术冷却、灵宠信息、上下文交互提示
const BossArenaManager = preload("res://scripts/combat/boss_arena_manager.gd")

@onready var hp_bar: ProgressBar = $TopBar/HpBar
@onready var mp_bar: ProgressBar = $TopBar/MpBar
@onready var hp_label: Label = $TopBar/HpBar/Label
@onready var mp_label: Label = $TopBar/MpBar/Label
@onready var spell_container: Container = $BottomBar/SpellContainer
@onready var pet_info_label: Label = $TopBar/PetInfo

# 法术槽位 UI 预制体
@onready var spell_slot_scene: PackedScene = load("res://scenes/ui/spell_slot.tscn") if ResourceLoader.exists("res://scenes/ui/spell_slot.tscn") else null

# 迷雾地图 HUD
@onready var minimap_hud: Control = $MinimapHUD if has_node("MinimapHUD") else _create_minimap()
@onready var boss_hud: Control = $BossHUD if has_node("BossHUD") else _create_boss_hud()
@onready var damage_indicator: Control = $DamageIndicator if has_node("DamageIndicator") else _create_damage_indicator()
@onready var boss_arena_panel: Control = $BossArenaPanel if has_node("BossArenaPanel") else _create_arena_panel()

# ==================== 交互提示（动态创建） ====================
var interaction_container: CenterContainer  # 屏幕中央的交互提示容器
var interaction_icon: Label
var interaction_key: Label
var interaction_text: Label
var interaction_progress: TextureProgressBar  # 采集进度条
var _current_gather_node: Node = null  # 🔧 当前正在采集的节点

var player_ref: Node
var magic_system_ref: Node
var pet_ref: Node
var detector: Node
var input_handler: Node

# 🔧 新增：子系统引用
var quest_system_ref: Node = null
var realm_ref: Node = null

# 🔧 灵宠面板
var pet_panel: Control = null

# 🔧 表情系统
var emote_ui: Control = null

# 🔧 社交 HUD（附近玩家提示）
var social_hud: Control = null

# 🔧 世界事件公告栏
var event_banner: Control = null

func _ready() -> void:
	# 注册秘境面板快捷键（如果尚未注册）
	if not InputMap.has_action("toggle_arena_panel"):
		InputMap.add_action("toggle_arena_panel")
		for key_code in [KEY_L, KEY_KP_5]:
			var ev = InputEventKey.new()
			ev.keycode = key_code
			InputMap.action_add_event("toggle_arena_panel", ev)
	
	player_ref = get_tree().get_first_node_in_group("player")
	magic_system_ref = get_node_or_null("/root/MagicSystem")
	pet_ref = get_tree().get_first_node_in_group("pets")
	detector = get_node_or_null("/root/InteractionDetector")
	input_handler = get_node_or_null("/root/InputHandler")
	# 🔧 获取任务和境界系统
	quest_system_ref = quest_system_ref if quest_system_ref else get_node("/root/QuestSystem")
	realm_ref = get_node_or_null("/root/GameManager/RealmSystem") if has_node("/root/GameManager/RealmSystem") else null
	
	# 🔧 连接背包物品获得飘字
	var inventory = get_node_or_null("/root/GameManager/InventorySystem") if has_node("/root/GameManager/InventorySystem") else null
	if inventory and inventory.has_signal("item_added"):
		if not inventory.item_added.is_connected(_on_item_added):
			inventory.item_added.connect(_on_item_added)
	
	# 创建交互提示 UI
	_build_interaction_hud()
	
	# 🔧 创建任务追踪器
	_build_quest_tracker()
	
	# 🔧 创建飘字系统
	_build_floating_text()
	
	# 🔧 创建任务面板（按J打开）
	_build_daily_quest_panel()
	
	# 🔧 创建灵宠面板
	_build_pet_panel()
	
	# 🔧 创建表情轮盘
	_build_emote_ui()
	
	# 🔧 创建社交 HUD
	_build_social_hud()
	
	# 🔧 创建事件公告栏
	_build_event_banner()
	
	# 🍖 创建饥饿条
	_build_hunger_bar()
	
	# 连接探测器信号
	if detector and detector.has_signal("target_changed"):
		detector.target_changed.connect(_on_target_changed)
		detector.target_lost.connect(_on_target_lost)
	
	# 🔧 连接境界突破信号
	if realm_ref and realm_ref.has_signal("breakthrough_possible"):
		realm_ref.breakthrough_possible.connect(_on_breakthrough_possible)
	if realm_ref and realm_ref.has_signal("realm_changed"):
		realm_ref.realm_changed.connect(_on_realm_changed)
	
	# 初始化法术槽
	_init_spell_slots()
	
	# 输入模式切换提示
	if input_handler and input_handler.has_signal("input_mode_changed"):
		input_handler.input_mode_changed.connect(_on_input_mode_changed)
		# 立即显示当前模式
		_on_input_mode_changed(input_handler.current_mode)

func _build_interaction_hud() -> void:
	"""在屏幕中央底部创建交互提示"""
	interaction_container = CenterContainer.new()
	interaction_container.name = "InteractionPrompt"
	interaction_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interaction_container.visible = false  # 默认隐藏
	add_child(interaction_container)
	
	# 锚定到底部中央
	interaction_container.anchors_preset = Control.PRESET_CENTER_BOTTOM
	interaction_container.offset_bottom = -40
	interaction_container.custom_minimum_size = Vector2(400, 60)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	interaction_container.add_child(vbox)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox)
	
	# 图标
	interaction_icon = Label.new()
	interaction_icon.add_theme_font_size_override("font_size", 28)
	interaction_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(interaction_icon)
	
	# 按键提示（带背景框）
	interaction_key = Label.new()
	interaction_key.add_theme_font_size_override("font_size", 20)
	interaction_key.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	interaction_key.add_theme_stylebox_override("normal", _make_key_style())
	interaction_key.custom_minimum_size = Vector2(40, 36)
	interaction_key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(interaction_key)
	
	# 动作文字
	interaction_text = Label.new()
	interaction_text.add_theme_font_size_override("font_size", 22)
	interaction_text.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	interaction_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(interaction_text)
	
	# 🔧 采集进度条（默认隐藏）
	interaction_progress = TextureProgressBar.new()
	interaction_progress.name = "GatherProgress"
	interaction_progress.visible = false
	interaction_progress.custom_minimum_size = Vector2(300, 8)
	interaction_progress.max_value = 1.0
	interaction_progress.value = 0.0
	interaction_progress.modulate = Color(0.2, 0.8, 1.0, 0.9)
	# 创建一个简单的 StyleBox 作为进度条背景
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.15, 0.6)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	interaction_progress.add_theme_stylebox_override("background", bg_style)
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 0.7, 1.0, 0.9)
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	interaction_progress.add_theme_stylebox_override("fill", fill_style)
	vbox.add_child(interaction_progress)

func _make_key_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.6, 0.6, 0.8, 0.9)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style

func _on_target_changed(target: Dictionary) -> void:
	"""探测到新目标时更新交互提示"""
	var icon = target.get("icon") or "❓"
	var action = target.get("action") or "交互"
	var hint = target.get("hint") or ""
	var dist = target.get("distance") or 999
	
	# 获取按键提示
	var key = "E"
	if input_handler and input_handler.has_method("get_action_hint"):
		key = input_handler.get_action_hint("interact")
	
	interaction_icon.text = icon
	interaction_key.text = key
	interaction_text.text = "%s %s" % [action, hint]
	
	# 距离着色（超出范围变红）
	if dist > 4.5:
		interaction_text.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		interaction_text.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	interaction_container.visible = true
	
	# 🔧 如果是可采集目标，连接到它的进度信号
	_disconnect_gather_signals()
	var node = target.get("node") or null
	var target_type = target.get("type", "")
	if node and target_type == "gatherable" and node.has_signal("gathering_progress"):
		_current_gather_node = node
		if not node.gathering_progress.is_connected(_on_gather_progress):
			node.gathering_progress.connect(_on_gather_progress)
		if not node.gathering_started.is_connected(_on_gather_started):
			node.gathering_started.connect(_on_gather_started)
		if not node.gathering_cancelled.is_connected(_on_gather_cancelled):
			node.gathering_cancelled.connect(_on_gather_cancelled)
		if not node.gathering_completed.is_connected(_on_gather_completed):
			node.gathering_completed.connect(_on_gather_completed)

func _on_target_lost() -> void:
	"""目标丢失时隐藏提示"""
	interaction_container.visible = false
	# 🔧 隐藏进度条
	interaction_progress.visible = false
	_disconnect_gather_signals()

# ==================== 🔧 采集进度处理 ====================

func _on_gather_started(total_time: float) -> void:
	interaction_progress.value = 0.0
	interaction_progress.visible = true
	# 进度条颜色根据采集时间变化（时间越长越华丽）
	if total_time > 3.0:
		interaction_progress.modulate = Color(1.0, 0.6, 0.0, 0.9)  # 橙色=珍贵
	elif total_time > 1.5:
		interaction_progress.modulate = Color(0.2, 0.8, 1.0, 0.9)  # 蓝色=普通
	else:
		interaction_progress.modulate = Color(0.4, 1.0, 0.4, 0.9)  # 绿色=快速

func _on_gather_progress(ratio: float) -> void:
	if interaction_progress.visible:
		interaction_progress.value = ratio

func _on_gather_cancelled() -> void:
	interaction_progress.visible = false
	interaction_progress.value = 0.0

func _on_gather_completed() -> void:
	interaction_progress.visible = false
	interaction_progress.value = 1.0
	# 完成时闪烁一下
	_play_gather_complete_flash()
	
	# 🔧 飘字提示采集到了什么
	if _current_gather_node and is_instance_valid(_current_gather_node):
		var res_id = _current_gather_node.get("resource_id") or ""
		var count = _current_gather_node.get("gather_count") or 1
		var res_name = _current_gather_node.get("resource_name") or ""
		if res_name:
			var text = "+%d %s 🪵" % [count, res_name]
			var color = Color(0.4, 1.0, 0.4)  # 绿色
			spawn_floating_text(text, color)

func _play_gather_complete_flash() -> void:
	var tween = create_tween()
	tween.tween_property(interaction_container, "modulate", Color(1, 1, 1, 1), 0)
	tween.tween_property(interaction_container, "modulate", Color(0.5, 1.0, 0.5, 1), 0.1)
	tween.tween_property(interaction_container, "modulate", Color(1, 1, 1, 1), 0.15)

func _disconnect_gather_signals() -> void:
	if _current_gather_node and is_instance_valid(_current_gather_node):
		if _current_gather_node.gathering_progress.is_connected(_on_gather_progress):
			_current_gather_node.gathering_progress.disconnect(_on_gather_progress)
		if _current_gather_node.gathering_started.is_connected(_on_gather_started):
			_current_gather_node.gathering_started.disconnect(_on_gather_started)
		if _current_gather_node.gathering_cancelled.is_connected(_on_gather_cancelled):
			_current_gather_node.gathering_cancelled.disconnect(_on_gather_cancelled)
		if _current_gather_node.gathering_completed.is_connected(_on_gather_completed):
			_current_gather_node.gathering_completed.disconnect(_on_gather_completed)
	_current_gather_node = null

# ==================== 迷雾地图 ====================

func _create_minimap() -> Control:
	"""动态创建迷雾地图 HUD"""
	var mm = preload("res://scripts/ui/minimap_hud.gd").new()
	mm.name = "MinimapHUD"
	add_child(mm)
	return mm

func _create_boss_hud() -> Control:
	var hud = preload("res://scripts/ui/boss_hud.gd").new()
	hud.name = "BossHUD"
	hud.visible = false
	add_child(hud)
	return hud

func _create_arena_panel() -> Control:
	"""创建秘境状态面板（L键打开）"""
	var panel = preload("res://scripts/ui/boss_arena_panel.gd").new()
	panel.name = "BossArenaPanel"
	panel.visible = false
	add_child(panel)
	
	# 确保秘境管理器在组中
	var am = get_tree().get_first_node_in_group("arena_manager")
	if not am:
		# 自动查找并加入组
		var found = get_tree().get_first_node_in_group("boss_manager")
		if found and found.has_method("get_all_boss_status"):
			# 如果boss_manager有引用到arena_manager
			pass
		# 也可以直接找 BossArenaManager 节点
		for node in get_tree().root.get_children():
			if node is BossArenaManager:
				node.add_to_group("arena_manager")
				break
	
	return panel

func _create_damage_indicator() -> Control:
	var di = preload("res://scripts/ui/damage_indicator.gd").new()
	di.name = "DamageIndicator"
	add_child(di)
	return di

# ==================== 原有功能 ====================

# ==================== 🔧 物品获得飘字 ====================

func _on_item_added(item_id: String, count: int, _slot_index: int) -> void:
	"""背包添加物品时飘字"""
	var item_name = ItemDatabase.get_item_name(item_id)
	if item_name.is_empty():
		item_name = item_id
	var quality = ItemDatabase.get_item_quality(item_id)
	var color = ItemDatabase.get_quality_color(quality)
	spawn_floating_text("+%d %s" % [count, item_name], color)

func _process(_delta: float) -> void:
	if player_ref == null:
		return
	
	_update_hp_mp()
	_update_spell_cooldowns()
	_update_pet_info()
	# 🔧 任务追踪刷新
	_update_quest_tracker()

# 🔧 输入处理
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_quest"):
		_toggle_quest_panel()
		get_viewport().set_input_as_handled()
	
	# 🔧 P 键召唤/收回灵宠
	if event.is_action_pressed("toggle_pet"):
		_toggle_pet_visibility()
		get_viewport().set_input_as_handled()
	
	# 🔧 B 键打开表情轮盘
	if event.is_action_pressed("toggle_emote"):
		if emote_ui and emote_ui.has_method("toggle"):
			emote_ui.toggle()
		get_viewport().set_input_as_handled()
	
	# 🏯 L 键打开秘境状态面板
	if event.is_action_pressed("toggle_arena_panel"):
		if boss_arena_panel and boss_arena_panel.has_method("open"):
			if boss_arena_panel.visible:
				boss_arena_panel.visible = false
			else:
				boss_arena_panel.open()
		get_viewport().set_input_as_handled()

# ==================== 🔧 表情轮盘 ====================

func _build_emote_ui() -> void:
	"""创建表情轮盘"""
	emote_ui = preload("res://scripts/ui/emote_ui.gd").new()
	emote_ui.name = "EmoteUI"
	add_child(emote_ui)
	
	if emote_ui.has_signal("emote_selected"):
		emote_ui.emote_selected.connect(_on_emote_selected)

func _on_emote_selected(emote_id: String, emote_name: String) -> void:
	"""玩家选择了表情"""
	# 播放本地表情
	_play_player_emote(emote_id)
	
	# 飘字显示
	spawn_floating_text("🧘 %s" % emote_name, Color(0.8, 0.7, 1.0))
	
	# TODO: 网络同步 — RPC 发送给附近玩家
	print("🎭 表情: %s (%s)" % [emote_name, emote_id])

func _play_player_emote(emote_id: String) -> void:
	"""播放玩家表情动画"""
	if not player_ref or not is_instance_valid(player_ref):
		return
	
	# 检查玩家是否有动画播放器
	if player_ref.has_method("play_emote"):
		player_ref.play_emote(emote_id)
	elif player_ref.has_node("AnimationPlayer"):
		var anim = player_ref.get_node("AnimationPlayer")
		if anim and anim.has_animation(emote_id):
			anim.play(emote_id)
	
	# 创建粒子特效
	_spawn_emote_particles(emote_id)

func _spawn_emote_particles(emote_id: String) -> void:
	"""表情粒子特效"""
	if not player_ref:
		return
	
	# 不同表情不同颜色/效果
	var colors = {
		"wave": Color(1, 0.8, 0.5),
		"bow": Color(0.8, 0.8, 0.3),
		"dance": Color(1, 0.4, 0.7),
		"sit": Color(0.5, 0.8, 1),
		"sword": Color(0.6, 0.3, 1),
		"cheer": Color(1, 1, 0.3),
	}
	var color = colors.get(emote_id, Color.WHITE)
	
	# 简单的飘字反馈
	spawn_floating_text("✨", color, Vector2(0, -60))

# ==================== 🔧 社交 HUD ====================

func _build_social_hud() -> void:
	"""创建附近玩家提示"""
	social_hud = preload("res://scripts/ui/social_hud.gd").new()
	social_hud.name = "SocialHUD"
	add_child(social_hud)

# ==================== 🔧 事件公告栏 ====================

func _build_event_banner() -> void:
	"""创建世界事件公告栏"""
	event_banner = preload("res://scripts/events/event_banner.gd").new()
	event_banner.name = "EventBanner"
	add_child(event_banner)
	
	# 连接事件管理器
	var evt_mgr = get_node("/root/WorldEventManager") if has_node("/root/WorldEventManager") else null
	if evt_mgr and evt_mgr.has_signal("event_announced"):
		evt_mgr.event_announced.connect(_on_event_announced)

func _on_event_announced(event_type: int, title: String, description: String, duration: float) -> void:
	"""收到事件公告 → 显示横幅"""
	if event_banner and event_banner.has_method("show_event"):
		event_banner.show_event(event_type, title, description, duration)

func _init_spell_slots() -> void:
	"""创建法术快捷键UI"""
	if magic_system_ref == null:
		return
	if spell_slot_scene == null:
		return
	var spells = magic_system_ref.get_unlocked_spells()
	var keys = ["1", "2", "3", "4", "5"]
	for i in range(spells.size()):
		var slot = spell_slot_scene.instantiate()
		slot.setup(spells[i].get("name") or "", keys[i], spells[i].get("type") or 0)
		if spell_container != null:
			spell_container.add_child(slot)

func _update_hp_mp() -> void:
	"""更新血量和法力条"""
	if hp_bar == null or hp_label == null:
		return
	if player_ref.has_method("get_hp_ratio"):
		var ratio = player_ref.get_hp_ratio()
		if ratio is float or ratio is int:
			hp_bar.value = ratio * 100.0
		hp_label.text = "%d/%d" % [player_ref.get_hp(), player_ref.get_max_hp()]

	if mp_bar == null or mp_label == null:
		return
	if player_ref.has_method("get_mp_ratio"):
		var ratio = player_ref.get_mp_ratio()
		if ratio is float or ratio is int:
			mp_bar.value = ratio * 100.0
		mp_label.text = "%d/%d" % [player_ref.get_mp(), player_ref.get_max_mp()]
	
	# 🍖 更新饥饿条
	_update_hunger()

func _update_spell_cooldowns() -> void:
	"""更新法术冷却显示"""
	if magic_system_ref == null or spell_container == null:
		return
	for slot in spell_container.get_children():
		if slot.has_method("update_cooldown"):
			var spell_type = slot.get("spell_type") or 0 if slot.has_method("get") else 0
			var ratio = magic_system_ref.get_spell_cooldown_ratio(spell_type)
			slot.update_cooldown(ratio)

func _update_pet_info() -> void:
	"""更新灵宠信息 — 使用面板"""
	if pet_panel and pet_ref and is_instance_valid(pet_ref):
		pet_panel.refresh()
	
	# 保留原来文字标签作为后备
	if pet_ref == null or not is_instance_valid(pet_ref):
		if pet_info_label != null:
			pet_info_label.text = ""
		return
	if pet_info_label == null:
		return
	var info = pet_ref.get_pet_info()
	pet_info_label.text = "%s Lv.%d ❤️%d" % [info.get("name", "灵宠"), info.get("level", 1), info.get("loyalty", 50)]

func _on_input_mode_changed(mode: int) -> void:
	"""输入模式切换时更新 HUD 提示文本"""
	var input_hint = $InputModeHint if has_node("InputModeHint") else null
	if not input_hint:
		# 动态创建
		input_hint = Label.new()
		input_hint.name = "InputModeHint"
		input_hint.add_theme_font_size_override("font_size", 14)
		input_hint.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 0.8))
		input_hint.anchors_preset = Control.PRESET_TOP_RIGHT
		input_hint.offset_top = 8
		input_hint.offset_right = -8
		add_child(input_hint)
	
	match mode:
		0: input_hint.text = "⌨️ 键鼠"
		1: input_hint.text = "🎮 手柄"
		2: input_hint.text = "👆 触屏"
	
	input_hint.show()
	# 3秒后淡出
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(input_hint):
		input_hint.hide()

# ==================== 🔧 创作任务追踪 HUD ====================

func _build_quest_tracker() -> void:
	"""在屏幕右侧创建任务追踪面板"""
	var tracker = VBoxContainer.new()
	tracker.name = "QuestTracker"
	tracker.visible = false
	tracker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tracker.anchors_preset = Control.PRESET_RIGHT_WIDE
	tracker.offset_top = 120
	tracker.offset_right = -10
	tracker.offset_bottom = -200
	tracker.custom_minimum_size = Vector2(260, 0)
	tracker.add_theme_constant_override("separation", 4)
	add_child(tracker)
	
	# 标题
	var title = Label.new()
	title.name = "QuestTitle"
	title.text = "📋 任务追踪"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tracker.add_child(title)
	
	# 用 RichTextLabel 来动态显示任务列表
	var quest_list = RichTextLabel.new()
	quest_list.name = "QuestList"
	quest_list.bbcode_enabled = true
	quest_list.fit_content = true
	quest_list.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quest_list.add_theme_font_size_override("normal_font_size", 14)
	quest_list.add_theme_color_override("default_color", Color(1, 1, 1, 0.9))
	quest_list.add_theme_constant_override("line_separation", 2)
	tracker.add_child(quest_list)

func _update_quest_tracker() -> void:
	"""每帧更新任务追踪显示"""
	if not quest_system_ref:
		return
	
	var tracker = get_node_or_null("QuestTracker")
	if not tracker:
		return
	
	var quest_list = tracker.get_node_or_null("QuestList")
	if not quest_list:
		return
	
	# 获取活跃任务
	var active = []
	if quest_system_ref.has_method("get_active_quests"):
		active = quest_system_ref.get_active_quests()
	
	if active.is_empty():
		tracker.visible = false
		return
	
	tracker.visible = true
	var text = ""
	for q in active:
		var name = q.get("name") or "未知任务"
		var step_desc = q.get("step_desc") or ""
		var step_progress = q.get("step_progress") or 0
		var step_target = q.get("step_target") or 0
		
		var is_done = step_target > 0 and step_progress >= step_target
		
		if is_done:
			text += "[color=#88ff88]✅ %s[/color]
" % name
		else:
			text += "[color=#ffffff]⬜ %s[/color]
" % name
		
		if step_desc:
			if step_target > 0:
				text += "   [color=#aaaaaa]%s %d/%d[/color]
" % [step_desc, step_progress, step_target]
			else:
				text += "   [color=#aaaaaa]%s[/color]
" % [step_desc]
	
	quest_list.text = text

# ==================== 🔧 任务面板（J键） ====================

func _build_daily_quest_panel() -> void:
	"""创建任务面板"""
	var panel = preload("res://scripts/ui/daily_quest_panel.gd").new()
	panel.name = "DailyQuestPanel"
	panel.visible = false
	add_child(panel)

func _toggle_quest_panel() -> void:
	var panel = get_node_or_null("DailyQuestPanel")
	if panel and panel.has_method("toggle"):
		panel.toggle()

# ==================== 🔧 灵宠面板 ====================

func _build_pet_panel() -> void:
	"""创建灵宠交互面板"""
	pet_panel = preload("res://scripts/ui/pet_panel.gd").new()
	pet_panel.name = "PetPanel"
	add_child(pet_panel)
	
	# 连接信号
	if pet_panel.has_signal("feed_pet"):
		pet_panel.feed_pet.connect(_on_pet_feed)
	if pet_panel.has_signal("pet_pet"):
		pet_panel.pet_pet.connect(_on_pet_pet)
	if pet_panel.has_signal("dismiss_pet"):
		pet_panel.dismiss_pet.connect(_on_pet_dismiss)
	
	# 初始刷新
	pet_panel.set_pet_ref(pet_ref)

func _on_pet_feed() -> void:
	"""喂灵宠"""
	if not pet_ref or not is_instance_valid(pet_ref) or not pet_ref.has_method("feed"):
		return
	# 从背包拿食物（这里简化：直接喂第一个食物类型）
	var result = pet_ref.feed(0)  # food_type=0 通用
	if pet_panel:
		pet_panel.refresh()
	spawn_floating_text(result.get("message") or "喂食完成", Color(0.6, 1.0, 0.6))

func _on_pet_pet() -> void:
	"""抚摸灵宠（加亲密度）"""
	if not pet_ref or not is_instance_valid(pet_ref):
		return
	# 抚摸直接加少量亲密度
	if pet_ref.has_method("feed"):
		var result = pet_ref.feed(-1)  # food_type=-1 表示抚摸
		if pet_panel:
			pet_panel.refresh()
		spawn_floating_text("🤚 摸摸头～", Color(1.0, 0.6, 0.8))

func _on_pet_dismiss() -> void:
	"""收回/召唤灵宠"""
	_toggle_pet_visibility()

func _toggle_pet_visibility() -> void:
	"""按 P 切换灵宠可见性"""
	if not pet_ref or not is_instance_valid(pet_ref):
		# 没有灵宠，尝试找一只
		pet_ref = get_tree().get_first_node_in_group("pets")
		if not pet_ref:
			spawn_floating_text("没有灵宠可以召唤 😅", Color(0.7, 0.7, 0.7))
			return
	
	var is_visible = pet_ref.visible
	pet_ref.visible = not is_visible
	
	# 显示/隐藏面板
	if pet_panel:
		pet_panel.visible = pet_ref.visible
		if pet_ref.visible:
			pet_panel.refresh()
	
	if is_visible:
		spawn_floating_text("🔔 灵宠已召回", Color(0.5, 0.7, 1.0))
	else:
		spawn_floating_text("🐾 灵宠已召唤", Color(0.5, 1.0, 0.5))

# ==================== 🔧 飘字系统 ====================

func _build_floating_text() -> void:
	"""创建飘字容器"""
	var container = Node.new()
	container.name = "FloatingTextContainer"
	add_child(container)

func spawn_floating_text(text: String, color: Color = Color.WHITE, pos_offset: Vector2 = Vector2.ZERO) -> void:
	"""在屏幕中间偏上位置生成飘字"""
	var container = get_node_or_null("FloatingTextContainer")
	if not container:
		return
	
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 定位到屏幕中央偏上 + 随机偏移避免重叠
	var screen_size = get_viewport().get_visible_rect().size
	label.position = Vector2(
		screen_size.x / 2 - 100 + pos_offset.x + randf_range(-80, 80),
		screen_size.y * 0.35 + pos_offset.y + randf_range(-20, 20)
	)
	label.custom_minimum_size = Vector2(200, 30)
	container.add_child(label)
	
	# 飘字动画：向上飘 + 淡出
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 60, 1.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.3)
	tween.set_parallel(false)
	tween.tween_callback(func():
		if is_instance_valid(label):
			label.queue_free()
	)

# ==================== 🔧 突破通知 ====================

func _on_breakthrough_possible(realm: int) -> void:
	"""修为满了，可以突破了"""
	spawn_floating_text("🌟 修为圆满！可按 B 突破！", Color(1, 0.9, 0.2))
	# 通知闪烁
	var notif = Label.new()
	notif.name = "BreakthroughNotif"
	notif.text = "🌟 修为圆满！[B]突破[/b]"
	notif.bbcode_enabled = true
	notif.add_theme_font_size_override("font_size", 18)
	notif.add_theme_color_override("default_color", Color(1, 0.9, 0.2))
	notif.anchors_preset = Control.PRESET_TOP_WIDE
	notif.offset_top = 60
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(notif)
	
	# 3秒后淡出
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(notif):
		var tween = create_tween()
		tween.tween_property(notif, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func(): if is_instance_valid(notif): notif.queue_free())

func _on_realm_changed(old_realm: int, new_realm: int, realm_name: String) -> void:
	"""境界突破成功！"""
	spawn_floating_text("🎉 突破成功！%s！" % realm_name, Color(1, 0.8, 0.0))
	
	# 全屏闪白
	var flash = ColorRect.new()
	flash.name = "BreakthroughFlash"
	flash.color = Color(1, 1, 1, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.anchors_preset = Control.PRESET_FULL_RECT
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "color", Color(1, 1, 1, 0.4), 0.1)
	tween.tween_property(flash, "color", Color(1, 1, 1, 0), 0.6)
	tween.tween_callback(func(): if is_instance_valid(flash): flash.queue_free())

# ==================== 🍖 饥饿条 ====================

var hunger_bar: ProgressBar = null
var hunger_label: Label = null

func _build_hunger_bar() -> void:
	"""创建饥饿值进度条（在 MP 条旁边）"""
	if not has_node("TopBar"):
		return
	
	var top_bar = $TopBar
	
	# 饥饿条放在 MP 条下方
	hunger_bar = ProgressBar.new()
	hunger_bar.name = "HungerBar"
	hunger_bar.custom_minimum_size = Vector2(200, 12)
	hunger_bar.max_value = 100.0
	hunger_bar.value = 100.0
	hunger_bar.modulate = Color(0.9, 0.6, 0.2, 0.9)  # 橙色，像烤肉
	top_bar.add_child(hunger_bar)
	
	# 设置进度条样式
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.2, 0.1, 0.0, 0.5)
	bg.set_corner_radius_all(4)
	hunger_bar.add_theme_stylebox_override("background", bg)
	
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.9, 0.6, 0.2, 0.8)
	fill.set_corner_radius_all(4)
	hunger_bar.add_theme_stylebox_override("fill", fill)
	
	# 文字标签
	hunger_label = Label.new()
	hunger_label.name = "HungerLabel"
	hunger_label.text = "🍖 100/100"
	hunger_label.add_theme_font_size_override("font_size", 10)
	hunger_label.add_theme_color_override("font_color", Color(1, 0.9, 0.7))
	hunger_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hunger_bar.add_child(hunger_label)

func _update_hunger() -> void:
	"""更新饥饿条显示"""
	if not hunger_bar or not player_ref:
		return
	
	if player_ref.has_method("get_hunger_ratio"):
		var ratio = player_ref.get_hunger_ratio()
		if ratio is float or ratio is int:
			hunger_bar.value = ratio * 100.0
		else:
			hunger_bar.value = 100.0
		
		# 饥饿条颜色随饥饿程度变化
		var fill = hunger_bar.get_theme_stylebox("fill")
		if fill:
			if ratio > 0.6:
				fill.bg_color = Color(0.9, 0.6, 0.2)  # 橙色 - 饱
			elif ratio > 0.3:
				fill.bg_color = Color(0.9, 0.7, 0.1)  # 黄色 - 饿
			else:
				fill.bg_color = Color(0.9, 0.2, 0.1)  # 红色 - 快饿死
	
	if hunger_label and player_ref.has_method("get_hunger") and player_ref.has_method("get_max_hunger"):
		var cur = int(player_ref.get_hunger())
		var maxv = int(player_ref.get_max_hunger())
		var status = player_ref.get_hunger_status() if player_ref.has_method("get_hunger_status") else ""
		hunger_label.text = "🍖 %d/%d  %s" % [cur, maxv, status]
