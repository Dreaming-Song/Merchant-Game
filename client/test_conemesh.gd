extends RefCounted
func _init():
	print("ConeMesh exists: ", ClassDB.class_exists("ConeMesh"))
	print("CylinderMesh exists: ", ClassDB.class_exists("CylinderMesh"))
	print("BoxMesh exists: ", ClassDB.class_exists("BoxMesh"))
