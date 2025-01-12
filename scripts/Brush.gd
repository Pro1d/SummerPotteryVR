class_name Brush
extends XRToolsPickable


var current_color := Color.TRANSPARENT :
	set(c):
		if c != current_color:
			current_color = c
			update_color()
@onready var tool_area := $ToolPos as Area3D
@onready var hair_mesh := %ColoredEnd as MeshInstance3D
@onready var _splash_audio := %SplashAudio as AudioStreamPlayer3D


func _ready() -> void:
	super()
	tool_area.area_entered.connect(
		func(paint_pot_area: Area3D) -> void:
			var paint_pot := PaintPot.find_parent_paint_pot(paint_pot_area)
			if paint_pot != null:
				current_color = paint_pot.color
				_splash_audio.play()
	)

func update_color() -> void:
	if hair_mesh == null: return
	var mat := hair_mesh.get_surface_override_material(0) as StandardMaterial3D
	mat.albedo_color = current_color

func get_tool_pos() -> Vector3:
	return tool_area.global_position
