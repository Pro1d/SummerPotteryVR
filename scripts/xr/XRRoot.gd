class_name XRRoot
extends XROrigin3D

@export var _passtrough := false

var xr_interface: XRInterface
var webxr_interface: WebXRInterface
var vr_supported := false

@onready var _camera := %XRCamera3D as XRCamera3D
@onready var left_controller := %XRControllerLeft as XRController3D
@onready var right_controller := %XRControllerRight as XRController3D

func _ready() -> void:
	if OS.has_feature("web"):
		for node: Node3D in get_tree().get_nodes_in_group("not-web"):
			if node  != null:
				node.hide()
		(%StartVRButton as Button).pressed.connect(_on_button_pressed)
		(%DirectionalLight3D as DirectionalLight3D).shadow_enabled = false
		webxr_interface = XRServer.find_interface("WebXR")
		if webxr_interface:
			# WebXR uses a lot of asynchronous callbacks, so we connect to various
			# signals in order to receive them.
			webxr_interface.session_supported.connect(self._webxr_session_supported)
			webxr_interface.session_started.connect(self._webxr_session_started)
			webxr_interface.session_ended.connect(self._webxr_session_ended)
			webxr_interface.session_failed.connect(self._webxr_session_failed)

			# This returns immediately - our _webxr_session_supported() method
			# (which we connected to the "session_supported" signal above) will
			# be called sometime later to let us know if it's supported or not.
			webxr_interface.is_session_supported("immersive-vr")
	else:
		(%StartVRButton as Button).hide()
		(%CanvasLayer as CanvasLayer).hide()
		xr_interface = XRServer.find_interface("OpenXR")
		if xr_interface and xr_interface.is_initialized():
			print("OpenXR initialized successfully")

			# Turn off v-sync!
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

			# Change our main viewport to output to the HMD
			get_viewport().use_xr = true
			
			set_passthrough(_passtrough)
		else:
			print("OpenXR not initialized, please check if your headset is connected")
	
	left_controller.button_pressed.connect(
		func(_e: Variant) -> void:
			if left_controller.is_button_pressed("primary_click") or left_controller.is_button_pressed("secondary_click"):
				center_world_on_camera(Vector3(0.14, 0, 0.62))
	)
	right_controller.button_pressed.connect(
		func(_e: Variant) -> void:
			if right_controller.is_button_pressed("primary_click") or right_controller.is_button_pressed("secondary_click"):
				center_world_on_camera(Vector3(0.14, 0, 0.62))
	)

func center_world_on_camera(origin: Vector3 = Vector3.ZERO) -> void:
	var pos := _camera.position
	pos.y = 0
	position = origin - pos

func set_passthrough(on: bool) -> bool:
	var success := true
	if xr_interface.is_passthrough_supported():
		if xr_interface.is_passthrough_enabled() != on:
			if on:
				success = xr_interface.start_passthrough()
			else:
				xr_interface.stop_passthrough()
	else:
		var modes := xr_interface.get_supported_environment_blend_modes()
		var mode := xr_interface.XR_ENV_BLEND_MODE_ALPHA_BLEND if on else xr_interface.XR_ENV_BLEND_MODE_OPAQUE
		if mode not in modes:
			success = false
		else:
			xr_interface.set_environment_blend_mode(mode)
	
	if success:
		get_viewport().transparent_bg = on
	return success

# Web XR
func _webxr_session_supported(session_mode: String, supported: bool) -> void:
	if session_mode == 'immersive-vr':
		vr_supported = supported

func _on_button_pressed() -> void:
	if not vr_supported:
		OS.alert("Your browser doesn't support VR")
		return

	# We want an immersive VR session, as opposed to AR ('immersive-ar') or a
	# simple 3DoF viewer ('viewer').
	webxr_interface.session_mode = 'immersive-vr'
	# 'bounded-floor' is room scale, 'local-floor' is a standing or sitting
	# experience (it puts you 1.6m above the ground if you have 3DoF headset),
	# whereas as 'local' puts you down at the XROrigin.
	# This list means it'll first try to request 'bounded-floor', then
	# fallback on 'local-floor' and ultimately 'local', if nothing else is
	# supported.
	webxr_interface.requested_reference_space_types = 'bounded-floor, local-floor, local'
	# In order to use 'local-floor' or 'bounded-floor' we must also
	# mark the features as required or optional.
	webxr_interface.required_features = 'local-floor'
	webxr_interface.optional_features = 'bounded-floor'

	# This will return false if we're unable to even request the session,
	# however, it can still fail asynchronously later in the process, so we
	# only know if it's really succeeded or failed when our
	# _webxr_session_started() or _webxr_session_failed() methods are called.
	if not webxr_interface.initialize():
		OS.alert("Failed to initialize")
		return

func _webxr_session_started() -> void:
	(%StartVRButton as Button).visible = false
	# This tells Godot to start rendering to the headset.
	get_viewport().use_xr = true
	# This will be the reference space type you ultimately got, out of the
	# types that you requested above. This is useful if you want the game to
	# work a little differently in 'bounded-floor' versus 'local-floor'.
	print ("Reference space type: " + webxr_interface.reference_space_type)

func _webxr_session_ended() -> void:
	(%StartVRButton as Button).visible = true
	# If the user exits immersive mode, then we tell Godot to render to the web
	# page again.
	get_viewport().use_xr = false

func _webxr_session_failed(message: String) -> void:
	OS.alert("Failed to initialize: " + message)
