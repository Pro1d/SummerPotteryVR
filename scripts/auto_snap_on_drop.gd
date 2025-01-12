class_name AutoSnapOnDrop
extends Node

@export var delay := 4.0  # sec

var _drop_timer := Timer.new()
var _tool : XRToolsPickable

@onready var _snap_zone := get_parent() as XRToolsSnapZone

func _ready() -> void:
	assert(_snap_zone != null)
	
	add_child(_drop_timer)
	_drop_timer.one_shot = true
	_drop_timer.wait_time = delay
	_drop_timer.timeout.connect(_on_tool_lost)
	
	# deferred init (the node snap_zone.initial_object may be not yet init)
	(func() -> void:
		if _snap_zone.initial_object:
			_tool = _snap_zone.get_node(_snap_zone.initial_object) as XRToolsPickable
			_tool.dropped.connect(_drop_timer.start.unbind(1))
			_tool.picked_up.connect(_drop_timer.stop.unbind(1))
	).call_deferred()

func _on_tool_lost() -> void:
	if not _snap_zone.has_snapped_object():
		_snap_zone.pick_up_object(_tool)
