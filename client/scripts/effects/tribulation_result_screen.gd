extends Control
## 🏆 渡劫结算界面 — 三阶段评分 + 奖励展示

class_name TribulationResultScreen

signal result_dismissed(accepted: bool)

# ==================== 常量 ====================
const RATING_DISPLAY = {
	"tian": {"name": "天阶", "color": Color("#ffd700"), "icon": "🌟"},
	"di":   {"name": "地阶", "color": Color("#44ccaa"), "icon": "✨"},
	"ren":  {"name": "人阶", "color": Color("#88aacc"), "icon": "✅"},
}

const PHASE_ICONS = {1: "⚡", 2: "🛡️", 3: "👻"}
const PHASE_NAMES = {1: "天雷闪避", 2: "五行抗雷", 3: "心魔幻境"}

# ==================== 状态 ====================
var _success: bool
var _rating: String
var _rewards: Dictionary
var _scores: Dictionary
var _realm_name: String

func _init(success: bool, rating: String, rewards: Dictionary, scores: Dictionary, realm_name: String) -> void:
	_success = success
	_rating = rating
	_rewards = rewards
	_scores = scores
	_realm_name = realm_name
	name = "TribulationResult"

func _ready() -> void:
	_build_ui()
	_play_entry_animation()

func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 暗色背景
	var bg = ColorRect.new()
	bg.name = "Bg"
	bg.color = Color(0, 0, 0, 0)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	
	# 主面板容器
	var panel = Panel.new()
	panel.name = "Panel"
	panel.anchors_preset = Control.PRESET_CENTER
	panel.custom_minimum_size = Vector2(500, 450)
	panel.size = Vector2(500, 450)
	panel.position = Vector2(-250, -225)
	panel.modulate = Color(1, 1, 1, 0)
	
	var panel_style = StyleBoxFlat.new()
	if _success:
		panel_style.bg_color = Color(0.05, 0.03, 0.1, 0.9)
		panel_style.set_border_width_all(2)
		panel_style.border_color = RATING_DISPLAY.get(_rating, {"color": Color.GRAY})["color"]
	else:
		panel_style.bg_color = Color(0.1, 0.02, 0.02, 0.9)
		panel_style.set_border_width_all(2)
		panel_style.border_color = Color("#662222")
	panel_style.corner_radius = 12
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.name = "MainVBox"
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.offset_left = 24
	vbox.offset_right = -24
	vbox.offset_top = 20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)
	
	if _success:
		_build_success_ui(vbox)
	else:
		_build_failure_ui(vbox)
	
	# 确认按钮
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.offset_top = 20
	
	var confirm_btn = Button.new()
	confirm_btn.name = "ConfirmBtn"
	if _success:
		var rating_data = RATING_DISPLAY.get(_rating, {"name": "未知"})
		confirm_btn.text = "%s 接受突破，飞升 %s !" % [rating_data.get("icon") or "✅", _realm_name]
	else:
		confirm_btn.text = "接受道伤，修养后再试..."
	confirm_btn.custom_minimum_size = Vector2(300, 40)
	confirm_btn.pressed.connect(_on_confirm)
	btn_hbox.add_child(confirm_btn)
	
	vbox.add_child(HSeparator.new())
	vbox.add_child(btn_hbox)

func _build_success_ui(vbox: VBoxContainer) -> void:
	var rating_data = RATING_DISPLAY.get(_rating, {"name": "未知", "color": Color.GRAY, "icon": "❓"})
	
	# 标题
	var title = Label.new()
	title.text = "%s 渡劫成功！" % rating_data["icon"]
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", rating_data["color"])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 3)
	vbox.add_child(title)
	
	# 评级
	var rating_label = Label.new()
	rating_label.text = "评价: " + str(rating_data.get("icon", "")) + " " + str(rating_data.get("name", ""))
	rating_label.add_theme_font_size_override("font_size", 22)
	rating_label.add_theme_color_override("font_color", rating_data["color"])
	rating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(rating_label)
	
	vbox.add_child(HSeparator.new())
	
	# 阶段得分
	var score_title = Label.new()
	score_title.text = "━━ 三阶段评分 ━━"
	score_title.add_theme_font_size_override("font_size", 14)
	score_title.add_theme_color_override("font_color", Color("#aaaaaa"))
	score_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(score_title)
	
	for phase_num in [1, 2, 3]:
		var score = _scores.get(phase_num, 0)
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		
		var icon = Label.new()
		icon.text = PHASE_ICONS.get(phase_num, "❓")
		icon.add_theme_font_size_override("font_size", 18)
		icon.custom_minimum_size = Vector2(30, 0)
		hbox.add_child(icon)
		
		var name_label = Label.new()
		name_label.text = PHASE_NAMES.get(phase_num, "未知")
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.size_flags_horizontal = SIZE_EXPAND_FILL
		hbox.add_child(name_label)
		
		var score_val = Label.new()
		score_val.text = "%d%%" % score
		score_val.add_theme_font_size_override("font_size", 16)
		score_val.add_theme_color_override("font_color", _get_score_color(score))
		score_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(score_val)
		
		vbox.add_child(hbox)
	
	vbox.add_child(HSeparator.new())
	
	# 奖励列表
	var reward_title = Label.new()
	reward_title.text = "━━ 渡劫奖励 ━━"
	reward_title.add_theme_font_size_override("font_size", 14)
	reward_title.add_theme_color_override("font_color", Color("#aaaaaa"))
	reward_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(reward_title)
	
	var reward_text = ""
	if _rewards.get("hp_bonus") or 0 > 0:
		reward_text += "❤️ 生命上限 +%d\n" % _rewards["hp_bonus"]
	if _rewards.get("attack_bonus") or 0 > 0:
		reward_text += "⚔️ 攻击力 +%d\n" % _rewards["attack_bonus"]
	if _rewards.get("speed_bonus") or 0 > 0:
		reward_text += "💨 移速 +%.0f%%\n" % (_rewards["speed_bonus"] * 100)
	if _rewards.get("xp_bonus") or 0 > 0:
		reward_text += "📖 修为 +%d\n" % _rewards["xp_bonus"]
	if _rewards.get("title") or "":
		reward_text += "🏅 称号：%s" % _rewards["title"]
	
	var reward_label = Label.new()
	reward_label.text = reward_text
	reward_label.add_theme_font_size_override("font_size", 15)
	reward_label.add_theme_color_override("font_color", Color("#88ff88"))
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(reward_label)

func _build_failure_ui(vbox: VBoxContainer) -> void:
	# 标题
	var title = Label.new()
	title.text = "💀 渡劫失败"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("#ff4444"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# 惩罚说明
	var punishment = VBoxContainer.new()
	punishment.add_theme_constant_override("separation", 4)
	
	var lines = [
		"☠️ 修为倒退至当前境界50%",
		"💔 道心受创（修炼效率-30%，持续24小时）",
		"💡 准备充足后再次尝试渡劫",
	]
	
	for line_text in lines:
		var l = Label.new()
		l.text = line_text
		l.add_theme_font_size_override("font_size", 15)
		l.add_theme_color_override("font_color", Color("#cccccc"))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		punishment.add_child(l)
	
	vbox.add_child(punishment)

# ==================== 入场动画 ====================

func _play_entry_animation() -> void:
	var bg = get_node("Bg")
	var panel = get_node("Panel")
	
	if not bg or not panel: 
		return
	
	# 背景渐暗
	var t1 = create_tween()
	t1.tween_property(bg, "color", Color(0, 0, 0, 0.7), 0.5)
	
	# 面板弹入
	var t2 = create_tween()
	t2.set_parallel(true)
	t2.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.4)
	t2.tween_property(panel, "scale", Vector2(1, 1), 0.5).from(Vector2(0.8, 0.8)).set_trans(Tween.TRANS_ELASTIC)
	
	await t1.finished

func _on_confirm() -> void:
	"""点击确认按钮"""
	# 淡出动画
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.4)
	await tween.finished
	
	result_dismissed.emit(_success)

# ==================== 工具 ====================

func _get_score_color(score: float) -> Color:
	if score >= 90: return Color("#ffd700")
	if score >= 60: return Color("#44ccaa")
	if score >= 30: return Color("#88aacc")
	return Color("#aa4444")
