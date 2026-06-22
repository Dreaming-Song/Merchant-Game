extends Node
## 仇恨系统 — 多人BOSS战的威胁值管理
##
## 每个玩家对BOSS造成伤害时增加威胁值
## BOSS选择威胁值最高的玩家作为目标
## 威胁值随时间缓慢衰减（防止永远拉不回来）

class_name ThreatSystem

var _threat_table: Dictionary = {}  # player_id → threat_value
var _boss: Node = null

func setup(boss: Node) -> void:
	_boss = boss

func add_threat(player_id: String, amount: int) -> void:
	_threat_table[player_id] = _threat_table.get(player_id, 0) + amount

func clear_threat(player_id: String) -> void:
	_threat_table.erase(player_id)

func clear_all() -> void:
	_threat_table.clear()

func get_top_threat() -> Dictionary:
	var top_id = ""
	var top_value = 0
	for pid in _threat_table.keys():
		if _threat_table[pid] > top_value:
			top_value = _threat_table[pid]
			top_id = pid
	return {"player_id": top_id, "threat": top_value}

func get_threat_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for pid in _threat_table.keys():
		list.append({"player_id": pid, "threat": _threat_table[pid]})
	list.sort_custom(func(a, b): return a.threat > b.threat)
	return list

func _process(delta: float) -> void:
	# 每秒 0.5% 衰减
	for pid in _threat_table.keys():
		_threat_table[pid] *= 0.995
		if _threat_table[pid] < 1:
			_threat_table.erase(pid)
