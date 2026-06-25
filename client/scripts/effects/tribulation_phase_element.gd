extends Node
## 🛡️ 雷劫·第二阶段：五行抗雷
##
## 玩法：
##   天雷带有五行属性劈下
##   玩家必须在限定时间内按【五行相克】规则切换对应护盾
##   ✔️ 正确克制 → 挡下伤害 + 大量渡劫进度
##   ❌ 被克/错误 → 全吃伤害 + 进度扣减
##   ⏱️ 超时未按 → 中等伤害
##
## 🎮 操作方式：
##   键盘：Q=木 W=火 E=土 R=金 T=水 (直接按键)
##   手柄：←→ 循环选择护盾 Ⓐ 确认
##
## 五行相克：
##   🌿木雷 → R(金)  🔥火雷 → T(水)  🗿土雷 → Q(木)
##   ⚔️金雷 → W(火)  💧水雷 → E(土)

class_name TribulationPhaseElement

signal phase_completed(score: float)
signal phase_failed(reason: String)

# ==================== 五行常量 ====================
const ELEMENTS = ["wood", "fire", "earth", "metal", "water"]
const ELEMENT_NAMES = {
	"wood":  "🌿 木", "fire":  "🔥 火", "earth": "🗿 土",
	"metal": "⚔️ 金", "water": "💧 水",
}
const ELEMENT_ICONS = {"wood": "🌿", "fire": "🔥", "earth": "🗿", "metal": "⚔️", "water": "💧"}
const ELEMENT_COLORS = {
	"wood":  Color("#4ae07a"), "fire":  Color("#ff4422"),
	"earth": Color("#d4a030"), "metal": Color("#e0e0e8"), "water": Color("#4488ff"),
}

# 五行相克: incoming -> 正确护盾
const COUNTER_MAP = {"wood": "metal", "fire": "water", "earth": "wood", "metal": "fire", "water": "earth"}
# 被克（选到被克元素=暴击）
const WEAK_MAP = {"wood": "fire", "fire": "wood", "earth": "metal", "metal": "water", "water": "earth"}
# 键盘映射
const KEY_MAP = {"wood": KEY_Q, "fire": KEY_W, "earth": KEY_E, "metal": KEY_R, "water": KEY_T}

# ==================== 引用 ====================
var _manager: Node = null
var _player: Node = null
var _config: Dictionary = {}

# ==================== 状态 ====================
var _total_rounds: int = 5
var _current_round: int = 0
var _score: float = 100.0
var _combo: int = 0
var _max_combo: int = 0
var _is_round_active: bool = false
var _current_strike: String = ""
var _current_answer: String = ""
var _timer_value: float = 0.0
var _timer_max: float = 2.0
var _is_running: bool = false

# 🎮 手柄循环选择
var _controller_sel_index: int = 2  # 默认选中earth(中间)
var _has_controller: bool = false    # 检测到手柄后切换UI提示

# ==================== UI节点 ====================
var _phase_hint: Label = null
var _incoming_label: Label = null
var _timer_label: Label = null
var _combo_label: Label = null
var _element_hud: Control = null
var _shield_indicators: Dictionary = {}  # element -> Panel
var _controller_hint: Label = null
var _sel_arrow_left: Label = null
var _sel_arrow_right: Label = null

func _init(manager: Node, player: Node, config: Dictionary) -> void:
	_manager = manager
	_player = player
	_config = config
	_total_rounds = config.get("element_rounds") or 5
	name = "PhaseElement"

func _ready() -> void:
	_register_actions()

func _register_actions() -> void:
	"""注册键盘+手柄动作"""
	# 键盘：每个元素一个动作
	for elem in ELEMENTS:
		var action = "trib_elem_%s" % elem
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var ev = InputEventKey.new()
			ev.keycode = KEY_MAP[elem]
			InputMap.action_add_event(action, ev)
	
	# 手柄：循环选择 + 确认
	for act in ["trib_cycle_left", "trib_cycle_right", "trib_confirm"]:
		if not InputMap.has_action(act):
			InputMap.add_action(act)
	
	# 为trib_cycle_left找已有绑定
	if InputMap.get_actions().find("ui_left") >= 0:
		# 复用ui_left/right的Gamepad绑定
		if InputMap.action_get_events("ui_left").size() > 0:
			for ev in InputMap.action_get_events("ui_left"):
				if ev is InputEventJoypadButton:
					var new_ev = ev.duplicate()
					InputMap.action_add_event("trib_cycle_left", new_ev)
		# UI没有手柄绑定？手动加
		var acts = InputMap.action_get_events("trib_cycle_left")
		if acts.is_empty():
			var ev = InputEventJoypadButton.new()
			ev.button_index = JOY_BUTTON_DPAD_LEFT
			InputMap.action_add_event("trib_cycle_left", ev)
			# 左摇杆左
			var ev2 = InputEventJoypadMotion.new()
			ev2.axis = JOY_AXIS_LEFT_X
			ev2.axis_value = -1.0
			InputMap.action_add_event("trib_cycle_left", ev2)
	
	if InputMap.action_get_events("trib_cycle_right").is_empty():
		var ev = InputEventJoypadButton.new()
		ev.button_index = JOY_BUTTON_DPAD_RIGHT
		InputMap.action_add_event("trib_cycle_right", ev)
		var ev2 = InputEventJoypadMotion.new()
		ev2.axis = JOY_AXIS_LEFT_X
		ev2.axis_value = 1.0
		InputMap.action_add_event("trib_cycle_right", ev2)
	
	if InputMap.action_get_events("trib_confirm").is_empty():
		var ev = InputEventJoypadButton.new()
		ev.button_index = JOY_BUTTON_A  # Ⓐ
		InputMap.action_add_event("trib_confirm", ev)

func _input(event: InputEvent) -> void:
	if not _is_running or not _is_round_active:
		return
	
	# ---- 键盘直接选择 ---- 
	for elem in ELEMENTS:
		if event.is_action_pressed("trib_elem_%s" % elem):
			get_viewport().set_input_as_handled()
			_on_element_selected(elem)
			return
	
	# ---- 手柄循环选择 ----
	if event.is_action_pressed("trib_cycle_left"):
		get_viewport().set_input_as_handled()
		_has_controller = true
		_controller_sel_index = (_controller_sel_index - 1 + 5) % 5
		_update_controller_highlight()
		
	elif event.is_action_pressed("trib_cycle_right"):
		get_viewport().set_input_as_handled()
		_has_controller = true
		_controller_sel_index = (_controller_sel_index + 1) % 5
		_update_controller_highlight()
		
	elif event.is_action_pressed("trib_confirm"):
		get_viewport().set_input_as_handled()
		if _has_controller:
			_on_element_selected(ELEMENTS[_controller_sel_index])

# ==================== 启动 ====================

func start() -> void:
	_is_running = true
	_create_hud()
	_show_phase_intro()
	await get_tree().create_timer(2.0).timeout
	if _is_running:
		_start_round()

# ==================== 波次逻辑 ====================

func _start_round() -> void:
	if not _is_running or _current_round >= _total_rounds:
		_complete_phase()
		return
	
	_current_round += 1
	_is_round_active = true
	_controller_sel_index = 2  # 重置选择
	
	_current_strike = ELEMENTS[randi() % ELEMENTS.size()]
	_current_answer = COUNTER_MAP[_current_strike]
	
	_update_round_display()
	_show_incoming_bolt(_current_strike)
	
	# 倒计时
	_timer_value = _timer_max
	_timer_label.visible = true
	
	while _timer_value > 0 and _is_round_active and _is_running:
		await get_tree().process_frame
		_timer_value -= get_process_delta_time()
		if _timer_label and is_instance_valid(_timer_label):
			_timer_label.text = "%.1f" % _timer_value
			if _timer_value < 0.5:      _timer_label.modulate = Color(1, 0.2, 0.2)
			elif _timer_value < 1.0:    _timer_label.modulate = Color(1, 0.8, 0.2)
			else:                        _timer_label.modulate = Color(0.3, 1, 0.3)
	
	if _is_round_active:
		_is_round_active = false
		_on_timeout()

func _on_element_selected(elem: String) -> void:
	if not _is_round_active: return
	_is_round_active = false
	
	_highlight_shield(elem, true)
	
	if elem == _current_answer:
		# ✅ 正确！
		_combo += 1
		if _combo > _max_combo: _max_combo = _combo
		var bonus = mini(_combo, 10) * 2
		_score = mini(100, _score + 12.0 + bonus)
		_show_result("✅ 克制成功！+%d%%" % (12 + bonus), Color(0.3, 1, 0.3))
		_play_shield_effect(elem, true)
		
	elif elem == WEAK_MAP.get(_current_strike, ""):
		# 🔴 被克！暴击！
		_combo = 0
		_score = max(0, _score - 20.0)
		_show_result("💥 被相克！-%d%%" % 20, Color(1, 0.2, 0.2))
		_play_shield_effect(elem, false)
		_apply_damage(1.5)
	else:
		# ⚠️ 错误
		_combo = 0
		_score = max(0, _score - 10.0)
		var correct_name = ELEMENT_NAMES.get(_current_answer, "?")
		_show_result("❌ 应选 %s -%d%%" % [correct_name, 10], Color(1, 0.6, 0.2))
		_play_shield_effect(elem, false)
		_apply_damage(1.0)
	
	_update_combo_display()
	await get_tree().create_timer(0.8).timeout
	_highlight_shield(elem, false)
	if _is_running: _start_round()

func _on_timeout() -> void:
	_combo = 0
	_score = max(0, _score - 15.0)
	var correct_name = ELEMENT_NAMES.get(_current_answer, "?")
	_show_result("⏱️ 超时！应选 %s -%d%%" % [correct_name, 15], Color(1, 0.6, 0.2))
	_play_shield_effect("", false)
	_apply_damage(1.2)
	_update_combo_display()
	await get_tree().create_timer(0.8).timeout
	if _is_running: _start_round()

func _apply_damage(mult: float = 1.0) -> void:
	if not _player or not is_instance_valid(_player): return
	var damage = int(_config.get("base_damage") or 50 * mult)
	if _player.has_method("take_damage"):
		_player.take_damage(damage, null)
	if _player.has_method("is_dead") and _player.is_dead():
		_is_running = false
		phase_failed.emit("被天雷击倒")

# ==================== HUD ====================

func _create_hud() -> void:
	if not _manager: return
	
	# 波次提示
	_phase_hint = _label("PhaseElementHint", 22, 80, Color(1, 1, 0.5))
	_phase_hint.anchors_preset = Control.PRESET_TOP_WIDE
	_phase_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# 天雷属性（大图标）
	_incoming_label = Label.new()
	_incoming_label.name = "IncomingLabel"
	_incoming_label.text = ""
	_incoming_label.add_theme_font_size_override("font_size", 40)
	_incoming_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_incoming_label.add_theme_constant_override("outline_size", 5)
	_incoming_label.anchors_preset = Control.PRESET_CENTER
	_incoming_label.position = Vector2(-100, -120)
	_incoming_label.custom_minimum_size = Vector2(200, 80)
	_incoming_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_incoming_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_manager.add_child(_incoming_label)
	
	# 倒计时
	_timer_label = Label.new()
	_timer_label.name = "TimerLabel"
	_timer_label.text = ""
	_timer_label.add_theme_font_size_override("font_size", 28)
	_timer_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_timer_label.add_theme_constant_override("outline_size", 3)
	_timer_label.anchors_preset = Control.PRESET_CENTER
	_timer_label.position = Vector2(120, -120)
	_timer_label.custom_minimum_size = Vector2(60, 40)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.visible = false
	_manager.add_child(_timer_label)
	
	# 连击
	_combo_label = Label.new()
	_combo_label.name = "ComboLabel"
	_combo_label.text = ""
	_combo_label.add_theme_font_size_override("font_size", 18)
	_combo_label.add_theme_color_override("font_color", Color("#ffd700"))
	_combo_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_combo_label.add_theme_constant_override("outline_size", 2)
	_combo_label.anchors_preset = Control.PRESET_TOP_WIDE
	_combo_label.offset_top = 115
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_manager.add_child(_combo_label)
	
	# ---- 五个护盾（底部） ----
	_element_hud = Control.new()
	_element_hud.name = "ElementShields"
	_element_hud.anchors_preset = Control.PRESET_CENTER_BOTTOM
	_element_hud.offset_bottom = -50
	_element_hud.custom_minimum_size = Vector2(550, 90)
	_element_hud.position = Vector2(-275, -45)
	_manager.add_child(_element_hud)
	
	var shield_order = ["wood", "fire", "earth", "metal", "water"]
	var shield_keys = ["Q", "W", "E", "R", "T"]
	var x_pos = 0
	
	for i in range(shield_order.size()):
		var elem = shield_order[i]
		var key = shield_keys[i]
		
		var shield = Panel.new()
		shield.name = "Shield_%s" % elem
		shield.custom_minimum_size = Vector2(90, 90)
		shield.position = Vector2(x_pos, 0)
		shield.size = Vector2(90, 90)
		_shield_indicators[elem] = shield
		_element_hud.add_child(shield)
		
		# 图标
		var icon = Label.new()
		icon.text = ELEMENT_ICONS[elem]
		icon.add_theme_font_size_override("font_size", 30)
		icon.anchors_preset = Control.PRESET_CENTER
		icon.position = Vector2(-15, -22)
		icon.custom_minimum_size = Vector2(30, 30)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shield.add_child(icon)
		
		# 按键提示
		var kl = Label.new()
		kl.text = key
		kl.add_theme_font_size_override("font_size", 12)
		kl.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
		kl.anchors_preset = Control.PRESET_CENTER
		kl.position = Vector2(-8, 18)
		kl.custom_minimum_size = Vector2(16, 16)
		kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shield.add_child(kl)
		
		# 名称
		var nl = Label.new()
		nl.text = ELEMENT_NAMES[elem].split(" ")[1]
		nl.add_theme_font_size_override("font_size", 10)
		nl.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
		nl.anchors_preset = Control.PRESET_CENTER
		nl.position = Vector2(-12, 34)
		nl.custom_minimum_size = Vector2(24, 12)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shield.add_child(nl)
		
		# 默认样式
		_update_shield_style(elem, false)
		
		x_pos += 100
	
	# 手柄选择箭头
	_sel_arrow_left = Label.new()
	_sel_arrow_left.name = "SelArrowLeft"
	_sel_arrow_left.text = "◀"
	_sel_arrow_left.add_theme_font_size_override("font_size", 20)
	_sel_arrow_left.add_theme_color_override("font_color", Color(1, 1, 0.3, 0.3))
	_sel_arrow_left.anchors_preset = Control.PRESET_CENTER
	_sel_arrow_left.position = Vector2(-320, 45)
	_sel_arrow_left.visible = false
	_manager.add_child(_sel_arrow_left)
	
	_sel_arrow_right = Label.new()
	_sel_arrow_right.name = "SelArrowRight"
	_sel_arrow_right.text = "▶"
	_sel_arrow_right.add_theme_font_size_override("font_size", 20)
	_sel_arrow_right.add_theme_color_override("font_color", Color(1, 1, 0.3, 0.3))
	_sel_arrow_right.anchors_preset = Control.PRESET_CENTER
	_sel_arrow_right.position = Vector2(310, 45)
	_sel_arrow_right.visible = false
	_manager.add_child(_sel_arrow_right)
	
	# 底部五行相克提示
	var b = Label.new()
	b.name = "BottomHint"
	b.text = "🛡️ 五行相克：木克土·土克水·水克火·火克金·金克木"
	b.add_theme_font_size_override("font_size", 11)
	b.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.4))
	b.anchors_preset = Control.PRESET_CENTER_BOTTOM
	b.offset_bottom = -12
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_manager.add_child(b)
	
	# 🎮 手柄操作提示（默认隐藏，检测到手柄后显示）
	_controller_hint = Label.new()
	_controller_hint.name = "ControllerHint"
	_controller_hint.text = "🎮 ← → 选择  Ⓐ 确认"
	_controller_hint.add_theme_font_size_override("font_size", 12)
	_controller_hint.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0, 0.6))
	_controller_hint.anchors_preset = Control.PRESET_CENTER_BOTTOM
	_controller_hint.offset_bottom = -30
	_controller_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_controller_hint.visible = false
	_manager.add_child(_controller_hint)

func _label(name: String, size: int, top: int, color: Color = Color(1, 1, 0.5)) -> Label:
	if _manager and _manager.has_node(name): return _manager.get_node(name)
	var l = Label.new()
	l.name = name
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	_manager.add_child(l)
	return l

# ==================== UI更新 ====================

func _update_round_display() -> void:
	if _phase_hint: _phase_hint.text = "第 %d / %d 雷" % [_current_round, _total_rounds]
	var sl = _manager.get_node_or_null("ScoreLabel")
	if sl: sl.text = "渡劫进度: %d%%" % int(_score)

func _show_incoming_bolt(element: String) -> void:
	if not _incoming_label or not is_instance_valid(_incoming_label): return
	_incoming_label.text = "%s" % ELEMENT_ICONS[element]
	_incoming_label.add_theme_color_override("font_color", ELEMENT_COLORS[element])
	_incoming_label.scale = Vector2(0.1, 0.1)
	var tw = create_tween()
	tw.tween_property(_incoming_label, "scale", Vector2(1.5, 1.5), 0.3).set_trans(Tween.TRANS_BOUNCE)
	tw.tween_property(_incoming_label, "scale", Vector2(1.0, 1.0), 0.2)
	_pulse_shield(COUNTER_MAP[element])
	
	var cn = ELEMENT_NAMES[COUNTER_MAP[element]]
	_show_hint("选择 [color=#%s]%s[/color] ！" % [ELEMENT_COLORS[COUNTER_MAP[element]].to_html(false), cn])

func _show_result(text: String, color: Color) -> void:
	_show_hint(text, color)

func _show_hint(text: String, color: Color = Color(1, 1, 0.3)) -> void:
	var h = _manager.get_node_or_null("CenterHint")
	if h and h is Label:
		h.text = text
		h.modulate = color
		var tw = create_tween()
		tw.tween_property(h, "modulate", Color(color.r, color.g, color.b, 0), 0.8).set_delay(0.3)

func _update_combo_display() -> void:
	if _combo_label:
		if _combo >= 2:
			_combo_label.text = "🔥 %d连击！" % _combo
			_combo_label.modulate = Color(1, 0.8, 0.2)
			var tw = create_tween()
			tw.tween_property(_combo_label, "scale", Vector2(1.3, 1.3), 0.1)
			tw.tween_property(_combo_label, "scale", Vector2(1.0, 1.0), 0.15)
		else: _combo_label.text = ""

func _update_controller_highlight() -> void:
	"""更新手柄选择的护盾高亮"""
	if not _has_controller: 
		_has_controller = true
		_controller_hint.visible = true
		_sel_arrow_left.visible = true
		_sel_arrow_right.visible = true
	
	var sel_elem = ELEMENTS[_controller_sel_index]
	
	# 重置所有护盾
	for elem in ELEMENTS:
		_update_shield_style(elem, false)
	
	# 高亮选中的
	_update_shield_style(sel_elem, true)

func _update_shield_style(elem: String, selected: bool) -> void:
	var shield = _shield_indicators.get(elem)
	if not shield: return
	
	var s = StyleBoxFlat.new()
	if selected:
		s.bg_color = ELEMENT_COLORS[elem]
		s.bg_color.a = 0.7
		s.corner_radius = 45
		s.set_border_width_all(3)
		s.border_color = Color.WHITE
		# 发光边框
		s.shadow_size = 8
		s.shadow_color = ELEMENT_COLORS[elem]
	else:
		s.bg_color = ELEMENT_COLORS[elem]
		s.bg_color.a = 0.25
		s.corner_radius = 45
		s.set_border_width_all(2)
		s.border_color = ELEMENT_COLORS[elem]
		s.border_color.a = 0.4
		s.shadow_size = 0
	shield.add_theme_stylebox_override("panel", s)

func _highlight_shield(elem: String, on: bool) -> void:
	_update_shield_style(elem, on)

func _pulse_shield(elem: String) -> void:
	for i in 3:
		_update_shield_style(elem, true)
		await get_tree().create_timer(0.12).timeout
		_update_shield_style(elem, false)
		await get_tree().create_timer(0.08).timeout

func _play_shield_effect(elem: String, success: bool) -> void:
	if not success:
		var hud = _manager.get_node_or_null("TribulationHUD")
		if hud and hud.has_method("shake"): hud.shake()
		var cam = get_tree().get_first_node_in_group("camera")
		if cam and cam.has_method("shake"): cam.shake(0.2, 10.0)

# ==================== 完成/清理 ====================

func _show_phase_intro() -> void:
	_show_hint("🛡️ 五行护体！键盘Q/W/E/R/T 或手柄←→+Ⓐ", Color(0.3, 1, 0.5))
	if _phase_hint: _phase_hint.text = "🛡️ 五行抗雷 — %d 雷" % _total_rounds

func _complete_phase() -> void:
	_is_running = false
	_is_round_active = false
	_show_hint("🎉 五行抗雷完成！")
	await get_tree().create_timer(1.2).timeout
	_cleanup_hud()
	phase_completed.emit(_score)

func _cleanup_hud() -> void:
	var names = ["IncomingLabel","TimerLabel","ComboLabel","ElementShields",
		"PhaseElementHint","BottomHint","ControllerHint","SelArrowLeft","SelArrowRight"]
	for n in names:
		var node = _manager.get_node_or_null(n)
		if node: node.queue_free()

func _get_input_handler() -> Node:
	return get_node("/root/InputHandler") if has_node("/root/InputHandler") else null

func _is_gamepad_mode() -> bool:
	var ih = _get_input_handler()
	if ih and ih.has_method("is_gamepad_mode"):
		return ih.is_gamepad_mode()
	# fallback: 检测是否有手柄连接
	return Input.get_connected_joypads().size() > 0

func _update_hint_for_input_mode() -> void:
	"""根据输入模式切换UI提示文字"""
	var is_gp = _is_gamepad_mode()
	if _controller_hint:
		_controller_hint.visible = is_gp
		_sel_arrow_left.visible = is_gp
		_sel_arrow_right.visible = is_gp
		if is_gp:
			_controller_hint.text = "🎮 ← → 选择  Ⓐ 确认"
	# 护盾按键角标切换
	for i in range(ELEMENTS.size()):
		var elem = ELEMENTS[i]
		var shield = _shield_indicators.get(elem)
		if shield and shield.get_child_count() >= 2:
			var kl = shield.get_child(1)  # 第二个子节点是按键提示
			if kl is Label:
				if is_gp:
					var gp_keys = ["←/▶", "▶/←", "Ⓐ", "Ⓐ", "Ⓐ"]
					kl.text = "D%d" % (i+1) if i < 4 else ""
				else:
					var kb_keys = {"wood":"Q","fire":"W","earth":"E","metal":"R","water":"T"}
					kl.text = kb_keys.get(elem, "?")

func _unregister_actions() -> void:
	"""清理注册的动作"""
	for elem in ELEMENTS:
		var action = "trib_elem_%s" % elem
		if InputMap.has_action(action):
			InputMap.erase_action(action)
	for act in ["trib_cycle_left", "trib_cycle_right", "trib_confirm"]:
		if InputMap.has_action(act):
			InputMap.erase_action(act)

func _exit_tree() -> void:
	_is_running = false; _is_round_active = false
	_unregister_actions()
	_cleanup_hud()
