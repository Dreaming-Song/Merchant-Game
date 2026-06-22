extends StaticBody3D
## 可采集资源节点 — 树木/矿石/草药
##
## 使用方法：
##   1. 挂载到 StaticBody3D（带 CollisionShape3D）
##   2. 设置 resource_id 和资源属性
##   3. InteractionDetector 自动识别为 "gatherable"
##   4. 采集后自动消失，按 respawn_time 刷新

class_name ResourceNode

signal gathered(resource_id: String, count: int)
signal respawned()

# ==================== 可配置属性 ====================
@export var resource_id: String = "wood"           # 物品ID（对应 ItemDatabase）
@export var resource_name: String = "木材"          # 显示名称
@export var gather_count: int = 1                  # 每次采集数量
@export var max_gathers: int = 3                   # 最大采集次数（-1=无限）
@export var respawn_time: float = 30.0             # 刷新时间（秒）
@export var required_tool: String = ""             # 需要的工具类型（空=徒手）
@export var required_tier: int = 0                 # 需要的工具等级
@export var gather_animation: String = "chop"      # 采集动画名
@export var destroy_on_empty: bool = true          # 采空后消失
@export var min_distance: float = 1.5              # 最小交互距离

# ==================== 内部状态 ====================
var current_gathers: int = 0
var is_depleted: bool = false
var is_respawning: bool = false
var original_position: Vector3
var original_scale: Vector3
var original_visible: bool = true

# 视觉效果
var _mesh_instance: MeshInstance3D = null
var _particles: GPUParticles3D = null

func _ready() -> void:
	add_to_group("resources")
	original_position = global_position
	original_scale = scale
	current_gathers = max_gathers
	
	# 使用 ResourceVisuals 生成视觉
	_mesh_instance = ResourceVisuals.create_visual(resource_id, self)
	
	# 添加闲置动画
	ResourceVisuals.add_idle_animation(self, resource_id)
	
	# 添加采集粒子
	ResourceVisuals.add_gather_particles(self, resource_id)
	
	# 获取粒子引用
	_particles = get_meta("_gather_particles", null) if has_meta("_gather_particles") else null
	
	# 如果没有 ResourceVisuals 匹配，回退到手动查找 MeshInstance
	if not _mesh_instance:
		_mesh_instance = get_node_or_null("MeshInstance3D") if has_node("MeshInstance3D") else null
		if not _mesh_instance:
			_mesh_instance = get_child(0) if get_child_count() > 0 and get_child(0) is MeshInstance3D else null

# ==================== 采集接口 ====================

func gather(player: Node) -> void:
	"""供 InteractionDetector / PlayerController 调用"""
	if is_depleted or is_respawning:
		return
	
	var gm = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	if not gm or not gm.has_method("gather_resource"):
		return
	
	# 检查距离
	if player and player.global_position.distance_to(global_position) > min_distance + 2.0:
		print("⚠️ 太远了，靠近一点再采集")
		return
	
	# 执行采集
	gm.gather_resource(resource_id, gather_count)
	gathered.emit(resource_id, gather_count)
	
	# 采集特效
	_play_gather_effect()
	
	# 计数
	if max_gathers > 0:
		current_gathers -= 1
		if current_gathers <= 0:
			_deplete()

## 视觉反馈 — 采集特效
func _play_gather_effect() -> void:
	# 缩放动画（闪烁一下）
	var tween = create_tween()
	tween.tween_property(self, "scale", original_scale * 1.2, 0.1)
	tween.tween_property(self, "scale", original_scale, 0.15)
	
	# 如果有粒子系统，播放
	if _particles and _particles.has_method("restart"):
		_particles.restart()
	elif _mesh_instance:
		# 简单变白闪烁
		var orig_modulate = _mesh_instance.modulate if _mesh_instance.has_method("get_modulate") else Color.WHITE
		var tween2 = create_tween()
		tween2.tween_property(_mesh_instance, "modulate", Color(1, 1, 0.5), 0.1)
		tween2.tween_property(_mesh_instance, "modulate", orig_modulate, 0.2)

## 资源耗尽
func _deplete() -> void:
	is_depleted = true
	
	if destroy_on_empty:
		# 淡出消失
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
		tween.tween_callback(_start_respawn)
	else:
		_start_respawn()

## 开始重生计时
func _start_respawn() -> void:
	is_respawning = true
	visible = false
	# 禁用碰撞
	collision_layer = 0
	collision_mask = 0
	
	await get_tree().create_timer(respawn_time).timeout
	_respawn()

## 重生
func _respawn() -> void:
	is_depleted = false
	is_respawning = false
	current_gathers = max_gathers
	scale = original_scale
	visible = true
	collision_layer = 1
	collision_mask = 1
	
	# 重生特效
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.0)
	tween.tween_property(self, "scale", original_scale, 0.3)
	
	respawned.emit(resource_id)

# ==================== HUD 交互提示 ====================

func get_hint_name() -> String:
	return resource_name

func get_resource_type() -> String:
	return resource_id
