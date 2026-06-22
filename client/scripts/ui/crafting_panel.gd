extends Control
## 合成面板 — DST/Terraria风格
##
## 靠近工作站时自动显示该站可合成配方
## 没有工作站时只显示徒手配方

class_name CraftingPanel

# ==================== 布局节点 ====================
@onready var station_indicator: Label = $StationIndicator
@onready var category_tabs: HBoxContainer = $CategoryTabs
@onready var recipe_grid: GridContainer = $RecipeGrid
@onready var recipe_detail: Control = $RecipeDetail
@onready var craft_button: Button = $RecipeDetail/CraftButton
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var progress_label: Label = $ProgressLabel
@onready var material_container: VBoxContainer = $RecipeDetail/MaterialList
@onready var result_icon: TextureRect = $RecipeDetail/ResultIcon
@onready var result_name: Label = $RecipeDetail/ResultName

# ==================== 数据 ====================
var _crafting_system: Node = null
var _selected_recipe: String = ""
var _current_recipes: Array[Dictionary] = []
var _current_category: String = "all"
var _station_filter: String = ""  # 当前聚焦的工作站

# ==================== 配方图标（简化：用颜色方块代替） ====================
const CATEGORY_ICONS: Dictionary = {
	"all":       "📋",
	"tool":      "🔧",
	"weapon":    "⚔️",
	"armor":     "🛡️",
	"building":  "🏗️",
	"furniture": "🪑",
	"storage":   "📦",
	"utility":   "🔥",
	"consumable": "🧪",
	"material":  "⛏️",
	"station":   "🔬",
	"food":      "🍖",
	"potion":    "🧴",
}

const CATEGORY_DISPLAY: Dictionary = {
	"all":       "全部",
	"tool":      "工具",
	"weapon":    "武器",
	"armor":     "防具",
	"building":  "建筑",
	"furniture": "家具",
	"storage":   "存储",
	"utility":   "杂项",
	"consumable": "消耗品",
	"material":  "材料",
	"station":   "工作站",
	"food":      "食物",
	"potion":    "丹药",
}

# ==================== 初始化 ====================
func _ready() -> void:
	_crafting_system = get_node("/root/GameManager/CraftingSystem") if has_node("/root/GameManager/CraftingSystem") else null
	if not _crafting_system:
		_crafting_system = get_node("/root/CraftingSystem")
	
	# 连接按钮
	if craft_button:
		craft_button.pressed.connect(_on_craft_pressed)
	
	# 初始隐藏进度条
	if progress_bar:
		progress_bar.visible = false
	if progress_label:
		progress_label.visible = false
	
	# 连接合成信号
	if _crafting_system:
		_crafting_system.crafting_progress.connect(_on_crafting_progress)
		_crafting_system.crafting_completed.connect(_on_crafting_completed)

# ==================== 刷新面板 ====================

func refresh(station_filter: String = "") -> void:
	"""刷新合成面板，可选过滤到指定工作站"""
	_station_filter = station_filter
	_refresh_station_indicator()
	_refresh_category_tabs()
	_refresh_recipes()
	_clear_detail()

func _refresh_station_indicator() -> void:
	"""显示当前附近的工作站"""
	if not _crafting_system:
		if station_indicator:
			station_indicator.text = "⚠️ 合成系统未加载"
		return
	
	var nearby = _crafting_system.get_nearby_stations()
	var text = ""
	
	if _station_filter and not _station_filter.is_empty():
		text = "📍 %s" % _station_filter
	elif nearby.size() > 0:
		text = "📍 附近: " + " + ".join(nearby)
		# 如果有多个工作站，默认用第一个
		if not _station_filter:
			_station_filter = nearby[0]
	else:
		text = "✋ 徒手合成（附近无工作站）"
		_station_filter = ""
	
	if station_indicator:
		station_indicator.text = text

func _refresh_category_tabs() -> void:
	"""刷新分类标签"""
	if not category_tabs:
		return
	
	# 清空现有标签
	for child in category_tabs.get_children():
		child.queue_free()
	
	# 获取当前可用配方中的所有分类
	var recipes = _get_filtered_recipes()
	var categories: Array[String] = ["all"]
	for r in recipes:
		var cat = r.get("category", r.data.get("category", "material"))
		if cat not in categories:
			categories.append(cat)
	
	# 创建标签按钮
	for cat in categories:
		var btn = Button.new()
		var icon = CATEGORY_ICONS.get(cat, "📦")
		var name = CATEGORY_DISPLAY.get(cat, cat)
		btn.text = "%s %s" % [icon, name]
		btn.toggle_mode = true
		btn.button_pressed = (cat == _current_category)
		btn.pressed.connect(_on_category_selected.bind(cat))
		category_tabs.add_child(btn)

func _refresh_recipes() -> void:
	"""刷新配方网格"""
	if not recipe_grid:
		return
	
	# 清空
	for child in recipe_grid.get_children():
		child.queue_free()
	
	var recipes = _get_filtered_recipes()
	_current_recipes = recipes
	
	# 过滤分类
	if _current_category != "all":
		recipes = recipes.filter(func(r): return r.get("category", r.data.get("category", "")) == _current_category)
	
	if recipes.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "  暂无可用配方"
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.modulate = Color(0.6, 0.6, 0.6)
		recipe_grid.add_child(empty_label)
		return
	
	# 创建配方格子（DST风格小图标）
	for recipe in recipes:
		var btn = _create_recipe_slot(recipe)
		recipe_grid.add_child(btn)

func _create_recipe_slot(recipe: Dictionary) -> Button:
	"""创建单个配方格子（DST风格：图标+名称+材料）"""
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(120, 100)
	btn.flat = false
	
	# 垂直布局
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var r = recipe.data if recipe.has("data") else recipe
	var rid = recipe.id if recipe.has("id") else recipe.get("rid", "")
	
	# 图标（用Emoji代替）
	var icon = CATEGORY_ICONS.get(r.get("category", ""), "📦")
	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(icon_label)
	
	# 名称
	var name_label = Label.new()
	name_label.text = r.get("name", "未知")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)
	
	# 材料需求（小字）
	var mat_text = _get_materials_summary(r.get("materials", {}))
	var mat_label = Label.new()
	mat_label.text = mat_text
	mat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mat_label.add_theme_font_size_override("font_size", 8)
	mat_label.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(mat_label)
	
	# 可合成标记
	var can_craft = _can_craft_materials(r)
	if can_craft:
		btn.modulate = Color(1, 1, 1)
	else:
		btn.modulate = Color(0.5, 0.5, 0.5)
	
	btn.add_child(vbox)
	btn.pressed.connect(_on_recipe_selected.bind(rid, recipe))
	
	return btn

# ==================== 详情面板 ====================

func _on_recipe_selected(recipe_id: String, recipe: Dictionary) -> void:
	"""选中配方，显示详情"""
	_selected_recipe = recipe_id
	
	if not recipe_detail:
		return
	
	recipe_detail.visible = true
	
	var r = recipe.get("data", recipe)
	
	# 显示名称
	if result_name:
		result_name.text = r.get("name", "未知")
	
	# 显示材料
	if material_container:
		for child in material_container.get_children():
			child.queue_free()
		
		var mats = r.get("materials", {})
		for mat_id in mats.keys():
			var needed = mats[mat_id]
			var has = _get_item_count(mat_id)
			var hbox = HBoxContainer.new()
			
			var icon = CATEGORY_ICONS.get(r.get("category", ""), "📦")
			var mat_name_label = Label.new()
			mat_name_label.text = "%s %s" % [icon, mat_id]
			mat_name_label.custom_minimum_size = Vector2(120, 0)
			mat_name_label.add_theme_font_size_override("font_size", 13)
			hbox.add_child(mat_name_label)
			
			var count_label = Label.new()
			count_label.text = " %d / %d" % [has, needed]
			count_label.add_theme_font_size_override("font_size", 13)
			if has >= needed:
				count_label.modulate = Color(0.3, 1.0, 0.3)  # 绿色：足够
			else:
				count_label.modulate = Color(1.0, 0.3, 0.3)  # 红色：不足
			hbox.add_child(count_label)
			
			material_container.add_child(hbox)
	
	# 更新合成按钮状态
	if craft_button:
		var can_craft = _can_craft_materials(r)
		craft_button.disabled = not can_craft
		craft_button.text = "⚒️ 合成" if can_craft else "❌ 材料不足"

func _on_craft_pressed() -> void:
	"""点击合成按钮"""
	if _selected_recipe.is_empty() or not _crafting_system:
		return
	
	var result = _crafting_system.craft(_selected_recipe, 1)
	if result.get("success", false):
		# 显示进度条
		if progress_bar:
			progress_bar.visible = true
			progress_bar.value = 0
		if progress_label:
			progress_label.visible = true
			progress_label.text = "合成中..."
		craft_button.disabled = true
		craft_button.text = "⏳ 合成中"
	else:
		print("⚠️ 合成失败: %s" % result.get("reason", "未知原因"))

func _clear_detail() -> void:
	if recipe_detail:
		recipe_detail.visible = false
	_selected_recipe = ""

# ==================== 进度回调 ====================

func _on_crafting_progress(recipe_id: String, progress: float) -> void:
	if recipe_id != _selected_recipe:
		return
	if progress_bar:
		progress_bar.visible = true
		progress_bar.value = progress * 100.0
	if progress_label:
		progress_label.text = "合成中... %d%%" % int(progress * 100.0)

func _on_crafting_completed(recipe_id: String) -> void:
	if recipe_id != _selected_recipe:
		return
	if progress_bar:
		progress_bar.visible = false
	if progress_label:
		progress_label.visible = false
	if craft_button:
		craft_button.disabled = false
		craft_button.text = "⚒️ 合成"
	
	# 刷新面板
	refresh(_station_filter)

func _on_crafting_cancelled(recipe_id: String) -> void:
	if recipe_id != _selected_recipe:
		return
	if progress_bar:
		progress_bar.visible = false
	if progress_label:
		progress_label.visible = false
	if craft_button:
		craft_button.disabled = false
		craft_button.text = "⚒️ 合成"

# ==================== 分类切换 ====================

func _on_category_selected(category: String) -> void:
	_current_category = category
	# 更新所有标签状态
	for child in category_tabs.get_children():
		if child is Button:
			child.button_pressed = (child.text.contains(CATEGORY_DISPLAY.get(category, category)) or 
				child.text.contains(CATEGORY_ICONS.get(category, "")))
	
	_refresh_recipes()
	_clear_detail()

# ==================== 数据获取 ====================

func _get_filtered_recipes() -> Array[Dictionary]:
	"""获取当前可用的配方列表（按工作站过滤）"""
	if not _crafting_system:
		return []
	
	# 优先使用工作站过滤
	if _station_filter and not _station_filter.is_empty():
		return _crafting_system.get_station_recipes(_station_filter)
	
	# 否则获取全部可用配方
	var all_recipes = _crafting_system.get_available_recipes()
	var result: Array[Dictionary] = []
	
	# all_recipes 是按工作站分组的 Dictionary
	for station in all_recipes.keys():
		for r in all_recipes[station]:
			r["_station"] = station
			result.append(r)
	
	return result

func _can_craft_materials(recipe: Dictionary) -> bool:
	"""检查材料是否足够"""
	if not _crafting_system:
		return false
	
	# 假设 CraftingSystem 有 check_materials 方法
	if _crafting_system.has_method("_check_materials"):
		return _crafting_system._check_materials(recipe)
	
	# 没有就直接检查材料
	var mats = recipe.get("materials", {})
	for mat_id in mats.keys():
		var needed = mats[mat_id]
		if _get_item_count(mat_id) < needed:
			return false
	return true

func _get_item_count(item_id: String) -> int:
	"""获取背包中物品数量"""
	var gm = get_node("/root/GameManager")
	if not gm:
		return 0
	if gm.has_method("get_inventory"):
		var inv = gm.get_inventory()
		if inv and inv.has_method("get_item_count"):
			return inv.get_item_count(item_id)
	return 0

func _get_materials_summary(materials: Dictionary) -> String:
	"""材料概要（小字显示）"""
	if materials.size() == 0:
		return ""
	var parts: Array[String] = []
	for mat_id in materials.keys():
		parts.append("%s×%d" % [mat_id, materials[mat_id]])
	return " ".join(parts)
