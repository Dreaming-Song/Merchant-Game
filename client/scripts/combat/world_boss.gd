extends CharacterBody3D
## 五行神兽 · BOSS 单位 — Phase 4 世界首领

const CreatureAppearance = preload("res://scripts/visuals/creature_appearance.gd")
const ThreatSystem = preload("res://scripts/combat/threat_system.gd")

## 每只神兽对应一个地貌，拥有：
## - 2 阶段变身（HP<50% 进入 Phase 2）
## - 专属五行技能
## - 全服通告 + 稀有掉落
## - 击败后冷却刷新（游戏天数）

enum Element { WOOD, FIRE, EARTH, METAL, WATER }

enum BossPhase { PHASE_1, PHASE_2 }

# 五行神兽类型（与 Element 一一对应）
enum BossType {
	AZURE_DRAGON = Element.WOOD,
	VERMILION_BIRD = Element.FIRE,
	GOLDEN_QILIN = Element.EARTH,
	WHITE_TIGER = Element.METAL,
	BLACK_WARRIOR = Element.WATER,
}

# ---------- BOSS 配置 ----------
const BOSS_NAME: Dictionary = {
	Element.WOOD: "青木神龙",
	Element.FIRE: "赤炎凤凰",
	Element.EARTH: "玄黄麒麟",
	Element.METAL: "白金白虎",
	Element.WATER: "幽冥玄武",
}

const BOSS_TITLE: Dictionary = {
	Element.WOOD: "东方·青龙",
	Element.FIRE: "南方·朱雀",
	Element.EARTH: "中央·麒麟",
	Element.METAL: "西方·白虎",
	Element.WATER: "北方·玄武",
}

const BOSS_COLORS: Dictionary = {
	Element.WOOD: Color(0.0, 0.8, 0.3),
	Element.FIRE: Color(0.9, 0.2, 0.1),
	Element.EARTH: Color(0.7, 0.6, 0.2),
	Element.METAL: Color(0.8, 0.8, 0.9),
	Element.WATER: Color(0.2, 0.4, 0.8),
}

const BOSS_ELEMENT: Dictionary = {
	Element.WOOD: "木",
	Element.FIRE: "火",
	Element.EARTH: "土",
	Element.METAL: "金",
	Element.WATER: "水",
}

static func get_boss_config(t: int) -> Dictionary:
	"""根据类型返回 BOSS 配置"""
	var biome_map = {
		Element.WOOD: "bamboo_forest",
		Element.FIRE: "volcano",
		Element.EARTH: "snow_peak",
		Element.METAL: "maple_forest",
		Element.WATER: "swamp",
	}
	return {
		"type": t,
		"name": BOSS_NAME.get(t, "未知神兽"),
		"title": BOSS_TITLE.get(t, "未知"),
		"color": BOSS_COLORS.get(t, Color.WHITE),
		"element": BOSS_ELEMENT.get(t, "无"),
		"max_hp": 50000 + t * 5000,
		"phase2_hp_ratio": 0.5,
		"base_attack": 200 + t * 30,
		"base_defense": 100 + t * 20,
		"speed": 4.0,
		"spawn_interval_days": 3,
		"drop_table": ["soul_crystal", "element_essence", "boss_trophy"],
		"phase2_skills": ["inferno_breath", "elemental_storm", "terra_fury"],
		"spawn_position": Vector3(100 + t * 200, 0, 200 + t * 150),
		"spawn_biome": biome_map.get(t, ""),
	}

# ---------- 实例属性 ----------
var boss_type: int = 0
var team_mode: bool = false
var boss_id: String
var element_type: int = Element.WOOD
var current_phase: BossPhase = BossPhase.PHASE_1
var max_hp: float = 50000.0
var current_hp: float = 50000.0
var base_attack: float = 200.0
var base_defense: float = 100.0
var move_speed: float = 4.0

var threat_system: ThreatSystem = null
var appearance_root: Node3D = null

# 信号
signal boss_damaged(boss_name: String, damage: int, current_hp: int, max_hp: int, phase: int)
signal boss_phase_changed(boss_name: String, phase: int)
signal boss_defeated(boss_name: String)
signal boss_ability(boss_name: String, ability_name: String)
signal phase_changed(boss_name: String, new_phase: int)
signal defeated(boss_name: String)
signal hp_changed(hp_ratio: float)

func _ready() -> void:
	var config = get_boss_config(element_type)
	max_hp = config.get("max_hp", 50000)
	current_hp = max_hp
	base_attack = config.get("base_attack", 200)
	base_defense = config.get("base_defense", 100)
	move_speed = config.get("speed", 4.0)
	
	# 构建外观
	var key = BOSS_NAME.get(element_type, "")
	if key:
		appearance_root = CreatureAppearance.build_appearance(key, false, true)
		if appearance_root:
			add_child(appearance_root)
		else:
			push_error("❌ 无法构建 BOSS 外观: %s" % key)
	
	# 威胁系统
	threat_system = ThreatSystem.new()
	
	print("🐉 %s 降临！" % BOSS_NAME.get(element_type, "神兽"))

func take_damage(amount: float, attacker) -> void:
	"""承受伤害"""
	var dmg = max(1.0, amount - base_defense * 0.1)
	current_hp = max(0.0, current_hp - dmg)
	
	var ratio = current_hp / max_hp
	hp_changed.emit(ratio)
	
	if ratio <= 0.5 and current_phase == BossPhase.PHASE_1:
		current_phase = BossPhase.PHASE_2
		phase_changed.emit(BOSS_NAME.get(element_type, ""), 2)
	
	if current_hp <= 0:
		defeated.emit(BOSS_NAME.get(element_type, ""))

func _process(delta: float) -> void:
	if threat_system and current_hp > 0:
		# ThreatSystem._process 已自动处理威胁衰减
		pass
