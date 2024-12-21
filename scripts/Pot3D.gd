class_name Pot3D
extends Node3D

@onready var outer := $OuterSurface as MeshInstance3D
@onready var inner := $InnerSurface as MeshInstance3D
@onready var flat_cap := $FlatCapTop as MeshInstance3D

@onready var cylinder_mesh := outer.mesh as CylinderMesh
@onready var flat_cap_cylinder_mesh := flat_cap.mesh as CylinderMesh

@onready var shader_material := preload("res://resources/materials/pot_3d.material") as ShaderMaterial #outer.material_override as ShaderMaterial

@onready var shape_curve := (
	(shader_material.get_shader_parameter("texture_shape") as CurveTexture).curve
)
@onready var displacement_curve := (
	(shader_material.get_shader_parameter("displacement_curve") as CurveTexture).curve
)
@onready var paint_curves: Array[Curve] = [
	(shader_material.get_shader_parameter("paint_texture") as CurveXYZTexture).curve_x,
	(shader_material.get_shader_parameter("paint_texture") as CurveXYZTexture).curve_y,
	(shader_material.get_shader_parameter("paint_texture") as CurveXYZTexture).curve_z,
]
@onready var paint_mask_curve := (
	(shader_material.get_shader_parameter("paint_mask_texture") as CurveTexture).curve
)

const half_thickness := 0.01 # m
const curve_resolution := 64 #24 if OS.has_feature("web") else 48
const paint_curve_resolution = curve_resolution * 4
const height := 0.4  # m
const max_radius := 0.3 # m
const min_radius := 0.03 # m
const max_sculpt_speed := 0.1 # m/s
const max_sculpt_speed_smooth := 0.05 # m/s

static func _fill_curve(curve: Curve, value: float, count: int, linear: bool = true) -> void:
	curve.clear_points()
	for i in count:
		curve.add_point(
			Vector2(float(i) / count, value),
			0, 0,
			Curve.TANGENT_LINEAR if linear else Curve.TANGENT_FREE,
			Curve.TANGENT_LINEAR if linear else Curve.TANGENT_FREE
		)
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var mat := shader_material.duplicate() as ShaderMaterial
	mat.set_shader_parameter("radial_offset", half_thickness)
	mat.set_shader_parameter("origin_offset", -outer.position)
	outer.set_surface_override_material(0, mat)
	mat = shader_material.duplicate() as ShaderMaterial
	inner.position.y = height / 2 + half_thickness
	(inner.mesh as CylinderMesh).height = height - half_thickness * 2
	mat.set_shader_parameter("radial_offset", -half_thickness)
	mat.set_shader_parameter("origin_offset", -inner.position)
	inner.set_surface_override_material(0, mat)
	
	const initial_radius := 0.5 * max_radius
	
	flat_cap.position.y = height
	flat_cap_cylinder_mesh.height = 0
	flat_cap_cylinder_mesh.top_radius = initial_radius + half_thickness
	flat_cap_cylinder_mesh.bottom_radius = initial_radius - half_thickness
	mat = shader_material.duplicate() as ShaderMaterial
	mat.set_shader_parameter("origin_offset", -flat_cap.position)
	mat.set_shader_parameter("apply_shape", false)
	flat_cap.set_surface_override_material(0, mat)
	
	Pot3D._fill_curve(shape_curve, initial_radius, curve_resolution)
	Pot3D._fill_curve(displacement_curve, 0.4, curve_resolution, false)
	Pot3D._fill_curve(paint_curves[0], 0.0, paint_curve_resolution, false)
	Pot3D._fill_curve(paint_curves[1], 0.0, paint_curve_resolution, false)
	Pot3D._fill_curve(paint_curves[2], 0.0, paint_curve_resolution, false)
	Pot3D._fill_curve(paint_mask_curve, 0.0, paint_curve_resolution, false)

# ^ y (height)
# |    *
# |   /
# |  *
# |  |
# +--*--> x (radius)
func sculpt(tool_transform: Transform3D, tool_radius: float, tool_strength: float, delta: float) -> Vector2:
	tool_transform = global_transform.affine_inverse() * tool_transform
	var tool_origin := tool_transform.origin
	var tool_dir := tool_transform.basis.x # to_local(tool_dir + tool_origin) - tool_origin
	var tool_sign := signf(tool_dir.dot(Vector3(tool_origin.x, 0, tool_origin.z)))
	var tool_origin_r := Vector2(tool_origin.x, tool_origin.z).length()
	var tool_origin_h := tool_origin.y
	#var tool_is_inside := shape_curve.sample(tool_origin_h / height) > tool_origin_r
	if tool_origin_r + tool_radius * tool_sign < 0:
		tool_sign = 1
	tool_radius += half_thickness
	tool_strength = tool_strength ** 1.5
	
	var displacement_feedback := 0.0
	var sculpt_feedback := 0.0
	
	for i in curve_resolution:
		var point_position := shape_curve.get_point_position(i)
		var point_r := point_position.y
		var point_h := (point_position.x + .5 / curve_resolution) * height
		
		if absf(point_h - tool_origin_h) > tool_radius:
			continue  # not in range vertically
		
		var offset_h := absf(point_h - tool_origin_h)
		var offset_h_normalized := offset_h / tool_radius
		var tool_shape_r := sqrt(tool_radius * tool_radius - offset_h * offset_h)
		var target_point_r := maxf(tool_origin_r + tool_shape_r * tool_sign, 0.0)
		var target_point_r_back := maxf(tool_origin_r - tool_radius * tool_sign, 0.0)
		
		if (
			(target_point_r_back < point_r and point_r < target_point_r)
			if tool_sign > 0 else
			(target_point_r_back > point_r and point_r > target_point_r)
		):
			var tool_speed := absf(target_point_r - point_r) / delta * tool_strength
			tool_speed = minf(tool_speed, max_sculpt_speed)
			var new_point_r := move_toward(point_r, target_point_r, tool_speed * delta)
			new_point_r = clampf(new_point_r, min_radius, max_radius)
			shape_curve.set_point_value(i, new_point_r)
			if i == curve_resolution - 1:
				flat_cap_cylinder_mesh.top_radius = new_point_r + half_thickness
				flat_cap_cylinder_mesh.bottom_radius = new_point_r - half_thickness
			
			var actual_speed := absf(new_point_r - point_r) / delta
			sculpt_feedback = maxf(sculpt_feedback, actual_speed / max_sculpt_speed)
			
			var delta_displacement := clampf(remap(
				actual_speed,
				0, max_sculpt_speed_smooth,
				-0.8, 0
			) if actual_speed < max_sculpt_speed_smooth else remap(
				actual_speed,
				max_sculpt_speed_smooth, max_sculpt_speed,
				0, 1 / 0.2
			), -8, 5)
			var displacement := displacement_curve.get_point_position(i).y
			displacement = clampf(displacement + delta_displacement * delta, 0, 1)
			displacement_curve.set_point_value(i, displacement)
			displacement_feedback = maxf(displacement_feedback, displacement * (1.0 - offset_h_normalized ** 2))
			
			const K := paint_curve_resolution / curve_resolution
			for j in range(i * K, (i + 1) * K):
				paint_mask_curve.set_point_value(j, maxf(0.0, paint_mask_curve.get_point_position(j).y - delta))
	
	return Vector2(displacement_feedback, clampf(sculpt_feedback, 0, 1))

func paint(tool_origin: Vector3, tool_radius: float, color: Color) -> float:
	tool_origin = to_local(tool_origin)
	
	var tool_origin_r := Vector2(tool_origin.x, tool_origin.z).length()
	var tool_origin_h := tool_origin.y
	
	var painting := false
	for i in paint_curve_resolution:
		var point_h := (paint_mask_curve.get_point_position(i).x + .5 / (paint_curve_resolution)) * height
		var point_r := shape_curve.sample(point_h  / height - (.5 / curve_resolution))
		var offset_h := absf(point_h - tool_origin_h)
		
		if offset_h > tool_radius:
			continue  # not in range vertically
		
		var tool_shape_r := tool_radius - offset_h
		var target_point_r0 := maxf(tool_origin_r - tool_shape_r - half_thickness, 0.0)
		var target_point_r1 := maxf(tool_origin_r + tool_radius + half_thickness, 0.0)
		if target_point_r0 < point_r and point_r < target_point_r1:
			paint_curves[0].set_point_value(i, color.r)
			paint_curves[1].set_point_value(i, color.g)
			paint_curves[2].set_point_value(i, color.b)
			paint_mask_curve.set_point_value(i, color.a)
			painting = true
	
	return 1.0 if painting else 0.0
