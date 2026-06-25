## 🎨 全生物外观系统 — 程序化模型生成
##
## 用基本几何体组合出每种生物的标志性轮廓
## 支持：妖兽 ×4、灵宠 ×9、神兽BOSS ×5
## 没有用到外部3D模型，全在代码里生成

class_name CreatureAppearance

# ==================== 颜色配置 ====================
const COLORS = {
	# ---- 妖兽 ----
	"spirit_wolf": Color("#8a9ba8"),
	"mist_ape": Color("#7a8a7a"),
	"flame_boar": Color("#b84a3a"),
	"iron_tortoise": Color("#5a6a5a"),
	
	# ---- 灵宠 ----
	"crane": Color("#f0f0f0"),
	"fox": Color("#e8843a"),
	"panda": Color("#303030"),
	"pixiu": Color("#c8a838"),
	
	# ---- 神兽 ----
	"azure_dragon": Color("#2a7a5a"),
	"white_tiger": Color("#f0f0f8"),
	"vermilion_bird": Color("#d83a20"),
	"black_warrior": Color("#2a3a6a"),
	"golden_qilin": Color("#d4b828"),
	
	# ---- 妖兽(新) ----
	"green_serpent": Color("#3a9a5a"),
	"venomous_wyrm": Color("#2a7a3a"),
	"blade_cub": Color("#c8c0a8"),
	"saber_tiger": Color("#d0c8b0"),
	"flame_sparrow": Color("#e8683a"),
	"scorch_bird": Color("#ff5520"),
	"ice_turtle": Color("#6aaacc"),
	"frost_tortoise": Color("#4a88aa"),
	"stone_beast": Color("#8a7a5a"),
	"rock_armor": Color("#6a5a3a"),
	"elite_glow": Color("#ffcc00"),
	"boss_aura": Color("#ff4400"),
}

## 发光色
const EMISSION = {
	"spirit_wolf": Color("#6ab0ff"),
	"mist_ape": Color("#a0d0a0"),
	"flame_boar": Color("#ff6620"),
	"iron_tortoise": Color("#80a080"),
	"crane": Color("#80d0ff"),
	"fox": Color("#ffaa40"),
	"panda": Color("#608060"),
	"pixiu": Color("#ffd700"),
	"azure_dragon": Color("#40ff80"),
	"white_tiger": Color("#c0c0ff"),
	"vermilion_bird": Color("#ff4422"),
	"black_warrior": Color("#4080ff"),
	"golden_qilin": Color("#ffee44"),
	# ---- 新妖兽 ----
	"green_serpent": Color("#30cc60"),
	"venomous_wyrm": Color("#20ff40"),
	"blade_cub": Color("#e0d8c0"),
	"saber_tiger": Color("#ffdd88"),
	"flame_sparrow": Color("#ff6620"),
	"scorch_bird": Color("#ff3300"),
	"ice_turtle": Color("#60ccff"),
	"frost_tortoise": Color("#40aaff"),
	"stone_beast": Color("#c0a870"),
	"rock_armor": Color("#d4b860"),
}

## 模型尺寸
const SIZES = {
	"spirit_wolf": Vector3(1.2, 0.8, 1.8),
	"mist_ape": Vector3(1.5, 2.2, 1.4),
	"flame_boar": Vector3(1.8, 1.0, 2.0),
	"iron_tortoise": Vector3(2.0, 0.6, 2.5),
	"crane": Vector3(0.6, 2.0, 0.6),
	"fox": Vector3(0.8, 0.7, 1.2),
	"panda": Vector3(1.4, 1.2, 1.4),
	"pixiu": Vector3(1.6, 1.2, 2.0),
	"azure_dragon": Vector3(0.8, 1.5, 4.0),
	"white_tiger": Vector3(2.0, 1.4, 3.0),
	"vermilion_bird": Vector3(1.2, 1.8, 2.2),
	"black_warrior": Vector3(2.4, 0.8, 2.8),
	"golden_qilin": Vector3(1.6, 1.6, 2.4),
	# ---- 新妖兽 ----
	"green_serpent": Vector3(0.4, 0.3, 1.6),
	"venomous_wyrm": Vector3(0.6, 0.5, 2.2),
	"blade_cub": Vector3(0.8, 0.6, 1.2),
	"saber_tiger": Vector3(1.4, 1.0, 2.2),
	"flame_sparrow": Vector3(0.6, 0.5, 0.6),
	"scorch_bird": Vector3(0.9, 0.8, 0.9),
	"ice_turtle": Vector3(1.4, 0.5, 1.8),
	"frost_tortoise": Vector3(1.8, 0.6, 2.2),
	"stone_beast": Vector3(1.6, 1.2, 1.6),
	"rock_armor": Vector3(2.0, 1.6, 2.0),
}

# ==================== 主入口 ====================

## 为指定生物类型生成完整外观节点
## 返回：{mesh: Node3D, scale_override: Vector3}
static func build_appearance(creature_type: String, is_elite: bool = false, is_boss: bool = false) -> Node3D:
	var root = Node3D.new()
	var key = creature_type.to_lower()
	var color = COLORS.get(key, Color.GRAY)
	var emission = EMISSION.get(key, Color.WHITE * 0.2)
	var size = SIZES.get(key, Vector3.ONE)
	
	# 精英/神兽放大
	if is_elite:
		size *= 1.2
	if is_boss:
		size *= 3.0
	
	# 为每种生物类型调用专属构建
	match key:
		"spirit_wolf": _build_wolf(root, size, color, emission)
		"mist_ape": _build_ape(root, size, color, emission)
		"flame_boar": _build_boar(root, size, color, emission)
		"iron_tortoise": _build_tortoise(root, size, color, emission)
		"crane": _build_crane(root, size, color, emission)
		"fox": _build_fox(root, size, color, emission)
		"panda": _build_panda(root, size, color, emission)
		"pixiu": _build_pixiu(root, size, color, emission)
		"azure_dragon": _build_azure_dragon(root, size, color, emission)
		"white_tiger": _build_white_tiger(root, size, color, emission)
		"vermilion_bird": _build_vermilion_bird(root, size, color, emission)
		"black_warrior": _build_black_warrior(root, size, color, emission)
		"golden_qilin": _build_golden_qilin(root, size, color, emission)
		# 新妖兽
		"green_serpent": _build_green_serpent(root, size, color, emission)
		"venomous_wyrm": _build_green_serpent(root, size, color, emission)
		"blade_cub": _build_blade_cub(root, size, color, emission)
		"saber_tiger": _build_saber_tiger(root, size, color, emission)
		"flame_sparrow": _build_flame_sparrow(root, size, color, emission)
		"scorch_bird": _build_scorch_bird(root, size, color, emission)
		"ice_turtle": _build_ice_turtle(root, size, color, emission)
		"frost_tortoise": _build_frost_tortoise(root, size, color, emission)
		"stone_beast": _build_stone_beast(root, size, color, emission)
		"rock_armor": _build_rock_armor(root, size, color, emission)
		_: _build_default(root, size, color, emission)
	
	# 精英光环
	if is_elite:
		_add_elite_aura(root, color)
	
	# BOSS更亮
	if is_boss:
		_add_boss_glow(root, color)
	
	# 头顶名字标签区
	var label_pivot = Node3D.new()
	label_pivot.position = Vector3.UP * (size.y * 0.7 + 0.5)
	label_pivot.name = "LabelPivot"
	root.add_child(label_pivot)
	
	return root


# ==================== 妖兽构建 ====================

static func _build_wolf(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""🐺 灵狼 — 流线型身躯"""
	# 身体
	var body = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.6, size.y * 0.5, size.z * 0.7), color, emission)
	body.position.y = size.y * 0.25
	root.add_child(body)
	
	# 头
	var head = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.35, size.y * 0.3, size.z * 0.25), color, emission)
	head.position = Vector3(0, size.y * 0.5, size.z * 0.4)
	root.add_child(head)
	
	# 眼睛发光
	var eye_mat = StandardMaterial3D.new()
	eye_mat.albedo_color = Color("#80d0ff")
	eye_mat.emission_enabled = true
	eye_mat.emission = Color("#80d0ff")
	var eye = _make_mesh(SphereMesh.new(), Vector3(0.08, 0.08, 0.08), Color("#80d0ff"), Color("#80d0ff"))
	eye.position = Vector3(size.x * 0.12, size.y * 0.55, size.z * 0.5)
	root.add_child(eye)
	var eye2 = eye.duplicate()
	eye2.position.x = -size.x * 0.12
	root.add_child(eye2)
	
	# 尾巴
	var tail = _make_mesh(CylinderMesh.new(), Vector3(0.06, size.z * 0.25, 0.06), color, emission)
	tail.position = Vector3(0, size.y * 0.15, -size.z * 0.4)
	tail.rotation.x = deg_to_rad(30)
	root.add_child(tail)

static func _build_ape(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""🐒 雾猿 — 高大佝偻"""
	# 躯干
	var body = _make_mesh(CapsuleMesh.new(), Vector3(size.x * 0.35, size.y * 0.4, size.z * 0.3), color, emission)
	body.position.y = size.y * 0.4
	root.add_child(body)
	
	# 头
	var head = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.25, size.y * 0.2, size.z * 0.25), color, emission)
	head.position = Vector3(0, size.y * 0.75, 0)
	root.add_child(head)
	
	# 眼睛
	var eye_mat = StandardMaterial3D.new()
	eye_mat.albedo_color = Color("#a0ffa0")
	eye_mat.emission_enabled = true
	eye_mat.emission = Color("#a0ffa0")
	var eye = _make_mesh(SphereMesh.new(), Vector3(0.06, 0.06, 0.06), Color("#a0ffa0"), Color("#a0ffa0"))
	eye.position = Vector3(size.x * 0.1, size.y * 0.8, size.z * 0.15)
	root.add_child(eye)
	var eye2 = eye.duplicate()
	eye2.position.x = -size.x * 0.1
	root.add_child(eye2)
	
	# 手臂
	for side in [-1, 1]:
		var arm = _make_mesh(CylinderMesh.new(), Vector3(0.08, size.y * 0.3, 0.08), color, emission)
		arm.position = Vector3(side * size.x * 0.4, size.y * 0.5, 0)
		arm.rotation.z = deg_to_rad(side * 20)
		root.add_child(arm)

static func _build_boar(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""🐗 焰猪 — 粗壮+火焰纹"""
	# 身体
	var body = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.45, size.y * 0.4, size.z * 0.5), color, emission)
	body.position.y = size.y * 0.35
	root.add_child(body)
	
	# 头
	var head = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.3, size.y * 0.25, size.z * 0.2), color, emission)
	head.position = Vector3(0, size.y * 0.35, size.z * 0.4)
	root.add_child(head)
	
	# 獠牙
	var tusk_mat = StandardMaterial3D.new()
	tusk_mat.albedo_color = Color("#e8d8b0")
	for side in [-1, 1]:
		var tusk = _make_mesh(CylinderMesh.new(), Vector3(0.04, 0.15, 0.04), Color("#e8d8b0"), Color.BLACK)
		tusk.position = Vector3(side * 0.12, size.y * 0.25, size.z * 0.45)
		tusk.rotation.x = deg_to_rad(side * 30)
		root.add_child(tusk)
	
	# 火焰纹（橙色发光条纹）
	var flame_mat = StandardMaterial3D.new()
	flame_mat.albedo_color = Color("#ff6620")
	flame_mat.emission_enabled = true
	flame_mat.emission = Color("#ff6620")
	var stripe = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.01, size.y * 0.3, size.z * 0.4), Color("#ff6620"), Color("#ff6620"))
	stripe.position.y = size.y * 0.35
	root.add_child(stripe)

static func _build_tortoise(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""🐢 铁龟 — 圆壳+金属感"""
	# 壳
	var shell = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.4, size.y * 0.3, size.z * 0.4), color, emission)
	shell.position.y = size.y * 0.3
	shell.scale.y = 0.5
	root.add_child(shell)
	
	# 壳上纹路
	var pattern_mat = StandardMaterial3D.new()
	pattern_mat.albedo_color = Color("#4a6a4a")
	pattern_mat.metallic = 0.7
	pattern_mat.roughness = 0.3
	var pattern = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.3, 0.02, size.z * 0.3), Color("#4a6a4a"), Color.BLACK)
	pattern.position.y = size.y * 0.45
	root.add_child(pattern)
	
	# 头
	var head = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.12, size.y * 0.1, size.z * 0.12), color, emission)
	head.position = Vector3(0, size.y * 0.1, size.z * 0.35)
	root.add_child(head)
	
	# 四肢
	for x in [-1, 1]:
		for z in [-1, 1]:
			var leg = _make_mesh(CylinderMesh.new(), Vector3(0.06, 0.12, 0.06), color, emission)
			leg.position = Vector3(x * size.x * 0.25, 0.05, z * size.z * 0.25)
			root.add_child(leg)


# ==================== 灵宠构建 ====================

static func _build_crane(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""🦩 仙鹤 — 高挑优雅"""
	# 身体
	var body = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.4, size.y * 0.15, size.z * 0.35), color, emission)
	body.position.y = size.y * 0.4
	body.scale.y = 0.5
	root.add_child(body)
	
	# 脖子
	var neck = _make_mesh(CylinderMesh.new(), Vector3(0.05, size.y * 0.4, 0.05), Color.WHITE, emission)
	neck.position = Vector3(0, size.y * 0.6, size.z * 0.1)
	neck.rotation.x = deg_to_rad(-20)
	root.add_child(neck)
	
	# 头
	var head = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.08, size.y * 0.06, size.z * 0.08), Color.RED, emission)
	head.position = Vector3(0, size.y * 0.8, size.z * 0.35)
	root.add_child(head)
	
	# 翅膀
	for side in [-1, 1]:
		var wing = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.5, 0.02, size.z * 0.2), Color.WHITE, emission)
		wing.position = Vector3(side * size.x * 0.4, size.y * 0.4, 0)
		wing.rotation.y = deg_to_rad(side * 30)
		root.add_child(wing)
	
	# 腿
	for side in [-1, 1]:
		var leg = _make_mesh(CylinderMesh.new(), Vector3(0.03, size.y * 0.3, 0.03), Color("#d4a070"), Color.BLACK)
		leg.position = Vector3(side * 0.08, size.y * 0.1, -size.z * 0.1)
		root.add_child(leg)

static func _build_fox(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""🦊 灵狐 — 灵动小巧"""
	# 身体
	var body = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.35, size.y * 0.25, size.z * 0.35), color, emission)
	body.position.y = size.y * 0.3
	root.add_child(body)
	
	# 头
	var head = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.15, size.y * 0.12, size.z * 0.15), color, emission)
	head.position = Vector3(0, size.y * 0.45, size.z * 0.25)
	root.add_child(head)
	
	# 耳朵
	for side in [-1, 1]:
		var ear = _make_mesh(CylinderMesh.new(), Vector3(0.06, 0.08, 0.06), color, emission)
		ear.position = Vector3(side * 0.1, size.y * 0.55, size.z * 0.2)
		root.add_child(ear)
	
	# 尾巴（多尾特效）
	var tail_mat = StandardMaterial3D.new()
	tail_mat.albedo_color = Color("#d07030")
	tail_mat.emission_enabled = true
	tail_mat.emission = Color("#d07030") * 0.3
	for i in range(3):
		var tail = _make_mesh(CylinderMesh.new(), Vector3(0.05, size.z * 0.3, 0.05), Color("#d07030"), Color("#d07030") * 0.3)
		tail.position = Vector3((i-1) * 0.06, size.y * 0.1, -size.z * 0.2)
		tail.rotation.x = deg_to_rad(20 + i * 10)
		tail.rotation.z = deg_to_rad((i-1) * 15)
		root.add_child(tail)

static func _build_panda(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""🐼 竹熊 — 圆滚滚"""
	# 身体
	var body = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.4, size.y * 0.35, size.z * 0.4), Color.WHITE, emission)
	body.position.y = size.y * 0.35
	root.add_child(body)
	
	# 黑色躯干带
	var band = _make_mesh(CylinderMesh.new(), Vector3(size.x * 0.38, size.y * 0.1, size.z * 0.38), Color("#222222"), Color.BLACK)
	band.position.y = size.y * 0.35
	root.add_child(band)
	
	# 头
	var head = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.25, size.y * 0.2, size.z * 0.25), Color.WHITE, emission)
	head.position = Vector3(0, size.y * 0.55, size.z * 0.2)
	root.add_child(head)
	
	# 眼圈
	for side in [-1, 1]:
		var eye_ring = _make_mesh(SphereMesh.new(), Vector3(0.1, 0.08, 0.05), Color("#222222"), Color.BLACK)
		eye_ring.position = Vector3(side * 0.12, size.y * 0.58, size.z * 0.35)
		root.add_child(eye_ring)

static func _build_pixiu(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""🦁 貔貅 — 狮形带翅"""
	# 身体
	var body = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.5, size.y * 0.4, size.z * 0.6), color, emission)
	body.position.y = size.y * 0.3
	root.add_child(body)
	
	# 头
	var head = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.2, size.y * 0.15, size.z * 0.2), color, emission)
	head.position = Vector3(0, size.y * 0.45, size.z * 0.4)
	root.add_child(head)
	
	# 翅膀
	for side in [-1, 1]:
		var wing = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.4, 0.05, size.z * 0.2), Color("#e8d080"), Color("#e8d080") * 0.3)
		wing.position = Vector3(side * size.x * 0.45, size.y * 0.45, 0)
		wing.rotation.y = deg_to_rad(side * 25)
		wing.rotation.x = deg_to_rad(-15)
		root.add_child(wing)
	
	# 角
	for side in [-1, 1]:
		var horn = _make_mesh(CylinderMesh.new(), Vector3(0.03, 0.1, 0.03), Color("#c8a838"), Color("#c8a838") * 0.3)
		horn.position = Vector3(side * 0.06, size.y * 0.55, size.z * 0.35)
		horn.rotation.x = deg_to_rad(side * 15)
		root.add_child(horn)


# ==================== 神兽构建 ====================

static func _build_azure_dragon(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""🐉 青龙 — 蛇形蜿蜒"""
	# 身体分段
	var segments = 6
	for i in range(segments):
		var t = float(i) / (segments - 1)
		var seg_size = lerp(size.x * 0.5, size.x * 0.3, t)
		var seg = _make_mesh(SphereMesh.new(), Vector3(seg_size, seg_size, seg_size), color, emission * (1.0 - t * 0.5))
		var zpos = lerp(size.z * 0.35, -size.z * 0.35, t)
		var ypos = size.y * 0.3 + sin(t * PI) * 0.3
		seg.position = Vector3(0, ypos, zpos)
		root.add_child(seg)
	
	# 头（更大）
	var head = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.35, size.y * 0.2, size.z * 0.2), color, emission)
	head.position = Vector3(0, size.y * 0.3, size.z * 0.4)
	root.add_child(head)
	
	# 角
	for side in [-1, 1]:
		var horn = _make_mesh(CylinderMesh.new(), Vector3(0.03, 0.12, 0.03), Color("#2a9a6a"), Color("#2a9a6a") * 0.5)
		horn.position = Vector3(side * 0.08, size.y * 0.5, size.z * 0.45)
		horn.rotation.z = deg_to_rad(side * 25)
		root.add_child(horn)
	
	# 胡须
	var whisker = _make_mesh(CylinderMesh.new(), Vector3(0.01, size.z * 0.2, 0.01), Color("#2a9a6a"), Color("#2a9a6a") * 0.3)
	whisker.position = Vector3(0, size.y * 0.25, size.z * 0.6)
	root.add_child(whisker)

static func _build_white_tiger(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""🐅 白虎 — 威猛虎躯"""
	# 身体
	var body = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.6, size.y * 0.45, size.z * 0.65), color, emission)
	body.position.y = size.y * 0.3
	root.add_child(body)
	
	# 虎纹
	for i in range(4):
		var t = float(i) / 3
		var stripe = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.01, size.y * 0.35, size.z * 0.05), Color("#2a2a3a"), Color.BLACK)
		var zpos = lerp(size.z * 0.2, -size.z * 0.3, t)
		stripe.position = Vector3(0, size.y * 0.3, zpos)
		root.add_child(stripe)
	
	# 头
	var head = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.25, size.y * 0.18, size.z * 0.2), color, emission)
	head.position = Vector3(0, size.y * 0.45, size.z * 0.45)
	root.add_child(head)
	
	# 王字纹
	var king = _make_mesh(BoxMesh.new(), Vector3(0.02, 0.02, 0.05), Color("#2a2a3a"), Color.BLACK)
	king.position = Vector3(0, size.y * 0.5, size.z * 0.55)
	root.add_child(king)
	
	# 尾巴
	var tail = _make_mesh(CylinderMesh.new(), Vector3(0.06, size.z * 0.2, 0.06), color, emission)
	tail.position = Vector3(0, size.y * 0.3, -size.z * 0.4)
	tail.rotation.x = deg_to_rad(40)
	root.add_child(tail)

static func _build_vermilion_bird(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""🦅 朱雀 — 火凤展翅"""
	# 身体
	var body = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.3, size.y * 0.2, size.z * 0.3), color, emission)
	body.position.y = size.y * 0.3
	root.add_child(body)
	
	# 翅膀展开
	for side in [-1, 1]:
		var wing = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.6, 0.04, size.z * 0.15), color, emission)
		wing.position = Vector3(side * size.x * 0.45, size.y * 0.35, 0)
		wing.rotation.y = deg_to_rad(side * 35)
		wing.rotation.x = deg_to_rad(-20)
		root.add_child(wing)
		
		# 火焰尾羽
		var feather = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.3, 0.02, size.z * 0.08), Color("#ff8844"), Color("#ff4422"))
		feather.position = Vector3(side * size.x * 0.3, size.y * 0.2, -size.z * 0.3)
		feather.rotation.z = deg_to_rad(side * 25)
		root.add_child(feather)
	
	# 冠羽
	var crest = _make_mesh(CylinderMesh.new(), Vector3(0.05, 0.1, 0.05), Color("#ff4422"), Color("#ff4422"))
	crest.position = Vector3(0, size.y * 0.55, size.z * 0.15)
	root.add_child(crest)

static func _build_black_warrior(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""🐢🐍 玄武 — 龟壳蛇绕"""
	# 龟壳
	var shell = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.35, size.y * 0.2, size.z * 0.35), color, emission)
	shell.scale.y = 0.4
	shell.position.y = size.y * 0.2
	root.add_child(shell)
	
	# 甲板纹路
	var plate = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.25, 0.02, size.z * 0.25), Color("#3a4a7a"), Color("#3a4a7a") * 0.3)
	plate.position.y = size.y * 0.35
	root.add_child(plate)
	
	# 蛇绕身
	var snake = _make_mesh(CylinderMesh.new(), Vector3(0.04, size.z * 0.6, 0.04), Color("#3a6a3a"), Color("#3a6a3a") * 0.3)
	snake.position = Vector3(size.x * 0.2, size.y * 0.3, size.z * 0.1)
	snake.rotation.x = deg_to_rad(45)
	snake.rotation.z = deg_to_rad(30)
	root.add_child(snake)
	
	# 蛇头
	var snake_head = _make_mesh(SphereMesh.new(), Vector3(0.06, 0.05, 0.06), Color("#3a8a3a"), Color("#3a8a3a") * 0.5)
	snake_head.position = Vector3(size.x * 0.25, size.y * 0.4, size.z * 0.25)
	root.add_child(snake_head)

static func _build_golden_qilin(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""🦄 麒麟 — 鹿身龙鳞"""
	# 身体
	var body = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.45, size.y * 0.35, size.z * 0.55), color, emission)
	body.position.y = size.y * 0.3
	root.add_child(body)
	
	# 鳞片纹理（用多个小球）
	for i in range(20):
		var scale = randf_range(0.02, 0.04)
		var scale_mesh = _make_mesh(SphereMesh.new(), Vector3(scale, scale, scale), Color("#e8d060"), Color("#e8d060") * 0.3)
		var rx = randf_range(-size.x * 0.2, size.x * 0.2)
		var ry = randf_range(size.y * 0.2, size.y * 0.45)
		var rz = randf_range(-size.z * 0.25, size.z * 0.25)
		scale_mesh.position = Vector3(rx, ry, rz)
		root.add_child(scale_mesh)
	
	# 头
	var head = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.18, size.y * 0.14, size.z * 0.18), color, emission)
	head.position = Vector3(0, size.y * 0.45, size.z * 0.4)
	root.add_child(head)
	
	# 角（麒麟独有——分叉角）
	for side in [-1, 1]:
		var horn = _make_mesh(CylinderMesh.new(), Vector3(0.03, 0.12, 0.03), Color("#d4a828"), Color("#d4a828") * 0.5)
		horn.position = Vector3(side * 0.06, size.y * 0.55, size.z * 0.42)
		horn.rotation.z = deg_to_rad(side * 20)
		root.add_child(horn)
		
		var horn_tip = _make_mesh(SphereMesh.new(), Vector3(0.04, 0.04, 0.04), Color("#ffee44"), Color("#ffee44"))
		horn_tip.position = Vector3(side * 0.08, size.y * 0.62, size.z * 0.38)
		root.add_child(horn_tip)
	
	# 鬃毛
	var mane = _make_mesh(CylinderMesh.new(), Vector3(0.08, size.y * 0.1, 0.08), Color("#d4a828"), Color("#d4a828") * 0.5)
	mane.position = Vector3(0, size.y * 0.5, size.z * 0.3)
	root.add_child(mane)

# ==================== 新妖兽构建 ====================

static func _build_green_serpent(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""🐍 木蛇/青蛟 — 细长身躯蜿蜒"""
	for i in range(4):
		var seg = _make_mesh(SphereMesh.new(), Vector3(size.x * (0.8 - i*0.1), size.y * 0.5, size.z * 0.2), color, emission * 0.6)
		seg.position = Vector3(0, size.y * 0.2 + sin(i * 0.8) * 0.1, -size.z * 0.25 * i + size.z * 0.2)
		root.add_child(seg)
	var head = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.5, size.y * 0.3, size.z * 0.15), color, emission)
	head.position = Vector3(0, size.y * 0.4, size.z * 0.35)
	root.add_child(head)
	for side in [-1, 1]:
		var fang = _make_mesh(CylinderMesh.new(), Vector3(0.02, size.y * 0.1, 0.02), Color("#40ff40"), Color("#40ff40"))
		fang.position = Vector3(side * size.x * 0.1, size.y * 0.25, size.z * 0.4)
		root.add_child(fang)

static func _build_blade_cub(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""🐯 小剑虎 — 矮壮幼虎"""
	var body = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.5, size.y * 0.4, size.z * 0.5), color, emission)
	body.position.y = size.y * 0.2; root.add_child(body)
	var head = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.3, size.y * 0.25, size.z * 0.2), color.lightened(0.1), emission)
	head.position = Vector3(0, size.y * 0.5, size.z * 0.3); root.add_child(head)
	var blade = _make_mesh(BoxMesh.new(), Vector3(0.03, size.y * 0.2, 0.03), Color("#e0d8c0"), Color("#c0c0ff"))
	blade.position = Vector3(0, size.y * 0.65, size.z * 0.2); root.add_child(blade)

static func _build_saber_tiger(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""⚔️ 剑虎(精英) — 剑齿虎"""
	var body = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.6, size.y * 0.5, size.z * 0.6), color, emission)
	body.position.y = size.y * 0.25; root.add_child(body)
	var head = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.35, size.y * 0.3, size.z * 0.2), color, emission)
	head.position = Vector3(0, size.y * 0.55, size.z * 0.4); root.add_child(head)
	for side in [-1, 1]:
		var fang = _make_mesh(CylinderMesh.new(), Vector3(0.03, size.y * 0.25, 0.03), Color("#e0d8c0"), Color("#c0c0ff"))
		fang.position = Vector3(side * size.x * 0.12, size.y * 0.3, size.z * 0.45)
		fang.rotation.x = deg_to_rad(side * 15); root.add_child(fang)
	var mark = _make_mesh(BoxMesh.new(), Vector3(0.05, size.y * 0.15, size.z * 0.3), Color("#f0e8d0"), Color("#e0d0a0"))
	mark.position = Vector3(0, size.y * 0.6, 0); root.add_child(mark)

static func _build_flame_sparrow(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""🐦 炎雀 — 小巧火鸟"""
	var body = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.35, size.y * 0.3, size.z * 0.25), color, emission)
	body.position.y = size.y * 0.3; root.add_child(body)
	for side in [-1, 1]:
		var wing = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.3, 0.03, size.z * 0.15), color.lightened(0.2), emission)
		wing.position = Vector3(side * size.x * 0.3, size.y * 0.3, 0)
		wing.rotation.z = deg_to_rad(side * 25); root.add_child(wing)
	var tail = _make_mesh(BoxMesh.new(), Vector3(0.02, size.y * 0.15, size.z * 0.1), Color("#ff6620"), Color("#ff4400"))
	tail.position = Vector3(0, size.y * 0.2, -size.z * 0.25); root.add_child(tail)

static func _build_scorch_bird(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""🔥 炙鸟(精英) — 烈焰环绕"""
	var body = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.4, size.y * 0.35, size.z * 0.3), color, emission)
	body.position.y = size.y * 0.35; root.add_child(body)
	for side in [-1, 1]:
		var wing = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.4, 0.04, size.z * 0.2), color.lightened(0.3), emission)
		wing.position = Vector3(side * size.x * 0.35, size.y * 0.35, 0)
		wing.rotation.z = deg_to_rad(side * 30); root.add_child(wing)
	for i in range(3):
		var tail = _make_mesh(BoxMesh.new(), Vector3(0.02, size.y * 0.2, size.z * 0.1), Color("#ff4400"), Color("#ff2200"))
		tail.position = Vector3((i-1) * size.x * 0.1, size.y * 0.2, -size.z * 0.3); root.add_child(tail)
	var crown = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.08, size.y * 0.08, size.z * 0.06), Color("#ffaa22"), Color("#ff8800"))
	crown.position = Vector3(0, size.y * 0.55, size.z * 0.25); root.add_child(crown)

static func _build_ice_turtle(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""🐢 冰鳖 — 覆冰小龟"""
	var body = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.6, size.y * 0.25, size.z * 0.5), color, emission * 0.5)
	body.position.y = size.y * 0.12; root.add_child(body)
	var shell = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.35, size.y * 0.2, size.z * 0.25), color.lightened(0.2), emission)
	shell.position.y = size.y * 0.3; root.add_child(shell)
	var crystal = _make_mesh(CylinderMesh.new(), Vector3(0.03, size.y * 0.15, 0.03), Color("#aaddff"), Color("#88bbff"))
	crystal.position = Vector3(0, size.y * 0.45, 0); root.add_child(crystal)

static func _build_frost_tortoise(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""❄️ 寒龟(精英) — 冰甲覆盖"""
	var body = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.7, size.y * 0.3, size.z * 0.6), color, emission * 0.4)
	body.position.y = size.y * 0.15; root.add_child(body)
	var shell = _make_mesh(SphereMesh.new(), Vector3(size.x * 0.4, size.y * 0.25, size.z * 0.3), color.lightened(0.15), emission)
	shell.position.y = size.y * 0.35; root.add_child(shell)
	for i in range(6):
		var angle = i * PI / 3
		var spike = _make_mesh(CylinderMesh.new(), Vector3(0.04, size.y * 0.2, 0.04), Color("#aaddff"), Color("#88bbff"))
		spike.position = Vector3(cos(angle) * size.x * 0.3, size.y * 0.4, sin(angle) * size.z * 0.25)
		spike.rotation.z = deg_to_rad(randf_range(-10, 10)); root.add_child(spike)

static func _build_stone_beast(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""🗿 土兽 — 石质粗犷"""
	var body = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.6, size.y * 0.5, size.z * 0.5), color, emission * 0.3)
	body.position.y = size.y * 0.25; root.add_child(body)
	var head = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.3, size.y * 0.25, size.z * 0.2), color, emission)
	head.position = Vector3(0, size.y * 0.5, size.z * 0.3); root.add_child(head)
	var vein = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.01, size.y * 0.02, size.z * 0.3), Color("#b0a080"), Color("#c0a870"))
	vein.position = Vector3(size.x * 0.15, size.y * 0.3, 0); root.add_child(vein)
	var vein2 = vein.duplicate(); vein2.position.x = -size.x * 0.15; root.add_child(vein2)

static func _build_rock_armor(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""🏔️ 岩甲兽(精英) — 身披岩石铠甲"""
	var body = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.7, size.y * 0.5, size.z * 0.6), color, emission * 0.3)
	body.position.y = size.y * 0.25; root.add_child(body)
	var head = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.35, size.y * 0.3, size.z * 0.25), color, emission)
	head.position = Vector3(0, size.y * 0.55, size.z * 0.35); root.add_child(head)
	for side in [-1, 1]:
		var pauldron = _make_mesh(BoxMesh.new(), Vector3(size.x * 0.2, size.y * 0.1, size.z * 0.12), color.darkened(0.2), emission * 0.2)
		pauldron.position = Vector3(side * size.x * 0.4, size.y * 0.4, 0); root.add_child(pauldron)
	for i in range(4):
		var angle = i * PI / 2 + PI / 4
		var spike = _make_mesh(CylinderMesh.new(), Vector3(0.05, size.y * 0.3, 0.05), color.darkened(0.3), emission * 0.2)
		spike.position = Vector3(cos(angle) * size.x * 0.35, size.y * 0.4, sin(angle) * size.z * 0.3); root.add_child(spike)

static func _build_default(root: Node3D, size: Vector3, color: Color, emission: Color) -> void:
	"""默认占位"""
	var box = _make_mesh(BoxMesh.new(), size, color, emission)
	box.position.y = size.y * 0.5
	root.add_child(box)


# ==================== 辅助 ====================

static func _make_mesh(mesh: PrimitiveMesh, scale: Vector3, color: Color, emission: Color) -> MeshInstance3D:
	"""创建带材质的基本几何体"""
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	if emission != Color.BLACK and emission != Color():
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = 0.5
	
	mat.metallic = 0.1
	mat.roughness = 0.7
	
	# 部分生物增加光泽
	if color.s > 0.5:
		mat.metallic = 0.3
		mat.roughness = 0.5
	
	var instance = MeshInstance3D.new()
	instance.mesh = mesh
	instance.scale = scale
	return instance

static func _add_elite_aura(root: Node3D, base_color: Color) -> void:
	"""精英光环环"""
	var ring = _make_mesh(TorusMesh.new(), Vector3(1.5, 0.05, 1.5), Color("#ffcc00"), Color("#ffcc00"))
	ring.position.y = 0.05
	root.add_child(ring)
	
	# 粒子提示用光柱
	var glow = _make_mesh(CylinderMesh.new(), Vector3(0.05, 0.5, 0.05), Color("#ffcc00"), Color("#ffcc00"))
	glow.position.y = 0.5
	root.add_child(glow)

static func _add_boss_glow(root: Node3D, base_color: Color) -> void:
	"""BOSS更大光环"""
	var ring1 = _make_mesh(TorusMesh.new(), Vector3(2.5, 0.08, 2.5), Color("#ff4400"), Color("#ff4400"))
	ring1.position.y = 0.05
	root.add_child(ring1)
	
	var ring2 = _make_mesh(TorusMesh.new(), Vector3(2.0, 0.05, 2.0), Color("#ffaa00"), Color("#ffaa00") * 0.8)
	ring2.position.y = 0.1
	root.add_child(ring2)
