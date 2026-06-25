extends Node

func _ready() -> void:
	print("\n========== DamageCalculator 测试开始 ==========\n")
	
	# Load calculator
	var DamageCalc = load("res://scripts/combat/damage_calculator.gd")
	print("  ✅ 加载 damage_calculator.gd 成功")
	
	var passed = 0
	var failed = 0
	
	# Test 1: basic damage
	var r = DamageCalc.calculate_damage({"attack": 100}, {"defense": 0}, {})
	assert(r.damage > 0, "damage > 0")
	print("  ✅ 基础伤害: %d" % r.damage)
	passed += 1
	
	# Test 2: defense reduction
	var r2 = DamageCalc.calculate_damage({"attack": 100}, {"defense": 100}, {})
	assert(r2.damage < r.damage, "defense reduces damage")
	print("  ✅ 防御减免: def=0->%d, def=100->%d" % [r.damage, r2.damage])
	passed += 1
	
	# Test 3: crit rate
	var crits = 0
	for i in range(200):
		var rr = DamageCalc.calculate_damage({"attack": 50, "crit_rate": 0.8, "crit_damage": 2.0}, {"defense": 0}, {})
		if rr.is_crit: crits += 1
	assert(crits > 100, "high crit rate works")
	print("  ✅ 暴击率: %d/200 = %.1f%%" % [crits, crits/2.0])
	passed += 1
	
	# Test 4: element counter (金 counters 木)
	var r3 = DamageCalc.calculate_damage({"attack": 100}, {"defense": 0, "element": "木"}, {"element": "金"})
	assert(r3.element_mult == 1.5, "gold beats wood")
	print("  ✅ 五行克制: 金→木 = x%.1f" % r3.element_mult)
	passed += 1
	
	# Test 5: element resist (金 is countered by 火)
	var r4 = DamageCalc.calculate_damage({"attack": 100}, {"defense": 0, "element": "火"}, {"element": "金"})
	assert(r4.element_mult == 0.67, "gold loses to fire")
	print("  ✅ 五行被克: 金←火 = x%.2f" % r4.element_mult)
	passed += 1
	
	# Test 6: healing
	var heal = DamageCalc.calculate_healing({"attack": 100, "heal_bonus": 0.2}, {"incoming_heal_bonus": 0.1}, {"effects": {"heal_mult": 2.0}})
	assert(heal > 200, "heal is reasonable")
	print("  ✅ 治疗量: %d" % heal)
	passed += 1
	
	# Test 7: shield
	var shield = DamageCalc.calculate_shield({"attack": 100}, {"effects": {"shield_mult": 3.0}})
	assert(shield == 300, "shield = 300")
	print("  ✅ 护盾量: %d" % shield)
	passed += 1
	
	# Test 8: guaranteed crit
	var r5 = DamageCalc.calculate_damage({"attack": 50, "crit_rate": 0.0}, {"defense": 0}, {"effects": {"crit_guarantee": true}})
	assert(r5.is_crit, "guaranteed crit")
	print("  ✅ 必定暴击")
	passed += 1
	
	# Test 9: damage multiplier
	var r6 = DamageCalc.calculate_damage({"attack": 100}, {"defense": 0}, {"damage_mult": 3.0})
	assert(r6.damage >= 250, "mult works")
	print("  ✅ 技能倍率 x3.0: %d" % r6.damage)
	passed += 1
	
	# Summary
	print("\n----------")
	print("结果: %d 通过, %d 失败" % [passed, failed])
	
	get_tree().quit(0 if failed == 0 else 1)
