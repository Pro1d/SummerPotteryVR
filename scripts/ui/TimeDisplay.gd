class_name TimeDisplay
extends HBoxContainer

var get_time_func : Callable
@onready var _minutes_label := $MinuteLabel as Label
@onready var _second1_label := $Second1Label as Label
@onready var _second2_label := $Second2Label as Label
@onready var _centi1_label := $Centi1Label as Label
@onready var _centi2_label := $Centi2Label as Label

func _ready() -> void:
	var minimum_size := Vector2i(maxi(maxi(maxi(maxi(
		_minutes_label.size.x,
		_second1_label.size.x),
		_second2_label.size.x),
		_centi1_label.size.x),
		_centi2_label.size.x),
		0
	)
	_minutes_label.custom_minimum_size = minimum_size
	_second1_label.custom_minimum_size = minimum_size
	_second2_label.custom_minimum_size = minimum_size
	_centi1_label.custom_minimum_size = minimum_size
	_centi2_label.custom_minimum_size = minimum_size

func _process(_delta: float) -> void:
	if get_time_func.is_null():
		return
	var time : float = get_time_func.call()
	set_time(time)

func set_time(time: float) -> void:
	var minutes := int(time / 60)
	var sec := int(time) % 60
	var centi := roundi(time * 100) % 100
	_minutes_label.text = str(minutes)
	_second1_label.text = str(int(sec / 10))
	_second2_label.text = str(int(sec) % 10)
	_centi1_label.text = str(int(centi / 10))
	_centi2_label.text = str(int(centi) % 10)
	
static func format_time(time: float) -> String:
	var minutes := int(time / 60)
	var sec := int(time) % 60
	var centi := roundi(time * 100) % 100
	return "%d:%02d.%02d" % [minutes, sec, centi]
