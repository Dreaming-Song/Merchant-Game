extends Node3D
## 联机玩家同步体 - Phase 3
## 显示其他玩家的位置/动作（非本地玩家的替身）

signal sync_ready

# ---------- 外观 ----------
@export var player_mesh: PackedScene  # 玩家模型
@export var label_3d: PackedScene     # 头顶名字标签

# ---------- 同步状态 ----------
var synced_player_id: String = ""
var display_name: String = ""

# 插值缓存
var _target_pos: Vector3 = Vector3.ZERO
var _target_rot: Vector3 = Vector3.ZERO
var _lerp_speed: float = 10.0

@onready var mesh_instance: Node3D = $MeshInstance
@onready var name_label: Label3D = $NameLabel

func _ready() -> void:
	_target_pos = global_position

func _physics_process(delta: float) -> void:
	# 插值到目标位置
	global_position = global_position.lerp(_target_pos, _lerp_speed * delta)
	rotation.y = lerp_angle(rotation.y, _target_rot.y, _lerp_speed * delta)

func apply_state(state: Dictionary) -> void:
	"""应用服务端同步过来的玩家状态"""
	_target_pos = Vector3(state.get("x", 0), state.get("y", 0), state.get("z", 0))
	_target_rot = Vector3(0, state.get("rot_y", 0), 0)

	# TODO: 根据 is_flying 切换飞行/地面动画
	# TODO: 同步 HP 显示血条

func set_display_name(name: String) -> void:
	display_name = name
	if name_label:
		name_label.text = name

func _on_sync_ready() -> void:
	sync_ready.emit()
