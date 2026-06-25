extends Control
## 📢 世界事件公告栏 — 屏幕顶部横向飘入通知
##
## 展示：事件名称 + 描述 + 倒计时
## 风格：修仙古风横幅，淡入淡出

class_name EventBanner

signal banner_closed(event_id: String)

var _banners: Array[Dictionary] = []  # {node, event_id, timer, remaining}
var _banner_scene: PackedScene = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_top = 0.05
	anchor_bottom = 0.0
	anchor_left = 0.0
	anchor_right = 1.0
	offset_top = 0
	offset_bottom = 80

func show_event(event_type: int, title: String, description: String, duration: float) -> void:
	"""显示事件公告横幅"""
	var banner = _create_banner(event_type, title, description, duration)
	add_child(banner.node)
	_banners.append(banner)
	
	# 弹出动画
	banner.node.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(banner.node, "modulate", Color(1, 1, 1, 1), 0.4).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(banner.node, "position:y", 0, 0.4).set_trans(Tween.TRANS_BACK)
	
	# 自动消失
	var auto_hide = create_tween()
	auto_hide.tween_interval(duration)
	auto_hide.tween_callback(func():
		if _banners.has(banner):
			_hide_banner(banner)
	)

func _create_banner(event_type: int, title: String, description: String, duration: float) -> Dictionary:
	"""创建单条公告节点"""
	var node = Control.new()
	node.name = "EventBanner_%d" % Time.get_ticks_msec()
	node.custom_minimum_size = Vector2(400, 60)
	node.position = Vector2(0, -60)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 水平居中容器
	var hbox = HBoxContainer.new()
	hbox.anchors_preset = Control.PRESET_HCENTER_WIDE
	hbox.add_theme_constant_override("separation", 8)
	
	# 背景框
	var bg = ColorRect.new()
	bg.color = _get_event_color(event_type, 0.75)
	bg.custom_minimum_size = Vector2(360, 52)
	bg.size = Vector2(360, 52)
	var style = StyleBoxFlat.new()
	style.bg_color = _get_event_color(event_type, 0.75)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.set_border_width_all(1)
	style.border_color = _get_event_color(event_type, 1.0)
	node.add_child(bg)
	
	# 装饰边框
	var border = ColorRect.new()
	border.color = _get_event_color(event_type, 0.9)
	border.custom_minimum_size = Vector2(360, 2)
	border.size = Vector2(360, 2)
	border.position = Vector2(0, 50)
	node.add_child(border)
	
	# 图标
	var icon_label = Label.new()
	icon_label.text = _get_event_icon(event_type)
	icon_label.add_theme_font_size_override("font_size", 24)
	icon_label.position = Vector2(8, 8)
	node.add_child(icon_label)
	
	# 标题
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	title_label.position = Vector2(44, 6)
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	node.add_child(title_label)
	
	# 描述
	var desc_label = Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	desc_label.position = Vector2(44, 28)
	node.add_child(desc_label)
	
	# 倒计时
	var timer_label = Label.new()
	timer_label.text = _format_time(duration)
	timer_label.add_theme_font_size_override("font_size", 11)
	timer_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 0.8))
	timer_label.position = Vector2(300, 6)
	node.add_child(timer_label)
	
	# 居中
	node.position = Vector2(
		(get_viewport().size.x - 360) / 2.0,
		-60
	)
	
	return {
		"node": node,
		"event_type": event_type,
		"timer_label": timer_label,
		"remaining": duration,
		"decay_timer": 0.0,
	}

func _hide_banner(banner: Dictionary) -> void:
	"""隐藏并移除公告"""
	if not is_instance_valid(banner.node):
		_banners.erase(banner)
		return
	
	var tween = create_tween()
	tween.tween_property(banner.node, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(func():
		if is_instance_valid(banner.node):
			banner.node.queue_free()
		_banners.erase(banner)
	)

func _process(delta: float) -> void:
	"""更新所有倒计时"""
	for banner in _banners:
		if not is_instance_valid(banner.node):
			continue
		banner.remaining -= delta
		var tl = banner.get("timer_label")
		if tl and is_instance_valid(tl):
			if banner.remaining > 0:
				tl.text = _format_time(banner.remaining)
			else:
				tl.text = "即将结束…"

func _get_event_color(event_type: int, alpha: float = 1.0) -> Color:
	match event_type:
		0: return Color(1.0, 0.3, 0.2, alpha)   # 兽潮 - 红
		1: return Color(0.6, 0.3, 1.0, alpha)   # 秘境 - 紫
		2: return Color(1.0, 0.8, 0.2, alpha)   # 宝箱 - 金
		3: return Color(0.3, 0.6, 1.0, alpha)   # 流星 - 蓝
		4: return Color(0.2, 0.8, 0.8, alpha)   # 灵泉 - 青
		_: return Color(0.5, 0.5, 0.5, alpha)

func _get_event_icon(event_type: int) -> String:
	match event_type:
		0: return "🌊"
		1: return "🔮"
		2: return "🎁"
		3: return "☄️"
		4: return "💧"
		_: return "📢"

func _format_time(seconds: float) -> String:
	var s = int(seconds)
	var m = s / 60
	var sec = s % 60
	return "%d:%02d" % [m, sec]
