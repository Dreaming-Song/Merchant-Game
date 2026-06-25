extends Node
## 类型预加载器 — 强制 Godot 在编译期注册所有 class_name 类型
##
## 解决 Godot 4 --headless 模式下 class_name 类型未在编译期注册的问题。
## 不依赖任何节点，仅通过 preload 触发文件编译，注册类型到全局作用域。

const _init_building_mode = preload("res://scripts/building/building_mode.gd")
const _init_building_system = preload("res://scripts/building/building_system.gd")
const _init_combat_system = preload("res://scripts/combat/combat_system.gd")
const _init_boss_arena = preload("res://scripts/combat/boss_arena_manager.gd")
const _init_minimap = preload("res://scripts/ui/minimap.gd")
const _init_hunger = preload("res://scripts/survival/hunger_system.gd")
const _init_items = preload("res://scripts/inventory/item_database.gd")
