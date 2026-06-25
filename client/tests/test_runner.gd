extends SceneTree

func _initialize():
	var test = load("res://scripts/combat/combat_unit_test.gd").new()
	root.add_child(test)
