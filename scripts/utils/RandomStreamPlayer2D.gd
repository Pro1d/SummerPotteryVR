class_name RandomStreamPlayer2D
extends AudioStreamPlayer2D

@export var streams : Array[AudioStream] = []
var prev_sound_index := -1

func play_random() -> void:
	var i := randi_range(0, streams.size() - 1)
	if i == prev_sound_index:
		i = randi_range(0, streams.size() - 1)
	prev_sound_index = i
	stream = streams[i]
	play()
