extends Node
class_name InventorySystem
## 背包系统 — 物品存储/管理/装备
##
## 功能：
## - 背包格子管理（可扩容）
## - 物品堆叠/拆分
## - 装备栏（武器/防具/工具/饰品/载具）
## - 物品使用/消耗
## - 工具耐久度
## - 存档
const ItemDatabase = preload("res://scripts/inventory/item_database.gd")
const CyclopediaSystem = preload("res://scripts/data/cyclopedia_system.gd")

# ==================== 信号 ====================
signal inventory_changed(slot_index: int, item_id: String, count: int)
signal item_added(item_id: String, count: int, slot_index: int)
signal item_removed(item_id: String, count: int)
signal item_used(item_id: String, slot_index: int)
signal equipment_changed(slot: String, item_id: String)
signal durability_changed(slot_index: int, durability: int, max_durability: int)
signal bag_expanded(new_slots: int)

# ==================== 背包配置 ====================
## 人物物品栏格子数（始终可用）
const PERSONAL_SLOT_COUNT: int = 8
var bag_slots: int = 24        # 总格子数（含人物栏）
var max_bag_slots: int = 120   # 最大格子数

# ==================== 背包数据 ====================
## slots: Array[Dictionary] 每个元素:
## {item_id: String, count: int, durability: int, soul_marked: bool}
## slots[0~7] = 人物物品栏（始终可用）
## slots[8+]  = 背包物品栏（仅当装备背包时可用）
var _slots: Array[Dictionary] = []

# ==================== 装备栏 ====================
## 装备槽位（与 item_database 中各物品的 slot 字段值对应）
## 注意：实际采用字符串 key 驱动，enum 值仅在 UI 中参考
enum EquipSlot {
	WEAPON,     # 武器（slot: "weapon"）
	TOOL,       # 工具（slot: "tool"）
	HELMET,     # 头盔（slot: "helmet"）
	ARMOR,      # 胸甲（slot: "armor"）
	LEGS,       # 护腿（slot: "legs"）
	BOOTS,      # 靴子（slot: "boots"）
	RING,       # 戒指（slot: "ring"）
	AMULET,     # 护符（slot: "amulet"）
	BELT,       # 腰带（slot: "belt"）
	BRACELET,   # 手镯（slot: "bracelet"）
	ACCESSORY1, # 饰品1（兼容旧版）
	ACCESSORY2, # 饰品2（兼容旧版）
	TRANSPORT,  # 载具
	BACKPACK,   # 🎒 背包（决定背包栏是否可用）
}
var _equipment: Dictionary = {}  # slot_name → item_id

# ==================== 魂器（灵魂印记） ====================
## 标记为魂器的物品 ID → true（该物品在死亡时保留）
var _soul_marked_items: Dictionary = {}
## 如果装备的背包本身是魂器 → 背包栏全部保留
var _backpack_soul_marked: bool = false

func _ready() -> void:
	# 初始化背包格子
	_resize_slots(bag_slots)

# ==================== 背包操作 ====================

## 添加物品到背包，自动堆叠到已有格子或新格子
## 返回实际添加数量
func add_item(item_id: String, count: int = 1) -> int:
	if count <= 0:
		return 0
	
	var item_data = ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return 0
	
	var remaining = count
	var stackable = ItemDatabase.is_stackable(item_id)
	var max_stack = ItemDatabase.get_max_stack(item_id)
	
	# 1. 先堆叠到已有格子
	if stackable:
		for i in range(_slots.size()):
			if _slots[i].item_id == item_id and _slots[i].count < max_stack:
				var space = max_stack - _slots[i].count
				var to_add = min(remaining, space)
				_slots[i].count += to_add
				remaining -= to_add
				inventory_changed.emit(i, item_id, _slots[i].count)
				item_added.emit(item_id, to_add, i)
				if remaining <= 0:
					return count
	
	# 2. 放入空格
	while remaining > 0:
		var empty_idx = _find_empty_slot()
		if empty_idx == -1:
			print("⚠️ 背包已满！%s × %d 无法全部放入" % [item_data.get("name", "?"), remaining])
			break
		
		var to_add = min(remaining, max_stack)
		_slots[empty_idx] = {"item_id": item_id, "count": to_add, "durability": -1}
		
		# 设置耐久度
		if item_data.has("durability"):
			_slots[empty_idx].durability = item_data.get("durability", 1)
		
		remaining -= to_add
		inventory_changed.emit(empty_idx, item_id, to_add)
		item_added.emit(item_id, to_add, empty_idx)
	
	return count - remaining

## 从背包移除物品
func remove_item(item_id: String, count: int = 1) -> bool:
	var total = get_item_count(item_id)
	if total < count:
		return false
	
	var remaining = count
	for i in range(_slots.size()):
		if _slots[i].item_id == item_id:
			var to_remove = min(remaining, _slots[i].count)
			_slots[i].count -= to_remove
			remaining -= to_remove
			
			if _slots[i].count <= 0:
				_slots[i] = {"item_id": "", "count": 0, "durability": -1}
			
			inventory_changed.emit(i, _slots[i].item_id, _slots[i].count)
			item_removed.emit(item_id, to_remove)
			
			if remaining <= 0:
				return true
	
	return true

## 检查是否有足够的物品
func has_item(item_id: String, count: int = 1) -> bool:
	return get_item_count(item_id) >= count

## 获取物品总数量
func get_item_count(item_id: String) -> int:
	var total = 0
	for slot in _slots:
		if slot.get("item_id", "") == item_id:
			total += slot.get("count", 0)
	return total

## 获取指定格子的物品
func get_slot(index: int) -> Dictionary:
	if index < 0 or index >= _slots.size():
		return {}
	return _slots[index]  # 返回引用（允许修改 soul_durability 等字段）

## 获取总格子数
func get_slot_count() -> int:
	return _slots.size()

## 获取已装备的某槽位物品 ID
func get_equipped_item(equip_slot: String) -> String:
	return _equipment.get(equip_slot, "")

## 查找某物品在背包中的第一个格子索引
func find_item_slot(item_id: String) -> int:
	for i in range(_slots.size()):
		if _slots[i].item_id == item_id and _slots[i].count > 0:
			return i
	return -1

## 检查是否装备了背包
func is_backpack_equipped() -> bool:
	return _equipment.get("backpack") or "" != ""

## 交换两个格子
func swap_slots(from_idx: int, to_idx: int) -> void:
	if from_idx < 0 or from_idx >= _slots.size():
		return
	if to_idx < 0 or to_idx >= _slots.size():
		return
	
	var temp = _slots[from_idx].duplicate(true)
	_slots[from_idx] = _slots[to_idx].duplicate(true)
	_slots[to_idx] = temp
	
	inventory_changed.emit(from_idx, _slots[from_idx].item_id, _slots[from_idx].count)
	inventory_changed.emit(to_idx, _slots[to_idx].item_id, _slots[to_idx].count)

## 拆分堆叠（从 from_idx 分出 count 个到 to_idx）
func split_stack(from_idx: int, count: int) -> bool:
	if from_idx < 0 or from_idx >= _slots.size():
		return false
	if not ItemDatabase.is_stackable(_slots[from_idx].item_id):
		return false
	
	var from_slot = _slots[from_idx]
	if from_slot.get("count", 0) <= count:
		return false
	
	var to_idx = _find_empty_slot()
	if to_idx == -1:
		return false
	
	from_slot["count"] = from_slot.get("count", 0) - count
	_slots[to_idx] = {"item_id": from_slot.get("item_id", ""), "count": count, "durability": from_slot.get("durability", 0)}
	
	inventory_changed.emit(from_idx, from_slot.get("item_id", ""), from_slot.get("count", 0))
	inventory_changed.emit(to_idx, from_slot.get("item_id", ""), count)
	return true

## 丢弃物品
func drop_item(slot_index: int, count: int = 1) -> bool:
	if slot_index < 0 or slot_index >= _slots.size():
		return false
	if _slots[slot_index].item_id.is_empty():
		return false
	
	var to_remove = min(count, _slots[slot_index].count)
	_slots[slot_index].count -= to_remove
	item_removed.emit(_slots[slot_index].item_id, to_remove)
	
	if _slots[slot_index].count <= 0:
		var empty = {"item_id": "", "count": 0, "durability": -1}
		_slots[slot_index] = empty
	
	inventory_changed.emit(slot_index, _slots[slot_index].item_id, _slots[slot_index].count)
	return true

# ==================== 物品使用 ====================

## 使用物品
func use_item(slot_index: int, target: Node = null) -> Dictionary:
	if slot_index < 0 or slot_index >= _slots.size():
		return {"success": false, "reason": "无效格子"}
	
	var slot = _slots[slot_index]
	if slot.get("item_id", "").is_empty():
		return {"success": false, "reason": "没有物品"}
	
	var item_data = ItemDatabase.get_item(slot.get("item_id", ""))
	if not item_data.get("usable") or false:
		return {"success": false, "reason": "该物品无法使用"}
	
	var effects = item_data.get("use_effect", {})
	
	# 消耗物品
	remove_item(slot.get("item_id", ""), 1)
	item_used.emit(slot.get("item_id", ""), slot_index)
	
	return {"success": true, "effects": effects}

## 使用工具耐久度
func use_durability(slot_index: int, amount: int = 1) -> void:
	if slot_index < 0 or slot_index >= _slots.size():
		return
	
	var slot = _slots[slot_index]
	var item_id = slot.get("item_id", "")
	if item_id.is_empty():
		return
	
	# 🆕 魂器走魂器耐久系统
	if is_soul_marked(item_id):
		var sfs = get_node_or_null("/root/SoulForgeSystem")
		if sfs:
			sfs.use_soul_durability(slot_index, amount * 10.0)  # 换算为魂器耐久消耗
		return
	
	# 普通耐久逻辑
	if slot.get("durability", 0) <= 0:
		return
	
	slot["durability"] = slot.get("durability", 0) - amount
	durability_changed.emit(slot_index, slot.get("durability", 0), 
		ItemDatabase.get_item(item_id).get("durability") or 1)
	
	# 耐久耗尽 → 触发老伙计判定
	if slot.get("durability", 0) <= 0:
		var sfs = get_node_or_null("/root/SoulForgeSystem")
		if sfs and sfs.has_method("on_durability_depleted"):
			sfs.on_durability_depleted(slot_index, item_id)
		
		# 正常销毁（SoulForgeSystem 如果觉醒会恢复物品，所以先执行销毁前检测）
		if not is_soul_marked(item_id):
			_slots[slot_index] = {"item_id": "", "count": 0, "durability": -1}
			inventory_changed.emit(slot_index, "", 0)
			print("💔 工具损坏！")

# ==================== 装备系统 ====================

## 装备物品
func equip_item(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= _slots.size():
		return false
	
	var slot = _slots[slot_index]
	var item_data = ItemDatabase.get_item(slot.get("item_id", ""))
	if not item_data.get("equippable") or false:
		return false
	
	var equip_slot = item_data.get("slot") or ""
	if equip_slot.is_empty():
		return false
	
	# 如果该装备槽已有物品，先卸下
	if _equipment.has(equip_slot):
		var old_item = _equipment[equip_slot]
		add_item(old_item, 1)
	
	# 装备新物品
	_equipment[equip_slot] = slot.get("item_id", "")
	remove_item(slot.get("item_id", ""), 1)
	
	equipment_changed.emit(equip_slot, slot.get("item_id", ""))
	print("⚔️ 装备 %s 到 %s 槽" % [item_data.get("name", "?"), equip_slot])
	return true

## 卸下装备
func unequip_item(equip_slot: String) -> bool:
	if not _equipment.has(equip_slot):
		return false
	
	var item_id = _equipment[equip_slot]
	_equipment.erase(equip_slot)
	
	# 放入背包
	var added = add_item(item_id, 1)
	if added == 0:
		# 背包满了，暂时保留装备
		_equipment[equip_slot] = item_id
		return false
	
	equipment_changed.emit(equip_slot, "")
	return true

## 获取装备属性加成总和
func get_equipment_stats() -> Dictionary:
	var total_stats = {}
	for slot in _equipment.values():
		var item_data = ItemDatabase.get_item(slot)
		var stats = item_data.get("stats", {})
		for key in stats.keys():
			total_stats[key] = total_stats.get(key, 0) + stats[key]
	return total_stats

## 获取装备的移动速度加成
func get_movement_speed_mult() -> float:
	for slot in _equipment.values():
		var item_data = ItemDatabase.get_item(slot)
		var mult = item_data.get("speed_mult") or 0.0
		if mult > 0:
			return mult
	return 1.0

## 获取当前装备武器
func get_equipped_weapon() -> String:
	return _equipment.get("weapon") or ""  # 🔧 L3: 用小写 key

## 获取当前装备工具
func get_equipped_tool() -> String:
	return _equipment.get("tool") or ""  # 🔧 L3: 用小写 key

# ==================== 背包扩容 ====================

## 扩容背包
func expand_bag(extra_slots: int = 6) -> bool:
	var new_size = min(bag_slots + extra_slots, max_bag_slots)
	if new_size > bag_slots:
		bag_slots = new_size
		_resize_slots(bag_slots)
		bag_expanded.emit(bag_slots)
		return true
	return false

# ==================== 内部 ====================

func _resize_slots(new_size: int) -> void:
	while _slots.size() < new_size:
		_slots.append({"item_id": "", "count": 0, "durability": -1})

func _find_empty_slot() -> int:
	for i in range(_slots.size()):
		if _slots[i].item_id.is_empty() or _slots[i].count <= 0:
			_slots[i] = {"item_id": "", "count": 0, "durability": -1}
			return i
	return -1

# ==================== 🎒 背包栏 / 魂器 ====================

## 是否有背包装备（决定背包栏 8+ 是否可用）
func has_backpack_equipped() -> bool:
	return _equipment.has("backpack") and not _equipment["backpack"].is_empty()

## 标记某物品为魂器（死亡保留）
func set_soul_marked(item_id: String, marked: bool = true) -> void:
	if marked:
		_soul_marked_items[item_id] = true
	else:
		_soul_marked_items.erase(item_id)
	print("🔮 魂器标记 %s → %s" % [item_id, marked])

## 检查某物品是否为魂器
func is_soul_marked(item_id: String) -> bool:
	return _soul_marked_items.get(item_id, false)

## 装备的背包是否有魂器印记（背包栏全部保留）
func is_backpack_soul_marked() -> bool:
	return _backpack_soul_marked

## 设置背包魂器状态
func set_backpack_soul_marked(marked: bool) -> void:
	_backpack_soul_marked = marked
	print("🎒 背包魂器状态 → %s" % marked)

## 同步背包魂器状态（检测装备的背包物品是否有 soul_mark 属性）
func sync_backpack_soul_mark() -> void:
	if not has_backpack_equipped():
		_backpack_soul_marked = false
		return
	var bp_id = _equipment.get("backpack") or ""
	if bp_id.is_empty():
		_backpack_soul_marked = false
		return
	# 检查背包物品本身的标签
	var item_data = ItemDatabase.get_item(bp_id)
	_backpack_soul_marked = item_data.get("soul_marked") or false or _soul_marked_items.get(bp_id, false)

## 获取死亡时应该掉落的物品列表（非魂器物品）
## 返回 [{item_id, count, slot}]，同时从背包移除
func collect_death_drop_items() -> Array[Dictionary]:
	var drops: Array[Dictionary] = []
	
	# 检查背包是否魂器
	var bp_protected = is_backpack_soul_marked()
	
	for i in range(_slots.size()):
		var slot = _slots[i]
		if slot.get("item_id", "").is_empty() or slot.get("count", 0) <= 0:
			continue
		
		var should_keep = false
		
		if i < PERSONAL_SLOT_COUNT:
			# 👤 人物物品栏：逐个检查魂器标记
			should_keep = is_soul_marked(slot.get("item_id", ""))
		else:
			# 🎒 背包物品栏：如果背包是魂器则全部保留
			should_keep = bp_protected or is_soul_marked(slot.get("item_id", ""))
		
		if not should_keep:
			drops.append({
				"slot": i,
				"item_id": slot.get("item_id", ""),
				"count": slot.get("count", 0),
				"durability": slot.get("durability", 0)
			})
	
	# 从背包移除掉落物品
	for drop in drops:
		_slots[drop.slot] = {"item_id": "", "count": 0, "durability": -1}
		inventory_changed.emit(drop.slot, "", 0)
		item_removed.emit(drop.item_id, drop.count)
	
	return drops

# ==================== 查询 ====================

## 获取背包所有物品（非空格）
func get_all_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for i in range(_slots.size()):
		if not _slots[i].item_id.is_empty() and _slots[i].count > 0:
			items.append({
				"slot": i,
				"item_id": _slots[i].item_id,
				"count": _slots[i].count,
				"durability": _slots[i].durability,
				"data": ItemDatabase.get_item(_slots[i].item_id),
			})
	return items

func get_all_slots() -> Array:
	return _slots

func get_equipment() -> Dictionary:
	return _equipment.duplicate()

func get_used_slot_count() -> int:
	var count = 0
	for slot in _slots:
		if not slot.get("item_id", "").is_empty() and slot.get("count", 0) > 0:
			count += 1
	return count

func is_full() -> bool:
	return _find_empty_slot() == -1

# ==================== 存档 ====================

func get_save_data() -> Dictionary:
	return {
		"bag_slots": bag_slots,
		"slots": _slots,
		"equipment": _equipment,
		"soul_marked_items": _soul_marked_items,
		"backpack_soul_marked": _backpack_soul_marked,
	}

func load_save_data(data: Dictionary) -> void:
	bag_slots = data.get("bag_slots") or 24
	_slots = []
	_resize_slots(bag_slots)
	
	var saved_slots = data.get("slots") or []
	for i in range(min(saved_slots.size(), _slots.size())):
		_slots[i] = saved_slots[i].duplicate()
	
	_equipment = data.get("equipment", {})
	_soul_marked_items = data.get("soul_marked_items", {})
	_backpack_soul_marked = data.get("backpack_soul_marked") or false

# ==================== 📖 图鉴/描述接口 ====================

## 获取物品描述（自动触发图鉴发现）
func get_item_description(item_id: String) -> String:
	var item_data = ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return "未知物品"
	
	# 自动记录到图鉴
	var cyc = get_node("/root/GameManager/CyclopediaSystem") if has_node("/root/GameManager/CyclopediaSystem") else null
	if cyc:
		cyc.discover_entry(CyclopediaSystem.Category.ITEM, item_id)
	
	return item_data.get("desc") or "暂无描述"

## 获取物品详情（含品质、分类等）
func get_item_detail(item_id: String) -> Dictionary:
	var item_data = ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return {}
	
	var cyc = get_node("/root/GameManager/CyclopediaSystem") if has_node("/root/GameManager/CyclopediaSystem") else null
	if cyc:
		cyc.discover_entry(CyclopediaSystem.Category.ITEM, item_id)
	
	return {
		"id": item_id,
		"name": item_data.get("name") or "?",
		"category": ItemDatabase.get_item_category(item_id),
		"quality": ItemDatabase.get_item_quality(item_id),
		"desc": item_data.get("desc") or "暂无描述",
		"icon": item_data.get("icon") or "",
		"stackable": item_data.get("stackable") or false,
		"max_stack": item_data.get("max_stack") or 1,
		"sell_price": item_data.get("sell_price") or 0,
	}
