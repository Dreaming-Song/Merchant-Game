extends Node
## 📜 功法系统 V2 — 探索效果 + 技能联动 + 突破进化
##
## 功法 = 可装备的被动能力，分为三大维度：
##   1. combat_stats: 战斗属性加成
##   2. exploration:  探索/生活功效（战斗外）
##   3. synergies:    技能联动强化
##   4. triggers:     触发型效果
##
## 每人最多装备 3 个功法。
## 功法可突破（小成→大成→圆满），每次突破解锁更强效果。
##
## 突破条件：
##   小成(Lv4):  流派等级≥10
##   大成(Lv7):  流派等级≥20 + 击杀数≥50
##   圆满(Lv10): 流派等级≥30 + 击杀数≥200 + 材料

class_name GongfaSystem

# ============================
# ⭐ 功法境界（突破阶段）
# ============================
enum GongfaStage {
	INITIAL = 0,   # 初悟 — 基础效果
	MINOR = 1,     # 小成 — 效果×1.5 + 探索效果解锁
	MAJOR = 2,     # 大成 — 效果×2.0 + 触发效果解锁
	PERFECT = 3,   # 圆满 — 效果×3.0 + 终极效果
}

const STAGE_NAMES: Dictionary = {
	GongfaStage.INITIAL: "初悟",
	GongfaStage.MINOR: "小成",
	GongfaStage.MAJOR: "大成",
	GongfaStage.PERFECT: "圆满",
}

const STAGE_MULTS: Dictionary = {
	GongfaStage.INITIAL: 1.0,
	GongfaStage.MINOR: 1.5,
	GongfaStage.MAJOR: 2.0,
	GongfaStage.PERFECT: 3.0,
}

# ============================
# 📜 功法数据库（30个）
# ============================
const GONGFA_DB: Dictionary = {
	# ============================================================
	# 🏔️ 通用功法（8个）
	# ============================================================
	"basic_breath": {
		"name": "养气诀", "school": "通用", "tier": 1,
		"combat_stats": {"mp_regen_bonus": 3.0, "max_mp_bonus_pct": 0.10},
		"exploration": {"combat_mp_regen_out": 5.0},
		"synergies": {}, "triggers": {},
		"flavor": "吐纳天地灵气，气脉悠长",
		"desc": "法力恢复+3/秒，最大法力+10%",
	},
	"body_tempering": {
		"name": "锻体术", "school": "通用", "tier": 1,
		"combat_stats": {"max_hp_bonus_pct": 0.15, "defense_bonus_pct": 0.10},
		"exploration": {"fall_damage_reduce_pct": 0.50, "swim_speed_bonus_pct": 0.30},
		"synergies": {}, "triggers": {},
		"flavor": "千锤百炼，筋骨如铁",
		"desc": "生命+15%，防御+10%，坠落伤害-50%，游泳速度+30%",
	},
	"heart_of_war": {
		"name": "战意心法", "school": "通用", "tier": 2,
		"combat_stats": {"attack_bonus_pct": 0.12, "crit_rate_bonus": 0.05},
		"exploration": {"enemy_aggro_range_bonus": 5.0},
		"synergies": {}, "triggers": {},
		"flavor": "战意如潮，一往无前",
		"desc": "攻击+12%，暴击+5%，敌人警戒范围+5米（更容易引怪）",
	},
	"spirit_gathering": {
		"name": "聚灵诀", "school": "通用", "tier": 2,
		"combat_stats": {"all_damage_bonus_pct": 0.08},
		"exploration": {"exp_bonus_pct": 0.20, "gongfa_exp_bonus_pct": 0.25, "loot_quality_bonus_pct": 0.10},
		"synergies": {}, "triggers": {},
		"flavor": "聚天地灵气，纳为己用",
		"desc": "全伤+8%，经验+20%，功法经验+25%，战利品品质+10%",
	},
	"windwalk": {
		"name": "踏风术", "school": "通用", "tier": 1,
		"combat_stats": {"dodge_cooldown_reduce_pct": 0.10},
		"exploration": {"move_speed_bonus_pct": 0.18, "jump_height_bonus_pct": 0.25, "stamina_regen_out_pct": 0.30},
		"synergies": {}, "triggers": {},
		"flavor": "身轻如燕，踏雪无痕",
		"desc": "移速+18%，跳跃+25%，闪避冷却-10%，脱战体力恢复+30%",
	},
	"spirit_eye": {
		"name": "灵瞳术", "school": "通用", "tier": 1,
		"combat_stats": {"crit_rate_bonus": 0.03},
		"exploration": {"reveal_hidden": true, "detect_range_bonus": 12.0, "herb_gather_mult": 2.0},
		"synergies": {}, "triggers": {},
		"flavor": "灵目如电，洞悉万物",
		"desc": "暴击+3%，发现隐藏物品(+12米感知)，采集草药双倍",
	},
	"breath_hide": {
		"name": "敛息诀", "school": "通用", "tier": 2,
		"combat_stats": {"crit_damage_bonus": 0.20},
		"exploration": {"stealth_out_of_combat": true, "stealth_speed_pct": 0.30, "enemy_detect_range_reduce_pct": 0.40},
		"synergies": {}, "triggers": {},
		"flavor": "敛息藏锋，暗影无形",
		"desc": "暴击伤害+20%，脱战3秒隐身，潜行速度+30%，怪物感知范围-40%",
	},
	"spring_heal": {
		"name": "春风化雨诀", "school": "通用", "tier": 2,
		"combat_stats": {"hp_regen": 3.0, "mp_regen_bonus": 2.0},
		"exploration": {"out_combat_hp_regen_pct": 0.03, "out_combat_mp_regen": 5.0},
		"synergies": {}, "triggers": {},
		"flavor": "春风化雨，润物无声",
		"desc": "战斗中回血+3/s 回蓝+2/s，脱战后每秒回血3%+回蓝5",
	},
	
	# ============================================================
	# 🗡️ 剑道功法（6个）
	# ============================================================
	"sword_saint": {
		"name": "太白剑经", "school": "剑道", "tier": 2,
		"combat_stats": {"sword_damage_bonus_pct": 0.15},
		"exploration": {},
		"synergies": {
			"sword_execute": {"consume_intent_damage_per_stack": 0.7},
			"sword_intent": {"max_sword_intent": 9},
		},
		"triggers": {"on_combo_finish": {"effect": "restore_mp", "value": 10}},
		"flavor": "剑道至圣，一剑破万法",
		"desc": "剑伤+15%，居合·心斩每层→70%，剑意上限+2，连击收尾回蓝10",
	},
	"ten_thousand_swords": {
		"name": "万剑归宗诀", "school": "剑道", "tier": 2,
		"combat_stats": {"aoe_damage_bonus_pct": 0.20},
		"exploration": {},
		"synergies": {
			"sword_rain": {"extra_swords": 8},
			"sword_slash": {"range_bonus": 2.0},
			"sword_dance": {"extra_hits": 3},
		},
		"triggers": {},
		"flavor": "万剑齐发，遮天蔽日",
		"desc": "AOE+20%，万剑诀+8剑，剑气斩+2米，剑舞+3次",
	},
	"heavenly_sword": {
		"name": "天剑诀", "school": "剑道", "tier": 3,
		"combat_stats": {"crit_damage_bonus": 0.60, "sword_damage_bonus_pct": 0.10},
		"exploration": {},
		"synergies": {
			"sword_thunder": {"cooldown_reduce_pct": 0.35, "extra_crit_damage": 0.80},
			"sword_dash": {"extra_damage_pct": 0.50},
		},
		"triggers": {"on_crit": {"effect": "aoe_explosion", "radius": 2.5, "damage_pct": 0.3}},
		"flavor": "天剑降世，雷动九霄",
		"desc": "爆伤+60%，天剑引雷冷却-35%+爆伤+80%，人剑合一+50%，暴击→剑意爆发",
	},
	"sword_shadow": {
		"name": "幽影剑诀", "school": "剑道", "tier": 2,
		"combat_stats": {"attack_speed_pct": 0.15, "dodge_cooldown_reduce_pct": 0.20},
		"exploration": {},
		"synergies": {
			"sword_draw": {"instant_damage_mult": 3.0},
			"sword_counter": {"counter_window_pct": 0.50},
		},
		"triggers": {"on_perfect_dodge": {"effect": "reset_skill", "skill_id": "sword_draw"}},
		"flavor": "剑出如影，一击必杀",
		"desc": "攻速+15%，闪避冷却-20%，拔刀斩×3，反击窗口+50%，完美闪避重置拔刀",
	},
	"seven_kill": {
		"name": "七杀剑诀", "school": "剑道", "tier": 2,
		"combat_stats": {},
		"exploration": {},
		"synergies": {
			"sword_execute": {"execute_threshold": 0.35},       # 斩杀线提升
		},
		"triggers": {
			"on_enemy_low_hp": {"effect": "execute_boost", "hp_threshold": 0.30, "damage_mult": 2.0},
			"on_kill": {"effect": "reset_skill_cooldowns", "amount_pct": 0.3},
		},
		"flavor": "七杀出鞘，不留活口",
		"desc": "对<30%HP敌人伤害×2，斩杀线提升至35%，击杀刷新30%冷却",
	},
	"green_lotus": {
		"name": "青莲剑歌", "school": "剑道", "tier": 3,
		"combat_stats": {"skill_cooldown_reduce_pct": 0.10},
		"exploration": {},
		"synergies": {
			"sword_slash": {"echo_chance": 0.5, "echo_damage": 0.5},
			"sword_flurry": {"echo_chance": 0.5, "echo_damage": 0.5},
			"sword_dance": {"echo_chance": 0.5, "echo_damage": 0.5},
		},
		"triggers": {"on_skill_cast": {"sword_chance": 0.5, "effect": "echo_attack"}},
		"flavor": "青莲出淤，剑歌不绝",
		"desc": "剑技冷却-10%，每次剑技50%触发回响(50%额外剑气)",
	},
	
	# ============================================================
	# ✨ 法术功法（6个）
	# ============================================================
	"blazing_heart": {
		"name": "烈焰心法", "school": "法术", "tier": 2,
		"combat_stats": {"fire_damage_bonus_pct": 0.30},
		"exploration": {},
		"synergies": {
			"fire_ball": {"burn_damage_mult": 2.0, "burn_prob_bonus": 0.3},
			"fire_storm": {"duration_bonus": 2.0, "tick_damage_pct": 0.8},
		},
		"triggers": {"on_burn_tick": {"effect": "restore_mp", "value": 1}},
		"flavor": "烈焰焚天，焚尽万物",
		"desc": "火伤+30%，火球灼烧翻倍+概率+30%，烈焰风暴+2秒，灼烧回蓝",
	},
	"frozen_will": {
		"name": "玄冰诀", "school": "法术", "tier": 2,
		"combat_stats": {"ice_damage_bonus_pct": 0.25, "slow_effect_bonus_pct": 0.20},
		"exploration": {"water_walk": true},
		"synergies": {
			"ice_spike": {"pierce_count_bonus": 2, "freeze_prob": 0.3},
			"frost_array": {"slow_pct_bonus": 0.20, "aoe_radius_bonus": 1.5},
			"arcane_freeze": {"freeze_duration_bonus": 1.5},
		},
		"triggers": {"on_freeze": {"effect": "chain_explosion", "radius": 3.0, "damage_pct": 0.5}},
		"flavor": "玄冰之境，万物凝滞",
		"desc": "冰伤+25%，减速+20%，水面行走，冰锥穿透+2+冰冻30%，冻结→冰爆",
	},
	"thunder_might": {
		"name": "雷霆秘典", "school": "法术", "tier": 3,
		"combat_stats": {"thunder_damage_bonus_pct": 0.30, "stun_prob_bonus": 0.15},
		"exploration": {},
		"synergies": {
			"thunder_bolt": {"aoe_radius_bonus": 2.0, "stun_duration_bonus": 0.8},
			"lightning_flash": {"teleport_range_bonus": 0.4, "damage_mult_add": 1.0},
		},
		"triggers": {"on_stun": {"effect": "thunder_strike", "damage_pct": 1.0}},
		"flavor": "雷霆万钧，天地失色",
		"desc": "雷伤+30%，眩晕概率+15%，天罚范围+2米，眩晕→追加雷击",
	},
	"arcane_master": {
		"name": "万象天引", "school": "法术", "tier": 3,
		"combat_stats": {"all_element_damage_pct": 0.15, "max_mp_bonus_pct": 0.30},
		"exploration": {},
		"synergies": {
			"element_burst": {"damage_per_mp": 0.8},
			"elemental_storm": {"chaos_explosions": 3},
			"life_tap": {"hp_cost_reduce_pct": 0.5, "cd_reset_bonus": 3.0},
		},
		"triggers": {"on_skill_cast": {"element_chance": 0.2, "effect": "random_element_proc"}},
		"flavor": "掌御万象，融汇五行",
		"desc": "全元素+15%，蓝上限+30%，元素爆发0.8/MP，五行+3爆，生命转化减半",
	},
	"lihuo_jue": {
		"name": "离火诀", "school": "法术", "tier": 2,
		"combat_stats": {"fire_crit_rate_bonus": 0.10},
		"exploration": {"lava_walk": true, "torch_radius_bonus": 0.5},
		"synergies": {
			"fire_ball": {"crit_damage_add": 0.5},
			"fire_storm": {"crit_chance_per_tick": 0.15},
		},
		"triggers": {"on_fire_crit": {"effect": "explosion", "radius": 2.0, "damage_pct": 0.5}},
		"flavor": "离火之精，焚天煮海",
		"desc": "火系暴击率+10%，火系暴击伤害+50%，火系暴击→小爆",
	},
	"cold_jade": {
		"name": "寒玉功", "school": "法术", "tier": 2,
		"combat_stats": {"ice_defense_bonus_pct": 0.15, "max_mp_bonus_pct": 0.15},
		"exploration": {"heat_resist": true, "cold_resist": true},
		"synergies": {
			"ice_spike": {"shield_on_hit_pct": 0.5},
			"frost_array": {"shield_value": 0.1},
		},
		"triggers": {"on_ice_cast": {"effect": "gain_shield", "shield_pct": 0.10}},
		"flavor": "寒玉凝神，冰肌玉骨",
		"desc": "冰伤+15% 蓝上限+15%，使用冰系法术获得10%伤害护盾，耐寒耐热",
	},
	
	# ============================================================
	# 👊 体术功法（5个）
	# ============================================================
	"diamond_body": {
		"name": "金刚不坏", "school": "体术", "tier": 2,
		"combat_stats": {"defense_bonus_pct": 0.25, "damage_reduction": 0.08},
		"exploration": {"knockback_resist": true},
		"synergies": {
			"iron_body": {"defense_buff_pct_bonus": 0.30, "buff_duration_bonus": 2.0},
			"golden_body": {"invincible_duration_bonus": 1.5, "heal_pct_bonus": 0.15},
		},
		"triggers": {"on_hit": {"effect": "thorn_damage", "damage_pct": 0.15}},
		"flavor": "金刚不坏，万法不侵",
		"desc": "防御+25%，减伤+8%，金刚体+30%+2秒，金身+1.5秒，反伤15%",
	},
	"dragon_veins": {
		"name": "龙脉锻体", "school": "体术", "tier": 3,
		"combat_stats": {"max_hp_bonus_pct": 0.30, "hp_regen": 5.0, "all_damage_bonus_pct": 0.10},
		"exploration": {"carry_weight_bonus_pct": 0.50, "break_objects": true},
		"synergies": {
			"quake_stomp": {"aoe_radius_bonus": 2.0, "stun_prob_bonus": 0.25},
			"dragon_grab": {"pull_range_bonus": 3.0, "stun_duration_bonus": 0.8},
		},
		"triggers": {"on_kill": {"effect": "heal_pct", "value": 0.10}},
		"flavor": "龙脉入体，气吞山河",
		"desc": "HP+30%，回血+5/s，全伤+10%，负重+50%，可破坏障碍物",
	},
	"undefeated_body": {
		"name": "不败金身", "school": "体术", "tier": 3,
		"combat_stats": {},
		"exploration": {},
		"synergies": {},
		"triggers": {
			"on_low_hp": {"effect": "last_stand", "hp_threshold": 0.30, "duration": 5.0, "damage_reduce": 0.50, "cooldown": 60.0}
		},
		"flavor": "金身不破，屹立不倒",
		"desc": "生命<30%时自动触发5秒减伤50%，冷却60秒",
	},
	"agile_body": {
		"name": "神行百变", "school": "体术", "tier": 2,
		"combat_stats": {"dodge_cooldown_reduce_pct": 0.15},
		"exploration": {"move_speed_bonus_pct": 0.12, "wall_jump": true},
		"synergies": {},
		"triggers": {"on_dodge": {"effect": "damage_reduce_buff", "duration": 2.0, "damage_reduce": 0.30}},
		"flavor": "神行百变，游刃有余",
		"desc": "移速+12%，闪避冷却-15%，可以蹬墙跳，闪避后2秒减伤30%",
	},
	
	# ============================================================
	# 📜 符道功法（5个）
	# ============================================================
	"talisman_master": {
		"name": "天师符法", "school": "符道", "tier": 2,
		"combat_stats": {"talisman_damage_bonus_pct": 0.25, "debuff_duration_bonus": 1.5},
		"exploration": {"debuff_resist": 0.3},
		"synergies": {
			"thunder_seal": {"damage_mult_add": 0.8, "paralyze_prob_bonus": 0.2},
			"soul_seal": {"silence_prob_bonus": 0.3, "silence_duration_bonus": 1.0},
		},
		"triggers": {"on_debuff": {"effect": "talisman_mark", "damage_pct": 0.2}},
		"flavor": "符箓通神，驱邪缚魅",
		"desc": "符伤+25%，减益时间+1.5秒，天雷符+80%伤害，减益→符印",
	},
	"eight_trigrams_dao": {
		"name": "八卦天道", "school": "符道", "tier": 3,
		"combat_stats": {"array_range_bonus": 0.5, "debuff_all_pct_bonus": 0.10},
		"exploration": {"auto_array_out_combat": true},
		"synergies": {
			"eight_trigrams": {"field_duration_bonus": 4.0, "ally_buff_pct": 0.15},
		},
		"triggers": {"on_field_tick": {"effect": "restore_hp_mp", "hp_pct": 0.01, "mp": 2}},
		"flavor": "八卦衍天道，阵起定乾坤",
		"desc": "阵法范围+50%，八卦阵+4秒+队友加成15%，脱战自动布阵",
	},
	"void_talisman": {
		"name": "太虚符法", "school": "符道", "tier": 3,
		"combat_stats": {"talisman_crit_rate_bonus": 0.10},
		"exploration": {"teleport_to_marker": true, "marker_count": 3},
		"synergies": {
			"soul_seal": {"dispel": true},
			"thunder_seal": {"dispel": true},
		},
		"triggers": {"on_talisman_crit": {"effect": "echo_seal", "damage_pct": 1.0}},
		"flavor": "太虚之境，符法通天",
		"desc": "符箓暴击率+10%，符箓附加驱散效果，符箓暴击→再触发一次",
	},
}

# ============================
# ⭐ 突破配置
# ============================
const BREAKTHROUGH_CONFIG: Dictionary = {
	GongfaStage.MINOR: {
		"level_req": 4,
		"conditions": {
			"school_level": {"min": 10, "desc": "对应流派等级≥10"},
		},
		"unlocks": ["exploration"],  # 小成解锁探索效果
		"desc": "悟得功法真意，探索天地之妙",
	},
	GongfaStage.MAJOR: {
		"level_req": 7,
		"conditions": {
			"school_level": {"min": 20, "desc": "对应流派等级≥20"},
			"kill_count": {"min": 50, "desc": "累计击杀≥50"},
		},
		"unlocks": ["triggers"],  # 大成解锁触发效果
		"desc": "功法大成，心随意动，引动天地之力",
	},
	GongfaStage.PERFECT: {
		"level_req": 10,
		"conditions": {
			"school_level": {"min": 30, "desc": "对应流派等级≥30"},
			"kill_count": {"min": 200, "desc": "累计击杀≥200"},
			"master_skill": {"count": 3, "desc": "掌握该流派≥3个技能"},
		},
		"unlocks": ["ultimate"],  # 圆满解锁终极效果
		"desc": "功法圆满，超凡入圣，天下无双",
	},
}

# ==================== 装备槽 ====================
const MAX_EQUIPPED: int = 3

# ==================== 运行时状态 ====================
var _equipped: Array[String] = []
var _gongfa_stages: Dictionary = {}           # gongfa_id → GongfaStage
var _gongfa_levels: Dictionary = {}           # gongfa_id → level (1-10)
var _gongfa_exp: Dictionary = {}              # gongfa_id → exp
var _gongfa_breakthrough_cd: Dictionary = {}  # gongfa_id → timestamp (突破CD)

# 缓存
var _cached_combat_stats: Dictionary = {}
var _cached_exploration: Dictionary = {}
var _cached_synergies: Dictionary = {}
var _cached_triggers: Array[Dictionary] = []
var _cached_ultimate: Array[Dictionary] = []

# 外部引用
var _skill_manager = null
var _cultivation = null

# 玩家数据（突破条件用）
var _player_kill_count: int = 0

# 信号
signal gongfa_equipped(gongfa_id: String, slot: int)
signal gongfa_unequipped(gongfa_id: String, slot: int)
signal gongfa_leveled(gongfa_id: String, new_level: int)
signal gongfa_breakthrough(gongfa_id: String, new_stage: int, stage_name: String)
signal gongfa_synergy_triggered(gongfa_id: String, skill_id: String, effect_desc: String)

func _ready() -> void:
	_skill_manager = get_node("/root/GameManager/SkillManager") if has_node("/root/GameManager/SkillManager") else null
	var gm = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	if gm and gm.cultivation:
		_cultivation = gm.cultivation
	_recalc_all()

func _process(delta: float) -> void:
	# 脱战恢复效果（通过引擎外部调用，这里只是占位）
	pass

# ============================
# 📜 功法装备管理
# ============================

func equip_gongfa(gongfa_id: String, slot: int) -> bool:
	if not GONGFA_DB.has(gongfa_id): return false
	if slot < 0 or slot >= MAX_EQUIPPED: return false
	if gongfa_id in _equipped: return false
	
	if slot < _equipped.size():
		unequip_gongfa(slot)
	while _equipped.size() <= slot:
		_equipped.append("")
	
	_equipped[slot] = gongfa_id
	if not _gongfa_levels.has(gongfa_id):
		_gongfa_levels[gongfa_id] = 1
		_gongfa_exp[gongfa_id] = 0
	if not _gongfa_stages.has(gongfa_id):
		_gongfa_stages[gongfa_id] = GongfaStage.INITIAL
	
	_recalc_all()
	gongfa_equipped.emit(gongfa_id, slot)
	print("📜 装备功法 [%s] 境界:%s" % [GONGFA_DB[gongfa_id].name, STAGE_NAMES[_gongfa_stages[gongfa_id]]])
	return true

func unequip_gongfa(slot: int) -> bool:
	if slot < 0 or slot >= _equipped.size(): return false
	var gongfa_id = _equipped[slot]
	if gongfa_id.is_empty(): return false
	_equipped[slot] = ""
	_recalc_all()
	gongfa_unequipped.emit(gongfa_id, slot)
	return true

func has_gongfa(gongfa_id: String) -> bool:
	return gongfa_id in _equipped

func get_equipped_gongfa() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for gid in _equipped:
		if not gid.is_empty():
			result.append({
				"id": gid, "data": GONGFA_DB[gid],
				"level": _gongfa_levels.get(gid, 1),
				"stage": _gongfa_stages.get(gid, GongfaStage.INITIAL),
				"stage_name": STAGE_NAMES[_gongfa_stages.get(gid, GongfaStage.INITIAL)],
			})
	return result

# ============================
# 📈 功法升级 + 突破
# ============================

func add_gongfa_exp(gongfa_id: String, amount: int) -> void:
	if not _gongfa_levels.has(gongfa_id):
		_gongfa_levels[gongfa_id] = 1
		_gongfa_exp[gongfa_id] = 0
	
	_gongfa_exp[gongfa_id] = _gongfa_exp.get(gongfa_id, 0) + amount
	
	var current_level = _gongfa_levels[gongfa_id]
	var exp_needed = _get_exp_for_level(current_level)
	
	while _gongfa_exp[gongfa_id] >= exp_needed and current_level < 10:
		_gongfa_exp[gongfa_id] -= exp_needed
		current_level += 1
		_gongfa_levels[gongfa_id] = current_level
		exp_needed = _get_exp_for_level(current_level)
		gongfa_leveled.emit(gongfa_id, current_level)
		print("📜 %s 升级！Lv.%d" % [GONGFA_DB[gongfa_id].name, current_level])
		_recalc_all()

func _get_exp_for_level(level: int) -> int:
	return level * 80 + 20  # 100, 180, 260, ...

## 尝试突破功法境界
## 返回 {success, stage, stage_name, reason}
func try_breakthrough(gongfa_id: String) -> Dictionary:
	if not GONGFA_DB.has(gongfa_id):
		return {"success": false, "reason": "功法不存在"}
	
	var current_stage = _gongfa_stages.get(gongfa_id, GongfaStage.INITIAL)
	if current_stage >= GongfaStage.PERFECT:
		return {"success": false, "reason": "已达圆满境界"}
	
	var next_stage = current_stage + 1
	var config = BREAKTHROUGH_CONFIG.get(next_stage, {})
	if config.is_empty():
		return {"success": false, "reason": "突破配置不存在"}
	
	# 检查等级
	if _gongfa_levels.get(gongfa_id, 1) < config.get("level_req") or 99:
		return {"success": false, "reason": "功法等级不足（需要Lv.%d）" % config.get("level_req") or 99}
	
	# 检查条件
	var conditions = config.get("conditions", {})
	for cond_key in conditions:
		var cond = conditions[cond_key]
		match cond_key:
			"school_level":
				var school = GONGFA_DB[gongfa_id].get("school") or "通用"
				var school_type = _school_name_to_type(school)
				if school_type >= 0 and _cultivation:
					var level = _cultivation.school_levels.get(school_type, 0)
					if level < cond.get("min") or 99:
						return {"success": false, "reason": cond.get("desc") or "条件不足"}
			
			"kill_count":
				if _player_kill_count < cond.get("min") or 999:
					return {"success": false, "reason": cond.get("desc") or "击杀不足"}
			
			"master_skill":
				var count = cond.get("count") or 0
				var school = GONGFA_DB[gongfa_id].get("school") or "通用"
				var school_name = school
				var school_skills = _skill_manager.get_school_skill_ids(school_name) if _skill_manager else []
				if _cultivation:
					var learned = 0
					for sid in school_skills:
						if _cultivation.has_skill(sid):
							learned += 1
					if learned < count:
						return {"success": false, "reason": cond.get("desc") or "掌握技能不足"}
	
	# ✅ 突破成功
	_gongfa_stages[gongfa_id] = next_stage
	_recalc_all()
	gongfa_breakthrough.emit(gongfa_id, next_stage, STAGE_NAMES[next_stage])
	print("⭐ %s 突破！【%s → %s】" % [
		GONGFA_DB[gongfa_id].name,
		STAGE_NAMES[current_stage], STAGE_NAMES[next_stage]
	])
	return {
		"success": true,
		"stage": next_stage,
		"stage_name": STAGE_NAMES[next_stage],
	}

func _school_name_to_type(school_name: String) -> int:
	match school_name:
		"剑道": return 0
		"法术": return 1
		"体术": return 2
		"丹道": return 3
		"符道": return 4
	return -1

# ============================
# 🧮 加成计算（带境界倍率）
# ============================

func _get_stage_mult(gongfa_id: String) -> float:
	var stage = _gongfa_stages.get(gongfa_id, GongfaStage.INITIAL)
	return STAGE_MULTS.get(stage, 1.0)

func _recalc_all() -> void:
	_cached_combat_stats = {}
	_cached_exploration = {}
	_cached_synergies = {}
	_cached_triggers = []
	_cached_ultimate = []
	
	for gid in _equipped:
		if gid.is_empty(): continue
		var data = GONGFA_DB.get(gid, {})
		if data.is_empty(): continue
		
		var stage = _gongfa_stages.get(gid, GongfaStage.INITIAL)
		var mult = STAGE_MULTS.get(stage, 1.0)
		var level = _gongfa_levels.get(gid, 1)
		var level_mult = 1.0 + (level - 1) * 0.08  # 每级+8%
		
		# === combat_stats ===
		var cstats = data.get("combat_stats", {})
		for key in cstats:
			_cached_combat_stats[key] = _cached_combat_stats.get(key, 0.0) + cstats[key] * mult * level_mult
		
		# === exploration（小成解锁） ===
		if stage >= GongfaStage.MINOR:
			var exp = data.get("exploration", {})
			for key in exp:
				var val = exp[key]
				if typeof(val) == TYPE_FLOAT or typeof(val) == TYPE_INT:
					_cached_exploration[key] = _cached_exploration.get(key, 0.0) + val * mult * level_mult
				else:
					_cached_exploration[key] = val  # bool值直接覆盖
		
		# === synergies（始终可用） ===
		var synergies = data.get("synergies", {})
		for skill_id in synergies:
			if not _cached_synergies.has(skill_id):
				_cached_synergies[skill_id] = {}
			for eff_key in synergies[skill_id]:
				var val = synergies[skill_id][eff_key]
				if typeof(val) == TYPE_FLOAT or typeof(val) == TYPE_INT:
					_cached_synergies[skill_id][eff_key] = _cached_synergies[skill_id].get(eff_key, 0.0) + val * mult * level_mult
		
		# === triggers（大成解锁） ===
		if stage >= GongfaStage.MAJOR:
			var triggers = data.get("triggers", {})
			for trigger_key in triggers:
				_cached_triggers.append({
					"gongfa_id": gid, "trigger": trigger_key,
					"effect": triggers[trigger_key].duplicate(),
					"stage": stage,
				})
		
		# === ultimate（圆满解锁） ===
		if stage >= GongfaStage.PERFECT:
			var ultimate = data.get("ultimate", {})
			if not ultimate.is_empty():
				_cached_ultimate.append({
					"gongfa_id": gid, "data": ultimate,
				})

# ============================
# 📤 对外接口
# ============================

## 战斗属性加成
func get_combat_stat_bonuses() -> Dictionary:
	return _cached_combat_stats.duplicate()

## 探索/生活效果
func get_exploration_effects() -> Dictionary:
	return _cached_exploration.duplicate()

## 技能联动
func get_skill_synergy(skill_id: String) -> Dictionary:
	return _cached_synergies.get(skill_id, {}).duplicate()

## 应用功法联动到技能
func apply_synergy_to_skill(skill_id: String, skill_data: Dictionary) -> Dictionary:
	var result = skill_data.duplicate(true)
	var synergy = _cached_synergies.get(skill_id, {})
	if synergy.is_empty(): return result
	
	var effects = result.get("effects", {}).duplicate(true)
	
	for key in synergy:
		match key:
			"extra_swords": effects["count"] = effects.get("count") or 0 + int(synergy[key])
			"extra_hits": effects["multi_hit"] = effects.get("multi_hit") or 0 + int(synergy[key])
			"range_bonus": result["range"] = result.get("range") or 3.0 + synergy[key]
			"damage_mult_add": result["damage_mult"] = result.get("damage_mult") or 1.0 + synergy[key]
			"cooldown_reduce_pct": result["cooldown"] = result.get("cooldown") or 0.0 * (1.0 - synergy[key])
			"duration_bonus": effects["duration"] = effects.get("duration") or 0.0 + synergy[key]
			"burn_damage_mult": effects["burn_damage"] = effects.get("burn_damage") or 0 * synergy[key]
			"burn_prob_bonus": effects["burn_prob"] = min(effects.get("burn_prob") or 0.0 + synergy[key], 1.0)
			"freeze_prob": effects["freeze_prob"] = min(effects.get("freeze_prob") or 0.0 + synergy[key], 1.0)
			"slow_pct_bonus": effects["slow_pct"] = min(effects.get("slow_pct") or 0.0 + synergy[key], 1.0)
			"stun_prob_bonus": effects["stun_prob"] = min(effects.get("stun_prob") or 0.0 + synergy[key], 1.0)
			"execute_threshold": effects["execute_threshold"] = synergy[key]
			"echo_chance": effects["echo_chance"] = synergy[key]
			"echo_damage": effects["echo_damage"] = synergy[key]
			"shield_on_hit_pct": effects["shield_on_hit"] = synergy[key]
			"shield_value": effects["shield_value"] = synergy[key]
			"dispel": effects["dispel"] = true
			"consume_intent_damage_per_stack": effects["per_intent_damage"] = synergy[key]
			_:
				effects[key] = synergy[key]
	
	for key in synergy:
		match key:
			"aoe_radius_bonus": result["range"] = result.get("range") or 5.0 + synergy[key]
			"pierce_count_bonus": effects["pierce"] = true
			"invincible_duration_bonus": effects["duration"] = effects.get("duration") or 0.0 + synergy[key]
			"heal_pct_bonus": effects["heal_pct"] = effects.get("heal_pct") or 0.0 + synergy[key]
			"pull_range_bonus": result["range"] = result.get("range") or 5.0 + synergy[key]
			"field_duration_bonus": effects["field_duration"] = effects.get("field_duration") or 0.0 + synergy[key]
			"chaos_explosions": effects["extra_explosions"] = int(synergy[key])
			"damage_per_mp": effects["damage_per_mp"] = synergy[key]
			"hp_cost_reduce_pct": effects["hp_cost_mult"] = 1.0 - synergy[key]
			"cd_reset_bonus": effects["cd_reset_seconds"] = synergy[key]
			"extra_crit_damage": effects["extra_crit_damage"] = synergy[key]
			"extra_damage_pct": effects["extra_damage"] = synergy[key]
			"counter_window_pct": effects["counter_window_mult"] = 1.0 + synergy[key]
			"instant_damage_mult": result["damage_mult"] = result.get("damage_mult") or 1.0 * synergy[key]
			"tick_damage_pct": effects["tick_damage_mult"] = synergy[key]
			"teleport_range_bonus": effects["teleport_range_mult"] = 1.0 + synergy[key]
			"stun_duration_bonus": effects["stun_duration"] = effects.get("stun_duration") or 0.0 + synergy[key]
			"silence_prob_bonus": effects["silence_prob"] = min(effects.get("silence_prob") or 0.0 + synergy[key], 1.0)
			"silence_duration_bonus": effects["silence_duration"] = effects.get("silence_duration") or 0.0 + synergy[key]
			"ally_buff_pct": effects["ally_buff"] = synergy[key]
			"crit_damage_add": effects["crit_damage_add"] = synergy[key]
			"crit_chance_per_tick": effects["crit_chance_tick"] = synergy[key]
			"max_sword_intent": effects["max_intent_bonus"] = int(synergy[key])
			"hp_cost_reduce_pct": effects["hp_cost_mult"] = 1.0 - synergy[key]
			"defense_buff_pct_bonus": effects["defense_buff_extra"] = synergy[key]
	
	result["effects"] = effects
	return result

## 战斗触发
func try_trigger(event_name: String, context: Dictionary = {}) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for trigger in _cached_triggers:
		if trigger["trigger"] == event_name:
			var effect = trigger["effect"].duplicate()
			effect["gongfa_id"] = trigger["gongfa_id"]
			effect["gongfa_name"] = GONGFA_DB.get(trigger["gongfa_id"], {}).get("name") or "?"
			results.append(effect)
			gongfa_synergy_triggered.emit(
				trigger["gongfa_id"], context.get("skill_id") or "",
				"触发 [%s]" % effect.get("effect") or "?"
			)
	return results

## 获取所有功法完整数据
func get_all_gongfa() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for gid in GONGFA_DB.keys():
		var stage = _gongfa_stages.get(gid, GongfaStage.INITIAL)
		var next_stage = stage < GongfaStage.PERFECT
		var bt_config = BREAKTHROUGH_CONFIG.get(stage + 1, {}) if next_stage else {}
		result.append({
			"id": gid,
			"data": GONGFA_DB[gid],
			"level": _gongfa_levels.get(gid, 1),
			"exp": _gongfa_exp.get(gid, 0),
			"stage": stage,
			"stage_name": STAGE_NAMES[stage],
			"equipped": gid in _equipped,
			"equip_slot": _equipped.find(gid) if gid in _equipped else -1,
			"can_breakthrough": next_stage and _can_breakthrough_check(gid, stage + 1).get("success") or false,
			"breakthrough_reqs": bt_config.get("conditions", {}),
		})
	return result

func _can_breakthrough_check(gongfa_id: String, target_stage: int) -> Dictionary:
	var config = BREAKTHROUGH_CONFIG.get(target_stage, {})
	if config.is_empty():
		return {"success": false, "reason": "已达最高境界"}
	if _gongfa_levels.get(gongfa_id, 1) < config.get("level_req") or 99:
		return {"success": false}
	return {"success": true}

func get_equipped_count() -> int:
	var count = 0
	for gid in _equipped:
		if not gid.is_empty(): count += 1
	return count

## 获取特定探索效果值
func get_exploration_value(key: String, default = null):
	return _cached_exploration.get(key, default)

## 增加击杀计数
func add_kill(count: int = 1) -> void:
	_player_kill_count += count
