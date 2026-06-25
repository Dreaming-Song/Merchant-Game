extends Node
## 📖 图鉴系统 — 发现记录 + 描述查询
##
## 自动记录玩家首次发现的：
## - 敌人（击杀时记录）
## - 物品（获得时记录）
## - 技能（学习时记录）
## - 功法（获得时记录）
## - 生物群系（进入时记录）
##
## 提供统一的描述查询接口，可扩展性强。

class_name CyclopediaSystem

# ==================== 图鉴分类 ====================
enum Category {
	ENEMY,      # 妖兽
	ITEM,       # 物品
	SKILL,      # 技能
	GONGFA,     # 功法
	BIOME,      # 生物群系
	PET,        # 灵宠（孵化后记录）
}

const CATEGORY_NAMES: Dictionary = {
	Category.ENEMY: "妖兽", Category.ITEM: "物品",
	Category.SKILL: "技能", Category.GONGFA: "功法",
	Category.BIOME: "群系", Category.PET: "灵宠",
}

# ==================== 数据存储 ====================
## entries[category][entry_id] = { id, name, desc, icon, discovered, details }
var _entries: Dictionary = {}

# ==================== 预置数据源 ====================
## 图鉴条目定义（未发现时也显示名称和简述）
## 发现后解锁完整描述
const PRESET_ENTRIES: Dictionary = {
	# ---------- 妖兽 ----------
	Category.ENEMY: {
		"spirit_wolf": {
			"name": "灵狼", "icon": "wolf",
			"desc": "竹林与枫林常见的敏捷型妖兽。速度快，擅长绕后攻击。",
			"details": {"类型": "近战敏捷", "掉落": "灵狼牙、兽肉、狼毫", "精英": "★灵狼王"},
		},
		"mist_ape": {
			"name": "雾猿", "icon": "ape",
			"desc": "生活在雾气中的大型猿猴。远程投石，保持距离作战。",
			"details": {"类型": "远程风筝", "掉落": "猿猴果、兽肉、灵木", "精英": "★雾猿长老"},
		},
		"flame_boar": {
			"name": "焰猪", "icon": "boar",
			"desc": "火山地带狂暴的野猪。冲锋撞击后有明显后摇，是输出窗口。",
			"details": {"类型": "冲撞重击", "掉落": "火熔石、兽肉、焰鬃毛", "精英": "★焰猪王"},
		},
		"iron_tortoise": {
			"name": "铁龟", "icon": "tortoise",
			"desc": "沼泽中的坚甲龟兽。缩壳时减伤80%并反弹伤害，需破防后攻击。",
			"details": {"类型": "重甲反伤", "掉落": "龟甲片、灵水、玄铁", "精英": "★铁龟老祖"},
		},
		"world_boss": {
			"name": "五行神兽", "icon": "boss",
			"desc": "世界BOSS，对应五行属性。2阶段变身，击败后固定掉落对应神兽宠物蛋。",
			"details": {"类型": "世界首领", "掉落": "灵珠、鳞甲/羽/牙/角、★神兽宠物蛋"},
		},
	},
	
	# ---------- 灵宠 ----------
	Category.PET: {
		"crane": {"name": "仙鹤", "icon": "crane", "desc": "优雅的仙鹤，擅长飞行载人。亲密度70解锁载人飞行。"},
		"fox": {"name": "灵狐", "icon": "fox", "desc": "灵巧的九尾狐，擅长采集辅助。亲密度50解锁采集助手。"},
		"panda": {"name": "竹熊", "icon": "panda", "desc": "憨厚但力大无穷的竹熊，擅长辅助战斗。"},
		"pixiu": {"name": "貔貅", "icon": "pixiu", "desc": "上古神兽貔貅，能增幅主人战斗力，稀有！"},
		"azure_dragon": {"name": "青龙", "icon": "dragon", "desc": "东方木德神兽·青龙幼体，掌控生机之力。"},
		"white_tiger": {"name": "白虎", "icon": "tiger", "desc": "西方金德神兽·白虎幼体，锐不可当。"},
		"vermilion_bird": {"name": "朱雀", "icon": "phoenix", "desc": "南方火德神兽·朱雀幼体，涅槃重生。"},
		"black_warrior": {"name": "玄武", "icon": "turtle", "desc": "北方水德神兽·玄武幼体，坚不可摧。"},
		"golden_qilin": {"name": "麒麟", "icon": "qilin", "desc": "中央土德神兽·麒麟幼体，祥瑞之兆。"},
	},
}

func _ready() -> void:
	_load_presets()

func _load_presets() -> void:
	"""加载预置条目到图鉴（未发现状态）"""
	for cat in PRESET_ENTRIES:
		if not _entries.has(cat):
			_entries[cat] = {}
		for eid in PRESET_ENTRIES[cat]:
			var data = PRESET_ENTRIES[cat][eid].duplicate()
			data["id"] = eid
			data["category"] = cat
			data["discovered"] = false
			_entries[cat][eid] = data

# ==================== API ====================

## 发现/记录一个条目
func discover_entry(category: int, entry_id: String) -> bool:
	if not _entries.has(category):
		_entries[category] = {}
	
	# 如果不存在，创建一个占位条目
	if not _entries[category].has(entry_id):
		_entries[category][entry_id] = {
			"id": entry_id, "name": entry_id, "category": category,
			"desc": "尚待探索...", "icon": "", "discovered": true,
			"details": {},
		}
		return true
	
	var entry = _entries[category][entry_id]
	if entry.get("discovered") or false:
		return false  # 已发现
	
	entry["discovered"] = true
	print("📖 图鉴新发现！[%s] %s" % [CATEGORY_NAMES.get(category, "?"), entry.get("name") or entry_id])
	return true

## 动态添加条目（供后续DLC/扩展使用）
func add_entry(category: int, entry_id: String, data: Dictionary) -> void:
	if not _entries.has(category):
		_entries[category] = {}
	
	var entry = data.duplicate()
	entry["id"] = entry_id
	entry["category"] = category
	entry["discovered"] = entry.get("discovered") or false
	_entries[category][entry_id] = entry

## 查询是否已发现
func is_discovered(category: int, entry_id: String) -> bool:
	if not _entries.has(category) or not _entries[category].has(entry_id):
		return false
	return _entries[category][entry_id].get("discovered") or false

## 获取条目完整信息
func get_entry(category: int, entry_id: String) -> Dictionary:
	if _entries.has(category) and _entries[category].has(entry_id):
		return _entries[category][entry_id].duplicate()
	return {"id": entry_id, "name": "???", "desc": "尚未发现", "discovered": false}

## 获取描述文本（已发现返回描述，未发现返回"???"）
func get_description(category: int, entry_id: String) -> String:
	var entry = get_entry(category, entry_id)
	if entry.get("discovered") or false:
		return entry.get("desc") or "暂无描述"
	return "尚未发现此%s..." % CATEGORY_NAMES.get(category, "内容")

## 获取某类所有已发现条目
func get_all_discovered(category: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not _entries.has(category):
		return result
	for eid in _entries[category]:
		var entry = _entries[category][eid]
		if entry.get("discovered") or false:
			result.append(entry.duplicate())
	return result

## 获取某类所有条目（含未发现）
func get_all_entries(category: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not _entries.has(category):
		return result
	for eid in _entries[category]:
		result.append(_entries[category][eid].duplicate())
	return result

## 获取未发现条目（灰色显示用）
func get_undiscovered_count(category: int) -> int:
	var count = 0
	if _entries.has(category):
		for eid in _entries[category]:
			if not _entries[category][eid].get("discovered") or false:
				count += 1
	return count

## 获取图鉴完成度
func get_completion() -> Dictionary:
	var total = 0
	var discovered = 0
	for cat in _entries:
		for eid in _entries[cat]:
			total += 1
			if _entries[cat][eid].get("discovered") or false:
				discovered += 1
	return {"total": total, "discovered": discovered, "pct": float(discovered) / max(total, 1)}

## 保存
func get_save_data() -> Dictionary:
	var data = {}
	for cat in _entries:
		var cat_name = str(cat)
		data[cat_name] = {}
		for eid in _entries[cat]:
			data[cat_name][eid] = {"discovered": _entries[cat][eid].get("discovered") or false}
	return data

func load_save_data(data: Dictionary) -> void:
	for cat_str in data:
		var cat = int(cat_str)
		if not _entries.has(cat):
			_entries[cat] = {}
		for eid in data[cat_str]:
			if _entries[cat].has(eid):
				_entries[cat][eid]["discovered"] = data[cat_str][eid].get("discovered") or false
