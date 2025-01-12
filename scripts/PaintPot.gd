@tool
class_name PaintPot
extends Node3D

@export var color := Color.RED :
	set(c):
		if c != color:
			color = c
			update_color()
@onready var paint_mesh := $Paint as MeshInstance3D

func _ready() -> void:
	update_color()

func update_color() -> void:
	if paint_mesh == null: return
	var mat := paint_mesh.get_surface_override_material(0) as StandardMaterial3D
	mat.albedo_color = color
	paint_mesh.set_surface_override_material(0, mat)

static func find_parent_paint_pot(body: Area3D) -> PaintPot:
	return (body.get_parent() as PaintPot) if body != null else null
