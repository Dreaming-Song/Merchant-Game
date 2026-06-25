extends Node
## 技能管理器 — 丰富版技能数据库（剑技 + 法术各14+）
##
## 技能解锁由 CultivationSystem 控制，SkillManager 负责：
## - 技能释放/冷却/法力消耗/连击联动
## - 查找技能数据
## - 流派独特机制

class_name SkillManager

# ==================== 外部依赖 ====================
const CultivationSystem = preload("res://scripts/combat/cultivation_system.gd")
const GongfaSystem = preload("res://scripts/combat/gongfa_system.gd")
const DamageCalculator = preload("res://scripts/combat/damage_calculator.gd")

# ==================== 🗡️ 剑道独有机制 ====================
## 剑意层数：连击/技能命中叠加，满层消耗触发额外效果
const SWORD_INTENT_MAX: int = 5
const SWORD_INTENT_DURATION: float = 4.0  # 层数持续时间

# ==================== ✨ 法术独有机制 ====================
## 元素共鸣：连续使用同系法术触发额外加成
const ELEMENT_CHAIN_WINDOW: float = 3.0  # 同系连击窗口
const ELEMENT_CHAIN_BONUS: float = 0.3   # 每层同系加成

# ==================== 技能数据库 ====================
const SKILL_DB: Dictionary = {
	# ============================================================
	# 🗡️ 剑道 — 14个技能
	# ============================================================
	"sword_slash": {
		"name": "剑气斩", "school": "剑道", "level": 1,
		"cooldown": 1.5, "mp_cost": 8,
		"damage_mult": 1.2, "range": 3.5, "element": "金",
		"effects": {"bleed_prob": 0.3, "bleed_damage": 5, "sword_intent": 1},
		"vfx": "sword_slash",
		"desc": "凝聚剑气向前斩击，120%伤害，30%概率流血 +1剑意",
		"tips": "基础起手技，攒剑意首选",
	},
	"sword_flurry": {
		"name": "剑影连击", "school": "剑道", "level": 3,
		"cooldown": 4.0, "mp_cost": 15,
		"damage_mult": 0.6, "range": 3.5, "element": "金",
		"effects": {"multi_hit": 3, "sword_intent": 2},
		"vfx": "sword_flurry",
		"desc": "快速连斩3次，每次60%伤害，+2剑意",
		"tips": "快速叠剑意神技",
	},
	"sword_rain": {
		"name": "万剑诀", "school": "剑道", "level": 6,
		"cooldown": 8.0, "mp_cost": 30,
		"damage_mult": 0.7, "range": 8.0, "element": "金",
		"effects": {"aoe": true, "count": 15, "sword_intent": 3},
		"vfx": "sword_rain",
		"desc": "召唤15把飞剑从天而降，每剑70%伤害，+3剑意",
		"tips": "清怪+攒剑意，大范围神器",
	},
	"sword_thunder": {
		"name": "天剑引雷", "school": "剑道", "level": 8,
		"cooldown": 12.0, "mp_cost": 45,
		"damage_mult": 3.5, "range": 4.5, "element": "金",
		"effects": {"crit_guarantee": true, "aoe": true, "sword_intent": 2},
		"vfx": "sword_thunder",
		"desc": "引天雷附于剑上劈落，350%范围伤害+必定暴击，+2剑意",
		"tips": "爆发技！配合强化100%暴击",
	},
	
	# 🆕 剑道新增技能
	"sword_draw": {
		"name": "拔刀斩·一闪", "school": "剑道", "level": 2,
		"cooldown": 3.0, "mp_cost": 10,
		"damage_mult": 2.0, "range": 4.0, "element": "金",
		"effects": {"instant": true, "sword_intent": 1},
		"vfx": "sword_draw",
		"desc": "居合拔刀术，200%伤害，无抬手动作",
		"tips": "收刀后瞬发，打对手措手不及",
	},
	"sword_moon": {
		"name": "月影斩", "school": "剑道", "level": 3,
		"cooldown": 5.0, "mp_cost": 15,
		"damage_mult": 1.3, "range": 3.0, "element": "水",
		"effects": {"aoe_360": true, "knockback": true, "sword_intent": 1},
		"vfx": "sword_moon",
		"desc": "回旋剑气360°斩击，130%伤害+击退，+1剑意",
		"tips": "被包围时解围神技",
	},
	"sword_armor_break": {
		"name": "破甲斩", "school": "剑道", "level": 4,
		"cooldown": 6.0, "mp_cost": 18,
		"damage_mult": 1.0, "range": 3.0, "element": "金",
		"effects": {"armor_reduce_pct": 0.3, "debuff_duration": 4.0, "sword_intent": 1},
		"vfx": "sword_armor_break",
		"desc": "破甲一击，100%伤害+目标防御-30%持续4秒，+1剑意",
		"tips": "打Boss起手技，全队受益",
	},
	"sword_dance": {
		"name": "剑舞·旋", "school": "剑道", "level": 5,
		"cooldown": 7.0, "mp_cost": 22,
		"damage_mult": 0.5, "range": 3.0, "element": "金",
		"effects": {"multi_hit": 5, "aoe_360": true, "sword_intent": 2},
		"vfx": "sword_dance",
		"desc": "持剑旋转5次，每次50%范围伤害，+2剑意",
		"tips": "持续旋转时带霸体，可边转边移动",
	},
	"sword_aura": {
		"name": "剑气护体", "school": "剑道", "level": 5,
		"cooldown": 10.0, "mp_cost": 20,
		"damage_mult": 0.3, "range": 2.5, "element": "金",
		"effects": {"aura": true, "duration": 6.0, "tick_interval": 0.5, "sword_intent": 0},
		"vfx": "sword_aura",
		"desc": "剑气环绕自身6秒，每0.5秒对周围30%伤害",
		"tips": "持续伤+防近身，贴身缠斗神技",
	},
	"sword_dash": {
		"name": "人剑合一", "school": "剑道", "level": 7,
		"cooldown": 8.0, "mp_cost": 25,
		"damage_mult": 2.5, "range": 8.0, "element": "金",
		"effects": {"dash": true, "pierce": true, "sword_intent": 1},
		"vfx": "sword_dash",
		"desc": "化身剑光直线突进8米，穿透路径所有敌人造成250%伤害，+1剑意",
		"tips": "追击+穿人，可穿墙（看地图设计）",
	},
	"sword_field": {
		"name": "剑域·斩", "school": "剑道", "level": 9,
		"cooldown": 18.0, "mp_cost": 50,
		"damage_mult": 0.0, "range": 8.0, "element": "金",
		"effects": {"field": true, "duration": 8.0, "field_buff": "sword_intent_double", "sword_intent": 0},
		"vfx": "sword_field",
		"desc": "展开半径8米剑域8秒，域内剑意获取翻倍，敌人减速40%",
		"tips": "剑道核心理想乡，领域内输出翻倍",
	},
	"sword_execute": {
		"name": "居合·心斩", "school": "剑道", "level": 10,
		"cooldown": 6.0, "mp_cost": 30,
		"damage_mult": 1.5, "range": 4.0, "element": "金",
		"effects": {"consume_intent": true, "per_intent_damage": 0.5, "sword_intent": 0},
		"vfx": "sword_execute",
		"desc": "消耗所有剑意层数，每层+50%伤害（基础150%，5层=400%）",
		"tips": "剑道终结技！攒满5层爆发毁天灭地",
	},
	"sword_counter": {
		"name": "剑闪·破", "school": "剑道", "level": 6,
		"cooldown": 4.0, "mp_cost": 15,
		"damage_mult": 1.8, "range": 3.5, "element": "金",
		"effects": {"counter": true, "counter_mult": 3.0, "sword_intent": 1},
		"vfx": "sword_counter",
		"desc": "看破反击技，受到攻击瞬间释放→3倍伤害反击（类似见切）",
		"tips": "高风险高回报，完美时机=瞬间爆炸",
	},
	"sword_spirit": {
		"name": "剑意通明", "school": "剑道", "level": 1,
		"cooldown": 0, "mp_cost": 0,
		"damage_mult": 0, "range": 0, "element": "",
		"type": "passive",
		"effects": {"crit_rate_bonus": 0.08},
		"desc": "被动·暴击率+8%",
	},
	"sword_intent": {
		"name": "剑心通神", "school": "剑道", "level": 4,
		"cooldown": 0, "mp_cost": 0,
		"damage_mult": 0, "range": 0, "element": "",
		"type": "passive",
		"effects": {"max_sword_intent": 7, "crit_damage_bonus": 0.3},
		"desc": "被动·剑意上限提升至7层+暴击伤害+30%",
	},
	
	# ============================================================
	# ✨ 法术 — 14个技能
	# ============================================================
	"fire_ball": {
		"name": "火球术", "school": "法术", "level": 1,
		"cooldown": 1.0, "mp_cost": 10,
		"damage_mult": 1.1, "range": 7.0, "element": "火",
		"effects": {"burn_prob": 0.4, "burn_damage": 6, "element_chain": "fire"},
		"vfx": "fire_ball",
		"desc": "凝聚火球攻击，110%伤害，40%概率灼烧+6/秒",
		"tips": "法术系最速冷却，火系连携起手",
	},
	"frost_array": {
		"name": "冰霜阵", "school": "法术", "level": 3,
		"cooldown": 4.0, "mp_cost": 18,
		"damage_mult": 0.8, "range": 6.0, "element": "水",
		"effects": {"slow_pct": 0.6, "slow_duration": 3.0, "aoe": true, "element_chain": "ice"},
		"vfx": "frost_array",
		"desc": "地面冰霜法阵，80%范围伤害+60%减速3秒",
		"tips": "控场起手，减速后接其他法术",
	},
	"thunder_bolt": {
		"name": "雷法·天罚", "school": "法术", "level": 5,
		"cooldown": 6.0, "mp_cost": 28,
		"damage_mult": 2.2, "range": 9.0, "element": "火",
		"effects": {"stun_prob": 0.3, "stun_duration": 1.5, "aoe": true, "element_chain": "thunder"},
		"vfx": "thunder_bolt",
		"desc": "引天雷劈落，220%范围伤害，30%眩晕1.5秒",
		"tips": "法术系爆发技，AOE+控制一体",
	},
	"elemental_storm": {
		"name": "五行崩裂", "school": "法术", "level": 8,
		"cooldown": 14.0, "mp_cost": 50,
		"damage_mult": 1.8, "range": 10.0, "element": "火",
		"effects": {"aoe": true, "element_chaos": true, "element_chain": "chaos"},
		"vfx": "elemental_storm",
		"desc": "引动五行之力大爆炸，180%范围伤害+随机元素异常",
		"tips": "终极AOE，核弹级清场",
	},
	
	# 🆕 法术新增技能
	"fire_storm": {
		"name": "烈焰风暴", "school": "法术", "level": 4,
		"cooldown": 8.0, "mp_cost": 25,
		"damage_mult": 0.5, "range": 7.0, "element": "火",
		"effects": {"aoe": true, "duration": 4.0, "tick_interval": 0.5, "element_chain": "fire"},
		"vfx": "fire_storm",
		"desc": "召唤烈焰风暴持续4秒，每0.5秒50%范围伤害",
		"tips": "配合冰霜减速，敌人站火里被烤熟",
	},
	"ice_spike": {
		"name": "冰锥术", "school": "法术", "level": 2,
		"cooldown": 2.5, "mp_cost": 14,
		"damage_mult": 1.8, "range": 8.0, "element": "水",
		"effects": {"pierce": true, "slow_pct": 0.4, "slow_duration": 2.0, "element_chain": "ice"},
		"vfx": "ice_spike",
		"desc": "凝聚冰锥穿透射击，180%伤害+40%减速2秒",
		"tips": "高倍率单体，可穿透多个敌人",
	},
	"lightning_flash": {
		"name": "雷闪", "school": "法术", "level": 5,
		"cooldown": 5.0, "mp_cost": 20,
		"damage_mult": 0.5, "range": 6.0, "element": "火",
		"effects": {"teleport": true, "aoe": true, "element_chain": "thunder"},
		"vfx": "lightning_flash",
		"desc": "化作雷电瞬移至目标位置，落地点50%范围伤害",
		"tips": "法师位移技！可穿墙可逃跑可追击",
	},
	"earth_wall": {
		"name": "土墙术", "school": "法术", "level": 4,
		"cooldown": 8.0, "mp_cost": 18,
		"damage_mult": 0.0, "range": 5.0, "element": "土",
		"effects": {"wall": true, "wall_hp": 300, "wall_duration": 6.0, "element_chain": "earth"},
		"vfx": "earth_wall",
		"desc": "升起土墙阻挡敌人，300HP持续6秒",
		"tips": "挡弹道/分割战场/卡位逃命",
	},
	"wind_blade": {
		"name": "风刃乱舞", "school": "法术", "level": 3,
		"cooldown": 3.0, "mp_cost": 15,
		"damage_mult": 0.7, "range": 8.0, "element": "木",
		"effects": {"multi_hit": 5, "element_chain": "wind"},
		"vfx": "wind_blade",
		"desc": "释放5道风刃扇形散射，每道70%伤害",
		"tips": "散射弹幕，打多个方向或贴脸全吃",
	},
	"shadow_step": {
		"name": "暗影步", "school": "法术", "level": 7,
		"cooldown": 6.0, "mp_cost": 20,
		"damage_mult": 2.0, "range": 5.0, "element": "水",
		"effects": {"teleport_back": true, "silence": true, "silence_duration": 2.0, "element_chain": "dark"},
		"vfx": "shadow_step",
		"desc": "遁入暗影出现在目标身后，200%伤害+沉默2秒",
		"tips": "绕背技，打脆皮法系专精",
	},
	"element_burst": {
		"name": "元素爆发", "school": "法术", "level": 10,
		"cooldown": 20.0, "mp_cost": 0,
		"damage_mult": 0.5, "range": 8.0, "element": "火",
		"effects": {"consume_all_mp": true, "damage_per_mp": 0.5, "aoe": true, "element_chain": "chaos"},
		"vfx": "element_burst",
		"desc": "消耗全部法力造成AOE，每点法力造成0.5倍伤害",
		"tips": "100法力=500%伤害！空蓝核弹",
	},
	"arcane_freeze": {
		"name": "绝对零度", "school": "法术", "level": 9,
		"cooldown": 16.0, "mp_cost": 40,
		"damage_mult": 1.2, "range": 6.0, "element": "水",
		"effects": {"freeze_prob": 0.8, "freeze_duration": 2.5, "aoe": true, "element_chain": "ice"},
		"vfx": "arcane_freeze",
		"desc": "极寒冰爆，120%范围伤害+80%冰冻2.5秒",
		"tips": "控场天花板，冻住后接火系双倍伤害",
	},
	"life_tap": {
		"name": "生命转化", "school": "法术", "level": 6,
		"cooldown": 10.0, "mp_cost": 0,
		"damage_mult": 0.0, "range": 0, "element": "木",
		"effects": {"hp_to_mp_pct": 0.3, "cd_reset": true, "element_chain": "life"},
		"vfx": "life_tap",
		"desc": "消耗30%当前生命值，转化为等量法力+刷新所有冷却2秒",
		"tips": "绝境反杀，残血换蓝再打一套",
	},
	"mana_resonance": {
		"name": "法力共鸣", "school": "法术", "level": 2,
		"cooldown": 0, "mp_cost": 0,
		"damage_mult": 0, "range": 0, "element": "",
		"type": "passive",
		"effects": {"mp_regen_bonus": 4.0},
		"desc": "被动·每秒额外回复4点法力",
	},
	"elemental_affinity": {
		"name": "元素亲和", "school": "法术", "level": 5,
		"cooldown": 0, "mp_cost": 0,
		"damage_mult": 0, "range": 0, "element": "",
		"type": "passive",
		"effects": {"element_damage_bonus": 0.25, "element_chain_bonus": 0.15},
		"desc": "被动·元素伤害+25%，元素连携加成额外+15%",
	},
	
	# ============================================================
	# 👊 体术 — 8个技能（保持精简）
	# ============================================================
	"iron_body": {
		"name": "金刚体", "school": "体术", "level": 2,
		"cooldown": 6.0, "mp_cost": 15,
		"damage_mult": 0.5, "range": 2.5, "element": "土",
		"effects": {"defense_buff_pct": 0.5, "buff_duration": 4.0},
		"vfx": "iron_body",
		"desc": "金刚护体，防御+50%持续4秒",
	},
	"quake_stomp": {
		"name": "震地击", "school": "体术", "level": 3,
		"cooldown": 4.0, "mp_cost": 12,
		"damage_mult": 0.8, "range": 4.0, "element": "土",
		"effects": {"stun_prob": 0.5, "stun_duration": 1.0, "aoe": true},
		"vfx": "quake_stomp",
		"desc": "猛踏地面，80%范围伤害+50%眩晕1秒",
	},
	"dragon_grab": {
		"name": "擒龙手", "school": "体术", "level": 5,
		"cooldown": 8.0, "mp_cost": 20,
		"damage_mult": 1.2, "range": 5.0, "element": "土",
		"effects": {"pull": true, "stun_duration": 1.0},
		"vfx": "dragon_grab",
		"desc": "隔空擒拿，拉至身前眩晕1秒，120%伤害",
	},
	"golden_body": {
		"name": "不灭金身", "school": "体术", "level": 8,
		"cooldown": 30.0, "mp_cost": 60,
		"damage_mult": 0, "range": 0, "element": "土",
		"effects": {"invincible": true, "duration": 3.0, "heal_pct": 0.20},
		"vfx": "golden_body",
		"desc": "3秒无敌+恢复20%生命值",
	},
	
	# ============================================================
	# 📜 符道 — 8个技能（保持精简）
	# ============================================================
	"soul_seal": {
		"name": "镇魂符", "school": "符道", "level": 2,
		"cooldown": 2.0, "mp_cost": 12,
		"damage_mult": 0.8, "range": 6.0, "element": "金",
		"effects": {"silence_prob": 0.4, "silence_duration": 2.0},
		"vfx": "soul_seal",
		"desc": "打出镇魂符咒，80%伤害+40%沉默2秒",
	},
	"thunder_seal": {
		"name": "天雷符", "school": "符道", "level": 5,
		"cooldown": 7.0, "mp_cost": 28,
		"damage_mult": 1.8, "range": 7.0, "element": "金",
		"effects": {"paralyze_prob": 0.5, "paralyze_duration": 1.5},
		"vfx": "thunder_seal",
		"desc": "天雷符箓降下雷击，180%伤害+50%麻痹1.5秒",
	},
	"eight_trigrams": {
		"name": "八卦阵", "school": "符道", "level": 7,
		"cooldown": 12.0, "mp_cost": 40,
		"damage_mult": 0.5, "range": 8.0, "element": "金",
		"effects": {"aoe": true, "debuff_all_pct": 0.3, "field_duration": 6.0},
		"vfx": "eight_trigrams",
		"desc": "八卦大阵，范围内敌人全属性-30%持续6秒",
	},
}

# ==================== 运行时状态 ====================
var _cooldowns: Dictionary = {}
var _cultivation: CultivationSystem = null
var _current_mp: float = 50.0
var _max_mp: float = 50.0

# 🗡️ 剑意状态
var _sword_intent: int = 0
var _sword_intent_timer: float = 0.0

# ✨ 元素共鸣状态
var _element_chain: Dictionary = {}   # element → last_use_time
var _element_chain_count: int = 0     # 当前连携层数
var _element_chain_element: String = ""

# 信号
signal skill_used(skill_id: String, skill_name: String, target: Node)
signal skill_on_cooldown(skill_id: String, remaining: float)
signal mp_changed(current: float, max: float)
signal skill_not_learned(skill_id: String, skill_name: String)
signal sword_intent_changed(current: int, max_intent: int)
signal element_chain_changed(element: String, count: int)

func _ready() -> void:
	var gm = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	if gm and gm.cultivation:
		_cultivation = gm.cultivation
	else:
		_cultivation = get_node("/root/GameManager/CultivationSystem") if has_node("/root/GameManager/CultivationSystem") else CultivationSystem.new()
	
	set_mp(50.0, 50.0)

func _process(delta: float) -> void:
	# 冷却递减
	for skill_id in _cooldowns.keys():
		_cooldowns[skill_id] -= delta
		if _cooldowns[skill_id] <= 0:
			_cooldowns.erase(skill_id)
	
	# 法力恢复
	if _cultivation:
		var stats = _cultivation.calculate_total_stats()
		var mp_regen_val = stats.get("mp_regen")
		var regen = (mp_regen_val if typeof(mp_regen_val) == TYPE_FLOAT or typeof(mp_regen_val) == TYPE_INT else 2.0) + get_passive_effect("mp_regen_bonus", 0.0)
		_current_mp = min(_current_mp + regen * delta, _max_mp)
	
	# 🗡️ 剑意衰减
	if _sword_intent > 0:
		_sword_intent_timer -= delta
		if _sword_intent_timer <= 0:
			_sword_intent = max(0, _sword_intent - 1)
			_sword_intent_timer = SWORD_INTENT_DURATION
			sword_intent_changed.emit(_sword_intent, get_max_intent())

# ==================== 🗡️ 剑意系统 ====================

func add_sword_intent(amount: int) -> void:
	"""叠加剑意层数"""
	var max_intent = get_max_intent()
	_sword_intent = min(_sword_intent + amount, max_intent)
	_sword_intent_timer = SWORD_INTENT_DURATION
	sword_intent_changed.emit(_sword_intent, max_intent)
	print("🗡️ 剑意 +%d（当前 %d/%d）" % [amount, _sword_intent, max_intent])

func get_max_intent() -> int:
	"""获取最大剑意上限（含被动加成）"""
	var base = SWORD_INTENT_MAX
	var bonus = int(get_passive_effect("max_sword_intent", 0))
	return base + bonus

func consume_sword_intent(amount: int = -1) -> int:
	"""消耗剑意，返回实际消耗层数（-1=全部）"""
	if amount < 0:
		amount = _sword_intent
	var consumed = min(amount, _sword_intent)
	_sword_intent -= consumed
	sword_intent_changed.emit(_sword_intent, get_max_intent())
	return consumed

func get_sword_intent() -> int:
	return _sword_intent

# ==================== ✨ 元素共鸣系统 ====================

func update_element_chain(element: String) -> void:
	"""更新元素连携"""
	var now = Time.get_ticks_msec() / 1000.0
	
	if _element_chain_element == element and now - _element_chain.get(element, 0.0) < ELEMENT_CHAIN_WINDOW:
		_element_chain_count = min(_element_chain_count + 1, 5)
	else:
		_element_chain_count = 1
		_element_chain_element = element
	
	_element_chain[element] = now
	element_chain_changed.emit(element, _element_chain_count)
	
	if _element_chain_count >= 3:
		print("✨ 元素共鸣 ×%d！%s系伤害 +%.0f%%" % [
			_element_chain_count, element,
			_element_chain_count * ELEMENT_CHAIN_BONUS * 100
		])

func get_element_chain_bonus() -> float:
	"""获取元素连携伤害加成"""
	var bonus = get_passive_effect("element_chain_bonus", 0.0)
	return _element_chain_count * (ELEMENT_CHAIN_BONUS + bonus)

# ==================== 核心接口 ====================

## 尝试释放技能
func use_skill(skill_id: String, caster: Node, target: Node = null) -> Dictionary:
	if not _cultivation:
		return {"success": false, "reason": "修行系统未加载"}
	
	if not _cultivation.has_skill(skill_id):
		skill_not_learned.emit(skill_id, get_skill_data(skill_id).get("name") or skill_id)
		return {"success": false, "reason": "未学习该技能"}
	
	var data = SKILL_DB.get(skill_id)
	if not data:
		return {"success": false, "reason": "技能不存在"}
	
	if _cooldowns.has(skill_id):
		skill_on_cooldown.emit(skill_id, _cooldowns[skill_id])
		return {"success": false, "reason": "冷却中"}
	
	# ============ 📜 功法联动：应用功法加成 ============
	var _gongfa = _get_gongfa_system()
	if _gongfa:
		# 应用功法对技能的联动加成
		data = _gongfa.apply_synergy_to_skill(skill_id, data)
		# 应用功法属性加成到后续伤害计算
		var gongfa_stats = _gongfa.get_combat_stat_bonuses()
		# 功法加成会在 _calculate_effective_attack 中处理
	
	# 特殊法力消耗处理
	var cost = data.get("mp_cost", 0)
	if data.get("effects", {}).get("consume_all_mp") or false:
		cost = _current_mp
	
	if _current_mp < cost:
		return {"success": false, "reason": "法力不足"}
	
	_current_mp -= cost
	mp_changed.emit(_current_mp, _max_mp)
	
	if data.get("cooldown", 0) > 0:
		_cooldowns[skill_id] = data.get("cooldown", 0)
	
	# 🗡️ 剑意叠加
	var intent_gain = data.get("effects", {}).get("sword_intent") or 0
	if intent_gain > 0:
		add_sword_intent(intent_gain)
	
	# ✨ 元素连携
	var chain_elem = data.get("effects", {}).get("element_chain") or ""
	if not chain_elem.is_empty():
		update_element_chain(chain_elem)
	
	# 📜 功法触发：技能释放事件
	if _gongfa:
		_gongfa.try_trigger("on_skill_cast", {"skill_id": skill_id})
	
	# 计算伤害
	var result = {"success": true, "skill_id": skill_id, "skill_name": data.get("name", "未知"), "data": data}
	
	if data.get("damage_mult", 1.0) > 0:
		var stats = _cultivation.calculate_total_stats()
		stats["attack"] = _calculate_effective_attack(stats, data)
		
		# 📜 功法属性加成应用
		if _gongfa:
			var gb = _gongfa.get_combat_stat_bonuses()
			stats["attack"] *= (1.0 + gb.get("all_damage_bonus_pct") or 0.0 + gb.get("sword_damage_bonus_pct") or 0.0 + gb.get("fire_damage_bonus_pct") or 0.0 + gb.get("ice_damage_bonus_pct") or 0.0 + gb.get("thunder_damage_bonus_pct") or 0.0 + gb.get("talisman_damage_bonus_pct") or 0.0 + gb.get("all_element_damage_pct") or 0.0)
			stats["crit_rate"] += gb.get("crit_rate_bonus") or 0.0 + gb.get("fire_crit_rate_bonus") or 0.0 + gb.get("talisman_crit_rate_bonus") or 0.0
			stats["crit_damage"] += gb.get("crit_damage_bonus") or 0.0
		
		var dmg_result = DamageCalculator.calculate_damage(stats, {}, data)
		result["damage"] = dmg_result.damage
		result["is_crit"] = dmg_result.is_crit
		result["element"] = dmg_result.element
	
	skill_used.emit(skill_id, data.get("name", "未知"), target)
	return result

# ==================== 📜 功法引用 ====================

var _gongfa_system: GongfaSystem = null

func _get_gongfa_system() -> GongfaSystem:
	if not _gongfa_system:
		_gongfa_system = get_node("/root/GameManager/GongfaSystem") if has_node("/root/GameManager/GongfaSystem") else null
	return _gongfa_system

func _calculate_effective_attack(stats: Dictionary, data: Dictionary) -> float:
	"""计算技能实际攻击力（含被动加成）"""
	var base = stats.get("attack") or 10.0
	
	# 元素伤害加成
	var elem_bonus = get_passive_effect("element_damage_bonus", 0.0)
	base *= (1.0 + elem_bonus)
	
	# 元素连携加成
	base *= (1.0 + get_element_chain_bonus())
	
	return base

func get_passive_effect(effect_key: String, default = 0):
	"""获取所有被动技能的总加成值"""
	var total = default
	for skill_id in SKILL_DB.keys():
		var data = SKILL_DB[skill_id]
		if data.get("type") != "passive":
			continue
		if not _cultivation or not _cultivation.has_skill(skill_id):
			continue
		var effects = data.get("effects", {})
		if effects.has(effect_key):
			total += effects[effect_key]
	return total

# ==================== 法力管理 ====================

func set_mp(mp: float, max_mp: float) -> void:
	_current_mp = mp
	_max_mp = max_mp
	mp_changed.emit(_current_mp, _max_mp)

func restore_mp(amount: float) -> void:
	_current_mp = min(_current_mp + amount, _max_mp)
	mp_changed.emit(_current_mp, _max_mp)

# ==================== 查询接口 ====================

static func get_skill_data(skill_id: String) -> Dictionary:
	return SKILL_DB.get(skill_id, {})

static func get_skills_by_school() -> Dictionary:
	var result: Dictionary = {}
	for skill_id in SKILL_DB.keys():
		var data = SKILL_DB[skill_id]
		var school = data.get("school") or "其他"
		if not result.has(school):
			result[school] = []
		result[school].append({"id": skill_id, "data": data})
	return result

static func get_school_skill_ids(school_name: String) -> Array[String]:
	var ids: Array[String] = []
	for skill_id in SKILL_DB.keys():
		if SKILL_DB[skill_id].get("school") == school_name:
			ids.append(skill_id)
	return ids

func get_cooldown(skill_id: String) -> float:
	return _cooldowns.get(skill_id, 0.0)

func get_current_mp() -> float:
	return _current_mp

func get_max_mp() -> float:
	return _max_mp
