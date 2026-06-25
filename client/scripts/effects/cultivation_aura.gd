extends Node3D
## 💫 修行光环系统 — 根据境界/流派给玩家添加视觉特效
##
## 挂在 Player 身上作为子节点，自动监听 RealmSystem 变化
## 效果：脚下光环 + 身上辉光 + 头顶境界印记（可选）

class_name CultivationAura

# ==================== 境界颜色配置 ====================
const REALM_AURA_CONFIG = {
	0: {"color": Color(0.6, 0.6, 0.6), "ring_scale": 0.5, "glow_intensity": 0.0, "label": "凡"},
	1: {"color": Color(0.4, 0.7, 1.0), "ring_scale": 0.8, "glow_intensity": 0.2, "label": "练"},
	2: {"color": Color(0.3, 0.9, 0.5), "ring_scale": 1.0, "glow_intensity": 0.4, "label": "基"},
	3: {"color": Color(1.0, 0.8, 0.2), "ring_scale": 1.2, "glow_intensity": 0.6, "label": "丹"},
	4: {"color": Color(1.0, 0.4, 0.7), "ring_scale": 1.4, "glow_intensity": 0.8, "label": "婴"},
	5: {"color": Color(1.0, 0.3, 0.2), "ring_scale": 1.6, "glow_intensity": 1.0, "label": "神"},
	6: {"color": Color(0.5, 0.2, 1.0), "ring_scale": 1.8, "glow_intensity": 1.2, "label": "乘"},
	7: {"color": Color(0.2, 0.4, 1.0), "ring_scale": 2.0, "glow_intensity": 1.5, "label": "劫"},
	8: {"color": Color(1.0, 0.9, 0.5), "ring_scale": 2.5, "glow_intensity": 2.0, "label": "仙"},
}

# ==================== 节点引用 ====================
var _player: Node = null
var _realm_system: Node = null

# 光环视觉节点
var _foot_ring: MeshInstance3D = null      # 脚下光环环
var _body_glow: MeshInstance3D = null       # 身体辉光
var _particles: Node3D = null               # 粒子浮动

var _current_realm: int = 0
var _target_color: Color = Color.WHITE
var _target_intensity: float = 0.0
var _target_ring_scale: float = 1.0

func _ready() -> void:
	# 自动找玩家
	_player = get_parent()
	if _player and not _player.is_in_group("player"):
		_player = null
	
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
	
	# 找 RealmSystem
	_realm_system = get_node("/root/GameManager/RealmSystem") if has_node("/root/GameManager/RealmSystem") else null
	
	# 构建光环
	_build_aura()
	
	# 监听境界变化
	if _realm_system and _realm_system.has_signal("realm_changed"):
		_realm_system.realm_changed.connect(_on_realm_changed)
	
	# 初始设置
	var initial_realm = _realm_system.get("current_realm") if _realm_system else 0
	_on_realm_changed(initial_realm)

func _build_aura() -> void:
	"""构建光环视觉节点"""
	# 1. 脚下光环（环形网格）
	_foot_ring = MeshInstance3D.new()
	_foot_ring.name = "FootRing"
	_foot_ring.mesh = _create_ring_mesh(1.0, 0.05)
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1, 1, 1, 0.3)
	ring_mat.emission = Color.WHITE
	ring_mat.emission_energy_multiplier = 1.0
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_foot_ring.material_override = ring_mat
	_foot_ring.global_position = Vector3(0, 0.05, 0)
	add_child(_foot_ring)
	
	# 2. 身体辉光（半透明椭球）
	_body_glow = MeshInstance3D.new()
	_body_glow.name = "BodyGlow"
	_body_glow.mesh = SphereMesh.new()
	_body_glow.mesh.radius = 0.6
	_body_glow.mesh.height = 2.0
	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(1, 1, 1, 0.08)
	glow_mat.emission = Color.WHITE
	glow_mat.emission_energy_multiplier = 0.5
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_body_glow.material_override = glow_mat
	_body_glow.global_position = Vector3(0, 1.0, 0)
	add_child(_body_glow)
	
	# 3. 浮动粒子（小亮点环绕）
	_particles = Node3D.new()
	_particles.name = "FloatParticles"
	add_child(_particles)
	
	for i in range(8):
		var dot = MeshInstance3D.new()
		dot.mesh = SphereMesh.new()
		dot.mesh.radius = 0.02
		dot.mesh.height = 0.04
		var dot_mat = StandardMaterial3D.new()
		dot_mat.albedo_color = Color(1, 1, 1, 0.6)
		dot_mat.emission = Color.WHITE
		dot_mat.emission_energy_multiplier = 2.0
		dot.material_override = dot_mat
		
		var angle = i * TAU / 8
		dot.position = Vector3(cos(angle) * 1.2, 0.5 + sin(i * 2.0) * 0.3, sin(angle) * 1.2)
		_particles.add_child(dot)
		
		# 环绕动画
		var tw = create_tween().set_loops()
		tw.tween_property(dot, "position", 
			Vector3(cos(angle + TAU) * 1.2, 0.5 + sin(i * 2.0 + TAU) * 0.3, sin(angle + TAU) * 1.2),
			4.0 + i * 0.3
		).as_relative()

func _process(delta: float) -> void:
	"""平滑过渡到目标值"""
	if not _foot_ring or not _body_glow:
		return
	
	# 跟随玩家位置
	if _player:
		global_position = _player.global_position
	
	# 颜色过渡
	var ring_mat = _foot_ring.material_override
	var glow_mat = _body_glow.material_override
	if ring_mat and glow_mat:
		# 光环颜色
		ring_mat.emission = ring_mat.emission.lerp(_target_color, delta * 3.0)
		ring_mat.albedo_color = Color(
			_target_color.r, _target_color.g, _target_color.b, 0.3
		)
		
		# 辉光
		var alpha = clamp(_target_intensity * 0.08, 0.0, 0.3)
		glow_mat.albedo_color.a = lerpf(glow_mat.albedo_color.a, alpha, delta * 3.0)
		glow_mat.emission = glow_mat.emission.lerp(_target_color, delta * 3.0)
		glow_mat.emission_energy_multiplier = lerpf(glow_mat.emission_energy_multiplier, _target_intensity, delta * 3.0)
		
		# 光环缩放
		var scale = lerpf(_foot_ring.scale.x, _target_ring_scale, delta * 3.0)
		_foot_ring.scale = Vector3(scale, 1, scale)
	
	# 粒子颜色
	for dot in _particles.get_children():
		if dot is MeshInstance3D and dot.material_override:
			dot.material_override.emission = dot.material_override.emission.lerp(_target_color, delta * 2.0)

func _on_realm_changed(new_realm: int) -> void:
	"""境界变化时更新光环"""
	_current_realm = clampi(new_realm, 0, 8)
	
	var config = REALM_AURA_CONFIG.get(_current_realm, REALM_AURA_CONFIG[0])
	_target_color = config["color"]
	_target_intensity = config["glow_intensity"]
	_target_ring_scale = config["ring_scale"]
	
	# 突破瞬间闪亮
	_flash_aura()

func _flash_aura() -> void:
	"""突破瞬间闪光"""
	if _body_glow and _body_glow.material_override:
		var orig = _body_glow.material_override.albedo_color.a
		_body_glow.material_override.albedo_color.a = 0.8
		_body_glow.material_override.emission_energy_multiplier = 5.0
		
		var tween = create_tween()
		tween.tween_property(_body_glow.material_override, "albedo_color:a", orig, 1.0)
		tween.parallel().tween_property(_body_glow.material_override, "emission_energy_multiplier", _target_intensity, 1.0)

# ==================== 辅助网格 ====================

func _create_ring_mesh(radius: float, width: float) -> ArrayMesh:
	"""生成光环环形网格"""
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	var segments = 24
	for i in range(segments + 1):
		var t = float(i) / segments * TAU
		var outer = Vector3(cos(t) * radius, 0, sin(t) * radius)
		var inner = Vector3(cos(t) * (radius - width), 0, sin(t) * (radius - width))
		st.set_color(Color(1, 1, 1, 1))
		st.add_vertex(outer)
		st.add_vertex(inner)
	
	return st.commit()

# ==================== 公共接口 ====================

func set_realm(realm_level: int) -> void:
	"""手动设置境界光环"""
	_on_realm_changed(realm_level)

func fade_out(duration: float = 1.0) -> void:
	"""淡出光环"""
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), duration)
	tween.tween_callback(queue_free)
