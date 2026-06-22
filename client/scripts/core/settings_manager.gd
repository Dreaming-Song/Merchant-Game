extends Node
## 设置管理器 — 存储/读取用户设置，持久化到 user://settings.cfg
##
## 生命周期：
##   1. 启动时自动从文件加载
##   2. 运行时通过 signal 通知各系统
##   3. 关闭时自动保存

class_name SettingsManager

signal settings_changed(key: String, value)

# ==================== 默认设置 ====================
var data: Dictionary = {
	"mouse_sensitivity": 0.002,       # 鼠标灵敏度 0.0005~0.01
	"master_volume": 80,              # 主音量 0~100
	"sfx_volume": 80,                 # 音效音量 0~100
	"music_volume": 60,               # 音乐音量 0~100
	"fullscreen": false,              # 全屏
	"show_hint": true,                # 显示交互提示
}

var _config_path: String = "user://settings.cfg"

func _ready() -> void:
	load_settings()

func _exit_tree() -> void:
	save_settings()

# ==================== 设置项操作 ====================

func get_setting(key: String, default = null):
	return data.get(key, default)

func set_setting(key: String, value) -> void:
	if data.has(key) and data[key] != value:
		data[key] = value
		settings_changed.emit(key, value)
		_apply_setting(key, value)

func reset_to_defaults() -> void:
	var defaults = {
		"mouse_sensitivity": 0.002,
		"master_volume": 80,
		"sfx_volume": 80,
		"music_volume": 60,
		"fullscreen": false,
		"show_hint": true,
	}
	for key in defaults.keys():
		if data.has(key):
			set_setting(key, defaults[key])

func has_setting(key: String) -> bool:
	return data.has(key)

# ==================== 即时生效 ====================

func _apply_setting(key: String, value) -> void:
	match key:
		"mouse_sensitivity":
			# 由 PlayerController 在 _process 中读取
			pass
		"master_volume":
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 
				linear_to_db(value / 100.0))
		"sfx_volume":
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), 
				linear_to_db(value / 100.0))
		"music_volume":
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), 
				linear_to_db(value / 100.0))
		"fullscreen":
			if value:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# ==================== 持久化 ====================

func save_settings() -> void:
	var cfg = ConfigFile.new()
	for key in data.keys():
		cfg.set_value("settings", key, data[key])
	var err = cfg.save(_config_path)
	if err != OK:
		print("⚠️ 设置保存失败: ", err)
	else:
		print("💾 设置已保存")

func load_settings() -> void:
	var cfg = ConfigFile.new()
	var err = cfg.load(_config_path)
	if err != OK:
		print("ℹ️ 无设置文件，使用默认值")
		_apply_all_defaults()
		return
	
	for key in data.keys():
		if cfg.has_section_key("settings", key):
			data[key] = cfg.get_value("settings", key)
	
	_apply_all_defaults()
	print("📂 设置已加载")

func _apply_all_defaults() -> void:
	# 启动时应用所有当前值
	for key in data.keys():
		_apply_setting(key, data[key])
