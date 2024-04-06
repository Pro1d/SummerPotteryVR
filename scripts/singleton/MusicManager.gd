extends Node

enum Volume { LOW=1, HIGH=2 }

#const menu_music := preload("res://assets/musics/last-stand-in-space.ogg")
#const game_music := preload("res://assets/musics/megasong.ogg")

var _vol := Volume.HIGH
var _mute := false
@onready var _player := AudioStreamPlayer.new()
@onready var _music_bus := AudioServer.get_bus_index(&"Music")
@onready var _default_volume_db := AudioServer.get_bus_volume_db(_music_bus)

func _ready() -> void:
	_player.bus = &"Music"
	set_volume(_vol)
	add_child(_player)

func toggle_mute() -> void:
	set_mute(not _mute)
	
func set_mute(m: bool) -> void:
	_mute = m
	AudioServer.set_bus_mute(_music_bus, _mute)

func is_mute() -> bool:
	return _mute

func set_volume(level: Volume) -> void:
	set_mute(false)
	_vol = level
	match level:
		Volume.HIGH:
			AudioServer.set_bus_volume_db(_music_bus, _default_volume_db)
		Volume.LOW:
			AudioServer.set_bus_volume_db(_music_bus, _default_volume_db - 9.0)

func start_menu_music():
	#_player.stream = menu_music
	_player.play()

func start_game_music():
	#_player.stream = game_music
	_player.play()

func stop_music():
	_player.stop()
