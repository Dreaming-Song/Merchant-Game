extends StaticBody3D
## 工作站 — 物理世界中的合成台/熔炉等
##
## 放在世界中，玩家靠近后自动激活对应合成配方
## 支持类型：workbench / furnace / anvil / alchemy_table / loom

class_name WorkstationStation

# ==================== 工作站类型 ====================
enum StationType {
	WORKBENCH,      # 工作台 — 基础工具/武器/木石建筑
	FURNACE,        # 熔炉 — 冶炼金属
	ANVIL,          # 铁砧 — 高级武器/护甲
	ALCHEMY_TABLE,  # 炼丹炉 — 丹药/灵药
	LOOM,           # 织布机 — 布料/防具
	SPIRIT_FURNACE, # 灵炉 — 高级冶炼
	RUNE_TABLE,     # 符文台 — 附魔/符文
	SOUL_FORGE,     # 魂器锻造台 — 锻造魂器
}

const STATION_NAMES: Dictionary = {
	StationType.WORKBENCH: "workbench",
	StationType.FURNACE: "furnace",
	StationType.ANVIL: "anvil",
	StationType.ALCHEMY_TABLE: "alchemy_furnace",
	StationType.LOOM: "loom",
	StationType.SPIRIT_FURNACE: "spirit_furnace",
	StationType.RUNE_TABLE: "rune_table",
	StationType.SOUL_FORGE: "soul_forge",
}

const STATION_DISPLAY_NAMES: Dictionary = {
	StationType.WORKBENCH: "工作台",
	StationType.FURNACE: "熔炉",
	StationType.ANVIL: "铁砧",
	StationType.ALCHEMY_TABLE: "炼丹炉",
	StationType.LOOM: "织布机",
	StationType.SPIRIT_FURNACE: "灵炉",
	StationType.RUNE_TABLE: "符文台",
	StationType.SOUL_FORGE: "魂器锻造台",
}

## 通过配方名获取工作站类型（用于放置时判断）
static func get_station_type_from_recipe(recipe_result: String) -> int:
	match recipe_result:
		"workbench": return StationType.WORKBENCH
		"furnace": return StationType.FURNACE
		"anvil": return StationType.ANVIL
		"alchemy_furnace": return StationType.ALCHEMY_TABLE
		"loom": return StationType.LOOM
		"spirit_furnace": return StationType.SPIRIT_FURNACE
		"rune_table": return StationType.RUNE_TABLE
		"soul_forge": return StationType.SOUL_FORGE
	return StationType.WORKBENCH

# ==================== 导出属性 ====================
@export var station_type: int = StationType.WORKBENCH
@export var interaction_radius: float = 4.0
@export var station_name: String = "工作台"

# ==================== 内部 ====================
var _player_nearby: bool = false
var _crafting_system: Node = null
var _trigger_area: Area3D = null

func _ready() -> void:
	station_name = STATION_DISPLAY_NAMES.get(station_type, "工作站")
	add_to_group("workstations")
	
	# 创建触发区域
	_trigger_area = Area3D.new()
	_trigger_area.name = "TriggerArea"
	add_child(_trigger_area)
	
	var col_shape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = interaction_radius
	col_shape.shape = sphere
	_trigger_area.add_child(col_shape)
	
	# 连接信号
	_trigger_area.body_entered.connect(_on_body_entered)
	_trigger_area.body_exited.connect(_on_body_exited)
	
	# 创建视觉
	_create_visual()
	
	# 获取合成系统引用
	_crafting_system = get_node("/root/GameManager/CraftingSystem") if has_node("/root/GameManager/CraftingSystem") else null
	if not _crafting_system:
		_crafting_system = get_node("/root/GameManager/CraftingSystem") if has_node("/root/GameManager/CraftingSystem") else null

func _create_visual() -> void:
	"""根据工作站类型创建不同视觉"""
	var station_id = STATION_NAMES.get(station_type, "workbench")
	
	match station_type:
		StationType.WORKBENCH:
			_create_workbench_visual()
		StationType.FURNACE, StationType.SPIRIT_FURNACE:
			_create_furnace_visual()
		StationType.ANVIL:
			_create_anvil_visual()
		StationType.ALCHEMY_TABLE:
			_create_alchemy_visual()
		StationType.LOOM:
			_create_loom_visual()
		StationType.RUNE_TABLE:
			_create_rune_visual()
		StationType.SOUL_FORGE:
			_create_soul_forge_visual()
		_:
			# 默认：盒子
			var box = MeshInstance3D.new()
			box.mesh = BoxMesh.new()
			box.mesh.size = Vector3(0.8, 0.6, 0.8)
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.5, 0.3, 0.1)
			box.mesh.material = mat
			box.position.y = 0.3
			add_child(box)

func _create_workbench_visual() -> void:
	"""工作台：桌面 + 四条腿"""
	# 桌面
	var top = MeshInstance3D.new()
	top.mesh = BoxMesh.new()
	top.mesh.size = Vector3(1.2, 0.1, 0.8)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.4, 0.2)
	top.mesh.material = mat
	top.position.y = 0.55
	add_child(top)
	
	# 四条腿
	for pos in [Vector3(-0.45, 0.15, -0.3), Vector3(0.45, 0.15, -0.3), Vector3(-0.45, 0.15, 0.3), Vector3(0.45, 0.15, 0.3)]:
		var leg = MeshInstance3D.new()
		leg.mesh = CylinderMesh.new()
		leg.mesh.top_radius = 0.04
		leg.mesh.bottom_radius = 0.04
		leg.mesh.height = 0.5
		var leg_mat = StandardMaterial3D.new()
		leg_mat.albedo_color = Color(0.4, 0.25, 0.1)
		leg.mesh.material = leg_mat
		leg.position = pos
		add_child(leg)
	
	# 工作台上小物件（工具）
	var tool = MeshInstance3D.new()
	tool.mesh = BoxMesh.new()
	tool.mesh.size = Vector3(0.3, 0.02, 0.05)
	var tool_mat = StandardMaterial3D.new()
	tool_mat.albedo_color = Color(0.7, 0.7, 0.7)
	tool.mesh.material = tool_mat
	tool.position = Vector3(0.2, 0.6, 0.15)
	tool.rotation_degrees.z = 15.0
	add_child(tool)
	
	# 头顶标识名（使用Label3D）
	var label = Label3D.new()
	label.text = station_name
	label.font_size = 12
	label.pixel_size = 0.01
	label.modulate = Color(1, 1, 0.8, 0.9)
	label.position = Vector3(0, 1.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func _create_furnace_visual() -> void:
	"""熔炉：底部圆筒+顶部火焰"""
	var base = MeshInstance3D.new()
	base.mesh = CylinderMesh.new()
	base.mesh.top_radius = 0.35
	base.mesh.bottom_radius = 0.4
	base.mesh.height = 0.7
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.2, 0.15)
	mat.metallic = 0.2
	base.mesh.material = mat
	base.position.y = 0.35
	add_child(base)
	
	# 顶部火焰（橙色半透明）
	var flame = MeshInstance3D.new()
	flame.mesh = SphereMesh.new()
	flame.mesh.radius = 0.12
	flame.mesh.height = 0.25
	var flame_mat = StandardMaterial3D.new()
	flame_mat.albedo_color = Color(1.0, 0.4, 0.0, 0.6)
	flame_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flame_mat.emission = Color(1.0, 0.5, 0.0)
	flame_mat.emission_energy_multiplier = 1.5
	flame.mesh.material = flame_mat
	flame.position = Vector3(0, 0.75, 0)
	add_child(flame)
	
	var label = Label3D.new()
	label.text = station_name
	label.font_size = 12
	label.pixel_size = 0.01
	label.modulate = Color(1, 0.7, 0.3, 0.9)
	label.position = Vector3(0, 1.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func _create_anvil_visual() -> void:
	"""铁砧"""
	var body = MeshInstance3D.new()
	body.mesh = BoxMesh.new()
	body.mesh.size = Vector3(0.5, 0.4, 0.3)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.4, 0.45)
	mat.metallic = 0.5
	mat.roughness = 0.4
	body.mesh.material = mat
	body.position.y = 0.2
	add_child(body)
	
	var top = MeshInstance3D.new()
	top.mesh = BoxMesh.new()
	top.mesh.size = Vector3(0.6, 0.1, 0.2)
	var top_mat = StandardMaterial3D.new()
	top_mat.albedo_color = Color(0.3, 0.3, 0.35)
	top_mat.metallic = 0.6
	top_mat.roughness = 0.3
	top.mesh.material = top_mat
	top.position = Vector3(0, 0.45, 0)
	add_child(top)
	
	var label = Label3D.new()
	label.text = station_name
	label.font_size = 12
	label.pixel_size = 0.01
	label.modulate = Color(0.8, 0.8, 0.9, 0.9)
	label.position = Vector3(0, 0.9, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func _create_alchemy_visual() -> void:
	"""炼丹炉：三足鼎"""
	var body = MeshInstance3D.new()
	body.mesh = SphereMesh.new()
	body.mesh.radius = 0.25
	body.mesh.height = 0.4
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.5, 0.2)
	mat.metallic = 0.3
	body.mesh.material = mat
	body.position.y = 0.3
	add_child(body)
	
	# 三足
	for i in range(3):
		var leg = MeshInstance3D.new()
		leg.mesh = CylinderMesh.new()
		leg.mesh.top_radius = 0.03
		leg.mesh.bottom_radius = 0.04
		leg.mesh.height = 0.15
		var leg_mat = StandardMaterial3D.new()
		leg_mat.albedo_color = Color(0.4, 0.35, 0.15)
		leg.mesh.material = leg_mat
		var angle = i * 2.0 * PI / 3.0
		leg.position = Vector3(cos(angle) * 0.18, 0.08, sin(angle) * 0.18)
		add_child(leg)
	
	# 烟雾粒子
	var smoke = MeshInstance3D.new()
	smoke.mesh = SphereMesh.new()
	smoke.mesh.radius = 0.06
	smoke.mesh.height = 0.1
	var smoke_mat = StandardMaterial3D.new()
	smoke_mat.albedo_color = Color(0.8, 0.7, 0.5, 0.3)
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke.mesh.material = smoke_mat
	smoke.position = Vector3(0, 0.55, 0)
	add_child(smoke)
	
	var label = Label3D.new()
	label.text = station_name
	label.font_size = 12
	label.pixel_size = 0.01
	label.modulate = Color(0.6, 0.9, 0.4, 0.9)
	label.position = Vector3(0, 0.9, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func _create_loom_visual() -> void:
	"""织布机"""
	var frame = MeshInstance3D.new()
	frame.mesh = BoxMesh.new()
	frame.mesh.size = Vector3(0.6, 0.8, 0.3)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.35, 0.2)
	frame.mesh.material = mat
	frame.position.y = 0.4
	add_child(frame)
	
	var cloth = MeshInstance3D.new()
	cloth.mesh = BoxMesh.new()
	cloth.mesh.size = Vector3(0.4, 0.3, 0.02)
	var cloth_mat = StandardMaterial3D.new()
	cloth_mat.albedo_color = Color(0.9, 0.85, 0.8)
	cloth.mesh.material = cloth_mat
	cloth.position = Vector3(0, 0.5, 0.16)
	add_child(cloth)
	
	var label = Label3D.new()
	label.text = station_name
	label.font_size = 12
	label.pixel_size = 0.01
	label.modulate = Color(0.9, 0.8, 0.6, 0.9)
	label.position = Vector3(0, 1.1, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func _create_rune_visual() -> void:
	"""符文台"""
	var base = MeshInstance3D.new()
	base.mesh = CylinderMesh.new()
	base.mesh.top_radius = 0.3
	base.mesh.bottom_radius = 0.35
	base.mesh.height = 0.2
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.15, 0.3)
	mat.metallic = 0.4
	base.mesh.material = mat
	base.position.y = 0.1
	add_child(base)
	
	# 符文光效
	var rune = MeshInstance3D.new()
	rune.mesh = BoxMesh.new()
	rune.mesh.size = Vector3(0.15, 0.02, 0.15)
	var rune_mat = StandardMaterial3D.new()
	rune_mat.albedo_color = Color(0.5, 0.2, 1.0, 0.7)
	rune_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rune_mat.emission = Color(0.5, 0.2, 1.0)
	rune_mat.emission_energy_multiplier = 1.0
	rune.mesh.material = rune_mat
	rune.position = Vector3(0, 0.2, 0)
	add_child(rune)
	
	var label = Label3D.new()
	label.text = station_name
	label.font_size = 12
	label.pixel_size = 0.01
	label.modulate = Color(0.7, 0.4, 1.0, 0.9)
	label.position = Vector3(0, 0.7, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func _create_soul_forge_visual() -> void:
	"""魂器锻造台 — 灵韵环绕的锻台"""
	# 底座
	var base = MeshInstance3D.new()
	base.mesh = BoxMesh.new()
	base.mesh.size = Vector3(1.0, 0.3, 1.0)
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.15, 0.1, 0.2)
	base_mat.metallic = 0.6
	base_mat.roughness = 0.4
	base.mesh.material = base_mat
	base.position.y = 0.15
	add_child(base)
	
	# 台面 — 深色石板
	var slab = MeshInstance3D.new()
	slab.mesh = CylinderMesh.new()
	slab.mesh.top_radius = 0.35
	slab.mesh.bottom_radius = 0.4
	slab.mesh.height = 0.08
	var slab_mat = StandardMaterial3D.new()
	slab_mat.albedo_color = Color(0.25, 0.2, 0.35)
	slab_mat.metallic = 0.5
	slab_mat.roughness = 0.3
	slab.mesh.material = slab_mat
	slab.position.y = 0.3
	add_child(slab)
	
	# 灵韵光环 — 旋转能量环
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.3, 0.6, 1.0, 0.6)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.emission = Color(0.3, 0.6, 1.0)
	ring_mat.emission_energy_multiplier = 2.0
	
	for i in range(3):
		var ring = MeshInstance3D.new()
		ring.mesh = TorusMesh.new()
		ring.mesh.inner_radius = 0.25
		ring.mesh.outer_radius = 0.32
		ring.mesh.material = ring_mat
		ring.position.y = 0.08 + i * 0.04
		ring.rotation.x = deg_to_rad(10)
		ring.rotation.y = deg_to_rad(i * 120)
		add_child(ring)
	
	# 标签
	var label = Label3D.new()
	label.text = station_name
	label.font_size = 12
	label.pixel_size = 0.01
	label.modulate = Color(0.3, 0.6, 1.0, 0.9)
	label.position = Vector3(0, 0.8, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

# ==================== 触发检测 ====================

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		var station_id = STATION_NAMES.get(station_type, "workbench")
		if _crafting_system and _crafting_system.has_method("enter_station_range"):
			_crafting_system.enter_station_range(station_id)
		print("🔧 进入 %s 范围" % station_name)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		var station_id = STATION_NAMES.get(station_type, "workbench")
		if _crafting_system and _crafting_system.has_method("leave_station_range"):
			_crafting_system.leave_station_range(station_id)
		print("🔧 离开 %s 范围" % station_name)

# ==================== 交互（可选） ====================

func interact() -> void:
	"""与工作站交互（打开对应合成面板）"""
	if not _player_nearby:
		return
	
	var ui = get_node("/root/UIManager") if has_node("/root/UIManager") else null
	if ui:
		if station_type == StationType.SOUL_FORGE:
			# 🆕 魂器锻造台 → 直接打开魂器面板
			ui.focus_station(station_type)
		else:
			# 打开合成面板并聚焦此工作站
			ui.toggle_panel("crafting")
			ui.focus_station(station_type)
