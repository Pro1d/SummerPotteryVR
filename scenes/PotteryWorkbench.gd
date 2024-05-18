@tool
class_name PotteryWorkBench
extends Node3D

@onready var spinning_node := $Spinning as Node3D
@onready var spinning_audio := $WoodSpinningAudio as AudioStreamPlayer3D
@onready var body_plate := %PlateBody as StaticBody3D
const max_rotation_speed := 2 * PI * 1.0
const rotation_accel := max_rotation_speed / 2
var rotation_speed := 0.0
@export var motor_on := false

func _process(delta: float) -> void:
	var accel := rotation_accel if motor_on else -rotation_accel
	rotation_speed = clampf(rotation_speed + accel * delta, 0.0, max_rotation_speed)
	spinning_node.rotation.y = wrapf(spinning_node.rotation.y + rotation_speed * delta, 0, 2 * PI)
	spinning_audio.volume_db = log(remap(rotation_speed, 0.0, max_rotation_speed, 0.01, 1.0)) * 10
	body_plate.constant_angular_velocity.y = spinning_node.rotation.y
	
func is_rotating() -> bool:
	return is_equal_approx(rotation_speed, max_rotation_speed)

func _on_power_button_pressed(_button: Variant) -> void:
	($Node3D/InteractableAreaButton/ButtonAudio as AudioStreamPlayer3D).play()
	motor_on = not motor_on
	spinning_audio.playing = motor_on
