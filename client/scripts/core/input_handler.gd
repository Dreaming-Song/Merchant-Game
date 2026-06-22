extends Node
## 统一输入处理器 — 自动检测设备，提供跨平台输入接口
##
## 输入模式自动切换：
##   KEYBOARD — 键鼠模式（显示键盘提示文字）
##   GAMEPAD — 手柄模式（显示手柄按键图标）
##   TOUCH — 触屏模式（显示虚拟按键/手势）

class_name InputHandler

enum InputMode { KEYBOARD, GAMEPAD, TOUCH }

signal input_mode_changed(mode: int)

var current_mode: int = InputMode.KEYBOARD

func _ready() -> void:
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		current_mode = InputMode.TOUCH
		input_mode_changed.emit(current_mode)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_change_mode(InputMode.KEYBOARD)
	elif event is InputEventJoypadButton and event.pressed:
		_change_mode(InputMode.GAMEPAD)
	elif event is InputEventJoypadMotion and abs(event.axis_value) > 0.3:
		_change_mode(InputMode.GAMEPAD)
	elif event is InputEventScreenTouch:
		_change_mode(InputMode.TOUCH)
	elif event is InputEventScreenDrag:
		_change_mode(InputMode.TOUCH)

func _change_mode(mode: int) -> void:
	if mode != current_mode:
		var old = current_mode
		current_mode = mode
		input_mode_changed.emit(mode)
		print("🖥️ 输入模式: %s → %s" % [_mode_name(old), _mode_name(mode)])

func _mode_name(mode: int) -> String:
	match mode:
		InputMode.KEYBOARD: return "键盘鼠标"
		InputMode.GAMEPAD: return "手柄"
		InputMode.TOUCH: return "触屏"
	return "未知"

## 获取移动轴（键盘 WASD / 手柄左摇杆 / 触控）
func get_movement_vector() -> Vector2:
	match current_mode:
		InputMode.TOUCH:
			return Vector2.ZERO  # 触控由虚拟摇杆处理
		InputMode.GAMEPAD:
			var stick = Vector2(
				Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
				Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
			)
			if stick.length() > 0.15:
				return stick.normalized()
			return Vector2.ZERO
		_:
			return Input.get_vector("move_left", "move_right", "move_forward", "move_back")

## 获取视角轴（右摇杆）
func get_look_vector() -> Vector2:
	match current_mode:
		InputMode.GAMEPAD:
			return Vector2(
				Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
				Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
			)
		_:
			return Vector2.ZERO

func is_touch_mode() -> bool:
	return current_mode == InputMode.TOUCH

func is_gamepad_mode() -> bool:
	return current_mode == InputMode.GAMEPAD

func get_action_hint(action: String) -> String:
	match current_mode:
		InputMode.KEYBOARD:
			match action:
				"interact": return "E"
				"jump": return "空格"
				"sprint": return "Shift"
				"sword_fly": return "F"
				"attack": return "鼠标左键"
				_: return action
		InputMode.GAMEPAD:
			match action:
				"interact": return "A"
				"jump": return "X"
				"sprint": return "左摇杆按下"
				"sword_fly": return "Y"
				"attack": return "RB"
				_: return action
		_: return "👆"
