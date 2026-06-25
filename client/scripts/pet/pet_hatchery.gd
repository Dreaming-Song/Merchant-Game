extends Node3D
## 🥚 灵宠孵化台 — 放置在家园的孵化装置
##
## 功能：
## - 放入宠物蛋 + 孵化材料 → 开始孵化
## - 孵化需要真实时间（或游戏天数）
## - 孵化完成后召唤对应灵宠
## - 神兽蛋孵化需要额外条件（流派等级）

class_name PetHatchery

signal hatching_started(pet_type: String, pet_name: String, finish_time: float)
signal hatch_complete(pet_type: String, pet_name: String)
signal hatch_cancelled(pet_type: String, pet_name: String)

# ==================== 配置 ====================
## 孵化所需时间（秒），可改为游戏天数
const HATCH_BASE_TIME: Dictionary = {
	"crane": 60,           # 仙鹤1分钟
	"fox": 60,             # 灵狐1分钟
	"panda": 120,          # 竹熊2分钟
	"pixiu": 300,          # 貔貅5分钟
	"azure_dragon": 600,   # 青龙10分钟
	"white_tiger": 600,    # 白虎10分钟
	"vermilion_bird": 600, # 朱雀10分钟
	"black_warrior": 600,  # 玄武10分钟
	"golden_qilin": 900,   # 麒麟15分钟
}

## 孵化所需材料
const HATCH_MATERIALS: Dictionary = {
	"crane": {"灵泉水": 5, "木材": 10},
	"fox": {"灵泉水": 5, "灵草": 5},
	"panda": {"竹笋": 10, "木材": 20},
	"pixiu": {"灵泉水": 20, "灵石": 10, "金灵珠": 1},
	"azure_dragon": {"木灵珠": 1, "青龙鳞": 3, "灵石": 20},
	"white_tiger": {"金灵珠": 1, "白虎牙": 3, "灵石": 20},
	"vermilion_bird": {"火灵珠": 1, "朱雀羽": 3, "灵石": 20},
	"black_warrior": {"水灵珠": 1, "玄武甲": 3, "灵石": 20},
	"golden_qilin": {"土灵珠": 1, "麒麟角": 3, "灵石": 50, "金灵珠": 1},
}

## 神兽蛋需要的流派等级
const GOD_BEAST_SCHOOL_LEVEL: int = 20

# ==================== 状态 ====================
var _active_hatch: Dictionary = {}  # 当前正在孵化的蛋
var _slot_count: int = 2            # 初始孵化槽位
var _slots: Array = []              # [{pet_type, pet_name, finish_time, progress}]

var _timer: Timer

func _ready() -> void:
	_timer = Timer.new()
	_timer.timeout.connect(_on_tick)
	_timer.wait_time = 1.0
	_timer.one_shot = false
	add_child(_timer)
	
	add_to_group("hatchery")
	print("🥚 孵化台就绪，%d个孵化槽" % _slot_count)

# ==================== 核心API ====================

## 开始孵化
## egg_item_data = {"pet_type": "crane", "name": "仙鹤蛋"}
## materials = {"灵泉水": 5, "木材": 10} 玩家背包中的材料
## 返回 {success, reason}
func start_hatching(slot: int, egg_item_data: Dictionary, inventory) -> Dictionary:
	if slot < 0 or slot >= _slot_count:
		return {"success": false, "reason": "无效孵化槽"}
	if slot < _slots.size() and _slots[slot].get("active") or false:
		return {"success": false, "reason": "该槽位正在孵化"}
	
	var pet_type = egg_item_data.get("pet_type") or ""
	if pet_type.is_empty():
		return {"success": false, "reason": "无效的蛋"}
	
	# 检查流派等级（神兽需要）
	var is_god_beast = pet_type in ["azure_dragon", "white_tiger", "vermilion_bird", "black_warrior", "golden_qilin"]
	if is_god_beast:
		var cult = _get_cultivation()
		if cult:
			# 需要对应流派等级≥20
			var school_level = cult.get("gongfa_unlocked_count") or 0 * 5
			if school_level < GOD_BEAST_SCHOOL_LEVEL:
				return {"success": false, "reason": "神兽蛋需要流派等级≥20才可孵化"}
	
	# 检查材料
	var materials = HATCH_MATERIALS.get(pet_type, {})
	var missing = []
	for mat_id in materials:
		if not inventory or inventory.get_item_count(mat_id) < materials[mat_id]:
			missing.append(mat_id)
	if not missing.is_empty():
		return {"success": false, "reason": "缺少材料: " + ", ".join(missing)}
	
	# 扣除材料
	for mat_id in materials:
		if inventory:
			inventory.remove_item(mat_id, materials[mat_id])
	
	# 开始孵化
	var hatch_time = HATCH_BASE_TIME.get(pet_type, 120.0)
	var finish_time = Time.get_ticks_sec() + hatch_time
	
	while _slots.size() <= slot:
		_slots.append({"active": false})
	
	_slots[slot] = {
		"active": true,
		"pet_type": pet_type,
		"pet_name": _get_pet_default_name(pet_type),
		"finish_time": finish_time,
		"total_time": hatch_time,
		"progress": 0.0,
	}
	
	if not _timer.is_processing():
		_timer.start()
	
	hatching_started.emit(pet_type, _slots[slot]["pet_name"], finish_time)
	print("🥚 开始孵化 %s！剩余 %.0f秒" % [_slots[slot]["pet_name"], hatch_time])
	return {"success": true}

## 取出已孵化的宠物
func collect_hatch(slot: int) -> Dictionary:
	if slot >= _slots.size() or not _slots[slot].get("active") or false:
		return {"success": false, "reason": "该槽位没有孵化"}
	
	var hatch = _slots[slot]
	if Time.get_ticks_sec() < hatch.get("finish_time") or 0:
		return {"success": false, "reason": "孵化尚未完成"}
	
	# 创建宠物
	var pet = _spawn_pet(hatch["pet_type"], hatch["pet_name"])
	
	_slots[slot] = {"active": false}
	hatch_complete.emit(hatch["pet_type"], hatch["pet_name"])
	print("🐣 %s 孵化完成！" % hatch["pet_name"])
	
	return {"success": true, "pet": pet}

## 取消孵化（退还材料一半）
func cancel_hatch(slot: int, inventory) -> Dictionary:
	if slot >= _slots.size() or not _slots[slot].get("active") or false:
		return {"success": false, "reason": "该槽位没有孵化"}
	
	var hatch = _slots[slot]
	var pet_type = hatch["pet_type"]
	var materials = HATCH_MATERIALS.get(pet_type, {})
	
	# 退还一半材料
	for mat_id in materials:
		var half = max(1, materials[mat_id] / 2)
		if inventory:
			inventory.add_item(mat_id, half)
	
	_slots[slot] = {"active": false}
	hatch_cancelled.emit(pet_type, hatch["pet_name"])
	print("🥚 取消孵化 %s" % hatch["pet_name"])
	return {"success": true}

## 获取孵化进度
func get_slot_info(slot: int) -> Dictionary:
	if slot >= _slots.size():
		return {"active": false}
	
	var hatch = _slots[slot]
	if not hatch.get("active") or false:
		return {"active": false}
	
	var now = Time.get_ticks_sec()
	var finish = hatch.get("finish_time") or now
	var total = hatch.get("total_time") or 1.0
	var elapsed = total - max(finish - now, 0)
	var progress = clamp(elapsed / total, 0.0, 1.0)
	
	return {
		"active": true,
		"pet_type": hatch["pet_type"],
		"pet_name": hatch["pet_name"],
		"progress": progress,
		"remaining": max(finish - now, 0),
		"done": now >= finish,
	}

func get_all_slots() -> Array:
	var result = []
	for i in range(_slot_count):
		result.append(get_slot_info(i))
	return result

# ==================== 内部 ====================

func _on_tick() -> void:
	"""每秒检查孵化进度"""
	var all_done = true
	for i in range(_slot_count):
		if i < _slots.size() and _slots[i].get("active") or false:
			if Time.get_ticks_sec() >= _slots[i].get("finish_time") or 0:
				#print("🐣 槽%d 孵化完成！" % i)
				pass
			all_done = false
	
	# 没有活跃孵化时停止计时器
	if all_done:
		_timer.stop()

func _spawn_pet(pet_type: String, pet_name: String) -> Node:
	"""生成宠物实体在孵化台旁边"""
	var pet_scene = load("res://scenes/pets/" + pet_type + ".tscn")
	if not pet_scene:
		print("⚠️ 宠物场景不存在: " + pet_type)
		return null
	
	var pet = pet_scene.instantiate()
	pet.pet_name = pet_name
	pet.pet_type = PetTypeMap.get_type(pet_type)
	
	# 放到孵化台旁边
	var spawn_pos = global_position + Vector3(2, 0, 0)
	pet.global_position = spawn_pos
	get_tree().current_scene.add_child(pet)
	
	return pet

func _get_pet_default_name(pet_type: String) -> String:
	var names = {
		"crane": "小鹤", "fox": "小狐", "panda": "滚滚",
		"pixiu": "小貔", "azure_dragon": "小青",
		"white_tiger": "小白", "vermilion_bird": "小雀",
		"black_warrior": "小玄", "golden_qilin": "小麟",
	}
	return names.get(pet_type, "灵宠")

func _get_cultivation() -> Dictionary:
	"""获取修炼系统状态"""
	var gm = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	if gm and gm.has_method("get_cultivation"):
		return gm.get_cultivation()
	return {}

# ==================== 存档 ====================

func get_save_data() -> Dictionary:
	return {
		"slot_count": _slot_count,
		"slots": _slots.duplicate(),
	}

func load_save_data(data: Dictionary) -> void:
	_slot_count = data.get("slot_count") or 2
	_slots = data.get("slots") or []
	# 恢复计时器
	var has_active = false
	for slot in _slots:
		if slot.get("active") or false:
			has_active = true
			break
	if has_active:
		_timer.start()
