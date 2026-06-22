extends Node
## NPC对话数据仓库 — 集中管理所有NPC的对话树
##
## 供 NPCBase 在 _ready 时引用
## 按 region_area 或 npc_id 分类

class_name NPCDialogueDB

# ==================== 新手村 NPC ====================

static func get_mentor_dialogue() -> Dictionary:
	return {
		"start_node": "greeting",
		"nodes": {
			"greeting": {
				"text": "你终于来了，孩子。灵脉异动，妖兽四起，这片大陆需要新的守护者。",
				"options": [
					{"text": "师父，请指点迷津", "next": "guidance"},
					{"text": "我准备好了！", "next": "ready_check"},
					{"text": "我再想想（离开）", "next": "_end"}
				]
			},
			"guidance": {
				"text": "先去灵药谷采集5株灵草练练手，再到后山击败一只妖兽。完成这些，你就算入门了。",
				"options": [
					{"text": "好，我这就去！", "next": "quest_offer"},
					{"text": "还有其他事吗？", "next": "tips"}
				]
			},
			"tips": {
				"text": "按 E 交互、I 打开背包、C 修行、B 建造。遇到困难按 H 查看帮助。",
				"options": [
					{"text": "接任务", "next": "quest_offer"},
					{"text": "记住了", "next": "_end"}
				]
			},
			"quest_offer": {
				"text": "很好！去灵药谷历练一番吧。",
				"options": [
					{"text": "📋 接取任务「初入灵境」", "next": "_end", "quest_start": "quest_first_steps"},
					{"text": "等一下再接", "next": "_end"}
				]
			},
			"ready_check": {
				"text": "让我看看你的修为……嗯，还差得远。先去灵药谷历练吧！",
				"options": [
					{"text": "是，师父", "next": "_end"}
				]
			}
		}
	}

static func get_pet_master_dialogue() -> Dictionary:
	return {
		"start_node": "greeting",
		"nodes": {
			"greeting": {
				"text": "嚯，新面孔啊！想选一只灵宠作伴吗？",
				"options": [
					{"text": "是的，请让我看看", "next": "show_pets", "quest_start": "quest_get_pet"},
					{"text": "我只是看看", "next": "browse"},
					{"text": "下次再说", "next": "_end"}
				]
			},
			"show_pets": {
				"text": "这有火凤、冰鸾、雷鹏三只幼崽，都是百年难得一遇的好资质！选一只吧。",
				"options": [
					{"text": "🔥 火凤（攻击型）", "next": "choose_fire"},
					{"text": "❄️ 冰鸾（辅助型）", "next": "choose_ice"},
					{"text": "⚡ 雷鹏（速度型）", "next": "choose_thunder"},
					{"text": "我再想想", "next": "_end"}
				]
			},
			"choose_fire": {
				"text": "好眼光！火凤属火，攻击力极强，带上它去历练吧！",
				"options": [{"text": "谢谢大师！", "next": "_end", "action": "open_pet_menu"}]
			},
			"choose_ice": {
				"text": "冰鸾性情温和，擅长治疗和辅助，是可靠的伙伴。",
				"options": [{"text": "谢谢大师！", "next": "_end", "action": "open_pet_menu"}]
			},
			"choose_thunder": {
				"text": "雷鹏速度极快，御剑飞行时带上它能日行千里！",
				"options": [{"text": "谢谢大师！", "next": "_end", "action": "open_pet_menu"}]
			},
			"browse": {
				"text": "随便看，这些灵宠可都是我的心血。",
				"options": [
					{"text": "那我选一只", "next": "show_pets"},
					{"text": "先走了", "next": "_end"}
				]
			}
		}
	}

static func get_herbalist_dialogue() -> Dictionary:
	return {
		"start_node": "greeting",
		"nodes": {
			"greeting": {
				"text": "采药归来？让我看看你的收获……",
				"options": [
					{"text": "✅ 交付「采集灵草」任务", "next": "complete_quest", "condition": "quest_active:quest_herb"},
					{"text": "我想学炼丹", "next": "alchemy"},
					{"text": "帮我治疗", "next": "heal"},
					{"text": "路过的", "next": "_end"}
				]
			},
			"complete_quest": {
				"text": "不错不错，这些灵草品质上佳！这是给你的报酬。",
				"options": [{"text": "谢谢药师", "next": "_end", "quest_complete": "quest_herb", "action": "heal_player"}]
			},
			"alchemy": {
				"text": "炼丹需要灵草和丹炉，你的修行境界到了炼气期才能学习。",
				"options": [
					{"text": "我已经到了！", "next": "teach", "condition": "realm:2"},
					{"text": "那下次再来", "next": "_end"}
				]
			},
			"teach": {
				"text": "好，我教你基础丹方。打开合成台（TAB），选择「丹药」分类即可。",
				"options": [{"text": "明白了！", "next": "_end", "action": "open_crafting"}]
			},
			"heal": {
				"text": "让我为你调息……好了，你感觉如何？",
				"options": [{"text": "满血复活！", "next": "_end", "action": "heal_player"}]
			}
		}
	}
