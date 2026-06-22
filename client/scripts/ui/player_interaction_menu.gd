extends PopupMenu
## 玩家交互菜单 — 右键/靠近其他玩家时弹出
##
## 选项：交易、组队邀请、关注、表情互动

class_name PlayerInteractionMenu

signal action_selected(target_player_id: String, action: String)

var _target_player_id: String = ""

func _ready() -> void:
	hide()
	
	# 构建菜单
	add_icon_item(null, "🤝 交易请求", 0)
	add_icon_item(null, "👥 组队邀请", 1)
	add_icon_item(null, "👋 挥手", 2)
	add_icon_item(null, "🙏 作揖", 3)
	add_icon_item(null, "💃 跳舞", 4)
	add_separator()
	add_icon_item(null, "📋 查看信息", 5)
	add_icon_item(null, "🚫 屏蔽玩家", 6)
	
	# 连接选择
	id_pressed.connect(_on_item_selected)

func show_for_player(player_id: String, screen_pos: Vector2) -> void:
	"""在屏幕位置显示交互菜单"""
	_target_player_id = player_id
	position = screen_pos
	popup()
	grab_focus()

func _on_item_selected(id: int) -> void:
	"""菜单项被选择"""
	var actions = ["trade", "party_invite", "emote_wave", "emote_bow", "emote_dance", "inspect", "block"]
	if id >= 0 and id < actions.size():
		action_selected.emit(_target_player_id, actions[id])
	hide()
