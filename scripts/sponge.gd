class_name Sponge
extends XRToolsPickable

@onready var sponge_shader := (%DeformableMesh as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial

var strength := 0.0 :
	set(s):
		strength = s
		_update_deform()

func _process(delta: float) -> void:
	var target_strength := 0.0
	
	var sponge_controller := get_picked_up_by_controller()
	if is_picked_up() and sponge_controller != null:
		target_strength = remap(sponge_controller.get_float("trigger"), 0, 1, 0.0, 1.0) ** 2.0
	
	strength = move_toward(strength, target_strength, delta * (1.0 / 0.1))
	
func _update_deform() -> void:
	sponge_shader.set_shader_parameter("deform_ratio", 1.0 - strength)
