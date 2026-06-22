extends Node
## 物品数据库 — 全物品定义
##
## 所有可获取物都在这，按类别/品质/境界分层
## 供背包、合成、建造、商店等系统共用

class_name ItemDatabase

# ==================== 物品分类 ====================
enum ItemCategory {
	MATERIAL,     # 材料（矿石/木材/草药）
	TOOL,         # 工具（斧/镐/锤）
	WEAPON,       # 武器（剑/弓/法器）
	ARMOR,        # 防具（甲/冠/靴）
	CONSUMABLE,   # 消耗品（食物/丹药）
	BUILDING,     # 建筑块
	FURNITURE,    # 家具
	TALISMAN,     # 符箓/阵法
	STATION,      # 合成台
	TRANSPORT,    # 载具（飞剑）
	QUEST,        # 任务物品
	ACCESSORY,    # 饰品/法宝
}

# ==================== 品质等级 ====================
enum Quality {
	COMMON,       # 普通（白色）
	UNCOMMON,     # 优秀（绿色）
	RARE,         # 精良（蓝色）
	EPIC,         # 史诗（紫色）
	LEGENDARY,    # 传说（金色）
	IMMORTAL,     # 仙品（红色）
}

static func get_quality_color(q: int) -> Color:
	match q:
		Quality.COMMON:    return Color(0.8, 0.8, 0.8)
		Quality.UNCOMMON:  return Color(0.3, 0.9, 0.3)
		Quality.RARE:      return Color(0.3, 0.5, 1.0)
		Quality.EPIC:      return Color(0.7, 0.3, 1.0)
		Quality.LEGENDARY: return Color(1.0, 0.8, 0.0)
		Quality.IMMORTAL:  return Color(1.0, 0.2, 0.2)
	return Color.WHITE

static func get_quality_name(q: int) -> String:
	match q:
		Quality.COMMON:    return "普通"
		Quality.UNCOMMON:  return "优秀"
		Quality.RARE:      return "精良"
		Quality.EPIC:      return "史诗"
		Quality.LEGENDARY: return "传说"
		Quality.IMMORTAL:  return "仙品"
	return "未知"

# ==================== 物品数据结构 ====================
## {id: {name, category, quality, tier, stackable, max_stack,
##       sell_price, buy_price, desc, effects, ...}}

const ITEMS: Dictionary = {
	# ========== 材料 ==========
	"wood": {
		"name": "木材", "category": ItemCategory.MATERIAL, "quality": Quality.COMMON,
		"tier": 0, "stackable": true, "max_stack": 99,
		"icon": "wood", "sell_price": 1,
		"desc": "从树上砍下的普通木材",
		"gatherable": true, "gather_tool": "axe",
	},
	"stone": {
		"name": "石头", "category": ItemCategory.MATERIAL, "quality": Quality.COMMON,
		"tier": 0, "stackable": true, "max_stack": 99,
		"icon": "stone", "sell_price": 1,
		"desc": "坚硬的花岗岩，建筑基础",
		"gatherable": true, "gather_tool": "pickaxe",
	},
	"thatch": {
		"name": "茅草", "category": ItemCategory.MATERIAL, "quality": Quality.COMMON,
		"tier": 0, "stackable": true, "max_stack": 99,
		"icon": "thatch", "sell_price": 1,
		"desc": "干燥的茅草，最简陋的建筑材料",
		"gatherable": true, "gather_tool": "hand",
	},
	"vine": {
		"name": "藤蔓", "category": ItemCategory.MATERIAL, "quality": Quality.COMMON,
		"tier": 0, "stackable": true, "max_stack": 99,
		"icon": "vine", "sell_price": 1,
		"desc": "坚韧的藤条，可当绳子用",
		"gatherable": true, "gather_tool": "hand",
	},
	"dirt": {
		"name": "泥土", "category": ItemCategory.MATERIAL, "quality": Quality.COMMON,
		"tier": 0, "stackable": true, "max_stack": 99,
		"icon": "dirt", "sell_price": 1,
		"desc": "普通的泥土，可填平地形",
		"gatherable": true, "gather_tool": "shovel",
	},
	"iron_ore": {
		"name": "铁矿石", "category": ItemCategory.MATERIAL, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": true, "max_stack": 99,
		"icon": "iron_ore", "sell_price": 3,
		"desc": "含有铁元素的矿石，熔炼后可得到铁锭",
		"gatherable": true, "gather_tool": "pickaxe", "gather_tier": 1,
	},
	"iron_ingot": {
		"name": "铁锭", "category": ItemCategory.MATERIAL, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": true, "max_stack": 99,
		"icon": "iron_ingot", "sell_price": 5,
		"desc": "熔炼后的精铁，制作铁器的原料",
	},
	"gold_ore": {
		"name": "金矿石", "category": ItemCategory.MATERIAL, "quality": Quality.RARE,
		"tier": 2, "stackable": true, "max_stack": 99,
		"icon": "gold_ore", "sell_price": 8,
		"desc": "稀有金矿，灵气传导性好",
		"gatherable": true, "gather_tool": "pickaxe", "gather_tier": 2,
	},
	"gold_ingot": {
		"name": "金锭", "category": ItemCategory.MATERIAL, "quality": Quality.RARE,
		"tier": 2, "stackable": true, "max_stack": 99,
		"icon": "gold_ingot", "sell_price": 12,
		"desc": "纯金锻造，法器的重要材料",
	},
	"spirit_ore": {
		"name": "灵矿石", "category": ItemCategory.MATERIAL, "quality": Quality.RARE,
		"tier": 2, "stackable": true, "max_stack": 99,
		"icon": "spirit_ore", "sell_price": 10,
		"desc": "蕴含灵气的矿石，修仙者必备",
		"gatherable": true, "gather_tool": "pickaxe", "gather_tier": 2,
	},
	"spirit_iron": {
		"name": "灵铁", "category": ItemCategory.MATERIAL, "quality": Quality.RARE,
		"tier": 2, "stackable": true, "max_stack": 99,
		"icon": "spirit_iron", "sell_price": 15,
		"desc": "精炼后的灵铁，灵气充沛",
	},
	"spirit_stone": {
		"name": "灵石", "category": ItemCategory.MATERIAL, "quality": Quality.RARE,
		"tier": 2, "stackable": true, "max_stack": 999,
		"icon": "spirit_stone", "sell_price": 20,
		"desc": "修仙界硬通货，蕴含精纯灵气",
	},
	"spirit_jade": {
		"name": "灵玉", "category": ItemCategory.MATERIAL, "quality": Quality.EPIC,
		"tier": 3, "stackable": true, "max_stack": 99,
		"icon": "spirit_jade", "sell_price": 50,
		"desc": "万年灵玉，制作高级法器的核心材料",
		"gatherable": true, "gather_tool": "pickaxe", "gather_tier": 3,
	},
	"spirit_crystal": {
		"name": "玉晶", "category": ItemCategory.MATERIAL, "quality": Quality.EPIC,
		"tier": 4, "stackable": true, "max_stack": 99,
		"icon": "spirit_crystal", "sell_price": 100,
		"desc": "天地灵气结晶，元婴期以上的修行至宝",
		"gatherable": true, "gather_tool": "pickaxe", "gather_tier": 4,
	},
	"spirit_wood": {
		"name": "灵木", "category": ItemCategory.MATERIAL, "quality": Quality.RARE,
		"tier": 2, "stackable": true, "max_stack": 99,
		"icon": "spirit_wood", "sell_price": 8,
		"desc": "灵气滋养过的灵木，质地坚韧",
		"gatherable": true, "gather_tool": "axe", "gather_tier": 2,
	},
	"spirit_brick": {
		"name": "灵砖", "category": ItemCategory.MATERIAL, "quality": Quality.RARE,
		"tier": 2, "stackable": true, "max_stack": 99,
		"icon": "spirit_brick", "sell_price": 6,
		"desc": "灵力烧制的砖块，坚固美观",
	},
	"celestial_iron": {
		"name": "星辰铁", "category": ItemCategory.MATERIAL, "quality": Quality.LEGENDARY,
		"tier": 6, "stackable": true, "max_stack": 99,
		"icon": "celestial_iron", "sell_price": 500,
		"desc": "天外陨铁，蕴含星辰之力",
		"gatherable": true, "gather_tool": "pickaxe", "gather_tier": 6,
	},
	"celestial_stone": {
		"name": "星辰石", "category": ItemCategory.MATERIAL, "quality": Quality.LEGENDARY,
		"tier": 6, "stackable": true, "max_stack": 99,
		"icon": "celestial_stone", "sell_price": 400,
		"desc": "来自九天的星辰灵石",
	},
	
	# ========== 草药/炼丹材料 ==========
	"herb_common": {
		"name": "普通草药", "category": ItemCategory.MATERIAL, "quality": Quality.COMMON,
		"tier": 0, "stackable": true, "max_stack": 99,
		"icon": "herb_common", "sell_price": 2,
		"desc": "普通的草药，略有微弱的灵力",
		"gatherable": true, "gather_tool": "hand",
	},
	"herb_qi": {
		"name": "聚气草", "category": ItemCategory.MATERIAL, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": true, "max_stack": 99,
		"icon": "herb_qi", "sell_price": 5,
		"desc": "能自发聚集灵气的灵草",
		"gatherable": true, "gather_tool": "hand",
	},
	"herb_spirit": {
		"name": "灵蕴草", "category": ItemCategory.MATERIAL, "quality": Quality.RARE,
		"tier": 2, "stackable": true, "max_stack": 99,
		"icon": "herb_spirit", "sell_price": 15,
		"desc": "灵力充沛的灵草，丹方主药",
		"gatherable": true, "gather_tool": "hand",
	},
	"herb_celestial": {
		"name": "天灵草", "category": ItemCategory.MATERIAL, "quality": Quality.EPIC,
		"tier": 4, "stackable": true, "max_stack": 99,
		"icon": "herb_celestial", "sell_price": 80,
		"desc": "蕴含天灵之气的仙草",
		"gatherable": true, "gather_tool": "hand",
	},
	"beast_core": {
		"name": "妖兽内丹", "category": ItemCategory.MATERIAL, "quality": Quality.RARE,
		"tier": 2, "stackable": true, "max_stack": 99,
		"icon": "beast_core", "sell_price": 30,
		"desc": "妖兽凝结的内丹，炼器的上等材料",
	},
	"dragon_scale": {
		"name": "龙鳞", "category": ItemCategory.MATERIAL, "quality": Quality.LEGENDARY,
		"tier": 5, "stackable": true, "max_stack": 99,
		"icon": "dragon_scale", "sell_price": 500,
		"desc": "真龙之鳞，蕴含龙威",
	},
	"phoenix_feather": {
		"name": "凤凰羽", "category": ItemCategory.MATERIAL, "quality": Quality.LEGENDARY,
		"tier": 5, "stackable": true, "max_stack": 99,
		"icon": "phoenix_feather", "sell_price": 600,
		"desc": "凤凰涅盘遗落的圣羽",
	},
	
	# ========== 丹药 ==========
	"qi_recovery_pill": {
		"name": "回气丹", "category": ItemCategory.CONSUMABLE, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": true, "max_stack": 99,
		"icon": "pill_blue", "sell_price": 10,
		"desc": "服用后恢复50点法力值",
		"usable": true, "use_effect": {"mp_restore": 50},
	},
	"foundation_pill": {
		"name": "筑基丹", "category": ItemCategory.CONSUMABLE, "quality": Quality.RARE,
		"tier": 2, "stackable": true, "max_stack": 10,
		"icon": "pill_gold", "sell_price": 100,
		"desc": "突破筑基期的必须丹药",
		"usable": true, "use_effect": {"breakthrough_boost": 1},
	},
	"golden_core_pill": {
		"name": "凝金丹", "category": ItemCategory.CONSUMABLE, "quality": Quality.EPIC,
		"tier": 3, "stackable": true, "max_stack": 10,
		"icon": "pill_purple", "sell_price": 500,
		"desc": "凝结金丹的必须丹药",
		"usable": true, "use_effect": {"breakthrough_boost": 2},
	},
	"health_potion": {
		"name": "回春丹", "category": ItemCategory.CONSUMABLE, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": true, "max_stack": 99,
		"icon": "pill_red", "sell_price": 8,
		"desc": "服用后恢复100点生命值",
		"usable": true, "use_effect": {"hp_restore": 100},
	},
	
	# ========== 武器 ==========
	"wooden_sword": {
		"name": "木剑", "category": ItemCategory.WEAPON, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "wooden_sword", "sell_price": 5,
		"desc": "粗制滥造的木剑，聊胜于无",
		"equippable": true, "slot": "weapon",
		"stats": {"attack": 5, "crit_rate": 0.02},
		"durability": 60,
	},
	"iron_sword": {
		"name": "铁剑", "category": ItemCategory.WEAPON, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "iron_sword", "sell_price": 30,
		"desc": "百炼精铁剑，凡人利器",
		"equippable": true, "slot": "weapon",
		"stats": {"attack": 15, "crit_rate": 0.05},
		"durability": 200,
	},
	"spirit_iron_sword": {
		"name": "灵铁剑", "category": ItemCategory.WEAPON, "quality": Quality.RARE,
		"tier": 2, "stackable": false, "max_stack": 1,
		"icon": "spirit_sword", "sell_price": 200,
		"desc": "附灵铁剑，可灌注灵力",
		"equippable": true, "slot": "weapon",
		"stats": {"attack": 35, "crit_rate": 0.08, "crit_damage": 0.1},
		"durability": 500,
	},
	"jade_sword": {
		"name": "玉灵剑", "category": ItemCategory.WEAPON, "quality": Quality.EPIC,
		"tier": 3, "stackable": false, "max_stack": 1,
		"icon": "jade_sword", "sell_price": 1000,
		"desc": "灵玉锻造，可飞行御剑",
		"equippable": true, "slot": "weapon",
		"stats": {"attack": 80, "crit_rate": 0.12, "crit_damage": 0.3},
		"durability": 1500,
	},
	"artifact_sword": {
		"name": "后天灵宝·斩仙", "category": ItemCategory.WEAPON, "quality": Quality.LEGENDARY,
		"tier": 6, "stackable": false, "max_stack": 1,
		"icon": "artifact_sword", "sell_price": 50000,
		"desc": "后天灵宝，一剑可斩山河",
		"equippable": true, "slot": "weapon",
		"stats": {"attack": 300, "crit_rate": 0.25, "crit_damage": 0.8},
		"durability": 5000,
	},
	
	# ========== 工具 ==========
	"stone_axe": {
		"name": "石斧", "category": ItemCategory.TOOL, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "stone_axe", "sell_price": 5,
		"desc": "砍树效率1倍",
		"equippable": true, "slot": "tool",
		"gather_power": 1, "gather_type": "axe",
		"durability": 100,
	},
	"iron_axe": {
		"name": "铁斧", "category": ItemCategory.TOOL, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "iron_axe", "sell_price": 20,
		"desc": "砍树效率2倍",
		"equippable": true, "slot": "tool",
		"gather_power": 2, "gather_type": "axe",
		"durability": 300,
	},
	"stone_pickaxe": {
		"name": "石镐", "category": ItemCategory.TOOL, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "stone_pickaxe", "sell_price": 5,
		"desc": "挖矿效率1倍",
		"equippable": true, "slot": "tool",
		"gather_power": 1, "gather_type": "pickaxe",
		"durability": 100,
	},
	"iron_pickaxe": {
		"name": "铁镐", "category": ItemCategory.TOOL, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "iron_pickaxe", "sell_price": 20,
		"desc": "挖矿效率2倍，可挖灵矿",
		"equippable": true, "slot": "tool",
		"gather_power": 2, "gather_type": "pickaxe",
		"durability": 300,
	},
	
	# ========== 防具 ==========
	"spirit_armor": {
		"name": "灵气甲", "category": ItemCategory.ARMOR, "quality": Quality.RARE,
		"tier": 2, "stackable": false, "max_stack": 1,
		"icon": "spirit_armor", "sell_price": 300,
		"desc": "灵气护甲，大幅提升防御",
		"equippable": true, "slot": "armor",
		"stats": {"defense": 25, "max_hp": 100},
		"durability": 800,
	},
	
	# ========== 运输工具 ==========
	"flying_sword": {
		"name": "飞剑", "category": ItemCategory.TRANSPORT, "quality": Quality.EPIC,
		"tier": 3, "stackable": false, "max_stack": 1,
		"icon": "flying_sword", "sell_price": 2000,
		"desc": "御剑飞行，遨游天地（移动速度+300%）",
		"equippable": true, "slot": "transport",
		"speed_mult": 3.0,
	},
	
	# ========== 建筑块（创建时用 BuildingSystem） ==========
	"thatch_wall": {
		"name": "茅草墙", "category": ItemCategory.BUILDING, "quality": Quality.COMMON,
		"tier": 0, "stackable": true, "max_stack": 99,
		"icon": "thatch_wall", "sell_price": 2,
		"desc": "最简陋的墙，HP: 50",
		"buildable": true, "piece_type": 0, "piece_tier": 0,
	},
	"wooden_wall": {
		"name": "木墙", "category": ItemCategory.BUILDING, "quality": Quality.COMMON,
		"tier": 0, "stackable": true, "max_stack": 99,
		"icon": "wooden_wall", "sell_price": 4,
		"desc": "厚实木墙，HP: 100",
		"buildable": true, "piece_type": 0, "piece_tier": 1,
	},
	"stone_wall": {
		"name": "石墙", "category": ItemCategory.BUILDING, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": true, "max_stack": 99,
		"icon": "stone_wall", "sell_price": 8,
		"desc": "厚实石墙，HP: 200",
		"buildable": true, "piece_type": 0, "piece_tier": 2,
	},
	"brick_wall": {
		"name": "灵砖墙", "category": ItemCategory.BUILDING, "quality": Quality.RARE,
		"tier": 2, "stackable": true, "max_stack": 99,
		"icon": "brick_wall", "sell_price": 15,
		"desc": "灵气砖墙，HP: 400",
		"buildable": true, "piece_type": 0, "piece_tier": 3,
	},
	"jade_wall": {
		"name": "灵石墙", "category": ItemCategory.BUILDING, "quality": Quality.EPIC,
		"tier": 3, "stackable": true, "max_stack": 99,
		"icon": "jade_wall", "sell_price": 50,
		"desc": "灵石堆砌，HP: 800",
		"buildable": true, "piece_type": 0, "piece_tier": 4,
	},
	"crystal_wall": {
		"name": "玉晶墙", "category": ItemCategory.BUILDING, "quality": Quality.EPIC,
		"tier": 4, "stackable": true, "max_stack": 99,
		"icon": "crystal_wall", "sell_price": 200,
		"desc": "玉晶壁，HP: 1500",
		"buildable": true, "piece_type": 0, "piece_tier": 5,
	},
	
	# ========== 功能性建筑 ==========
	"campfire": {
		"name": "篝火", "category": ItemCategory.STATION, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "campfire", "sell_price": 5,
		"desc": "照亮黑夜，烧制食物，驱散野兽",
		"placeable": true, "place_type": "campfire",
	},
	"workbench": {
		"name": "工作台", "category": ItemCategory.STATION, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "workbench", "sell_price": 10,
		"desc": "万物合成之始，基础制造站",
		"placeable": true, "place_type": "workbench",
	},
	"furnace": {
		"name": "熔炉", "category": ItemCategory.STATION, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "furnace", "sell_price": 20,
		"desc": "冶炼金属，烧制陶瓷",
		"placeable": true, "place_type": "furnace",
	},
	"alchemy_furnace": {
		"name": "炼丹炉", "category": ItemCategory.STATION, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "alchemy_furnace", "sell_price": 30,
		"desc": "炼制基础丹药",
		"placeable": true, "place_type": "alchemy_furnace",
	},
	"spirit_furnace": {
		"name": "灵熔炉", "category": ItemCategory.STATION, "quality": Quality.RARE,
		"tier": 2, "stackable": false, "max_stack": 1,
		"icon": "spirit_furnace", "sell_price": 100,
		"desc": "精炼灵矿，锻造法器",
		"placeable": true, "place_type": "spirit_furnace",
	},
	
	# ========== 家具/装饰 ==========
	"wooden_chest": {
		"name": "木箱", "category": ItemCategory.FURNITURE, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "wooden_chest", "sell_price": 8,
		"desc": "20格存储空间",
		"placeable": true, "place_type": "chest", "storage_slots": 20,
	},
	"spirit_chest": {
		"name": "灵木箱", "category": ItemCategory.FURNITURE, "quality": Quality.RARE,
		"tier": 2, "stackable": false, "max_stack": 1,
		"icon": "spirit_chest", "sell_price": 80,
		"desc": "40格存储空间",
		"placeable": true, "place_type": "chest", "storage_slots": 40,
	},
	"torch": {
		"name": "火把", "category": ItemCategory.FURNITURE, "quality": Quality.COMMON,
		"tier": 0, "stackable": true, "max_stack": 99,
		"icon": "torch", "sell_price": 1,
		"desc": "插在墙上或手持照明",
		"placeable": true, "place_type": "torch",
	},
	"wooden_bed": {
		"name": "木床", "category": ItemCategory.FURNITURE, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "wooden_bed", "sell_price": 15,
		"desc": "睡觉恢复生命，设置重生点",
		"placeable": true, "place_type": "bed",
	},
	"spirit_lamp": {
		"name": "灵灯", "category": ItemCategory.FURNITURE, "quality": Quality.RARE,
		"tier": 2, "stackable": true, "max_stack": 99,
		"icon": "spirit_lamp", "sell_price": 25,
		"desc": "散发柔和灵光，照亮大片区域",
		"placeable": true, "place_type": "lamp",
	},
}

# ==================== 工具方法 ====================

static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})

static func get_item_name(item_id: String) -> String:
	return ITEMS.get(item_id, {}).get("name", item_id)

static func get_item_category(item_id: String) -> int:
	return ITEMS.get(item_id, {}).get("category", -1)

static func get_item_quality(item_id: String) -> int:
	return ITEMS.get(item_id, {}).get("quality", Quality.COMMON)

static func is_stackable(item_id: String) -> bool:
	return ITEMS.get(item_id, {}).get("stackable", false)

static func get_max_stack(item_id: String) -> int:
	return ITEMS.get(item_id, {}).get("max_stack", 1)

static func is_equippable(item_id: String) -> bool:
	return ITEMS.get(item_id, {}).get("equippable", false)

static func get_slot(item_id: String) -> String:
	return ITEMS.get(item_id, {}).get("slot", "")

static func get_stats(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {}).get("stats", {})

static func get_tier(item_id: String) -> int:
	return ITEMS.get(item_id, {}).get("tier", 0)

## 按分类获取物品列表
static func get_items_by_category(category: int) -> Dictionary:
	var result: Dictionary = {}
	for id in ITEMS.keys():
		if ITEMS[id].category == category:
			result[id] = ITEMS[id]
	return result

## 按境界获取可用物品
static func get_items_for_tier(max_tier: int) -> Dictionary:
	var result: Dictionary = {}
	for id in ITEMS.keys():
		if ITEMS[id].tier <= max_tier:
			result[id] = ITEMS[id]
	return result

## 搜索物品
static func search_items(query: String) -> Dictionary:
	var result: Dictionary = {}
	var q = query.to_lower()
	for id in ITEMS.keys():
		var item = ITEMS[id]
		if q in id.to_lower() or q in item.name.to_lower():
			result[id] = item
	return result

## 获取所有物品 ID
static func get_all_item_ids() -> Array[String]:
	return ITEMS.keys()
