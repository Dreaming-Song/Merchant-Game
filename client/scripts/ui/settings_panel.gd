extends Control
## 设置面板 — 可调节的条目列表
##
## 通过 UIManager 打开（暂停菜单 → 设置）
## 所有修改实时生效，关闭时自动保存

class_name SettingsPanel

signal back_pressed()

# ==================== 设置控件引用 ====================

func _ready() -> void:
	_build_ui()
	_load_current_values()

func _build_ui() -> void:
	# 清空自身
	for child in get_children():
		child.queue_free()
	
	# 整体布局
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	# 标题
	var title = Label.new()
	title.text = "⚙️ 设置"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# 分割线
	vbox.add_child(_make_separator())
	
	# ---- 鼠标灵敏度 ----
	vbox.add_child(_make_slider_row("鼠标灵敏度", "mouse_sensitivity", 0.0005, 0.01, 0.0001))
	
	# ---- 音量 ----
	vbox.add_child(_make_section_label("音量"))
	vbox.add_child(_make_slider_row("主音量", "master_volume", 0, 100, 1))
	vbox.add_child(_make_slider_row("音效", "sfx_volume", 0, 100, 1))
	vbox.add_child(_make_slider_row("音乐", "music_volume", 0, 100, 1))
	
	# ---- 显示 ----
	vbox.add_child(_make_section_label("显示"))
	vbox.add_child(_make_check_row("全屏模式", "fullscreen"))
	vbox.add_child(_make_check_row("显示交互提示", "show_hint"))
	
	# 弹性空间
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	# ---- 底部按钮 ----
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	
	var reset_btn = Button.new()
	reset_btn.text = "🔄 恢复默认"
	reset_btn.pressed.connect(_on_reset_defaults)
	reset_btn.custom_minimum_size = Vector2(180, 48)
	btn_hbox.add_child(reset_btn)
	
	var back_btn = Button.new()
	back_btn.text = "⬅ 返回"
	back_btn.pressed.connect(_on_back)
	back_btn.custom_minimum_size = Vector2(180, 48)
	btn_hbox.add_child(back_btn)
	
	vbox.add_child(btn_hbox)

# ==================== UI 构建工具 ====================

func _make_separator() -> HSeparator:
	var sep = HSeparator.new()
	sep.custom_minimum_size = Vector2(0, 4)
	return sep

func _make_section_label(text: String) -> Label:
	var label = Label.new()
	label.text = "── " + text + " ──"
	label.add_theme_font_size_override("font_size", 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	return label

func _make_slider_row(label_text: String, key: String, min_val: float, max_val: float, step: float) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(120, 36)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(label)
	
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(200, 36)
	slider.set_meta("setting_key", key)
	slider.drag_ended.connect(_on_slider_changed.bind(slider))
	hbox.add_child(slider)
	
	var value_label = Label.new()
	value_label.custom_minimum_size = Vector2(60, 36)
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.set_meta("setting_key", key)
	value_label.set_meta("is_value_label", true)
	hbox.add_child(value_label)
	
	return hbox

func _make_check_row(label_text: String, key: String) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var check = CheckBox.new()
	check.text = " " + label_text
	check.set_meta("setting_key", key)
	check.toggled.connect(_on_check_toggled.bind(check))
	check.custom_minimum_size = Vector2(0, 40)
	hbox.add_child(check)
	
	return hbox

# ==================== 回调 ====================

func _on_slider_changed(_value_changed: bool, slider: HSlider) -> void:
	if not _value_changed:
		return
	var key: String = slider.get_meta("setting_key", "")
	if key.is_empty():
		return
	var val = slider.value
	var sm = get_node("/root/SettingsManager") if has_node("/root/SettingsManager") else null
	if sm and sm.has_method("set_setting"):
		sm.set_setting(key, val)
	_update_value_label(key, val)

func _on_check_toggled(button_pressed: bool, check: CheckBox) -> void:
	var key: String = check.get_meta("setting_key", "")
	if key.is_empty():
		return
	var sm = get_node("/root/SettingsManager") if has_node("/root/SettingsManager") else null
	if sm and sm.has_method("set_setting"):
		sm.set_setting(key, button_pressed)

func _on_reset_defaults() -> void:
	var sm = get_node("/root/SettingsManager") if has_node("/root/SettingsManager") else null
	if sm and sm.has_method("reset_to_defaults"):
		sm.reset_to_defaults()
	_load_current_values()

func _on_back() -> void:
	back_pressed.emit()

# ==================== 值同步 ====================

func _load_current_values() -> void:
	var sm = get_node("/root/SettingsManager") if has_node("/root/SettingsManager") else null
	if not sm:
		return
	
	# 遍历所有 slider
	for slider in _find_all_sliders(self):
		var key: String = slider.get_meta("setting_key", "")
		if key.is_empty():
			continue
		var val = sm.get_setting(key)
		if val != null:
			slider.value = val if val is float else float(val)
			_update_value_label(key, slider.value)
	
	# 遍历所有 checkbox
	for check in _find_all_checks(self):
		var key: String = check.get_meta("setting_key", "")
		if key.is_empty():
			continue
		var val = sm.get_setting(key)
		if val != null:
			check.button_pressed = val

func _update_value_label(key: String, value: float) -> void:
	if key == "mouse_sensitivity":
		_set_value_text(key, "%.1f" % (value * 1000))
	elif key in ["master_volume", "sfx_volume", "music_volume"]:
		_set_value_text(key, "%d%%" % value)

func _set_value_text(key: String, text: String) -> void:
	for child in _find_all_labels(self):
		if child.get_meta("is_value_label", false) and child.get_meta("setting_key", "") == key:
			child.text = text

# ==================== 递归查找 ====================

func _find_all_sliders(parent: Node) -> Array[HSlider]:
	var result: Array[HSlider] = []
	for child in parent.get_children():
		if child is HSlider:
			result.append(child)
		result.append_array(_find_all_sliders(child))
	return result

func _find_all_checks(parent: Node) -> Array[CheckBox]:
	var result: Array[CheckBox] = []
	for child in parent.get_children():
		if child is CheckBox:
			result.append(child)
		result.append_array(_find_all_checks(child))
	return result

func _find_all_labels(parent: Node) -> Array[Label]:
	var result: Array[Label] = []
	for child in parent.get_children():
		if child is Label:
			result.append(child)
		result.append_array(_find_all_labels(child))
	return result
