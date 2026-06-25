extends Control

## 手柄布局参考面板
## 可从帮助菜单或按 Start 打开

var close_handler: Callable

func _ready() -> void:
	# 关闭按钮信号
	$CloseBtn.pressed.connect(_on_close)
	
	# 默认 ESC 或 B 键关闭
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
		close()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()

## 打开布局（可从其他面板调用）
func open(callback: Callable = Callable()) -> void:
	close_handler = callback
	show()
	mouse_filter = MOUSE_FILTER_STOP
	$CloseBtn.grab_focus()

## 关闭
func close() -> void:
	hide()
	mouse_filter = MOUSE_FILTER_IGNORE
	if close_handler.is_valid():
		close_handler.call()

func _on_close() -> void:
	close()
