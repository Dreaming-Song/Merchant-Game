extends Node
## 配方数据库 — 按境界分层，参考MC/DST/Terraria的合成树
##
## 每阶配方按境界解锁：
##   凡→练→筑→金→婴→化→大→渡→飞
##   0   1   2   3   4   5   6   7   8

class_name RecipeDatabase

# ==================== 所有配方 ====================
const RECIPES: Dictionary = {
	# ========== Tier 0：凡人期 ==========
	# -- 基础工具 --
	"stone_axe": {
		"name": "石斧", "category": "tool", "station": "workbench",
		"materials": {"wood": 3, "stone": 2, "vine": 1},
		"result": "stone_axe", "result_count": 1,
		"craft_time": 3.0, "realm_required": 0, "tier": 0,
		"desc": "砍树必备，效率低下但能用",
	},
	"stone_pickaxe": {
		"name": "石镐", "category": "tool", "station": "workbench",
		"materials": {"wood": 3, "stone": 3, "vine": 1},
		"result": "stone_pickaxe", "result_count": 1,
		"craft_time": 3.0, "realm_required": 0, "tier": 0,
		"desc": "挖矿采石，凡人首选",
	},
	"stone_hammer": {
		"name": "石锤", "category": "tool", "station": "workbench",
		"materials": {"wood": 4, "stone": 3},
		"result": "stone_hammer", "result_count": 1,
		"craft_time": 3.0, "realm_required": 0, "tier": 0,
		"desc": "拆解建筑，回收材料",
	},
	"wooden_sword": {
		"name": "木剑", "category": "weapon", "station": "workbench",
		"materials": {"wood": 5, "vine": 2},
		"result": "wooden_sword", "result_count": 1,
		"craft_time": 2.0, "realm_required": 0, "tier": 0,
		"desc": "粗制滥造的木剑，聊胜于无",
	},
	"wooden_bow": {
		"name": "木弓", "category": "weapon", "station": "workbench",
		"materials": {"wood": 4, "vine": 3},
		"result": "wooden_bow", "result_count": 1,
		"craft_time": 3.0, "realm_required": 0, "tier": 0,
		"desc": "简易木弓，远程防身",
	},
	
	# -- 基础建筑 --
	"thatch_wall": {
		"name": "茅草墙", "category": "building", "station": "",
		"materials": {"thatch": 4, "wood": 2},
		"result": "thatch_wall", "result_count": 1,
		"craft_time": 2.0, "realm_required": 0, "tier": 0,
		"desc": "最简陋的墙，风吹就倒",
	},
	"thatch_floor": {
		"name": "茅草地板", "category": "building", "station": "",
		"materials": {"thatch": 2, "wood": 1},
		"result": "thatch_floor", "result_count": 1,
		"craft_time": 1.5, "realm_required": 0, "tier": 0,
		"desc": "踩着还算干爽",
	},
	"wooden_wall": {
		"name": "木墙", "category": "building", "station": "workbench",
		"materials": {"wood": 4},
		"result": "wooden_wall", "result_count": 1,
		"craft_time": 3.0, "realm_required": 0, "tier": 0,
		"desc": "厚实木墙，遮风挡雨",
	},
	"wooden_door": {
		"name": "木门", "category": "building", "station": "workbench",
		"materials": {"wood": 6},
		"result": "wooden_door", "result_count": 1,
		"craft_time": 4.0, "realm_required": 0, "tier": 0,
		"desc": "有门才有家",
	},
	"wooden_chest": {
		"name": "木箱", "category": "storage", "station": "workbench",
		"materials": {"wood": 8, "stone": 2},
		"result": "wooden_chest", "result_count": 1,
		"craft_time": 5.0, "realm_required": 0, "tier": 0,
		"desc": "20格存储空间",
	},
	"campfire": {
		"name": "篝火", "category": "utility", "station": "",
		"materials": {"wood": 3, "stone": 3},
		"result": "campfire", "result_count": 1,
		"craft_time": 2.0, "realm_required": 0, "tier": 0,
		"desc": "照亮黑夜，烧制食物，驱散野兽",
	},
	"workbench": {
		"name": "工作台", "category": "station", "station": "",
		"materials": {"wood": 6, "stone": 3},
		"result": "workbench", "result_count": 1,
		"craft_time": 5.0, "realm_required": 0, "tier": 0,
		"desc": "万物合成之始，基础制造站",
	},
	"wooden_bed": {
		"name": "木床", "category": "furniture", "station": "workbench",
		"materials": {"wood": 8, "thatch": 5},
		"result": "wooden_bed", "result_count": 1,
		"craft_time": 6.0, "realm_required": 0, "tier": 0,
		"desc": "睡一觉恢复生命，设置重生点",
	},
	"torch": {
		"name": "火把", "category": "utility", "station": "",
		"materials": {"wood": 1, "vine": 1},
		"result": "torch", "result_count": 4,
		"craft_time": 1.0, "realm_required": 0, "tier": 0,
		"desc": "插在墙上或手持照明",
	},
	
	# -- 草甲套（Tier 0，工作台） --
	"straw_hat": {
		"name": "草帽", "category": "armor", "station": "workbench",
		"materials": {"thatch": 3, "vine": 1},
		"result": "straw_hat", "result_count": 1,
		"craft_time": 2.0, "realm_required": 0, "tier": 0,
		"desc": "茅草编的帽子，遮阳尚可",
	},
	"grass_armor": {
		"name": "草甲", "category": "armor", "station": "workbench",
		"materials": {"thatch": 5, "vine": 2},
		"result": "grass_armor", "result_count": 1,
		"craft_time": 3.0, "realm_required": 0, "tier": 0,
		"desc": "藤蔓编的简易胸甲",
	},
	"grass_skirt": {
		"name": "草裙", "category": "armor", "station": "workbench",
		"materials": {"thatch": 3, "vine": 1},
		"result": "grass_skirt", "result_count": 1,
		"craft_time": 2.0, "realm_required": 0, "tier": 0,
		"desc": "遮羞防晒，走起来沙沙响",
	},
	"straw_sandals": {
		"name": "草鞋", "category": "armor", "station": "workbench",
		"materials": {"thatch": 2, "vine": 1},
		"result": "straw_sandals", "result_count": 1,
		"craft_time": 1.5, "realm_required": 0, "tier": 0,
		"desc": "走山路不硌脚",
	},
	"wood_ring": {
		"name": "木戒", "category": "accessory", "station": "workbench",
		"materials": {"wood": 3, "vine": 1},
		"result": "wood_ring", "result_count": 1,
		"craft_time": 2.0, "realm_required": 0, "tier": 0,
		"desc": "粗糙木戒指，+5 灵气上限",
	},
	
	# ========== Tier 1：练气期 ==========
	"iron_axe": {
		"name": "铁斧", "category": "tool", "station": "workbench",
		"materials": {"wood": 2, "iron_ingot": 3},
		"result": "iron_axe", "result_count": 1,
		"craft_time": 5.0, "realm_required": 1, "tier": 1,
		"desc": "锋利铁斧，砍树效率翻倍",
	},
	"iron_pickaxe": {
		"name": "铁镐", "category": "tool", "station": "workbench",
		"materials": {"wood": 2, "iron_ingot": 4},
		"result": "iron_pickaxe", "result_count": 1,
		"craft_time": 5.0, "realm_required": 1, "tier": 1,
		"desc": "能挖铁矿和灵石",
	},
	"iron_sword": {
		"name": "铁剑", "category": "weapon", "station": "workbench",
		"materials": {"wood": 2, "iron_ingot": 5},
		"result": "iron_sword", "result_count": 1,
		"craft_time": 6.0, "realm_required": 1, "tier": 1,
		"desc": "百炼精铁剑，凡人利器",
	},
	"furnace": {
		"name": "熔炉", "category": "station", "station": "workbench",
		"materials": {"stone": 10, "wood": 5},
		"result": "furnace", "result_count": 1,
		"craft_time": 8.0, "realm_required": 1, "tier": 1,
		"desc": "冶炼金属，烧制陶瓷",
	},
	"stone_wall": {
		"name": "石墙", "category": "building", "station": "workbench",
		"materials": {"stone": 4},
		"result": "stone_wall", "result_count": 1,
		"craft_time": 4.0, "realm_required": 1, "tier": 1,
		"desc": "厚实石墙，防御力大幅提升",
	},
	"herb_garden": {
		"name": "灵田", "category": "farming", "station": "",
		"materials": {"wood": 4, "stone": 4, "dirt": 6},
		"result": "herb_garden", "result_count": 1,
		"craft_time": 8.0, "realm_required": 1, "tier": 1,
		"desc": "种植灵草药材的田地",
	},
	"alchemy_furnace": {
		"name": "炼丹炉", "category": "station", "station": "workbench",
		"materials": {"iron_ingot": 4, "stone": 8},
		"result": "alchemy_furnace", "result_count": 1,
		"craft_time": 8.0, "realm_required": 1, "tier": 1,
		"desc": "炼制基础丹药",
	},
	"qi_recovery_pill": {
		"name": "回气丹", "category": "alchemy", "station": "alchemy_furnace",
		"materials": {"herb_qi": 3, "herb_common": 2},
		"result": "qi_recovery_pill", "result_count": 3,
		"craft_time": 4.0, "realm_required": 1, "tier": 1,
		"desc": "恢复50点法力",
	},
	"basic_talisman": {
		"name": "基础符箓", "category": "talisman", "station": "workbench",
		"materials": {"paper": 2, "herb_qi": 1, "ink": 1},
		"result": "basic_talisman", "result_count": 2,
		"craft_time": 5.0, "realm_required": 1, "tier": 1,
		"desc": "释放一道基础五行法术",
	},
	
	# ========== Tier 2：筑基期 ==========
	"spirit_iron_sword": {
		"name": "灵铁剑", "category": "weapon", "station": "furnace",
		"materials": {"spirit_iron": 5, "spirit_stone": 2},
		"result": "spirit_iron_sword", "result_count": 1,
		"craft_time": 10.0, "realm_required": 2, "tier": 2,
		"desc": "附灵铁剑，可灌注灵力",
	},
	"brick_wall": {
		"name": "灵砖墙", "category": "building", "station": "furnace",
		"materials": {"spirit_brick": 4},
		"result": "brick_wall", "result_count": 1,
		"craft_time": 5.0, "realm_required": 2, "tier": 2,
		"desc": "灵气灌注的砖墙，坚固且美观",
	},
	"spirit_chest": {
		"name": "灵木箱", "category": "storage", "station": "workbench",
		"materials": {"spirit_wood": 6, "spirit_stone": 2},
		"result": "spirit_chest", "result_count": 1,
		"craft_time": 6.0, "realm_required": 2, "tier": 2,
		"desc": "40格存储空间",
	},
	"spirit_furnace": {
		"name": "灵熔炉", "category": "station", "station": "furnace",
		"materials": {"spirit_stone": 10, "iron_ingot": 5},
		"result": "spirit_furnace", "result_count": 1,
		"craft_time": 10.0, "realm_required": 2, "tier": 2,
		"desc": "精炼灵矿，锻造法器",
	},
	"spirit_lamp": {
		"name": "灵灯", "category": "decoration", "station": "workbench",
		"materials": {"spirit_stone": 2, "iron_ingot": 1},
		"result": "spirit_lamp", "result_count": 1,
		"craft_time": 3.0, "realm_required": 2, "tier": 2,
		"desc": "散发柔和灵光，照亮大片区域",
	},
	"spirit_door": {
		"name": "灵木门", "category": "building", "station": "workbench",
		"materials": {"spirit_wood": 6, "spirit_stone": 1},
		"result": "spirit_door", "result_count": 1,
		"craft_time": 5.0, "realm_required": 2, "tier": 2,
		"desc": "灵气加持的门，更坚固",
	},
	"foundation_pill": {
		"name": "筑基丹", "category": "alchemy", "station": "alchemy_furnace",
		"materials": {"herb_spirit": 5, "herb_qi": 3, "spirit_stone": 2},
		"result": "foundation_pill", "result_count": 1,
		"craft_time": 12.0, "realm_required": 2, "tier": 2,
		"desc": "突破筑基期的必须丹药",
	},
	
	# ========== Tier 3：金丹期 ==========
	"jade_sword": {
		"name": "玉灵剑", "category": "weapon", "station": "spirit_furnace",
		"materials": {"spirit_jade": 5, "gold_ingot": 3, "spirit_stone": 5},
		"result": "jade_sword", "result_count": 1,
		"craft_time": 20.0, "realm_required": 3, "tier": 3,
		"desc": "灵玉锻造，可飞行御剑",
	},
	"jade_wall": {
		"name": "灵石墙", "category": "building", "station": "spirit_furnace",
		"materials": {"spirit_stone": 4},
		"result": "jade_wall", "result_count": 1,
		"craft_time": 8.0, "realm_required": 3, "tier": 3,
		"desc": "灵石堆砌，灵气充盈",
	},
	"spirit_armor": {
		"name": "灵气甲", "category": "armor", "station": "spirit_furnace",
		"materials": {"spirit_iron": 8, "spirit_stone": 4, "gold_ingot": 2},
		"result": "spirit_armor", "result_count": 1,
		"craft_time": 15.0, "realm_required": 3, "tier": 3,
		"desc": "灵气护甲，大幅提升防御",
	},
	"protection_array": {
		"name": "护山大阵", "category": "building", "station": "spirit_furnace",
		"materials": {"spirit_stone": 20, "spirit_jade": 5, "gold_ingot": 5},
		"result": "protection_array", "result_count": 1,
		"craft_time": 30.0, "realm_required": 3, "tier": 3,
		"desc": "守护整片领地的结界大阵",
	},
	"golden_core_pill": {
		"name": "凝金丹", "category": "alchemy", "station": "alchemy_furnace",
		"materials": {"herb_spirit": 8, "beast_core": 3, "spirit_jade": 2},
		"result": "golden_core_pill", "result_count": 1,
		"craft_time": 20.0, "realm_required": 3, "tier": 3,
		"desc": "凝结金丹的必须丹药",
	},
	"flying_sword": {
		"name": "飞剑", "category": "transport", "station": "spirit_furnace",
		"materials": {"spirit_iron": 10, "spirit_jade": 3, "gold_ingot": 5},
		"result": "flying_sword", "result_count": 1,
		"craft_time": 25.0, "realm_required": 3, "tier": 3,
		"desc": "御剑飞行，遨游天地",
	},
	
	# ========== Tier 4：元婴期 ==========
	"crystal_wall": {
		"name": "玉晶墙", "category": "building", "station": "spirit_furnace",
		"materials": {"spirit_crystal": 4},
		"result": "crystal_wall", "result_count": 1,
		"craft_time": 10.0, "realm_required": 4, "tier": 4,
		"desc": "通体透明的晶壁，坚不可摧",
	},
	"teleport_array": {
		"name": "传送阵", "category": "building", "station": "spirit_furnace",
		"materials": {"spirit_crystal": 10, "spirit_stone": 20, "spirit_jade": 5},
		"result": "teleport_array", "result_count": 1,
		"craft_time": 40.0, "realm_required": 4, "tier": 4,
		"desc": "瞬间传送至绑定的其他传送阵",
	},
	"nascent_soul_pill": {
		"name": "化婴丹", "category": "alchemy", "station": "alchemy_furnace",
		"materials": {"herb_celestial": 5, "beast_core": 5, "spirit_crystal": 3},
		"result": "nascent_soul_pill", "result_count": 1,
		"craft_time": 30.0, "realm_required": 4, "tier": 4,
		"desc": "碎丹成婴的必须丹药",
	},
	"pocket_dimension": {
		"name": "洞天福地", "category": "building", "station": "spirit_furnace",
		"materials": {"spirit_crystal": 20, "spirit_jade": 10, "spirit_stone": 50},
		"result": "pocket_dimension", "result_count": 1,
		"craft_time": 60.0, "realm_required": 4, "tier": 4,
		"desc": "开辟独立空间作为洞府",
	},
	
	# ========== Tier 5+：化神及以上（简略） ==========
	"floating_island": {
		"name": "浮空平台", "category": "building", "station": "spirit_furnace",
		"materials": {"spirit_crystal": 30, "celestial_stone": 10, "spirit_stone": 100},
		"result": "floating_island", "result_count": 1,
		"craft_time": 120.0, "realm_required": 5, "tier": 5,
		"desc": "悬浮于空中的平台，建造天空之城的基础",
	},
	"artifact_sword": {
		"name": "后天灵宝·斩仙", "category": "weapon", "station": "spirit_furnace",
		"materials": {"celestial_iron": 10, "dragon_scale": 3, "phoenix_feather": 3},
		"result": "artifact_sword", "result_count": 1,
		"craft_time": 120.0, "realm_required": 6, "tier": 6,
		"desc": "后天灵宝，一剑可斩山河",
	},
	
	# ========== 铁砧（ANVIL）配方 ==========
	"anvil": {
		"name": "铁砧", "category": "station", "station": "furnace",
		"materials": {"iron_ingot": 8, "stone": 4},
		"result": "anvil", "result_count": 1,
		"craft_time": 8.0, "realm_required": 1, "tier": 1,
		"desc": "锻造高级武器和护甲的工作站",
	},
	"iron_helmet": {
		"name": "铁头盔", "category": "armor", "station": "anvil",
		"materials": {"iron_ingot": 5},
		"result": "iron_helmet", "result_count": 1,
		"craft_time": 6.0, "realm_required": 1, "tier": 1,
		"desc": "基础铁质头盔",
	},
	"iron_armor": {
		"name": "铁甲", "category": "armor", "station": "anvil",
		"materials": {"iron_ingot": 8},
		"result": "iron_armor", "result_count": 1,
		"craft_time": 8.0, "realm_required": 1, "tier": 1,
		"desc": "铁制板甲，结实可靠",
	},
	"iron_greaves": {
		"name": "铁护腿", "category": "armor", "station": "anvil",
		"materials": {"iron_ingot": 6},
		"result": "iron_greaves", "result_count": 1,
		"craft_time": 7.0, "realm_required": 1, "tier": 1,
		"desc": "铁制腿甲，大幅度提升下盘防御",
	},
	"spirit_helmet": {
		"name": "灵铁头盔", "category": "armor", "station": "anvil",
		"materials": {"spirit_iron": 5, "spirit_stone": 2},
		"result": "spirit_helmet", "result_count": 1,
		"craft_time": 10.0, "realm_required": 2, "tier": 2,
		"desc": "灵铁锻造，灵气护体",
	},
	"spirit_chestplate": {
		"name": "灵铁胸甲", "category": "armor", "station": "anvil",
		"materials": {"spirit_iron": 8, "spirit_stone": 3},
		"result": "spirit_chestplate", "result_count": 1,
		"craft_time": 12.0, "realm_required": 2, "tier": 2,
		"desc": "灵铁胸甲，防御大增",
	},
	
	# ========== 织布机（LOOM）配方 ==========
	"loom": {
		"name": "织布机", "category": "station", "station": "workbench",
		"materials": {"wood": 8, "vine": 4},
		"result": "loom", "result_count": 1,
		"craft_time": 6.0, "realm_required": 0, "tier": 0,
		"desc": "编织布料和防具的工作站",
	},
	"cloth": {
		"name": "布匹", "category": "material", "station": "loom",
		"materials": {"vine": 4, "silk": 2},
		"result": "cloth", "result_count": 2,
		"craft_time": 3.0, "realm_required": 0, "tier": 0,
		"desc": "基础布料，制作防具的原材料",
	},
	
	# -- 皮甲套（Tier 1，织布机） --
	"leather_helmet": {
		"name": "皮帽", "category": "armor", "station": "loom",
		"materials": {"cloth": 2, "leather": 2},
		"result": "leather_helmet", "result_count": 1,
		"craft_time": 4.0, "realm_required": 1, "tier": 1,
		"desc": "鞣制皮革帽，轻便耐用",
	},
	"leather_armor": {
		"name": "皮甲", "category": "armor", "station": "loom",
		"materials": {"cloth": 3, "leather": 3},
		"result": "leather_armor", "result_count": 1,
		"craft_time": 5.0, "realm_required": 1, "tier": 1,
		"desc": "厚实皮革胸甲，能挡野兽爪牙",
	},
	"leather_pants": {
		"name": "皮裤", "category": "armor", "station": "loom",
		"materials": {"cloth": 2, "leather": 2},
		"result": "leather_pants", "result_count": 1,
		"craft_time": 4.0, "realm_required": 1, "tier": 1,
		"desc": "护腿，行动灵活不失防护",
	},
	"leather_boots": {
		"name": "皮靴", "category": "armor", "station": "loom",
		"materials": {"cloth": 2, "leather": 1},
		"result": "leather_boots", "result_count": 1,
		"craft_time": 3.5, "realm_required": 1, "tier": 1,
		"desc": "结实的皮靴，越野跋涉不在话下",
	},
	"leather_belt": {
		"name": "皮带", "category": "accessory", "station": "loom",
		"materials": {"leather": 2, "cloth": 1},
		"result": "leather_belt", "result_count": 1,
		"craft_time": 3.0, "realm_required": 1, "tier": 1,
		"desc": "宽皮腰带，+10 血量上限",
	},
	"cloth_robe": {
		"name": "布衣", "category": "armor", "station": "loom",
		"materials": {"cloth": 4, "vine": 2},
		"result": "cloth_robe", "result_count": 1,
		"craft_time": 4.0, "realm_required": 0, "tier": 0,
		"desc": "基础布衣，聊胜于无",
	},
	"silk_robe": {
		"name": "灵丝绸衣", "category": "armor", "station": "loom",
		"materials": {"silk": 6, "cloth": 2},
		"result": "silk_robe", "result_count": 1,
		"craft_time": 8.0, "realm_required": 2, "tier": 2,
		"desc": "灵丝编织，轻便而坚韧",
	},
	
	# ========== 符文台（RUNE_TABLE）配方 ==========
	"rune_table": {
		"name": "符文台", "category": "station", "station": "workbench",
		"materials": {"stone": 10, "spirit_stone": 5, "ink": 3},
		"result": "rune_table", "result_count": 1,
		"craft_time": 12.0, "realm_required": 1, "tier": 1,
		"desc": "铭刻符文、附魔装备的工作站",
	},
	"rune_sharp": {
		"name": "锋锐符文", "category": "rune", "station": "rune_table",
		"materials": {"spirit_stone": 2, "ink": 2},
		"result": "rune_sharp", "result_count": 1,
		"craft_time": 5.0, "realm_required": 1, "tier": 1,
		"desc": "武器附魔：增加10%攻击力",
	},
	"rune_tough": {
		"name": "坚韧符文", "category": "rune", "station": "rune_table",
		"materials": {"spirit_stone": 2, "ink": 2},
		"result": "rune_tough", "result_count": 1,
		"craft_time": 5.0, "realm_required": 1, "tier": 1,
		"desc": "防具附魔：增加10%防御力",
	},
	"rune_speed": {
		"name": "神行符文", "category": "rune", "station": "rune_table",
		"materials": {"spirit_stone": 3, "ink": 2, "herb_qi": 2},
		"result": "rune_speed", "result_count": 1,
		"craft_time": 6.0, "realm_required": 1, "tier": 1,
		"desc": "鞋子附魔：增加15%移速",
	},
	"rune_regen": {
		"name": "回春符文", "category": "rune", "station": "rune_table",
		"materials": {"spirit_stone": 3, "ink": 3, "herb_spirit": 2},
		"result": "rune_regen", "result_count": 1,
		"craft_time": 8.0, "realm_required": 2, "tier": 2,
		"desc": "装备附魔：每秒恢复0.5%生命",
	},
	"rune_fire": {
		"name": "烈焰符文", "category": "rune", "station": "rune_table",
		"materials": {"spirit_stone": 5, "ink": 3, "fire_essence": 2},
		"result": "rune_fire", "result_count": 1,
		"craft_time": 10.0, "realm_required": 2, "tier": 2,
		"desc": "武器附魔：额外火焰伤害",
	},
	
	# ========== 熔炉新增配方 ==========
	"iron_ingot": {
		"name": "铁锭", "category": "material", "station": "furnace",
		"materials": {"iron_ore": 2},
		"result": "iron_ingot", "result_count": 1,
		"craft_time": 4.0, "realm_required": 0, "tier": 0,
		"desc": "冶炼铁矿石得到铁锭",
	},
	"gold_ingot": {
		"name": "金锭", "category": "material", "station": "furnace",
		"materials": {"gold_ore": 2},
		"result": "gold_ingot", "result_count": 1,
		"craft_time": 4.0, "realm_required": 1, "tier": 1,
		"desc": "冶炼金矿得到金锭",
	},
	"spirit_iron": {
		"name": "灵铁", "category": "material", "station": "furnace",
		"materials": {"spirit_ore": 2},
		"result": "spirit_iron", "result_count": 1,
		"craft_time": 6.0, "realm_required": 1, "tier": 1,
		"desc": "冶炼灵矿得到灵铁",
	},
	"spirit_brick": {
		"name": "灵砖", "category": "material", "station": "furnace",
		"materials": {"stone": 2, "spirit_stone": 1},
		"result": "spirit_brick", "result_count": 2,
		"craft_time": 5.0, "realm_required": 2, "tier": 2,
		"desc": "灌注灵气的砖块",
	},
	"glass": {
		"name": "玻璃", "category": "material", "station": "furnace",
		"materials": {"sand": 2},
		"result": "glass", "result_count": 2,
		"craft_time": 3.0, "realm_required": 1, "tier": 1,
		"desc": "烧制玻璃，用于窗户",
	},
	
	# ==========================================================
	# 🆕 Tier 0 凡人 · 新工具/武器/防具
	# ==========================================================
	"stone_shovel": {
		"name": "石锹", "category": "tool", "station": "workbench",
		"materials": {"wood": 2, "stone": 2},
		"result": "stone_shovel", "result_count": 1,
		"craft_time": 2.5, "realm_required": 0, "tier": 0,
		"desc": "挖土铲沙，手工作坊出品",
	},
	"stone_scythe": {
		"name": "石镰", "category": "tool", "station": "workbench",
		"materials": {"wood": 2, "stone": 2, "vine": 1},
		"result": "stone_scythe", "result_count": 1,
		"craft_time": 2.5, "realm_required": 0, "tier": 0,
		"desc": "采集草药藤蔓",
	},
	"stone_dagger": {
		"name": "石匕首", "category": "weapon", "station": "workbench",
		"materials": {"stone": 3, "wood": 1, "vine": 1},
		"result": "stone_dagger", "result_count": 1,
		"craft_time": 2.0, "realm_required": 0, "tier": 0,
		"desc": "磨尖的燧石匕首",
	},
	"wooden_staff": {
		"name": "木杖", "category": "weapon", "station": "workbench",
		"materials": {"wood": 6, "vine": 2},
		"result": "wooden_staff", "result_count": 1,
		"craft_time": 3.0, "realm_required": 0, "tier": 0,
		"desc": "粗糙的木制法杖",
	},
	"fishing_rod_wooden": {
		"name": "木钓竿", "category": "tool", "station": "workbench",
		"materials": {"wood": 4, "vine": 3},
		"result": "fishing_rod_wooden", "result_count": 1,
		"craft_time": 3.0, "realm_required": 0, "tier": 0,
		"desc": "普通木钓竿，能在水域钓鱼",
	},
	"cloth_helmet": {
		"name": "布帽", "category": "armor", "station": "loom",
		"materials": {"cloth": 2},
		"result": "cloth_helmet", "result_count": 1,
		"craft_time": 2.0, "realm_required": 0, "tier": 0,
		"desc": "简陋布帽",
	},
	"cloth_legs": {
		"name": "布裤", "category": "armor", "station": "loom",
		"materials": {"cloth": 3},
		"result": "cloth_legs", "result_count": 1,
		"craft_time": 2.5, "realm_required": 0, "tier": 0,
		"desc": "粗布裤子",
	},
	"cloth_boots": {
		"name": "布鞋", "category": "armor", "station": "loom",
		"materials": {"cloth": 2},
		"result": "cloth_boots", "result_count": 1,
		"craft_time": 2.0, "realm_required": 0, "tier": 0,
		"desc": "普通布鞋",
	},
	
	# ==========================================================
	# 🆕 Tier 1 练气 · 铁器/铜饰品
	# ==========================================================
	"iron_shovel": {
		"name": "铁锹", "category": "tool", "station": "anvil",
		"materials": {"wood": 2, "iron_ingot": 3},
		"result": "iron_shovel", "result_count": 1,
		"craft_time": 5.0, "realm_required": 1, "tier": 1,
		"desc": "挖土效率2倍",
	},
	"iron_hammer": {
		"name": "铁锤", "category": "tool", "station": "anvil",
		"materials": {"wood": 3, "iron_ingot": 4},
		"result": "iron_hammer", "result_count": 1,
		"craft_time": 6.0, "realm_required": 1, "tier": 1,
		"desc": "拆解建筑效率更高",
	},
	"iron_scythe": {
		"name": "铁镰", "category": "tool", "station": "anvil",
		"materials": {"wood": 2, "iron_ingot": 3},
		"result": "iron_scythe", "result_count": 1,
		"craft_time": 5.0, "realm_required": 1, "tier": 1,
		"desc": "采集效率2倍",
	},
	"iron_bow": {
		"name": "铁弓", "category": "weapon", "station": "anvil",
		"materials": {"wood": 3, "iron_ingot": 4, "vine": 2},
		"result": "iron_bow", "result_count": 1,
		"craft_time": 7.0, "realm_required": 1, "tier": 1,
		"desc": "铁骨弓，远程利器",
	},
	"iron_spear": {
		"name": "铁枪", "category": "weapon", "station": "anvil",
		"materials": {"wood": 3, "iron_ingot": 6},
		"result": "iron_spear", "result_count": 1,
		"craft_time": 7.0, "realm_required": 1, "tier": 1,
		"desc": "百炼铁枪",
	},
	"iron_dagger": {
		"name": "铁匕首", "category": "weapon", "station": "anvil",
		"materials": {"iron_ingot": 3, "wood": 1},
		"result": "iron_dagger", "result_count": 1,
		"craft_time": 4.0, "realm_required": 1, "tier": 1,
		"desc": "轻便铁匕首",
	},
	"iron_boots": {
		"name": "铁靴", "category": "armor", "station": "anvil",
		"materials": {"iron_ingot": 4, "leather": 2},
		"result": "iron_boots", "result_count": 1,
		"craft_time": 5.0, "realm_required": 1, "tier": 1,
		"desc": "铁靴厚重",
	},
	"copper_ring": {
		"name": "铜戒指", "category": "accessory", "station": "anvil",
		"materials": {"copper_ingot": 3, "spirit_stone": 1},
		"result": "copper_ring", "result_count": 1,
		"craft_time": 4.0, "realm_required": 1, "tier": 1,
		"desc": "简陋铜戒",
	},
	"copper_amulet": {
		"name": "铜护符", "category": "accessory", "station": "anvil",
		"materials": {"copper_ingot": 4, "spirit_stone": 2, "vine": 2},
		"result": "copper_amulet", "result_count": 1,
		"craft_time": 5.0, "realm_required": 1, "tier": 1,
		"desc": "铜制护符",
	},
	# -- 熔炉/织布机补充 --
	"leather": {
		"name": "皮革", "category": "material", "station": "loom",
		"materials": {"vine": 3, "herb_common": 1},
		"result": "leather", "result_count": 1,
		"craft_time": 3.0, "realm_required": 0, "tier": 0,
		"desc": "鞣制过的兽皮",
	},
	"silk": {
		"name": "灵丝", "category": "material", "station": "loom",
		"materials": {"vine": 4, "spirit_stone": 1, "herb_qi": 2},
		"result": "silk", "result_count": 2,
		"craft_time": 5.0, "realm_required": 1, "tier": 1,
		"desc": "灵蚕吐出的丝线",
	},
	
	# ==========================================================
	# 🆕 Tier 2 筑基 · 灵铁工具/武器/防具/饰品
	# ==========================================================
	"spirit_shovel": {
		"name": "灵铁锹", "category": "tool", "station": "anvil",
		"materials": {"spirit_iron": 3, "spirit_wood": 2},
		"result": "spirit_shovel", "result_count": 1,
		"craft_time": 8.0, "realm_required": 2, "tier": 2,
		"desc": "灵铁锻造，挖土效率3倍",
	},
	"spirit_scythe": {
		"name": "灵铁镰", "category": "tool", "station": "anvil",
		"materials": {"spirit_iron": 3, "spirit_wood": 2},
		"result": "spirit_scythe", "result_count": 1,
		"craft_time": 8.0, "realm_required": 2, "tier": 2,
		"desc": "采集效率3倍",
	},
	"spirit_hammer": {
		"name": "灵铁锤", "category": "tool", "station": "anvil",
		"materials": {"spirit_iron": 5, "spirit_wood": 2},
		"result": "spirit_hammer", "result_count": 1,
		"craft_time": 10.0, "realm_required": 2, "tier": 2,
		"desc": "灵铁重锤",
	},
	"fishing_rod_spirit": {
		"name": "灵丝钓竿", "category": "tool", "station": "workbench",
		"materials": {"silk": 4, "spirit_wood": 3, "spirit_iron": 2},
		"result": "fishing_rod_spirit", "result_count": 1,
		"craft_time": 8.0, "realm_required": 2, "tier": 2,
		"desc": "灵丝钓竿",
	},
	"spirit_bow": {
		"name": "灵铁弓", "category": "weapon", "station": "anvil",
		"materials": {"spirit_iron": 5, "silk": 2},
		"result": "spirit_bow", "result_count": 1,
		"craft_time": 12.0, "realm_required": 2, "tier": 2,
		"desc": "灵铁弓弦",
	},
	"spirit_staff": {
		"name": "灵铁杖", "category": "weapon", "station": "anvil",
		"materials": {"spirit_iron": 4, "spirit_wood": 4, "spirit_stone": 2},
		"result": "spirit_staff", "result_count": 1,
		"craft_time": 12.0, "realm_required": 2, "tier": 2,
		"desc": "铭刻灵纹的法杖",
	},
	"spirit_spear": {
		"name": "灵铁枪", "category": "weapon", "station": "anvil",
		"materials": {"spirit_iron": 6, "spirit_wood": 2},
		"result": "spirit_spear", "result_count": 1,
		"craft_time": 12.0, "realm_required": 2, "tier": 2,
		"desc": "灵铁长枪",
	},
	"spirit_legs": {
		"name": "灵铁护腿", "category": "armor", "station": "anvil",
		"materials": {"spirit_iron": 5, "spirit_stone": 2},
		"result": "spirit_legs", "result_count": 1,
		"craft_time": 10.0, "realm_required": 2, "tier": 2,
		"desc": "灵铁护腿",
	},
	"spirit_boots": {
		"name": "灵铁靴", "category": "armor", "station": "anvil",
		"materials": {"spirit_iron": 4, "leather": 2},
		"result": "spirit_boots", "result_count": 1,
		"craft_time": 8.0, "realm_required": 2, "tier": 2,
		"desc": "灵铁靴",
	},
	"spirit_ring": {
		"name": "灵铁戒", "category": "accessory", "station": "anvil",
		"materials": {"spirit_iron": 2, "spirit_stone": 3},
		"result": "spirit_ring", "result_count": 1,
		"craft_time": 8.0, "realm_required": 2, "tier": 2,
		"desc": "灵铁戒指",
	},
	"spirit_amulet": {
		"name": "灵玉坠", "category": "accessory", "station": "anvil",
		"materials": {"spirit_jade": 1, "spirit_stone": 3, "silk": 2},
		"result": "spirit_amulet", "result_count": 1,
		"craft_time": 10.0, "realm_required": 2, "tier": 2,
		"desc": "灵玉吊坠",
	},
	"spirit_bracelet": {
		"name": "灵纹镯", "category": "accessory", "station": "anvil",
		"materials": {"spirit_iron": 3, "spirit_stone": 2},
		"result": "spirit_bracelet", "result_count": 1,
		"craft_time": 8.0, "realm_required": 2, "tier": 2,
		"desc": "刻有防御阵法的灵纹镯",
	},
	"spirit_belt": {
		"name": "灵纹腰带", "category": "accessory", "station": "loom",
		"materials": {"silk": 4, "spirit_stone": 2, "leather": 2},
		"result": "spirit_belt", "result_count": 1,
		"craft_time": 8.0, "realm_required": 2, "tier": 2,
		"desc": "刻有聚灵纹的腰带",
	},
	"fire_essence": {
		"name": "火灵精", "category": "material", "station": "spirit_furnace",
		"materials": {"spirit_stone": 3, "copper_ingot": 2, "herb_qi": 2},
		"result": "fire_essence", "result_count": 1,
		"craft_time": 8.0, "realm_required": 2, "tier": 2,
		"desc": "火灵之力精华",
	},
	"water_essence": {
		"name": "水灵精", "category": "material", "station": "spirit_furnace",
		"materials": {"spirit_stone": 3, "copper_ingot": 2, "herb_spirit": 2},
		"result": "water_essence", "result_count": 1,
		"craft_time": 8.0, "realm_required": 2, "tier": 2,
		"desc": "水灵之力精华",
	},
	"earth_essence": {
		"name": "土灵精", "category": "material", "station": "spirit_furnace",
		"materials": {"spirit_stone": 3, "iron_ingot": 2, "dirt": 4},
		"result": "earth_essence", "result_count": 1,
		"craft_time": 8.0, "realm_required": 2, "tier": 2,
		"desc": "土灵之力精华",
	},
	
	# ==========================================================
	# 🆕 Tier 3 金丹 · 玉灵装备/饰品
	# ==========================================================
	"jade_pickaxe": {
		"name": "玉灵镐", "category": "tool", "station": "spirit_furnace",
		"materials": {"spirit_jade": 3, "spirit_iron": 3, "spirit_wood": 2},
		"result": "jade_pickaxe", "result_count": 1,
		"craft_time": 18.0, "realm_required": 3, "tier": 3,
		"desc": "玉灵镐头，挖矿效率4倍",
	},
	"jade_axe": {
		"name": "玉灵斧", "category": "tool", "station": "spirit_furnace",
		"materials": {"spirit_jade": 3, "spirit_iron": 3, "spirit_wood": 3},
		"result": "jade_axe", "result_count": 1,
		"craft_time": 18.0, "realm_required": 3, "tier": 3,
		"desc": "玉灵斧刃，砍树效率4倍",
	},
	"jade_staff": {
		"name": "玉灵杖", "category": "weapon", "station": "spirit_furnace",
		"materials": {"spirit_jade": 6, "gold_ingot": 3, "spirit_stone": 5},
		"result": "jade_staff", "result_count": 1,
		"craft_time": 22.0, "realm_required": 3, "tier": 3,
		"desc": "玉灵法杖",
	},
	"jade_bow": {
		"name": "玉灵弓", "category": "weapon", "station": "spirit_furnace",
		"materials": {"spirit_jade": 5, "silk": 3, "spirit_iron": 3},
		"result": "jade_bow", "result_count": 1,
		"craft_time": 20.0, "realm_required": 3, "tier": 3,
		"desc": "玉灵弓",
	},
	"jade_dagger": {
		"name": "玉灵匕", "category": "weapon", "station": "spirit_furnace",
		"materials": {"spirit_jade": 4, "gold_ingot": 2},
		"result": "jade_dagger", "result_count": 1,
		"craft_time": 15.0, "realm_required": 3, "tier": 3,
		"desc": "玉灵匕首",
	},
	"jade_helmet": {
		"name": "玉灵冠", "category": "armor", "station": "spirit_furnace",
		"materials": {"spirit_jade": 4, "gold_ingot": 2, "spirit_stone": 3},
		"result": "jade_helmet", "result_count": 1,
		"craft_time": 18.0, "realm_required": 3, "tier": 3,
		"desc": "玉灵冠冕",
	},
	"jade_chestplate": {
		"name": "玉灵甲", "category": "armor", "station": "spirit_furnace",
		"materials": {"spirit_jade": 8, "gold_ingot": 4, "spirit_stone": 5},
		"result": "jade_chestplate", "result_count": 1,
		"craft_time": 25.0, "realm_required": 3, "tier": 3,
		"desc": "玉灵宝甲",
	},
	"jade_legs": {
		"name": "玉灵护膝", "category": "armor", "station": "spirit_furnace",
		"materials": {"spirit_jade": 4, "gold_ingot": 2, "silk": 2},
		"result": "jade_legs", "result_count": 1,
		"craft_time": 18.0, "realm_required": 3, "tier": 3,
		"desc": "玉灵护膝",
	},
	"jade_boots": {
		"name": "玉灵靴", "category": "armor", "station": "spirit_furnace",
		"materials": {"spirit_jade": 3, "gold_ingot": 2, "leather": 2},
		"result": "jade_boots", "result_count": 1,
		"craft_time": 15.0, "realm_required": 3, "tier": 3,
		"desc": "玉灵靴",
	},
	"jade_ring": {
		"name": "玉灵戒", "category": "accessory", "station": "spirit_furnace",
		"materials": {"spirit_jade": 2, "gold_ingot": 2, "spirit_stone": 3},
		"result": "jade_ring", "result_count": 1,
		"craft_time": 15.0, "realm_required": 3, "tier": 3,
		"desc": "玉灵戒指",
	},
	"jade_amulet": {
		"name": "玉灵坠", "category": "accessory", "station": "spirit_furnace",
		"materials": {"spirit_jade": 3, "gold_ingot": 2, "silk": 2},
		"result": "jade_amulet", "result_count": 1,
		"craft_time": 18.0, "realm_required": 3, "tier": 3,
		"desc": "玉灵吊坠",
	},
	"jade_bracelet": {
		"name": "玉灵镯", "category": "accessory", "station": "spirit_furnace",
		"materials": {"spirit_jade": 2, "gold_ingot": 3},
		"result": "jade_bracelet", "result_count": 1,
		"craft_time": 15.0, "realm_required": 3, "tier": 3,
		"desc": "玉灵手镯",
	},
	
	# ==========================================================
	# 🆕 Tier 4 元婴 · 玉晶武器/防具/饰品
	# ==========================================================
	"crystal_sword": {
		"name": "玉晶剑", "category": "weapon", "station": "spirit_furnace",
		"materials": {"spirit_crystal": 8, "spirit_jade": 5, "gold_ingot": 3},
		"result": "crystal_sword", "result_count": 1,
		"craft_time": 35.0, "realm_required": 4, "tier": 4,
		"desc": "玉晶神剑",
	},
	"crystal_staff": {
		"name": "玉晶杖", "category": "weapon", "station": "spirit_furnace",
		"materials": {"spirit_crystal": 8, "spirit_jade": 5, "spirit_stone": 10},
		"result": "crystal_staff", "result_count": 1,
		"craft_time": 35.0, "realm_required": 4, "tier": 4,
		"desc": "玉晶法杖",
	},
	"crystal_helmet": {
		"name": "玉晶冠", "category": "armor", "station": "spirit_furnace",
		"materials": {"spirit_crystal": 5, "spirit_jade": 3, "gold_ingot": 2},
		"result": "crystal_helmet", "result_count": 1,
		"craft_time": 25.0, "realm_required": 4, "tier": 4,
		"desc": "玉晶冠冕",
	},
	"crystal_chestplate": {
		"name": "玉晶甲", "category": "armor", "station": "spirit_furnace",
		"materials": {"spirit_crystal": 10, "spirit_jade": 5, "gold_ingot": 4, "spirit_stone": 8},
		"result": "crystal_chestplate", "result_count": 1,
		"craft_time": 40.0, "realm_required": 4, "tier": 4,
		"desc": "玉晶宝甲",
	},
	"crystal_legs": {
		"name": "玉晶护膝", "category": "armor", "station": "spirit_furnace",
		"materials": {"spirit_crystal": 5, "spirit_jade": 3, "silk": 3},
		"result": "crystal_legs", "result_count": 1,
		"craft_time": 25.0, "realm_required": 4, "tier": 4,
		"desc": "玉晶护膝",
	},
	"crystal_boots": {
		"name": "玉晶靴", "category": "armor", "station": "spirit_furnace",
		"materials": {"spirit_crystal": 4, "spirit_jade": 2, "leather": 2},
		"result": "crystal_boots", "result_count": 1,
		"craft_time": 20.0, "realm_required": 4, "tier": 4,
		"desc": "玉晶靴",
	},
	"crystal_ring": {
		"name": "玉晶戒", "category": "accessory", "station": "spirit_furnace",
		"materials": {"spirit_crystal": 3, "spirit_jade": 3, "gold_ingot": 2},
		"result": "crystal_ring", "result_count": 1,
		"craft_time": 25.0, "realm_required": 4, "tier": 4,
		"desc": "玉晶戒指",
	},
	"crystal_amulet": {
		"name": "玉晶坠", "category": "accessory", "station": "spirit_furnace",
		"materials": {"spirit_crystal": 4, "spirit_jade": 3, "silk": 3},
		"result": "crystal_amulet", "result_count": 1,
		"craft_time": 28.0, "realm_required": 4, "tier": 4,
		"desc": "玉晶吊坠",
	},
	
	# ==========================================================
	# 🆕 Tier 6 化神 · 后天灵宝/星辰套
	# ==========================================================
	"artifact_staff": {
		"name": "后天灵宝·混元", "category": "weapon", "station": "spirit_furnace",
		"materials": {"celestial_iron": 8, "phoenix_feather": 3, "spirit_crystal": 10},
		"result": "artifact_staff", "result_count": 1,
		"craft_time": 150.0, "realm_required": 6, "tier": 6,
		"desc": "后天灵宝法杖",
	},
	"artifact_bow": {
		"name": "后天灵宝·落日", "category": "weapon", "station": "spirit_furnace",
		"materials": {"celestial_iron": 8, "dragon_scale": 3, "silk": 5},
		"result": "artifact_bow", "result_count": 1,
		"craft_time": 140.0, "realm_required": 6, "tier": 6,
		"desc": "落日神弓",
	},
	"celestial_helmet": {
		"name": "星辰冠", "category": "armor", "station": "spirit_furnace",
		"materials": {"celestial_iron": 6, "celestial_stone": 4, "spirit_crystal": 5},
		"result": "celestial_helmet", "result_count": 1,
		"craft_time": 80.0, "realm_required": 6, "tier": 6,
		"desc": "星辰冠冕",
	},
	"celestial_chestplate": {
		"name": "星辰甲", "category": "armor", "station": "spirit_furnace",
		"materials": {"celestial_iron": 10, "celestial_stone": 6, "dragon_scale": 3, "spirit_crystal": 8},
		"result": "celestial_chestplate", "result_count": 1,
		"craft_time": 120.0, "realm_required": 6, "tier": 6,
		"desc": "星辰战甲",
	},
	"celestial_legs": {
		"name": "星辰护膝", "category": "armor", "station": "spirit_furnace",
		"materials": {"celestial_iron": 5, "celestial_stone": 3, "silk": 5},
		"result": "celestial_legs", "result_count": 1,
		"craft_time": 70.0, "realm_required": 6, "tier": 6,
		"desc": "星辰护膝",
	},
	"celestial_boots": {
		"name": "星辰靴", "category": "armor", "station": "spirit_furnace",
		"materials": {"celestial_iron": 4, "celestial_stone": 2, "leather": 3},
		"result": "celestial_boots", "result_count": 1,
		"craft_time": 60.0, "realm_required": 6, "tier": 6,
		"desc": "星辰靴",
	},
	"celestial_ring": {
		"name": "星辰戒", "category": "accessory", "station": "spirit_furnace",
		"materials": {"celestial_iron": 4, "celestial_stone": 3, "gold_ingot": 5},
		"result": "celestial_ring", "result_count": 1,
		"craft_time": 80.0, "realm_required": 6, "tier": 6,
		"desc": "星辰戒指",
	},
}

# ==================== 工具方法 ====================

## 获取所有配方
static func get_all_recipes() -> Dictionary:
	return RECIPES

## 按境界获取可用的配方
static func get_recipes_for_realm(realm: int) -> Dictionary:
	var result: Dictionary = {}
	for id in RECIPES.keys():
		if RECIPES[id].realm_required <= realm:
			result[id] = RECIPES[id]
	return result

## 按类别获取配方
static func get_recipes_by_category(category: String, realm: int = 999) -> Dictionary:
	var result: Dictionary = {}
	for id in RECIPES.keys():
		var r = RECIPES[id]
		if r.category == category and r.realm_required <= realm:
			result[id] = r
	return result

## 获取某个配方的完整数据
static func get_recipe(recipe_id: String) -> Dictionary:
	return RECIPES.get(recipe_id, {})

## 按合成台筛选
static func get_recipes_for_station(station: String, realm: int = 999) -> Dictionary:
	var result: Dictionary = {}
	for id in RECIPES.keys():
		var r = RECIPES[id]
		if r.station == station and r.realm_required <= realm:
			result[id] = r
	return result

## 获取所有合成台类型
static func get_all_stations() -> Array[String]:
	var stations: Array[String] = []
	for id in RECIPES.keys():
		var s = RECIPES[id].station
		if not s.is_empty() and not s in stations:
			stations.append(s)
	return stations

## 搜索配方
static func search_recipes(query: String, realm: int = 999) -> Dictionary:
	var result: Dictionary = {}
	var q = query.to_lower()
	for id in RECIPES.keys():
		var r = RECIPES[id]
		if r.realm_required <= realm:
			if q in id.to_lower() or q in r.name.to_lower() or q in r.desc.to_lower():
				result[id] = r
	return result
