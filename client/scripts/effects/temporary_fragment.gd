extends Node3D
## 临时碎片节点：向指定方向飞出，一段时间后自动销毁

var _velocity: Vector3 = Vector3.ZERO
var _lifetime: float = 1.0
var _age: float = 0.0

func init(velocity: Vector3, lifetime: float = 1.0) -> void:
	_velocity = velocity
	_lifetime = lifetime

func _process(delta: float) -> void:
	_age += delta
	if _age >= _lifetime:
		queue_free()
		return
	
	# 简单弹道（重力 + 阻力）
	_velocity.y -= 9.8 * delta * 0.3  # 轻量化重力
	_velocity *= 0.98  # 阻力
	position += _velocity * delta
	
	# 自旋效果
	rotation.x += delta * randf_range(2.0, 5.0)
	rotation.y += delta * randf_range(-3.0, 3.0)
