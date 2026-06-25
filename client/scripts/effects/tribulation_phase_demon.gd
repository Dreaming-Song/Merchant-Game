extends Node
## 👻 雷劫·第三阶段：心魔幻境
##
## 心魔强度 = 动态缩放！前两阶段失误越多 → 心魔越强 💀
##   - HP倍率: 0.8x(完美) ~ 2.5x(全崩)
##   - 攻击速度: 越快越难躲
##   - 伤害加成
##
## 🎮 操作：
##   键盘：↑跳跃 ↓蹲伏 ␣凝神 ←→挣脱
##   手柄：↑↓选择 Ⓐ凝神 ←→挣脱
##
## 攻击模式：
##   🔴 业火横斩 → 蹲伏 [↓ / D-Down]
##   🔵 业火穿刺 → 跳跃 [↑ / D-Up]
##   🟡 业火漩涡 → 凝神 [␣ / Ⓐ]
##   🟣 业火心蚀 → 连按←→挣脱

class_name TribulationPhaseDemon

signal phase_completed(score: float)
signal phase_failed(reason: String)

# ==================== 攻击模式 ====================
const ATTACK_PATTERNS = [
	{"name":"业火横斩","icon":"🔥","arrow":"⤵️","hint":"蹲伏 [↓ 或 D-Down]",
	 "action":"dodge_down","color":Color("#ff4444"),"time":1.2},
	{"name":"业火穿刺","icon":"⚡","arrow":"⤴️","hint":"跳跃 [↑ 或 D-Up]",
	 "action":"dodge_up","color":Color("#4488ff"),"time":1.2},
	{"name":"业火漩涡","icon":"🌀","arrow":"⏸️","hint":"凝神 [␣ 或 Ⓐ]",
	 "action":"defend","color":Color("#ffcc00"),"time":1.5},
	{"name":"业火心蚀","icon":"💀","arrow":"↔️","hint":"挣脱 [←→ 连按]",
	 "action":"break_free","color":Color("#cc44ff"),"time":1.8},
]

# ==================== 引用 ====================
var _manager: Node = null
var _player: Node = null
var _config: Dictionary = {}

# ==================== 动态状态 ====================
var _demon_hp: float = 100.0
var _demon_max_hp: float = 100.0
var _daoxin: float = 0.0
var _score: float = 100.0
var _round: int = 0
var _max_rounds: int = 6
var _is_running: bool = false
var _is_attacking: bool = false
var _current_pattern: Dictionary = {}
var _pattern_timer: float = 0.0
var _break_free_count: int = 0

# 动态强度参数（从Manager传入）
var _weakness_factor: float = 1.0
var _hp_mult: float = 1.0
var _attack_speed_mult: float = 1.0
var _damage_mult: float = 1.0

# 🎮 手柄
var _has_controller: bool = false

# ==================== UI节点 ====================
var _bg: ColorRect = null
var _demon_icon: Label = null
var _demon_hp_bar: TextureProgressBar = null
var _demon_hp_label: Label = null
var _daoxin_bar: TextureProgressBar = null
var _daoxin_label: Label = null
var _attack_panel: Panel = null
var _attack_icon: Label = null
var _attack_arrow: Label = null
var _attack_hint: Label = null
var _attack_timer: Label = null
var _center_result: Label = null
var _action_hint: Label = null
var _top_label: Label = null
var _weakness_indicator: Label = null

func _init(manager: Node, player: Node, config: Dictionary) -> void:
	_manager = manager
	_player = player
	_config = config
	
	# 📊 动态强度参数
	_hp_mult = config.get("demon_hp_mult") or 1.0
	_attack_speed_mult = config.get("demon_attack_speed") or 1.0
	_weakness_factor = config.get("weakness_factor") or 1.0
	_damage_mult = 0.8 + _weakness_factor * 0.3  # 伤害也随强度增加
	
	_demon_max_hp = 100.0 * _hp_mult
	_demon_hp = _demon_max_hp
	_max_rounds = 5 + int(config.get("element_rounds") or 3 * 0.5)  # 随境界增加
	
	print("👻 心魔强度: HPx%.1f 速度x%.1f 伤害x%.1f 回合%d" % [
		_hp_mult, _attack_speed_mult, _damage_mult, _max_rounds])
	name = "PhaseDemon"

func _ready() -> void:
	_register_actions()

func _register_actions() -> void:
	"""注册手柄动作"""
	for act in ["trib_demon_up","trib_demon_down","trib_demon_defend",
	             "trib_demon_break_left","trib_demon_break_right"]:
		if not InputMap.has_action(act):
			InputMap.add_action(act)
	
	# 上 = D-Up 或 左摇杆上
	if InputMap.action_get_events("trib_demon_up").is_empty():
		for btn in [JOY_BUTTON_DPAD_UP]:
			var ev = InputEventJoypadButton.new()
			ev.button_index = btn
			InputMap.action_add_event("trib_demon_up", ev)
		var ev2 = InputEventJoypadMotion.new()
		ev2.axis = JOY_AXIS_LEFT_Y
		ev2.axis_value = -1.0
		InputMap.action_add_event("trib_demon_up", ev2)
	
	if InputMap.action_get_events("trib_demon_down").is_empty():
		for btn in [JOY_BUTTON_DPAD_DOWN]:
			var ev = InputEventJoypadButton.new()
			ev.button_index = btn
			InputMap.action_add_event("trib_demon_down", ev)
		var ev2 = InputEventJoypadMotion.new()
		ev2.axis = JOY_AXIS_LEFT_Y
		ev2.axis_value = 1.0
		InputMap.action_add_event("trib_demon_down", ev2)
	
	if InputMap.action_get_events("trib_demon_defend").is_empty():
		var ev = InputEventJoypadButton.new()
		ev.button_index = JOY_BUTTON_A
		InputMap.action_add_event("trib_demon_defend", ev)
	
	for side in ["left","right"]:
		var act_name = "trib_demon_break_%s" % side
		if InputMap.action_get_events(act_name).is_empty():
			var ev = InputEventJoypadButton.new()
			ev.button_index = JOY_BUTTON_DPAD_LEFT if side == "left" else JOY_BUTTON_DPAD_RIGHT
			InputMap.action_add_event(act_name, ev)

func _input(event: InputEvent) -> void:
	if not _is_running or not _is_attacking: return
	
	var p = _current_pattern
	if p.is_empty(): return
	
	match p.get("action") or "":
		"dodge_down":
			if event.is_action_pressed("ui_down") or \
			   (event is InputEventKey and event.keycode == KEY_DOWN) or \
			   event.is_action_pressed("trib_demon_down"):
				_has_controller = event is InputEventJoypadButton or event is InputEventJoypadMotion
				get_viewport().set_input_as_handled()
				_on_correct_reaction()
		"dodge_up":
			if event.is_action_pressed("ui_up") or \
			   (event is InputEventKey and event.keycode == KEY_UP) or \
			   event.is_action_pressed("trib_demon_up"):
				_has_controller = event is InputEventJoypadButton or event is InputEventJoypadMotion
				get_viewport().set_input_as_handled()
				_on_correct_reaction()
		"defend":
			if event.is_action_pressed("ui_accept") or \
			   (event is InputEventKey and event.keycode == KEY_SPACE) or \
			   event.is_action_pressed("trib_demon_defend"):
				_has_controller = event is InputEventJoypadButton or event is InputEventJoypadMotion
				get_viewport().set_input_as_handled()
				_on_correct_reaction()
		"break_free":
			var is_pressed_left = event.is_action_pressed("ui_left") or \
				(event is InputEventKey and event.keycode in [KEY_LEFT,KEY_A]) or \
				event.is_action_pressed("trib_demon_break_left")
			var is_pressed_right = event.is_action_pressed("ui_right") or \
				(event is InputEventKey and event.keycode in [KEY_RIGHT,KEY_D]) or \
				event.is_action_pressed("trib_demon_break_right")
			
			if is_pressed_left or is_pressed_right:
				if event is InputEventJoypadButton or event is InputEventJoypadMotion:
					_has_controller = true
				get_viewport().set_input_as_handled()
				_break_free_count += 1
				if _break_free_count >= 5:
					_on_correct_reaction()
				else:
					var pct = int(_break_free_count / 5.0 * 100)
					if _action_hint:
						_action_hint.text = "挣脱 %d%%  [←→ 连按]" % pct

# ==================== 启动 ====================

func start() -> void:
	_is_running = true
	_create_hud()
	
	# 根据强度显示不同入场文字
	var intro_text = "👻 心魔降临..."
	if _weakness_factor > 2.0:
		intro_text = "💀 远古心魔！前路坎坷，它变得异常强大！"
	elif _weakness_factor > 1.5:
		intro_text = "👿 心魔借你道心裂痕滋生，比预计更强！"
	else:
		intro_text = "👻 心魔虽强，但你道心稳固，不足为惧！"
	
	_show_center_result(intro_text, Color("#cc66ff"))
	_show_action_hint("躲攻击→攒道心→击败心魔！[↑↓␣←→ 或 手柄]", Color("#aaddff"))
	
	await get_tree().create_timer(3.0).timeout
	
	if _is_running: _start_round()

# ==================== 回合逻辑 ====================

func _start_round() -> void:
	if not _is_running: return
	_round += 1
	
	if _demon_hp <= 0: _on_demon_defeated(); return
	if _round > _max_rounds: _complete_phase(); return
	
	if _top_label:
		_top_label.text = "👻 心魔 — 第 %d/%d 回合" % [_round, _max_rounds]
	
	# ---- A: 蓄道心期 ----
	_is_attacking = false
	_show_action_hint("按住 [空格/Ⓐ] 积攒道心...", Color("#aaddff"))
	_hide_attack_ui()
	
	var charge_time = 0.0
	var charge_duration = 3.0 / _attack_speed_mult  # 攻击越快 = 蓄力时间越短
	
	while charge_time < charge_duration and _is_running:
		await get_tree().process_frame
		var delta = get_process_delta_time()
		
		if Input.is_key_pressed(KEY_SPACE) or Input.is_joy_button_pressed(0, JOY_BUTTON_A):
			_has_controller = true
			var rate = delta * 25.0 * _attack_speed_mult
			_daoxin = mini(100.0, _daoxin + rate)
			charge_time += delta * 1.5
		else:
			charge_time += delta
			_daoxin = max(0, _daoxin - delta * 8.0)
		
		if _daoxin_label: _daoxin_label.text = "道心: %d%%" % int(_daoxin)
		if _daoxin_bar: _daoxin_bar.value = _daoxin
	
	if not _is_running: return
	
	# ---- B: 心魔攻击！ ----
	_is_attacking = true
	_current_pattern = ATTACK_PATTERNS[randi() % ATTACK_PATTERNS.size()]
	_break_free_count = 0
	
	_show_attack_ui(_current_pattern)
	_hide_action_hint()
	
	_pattern_timer = _current_pattern.get("time") or 1.2 / _attack_speed_mult
	var reacted = false
	
	while _pattern_timer > 0 and _is_attacking and _is_running and not reacted:
		await get_tree().process_frame
		_pattern_timer -= get_process_delta_time()
		if _attack_timer:
			_attack_timer.text = "%.1f" % _pattern_timer
			if _pattern_timer < 0.3:     _attack_timer.modulate = Color(1,0.2,0.2)
			elif _pattern_timer < 0.7:   _attack_timer.modulate = Color(1,0.8,0.2)
	
	if _is_attacking and not reacted:
		_is_attacking = false
		_on_wrong_reaction("⏱️ 被心魔命中！")

func _get_input_handler() -> Node:
	return get_node("/root/InputHandler") if has_node("/root/InputHandler") else null

func _is_gamepad_mode() -> bool:
	var ih = _get_input_handler()
	if ih and ih.has_method("is_gamepad_mode"):
		return ih.is_gamepad_mode()
	return Input.get_connected_joypads().size() > 0

func _update_demon_hint_for_mode() -> void:
	"""根据输入模式切换攻击提示"""
	var gp = _is_gamepad_mode()
	# 更新ATTACK_PATTERNS中的提示文本
	# 动态显示，不再展示

func _on_correct_reaction() -> void:
	_is_attacking = false
	var base_damage = 15.0 * (1.0 + _weakness_factor * 0.1)  # 强心魔更难打，但反击伤害一样
	# 实际上应该更难打——心魔越强，单次伤害越低（因为HP更高了）
	# 所以：固定伤害值，但心魔HP更高
	base_damage = 15.0
	
	if _daoxin >= 50:
		base_damage *= 1.5
		_show_center_result("💥 道心一击！-%.0fHP" % base_damage, Color("#ffd700"))
	elif _daoxin >= 25:
		base_damage *= 1.2
		_show_center_result("⚔️ 反击！-%.0fHP" % base_damage, Color("#88ff88"))
	else:
		_show_center_result("✅ 躲开！-%.0fHP" % base_damage, Color("#88aaff"))
	
	_daoxin = max(0, _daoxin - 30.0)
	_demon_hp = max(0, _demon_hp - base_damage)
	_update_demon_hp()
	_score = mini(100, _score + 3.0)
	_play_hit_effect()
	
	await get_tree().create_timer(0.6 / _attack_speed_mult).timeout
	_start_round()

func _on_wrong_reaction(reason: String) -> void:
	_demon_hp = mini(_demon_max_hp, _demon_hp + 5.0)
	_update_demon_hp()
	_score = max(0, _score - 8.0)
	
	# 强度越高，扣血越狠
	var dmg_mult = 0.8 * _damage_mult
	_show_center_result(reason, Color("#ff4444"))
	
	if _player and _player.has_method("take_damage"):
		var damage = int(_config.get("base_damage") or 50 * dmg_mult)
		_player.take_damage(damage, null)
		if _player.has_method("is_dead") and _player.is_dead():
			_is_running = false
			phase_failed.emit("心魔吞噬灵魂")
			return
	
	var cam = get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"): cam.shake(0.3, 12.0)
	
	await get_tree().create_timer(0.8).timeout
	_start_round()

# ==================== BOSS状态 ====================

func _on_demon_defeated() -> void:
	_is_attacking = false; _is_running = false
	_score = mini(100, _score + 20.0)
	
	if _weakness_factor > 2.0:
		_show_center_result("⚡ 战胜远古心魔！道心通明！", Color("#ffd700"))
	elif _weakness_factor > 1.5:
		_show_center_result("🔥 战胜强敌！心魔已破！", Color("#ff8800"))
	else:
		_show_center_result("✨ 心魔消散！道心稳固！", Color("#88ff88"))
	
	_show_action_hint("🧘 战胜自我，境界圆满！", Color("#aaffaa"))
	await get_tree().create_timer(2.0).timeout
	_cleanup_hud()
	phase_completed.emit(_score)

func _complete_phase() -> void:
	_is_running = false; _is_attacking = false
	var hp_ratio = _demon_hp / _demon_max_hp
	if hp_ratio > 0.5:
		_score = max(0, _score - 20.0)
		_show_center_result("⚠️ 心魔未除...", Color("#ff8844"))
	else:
		_score = max(0, _score + 10.0)
		_show_center_result("⚔️ 心魔重创，未能全灭", Color("#88aaff"))
	
	await get_tree().create_timer(2.0).timeout
	_cleanup_hud()
	phase_completed.emit(_score)

# ==================== HUD ====================

func _create_hud() -> void:
	if not _manager: return
	
	_bg = ColorRect.new()
	_bg.name="DemonBg"; _bg.color=Color(0.02,0,0.05,0.5)
	_bg.anchors_preset=Control.PRESET_FULL_RECT; _bg.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_manager.add_child(_bg)
	
	# 心魔图标
	_demon_icon=Label.new(); _demon_icon.name="DemonIcon"; _demon_icon.text="👻"
	_demon_icon.add_theme_font_size_override("font_size",72)
	_demon_icon.anchors_preset=Control.PRESET_CENTER
	_demon_icon.position=Vector2(-50,-130); _demon_icon.custom_minimum_size=Vector2(100,100)
	_demon_icon.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_demon_icon.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	_manager.add_child(_demon_icon)
	
	# 心魔名称（显示强度）
	var nl=Label.new(); nl.name="DemonName"
	var wl = _weakness_factor
	if wl>2.0: nl.text="💀 远古心魔 Lv.3"
	elif wl>1.5: nl.text="👿 强欲心魔 Lv.2"
	else: nl.text="👻 凡根心魔 Lv.1"
	nl.add_theme_font_size_override("font_size",16)
	nl.add_theme_color_override("font_color",Color("#cc66ff"))
	nl.anchors_preset=Control.PRESET_CENTER
	nl.position=Vector2(-80,-70); nl.custom_minimum_size=Vector2(160,20)
	nl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_manager.add_child(nl)
	
	# 强度指示器
	_weakness_indicator=Label.new(); _weakness_indicator.name="WeaknessIndicator"
	var w_text = "⚠️ 道心裂痕 x%.1f" % _weakness_factor
	if wl>2.0: _weakness_indicator.add_theme_color_override("font_color",Color("#ff4444"))
	elif wl>1.5: _weakness_indicator.add_theme_color_override("font_color",Color("#ff8844"))
	else: _weakness_indicator.add_theme_color_override("font_color",Color("#88aa88"))
	_weakness_indicator.text=w_text
	_weakness_indicator.add_theme_font_size_override("font_size",12)
	_weakness_indicator.anchors_preset=Control.PRESET_CENTER
	_weakness_indicator.position=Vector2(-80,-52); _weakness_indicator.custom_minimum_size=Vector2(160,14)
	_weakness_indicator.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_manager.add_child(_weakness_indicator)
	
	# 心魔HP条
	_demon_hp_bar = TextureProgressBar.new(); _demon_hp_bar.name="DemonHPBar"
	_demon_hp_bar.anchors_preset=Control.PRESET_CENTER
	_demon_hp_bar.position=Vector2(-120,-35); _demon_hp_bar.custom_minimum_size=Vector2(240,20)
	_demon_hp_bar.max_value=_demon_max_hp; _demon_hp_bar.value=_demon_hp
	var fill=StyleBoxFlat.new(); fill.bg_color=Color(0.8,0.1,0.3,0.7); fill.corner_radius=4
	var bg_s=StyleBoxFlat.new(); bg_s.bg_color=Color(0.05,0,0.03,0.3); bg_s.corner_radius=4
	_demon_hp_bar.add_theme_stylebox_override("fill",fill)
	_demon_hp_bar.add_theme_stylebox_override("background",bg_s)
	_manager.add_child(_demon_hp_bar)
	
	_demon_hp_label=Label.new(); _demon_hp_label.name="DemonHPLabel"
	_demon_hp_label.text="HP: %d/%d"%[_demon_hp,_demon_max_hp]
	_demon_hp_label.add_theme_font_size_override("font_size",12)
	_demon_hp_label.add_theme_color_override("font_color",Color("#ff6699"))
	_demon_hp_label.anchors_preset=Control.PRESET_CENTER
	_demon_hp_label.position=Vector2(130,-33); _demon_hp_label.custom_minimum_size=Vector2(100,18)
	_manager.add_child(_demon_hp_label)
	
	# 道心条
	_daoxin_bar=TextureProgressBar.new(); _daoxin_bar.name="DaoxinBar"
	_daoxin_bar.anchors_preset=Control.PRESET_CENTER
	_daoxin_bar.position=Vector2(-120,60); _daoxin_bar.custom_minimum_size=Vector2(240,16)
	_daoxin_bar.max_value=100.0; _daoxin_bar.value=0.0
	var dxf=StyleBoxFlat.new(); dxf.bg_color=Color(0.3,0.6,1.0,0.5); dxf.corner_radius=4
	var dxb=StyleBoxFlat.new(); dxb.bg_color=Color(0.02,0.02,0.05,0.2); dxb.corner_radius=4
	_daoxin_bar.add_theme_stylebox_override("fill",dxf)
	_daoxin_bar.add_theme_stylebox_override("background",dxb)
	_manager.add_child(_daoxin_bar)
	
	_daoxin_label=Label.new(); _daoxin_label.name="DaoxinLabel"
	_daoxin_label.text="道心: 0%"
	_daoxin_label.add_theme_font_size_override("font_size",12)
	_daoxin_label.add_theme_color_override("font_color",Color("#88aaff"))
	_daoxin_label.anchors_preset=Control.PRESET_CENTER
	_daoxin_label.position=Vector2(130,58); _daoxin_label.custom_minimum_size=Vector2(100,14)
	_manager.add_child(_daoxin_label)
	
	# 攻击面板
	_attack_panel=Panel.new(); _attack_panel.name="AttackPanel"
	_attack_panel.anchors_preset=Control.PRESET_CENTER
	_attack_panel.position=Vector2(-120,-20); _attack_panel.custom_minimum_size=Vector2(240,50)
	_attack_panel.size=Vector2(240,50); _attack_panel.visible=false
	var aps=StyleBoxFlat.new(); aps.bg_color=Color(0.1,0,0.15,0.85)
	aps.corner_radius=8; aps.set_border_width_all(2); aps.border_color=Color("#8844cc")
	_attack_panel.add_theme_stylebox_override("panel",aps)
	_manager.add_child(_attack_panel)
	
	_attack_icon=Label.new(); _attack_icon.name="AttackIcon"
	_attack_icon.text="🔥"; _attack_icon.add_theme_font_size_override("font_size",36)
	_attack_icon.anchors_preset=Control.PRESET_CENTER
	_attack_icon.position=Vector2(-100,-8); _attack_icon.custom_minimum_size=Vector2(44,44)
	_attack_icon.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_attack_panel.add_child(_attack_icon)
	
	_attack_arrow=Label.new(); _attack_arrow.name="AttackArrow"
	_attack_arrow.text="⤵️"; _attack_arrow.add_theme_font_size_override("font_size",28)
	_attack_arrow.anchors_preset=Control.PRESET_CENTER
	_attack_arrow.position=Vector2(-50,-8); _attack_arrow.custom_minimum_size=Vector2(40,40)
	_attack_arrow.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_attack_panel.add_child(_attack_arrow)
	
	_attack_hint=Label.new(); _attack_hint.name="AttackHint"
	_attack_hint.text="蹲伏 [↓]"; _attack_hint.add_theme_font_size_override("font_size",15)
	_attack_hint.add_theme_color_override("font_outline_color",Color.BLACK)
	_attack_hint.add_theme_constant_override("outline_size",2)
	_attack_hint.anchors_preset=Control.PRESET_CENTER
	_attack_hint.position=Vector2(10,-10); _attack_hint.custom_minimum_size=Vector2(120,30)
	_attack_panel.add_child(_attack_hint)
	
	_attack_timer=Label.new(); _attack_timer.name="AttackTimer"
	_attack_timer.text=""; _attack_timer.add_theme_font_size_override("font_size",14)
	_attack_timer.add_theme_color_override("font_color",Color(1,1,1,0.5))
	_attack_timer.anchors_preset=Control.PRESET_CENTER
	_attack_timer.position=Vector2(-105,12); _attack_timer.custom_minimum_size=Vector2(30,16)
	_attack_panel.add_child(_attack_timer)
	
	_center_result=Label.new(); _center_result.name="CenterResult"
	_center_result.text=""; _center_result.add_theme_font_size_override("font_size",22)
	_center_result.add_theme_color_override("font_outline_color",Color.BLACK)
	_center_result.add_theme_constant_override("outline_size",4)
	_center_result.anchors_preset=Control.PRESET_CENTER
	_center_result.position=Vector2(-160,100); _center_result.custom_minimum_size=Vector2(320,30)
	_center_result.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_manager.add_child(_center_result)
	
	_action_hint=Label.new(); _action_hint.name="ActionHint"
	_action_hint.text=""; _action_hint.add_theme_font_size_override("font_size",16)
	_action_hint.add_theme_color_override("font_outline_color",Color.BLACK)
	_action_hint.add_theme_constant_override("outline_size",3)
	_action_hint.anchors_preset=Control.PRESET_CENTER_BOTTOM
	_action_hint.offset_bottom=-60; _action_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_manager.add_child(_action_hint)
	
	_top_label=_label("PhaseDemonTop",18,80,Color("#cc66ff"))

func _label(n,s,t,c=Color(1,1,0.5)):
	var l=_manager.get_node_or_null(n)
	if l: return l
	l=Label.new(); l.name=n; l.add_theme_font_size_override("font_size",s)
	l.add_theme_color_override("font_color",c)
	l.add_theme_color_override("font_outline_color",Color.BLACK)
	l.add_theme_constant_override("outline_size",3)
	_manager.add_child(l)
	return l

# ==================== UI更新 ====================

func _show_attack_ui(p: Dictionary) -> void:
	if not _attack_panel: return
	_attack_panel.visible=true
	_attack_icon.text=p.get("icon") or "🔥"
	_attack_arrow.text=p.get("arrow") or "⤵️"
	# 根据输入模式动态切换提示
	var gp = _is_gamepad_mode()
	var hint_action = p.get("action") or ""
	var hint_map = {
		"dodge_down": "蹲伏 [↓/D-Down]" if not gp else "蹲伏 [↓]",
		"dodge_up": "跳跃 [↑/D-Up]" if not gp else "跳跃 [↑]",
		"defend": "凝神 [␣/Ⓐ]" if not gp else "凝神 [Ⓐ]",
		"break_free": "挣脱 [←→连按]" if not gp else "挣脱 [←→]",
	}
	_attack_hint.text = hint_map.get(hint_action, p.get("hint") or "")
	_attack_hint.add_theme_color_override("font_color",p.get("color") or Color.WHITE)
	_attack_timer.text="%.1f"%(p.get("time") or 1.2/_attack_speed_mult)
	
	var s=StyleBoxFlat.new(); s.bg_color=Color(0.1,0,0.15,0.85)
	s.corner_radius=8; s.set_border_width_all(2)
	s.border_color=p.get("color") or Color("#8844cc")
	_attack_panel.add_theme_stylebox_override("panel",s)
	
	_attack_panel.scale=Vector2(0.1,0.1)
	var tw=create_tween()
	tw.tween_property(_attack_panel,"scale",Vector2(1.2,1.2),0.15).set_trans(Tween.TRANS_BOUNCE)
	tw.tween_property(_attack_panel,"scale",Vector2(1.0,1.0),0.1)

func _hide_attack_ui() -> void:
	if _attack_panel: _attack_panel.visible=false

func _show_center_result(text:String,color:Color) -> void:
	if _center_result:
		_center_result.text=text; _center_result.add_theme_color_override("font_color",color)
		_center_result.scale=Vector2(1.5,1.5)
		var tw=create_tween()
		tw.tween_property(_center_result,"scale",Vector2(1.0,1.0),0.3).set_trans(Tween.TRANS_BOUNCE)
		tw.tween_property(_center_result,"modulate",Color(color.r,color.g,color.b,0),1.2).set_delay(0.5)

func _show_action_hint(text:String,c:Color=Color(1,1,1)) -> void:
	if _action_hint: _action_hint.text=text; _action_hint.add_theme_color_override("font_color",c)

func _hide_action_hint() -> void:
	if _action_hint: _action_hint.text=""

func _update_demon_hp() -> void:
	if _demon_hp_bar: _demon_hp_bar.value=_demon_hp
	if _demon_hp_label: _demon_hp_label.text="HP: %d/%d"%[_demon_hp,_demon_max_hp]
	if _demon_hp<_demon_max_hp*0.3 and _demon_icon: _demon_icon.text="💀"

func _play_hit_effect() -> void:
	if _demon_icon:
		_demon_icon.modulate=Color(1,0.5,0.5)
		var pos=_demon_icon.position
		var tw=create_tween()
		tw.tween_property(_demon_icon,"modulate",Color(1,1,1),0.3)
		tw.parallel().tween_method(func(o):
			if _demon_icon: _demon_icon.position=pos+Vector2(randf_range(-5,5),0)
		,0,0,0.2)
		tw.tween_callback(func(): if _demon_icon: _demon_icon.position=pos)

func _cleanup_hud() -> void:
	var nms=["DemonBg","DemonIcon","DemonName","DemonHPBar","DemonHPLabel",
		"DaoxinBar","DaoxinLabel","AttackPanel","CenterResult",
		"ActionHint","PhaseDemonTop","WeaknessIndicator"]
	for n in nms:
		var nd=_manager.get_node_or_null(n)
		if nd: nd.queue_free()

func _unregister_actions() -> void:
	"""清理注册的手柄动作"""
	for act in ["trib_demon_up","trib_demon_down","trib_demon_defend",
	             "trib_demon_break_left","trib_demon_break_right"]:
		if InputMap.has_action(act):
			InputMap.erase_action(act)

func _exit_tree() -> void:
	_is_running=false; _is_attacking=false
	_unregister_actions()
	_cleanup_hud()
