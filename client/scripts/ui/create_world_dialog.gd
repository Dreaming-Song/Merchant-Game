extends AcceptDialog
## 创建新世界弹窗
##
## 输入：世界名称、种子（可选）、游戏模式

class_name CreateWorldDialog

signal world_created(name: String, seed: int)

var _name_input: LineEdit
var _seed_input: LineEdit
var _mode_option: OptionButton
var _random_seed: bool = true

func _ready() -> void:
	title = "✨ 创建新世界"
	ok_button_text = "创世"
	cancel_button_text = "取消"
	
	# 自定义内容
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	
	# 世界名称
	vbox.add_child(Label.new())
	var name_label = Label.new()
	name_label.text = "世界名称"
	vbox.add_child(name_label)
	_name_input = LineEdit.new()
	_name_input.placeholder_text = "输入世界名称..."
	_name_input.text = _generate_default_name()
	vbox.add_child(_name_input)
	
	# 种子
	var seed_label = Label.new()
	seed_label.text = "世界种子（留空随机）"
	vbox.add_child(seed_label)
	var seed_hbox = HBoxContainer.new()
	_seed_input = LineEdit.new()
	_seed_input.placeholder_text = "随机生成..."
	_seed_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_hbox.add_child(_seed_input)
	var random_btn = Button.new()
	random_btn.text = "🎲"
	random_btn.custom_minimum_size = Vector2(36, 0)
	random_btn.pressed.connect(_on_random_seed)
	seed_hbox.add_child(random_btn)
	vbox.add_child(seed_hbox)
	
	# 游戏模式
	var mode_label = Label.new()
	mode_label.text = "游戏模式"
	vbox.add_child(mode_label)
	_mode_option = OptionButton.new()
	_mode_option.add_item("🟢 生存模式", 0)
	_mode_option.add_item("🟡 创造模式", 1)
	_mode_option.add_item("🔴 硬核模式", 2)
	_mode_option.select(0)
	vbox.add_child(_mode_option)
	
	add_child(vbox)
	
	# 确认时触发
	confirmed.connect(_on_confirmed)
	_name_input.text_changed.connect(_validate)

func _generate_default_name() -> String:
	var names = ["灵境大陆", "万仙界", "灵药谷", "青云山", "碧波潭", "星辰海", "天机城", "紫霄宫"]
	return names[randi() % names.size()]

func _on_random_seed() -> void:
	_seed_input.text = str(randi_range(0, 99999999))

func _validate(new_text: String) -> void:
	ok_button_disabled = new_text.strip_edges().is_empty()

func _on_confirmed() -> void:
	var name = _name_input.text.strip_edges()
	var seed = 0
	if _seed_input.text.strip_edges().is_empty():
		seed = randi()
	else:
		seed = _seed_input.text.strip_edges().hash()
	
	var modes = ["survival", "creative", "hardcore"]
	var mode = modes[_mode_option.selected]
	
	if not name.is_empty():
		world_created.emit(name, seed)
