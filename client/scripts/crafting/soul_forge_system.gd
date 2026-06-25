## 魂器锻造系统
##
## 5种魂器来源 + 魂器耐久冷却管理
##
## 🔮 来源：
##   1. 血祭锻造  — 祭坛献祭 HP，成功绑定
##   2. 突破共振  — 大境界突破时概率共鸣
##   3. 老伙计    — 耐久耗尽时低概率觉醒（大概率摧毁）
##   4. 融合献祭  — 消耗魂晶 100% 绑定
##   5. 概率附魂  — 混沌之灵低概率附魂
##
## 🎨 每种来源有独立视觉特效

extends Node

# class_name SoulForgeSystem — 已通过 autoload 注册

# ==================== 来源枚举 ====================

enum SoulSource {
	BLOOD_SACRIFICE,   # 1. 血祭锻造
	BREAKTHROUGH,      # 2. 突破共振
	OLD_FRIEND,        # 3. 老伙计
	FUSION,            # 4. 融合献祭
	ENCHANTMENT,       # 5. 概率附魂
}

# ==================== 配置 ====================

## 各来源的中文名
const SOURCE_NAMES: Dictionary = {
	SoulSource.BLOOD_SACRIFICE: "血祭锻造",
	SoulSource.BREAKTHROUGH: "突破共振",
	SoulSource.OLD_FRIEND: "老伙计",
	SoulSource.FUSION: "融合献祭",
	SoulSource.ENCHANTMENT: "概率附魂",
}

## 魂器基础耐久上限（所有魂器通用）
const BASE_SOUL_DURABILITY: int = 100

## 冷却时间（秒）— 耐久耗尽后等多久才能用
const SOUL_COOLDOWN_TIME: float = 60.0

## 每秒自然恢复的耐久（即使未使用）
const SOUL_REGEN_RATE: float = 0.3

## 冷却期间额外恢复速率加成
const COOLDOWN_REGEN_BONUS: float = 2.0

# ==================== 来源概率 ====================

const BLOOD_SACRIFICE_BASE_CHANCE: float = 0.25    # 25%
const BREAKTHROUGH_CHANCE: float = 0.10             # 10%
const OLD_FRIEND_CHANCE: float = 0.05               # 5% 觉醒
const OLD_FRIEND_DESTROY_CHANCE: float = 0.70       # 70% 直接摧毁
const ENCHANTMENT_BASE_CHANCE: float = 0.08          # 8%

# ==================== 信号 ====================

signal soul_mark_created(item_id: String, source: int, slot_index: int)
signal soul_mark_failed(item_id: String, source: int, reason: String)
signal soul_durability_changed(slot_index: int, current: float, max_val: float)
signal soul_depleted(slot_index: int, cooldown: float)
signal soul_recovered(slot_index: int)
signal soul_item_decomposed(item_id: String, count: int, yield_soul_essence: int)

# ==================== 来源特效数据 ====================

## 每个来源的特效参数（给 Visual 层用）
const SOURCE_VFX: Dictionary = {
	SoulSource.BLOOD_SACRIFICE: {
		"color": Color(0.9, 0.1, 0.1),       # 血红
		"particle": "blood_sacrifice",
		"icon_modulate": Color(1.0, 0.3, 0.3),
		"aura_type": "crimson_blood",
		"label_color": Color(0.9, 0.15, 0.15),
	},
	SoulSource.BREAKTHROUGH: {
		"color": Color(0.5, 0.2, 1.0),       # 紫光
		"particle": "breakthrough_resonance",
		"icon_modulate": Color(0.6, 0.3, 1.0),
		"aura_type": "purple_lightning",
		"label_color": Color(0.6, 0.2, 1.0),
	},
	SoulSource.OLD_FRIEND: {
		"color": Color(1.0, 0.85, 0.2),      # 金色
		"particle": "old_friend",
		"icon_modulate": Color(1.0, 0.9, 0.3),
		"aura_type": "golden_glow",
		"label_color": Color(0.9, 0.7, 0.1),
	},
	SoulSource.FUSION: {
		"color": Color(0.2, 0.6, 1.0),       # 蓝焰
		"particle": "fusion_flame",
		"icon_modulate": Color(0.3, 0.7, 1.0),
		"aura_type": "blue_flame",
		"label_color": Color(0.2, 0.5, 0.9),
	},
	SoulSource.ENCHANTMENT: {
		"color": Color(0.1, 1.0, 0.8),       # 青虹
		"particle": "enchantment_glow",
		"icon_modulate": Color(0.2, 1.0, 0.8),
		"aura_type": "rainbow_halo",
		"label_color": Color(0.1, 0.8, 0.7),
	},
}

# ==================== 状态 ====================

var _game_manager: Node = null

func _ready() -> void:
	_game_manager = get_node("/root/GameManager")
	# 连接突破事件（方案2）
	var realm_sys = get_node_or_null("/root/GameManager/RealmSystem")
	if realm_sys and realm_sys.has_signal("realm_changed"):
		realm_sys.realm_changed.connect(_on_realm_changed)

func _process(delta: float) -> void:
	_tick_soul_durability(delta)

# ==================== 🎯 5种魂器来源 ====================

# ---------- 1. 🩸 血祭锻造 ----------
## 在祭坛尝试血祭锻造，消耗 HP 换取魂器绑定
## altar_pos: 祭坛世界坐标（用于特效）
func try_blood_sacrifice(player, slot_index: int, altar_pos: Vector3 = Vector3.ZERO) -> bool:
	"""条件：玩家HP > 30%，扣除至10%，25%概率成功"""
	if not _validate_player_and_slot(player, slot_index):
		return false
	
	var current_hp = player.current_hp
	var max_hp = player.max_hp
	if current_hp < max_hp * 0.3:
		emit_signal("soul_mark_failed", _get_slot_item_id(slot_index), SoulSource.BLOOD_SACRIFICE, "气血不足，无法血祭")
		return false
	
	# 扣除血量至 10%（保留底线）
	var hp_cost = current_hp - max_hp * 0.1
	player.take_damage(hp_cost, null)
	
	# 概率判定
	if randf() < BLOOD_SACRIFICE_BASE_CHANCE:
		_apply_soul_mark(slot_index, SoulSource.BLOOD_SACRIFICE)
		return true
	else:
		emit_signal("soul_mark_failed", _get_slot_item_id(slot_index), SoulSource.BLOOD_SACRIFICE, "血祭失败，物品未被选中")
		return false

# ---------- 2. 🌀 突破共振 ----------
func _on_realm_changed(old_realm: int, new_realm: int, realm_name: String) -> void:
	"""大境界突破时触发：10%概率随机绑定当前主手/工具"""
	if not _game_manager or not _game_manager.inventory:
		return
	var inv = _game_manager.inventory
	
	# 找当前装备的主手武器或工具
	var candidates = []
	for equip_slot in ["WEAPON", "TOOL"]:
		var item_id = inv.get_equipped_item(equip_slot)
		if not item_id.is_empty():
			candidates.append(item_id)
	
	if candidates.is_empty():
		return
	
	# 随机选一个，10%概率
	var chosen = candidates[randi() % candidates.size()]
	if randf() < BREAKTHROUGH_CHANCE:
		# 查找该物品在背包中的位置
		var slot_idx = inv.find_item_slot(chosen)
		if slot_idx >= 0:
			_apply_soul_mark(slot_idx, SoulSource.BREAKTHROUGH)
			print("🌀 突破共鸣！%s 获得了魂器印记！" % ItemDatabase.get_item_name(chosen))

# ---------- 3. 🔥 老伙计 ----------
## 耐久耗尽时调用（由 inventory_system.use_durability 触发）
func on_durability_depleted(slot_index: int, item_id: String) -> void:
	"""
	耐久耗尽时：
	- 5% 概率觉醒为「老伙计」魂器
	- 70% 概率直接摧毁
	- 25% 概率普通损坏（物品变空，与原来一样）
	"""
	var roll = randf()
	if roll < OLD_FRIEND_CHANCE:
		# 物品觉醒！变成魂器
		print("🔥 %s 在最后一刻觉醒为「老伙计」！" % ItemDatabase.get_item_name(item_id))
		_apply_soul_mark(slot_index, SoulSource.OLD_FRIEND)
	elif roll < OLD_FRIEND_CHANCE + OLD_FRIEND_DESTROY_CHANCE:
		# 摧毁
		print("💥 %s 在耐久耗尽后彻底损毁！" % ItemDatabase.get_item_name(item_id))
		# 由 inventory_system 处理清空，这里只发通知
		emit_signal("soul_mark_failed", item_id, SoulSource.OLD_FRIEND, "物品彻底损毁")
	else:
		# 普通损坏（默认行为）
		print("🔧 %s 耐久耗尽，正常损坏" % ItemDatabase.get_item_name(item_id))

# ---------- 4. 💫 融合献祭 ----------
## 消耗 3 个魂晶，100% 打造魂器
func try_fusion_forge(slot_index: int) -> bool:
	"""
	条件：背包有 3 个 soul_essence（魂晶）
	消耗：3 魂晶
	结果：100% 获得魂器印记
	"""
	if not _game_manager or not _game_manager.inventory:
		return false
	var inv = _game_manager.inventory
	
	# 检查魂晶数量
	var essence_count = inv.get_item_count("soul_essence")
	if essence_count < 3:
		emit_signal("soul_mark_failed", _get_slot_item_id(slot_index), SoulSource.FUSION, "魂晶不足（需要3个）")
		return false
	
	# 消耗魂晶
	if not inv.remove_item("soul_essence", 3):
		return false
	
	_apply_soul_mark(slot_index, SoulSource.FUSION)
	return true

# ---------- 5. ⚖️ 概率附魂 ----------
## 使用混沌之灵尝试附魂
func try_enchantment(slot_index: int, extra_material_count: int = 0) -> bool:
	"""
	条件：至少 1 个混沌之灵
	基础概率：8%
	每个额外混沌之灵 +5%，上限 80%
	消耗：1 + extra_material_count 个混沌之灵
	"""
	if not _game_manager or not _game_manager.inventory:
		return false
	var inv = _game_manager.inventory
	
	var required = 1 + extra_material_count
	var have = inv.get_item_count("chaos_spirit")
	if have < required:
		emit_signal("soul_mark_failed", _get_slot_item_id(slot_index), SoulSource.ENCHANTMENT, "混沌之灵不足")
		return false
	
	# 消耗材料
	if not inv.remove_item("chaos_spirit", required):
		return false
	
	# 计算概率
	var chance = min(0.8, ENCHANTMENT_BASE_CHANCE + extra_material_count * 0.05)
	
	if randf() < chance:
		_apply_soul_mark(slot_index, SoulSource.ENCHANTMENT)
		return true
	else:
		emit_signal("soul_mark_failed", _get_slot_item_id(slot_index), SoulSource.ENCHANTMENT, "附魂失败，混沌之灵消散")
		return false

# ==================== 🛠️ 核心方法 ====================

## 对某格物品施加魂器印记
func _apply_soul_mark(slot_index: int, source: int) -> void:
	if not _game_manager or not _game_manager.inventory:
		return
	var inv = _game_manager.inventory
	var item_id = _get_slot_item_id(slot_index)
	if item_id.is_empty():
		return
	
	# 标记为魂器
	inv.set_soul_marked(item_id, true)
	
	# 如果背包是魂器，同步状态
	if inv.is_backpack_equipped():
		inv.sync_backpack_soul_mark()
	
	# 初始化魂器耐久数据（存入 slot 的额外字段）
	var slot = inv.get_slot(slot_index)
	if slot and not slot.is_empty():
		slot.soul_source = source
		slot.soul_durability = BASE_SOUL_DURABILITY
		slot.soul_durability_max = BASE_SOUL_DURABILITY
		slot.soul_cooldown = 0.0
	
	print("🔮 魂器锻造成功！【%s】→ %s" % [ItemDatabase.get_item_name(item_id), SOURCE_NAMES[source]])
	soul_mark_created.emit(item_id, source, slot_index)

## 分解魂器 → 返还魂晶
func decompose_soul_item(slot_index: int) -> bool:
	"""
	魂器只能分解，不能丢弃/出售
	分解获得 1~3 个魂晶（根据来源品质浮动）
	"""
	if not _game_manager or not _game_manager.inventory:
		return false
	var inv = _game_manager.inventory
	var slot = inv.get_slot(slot_index)
	if slot.is_empty() or slot.get("item_id", "").is_empty():
		return false
	
	var item_id = slot.get("item_id", "")
	if not inv.is_soul_marked(item_id):
		emit_signal("soul_mark_failed", item_id, -1, "该物品不是魂器，无法分解")
		return false
	
	# 计算返还魂晶数量（魂器来源影响）
	var base_yield = 1
	var source = slot.get("soul_source", -1)
	match source:
		SoulSource.BLOOD_SACRIFICE, SoulSource.FUSION:
			base_yield = 2
		SoulSource.BREAKTHROUGH:
			base_yield = 1
		SoulSource.OLD_FRIEND:
			base_yield = 3
		SoulSource.ENCHANTMENT:
			base_yield = 1
	
	var yield_count = base_yield + (randi() % 2)  # 1~3浮动
	var count = slot.get("count", 0)
	
	# 清除魂器标记
	inv.set_soul_marked(item_id, false)
	
	# 清除物品（通过 inventory 内部方法）
	inv.remove_item(item_id, count)
	
	# 返还魂晶
	inv.add_item("soul_essence", yield_count)
	
	print("♻️ 分解魂器 %s → 获得 %d 个魂晶" % [ItemDatabase.get_item_name(item_id), yield_count])
	soul_item_decomposed.emit(item_id, count, yield_count)
	return true

# ==================== ⏳ 魂器耐久管理 ====================

## 每秒 tick：恢复耐久 + 冷却计时
func _tick_soul_durability(delta: float) -> void:
	if not _game_manager or not _game_manager.inventory:
		return
	var inv = _game_manager.inventory
	
	for i in range(inv.get_slot_count()):
		var slot = inv.get_slot(i)
		if slot.is_empty() or slot.get("item_id", "").is_empty():
			continue
		if not inv.is_soul_marked(slot.get("item_id", "")):
			continue
		if not slot.has("soul_durability"):
			continue
		
		var current = slot.soul_durability
		var max_val = slot.soul_durability_max
		var cooldown = slot.get("soul_cooldown") or 0.0
		
		if current >= max_val and cooldown <= 0:
			continue  # 满耐久且不在冷却，跳过
		
		# 冷却计时减少
		if cooldown > 0:
			cooldown -= delta
			if cooldown <= 0:
				cooldown = 0
				soul_recovered.emit(i)
				print("⏰ 魂器 %s 冷却结束，恢复可用" % ItemDatabase.get_item_name(slot.get("item_id", "")))
		
		# 耐久恢复（冷却期间恢复速度更快）
		var regen = SOUL_REGEN_RATE
		if cooldown > 0:
			regen *= COOLDOWN_REGEN_BONUS
		current = min(max_val, current + regen * delta)
		
		slot.soul_durability = current
		slot.soul_cooldown = cooldown
		
		soul_durability_changed.emit(i, current, max_val)

## 使用魂器耐久（由外部调用，比如 tool 使用）
func use_soul_durability(slot_index: int, amount: float = 10.0) -> bool:
	"""
	使用魂器，消耗耐久
	如果耐久归零 → 进入冷却
	返回：true=成功使用，false=在冷却中无法使用
	"""
	if not _game_manager or not _game_manager.inventory:
		return false
	var inv = _game_manager.inventory
	var slot = inv.get_slot(slot_index)
	if slot.is_empty() or slot.get("item_id", "").is_empty():
		return false
	if not inv.is_soul_marked(slot.get("item_id", "")):
		return false
	
	var cooldown = slot.get("soul_cooldown") or 0.0
	if cooldown > 0:
		return false  # 冷却中，不可用
	
	var current = slot.get("soul_durability") or BASE_SOUL_DURABILITY
	if current <= 0:
		# 进入冷却
		slot.soul_cooldown = SOUL_COOLDOWN_TIME
		soul_depleted.emit(slot_index, SOUL_COOLDOWN_TIME)
		print("⚫ 魂器 %s 耐久耗尽，进入 %ds 冷却" % [ItemDatabase.get_item_name(slot.get("item_id", "")), SOUL_COOLDOWN_TIME])
		return false
	
	slot.soul_durability = max(0, current - amount)
	soul_durability_changed.emit(slot_index, slot.soul_durability, slot.soul_durability_max)
	
	if slot.soul_durability <= 0:
		slot.soul_cooldown = SOUL_COOLDOWN_TIME
		soul_depleted.emit(slot_index, SOUL_COOLDOWN_TIME)
		print("⚫ 魂器 %s 耐久耗尽，进入 %ds 冷却" % [ItemDatabase.get_item_name(slot.get("item_id", "")), SOUL_COOLDOWN_TIME])
	
	return true

## 检查魂器是否可用（非冷却中且耐久 > 0）
func is_soul_item_usable(slot_index: int) -> bool:
	if not _game_manager or not _game_manager.inventory:
		return false
	var inv = _game_manager.inventory
	var slot = inv.get_slot(slot_index)
	if slot.is_empty() or slot.get("item_id", "").is_empty():
		return false
	if not inv.is_soul_marked(slot.get("item_id", "")):
		return true  # 不是魂器，走普通逻辑
	return slot.get("soul_cooldown") or 0.0 <= 0 and slot.get("soul_durability") or 0 > 0

## 获取魂器耐久百分比（0.0~1.0）
func get_soul_durability_ratio(slot_index: int) -> float:
	if not _game_manager or not _game_manager.inventory:
		return 1.0
	var slot = _game_manager.inventory.get_slot(slot_index)
	if slot.is_empty():
		return 1.0
	var max_val = slot.get("soul_durability_max") or BASE_SOUL_DURABILITY
	if max_val <= 0:
		return 1.0
	return slot.get("soul_durability") or max_val / max_val

# ==================== 🔍 工具 ====================

## 判断物品是否能成为魂器
## 规则：武器/工具/衣物(盔甲)/食品(带饱食度的消耗品)/背包装备 才有资格
static func is_item_soul_markable(item_id: String) -> bool:
	if item_id.is_empty():
		return false
	var item = ItemDatabase.get_item(item_id)
	if item.is_empty():
		return false
	
	var cat = item.get("category", -1)
	
	# 武器、工具、防具 — 直接准入
	if cat in [ItemDatabase.ItemCategory.WEAPON, ItemDatabase.ItemCategory.TOOL, ItemDatabase.ItemCategory.ARMOR]:
		return true
	
	# 食品 — CONSUMABLE 且带 hunger_restore 效果
	if cat == ItemDatabase.ItemCategory.CONSUMABLE:
		var use_effect = item.get("use_effect", {})
		if use_effect.has("hunger_restore"):
			return true
	
	# 背包 — 装备槽位是 backpack 且可装备
	if item.get("equippable") or false:
		var eq_slot = item.get("slot") or ""
		if eq_slot == "backpack":
			return true
	
	return false

func _get_slot_item_id(slot_index: int) -> String:
	if not _game_manager or not _game_manager.inventory:
		return ""
	var slot = _game_manager.inventory.get_slot(slot_index)
	if slot.is_empty():
		return ""
	return slot.get("item_id") or ""

func _validate_player_and_slot(player, slot_index: int) -> bool:
	if not player or not _game_manager or not _game_manager.inventory:
		return false
	var inv = _game_manager.inventory
	var slot = inv.get_slot(slot_index)
	if slot.is_empty() or slot.get("item_id", "").is_empty():
		return false
	if not is_item_soul_markable(slot.get("item_id", "")):
		emit_signal("soul_mark_failed", slot.get("item_id", ""), -1, "该类型物品不能成为魂器（仅武器/工具/防具/食品/背包）")
		return false
	if inv.is_soul_marked(slot.get("item_id", "")):
		emit_signal("soul_mark_failed", slot.get("item_id", ""), -1, "已经是魂器了")
		return false
	return true
