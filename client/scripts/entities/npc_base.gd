extends CharacterBody3D
## NPC基础类 — 可交互对话角色
##
## 使用方法：
##   1. 挂载到任意 CharacterBody3D 或 StaticBody3D
##   2. 在编辑器中设置 display_name 和 dialogue_data
##   3. 脚本自动加入 "npc" 组
##   4. InteractionDetector 自动识别并触发对话

class_name NPCBase

# ==================== 编辑器中可配置 ====================
@export var display_name: String = "村民"
@export var npc_title: String = ""  # 头衔（如"灵药谷药童"）
@export var greeting_text: String = "你好，旅者！"
@export var dialogue_data: Dictionary = {}  # 对话树数据
@export var portrait_path: String = ""  # 头像路径（可选）
@export var auto_talk: bool = false  # 靠近自动触发对话（不需要按E）

# ==================== 状态 ====================
var is_talking: bool = false

func _ready() -> void:
	add_to_group("npc")
	
	# 如果没有自定义对话，生成默认对话
	if dialogue_data.is_empty():
		_generate_default_dialogue()

func _generate_default_dialogue() -> void:
	dialogue_data = {
		"start_node": "greeting",
		"nodes": {
			"greeting": {
				"text": greeting_text,
				"options": [
					{"text": "你是谁？", "next": "who"},
					{"text": "这里有什么任务吗？", "next": "quest"},
					{"text": "再见", "next": "_end"}
				]
			},
			"who": {
				"text": "我是%s%s，在这片大陆上游历。你有何需要帮助的？" % [display_name, "（%s）" % npc_title if not npc_title.is_empty() else ""],
				"options": [
					{"text": "有任务给我吗？", "next": "quest"},
					{"text": "没事了", "next": "_end"}
				]
			},
			"quest": {
				"text": "目前还没有适合你的任务，多探索这个世界吧！",
				"options": [
					{"text": "好的，那我走了", "next": "_end"}
				]
			}
		}
	}

# ==================== 交互接口 ====================

## 供 InteractionDetector 调用
func interact(player: Node) -> void:
	"""与 NPC 交互"""
	var ui = get_node("/root/UIManager") if has_node("/root/UIManager") else null
	if ui and ui.has_method("open_dialogue"):
		ui.open_dialogue(self)

## 供 DialoguePanel 获取对话数据
func get_dialogue() -> Dictionary:
	return dialogue_data.duplicate(true)

## 供 HUD 显示
func get_hint_name() -> String:
	if not npc_title.is_empty():
		return "%s (%s)" % [display_name, npc_title]
	return display_name

# ==================== 附加功能 ====================

## 面向玩家
func face_player(player_pos: Vector3) -> void:
	look_at(Vector3(player_pos.x, global_position.y, player_pos.z), Vector3.UP)

## 随机移动（巡逻用）
func patrol_random() -> void:
	var target = global_position + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
	var dir = (target - global_position).normalized()
	velocity = dir * 1.5
	move_and_slide()
