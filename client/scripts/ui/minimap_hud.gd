extends Control
## 迷雾地图 HUD — 在游戏画面右上角显示迷你地图

class_name MinimapHUD

signal fullscreen_map_toggled()

# 类型预加载
const _MinimapType = preload("res://scripts/ui/minimap.gd")

var _minimap: _MinimapType = null
var _map_rect: TextureRect = null
var _player_marker: TextureRect = null
var _fog_rect: TextureRect = null

func _ready() -> void:
	# 创建 minimap 逻辑
	_minimap = _MinimapType.new()
	_minimap.name = "MinimapLogic"
	add_child(_minimap)
	
	# 创建 UI 容器（右上角）
	var margin = MarginContainer.new()
	margin.name = "MapContainer"
	margin.anchors_preset = Control.PRESET_TOP_RIGHT
	margin.offset_left = -220
	margin.offset_top = 10
	margin.offset_right = -10
	margin.offset_bottom = 210
	add_child(margin)
	
	# 地图边框
	var panel = Panel.new()
	panel.add_theme_stylebox_override("panel", _make_map_style())
	margin.add_child(panel)
	
	var map_vbox = VBoxContainer.new()
	map_vbox.add_theme_constant_override("separation", 2)
	panel.add_child(map_vbox)
	
	# 地图标题
	var title = Label.new()
	title.text = "🗺️ 小地图"
	title.add_theme_font_size_override("font_size", 11)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 0.8))
	map_vbox.add_child(title)
	
	# 地图纹理容器
	var map_container = CenterContainer.new()
	map_container.custom_minimum_size = Vector2(200, 200)
	map_vbox.add_child(map_container)
	
	# 迷雾纹理（上层）
	_fog_rect = TextureRect.new()
	_fog_rect.stretch_mode = TextureRect.STRETCH_KEEP
	_fog_rect.texture = _minimap.get_fog_texture() if _minimap else null
	map_container.add_child(_fog_rect)
	
	# 玩家标记
	_player_marker = TextureRect.new()
	_player_marker.custom_minimum_size = Vector2(8, 8)
	_player_marker.modulate = Color(1, 0.8, 0.2)
	map_container.add_child(_player_marker)
	
	# 按键提示
	var hint = Label.new()
	hint.text = "M 放大地图"
	hint.add_theme_font_size_override("font_size", 9)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))
	map_vbox.add_child(hint)

func _make_map_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.7)
	style.set_border_width_all(2)
	style.border_color = Color(0.3, 0.4, 0.5, 0.5)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

func _process(delta: float) -> void:
	if not _minimap:
		return
	
	# 获取玩家位置
	var player = get_tree().get_first_node_in_group("player")
	if player:
		_minimap.update_player_position(player.global_position)
		
		# 更新玩家标记位置
		var map_pos = _minimap.get_player_map_pos()
		_player_marker.position = map_pos - Vector2(4, 4)
	
	# 更新迷雾纹理
	if _fog_rect and _minimap:
		_fog_rect.texture = _minimap.get_fog_texture()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_map") and not event.is_echo():
		fullscreen_map_toggled.emit()
