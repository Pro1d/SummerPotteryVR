extends Node3D

@onready var music_player := $Music as AudioStreamPlayer3D
#@onready var noise_player := $WhiteNoise as AudioStreamPlayer3D
var on := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music_player.play()
	#noise_player.play()
	#_run_random_noise()

#func _run_random_noise() -> void:
	#var default_noise_db := noise_player.volume_db
	#var default_music_db := music_player.volume_db
	#while true:
		#var tween := create_tween()
		#var delta_db := randf_range(5, 15)
		#tween.tween_property(noise_player, "volume_db", default_noise_db + delta_db, 1.0).from(default_noise_db)
		#tween.parallel().tween_property(music_player, "volume_db", default_music_db - delta_db*2, 1.0).from(default_music_db)
		#tween.tween_interval(randf_range(1.0, 2.0))
		#tween.tween_property(noise_player, "volume_db", default_noise_db, 0.3)
		#tween.parallel().tween_property(music_player, "volume_db", default_music_db, 0.3)
		#tween.tween_interval(randf_range(3.0, 8.0))
		#tween.play()
		#await tween.finished
		#tween.kill()


func _on_power_button_pressed(_button: Variant) -> void:
	($InteractableAreaButton/ButtonAudio as AudioStreamPlayer3D).play()
	on = not on
	music_player.volume_db = 0.0 if on else -100.0
	#noise_player.playing = not noise_player.playing
