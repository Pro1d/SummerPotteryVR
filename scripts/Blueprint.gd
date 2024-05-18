@tool
extends Node3D

@export var texture : Texture2D :
	set(t):
		if texture != t:
			texture = t
			update_texture()

func _ready() -> void:
	update_texture()

func update_texture() -> void:
	var mesh := $Blueprint as MeshInstance3D
	var mat := mesh.get_surface_override_material(0).duplicate() as StandardMaterial3D
	mat.albedo_texture = texture
	mesh.set_surface_override_material(0, mat)
