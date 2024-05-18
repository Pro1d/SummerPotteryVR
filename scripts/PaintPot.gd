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
	var mat := paint_mesh.mesh.surface_get_material(0).duplicate() as StandardMaterial3D
	mat.albedo_color = color
	paint_mesh.set_surface_override_material(0, mat)
