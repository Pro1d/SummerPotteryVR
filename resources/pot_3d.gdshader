// NOTE: Shader automatically converted from Godot Engine 4.2.2.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx, world_vertex_coords; //skip_vertex_transform;

const float inv_PI = 1.0 / PI;

uniform vec4 albedo : source_color;
uniform vec4 albedo_bump : source_color;
uniform vec4 albedo_flaw : source_color;
uniform float roughness : hint_range(0,1);
uniform sampler2D texture_displacement : hint_default_black, filter_linear, repeat_enable;
uniform sampler2D displacement_curve : hint_default_white, filter_linear, repeat_disable;
uniform sampler2D lines_texture : hint_default_black, filter_linear, repeat_enable;
uniform sampler2D paint_texture : hint_default_black, filter_linear, repeat_disable;
uniform sampler2D paint_mask_texture : hint_default_black, filter_linear, repeat_disable;
uniform float displacement_length = 0.03;
uniform float height = 0.4;
uniform mat4 parent_transform;
uniform mat4 parent_transform_inv;
varying float disp; // [-.5 ; +.5]
varying float darken; // 0-1
varying float lighten; // 0-1
varying vec3 uv3; // theta, height, radius

void vertex() {
	vec4 local_pos = parent_transform_inv * vec4(VERTEX, 1);
	float theta = atan(local_pos.x, local_pos.z) * inv_PI * .5 + .5;
	float h = clamp(local_pos.y / height, 0, 1);
	uv3 = vec3(theta, h, length(local_pos.xz));
	
	float noise = texture(texture_displacement, vec2(uv3.x, uv3.y * 0.3)).r;
	disp = 0.0;
	darken = 0.0;
	lighten = 0.0;
	
	if (uv3.z > 1e-3) {
		float factor = texture(displacement_curve, vec2(1.0 - uv3.y, 0)).r * 0.95 + 0.05;
		disp = (noise - .5) * factor;
		local_pos.xz = local_pos.xz / uv3.z * (uv3.z + disp * min(displacement_length, uv3.z * .35));
		darken = clamp(-disp * factor * 2.0, 0, 1);
		lighten = clamp(disp * factor * 2.0, 0, 1);
	}
	VERTEX = ((parent_transform * local_pos)).xyz;
}

void fragment() {
	// lines pattern
	float lines = texture(lines_texture, vec2(uv3.y, 1.0-uv3.z)).r;
	lines *= lines * lines;
	
	vec4 paint_tex = texture(paint_texture, vec2(1.0 - uv3.y, uv3.x));
	float paint_mask_tex = texture(paint_mask_texture, vec2(1.0 - uv3.y, uv3.x)).r;
	
	float masked_lines = lines * clamp(1.0 - abs(disp) / .2, 0, 1);
	ALBEDO = mix(mix(mix(
		mix(albedo.rgb, albedo_bump.rgb, masked_lines),
		albedo_flaw.rgb, darken),
		albedo_bump.rgb, lighten
	), paint_tex.rgb, paint_mask_tex * 0.65);
	
	METALLIC = mix(0.0, 0.25, paint_mask_tex); //metallic;//mix(metallic, 0.2, masked_lines);
	ROUGHNESS = mix(roughness, 0.35, paint_mask_tex); //mix(roughness, 0.1, masked_lines);
	SPECULAR = 0.5;
	//AO_LIGHT_AFFECT = 1.0;
	//AO = mix(0.5, 1.0, clamp(darken * darken, 0, 1));
}
