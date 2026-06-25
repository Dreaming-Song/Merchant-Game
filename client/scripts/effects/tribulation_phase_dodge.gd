extends Node
## ⚡ 雷劫·第一阶段：天雷闪避
##
## 玩法：地面出现预兆光圈 → 1秒后天雷劈下
## 玩家必须在预警时间内走出光圈范围
## 成功躲开 +分，被劈中扣血 -分
##
## 难度递增：
##   波次越多，同时落雷越多，预警时间越短
##   追踪雷：会预判玩家移动方向

class_name TribulationPhaseDodge

signal phase_completed(score: float)
signal phase_failed(reason: String)

# ==================== 配置 ====================
var _manager: Node = null
var _player: Node = null
var _config: Dictionary = {}

# ==================== 状态 ====================
var _current_wave: int = 0
var _total_waves: int = 3
var _max_strikes: int = 2
var _warning_time: float = 1.5
var _base_damage: int = 30
var _score: float = 100.0  # 100分起步，被劈中扣分
var _successful_dodges: int = 0
var _total_strikes: int = 0
var _is_running: bool = false

# ==================== 世界特效 ====================
var _strike_markers: Array[Node3D] = []  # 3D光圈标记
var _world_root: Node3D = null

# ==================== 2D HUD ====================
var _warning_label: Label = null
var _wave_label: Label = null
var _score_label: Label = null
var _center_hint: Label = null

func _init(manager: Node, player: Node, config: Dictionary) -> void:
	_manager = manager
	_player = player
	_config = config
	_total_waves = config.get("waves") or 3
	_max_strikes = config.get("max_strikes") or 2
	_warning_time = config.get("warning_time") or 1.2
	_base_damage = config.get("base_damage") or 30
	name = "PhaseDodge"

func _ready() -> void:
	# 找世界根节点（用于创建3D特效）
	_world_root = get_tree().get_first_node_in_group("world_root")
	if not _world_root:
		_world_root = get_tree().current_scene

func start() -> void:
	"""开始天雷闪避阶段"""
	_is_running = true
	_create_hud()
	_show_phase_intro()
	
	# 短暂延迟后开始第一波
	await get_tree().create_timer(2.0).timeout
	if _is_running:
		_start_next_wave()

# ==================== 波次逻辑 ====================

func _start_next_wave() -> void:
	"""开始新一波落雷"""
	if not _is_running:
		return
	
	_current_wave += 1
	
	if _current_wave > _total_waves:
		_complete_phase()
		return
	
	# 更新波次显示
	if _wave_label:
		_wave_label.text = "第 %d / %d 波" % [_current_wave, _total_waves]
	
	if _center_hint:
		_center_hint.text = "⚡ 注意地面光圈！"
		_center_hint.modulate = Color(1, 1, 0.3, 1)
		var tween = create_tween()
		tween.tween_property(_center_hint, "modulate", Color(1, 1, 0.3, 0), 1.5)
	
	# 这一波生成几个落雷点
	var strike_count = mini(_current_wave, _max_strikes)
	if strike_count < 1:
		strike_count = 1
	
	# 有追踪雷吗？（后面波次会出现）
	var has_tracking = _current_wave > _total_waves * 0.5
	
	_total_strikes += strike_count
	
	# 并行生成所有落雷预兆
	for i in range(strike_count):
		var is_tracking = has_tracking and (i == 0)  # 第一道是追踪雷
		_spawn_lightning_strike(is_tracking)
		await get_tree().create_timer(0.15).timeout  # 错开生成时间
	
	# 等待这一波所有落雷完成 = 预警时间 + 0.5秒
	var wave_duration = _warning_time + 0.8
	await get_tree().create_timer(wave_duration).timeout
	
	# 如果这一波没结束（玩家还活着），进入下一波
	# 波次间隔
	await get_tree().create_timer(1.0).timeout
	
	if _is_running:
		_start_next_wave()

# ==================== 生成落雷 ====================

func _spawn_lightning_strike(tracking: bool = false) -> void:
	"""生成一道落雷的完整流程（预兆→劈下→结算）"""
	# ---- 1. 计算落雷位置 ----
	var target_pos = _get_strike_position(tracking)
	
	# ---- 2. 创建预兆光圈（3D地面特效） ----
	var marker = _create_strike_marker(target_pos, tracking)
	if marker:
		_strike_markers.append(marker)
	
	# ---- 3. 预警倒计时 ----
	await get_tree().create_timer(_warning_time).timeout
	
	# 如果玩家已被之前的雷劈死，就不继续了
	if not _is_running:
		return
	
	# ---- 4. 劈下闪电！ ----
	_strike_lightning(target_pos, marker, tracking)

func _get_strike_position(tracking: bool) -> Vector3:
	"""计算落雷位置"""
	var player_pos = _player.global_position if _player and is_instance_valid(_player) else Vector3.ZERO
	
	if tracking and _player:
		# 追踪雷：预判玩家移动方向
		var velocity = _player.get("velocity") or Vector3.ZERO if _player.has("velocity") else Vector3.ZERO
		var look_dir = velocity.normalized()
		var predict_distance = velocity.length() * _warning_time * 0.8  # 预判走位距离
		
		# 80%概率预判玩家前方，20%概率预判后方（增加变数）
		if randf() < 0.2:
			predict_distance = -predict_distance * 0.5
		
		return player_pos + look_dir * predict_distance + Vector3(
			randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5)
		)
	else:
		# 普通雷：在玩家周围随机
		var angle = randf() * TAU
		var dist = randf_range(2.0, 8.0)
		return player_pos + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

func _create_strike_marker(pos: Vector3, tracking: bool) -> Node3D:
	"""在地面创建落雷预兆光圈"""
	if not _world_root:
		return null
	
	# 光圈Mesh（渐变圆环）
	var marker = Node3D.new()
	marker.name = "StrikeMarker_%d" % _strike_markers.size()
	marker.global_position = Vector3(pos.x, 0.05, pos.z)
	marker.set_meta("tracking", tracking)
	
	# 外圈（红色预警）
	var outer_ring = MeshInstance3D.new()
	var ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = 1.0
	ring_mesh.outer_radius = 1.3
	ring_mesh.ring_count = 24
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.1, 0.0, 0.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.2, 0.0) * 0.8
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.alpha = 0.6
	
	outer_ring.mesh = ring_mesh
	outer_ring.material_override = mat
	outer_ring.rotation.x = deg_to_rad(90)
	marker.add_child(outer_ring)
	
	# 内圈（白色高亮，闪烁）
	var inner_ring = MeshInstance3D.new()
	var inner_mesh = TorusMesh.new()
	inner_mesh.inner_radius = 0.3
	inner_mesh.outer_radius = 0.6
	inner_mesh.ring_count = 16
	
	var inner_mat = StandardMaterial3D.new()
	inner_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.0)
	inner_mat.emission_enabled = true
	inner_mat.emission = Color(1.0, 1.0, 0.5) * 0.5
	inner_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	inner_mat.alpha = 0.3
	
	inner_ring.mesh = inner_mesh
	inner_ring.material_override = inner_mat
	inner_ring.rotation.x = deg_to_rad(90)
	marker.add_child(inner_ring)
	
	if tracking:
		# 追踪雷额外标记：更强的红光
		mat.emission = Color(1.0, 0.0, 0.0) * 1.2
		mat.alpha = 0.9
		
		# 加一个向上的红色光柱提示
		var pillar = CylinderMesh.new()
		pillar.top_radius = 0.05
		pillar.bottom_radius = 0.3
		pillar.height = 3.0
		
		var pillar_mat = StandardMaterial3D.new()
		pillar_mat.albedo_color = Color(1.0, 0.0, 0.0, 0.0)
		pillar_mat.emission_enabled = true
		pillar_mat.emission = Color(1.0, 0.0, 0.0) * 0.3
		pillar_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pillar_mat.alpha = 0.15
		
		var pillar_mesh = MeshInstance3D.new()
		pillar_mesh.mesh = pillar
		pillar_mesh.material_override = pillar_mat
		pillar_mesh.position.y = 1.5
		marker.add_child(pillar_mesh)
	
	# 光圈动画：逐渐放大+闪烁（预警效果）
	var tween = create_tween()
	tween.tween_method(func(v): 
		if is_instance_valid(outer_ring) and outer_ring.material_override:
			var m = outer_ring.material_override
			m.emission_energy_multiplier = v
			m.alpha = 0.3 + v * 0.7
		# 内圈闪烁
		if is_instance_valid(inner_ring) and inner_ring.material_override:
			var im = inner_ring.material_override
			im.alpha = 0.15 + v * 0.5
	, 0.3, 1.0, _warning_time * 0.8).set_ease(Tween.EASE_IN)
	
	_world_root.add_child(marker)
	return marker

func _strike_lightning(pos: Vector3, marker: Node3D, tracking: bool) -> void:
	"""落雷击中 + 伤害判定"""
	if not _player or not is_instance_valid(_player):
		_clear_marker(marker)
		return
	
	# ---- 闪电特效 ----
	_spawn_lightning_effect(pos)
	
	# ---- 屏幕震动 ----
	_trigger_screen_shake()
	
	# ---- 判定玩家是否在范围内 ----
	var player_pos = _player.global_position
	var dist = Vector2(player_pos.x - pos.x, player_pos.z - pos.z).length()
	
	# 命中范围 = 1.5单位
	var hit_radius = 1.5 if not tracking else 2.0  # 追踪雷范围更大
	var is_hit = dist <= hit_radius
	
	if is_hit:
		# 🔴 被击中！
		_successful_dodges = max(0, _successful_dodges - 1)  # 失败的"闪避"
		_score = max(0, _score - 10.0)
		
		# 扣血
		if _player.has_method("take_damage"):
			var damage = int(_base_damage * (1.2 if tracking else 1.0))
			_player.take_damage(damage, null)
		
		# 显示伤害
		if _center_hint:
			_center_hint.text = "💥 被雷劈中！ -%dHP" % int(_base_damage * (1.2 if tracking else 1.0))
			_center_hint.modulate = Color(1, 0.2, 0.2, 1)
			var tween = create_tween()
			tween.tween_property(_center_hint, "modulate", Color(1, 0.2, 0.2, 0), 1.0)
		
		print("💥 雷劫: 玩家被劈中! 距离=%.1f" % dist)
	else:
		# 🟢 成功躲开！
		_successful_dodges += 1
		_score = mini(100, _score + 5.0)
		
		if dist < 3.0 and _center_hint:
			_center_hint.text = "⚡ 惊险躲开！"
			_center_hint.modulate = Color(0.3, 1, 0.3, 1)
			var tween = create_tween()
			tween.tween_property(_center_hint, "modulate", Color(0.3, 1, 0.3, 0), 0.8)
	
	# 更新分数显示
	if _score_label:
		_score_label.text = "渡劫进度: %d%%" % int(_score)
	
	# 检查玩家是否死亡
	if _player and _player.has_method("is_dead") and _player.is_dead():
		_is_running = false
		phase_failed.emit("被天雷击倒")
		return
	
	# 清理光圈标记
	_clear_marker(marker)

# ==================== 视觉特效 ====================

func _spawn_lightning_effect(pos: Vector3) -> void:
	"""闪电击中地面特效"""
	if not _world_root:
		return
	
	# 闪电光柱
	var bolt = MeshInstance3D.new()
	var bolt_mesh = CylinderMesh.new()
	bolt_mesh.top_radius = 0.3
	bolt_mesh.bottom_radius = 0.1
	bolt_mesh.height = 10.0
	
	var bolt_mat = StandardMaterial3D.new()
	bolt_mat.albedo_color = Color(1.0, 1.0, 1.0)
	bolt_mat.emission_enabled = true
	bolt_mat.emission = Color(1.0, 1.0, 0.8) * 2.0
	bolt_mat.emission_energy_multiplier = 2.0
	
	bolt.mesh = bolt_mesh
	bolt.material_override = bolt_mat
	bolt.global_position = Vector3(pos.x, 5.0, pos.z)
	_world_root.add_child(bolt)
	
	# 地面焦痕（圆盘）
	var scorch = MeshInstance3D.new()
	var scorch_mesh = CylinderMesh.new()
	scorch_mesh.top_radius = 0.8
	scorch_mesh.bottom_radius = 1.2
	scorch_mesh.height = 0.05
	
	var scorch_mat = StandardMaterial3D.new()
	scorch_mat.albedo_color = Color(0.15, 0.05, 0.0, 0.8)
	scorch_mat.emission_enabled = true
	scorch_mat.emission = Color(0.3, 0.1, 0.0) * 0.5
	
	scorch.mesh = scorch_mesh
	scorch.material_override = scorch_mat
	scorch.global_position = Vector3(pos.x, 0.02, pos.z)
	_world_root.add_child(scorch)
	
	# 闪电消失动画
	var tween = create_tween()
	tween.tween_method(func(v):
		if is_instance_valid(bolt):
			bolt.scale = Vector3(1, 1, 1) * v
			if bolt.material_override:
				bolt.material_override.emission_energy_multiplier = v * 3.0
		if is_instance_valid(scorch):
			scorch.modulate = Color(1, 1, 1, v * 0.8)
	, 1.0, 0.0, 0.3).set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(func():
		if is_instance_valid(bolt): bolt.queue_free()
	)
	
	# 焦痕5秒后消失
	var tween2 = create_tween()
	tween2.tween_interval(5.0)
	tween2.tween_method(func(v):
		if is_instance_valid(scorch):
			scorch.modulate = Color(1, 1, 1, v)
	, 0.8, 0.0, 1.0)
	tween2.tween_callback(func():
		if is_instance_valid(scorch): scorch.queue_free()
	)

func _trigger_screen_shake() -> void:
	"""触发屏幕震动"""
	# 尝试多种震动方式
	var camera = get_tree().get_first_node_in_group("camera")
	if camera and camera.has_method("shake"):
		camera.shake(0.3, 15.0)
	
	# HUD震动
	if _manager and _manager.has_node("TribulationHUD"):
		var hud = _manager.get_node("TribulationHUD")
		if hud and hud.has_method("shake"):
			hud.shake()

# ==================== HUD ====================

func _create_hud() -> void:
	"""创建阶段HUD（如果主HUD没有创建的话）"""
	# 提示标签放在Manager里
	if not _manager:
		return
	
	# 波次标签
	_wave_label = Label.new()
	_wave_label.name = "WaveLabel"
	_wave_label.text = "准备..."
	_wave_label.add_theme_font_size_override("font_size", 20)
	_wave_label.add_theme_color_override("font_color", Color("#ffcc44"))
	_wave_label.anchors_preset = Control.PRESET_TOP_WIDE
	_wave_label.offset_top = 80
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_manager.add_child(_wave_label)
	
	# 分数/进度标签
	_score_label = Label.new()
	_score_label.name = "ScoreLabel"
	_score_label.text = "渡劫进度: 100%"
	_score_label.add_theme_font_size_override("font_size", 18)
	_score_label.add_theme_color_override("font_color", Color("#88aaff"))
	_score_label.anchors_preset = Control.PRESET_TOP_WIDE
	_score_label.offset_top = 110
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_manager.add_child(_score_label)
	
	# 中央提示
	_center_hint = Label.new()
	_center_hint.name = "CenterHint"
	_center_hint.text = ""
	_center_hint.add_theme_font_size_override("font_size", 24)
	_center_hint.add_theme_color_override("font_color", Color(1, 1, 0.3))
	_center_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_center_hint.add_theme_constant_override("outline_size", 4)
	_center_hint.anchors_preset = Control.PRESET_CENTER
	_center_hint.position = Vector2(-150, -40)
	_center_hint.custom_minimum_size = Vector2(300, 40)
	_center_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_manager.add_child(_center_hint)

func _show_phase_intro() -> void:
	"""阶段开场提示"""
	if _center_hint:
		_center_hint.text = "⚡ 天雷将至！注意地面光圈！"
		_center_hint.modulate = Color(1, 1, 0.3, 1)
		var tween = create_tween()
		tween.tween_property(_center_hint, "modulate", Color(1, 1, 0.3, 0), 2.0)

# ==================== 完成/清理 ====================

func _complete_phase() -> void:
	"""阶段完成"""
	_is_running = false
	var final_score = _score
	
	# 清理残留标记
	for marker in _strike_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	_strike_markers.clear()
	
	# 清理HUD
	_cleanup_hud()
	
	# 小延迟后通知完成
	await get_tree().create_timer(0.5).timeout
	phase_completed.emit(final_score)

func _clear_marker(marker: Node3D) -> void:
	"""清理单个标记"""
	if marker and is_instance_valid(marker):
		marker.queue_free()
	_strike_markers.erase(marker)

func _cleanup_hud() -> void:
	"""清理HUD元素"""
	for node_name in ["WaveLabel", "ScoreLabel", "CenterHint"]:
		if _manager and _manager.has_node(node_name):
			_manager.get_node(node_name).queue_free()
	
	_wave_label = null
	_score_label = null
	_center_hint = null

func _exit_tree() -> void:
	"""退出时清理"""
	if _is_running:
		_is_running = false
		
		for marker in _strike_markers:
			if is_instance_valid(marker):
				marker.queue_free()
		_strike_markers.clear()
		
		_cleanup_hud()
