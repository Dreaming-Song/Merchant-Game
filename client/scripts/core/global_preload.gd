@tool
## 全局类型预加载 — @tool 模式确保编译期注册所有 class_name 类型
## 不添加为 Autoload，由主场景或任意脚本引用触发

const _mode = preload("res://scripts/building/building_mode.gd")
const _sys = preload("res://scripts/building/building_system.gd")
const _ghost = preload("res://scripts/building/building_ghost.gd")
const _sfx = preload("res://scripts/building/building_sfx.gd")
const _combat = preload("res://scripts/combat/combat_system.gd")
const _boss = preload("res://scripts/combat/boss_arena_manager.gd")
const _hunger = preload("res://scripts/survival/hunger_system.gd")
const _minimap = preload("res://scripts/ui/minimap.gd")
const _gongfa = preload("res://scripts/cultivation/gongfa_system.gd")
const _stamina = preload("res://scripts/core/stamina_system.gd")
const _crafting = preload("res://scripts/crafting/crafting_system.gd")
const _items = preload("res://scripts/inventory/item_database.gd")
const _skill = preload("res://scripts/combat/skill_manager.gd")
