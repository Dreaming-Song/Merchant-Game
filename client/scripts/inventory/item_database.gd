extends Node
## 物品数据库 — 全物品定义
##
## 所有可获取物都在这，按类别/品质/境界分层
## 供背包、合成、建造、商店等系统共用

# class_name 已通过 autoload 注册，不重复声明

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
	
	# ========== 食物（饥饿恢复）==========
	"wild_berry": {
		"name": "野果", "category": ItemCategory.CONSUMABLE, "quality": Quality.COMMON,
		"tier": 0, "stackable": true, "max_stack": 99,
		"icon": "berry_red", "sell_price": 1,
		"desc": "山间常见的野果，酸酸甜甜，勉强充饥",
		"usable": true, "use_effect": {"hunger_restore": 15},
	},
	"roasted_meat": {
		"name": "烤肉", "category": ItemCategory.CONSUMABLE, "quality": Quality.COMMON,
		"tier": 1, "stackable": true, "max_stack": 20,
		"icon": "meat_cooked", "sell_price": 8,
		"desc": "烤得金黄流油的兽肉，能有效填饱肚子",
		"usable": true, "use_effect": {"hunger_restore": 40},
	},
	"spirit_fruit": {
		"name": "灵果", "category": ItemCategory.CONSUMABLE, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": true, "max_stack": 30,
		"icon": "fruit_glowing", "sell_price": 15,
		"desc": "吸收了灵气的果实，既能充饥又能恢复灵力",
		"usable": true, "use_effect": {"hunger_restore": 30, "mp_restore": 20},
	},
	"rice_ball": {
		"name": "饭团", "category": ItemCategory.CONSUMABLE, "quality": Quality.COMMON,
		"tier": 0, "stackable": true, "max_stack": 50,
		"icon": "rice_ball", "sell_price": 3,
		"desc": "用灵谷捏成的饭团，凡人的主食",
		"usable": true, "use_effect": {"hunger_restore": 25},
	},
	"hearty_stew": {
		"name": "灵兽浓汤", "category": ItemCategory.CONSUMABLE, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": true, "max_stack": 10,
		"icon": "stew_hot", "sell_price": 20,
		"desc": "用灵兽肉和草药熬制的浓汤，大补",
		"usable": true, "use_effect": {"hunger_restore": 60, "hp_restore": 50},
	},
	"immortal_meal": {
		"name": "仙珍筵", "category": ItemCategory.CONSUMABLE, "quality": Quality.RARE,
		"tier": 3, "stackable": true, "max_stack": 5,
		"icon": "feast_golden", "sell_price": 100,
		"desc": "传说中的修仙筵席，凡人吃一口能三天不饿",
		"usable": true, "use_effect": {"hunger_restore": 150, "hp_restore": 200, "mp_restore": 100},
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
	# -- 轻甲套装 Tier 0 --
	"straw_hat": {
		"name": "草帽", "category": ItemCategory.ARMOR, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "straw_hat", "sell_price": 5,
		"desc": "茅草编的帽子，遮阳尚可，防砍免谈",
		"equippable": true, "slot": "helmet",
		"stats": {"defense": 1},
		"durability": 50,
	},
	"grass_armor": {
		"name": "草甲", "category": ItemCategory.ARMOR, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "grass_armor", "sell_price": 6,
		"desc": "藤蔓编的简易胸甲，聊胜于无",
		"equippable": true, "slot": "armor",
		"stats": {"defense": 2},
		"durability": 60,
	},
	"grass_skirt": {
		"name": "草裙", "category": ItemCategory.ARMOR, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "grass_skirt", "sell_price": 4,
		"desc": "遮羞兼防晒，小心走光",
		"equippable": true, "slot": "legs",
		"stats": {"defense": 1},
		"durability": 40,
	},
	"straw_sandals": {
		"name": "草鞋", "category": ItemCategory.ARMOR, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "straw_sandals", "sell_price": 3,
		"desc": "走山路不硌脚，仅此而已",
		"equippable": true, "slot": "boots",
		"stats": {"defense": 1},
		"durability": 35,
	},
	# -- 皮甲套装 Tier 1 --
	"leather_helmet": {
		"name": "皮帽", "category": ItemCategory.ARMOR, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "leather_helmet", "sell_price": 20,
		"desc": "鞣制皮革帽，轻便耐用",
		"equippable": true, "slot": "helmet",
		"stats": {"defense": 4},
		"durability": 150,
	},
	"leather_armor": {
		"name": "皮甲", "category": ItemCategory.ARMOR, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "leather_armor", "sell_price": 35,
		"desc": "厚实皮革制成的胸甲，能挡住野兽爪牙",
		"equippable": true, "slot": "armor",
		"stats": {"defense": 8},
		"durability": 200,
	},
	"leather_pants": {
		"name": "皮裤", "category": ItemCategory.ARMOR, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "leather_pants", "sell_price": 20,
		"desc": "护腿，行动灵活不失防护",
		"equippable": true, "slot": "legs",
		"stats": {"defense": 3},
		"durability": 150,
	},
	"leather_boots": {
		"name": "皮靴", "category": ItemCategory.ARMOR, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "leather_boots", "sell_price": 18,
		"desc": "结实的皮靴，越野跋涉不在话下",
		"equippable": true, "slot": "boots",
		"stats": {"defense": 3},
		"durability": 180,
	},
	# -- 铁甲套装 Tier 1 --
	"iron_helmet": {
		"name": "铁盔", "category": ItemCategory.ARMOR, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "iron_helmet", "sell_price": 50,
		"desc": "精铁打造的头盔，防护力不俗",
		"equippable": true, "slot": "helmet",
		"stats": {"defense": 8},
		"durability": 350,
	},
	"iron_armor": {
		"name": "铁甲", "category": ItemCategory.ARMOR, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "iron_armor", "sell_price": 80,
		"desc": "铁制板甲，结实可靠",
		"equippable": true, "slot": "armor",
		"stats": {"defense": 15},
		"durability": 500,
	},
	"iron_greaves": {
		"name": "铁护腿", "category": ItemCategory.ARMOR, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "iron_greaves", "sell_price": 45,
		"desc": "铁制腿甲，大幅度提升下盘防御",
		"equippable": true, "slot": "legs",
		"stats": {"defense": 7},
		"durability": 300,
	},
	"iron_boots": {
		"name": "铁靴", "category": ItemCategory.ARMOR, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "iron_boots", "sell_price": 40,
		"desc": "沉重的铁靴，踩到脚趾可疼了",
		"equippable": true, "slot": "boots",
		"stats": {"defense": 6},
		"durability": 400,
	},
	# ========== 饰品 ==========
	"wood_ring": {
		"name": "木戒", "category": ItemCategory.ACCESSORY, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "wood_ring", "sell_price": 5,
		"desc": "粗糙的木戒指，+5 灵气上限",
		"equippable": true, "slot": "ring",
		"stats": {"max_mana": 5},
		"durability": 100,
	},
	"copper_amulet": {
		"name": "铜项链", "category": ItemCategory.ACCESSORY, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "copper_amulet", "sell_price": 25,
		"desc": "铜制护身符，微增法力回复",
		"equippable": true, "slot": "amulet",
		"stats": {"max_mana": 15, "mana_regen": 0.5},
		"durability": 200,
	},
	"leather_belt": {
		"name": "皮带", "category": ItemCategory.ACCESSORY, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "leather_belt", "sell_price": 15,
		"desc": "宽皮腰带，+10 血量上限",
		"equippable": true, "slot": "belt",
		"stats": {"max_hp": 10},
		"durability": 150,
	},
	"spirit_ring": {
		"name": "灵纹戒", "category": ItemCategory.ACCESSORY, "quality": Quality.RARE,
		"tier": 2, "stackable": false, "max_stack": 1,
		"icon": "spirit_ring", "sell_price": 100,
		"desc": "刻有聚灵法阵的戒指，大幅提升法力",
		"equippable": true, "slot": "ring",
		"stats": {"max_mana": 50, "mana_regen": 1.0},
		"durability": 400,
	},
	"spirit_amulet": {
		"name": "灵玉项链", "category": ItemCategory.ACCESSORY, "quality": Quality.RARE,
		"tier": 2, "stackable": false, "max_stack": 1,
		"icon": "spirit_amulet", "sell_price": 120,
		"desc": "灵玉雕琢的项链，护体养神",
		"equippable": true, "slot": "amulet",
		"stats": {"defense": 5, "max_hp": 30, "max_mana": 20},
		"durability": 350,
	},
	"spirit_bracelet": {
		"name": "灵纹镯", "category": ItemCategory.ACCESSORY, "quality": Quality.RARE,
		"tier": 2, "stackable": false, "max_stack": 1,
		"icon": "spirit_bracelet", "sell_price": 90,
		"desc": "刻有防御阵法的镯子，+5 防御 +10 血量",
		"equippable": true, "slot": "bracelet",
		"stats": {"defense": 5, "max_hp": 10},
		"durability": 300,
	},
	
	# ========== 高级防具 ==========
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
	
	# ========== 背包 ==========
	"leather_bag": {
		"name": "皮背包", "category": ItemCategory.ARMOR, "quality": Quality.COMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "bag_leather", "sell_price": 50,
		"desc": "简单的皮革背包，+3 背包栏位",
		"equippable": true, "slot": "backpack",
		"extra_slots": 3,
	},
	"spirit_bag": {
		"name": "灵纹背包", "category": ItemCategory.ARMOR, "quality": Quality.RARE,
		"tier": 2, "stackable": false, "max_stack": 1,
		"icon": "bag_spirit", "sell_price": 300,
		"desc": "刻有灵纹的精致背包，+6 背包栏位",
		"equippable": true, "slot": "backpack",
		"extra_slots": 6,
	},
	"iron_bag": {
		"name": "玄铁背包", "category": ItemCategory.ARMOR, "quality": Quality.EPIC,
		"tier": 3, "stackable": false, "max_stack": 1,
		"icon": "bag_iron", "sell_price": 800,
		"desc": "玄铁打造，硬核储物，+10 背包栏位，自带防护",
		"equippable": true, "slot": "backpack",
		"extra_slots": 10,
		"stats": {"defense": 5, "max_hp": 30},
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
	"anvil": {
		"name": "铁砧", "category": ItemCategory.STATION, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "anvil", "sell_price": 25,
		"desc": "锻造高级武器和护甲的工作站",
		"placeable": true, "place_type": "anvil",
	},
	"loom": {
		"name": "织布机", "category": ItemCategory.STATION, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "loom", "sell_price": 15,
		"desc": "编织布料和防具的工作站",
		"placeable": true, "place_type": "loom",
	},
	"rune_table": {
		"name": "符文台", "category": ItemCategory.STATION, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "rune_table", "sell_price": 35,
		"desc": "铭刻符文、附魔装备的工作站",
		"placeable": true, "place_type": "rune_table",
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
	
	# ========== 铜矿（熔炼用）🔧 B6 ==========
	"copper_ore": {
		"name": "铜矿石", "category": ItemCategory.MATERIAL, "quality": Quality.COMMON,
		"tier": 0, "stackable": true, "max_stack": 99,
		"icon": "copper_ore", "sell_price": 2,
		"desc": "含铜矿石，熔炼可得铜锭",
		"gatherable": true, "gather_tool": "pickaxe",
	},
	"copper_ingot": {
		"name": "铜锭", "category": ItemCategory.MATERIAL, "quality": Quality.COMMON,
		"tier": 0, "stackable": true, "max_stack": 99,
		"icon": "copper_ingot", "sell_price": 3,
		"desc": "熔炼后的铜锭，基础金属材料",
	},
	
	# ========== 符箓材料 🔧 B6 ==========
	"paper": {
		"name": "符纸", "category": ItemCategory.MATERIAL, "quality": Quality.COMMON,
		"tier": 0, "stackable": true, "max_stack": 99,
		"icon": "paper", "sell_price": 1,
		"desc": "绘制符箓的空白符纸",
	},
	"ink": {
		"name": "朱砂墨", "category": ItemCategory.MATERIAL, "quality": Quality.COMMON,
		"tier": 0, "stackable": true, "max_stack": 99,
		"icon": "ink", "sell_price": 2,
		"desc": "朱砂调制的灵墨，绘制符箓必备",
	},
	
	# ========== 缺失的工具 🔧 B6 ==========
	"stone_hammer": {
		"name": "石锤", "category": ItemCategory.TOOL, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "stone_hammer", "sell_price": 5,
		"desc": "拆解建筑，回收材料",
		"equippable": true, "slot": "tool",
		"durability": 100,
	},
	
	# ========== 缺失的武器 🔧 B6 ==========
	"wooden_bow": {
		"name": "木弓", "category": ItemCategory.WEAPON, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "wooden_bow", "sell_price": 5,
		"desc": "简易木弓，远程防身",
		"equippable": true, "slot": "weapon",
		"stats": {"attack": 4, "crit_rate": 0.03},
		"durability": 50,
	},
	
	# ========== 缺失的建筑块 🔧 B6 ==========
	"thatch_floor": {
		"name": "茅草地板", "category": ItemCategory.BUILDING, "quality": Quality.COMMON,
		"tier": 0, "stackable": true, "max_stack": 99,
		"icon": "thatch_floor", "sell_price": 2,
		"desc": "茅草铺就的地板，HP: 50",
		"buildable": true, "piece_type": 1, "piece_tier": 0,
	},
	"wooden_door": {
		"name": "木门", "category": ItemCategory.BUILDING, "quality": Quality.COMMON,
		"tier": 0, "stackable": true, "max_stack": 99,
		"icon": "wooden_door", "sell_price": 6,
		"desc": "有门才有家，HP: 80",
		"buildable": true, "piece_type": 3, "piece_tier": 0,
	},
	"spirit_door": {
		"name": "灵木门", "category": ItemCategory.BUILDING, "quality": Quality.RARE,
		"tier": 2, "stackable": true, "max_stack": 99,
		"icon": "spirit_door", "sell_price": 25,
		"desc": "灵气加持的门，HP: 300",
		"buildable": true, "piece_type": 3, "piece_tier": 3,
	},
	"protection_array": {
		"name": "护山大阵", "category": ItemCategory.BUILDING, "quality": Quality.EPIC,
		"tier": 3, "stackable": false, "max_stack": 1,
		"icon": "protection_array", "sell_price": 500,
		"desc": "守护整片领地的结界大阵",
		"buildable": true, "piece_type": 10, "piece_tier": 3,
	},
	"teleport_array": {
		"name": "传送阵", "category": ItemCategory.BUILDING, "quality": Quality.EPIC,
		"tier": 4, "stackable": false, "max_stack": 1,
		"icon": "teleport_array", "sell_price": 2000,
		"desc": "瞬间传送至绑定的其他传送阵",
		"buildable": true, "piece_type": 10, "piece_tier": 4,
	},
	"pocket_dimension": {
		"name": "洞天福地", "category": ItemCategory.BUILDING, "quality": Quality.LEGENDARY,
		"tier": 4, "stackable": false, "max_stack": 1,
		"icon": "pocket_dimension", "sell_price": 10000,
		"desc": "独立空间洞府",
		"buildable": true, "piece_type": 10, "piece_tier": 4,
	},
	"floating_island": {
		"name": "浮空平台", "category": ItemCategory.BUILDING, "quality": Quality.LEGENDARY,
		"tier": 5, "stackable": true, "max_stack": 99,
		"icon": "floating_island", "sell_price": 5000,
		"desc": "悬浮于空中的平台，天空之城的基础",
		"buildable": true, "piece_type": 1, "piece_tier": 5,
	},
	
	# ========== 缺失的符箓 🔧 B6 ==========
	"basic_talisman": {
		"name": "基础符箓", "category": ItemCategory.TALISMAN, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": true, "max_stack": 99,
		"icon": "basic_talisman", "sell_price": 10,
		"desc": "释放一道基础五行法术",
		"usable": true, "use_effect": {"mp_restore": 0, "effect": "fire_bolt"},
	},
	
	# ========== 缺失的功能建筑 🔧 B6 ==========
	"herb_garden": {
		"name": "灵田", "category": ItemCategory.STATION, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "herb_garden", "sell_price": 20,
		"desc": "种植灵草药材的田地",
		"placeable": true, "place_type": "herb_garden",
	},
	
	# ========== 缺失的丹药 🔧 B6 ==========
	"nascent_soul_pill": {
		"name": "化婴丹", "category": ItemCategory.CONSUMABLE, "quality": Quality.EPIC,
		"tier": 4, "stackable": true, "max_stack": 10,
		"icon": "nascent_soul_pill", "sell_price": 2000,
		"desc": "碎丹成婴的必须丹药",
		"usable": true, "use_effect": {"breakthrough_boost": 3},
	},
	
	# ========== 🥚 宠物蛋 ==========
	"pet_egg_crane": {
		"name": "仙鹤蛋", "category": ItemCategory.MATERIAL, "quality": Quality.RARE,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "egg_blue", "sell_price": 100,
		"desc": "仙鹤的蛋，放入孵化台可孵化出仙鹤灵宠。
仙鹤优雅灵动，亲密度70解锁载人飞行。",
		"pet_type": "crane",
	},
	"pet_egg_fox": {
		"name": "灵狐蛋", "category": ItemCategory.MATERIAL, "quality": Quality.RARE,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "egg_orange", "sell_price": 100,
		"desc": "灵狐的蛋，孵化后获得灵狐。
灵狐擅长采集，亲密度50解锁采集助手。",
		"pet_type": "fox",
	},
	"pet_egg_panda": {
		"name": "竹熊蛋", "category": ItemCategory.MATERIAL, "quality": Quality.RARE,
		"tier": 2, "stackable": false, "max_stack": 1,
		"icon": "egg_green", "sell_price": 150,
		"desc": "竹熊的蛋，孵化后获得竹熊。
竹熊憨厚力大，擅长辅助战斗。",
		"pet_type": "panda",
	},
	"pet_egg_pixiu": {
		"name": "貔貅蛋", "category": ItemCategory.MATERIAL, "quality": Quality.LEGENDARY,
		"tier": 3, "stackable": false, "max_stack": 1,
		"icon": "egg_gold", "sell_price": 5000,
		"desc": "上古神兽貔貅之蛋，极为稀有。
貔貅能增幅主人战斗力，招财进宝。",
		"pet_type": "pixiu",
	},
	"pet_egg_azure_dragon": {
		"name": "青龙蛋", "category": ItemCategory.MATERIAL, "quality": Quality.LEGENDARY,
		"tier": 4, "stackable": false, "max_stack": 1,
		"icon": "egg_green", "sell_price": 10000,
		"desc": "东方木德神兽·青龙的蛋。
孵化出青龙幼体，掌控生机之力。",
		"pet_type": "azure_dragon",
	},
	"pet_egg_white_tiger": {
		"name": "白虎蛋", "category": ItemCategory.MATERIAL, "quality": Quality.LEGENDARY,
		"tier": 4, "stackable": false, "max_stack": 1,
		"icon": "egg_white", "sell_price": 10000,
		"desc": "西方金德神兽·白虎的蛋。
孵化出白虎幼体，锐不可当。",
		"pet_type": "white_tiger",
	},
	"pet_egg_vermilion_bird": {
		"name": "朱雀蛋", "category": ItemCategory.MATERIAL, "quality": Quality.LEGENDARY,
		"tier": 4, "stackable": false, "max_stack": 1,
		"icon": "egg_red", "sell_price": 10000,
		"desc": "南方火德神兽·朱雀的蛋。
孵化出朱雀幼体，涅槃重生。",
		"pet_type": "vermilion_bird",
	},
	"pet_egg_black_warrior": {
		"name": "玄武蛋", "category": ItemCategory.MATERIAL, "quality": Quality.LEGENDARY,
		"tier": 4, "stackable": false, "max_stack": 1,
		"icon": "egg_blue", "sell_price": 10000,
		"desc": "北方水德神兽·玄武的蛋。
孵化出玄武幼体，坚不可摧。",
		"pet_type": "black_warrior",
	},
	"pet_egg_golden_qilin": {
		"name": "麒麟蛋", "category": ItemCategory.MATERIAL, "quality": Quality.LEGENDARY,
		"tier": 5, "stackable": false, "max_stack": 1,
		"icon": "egg_gold", "sell_price": 20000,
		"desc": "中央土德神兽·麒麟的蛋。
孵化出麒麟幼体，祥瑞之兆。",
		"pet_type": "golden_qilin",
	},
	
	# ========== 五行通关令牌 ==========
	"azure_pass": {
		"name": "青龙令", "category": ItemCategory.CONSUMABLE, "quality": Quality.EPIC,
		"tier": 3, "stackable": true, "max_stack": 99,
		"icon": "token_green", "sell_price": 500,
		"desc": "蕴含东方木德之力的令牌。
使用后传送至【青龙秘境·万木春】挑战神兽青龙。",
		"effect": "teleport_to_arena:azure_dragon",
		"craft": {"青木精华": 3, "青龙令碎片": 5},
	},
	"tiger_pass": {
		"name": "白虎令", "category": ItemCategory.CONSUMABLE, "quality": Quality.EPIC,
		"tier": 3, "stackable": true, "max_stack": 99,
		"icon": "token_white", "sell_price": 500,
		"desc": "蕴含西方金德之力的令牌。
使用后传送至【白虎秘境·万兵谷】挑战神兽白虎。",
		"effect": "teleport_to_arena:white_tiger",
		"craft": {"锐金砂": 3, "白虎令碎片": 5},
	},
	"bird_pass": {
		"name": "朱雀令", "category": ItemCategory.CONSUMABLE, "quality": Quality.EPIC,
		"tier": 3, "stackable": true, "max_stack": 99,
		"icon": "token_red", "sell_price": 500,
		"desc": "蕴含南方火德之力的令牌。
使用后传送至【朱雀秘境·焚天窟】挑战神兽朱雀。",
		"effect": "teleport_to_arena:vermilion_bird",
		"craft": {"火结晶": 3, "朱雀令碎片": 5},
	},
	"turtle_pass": {
		"name": "玄武令", "category": ItemCategory.CONSUMABLE, "quality": Quality.EPIC,
		"tier": 3, "stackable": true, "max_stack": 99,
		"icon": "token_blue", "sell_price": 500,
		"desc": "蕴含北方水德之力的令牌。
使用后传送至【玄武秘境·寒冰渊】挑战神兽玄武。",
		"effect": "teleport_to_arena:black_warrior",
		"craft": {"寒玉": 3, "玄武令碎片": 5},
	},
	"qilin_pass": {
		"name": "麒麟令", "category": ItemCategory.CONSUMABLE, "quality": Quality.EPIC,
		"tier": 3, "stackable": true, "max_stack": 99,
		"icon": "token_gold", "sell_price": 500,
		"desc": "蕴含中央土德之力的令牌。
使用后传送至【麒麟秘境·镇岳台】挑战神兽麒麟。",
		"effect": "teleport_to_arena:golden_qilin",
		"craft": {"土灵石": 3, "麒麟令碎片": 5},
	},
	
	# ========== 🔮 魂器材料 ==========
	"soul_essence": {
		"name": "魂晶", "category": ItemCategory.MATERIAL, "quality": Quality.RARE,
		"tier": 2, "stackable": true, "max_stack": 99,
		"icon": "soul_essence", "sell_price": 200,
		"desc": "蕴含灵魂之力的结晶。
分解魂器获得，可用于融合献祭锻造魂器。",
		"soul_markable": false,
	},
	"chaos_spirit": {
		"name": "混沌之灵", "category": ItemCategory.MATERIAL, "quality": Quality.EPIC,
		"tier": 3, "stackable": true, "max_stack": 99,
		"icon": "chaos_spirit", "sell_price": 500,
		"desc": "天地初开时残留的混沌气息。
可用于概率附魂，多个可提高成功率。",
		"soul_markable": false,
	},

	# ==========================================================
	# 🆕 补全材料（铸造/炼器中间产物）
	# ==========================================================
	"sand": {
		"name": "沙子", "category": ItemCategory.MATERIAL, "quality": Quality.COMMON,
		"tier": 0, "stackable": true, "max_stack": 99,
		"icon": "sand", "sell_price": 1,
		"desc": "河床中筛出的细沙，可烧制玻璃",
		"gatherable": true, "gather_tool": "shovel",
	},
	"leather": {
		"name": "皮革", "category": ItemCategory.MATERIAL, "quality": Quality.COMMON,
		"tier": 0, "stackable": true, "max_stack": 99,
		"icon": "leather", "sell_price": 3,
		"desc": "鞣制后的兽皮，制作防具和背包的原料",
	},
	"silk": {
		"name": "灵丝", "category": ItemCategory.MATERIAL, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": true, "max_stack": 99,
		"icon": "silk", "sell_price": 8,
		"desc": "由灵蚕吐出的丝线，坚韧轻盈",
	},
	"cloth": {
		"name": "布匹", "category": ItemCategory.MATERIAL, "quality": Quality.COMMON,
		"tier": 0, "stackable": true, "max_stack": 99,
		"icon": "cloth", "sell_price": 4,
		"desc": "基础布料，制作防具的原材料",
	},
	"fire_essence": {
		"name": "火灵精", "category": ItemCategory.MATERIAL, "quality": Quality.RARE,
		"tier": 2, "stackable": true, "max_stack": 99,
		"icon": "fire_essence", "sell_price": 20,
		"desc": "蕴藏火灵之力的精华，附魔与炼器原料",
	},
	"water_essence": {
		"name": "水灵精", "category": ItemCategory.MATERIAL, "quality": Quality.RARE,
		"tier": 2, "stackable": true, "max_stack": 99,
		"icon": "water_essence", "sell_price": 20,
		"desc": "蕴藏水灵之力的精华，附魔与炼器原料",
	},
	"earth_essence": {
		"name": "土灵精", "category": ItemCategory.MATERIAL, "quality": Quality.RARE,
		"tier": 2, "stackable": true, "max_stack": 99,
		"icon": "earth_essence", "sell_price": 20,
		"desc": "蕴藏土灵之力的精华，附魔与炼器原料",
	},

	# ==========================================================
	# 🆕 工具（补全：锹/镰/锤/钓竿）
	# ==========================================================
	"stone_shovel": {
		"name": "石锹", "category": ItemCategory.TOOL, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "stone_shovel", "sell_price": 5,
		"desc": "挖土铲沙，效率1倍",
		"equippable": true, "slot": "tool",
		"gather_power": 1, "gather_type": "shovel",
		"durability": 80,
	},
	"stone_scythe": {
		"name": "石镰", "category": ItemCategory.TOOL, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "stone_scythe", "sell_price": 5,
		"desc": "采集草药藤蔓，效率1倍",
		"equippable": true, "slot": "tool",
		"gather_power": 1, "gather_type": "scythe",
		"durability": 80,
	},
	"fishing_rod_wooden": {
		"name": "木钓竿", "category": ItemCategory.TOOL, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "fishing_rod", "sell_price": 8,
		"desc": "普通木钓竿，能在水域钓鱼",
		"equippable": true, "slot": "tool",
		"gather_type": "fishing",
		"durability": 60,
	},
	"iron_shovel": {
		"name": "铁锹", "category": ItemCategory.TOOL, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "iron_shovel", "sell_price": 20,
		"desc": "挖土效率2倍",
		"equippable": true, "slot": "tool",
		"gather_power": 2, "gather_type": "shovel",
		"durability": 300,
	},
	"iron_hammer": {
		"name": "铁锤", "category": ItemCategory.TOOL, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "iron_hammer", "sell_price": 25,
		"desc": "拆解建筑效率更高，兼具战斗能力",
		"equippable": true, "slot": "tool",
		"gather_power": 2, "gather_type": "hammer",
		"durability": 350,
		"stats": {"attack": 8},
	},
	"iron_scythe": {
		"name": "铁镰", "category": ItemCategory.TOOL, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "iron_scythe", "sell_price": 20,
		"desc": "采集草药效率2倍",
		"equippable": true, "slot": "tool",
		"gather_power": 2, "gather_type": "scythe",
		"durability": 300,
	},
	"spirit_shovel": {
		"name": "灵铁锹", "category": ItemCategory.TOOL, "quality": Quality.RARE,
		"tier": 2, "stackable": false, "max_stack": 1,
		"icon": "spirit_shovel", "sell_price": 60,
		"desc": "灵铁锻造，挖土效率3倍",
		"equippable": true, "slot": "tool",
		"gather_power": 3, "gather_type": "shovel",
		"durability": 600,
	},
	"spirit_scythe": {
		"name": "灵铁镰", "category": ItemCategory.TOOL, "quality": Quality.RARE,
		"tier": 2, "stackable": false, "max_stack": 1,
		"icon": "spirit_scythe", "sell_price": 60,
		"desc": "灵铁镰刀，采集效率3倍",
		"equippable": true, "slot": "tool",
		"gather_power": 3, "gather_type": "scythe",
		"durability": 600,
	},
	"spirit_hammer": {
		"name": "灵铁锤", "category": ItemCategory.TOOL, "quality": Quality.RARE,
		"tier": 2, "stackable": false, "max_stack": 1,
		"icon": "spirit_hammer", "sell_price": 80,
		"desc": "灵铁重锤，拆除和战斗两用",
		"equippable": true, "slot": "tool",
		"gather_power": 3, "gather_type": "hammer",
		"durability": 700,
		"stats": {"attack": 15},
	},
	"fishing_rod_spirit": {
		"name": "灵丝钓竿", "category": ItemCategory.TOOL, "quality": Quality.RARE,
		"tier": 2, "stackable": false, "max_stack": 1,
		"icon": "fishing_rod_spirit", "sell_price": 100,
		"desc": "灵丝编织的钓线，能钓到灵鱼",
		"equippable": true, "slot": "tool",
		"gather_type": "fishing",
		"durability": 300,
	},
	"jade_pickaxe": {
		"name": "玉灵镐", "category": ItemCategory.TOOL, "quality": Quality.EPIC,
		"tier": 3, "stackable": false, "max_stack": 1,
		"icon": "jade_pickaxe", "sell_price": 300,
		"desc": "灵玉镐头，挖矿效率4倍",
		"equippable": true, "slot": "tool",
		"gather_power": 4, "gather_type": "pickaxe",
		"durability": 1500,
	},
	"jade_axe": {
		"name": "玉灵斧", "category": ItemCategory.TOOL, "quality": Quality.EPIC,
		"tier": 3, "stackable": false, "max_stack": 1,
		"icon": "jade_axe", "sell_price": 300,
		"desc": "玉灵斧刃，砍树效率4倍",
		"equippable": true, "slot": "tool",
		"gather_power": 4, "gather_type": "axe",
		"durability": 1500,
	},

	# ==========================================================
	# 🆕 武器（补全：匕首/弓/枪/杖）
	# ==========================================================
	"stone_dagger": {
		"name": "石匕首", "category": ItemCategory.WEAPON, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "stone_dagger", "sell_price": 4,
		"desc": "磨尖的燧石匕首，速度快但伤害低",
		"equippable": true, "slot": "weapon",
		"stats": {"attack": 3, "crit_rate": 0.05, "attack_speed": 1.3},
		"durability": 40,
	},
	"wooden_staff": {
		"name": "木杖", "category": ItemCategory.WEAPON, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "wooden_staff", "sell_price": 6,
		"desc": "粗糙的木制法杖，能放大微弱灵力",
		"equippable": true, "slot": "weapon",
		"stats": {"attack": 4, "spell_power": 2},
		"durability": 50,
	},
	"iron_bow": {
		"name": "铁弓", "category": ItemCategory.WEAPON, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "iron_bow", "sell_price": 35,
		"desc": "铁骨弓，射程远，伤害不俗",
		"equippable": true, "slot": "weapon",
		"stats": {"attack": 12, "crit_rate": 0.08, "range": 15},
		"durability": 250,
	},
	"iron_spear": {
		"name": "铁枪", "category": ItemCategory.WEAPON, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "iron_spear", "sell_price": 30,
		"desc": "百炼铁枪，攻守兼备",
		"equippable": true, "slot": "weapon",
		"stats": {"attack": 14, "defense": 3},
		"durability": 250,
	},
	"iron_dagger": {
		"name": "铁匕首", "category": ItemCategory.WEAPON, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "iron_dagger", "sell_price": 15,
		"desc": "轻便铁匕首，攻速快暴击高",
		"equippable": true, "slot": "weapon",
		"stats": {"attack": 8, "crit_rate": 0.12, "attack_speed": 1.5},
		"durability": 150,
	},
	"spirit_bow": {
		"name": "灵铁弓", "category": ItemCategory.WEAPON, "quality": Quality.RARE,
		"tier": 2, "stackable": false, "max_stack": 1,
		"icon": "spirit_bow", "sell_price": 250,
		"desc": "灵铁弓弦，灵力箭矢穿云裂石",
		"equippable": true, "slot": "weapon",
		"stats": {"attack": 28, "crit_rate": 0.10, "range": 20},
		"durability": 500,
	},
	"spirit_staff": {
		"name": "灵铁杖", "category": ItemCategory.WEAPON, "quality": Quality.RARE,
		"tier": 2, "stackable": false, "max_stack": 1,
		"icon": "spirit_staff", "sell_price": 280,
		"desc": "铭刻灵纹的法杖，法术威力大增",
		"equippable": true, "slot": "weapon",
		"stats": {"attack": 20, "spell_power": 18},
		"durability": 400,
	},
	"spirit_spear": {
		"name": "灵铁枪", "category": ItemCategory.WEAPON, "quality": Quality.RARE,
		"tier": 2, "stackable": false, "max_stack": 1,
		"icon": "spirit_spear", "sell_price": 260,
		"desc": "灵铁锻造，枪出如龙",
		"equippable": true, "slot": "weapon",
		"stats": {"attack": 32, "defense": 5},
		"durability": 600,
	},
	"jade_staff": {
		"name": "玉灵杖", "category": ItemCategory.WEAPON, "quality": Quality.EPIC,
		"tier": 3, "stackable": false, "max_stack": 1,
		"icon": "jade_staff", "sell_price": 1200,
		"desc": "灵玉雕琢的法杖，引动天地灵气",
		"equippable": true, "slot": "weapon",
		"stats": {"attack": 40, "spell_power": 50},
		"durability": 1200,
	},
	"jade_bow": {
		"name": "玉灵弓", "category": ItemCategory.WEAPON, "quality": Quality.EPIC,
		"tier": 3, "stackable": false, "max_stack": 1,
		"icon": "jade_bow", "sell_price": 1100,
		"desc": "玉灵弓身，灵气凝矢，百步穿杨",
		"equippable": true, "slot": "weapon",
		"stats": {"attack": 60, "crit_rate": 0.15, "range": 25},
		"durability": 1000,
	},
	"jade_dagger": {
		"name": "玉灵匕", "category": ItemCategory.WEAPON, "quality": Quality.EPIC,
		"tier": 3, "stackable": false, "max_stack": 1,
		"icon": "jade_dagger", "sell_price": 800,
		"desc": "灵玉锻造的匕首，削铁如泥",
		"equippable": true, "slot": "weapon",
		"stats": {"attack": 45, "crit_rate": 0.20, "attack_speed": 1.6},
		"durability": 800,
	},
	"crystal_sword": {
		"name": "玉晶剑", "category": ItemCategory.WEAPON, "quality": Quality.EPIC,
		"tier": 4, "stackable": false, "max_stack": 1,
		"icon": "crystal_sword", "sell_price": 5000,
		"desc": "玉晶铸剑，剑气纵横三千里",
		"equippable": true, "slot": "weapon",
		"stats": {"attack": 150, "crit_rate": 0.18, "crit_damage": 0.5},
		"durability": 2500,
	},
	"crystal_staff": {
		"name": "玉晶杖", "category": ItemCategory.WEAPON, "quality": Quality.EPIC,
		"tier": 4, "stackable": false, "max_stack": 1,
		"icon": "crystal_staff", "sell_price": 5500,
		"desc": "玉晶法杖，号令天地灵气",
		"equippable": true, "slot": "weapon",
		"stats": {"attack": 80, "spell_power": 120},
		"durability": 2000,
	},
	"artifact_staff": {
		"name": "后天灵宝·混元", "category": ItemCategory.WEAPON, "quality": Quality.LEGENDARY,
		"tier": 6, "stackable": false, "max_stack": 1,
		"icon": "artifact_staff", "sell_price": 60000,
		"desc": "后天灵宝，混元一气，万法归宗",
		"equippable": true, "slot": "weapon",
		"stats": {"attack": 150, "spell_power": 400, "crit_rate": 0.20},
		"durability": 4000,
	},
	"artifact_bow": {
		"name": "后天灵宝·落日", "category": ItemCategory.WEAPON, "quality": Quality.LEGENDARY,
		"tier": 6, "stackable": false, "max_stack": 1,
		"icon": "artifact_bow", "sell_price": 55000,
		"desc": "后天灵宝，落日神弓，一箭可落九日",
		"equippable": true, "slot": "weapon",
		"stats": {"attack": 350, "crit_rate": 0.30, "crit_damage": 1.0, "range": 35},
		"durability": 3500,
	},

	# ==========================================================
	# 🆕 防具（全套装：头盔/胸甲/护腿/靴子）
	# ==========================================================
	# -- Tier 0 布甲套 --
	"cloth_helmet": {
		"name": "布帽", "category": ItemCategory.ARMOR, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "cloth_helmet", "sell_price": 3,
		"desc": "简陋布帽，聊胜于无",
		"equippable": true, "slot": "helmet",
		"stats": {"defense": 2},
		"durability": 30,
	},
	"cloth_robe": {
		"name": "布衣", "category": ItemCategory.ARMOR, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "cloth_robe", "sell_price": 8,
		"desc": "基础布衣，聊胜于无",
		"equippable": true, "slot": "armor",
		"stats": {"defense": 5},
		"durability": 50,
	},
	"cloth_legs": {
		"name": "布裤", "category": ItemCategory.ARMOR, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "cloth_legs", "sell_price": 5,
		"desc": "粗布裤子，行动轻盈",
		"equippable": true, "slot": "legs",
		"stats": {"defense": 2, "speed": 0.02},
		"durability": 40,
	},
	"cloth_boots": {
		"name": "布鞋", "category": ItemCategory.ARMOR, "quality": Quality.COMMON,
		"tier": 0, "stackable": false, "max_stack": 1,
		"icon": "cloth_boots", "sell_price": 3,
		"desc": "普通布鞋，走路生风",
		"equippable": true, "slot": "boots",
		"stats": {"defense": 1, "speed": 0.05},
		"durability": 30,
	},

	# -- Tier 2 灵铁甲套 --
	"spirit_helmet": {
		"name": "灵铁头盔", "category": ItemCategory.ARMOR, "quality": Quality.RARE,
		"tier": 2, "stackable": false, "max_stack": 1,
		"icon": "spirit_helmet", "sell_price": 150,
		"desc": "灵铁锻造，灵气护体",
		"equippable": true, "slot": "helmet",
		"stats": {"defense": 18, "max_hp": 50},
		"durability": 500,
	},
	"spirit_chestplate": {
		"name": "灵铁胸甲", "category": ItemCategory.ARMOR, "quality": Quality.RARE,
		"tier": 2, "stackable": false, "max_stack": 1,
		"icon": "spirit_chestplate", "sell_price": 250,
		"desc": "灵铁胸甲，防御大增",
		"equippable": true, "slot": "armor",
		"stats": {"defense": 30, "max_hp": 80},
		"durability": 800,
	},
	"spirit_legs": {
		"name": "灵铁护腿", "category": ItemCategory.ARMOR, "quality": Quality.RARE,
		"tier": 2, "stackable": false, "max_stack": 1,
		"icon": "spirit_legs", "sell_price": 120,
		"desc": "灵铁护腿，灵气流转",
		"equippable": true, "slot": "legs",
		"stats": {"defense": 12, "speed": 0.03},
		"durability": 500,
	},
	"spirit_boots": {
		"name": "灵铁靴", "category": ItemCategory.ARMOR, "quality": Quality.RARE,
		"tier": 2, "stackable": false, "max_stack": 1,
		"icon": "spirit_boots", "sell_price": 100,
		"desc": "灵铁锻造，身轻如燕",
		"equippable": true, "slot": "boots",
		"stats": {"defense": 8, "speed": 0.08},
		"durability": 400,
	},
	# -- Tier 3 玉灵甲套 --
	"jade_helmet": {
		"name": "玉灵冠", "category": ItemCategory.ARMOR, "quality": Quality.EPIC,
		"tier": 3, "stackable": false, "max_stack": 1,
		"icon": "jade_helmet", "sell_price": 600,
		"desc": "灵玉冠冕，灵力汇聚",
		"equippable": true, "slot": "helmet",
		"stats": {"defense": 30, "max_hp": 100, "spell_power": 10},
		"durability": 1000,
	},
	"jade_chestplate": {
		"name": "玉灵甲", "category": ItemCategory.ARMOR, "quality": Quality.EPIC,
		"tier": 3, "stackable": false, "max_stack": 1,
		"icon": "jade_chestplate", "sell_price": 1000,
		"desc": "玉灵锻造的宝甲，刀枪不入",
		"equippable": true, "slot": "armor",
		"stats": {"defense": 50, "max_hp": 200},
		"durability": 1500,
	},
	"jade_legs": {
		"name": "玉灵护膝", "category": ItemCategory.ARMOR, "quality": Quality.EPIC,
		"tier": 3, "stackable": false, "max_stack": 1,
		"icon": "jade_legs", "sell_price": 500,
		"desc": "玉灵护膝，灵力贯通",
		"equippable": true, "slot": "legs",
		"stats": {"defense": 20, "speed": 0.05, "max_hp": 50},
		"durability": 1000,
	},
	"jade_boots": {
		"name": "玉灵靴", "category": ItemCategory.ARMOR, "quality": Quality.EPIC,
		"tier": 3, "stackable": false, "max_stack": 1,
		"icon": "jade_boots", "sell_price": 450,
		"desc": "玉灵靴，踏空而行",
		"equippable": true, "slot": "boots",
		"stats": {"defense": 12, "speed": 0.15},
		"durability": 800,
	},
	# -- Tier 4 玉晶套 --
	"crystal_helmet": {
		"name": "玉晶冠", "category": ItemCategory.ARMOR, "quality": Quality.EPIC,
		"tier": 4, "stackable": false, "max_stack": 1,
		"icon": "crystal_helmet", "sell_price": 3000,
		"desc": "玉晶冠冕，元婴神识",
		"equippable": true, "slot": "helmet",
		"stats": {"defense": 60, "max_hp": 300, "spell_power": 30},
		"durability": 2000,
	},
	"crystal_chestplate": {
		"name": "玉晶甲", "category": ItemCategory.ARMOR, "quality": Quality.EPIC,
		"tier": 4, "stackable": false, "max_stack": 1,
		"icon": "crystal_chestplate", "sell_price": 5000,
		"desc": "玉晶宝甲，坚不可摧",
		"equippable": true, "slot": "armor",
		"stats": {"defense": 100, "max_hp": 500},
		"durability": 3000,
	},
	"crystal_legs": {
		"name": "玉晶护膝", "category": ItemCategory.ARMOR, "quality": Quality.EPIC,
		"tier": 4, "stackable": false, "max_stack": 1,
		"icon": "crystal_legs", "sell_price": 2500,
		"desc": "玉晶护膝，灵力充盈",
		"equippable": true, "slot": "legs",
		"stats": {"defense": 40, "speed": 0.08, "max_hp": 150},
		"durability": 2000,
	},
	"crystal_boots": {
		"name": "玉晶靴", "category": ItemCategory.ARMOR, "quality": Quality.EPIC,
		"tier": 4, "stackable": false, "max_stack": 1,
		"icon": "crystal_boots", "sell_price": 2000,
		"desc": "玉晶靴，御空飞行",
		"equippable": true, "slot": "boots",
		"stats": {"defense": 20, "speed": 0.25},
		"durability": 1500,
	},
	# -- Tier 6 星辰套 --
	"celestial_helmet": {
		"name": "星辰冠", "category": ItemCategory.ARMOR, "quality": Quality.LEGENDARY,
		"tier": 6, "stackable": false, "max_stack": 1,
		"icon": "celestial_helmet", "sell_price": 30000,
		"desc": "星辰铁所铸，引动星辉护体",
		"equippable": true, "slot": "helmet",
		"stats": {"defense": 120, "max_hp": 800, "spell_power": 80},
		"durability": 4000,
	},
	"celestial_chestplate": {
		"name": "星辰甲", "category": ItemCategory.ARMOR, "quality": Quality.LEGENDARY,
		"tier": 6, "stackable": false, "max_stack": 1,
		"icon": "celestial_chestplate", "sell_price": 50000,
		"desc": "星辰战甲，万法不侵",
		"equippable": true, "slot": "armor",
		"stats": {"defense": 200, "max_hp": 1500},
		"durability": 6000,
	},
	"celestial_legs": {
		"name": "星辰护膝", "category": ItemCategory.ARMOR, "quality": Quality.LEGENDARY,
		"tier": 6, "stackable": false, "max_stack": 1,
		"icon": "celestial_legs", "sell_price": 25000,
		"desc": "星辰之力灌注，步履如飞",
		"equippable": true, "slot": "legs",
		"stats": {"defense": 80, "speed": 0.12, "max_hp": 400},
		"durability": 4000,
	},
	"celestial_boots": {
		"name": "星辰靴", "category": ItemCategory.ARMOR, "quality": Quality.LEGENDARY,
		"tier": 6, "stackable": false, "max_stack": 1,
		"icon": "celestial_boots", "sell_price": 20000,
		"desc": "踏星而行，缩地成寸",
		"equippable": true, "slot": "boots",
		"stats": {"defense": 40, "speed": 0.40},
		"durability": 3000,
	},

	# ==========================================================
	# 🆕 饰品（戒指/护符/腰带/手镯）
	# ==========================================================
	"copper_ring": {
		"name": "铜戒指", "category": ItemCategory.ACCESSORY, "quality": Quality.UNCOMMON,
		"tier": 1, "stackable": false, "max_stack": 1,
		"icon": "copper_ring", "sell_price": 20,
		"desc": "简陋铜戒，略微提升灵气感应",
		"equippable": true, "slot": "ring",
		"stats": {"attack": 2, "spell_power": 3},
		"durability": 100,
	},
	"spirit_belt": {
		"name": "灵纹腰带", "category": ItemCategory.ACCESSORY, "quality": Quality.RARE,
		"tier": 2, "stackable": false, "max_stack": 1,
		"icon": "spirit_belt", "sell_price": 120,
		"desc": "刻有聚灵纹的腰带，提升体力",
		"equippable": true, "slot": "belt",
		"stats": {"max_hp": 80, "max_mp": 30},
		"durability": 200,
	},
	"jade_ring": {
		"name": "玉灵戒", "category": ItemCategory.ACCESSORY, "quality": Quality.EPIC,
		"tier": 3, "stackable": false, "max_stack": 1,
		"icon": "jade_ring", "sell_price": 800,
		"desc": "灵玉戒，灵力澎湃",
		"equippable": true, "slot": "ring",
		"stats": {"attack": 20, "spell_power": 25, "crit_rate": 0.05},
		"durability": 600,
	},
	"jade_amulet": {
		"name": "玉灵坠", "category": ItemCategory.ACCESSORY, "quality": Quality.EPIC,
		"tier": 3, "stackable": false, "max_stack": 1,
		"icon": "jade_amulet", "sell_price": 1000,
		"desc": "万年灵玉吊坠，可抵一次致命伤害",
		"equippable": true, "slot": "amulet",
		"stats": {"defense": 20, "max_hp": 200, "mp_regen": 3},
		"durability": 500,
	},
	"jade_bracelet": {
		"name": "玉灵镯", "category": ItemCategory.ACCESSORY, "quality": Quality.EPIC,
		"tier": 3, "stackable": false, "max_stack": 1,
		"icon": "jade_bracelet", "sell_price": 700,
		"desc": "灵玉手镯，凝聚灵气",
		"equippable": true, "slot": "bracelet",
		"stats": {"spell_power": 15, "max_mp": 100, "mp_regen": 2},
		"durability": 500,
	},
	"crystal_ring": {
		"name": "玉晶戒", "category": ItemCategory.ACCESSORY, "quality": Quality.EPIC,
		"tier": 4, "stackable": false, "max_stack": 1,
		"icon": "crystal_ring", "sell_price": 4000,
		"desc": "玉晶凝成的戒指，蕴含元婴之力",
		"equippable": true, "slot": "ring",
		"stats": {"attack": 50, "spell_power": 60, "crit_rate": 0.08, "crit_damage": 0.3},
		"durability": 1000,
	},
	"crystal_amulet": {
		"name": "玉晶坠", "category": ItemCategory.ACCESSORY, "quality": Quality.EPIC,
		"tier": 4, "stackable": false, "max_stack": 1,
		"icon": "crystal_amulet", "sell_price": 5000,
		"desc": "玉晶吊坠，元婴护体",
		"equippable": true, "slot": "amulet",
		"stats": {"defense": 40, "max_hp": 500, "mp_regen": 5},
		"durability": 1000,
	},
	"celestial_ring": {
		"name": "星辰戒", "category": ItemCategory.ACCESSORY, "quality": Quality.LEGENDARY,
		"tier": 6, "stackable": false, "max_stack": 1,
		"icon": "celestial_ring", "sell_price": 40000,
		"desc": "星辰铁打造，引动星辰之力",
		"equippable": true, "slot": "ring",
		"stats": {"attack": 120, "spell_power": 150, "crit_rate": 0.15, "crit_damage": 0.8},
		"durability": 2000,
	},
	
	# ==================== 配方中的辅助物品 ====================
	
	"glass": {
		"name": "玻璃", "category": ItemCategory.MATERIAL, "tier": 0,
		"stackable": true, "max_stack": 64, "icon": "glass",
		"sell_price": 2, "rarity": "common",
		"desc": "透明的玻璃，可用于制作容器和装饰",
	},
	"rune_speed": {
		"name": "疾风符文", "category": ItemCategory.MATERIAL, "tier": 2,
		"stackable": true, "max_stack": 16, "icon": "rune",
		"sell_price": 20, "rarity": "uncommon",
		"desc": "篆刻风之纹路，镶嵌后增加移动速度",
	},
	"rune_sharp": {
		"name": "锋锐符文", "category": ItemCategory.MATERIAL, "tier": 2,
		"stackable": true, "max_stack": 16, "icon": "rune",
		"sell_price": 20, "rarity": "uncommon",
		"desc": "篆刻锐之纹路，镶嵌后增加攻击力",
	},
	"rune_regen": {
		"name": "再生符文", "category": ItemCategory.MATERIAL, "tier": 2,
		"stackable": true, "max_stack": 16, "icon": "rune",
		"sell_price": 20, "rarity": "uncommon",
		"desc": "篆刻生之纹路，镶嵌后增加生命恢复",
	},
	"rune_fire": {
		"name": "烈焰符文", "category": ItemCategory.MATERIAL, "tier": 2,
		"stackable": true, "max_stack": 16, "icon": "rune",
		"sell_price": 20, "rarity": "uncommon",
		"desc": "篆刻火之纹路，镶嵌后增加火系伤害",
	},
	"rune_tough": {
		"name": "坚韧符文", "category": ItemCategory.MATERIAL, "tier": 2,
		"stackable": true, "max_stack": 16, "icon": "rune",
		"sell_price": 20, "rarity": "uncommon",
		"desc": "篆刻石之纹路，镶嵌后增加防御力",
	},
	"silk_robe": {
		"name": "灵丝法袍", "category": ItemCategory.ARMOR, "tier": 2,
		"stackable": false, "max_stack": 1, "icon": "armor",
		"sell_price": 80, "rarity": "uncommon",
		"desc": "用灵丝编织的法袍，轻盈而坚韧",
		"equippable": true, "slot": "armor",
		"durability": 150, "defense": 8,
		"stats": {"max_mp": 30, "mp_regen": 1},
	},
}

# ==================== 工具方法 ====================

static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})

static func get_item_name(item_id: String) -> String:
	return ITEMS.get(item_id, {}).get("name") or item_id

static func get_item_category(item_id: String) -> int:
	return ITEMS.get(item_id, {}).get("category", -1)

static func get_item_quality(item_id: String) -> int:
	return ITEMS.get(item_id, {}).get("quality") or Quality.COMMON

static func is_stackable(item_id: String) -> bool:
	return ITEMS.get(item_id, {}).get("stackable") or false

static func get_max_stack(item_id: String) -> int:
	return ITEMS.get(item_id, {}).get("max_stack") or 1

static func is_equippable(item_id: String) -> bool:
	return ITEMS.get(item_id, {}).get("equippable") or false

static func get_slot(item_id: String) -> String:
	return ITEMS.get(item_id, {}).get("slot") or ""

static func get_stats(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {}).get("stats", {})

static func get_tier(item_id: String) -> int:
	return ITEMS.get(item_id, {}).get("tier") or 0

## 按分类获取物品列表
static func get_items_by_category(category: int) -> Dictionary:
	var result: Dictionary = {}
	for id in ITEMS.keys():
		if ITEMS[id].get("category", -1) == category:
			result[id] = ITEMS[id]
	return result

## 按境界获取可用物品
static func get_items_for_tier(max_tier: int) -> Dictionary:
	var result: Dictionary = {}
	for id in ITEMS.keys():
		if ITEMS[id].get("tier", 0) <= max_tier:
			result[id] = ITEMS[id]
	return result

## 搜索物品
static func search_items(query: String) -> Dictionary:
	var result: Dictionary = {}
	var q = query.to_lower()
	for id in ITEMS.keys():
		var item = ITEMS[id]
		if q in id.to_lower() or q in item.get("name", "").to_lower():
			result[id] = item
	return result

## 获取所有物品 ID
static func get_all_item_ids() -> Array[String]:
	return ITEMS.keys()
