extends Node3D

@onready var sponge := %Sponge as XRToolsPickable
@onready var brush := %Brush as Brush
@onready var workbench := %PotteryWorkbench as PotteryWorkBench
@onready var pot := %Pot3D as Pot3D
@onready var xr_root := $XROrigin3D as XRRoot

@onready var _controllers: Array[XRController3D] = [xr_root.left_controller, xr_root.right_controller]
var _haptic_intensity_low: Array[float] = [0.0, 0.0]
var _haptic_intensity_high: Array[float] = [0.0, 0.0]

func _ready() -> void:
	_run_haptic_loop()
	
func _run_haptic_loop() -> void:
	const duration_high := 0.075
	const duration_low := 0.225
	while true:
		for i in 2:
			if _haptic_intensity_low[i] > 1e-3:
				_controllers[i].trigger_haptic_pulse("haptic", 0.0, _haptic_intensity_low[i], duration_low+0.01, 0.0)
		await get_tree().create_timer(duration_low).timeout
		for i in 2:
			if _haptic_intensity_high[i] > 1e-3:
				_controllers[i].trigger_haptic_pulse("haptic", 0.0, _haptic_intensity_high[i], duration_high+0.01, 0.0)
		await get_tree().create_timer(duration_high).timeout
	
func enable_culling(n: Node3D) -> void:
	var mi := n as MeshInstance3D
	if mi != null:
		var mesh := mi.mesh as ArrayMesh
		if mesh != null:
			for i in mesh.get_surface_count():
				var mat := mesh.surface_get_material(i) as StandardMaterial3D
				if mat != null:
					mat.cull_mode = BaseMaterial3D.CULL_BACK
					mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	for c: Node3D in n.get_children():
		if c != null:
			enable_culling(c)

func _process(delta: float) -> void:
	for i in 2:
		_haptic_intensity_low[i] = 0.0
		_haptic_intensity_high[i] = 0.0
	
	if workbench.is_rotating():
		var sponge_controller := sponge.get_picked_up_by_controller()
		if sponge.is_picked_up() and sponge_controller != null:
			var strength := remap(sponge_controller.get_float("trigger"), 0, 1, 0.0, 1.0)
			var feedback := pot.sculpt(sponge.global_transform, 0.045, strength, delta)
			
			var displacement_fb := feedback.x
			var scuplt_fb := feedback.y
			var intensity_low :=  0.0 if is_zero_approx(scuplt_fb) else lerpf(0.01, 0.11, scuplt_fb)
			var intensity_high := lerpf(0.0, 0.5, displacement_fb)
			intensity_high = maxf(intensity_high, intensity_low)
			var controller_index := _controllers.find(sponge_controller)
			if controller_index != -1:
				_haptic_intensity_low[controller_index] = intensity_low
				_haptic_intensity_high[controller_index] = intensity_high
			
		var brush_controller := brush.get_picked_up_by_controller()
		if brush.is_picked_up() and brush_controller != null:
			var feedback := pot.paint(brush.get_tool_pos(), 0.02, brush.current_color)
			var controller_index := _controllers.find(brush_controller)
			if controller_index != -1:
				_haptic_intensity_low[controller_index] = feedback * 0.02
				_haptic_intensity_high[controller_index] = feedback * 0.02
			
