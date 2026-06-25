extends StaticBody3D
class_name ResourceNode

## 可采集资源节点 — 树木/矿石/草药

const ResourceVisuals = preload("res://scripts/entities/resource_visuals.gd")

signal gathered(resource_id: String, count: int)
signal respawned()
# 🔧 新增：采集进度信号
signal gathering_progress(ratio: float)
signal gathering_started(total_time: float)
signal gathering_cancelled()
signal gathering_completed()

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
# 🔧 新增：采集耗时（秒），0=瞬间
@export var gather_time: float = 2.0

# ==================== 内部状态 ====================
var current_gathers: int = 0
var is_depleted: bool = false
var is_respawning: bool = false
var original_position: Vector3
var original_scale: Vector3
var original_visible: bool = true

# 🔧 新增：采集状态
var is_gathering: bool = false
var _gathering_player: Node = null
var _gather_timer: float = 0.0
var _gather_start_dist: float = 0.0

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

func _process(delta: float) -> void:
	# 🔧 新增：采集进度更新 & 距离检测
	if is_gathering and _gathering_player:
		# 玩家走远了就取消
		var dist = _gathering_player.global_position.distance_to(global_position)
		if dist > min_distance + 3.0:
			_cancel_gather()
			return
		
		_gather_timer += delta
		var progress = min(_gather_timer / gather_time, 1.0)
		gathering_progress.emit(progress)
		
		if _gather_timer >= gather_time:
			_complete_gather()

# ==================== 采集接口 ====================

func gather(player: Node) -> void:
	"""供 InteractionDetector / PlayerController 调用"""
	if is_depleted or is_respawning:
		return
	
	# 🔧 如果已经在采这个资源，不要重复触发
	if is_gathering:
		return
	
	# 检查距离
	if player and player.global_position.distance_to(global_position) > min_distance + 2.0:
		print("⚠️ 太远了，靠近一点再采集")
		return
	
	# 🔧 如果 gather_time > 0，进入采集进度模式
	if gather_time > 0.0:
		is_gathering = true
		_gathering_player = player
		_gather_timer = 0.0
		_gather_start_dist = player.global_position.distance_to(global_position)
		gathering_started.emit(gather_time)
		# 开始采集动画
		_play_gather_anim_start()
		return
	
	# 🔧 gather_time <= 0 走原来的瞬间采集
	_do_instant_gather(player)

## 🔧 立即采集（无进度条）
func _do_instant_gather(player: Node) -> void:
	var gm = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	if not gm or not gm.has_method("gather_resource"):
		return
	
	gm.gather_resource(resource_id, gather_count)
	gathered.emit(resource_id, gather_count)
	
	# 采集特效
	_play_gather_effect()
	
	# 计数
	if max_gathers > 0:
		current_gathers -= 1
		if current_gathers <= 0:
			_deplete()

## 🔧 完成采集（进度条走完）
func _complete_gather() -> void:
	if not is_gathering:
		return
	
	is_gathering = false
	_gathering_player = null
	
	var gm = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	if not gm or not gm.has_method("gather_resource"):
		gathering_cancelled.emit()
		return
	
	gm.gather_resource(resource_id, gather_count)
	gathered.emit(resource_id, gather_count)
	gathering_completed.emit()
	
	# 采集特效
	_play_gather_effect()
	
	# 计数
	if max_gathers > 0:
		current_gathers -= 1
		if current_gathers <= 0:
			_deplete()

## 🔧 取消采集
func _cancel_gather() -> void:
	if not is_gathering:
		return
	is_gathering = false
	_gathering_player = null
	_gather_timer = 0.0
	_play_gather_anim_cancel()
	gathering_cancelled.emit()

## 🔧 是否可以继续采集（用于外部检查）
func can_gather() -> bool:
	return not is_gathering and not is_depleted and not is_respawning

func _play_gather_anim_start() -> void:
	"""采集开始动画 — 简单闪烁"""
	var tween = create_tween()
	tween.tween_property(self, "scale", original_scale * 1.05, 0.2)

func _play_gather_anim_cancel() -> void:
	"""采集取消动画 — 恢复原状"""
	var tween = create_tween()
	tween.tween_property(self, "scale", original_scale, 0.1)

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
