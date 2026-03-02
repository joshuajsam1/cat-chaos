extends Node3D

# ---------------------------------------------------------------------------
# HouseVisuals — applies procedural materials to house meshes at startup
# ---------------------------------------------------------------------------

func _ready() -> void:
	_apply_material("Floor/MeshInstance3D",     Color(0.72, 0.60, 0.45))  # warm wood
	_apply_material("WallNorth/MeshInstance3D", Color(0.88, 0.84, 0.76))  # off-white
	_apply_material("WallSouth/MeshInstance3D", Color(0.88, 0.84, 0.76))
	_apply_material("WallEast/MeshInstance3D",  Color(0.85, 0.80, 0.70))
	_apply_material("WallWest/MeshInstance3D",  Color(0.85, 0.80, 0.70))
	_apply_material("Sofa/MeshInstance3D",      Color(0.25, 0.45, 0.70))  # blue sofa
	_apply_material("KitchenTable/MeshInstance3D", Color(0.50, 0.32, 0.18))  # brown table

func _apply_material(node_path: String, color: Color) -> void:
	var node := get_node_or_null(node_path) as MeshInstance3D
	if not node:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	node.material_override = mat
