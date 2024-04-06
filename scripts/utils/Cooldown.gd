class_name Cooldown
extends Node

signal charges_changed(charges, max_charges)
signal activated()
signal terminated()

@export var max_charges := 3
@export var active_duration := 1.0 : set=set_active_duration
@export var cooldown_duration := 5.0 : set=set_cooldown_duration

var charges : int

@onready var _cooldown_timer := $CooldownTimer as Timer
@onready var _active_timer := $ActiveTimer as Timer

func _ready() -> void:
	_active_timer.wait_time = active_duration
	_cooldown_timer.wait_time = cooldown_duration
	_active_timer.timeout.connect(_on_active_timeout)
	_cooldown_timer.timeout.connect(_on_cooldown_timeout)

func set_active_duration(d : float) -> void:
	active_duration = d
	_active_timer.wait_time = active_duration

func set_cooldown_duration(d : float) -> void:
	cooldown_duration = d
	_cooldown_timer.wait_time = cooldown_duration

func reset(initial_charges: int = 1) -> void:
	charges = initial_charges
	charges_changed.emit(charges, max_charges)
	_active_timer.stop()
	_cooldown_timer.stop()
	if charges < max_charges:
		_cooldown_timer.start()

func is_activable() -> bool:
	return charges >= 1 and _active_timer.time_left <= 0

func activate() -> void:
	if is_activable():
		charges -= 1
		charges_changed.emit(charges, max_charges)
		
		if _active_timer.wait_time > 0:
			_active_timer.start()
		activated.emit()
		
		if _cooldown_timer.time_left <= 0:
			_cooldown_timer.start()

func get_remaining_cooldown_duration() -> float:
	return _cooldown_timer.time_left

func get_cooldown_duration() -> float:
	return _cooldown_timer.wait_time

func is_cooling_down() -> bool:
	return _cooldown_timer.time_left > 0

func get_remaining_active_duration() -> float:
	return _active_timer.time_left

func get_active_duration() -> float:
	return _active_timer.wait_time

func is_active() -> bool:
	return _active_timer.time_left > 0

func _on_cooldown_timeout() -> void:
	charges += 1
	charges_changed.emit(charges, max_charges)
	if charges < max_charges:
		_cooldown_timer.start()

func _on_active_timeout() -> void:
	terminated.emit()
