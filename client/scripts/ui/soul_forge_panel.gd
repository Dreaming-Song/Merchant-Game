## 魂器锻造面板
##
## 5种锻造方案的 UI 入口
## 只对 武器/工具/防具/食品/背包 显示可操作
## 靠近魂器锻造台时自动打开
extends Control
class_name SoulForgePanel

const SoulForgeSystem = preload("res://scripts/crafting/soul_forge_system.gd")

# ==================== 节点引用 ====================
@onready var item_slot_icon: TextureRect = get_node_or_null("ItemSlot/SlotIcon")
@onready var item_slot_border: TextureRect = get_node_or_null("ItemSlot/SlotBorder")
@onready var item_name_label: Label = get_node_or_null("ItemInfo/ItemName")
@onready var item_category_label: Label = get_node_or_null("ItemInfo/ItemCategory")
@onready var source_tabs: HBoxContainer = get_node_or_null("SourceTabs")
@onready var source_detail: Control = get_node_or_null("SourceDetail")
@onready var source_name_label: Label = get_node_or_null("SourceDetail/SourceName")
@onready var source_desc_label: Label = get_node_or_null("SourceDetail/SourceDesc")
@onready var source_chance_label: Label = get_node_or_null("SourceDetail/ChanceLabel")
@onready var source_vfx_preview: ColorRect = get_node_or_null("SourceDetail/VfxPreview")
@onready var execute_button: Button = get_node_or_null("SourceDetail/ExecuteBtn")
@onready var cost_label: Label = get_node_or_null("SourceDetail/CostLabel")
@onready var result_feedback: Label = get_node_or_null("FeedbackLabel")
@onready var durability_bar: TextureProgressBar = get_node_or_null("ItemInfo/DurabilityBar")
@onready var soul_status_label: Label = get_node_or_null("ItemInfo/SoulStatus")
@onready var station_label: Label = get_node_or_null("StationIndicator")

# ============ 概率附魂专属 ============
@onready var enchant_spinbox: SpinBox = get_node_or_null("SourceDetail/EnchantSpinbox")
@onready var enchant_hbox: HBoxContainer = get_node_or_null("SourceDetail/EnchantHBox")

# ==================== 数据 ====================
var _selected_slot_index: int = -1
var _selected_item_id: String = ""
var _selected_source: int = -1
var _soul_forge: Node = null

# ==================== 来源展示配置 ====================
const SOURCE_UI: Dictionary = {
	SoulForgeSystem.SoulSource.BLOOD_SACRIFICE: {
		"icon": "🩸",
		"name": "血祭锻造",
		"desc": "以自身精血为引，唤醒器物中沉睡的魂灵。\n条件：HP > 30%\n消耗：扣除 HP 至 10%",
		"chance": "25%",
		"cost": "HP 20%（保底10%）",
		"color": Color(0.9, 0.15, 0.15),
	},
	SoulForgeSystem.SoulSource.BREAKTHROUGH: {
		"icon": "🌀",
		"name": "突破共振",
		"desc": "大境界突破时，天劫之力可能共鸣器物。\n条件：大境界突破时自动触发\n消耗：无",
		"chance": "10%",
		"cost": "无（突破时免费）",
		"color": Color(0.6, 0.2, 1.0),
	},
	SoulForgeSystem.SoulSource.OLD_FRIEND: {
		"icon": "🔥",
		"name": "老伙计",
		"desc": "朝夕相伴的老伙计，在最关键的时刻觉醒！\n条件：耐久耗尽时触发\n消耗：物品本身（70%摧毁风险！）",
		"chance": "5% (觉醒) / 70% (摧毁)",
		"cost": "高风险！用完即碎",
		"color": Color(1.0, 0.85, 0.2),
	},
	SoulForgeSystem.SoulSource.FUSION: {
		"icon": "💫",
		"name": "融合献祭",
		"desc": "以魂晶为引，稳定融合出魂器。\n条件：背包有 3 个魂晶\n消耗：3 魂晶",
		"chance": "100%",
		"cost": "3 × 魂晶",
		"color": Color(0.2, 0.6, 1.0),
	},
	SoulForgeSystem.SoulSource.ENCHANTMENT: {
		"icon": "⚖️",
		"name": "概率附魂",
		"desc": "以混沌之灵沟通天地，赌一把附魂！\n条件：至少 1 个混沌之灵\n消耗：1+ 混沌之灵（每个+5%概率）",
		"chance": "基础8%，每魂+5%",
		"cost": "1~N × 混沌之灵（可调节）",
		"color": Color(0.1, 1.0, 0.8),
	},
}

# ==================== 初始化 ====================

func _ready() -> void:
	_soul_forge = get_node("/root/SoulForgeSystem")
	_build_source_tabs()
	if execute_button != null:
		execute_button.pressed.connect(_on_execute)
	if enchant_spinbox != null:
		enchant_spinbox.value_changed.connect(_on_enchant_amount_changed)
	if enchant_spinbox != null:
		enchant_spinbox.min_value = 1
		enchant_spinbox.max_value = 20
		enchant_spinbox.step = 1
		enchant_spinbox.value = 1
	if enchant_hbox != null:
		enchant_hbox.visible = false  # 默认隐藏，选中附魂时显示

func _build_source_tabs() -> void:
	"""生成 5 个来源标签"""
	if source_tabs == null:
		return
	var sources = [
		SoulForgeSystem.SoulSource.BLOOD_SACRIFICE,
		SoulForgeSystem.SoulSource.BREAKTHROUGH,
		SoulForgeSystem.SoulSource.OLD_FRIEND,
		SoulForgeSystem.SoulSource.FUSION,
		SoulForgeSystem.SoulSource.ENCHANTMENT,
	]
	for src in sources:
		var ui = SOURCE_UI[src]
		var btn = Button.new()
		btn.text = "%s %s" % [ui.icon, ui.name]
		btn.custom_minimum_size = Vector2(100, 36)
		btn.toggle_mode = true
		btn.add_theme_color_override("font_color", ui.color)
		btn.pressed.connect(_on_source_tab_pressed.bind(src))
		source_tabs.add_child(btn)

# ==================== 公共接口 ====================

## 打开面板时调用，传入要锻造的格子索引
func inspect_slot(slot_index: int) -> void:
	_selected_slot_index = slot_index
	_refresh_item_info()
	_select_source(SoulForgeSystem.SoulSource.FUSION)  # 默认选中融合
	visible = true
	result_feedback.text = ""

## 由锻造台交互调用
func open_for_station(slot_index: int) -> void:
	station_label.text = "🔮 魂器锻造台"
	inspect_slot(slot_index)

# ==================== 刷新 ====================

func _refresh_item_info() -> void:
	if _selected_slot_index < 0:
		return
	var inv = get_node("/root/GameManager").inventory
	if not inv:
		return
	
	var slot = inv.get_slot(_selected_slot_index)
	if slot.is_empty() or slot.get("item_id", "").is_empty():
		item_name_label.text = "请选择一件物品"
		execute_button.disabled = true
		return
	
	_selected_item_id = slot.get("item_id", "")
	var item_data = ItemDatabase.get_item(_selected_item_id)
	item_name_label.text = item_data.get("name") or "未知"
	item_category_label.text = _category_to_display(item_data.get("category", -1))
	
	# 魂器状态
	var is_soul = inv.is_soul_marked(_selected_item_id)
	if is_soul:
		var source = slot.get("soul_source", -1)
		var src_name = SoulForgeSystem.SOURCE_NAMES.get(source, "未知")
		soul_status_label.text = "🔮 魂器（%s）" % src_name
		soul_status_label.modulate = SOURCE_UI.get(source, {}).get("color") or Color.WHITE
		execute_button.disabled = true
		execute_button.text = "已是魂器"
	else:
		# 检查是否可锻造
		if SoulForgeSystem.is_item_soul_markable(_selected_item_id):
			soul_status_label.text = "✨ 可锻造"
			soul_status_label.modulate = Color(0.3, 1.0, 0.5)
			execute_button.disabled = false
			execute_button.text = "🔥 执行锻造"
		else:
			soul_status_label.text = "❌ 不可锻造（仅武器/工具/防具/食品/背包）"
			soul_status_label.modulate = Color(1.0, 0.3, 0.3)
			execute_button.disabled = true
			execute_button.text = "❌ 不可锻造"
	
	# 耐久信息
	if is_soul:
		var current = slot.get("soul_durability") or 100
		var max_val = slot.get("soul_durability_max") or 100
		var cooldown = slot.get("soul_cooldown") or 0.0
		durability_bar.value = (current / max_val) * 100.0
		if cooldown > 0:
			durability_bar.modulate = Color(0.4, 0.4, 0.4)
			item_name_label.text += " [冷却 %.1fs]" % cooldown
		else:
			durability_bar.modulate = Color(1, 1, 1)
	else:
		var dur = slot.get("durability", -1)
		if dur >= 0:
			var max_dur = item_data.get("durability") or 1
			durability_bar.value = (dur / max_dur) * 100.0
		else:
			durability_bar.value = 100.0
			durability_bar.modulate = Color(0.5, 0.5, 0.5)

func _refresh_detail() -> void:
	if _selected_source < 0:
		return
	var ui = SOURCE_UI[_selected_source]
	source_name_label.text = "%s %s" % [ui.icon, ui.name]
	source_desc_label.text = ui.desc
	source_chance_label.text = "概率：%s" % ui.chance
	cost_label.text = "消耗：%s" % ui.cost
	source_vfx_preview.color = ui.color
	
	# 显示/隐藏附魂数量调节
	enchant_hbox.visible = (_selected_source == SoulForgeSystem.SoulSource.ENCHANTMENT)
	
	# 特殊处理：融合献祭需要检查魂晶数量
	if _selected_source == SoulForgeSystem.SoulSource.FUSION:
		_update_fusion_cost()
	
	# 特殊处理：附魂实时概率
	if _selected_source == SoulForgeSystem.SoulSource.ENCHANTMENT:
		_update_enchantment_detail()

func _update_fusion_cost() -> void:
	var inv = get_node("/root/GameManager").inventory
	if not inv:
		return
	var count = inv.get_item_count("soul_essence")
	cost_label.text = "消耗：3 魂晶（持有 %d）" % count
	if count < 3:
		cost_label.modulate = Color.RED
		execute_button.disabled = true
	else:
		cost_label.modulate = Color.WHITE
		execute_button.disabled = false

func _update_enchantment_detail() -> void:
	var amount = int(enchant_spinbox.value)
	var base_chance = 0.08
	var per_spirit = 0.05
	var total_chance = min(base_chance + per_spirit * amount, 0.80)
	source_chance_label.text = "概率：%.0f%%（基础8%% + %d×5%%）" % [total_chance * 100, amount]
	
	var inv = get_node("/root/GameManager").inventory
	if inv:
		var held = inv.get_item_count("chaos_essence")
		cost_label.text = "消耗：%d 混沌之灵（持有 %d）" % [amount, held]
		if held < amount:
			cost_label.modulate = Color.RED
			execute_button.disabled = true
		else:
			cost_label.modulate = Color.WHITE
			execute_button.disabled = false

func _on_enchant_amount_changed(value: float) -> void:
	if _selected_source == SoulForgeSystem.SoulSource.ENCHANTMENT:
		_update_enchantment_detail()

# ==================== 交互 ====================

func _on_source_tab_pressed(source: int) -> void:
	_select_source(source)

func _select_source(source: int) -> void:
	_selected_source = source
	_refresh_detail()
	
	# 高亮对应的标签
	for i in range(source_tabs.get_child_count()):
		var btn = source_tabs.get_child(i) as Button
		if btn:
			btn.button_pressed = (i == source)

func _on_execute() -> void:
	if _selected_slot_index < 0 or _selected_source < 0:
		return
	if not _soul_forge:
		return
	
	var success = false
	var source_name = SoulForgeSystem.SOURCE_NAMES.get(_selected_source, "未知")
	
	match _selected_source:
		SoulForgeSystem.SoulSource.BLOOD_SACRIFICE:
			var player = get_node("/root/GameManager/Player")
			success = _soul_forge.try_blood_sacrifice(player, _selected_slot_index)
		
		SoulForgeSystem.SoulSource.FUSION:
			success = _soul_forge.try_fusion_forge(_selected_slot_index)
		
		SoulForgeSystem.SoulSource.ENCHANTMENT:
			var amount = int(enchant_spinbox.value)
			success = _soul_forge.try_enchantment(_selected_slot_index, amount)
		
		SoulForgeSystem.SoulSource.BREAKTHROUGH:
			result_feedback.text = "🌀 突破共振由大境界突破自动触发，无法手动激活"
			return
		
		SoulForgeSystem.SoulSource.OLD_FRIEND:
			result_feedback.text = "🔥 老伙计由耐久耗尽触发，请使用该物品直至耐久归零"
			return
	
	if success:
		result_feedback.text = "✅ 魂器锻造成功！(%s)" % source_name
		result_feedback.modulate = Color(0.3, 1.0, 0.3)
	else:
		result_feedback.text = "❌ 锻造失败，请检查条件"
		result_feedback.modulate = Color(1.0, 0.3, 0.3)
	
	_refresh_item_info()

# ==================== 关闭 ====================

func close_panel() -> void:
	visible = false
	_selected_slot_index = -1
	_selected_item_id = ""
	_selected_source = -1
	station_label.text = ""

# ==================== 工具 ====================

static func _category_to_display(cat: int) -> String:
	match cat:
		ItemDatabase.ItemCategory.WEAPON: return "⚔️ 武器"
		ItemDatabase.ItemCategory.TOOL: return "🔧 工具"
		ItemDatabase.ItemCategory.ARMOR: return "🛡️ 防具"
		ItemDatabase.ItemCategory.CONSUMABLE: return "🍖 食品"
		_: return "📦 其他"
