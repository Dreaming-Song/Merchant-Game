extends Control
## 表情轮盘 — 快速选择表情/动作
##
## 按 ` 键（反引号）或 B+左摇杆打开
## 鼠标指向/手柄摇杆选择

class_name EmoteWheel

signal emote_selected(emote_name: String)

var _is_open: bool = false
var _sectors: Array[Dictionary] = []

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_sectors()

func _build_sectors() -> void:
	_sectors = [
		{"name": "👋 挥手", "angle": 0},
		{"name": "🙏 作揖", "angle": 45},
		{"name": "💃 跳舞", "angle": 90},
		{"name": "⚔️ 挑衅", "angle": 135},
		{"name": "😄 大笑", "angle": 180},
		{"name": "😢 哭泣", "angle": 225},
		{"name": "🧘 打坐", "angle": 270},
		{"name": "👆 指路", "angle": 315},
	]

func open() -> void:
	_is_open = true
	visible = true

func close() -> void:
	_is_open = false
	visible = false

func _input(event: InputEvent) -> void:
	# 反引号/波浪号打开
	if event.is_action_pressed("ui_focus_next") or event.is_action_pressed("emote_wheel"):
		if not _is_open:
			open()
		else:
			close()
		get_viewport().set_input_as_handled()
	
	# ESC 关闭
	if event.is_action_pressed("ui_cancel") and _is_open:
		close()

func _process(delta: float) -> void:
	if not _is_open:
		return
	
	# 检测鼠标位置选择表情
	var mouse_pos = get_global_mouse_position()
	var center = get_viewport_rect().size / 2
	var dir = mouse_pos - center
	
	if dir.length() > 50:
		var angle = rad_to_deg(atan2(dir.y, dir.x))
		if angle < 0:
			angle += 360
		
		# 找到最接近的扇区
		var closest = _sectors[0]
		var min_diff = 999
		for s in _sectors:
			var diff = abs(angle - s.angle)
			if diff > 180:
				diff = 360 - diff
			if diff < min_diff:
				min_diff = diff
				closest = s
		
		# 显示当前选中的表情
		_selected = closest.name
	
	# 点击释放鼠标执行
	if Input.is_action_just_released("ui_click"):
		if _selected:
			emote_selected.emit(_selected)
		close()

var _selected: String = ""

func _draw() -> void:
	if not _is_open:
		return
	# 绘制轮盘背景
	var center = get_viewport_rect().size / 2
	draw_circle(center, 100, Color(0, 0, 0, 0.5))
	draw_circle(center, 40, Color(0.2, 0.2, 0.3, 0.8))
