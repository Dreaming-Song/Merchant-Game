extends Control
## 🐾 灵宠交互面板 — 显示在 HUD 左上角
##
## 展示：名字、等级、亲密度/饱食度进度条、技能、操作按钮
## 按 P 可召唤/收回灵宠（在 HUD 中处理）

class_name PetPanel

signal feed_pet()
signal pet_pet()
signal dismiss_pet()

var pet_ref: Node = null
var is_open: bool = false  # 是否展开详情

# UI 节点
var _main_container: VBoxContainer
var _name_label: Label
var _level_label: Label
var _hunger_bar: ProgressBar
var _loyalty_bar: TextureProgressBar
var _skills_label: Label
var _btn_feed: Button
var _btn_pet: Button
var _btn_dismiss: Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	visible = false

func _build_ui() -> void:
	"""构建灵宠面板UI"""
	_main_container = VBoxContainer.new()
	_main_container.name = "PetPanelMain"
	_main_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_main_container.anchors_preset = Control.PRESET_TOP_LEFT
	_main_container.offset_left = 12
	_main_container.offset_top = 80
	_main_container.custom_minimum_size = Vector2(180, 0)
	_main_container.add_theme_constant_override("separation", 3)
	add_child(_main_container)
	
	# ── 背景框 ──
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.05, 0.12, 0.7)
	bg.corner_radius_top_left = 8
	bg.corner_radius_top_right = 8
	bg.corner_radius_bottom_left = 8
	bg.corner_radius_bottom_right = 8
	_main_container.add_theme_stylebox_override("panel", bg)
	
	# ── 第一行：名字 + 等级 ──
	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 6)
	_main_container.add_child(top_hbox)
	
	var icon = Label.new()
	icon.text = "🐾"
	icon.add_theme_font_size_override("font_size", 20)
	top_hbox.add_child(icon)
	
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 16)
	_name_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	top_hbox.add_child(_name_label)
	
	_level_label = Label.new()
	_level_label.add_theme_font_size_override("font_size", 14)
	_level_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	top_hbox.add_child(_level_label)
	
	# ── 饱食度条 ──
	var hunger_hbox = HBoxContainer.new()
	hunger_hbox.add_theme_constant_override("separation", 4)
	_main_container.add_child(hunger_hbox)
	
	var hunger_icon = Label.new()
	hunger_icon.text = "🍖"
	hunger_icon.add_theme_font_size_override("font_size", 12)
	hunger_hbox.add_child(hunger_icon)
	
	_hunger_bar = ProgressBar.new()
	_hunger_bar.custom_minimum_size = Vector2(120, 12)
	_hunger_bar.max_value = 100
	_hunger_bar.value = 100
	# TextureProgressBar 没有 show_percentage 属性，已移除
	var h_bg = StyleBoxFlat.new()
	h_bg.bg_color = Color(0.15, 0.1, 0.08, 0.6)
	h_bg.corner_radius_top_left = 4
	h_bg.corner_radius_top_right = 4
	h_bg.corner_radius_bottom_left = 4
	h_bg.corner_radius_bottom_right = 4
	_hunger_bar.add_theme_stylebox_override("background", h_bg)
	var h_fill = StyleBoxFlat.new()
	h_fill.bg_color = Color(0.9, 0.6, 0.2, 0.9)
	h_fill.corner_radius_top_left = 4
	h_fill.corner_radius_top_right = 4
	h_fill.corner_radius_bottom_left = 4
	h_fill.corner_radius_bottom_right = 4
	_hunger_bar.add_theme_stylebox_override("fill", h_fill)
	hunger_hbox.add_child(_hunger_bar)
	
	var hunger_val = Label.new()
	hunger_val.name = "HungerVal"
	hunger_val.add_theme_font_size_override("font_size", 10)
	hunger_val.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hunger_hbox.add_child(hunger_val)
	
	# ── 亲密度条 ──
	var loy_hbox = HBoxContainer.new()
	loy_hbox.add_theme_constant_override("separation", 4)
	_main_container.add_child(loy_hbox)
	
	var loy_icon = Label.new()
	loy_icon.text = "❤️"
	loy_icon.add_theme_font_size_override("font_size", 12)
	loy_hbox.add_child(loy_icon)
	
	_loyalty_bar = TextureProgressBar.new()
	_loyalty_bar.custom_minimum_size = Vector2(120, 12)
	_loyalty_bar.max_value = 100
	_loyalty_bar.value = 50
	# TextureProgressBar 没有 show_percentage 属性，已移除
	var l_bg = StyleBoxFlat.new()
	l_bg.bg_color = Color(0.1, 0.05, 0.12, 0.6)
	l_bg.corner_radius_top_left = 4
	l_bg.corner_radius_top_right = 4
	l_bg.corner_radius_bottom_left = 4
	l_bg.corner_radius_bottom_right = 4
	_loyalty_bar.add_theme_stylebox_override("background", l_bg)
	var l_fill = StyleBoxFlat.new()
	l_fill.bg_color = Color(1.0, 0.3, 0.5, 0.9)
	l_fill.corner_radius_top_left = 4
	l_fill.corner_radius_top_right = 4
	l_fill.corner_radius_bottom_left = 4
	l_fill.corner_radius_bottom_right = 4
	_loyalty_bar.add_theme_stylebox_override("fill", l_fill)
	loy_hbox.add_child(_loyalty_bar)
	
	var loy_val = Label.new()
	loy_val.name = "LoyaltyVal"
	loy_val.add_theme_font_size_override("font_size", 10)
	loy_val.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	loy_hbox.add_child(loy_val)
	
	# ── 技能列表 ──
	_skills_label = Label.new()
	_skills_label.add_theme_font_size_override("font_size", 11)
	_skills_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 0.8))
	_main_container.add_child(_skills_label)
	
	# ── 操作按钮（默认隐藏，展开才显示） ──
	var btn_hbox = HBoxContainer.new()
	btn_hbox.name = "ButtonRow"
	btn_hbox.add_theme_constant_override("separation", 4)
	btn_hbox.visible = false
	_main_container.add_child(btn_hbox)
	
	_btn_feed = Button.new()
	_btn_feed.text = "🍚 喂食"
	_btn_feed.custom_minimum_size = Vector2(56, 24)
	_btn_feed.add_theme_font_size_override("font_size", 11)
	_btn_feed.pressed.connect(_on_feed_pressed)
	btn_hbox.add_child(_btn_feed)
	
	_btn_pet = Button.new()
	_btn_pet.text = "🤚 抚摸"
	_btn_pet.custom_minimum_size = Vector2(56, 24)
	_btn_pet.add_theme_font_size_override("font_size", 11)
	_btn_pet.pressed.connect(_on_pet_pressed)
	btn_hbox.add_child(_btn_pet)
	
	_btn_dismiss = Button.new()
	_btn_dismiss.text = "🔔 召回"
	_btn_dismiss.custom_minimum_size = Vector2(56, 24)
	_btn_dismiss.add_theme_font_size_override("font_size", 11)
	_btn_dismiss.pressed.connect(_on_dismiss_pressed)
	btn_hbox.add_child(_btn_dismiss)

# ==================== 刷新显示 ====================

func refresh() -> void:
	"""每帧/每次变化时刷新面板"""
	if not pet_ref or not is_instance_valid(pet_ref):
		visible = false
		return
	
	visible = true
	var info = pet_ref.get_pet_info()
	
	_name_label.text = info.get("name", "灵宠")
	_level_label.text = "Lv.%d" % info.get("level", 1)
	
	# 饱食度
	var hunger = info.get("hunger", 100)
	_hunger_bar.value = hunger
	var h_val = get_node_or_null("PetPanelMain/HungerVal") if has_node("PetPanelMain/HungerVal") else null
	if h_val:
		h_val.text = "%d%%" % hunger
	# 饥饿时变色
	if hunger < 30:
		_hunger_bar.modulate = Color(1.0, 0.4, 0.3)
	elif hunger < 60:
		_hunger_bar.modulate = Color(1.0, 0.8, 0.3)
	else:
		_hunger_bar.modulate = Color(1.0, 1.0, 1.0)
	
	# 亲密度
	var loyalty = info.get("loyalty") or 50
	_loyalty_bar.value = loyalty
	var l_val = get_node_or_null("PetPanelMain/LoyaltyVal") if has_node("PetPanelMain/LoyaltyVal") else null
	if l_val:
		l_val.text = "%d%%" % loyalty
	
	# 技能列表
	var skills = info.get("skills") or []
	if skills.is_empty():
		_skills_label.text = "未解锁技能"
		_skills_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))
	else:
		var skill_text = ""
		for s in skills:
			skill_text += "✨ %s  " % s
		_skills_label.text = skill_text
		_skills_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 0.8))
	
	# 是否可载人
	if info.get("can_mount") or false:
		_level_label.text += " 🐉"

# ==================== 展开/收起 ====================

func toggle_expand() -> void:
	"""展开/收起按钮行"""
	is_open = not is_open
	var btn_row = _main_container.get_node_or_null("ButtonRow")
	if btn_row:
		btn_row.visible = is_open
		if is_open:
			_main_container.offset_top = 80
			_main_container.custom_minimum_size.y = 220
		else:
			_main_container.custom_minimum_size.y = 0

# ==================== 按钮回调 ====================

func _on_feed_pressed() -> void:
	feed_pet.emit()

func _on_pet_pressed() -> void:
	pet_pet.emit()
	# 点击抚摸时触发亲密度增加反馈
	if pet_ref and pet_ref.has_method("get_pet_info"):
		var info = pet_ref.get_pet_info()
		_display_pet_reaction("purr")

func _on_dismiss_pressed() -> void:
	dismiss_pet.emit()

func _display_pet_reaction(emotion: String) -> void:
	"""显示灵宠反应（简单飘字）"""
	var texts = {
		"purr": ["😊 好舒服～", "🥰 喜欢！", "😌 呼噜呼噜～"],
		"happy": ["😄 开心！", "🎉 耶！", "🥳 再来！"],
		"hungry": ["😢 饿了……", "🥺 想吃！"],
	}
	var pool = texts.get(emotion, ["😊"])
	var msg = pool[randi() % pool.size()]
	
	# 找 HUD 发飘字
	var hud = get_parent()
	if hud and hud.has_method("spawn_floating_text"):
		var color = Color(1.0, 0.6, 0.8)
		hud.spawn_floating_text(msg, color, Vector2(-100, -40))

func set_pet_ref(new_ref: Node) -> void:
	pet_ref = new_ref
	if pet_ref:
		refresh()
	else:
		visible = false
