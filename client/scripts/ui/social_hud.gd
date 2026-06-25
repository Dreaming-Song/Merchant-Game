extends Control
## 👥 社交 HUD — 附近玩家提示
##
## 当有其他玩家靠近时，自动在屏幕边缘显示其信息
## 显示：名字、等级、距离、状态（空手/牵手/战斗中）

class_name SocialHUD

signal player_interact_requested(player_id: String)

var _player_labels: Dictionary = {}  # player_id → Label
var _spawner: Node = null
var _local_player: Node = null
var _handhold: Node = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spawner = get_node("/root/PlayerSpawner") if has_node("/root/PlayerSpawner") else null
	_local_player = get_tree().get_first_node_in_group("player")
	_handhold = get_node("/root/HandHoldManager") if has_node("/root/HandHoldManager") else null

func _process(_delta: float) -> void:
	if not _spawner or not _local_player:
		return
	
	# 获取所有远程玩家
	var remote_players = []
	if _spawner.has_method("get_player_list"):
		remote_players = _spawner.get_player_list()
	
	# 检查每个玩家的距离
	var current_ids = []
	for p in remote_players:
		var pid = str(p.get("player_id") or "")
		if pid.is_empty():
			continue
		current_ids.append(pid)
		
		var dist = p.get("distance") or 999
		if dist > 15.0:
			_remove_label(pid)
			continue
		
		_update_label(pid, p, dist)
	
	# 清理已离开的标签
	for pid in _player_labels.keys():
		if not pid in current_ids:
			_remove_label(pid)

func _update_label(player_id: String, data: Dictionary, dist: float) -> void:
	"""创建或更新玩家标签"""
	var label = _player_labels.get(player_id)
	if not label:
		label = _make_label()
		label.name = "PlayerLabel_%s" % player_id
		add_child(label)
		_player_labels[player_id] = label
	
	# 位置：从3D世界坐标映射到屏幕
	var player_node = _get_player_node(player_id)
	var screen_pos = Vector2.ZERO
	if player_node:
		var camera = get_viewport().get_camera_3d()
		if camera:
			screen_pos = camera.unproject_position(player_node.global_position + Vector3(0, 2.5, 0))
	
	# 如果不在屏幕内，放在屏幕边缘
	var screen_size = get_viewport().get_visible_rect().size
	if screen_pos.x < 0 or screen_pos.x > screen_size.x or screen_pos.y < 0 or screen_pos.y > screen_size.y or dist > 10:
		# 屏幕外 → 边缘箭头
		screen_pos.x = clamp(screen_pos.x, 20, screen_size.x - 20)
		screen_pos.y = clamp(screen_pos.y, 20, screen_size.y - 20)
		label.modulate = Color(0.5, 0.5, 0.5, 0.5)
	else:
		label.modulate = Color(1, 1, 1, 1)
	
	label.position = screen_pos - Vector2(50, 0)
	
	# 文字内容
	var name = data.get("player_name") or "道友"
	var rank = data.get("realm_name") or "凡人"
	var status = ""
	if _handhold:
		if _handhold.my_leader_id == player_id:
			status = "🤝 牵着"
		elif _handhold.my_follower_ids.has(player_id):
			status = "🤝 被牵"
	
	var dist_text = ""
	if dist < 3: dist_text = " 很近"
	elif dist < 7: dist_text = " 较近"
	else: dist_text = ""
	
	label.text = "%s\n[color=#8888ff]%s[/color] %s%s" % [name, rank, dist_text, status]

func _make_label() -> RichTextLabel:
	"""创建一个玩家标签"""
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("normal_font_size", 12)
	label.add_theme_color_override("default_color", Color(1, 1, 1, 0.9))
	label.add_theme_constant_override("line_separation", 1)
	label.custom_minimum_size = Vector2(120, 30)
	return label

func _remove_label(player_id: String) -> void:
	var label = _player_labels.get(player_id)
	if label and is_instance_valid(label):
		label.queue_free()
	_player_labels.erase(player_id)

func _get_player_node(player_id: String) -> Node3D:
	if _spawner and _spawner.has_method("get_player_node"):
		return _spawner.get_player_node(player_id)
	return null
