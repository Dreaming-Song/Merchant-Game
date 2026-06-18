extends RigidBody3D
## 可交互树木 - Phase 1
## 玩家挥剑砍击 → 树木物理倒下 → 掉落木材

# ---------- 可配置参数 ----------
@export var tree_name: String = "竹"
@export var health: int = 3                     # 需要砍几下
@export var wood_drop_count: int = 2            # 掉落木材数量
@export var drop_scene: PackedFileSystem        # 掉落物预制体
@export var fall_impulse_strength: float = 5.0  # 击倒力度

# ---------- 内部状态 ----------
var is_fallen: bool = false
var original_transform: Transform3D

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	original_transform = global_transform
	# 初始锁死，只有被砍才激活物理
	freeze = true

func hit(damage: int = 1) -> void:
	"""玩家挥剑击中时调用"""
	if is_fallen:
		return

	health -= damage
	if health <= 0:
		fall_down()
	else:
		# 小幅度震动反馈
		apply_impulse(Vector3.UP * 0.5, global_position)

func fall_down() -> void:
	"""树木倒下"""
	is_fallen = true
	freeze = false  # 激活物理

	# 朝玩家方向施加推力
	var impulse_dir: Vector3 = Vector3(
		randf_range(-1.0, 1.0),
		0.3,
		randf_range(-1.0, 1.0)
	).normalized()
	apply_impulse(impulse_dir * fall_impulse_strength, global_position)

	# 掉落木材
	spawn_drops()

	# TODO: 播放树木倒下音效 + 粒子特效

	# 自动销毁（一段时间后）
	await get_tree().create_timer(10.0).timeout
	queue_free()

func spawn_drops() -> void:
	"""生成掉落物"""
	if drop_scene == null:
		return
	for i in range(wood_drop_count):
		var drop = drop_scene.instantiate()
		get_tree().current_scene.add_child(drop)
		drop.global_position = global_position + Vector3(
			randf_range(-1.0, 1.0),
			1.0,
			randf_range(-1.0, 1.0)
		)

func regenerate() -> void:
	"""重置树木（用于测试/读档）"""
	is_fallen = false
	health = 3
	freeze = true
	global_transform = original_transform
