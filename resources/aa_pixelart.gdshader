shader_type canvas_item;
uniform int atlas_cell_size = 16;
varying float inv_scale;

void vertex() {
	mat4 m = CANVAS_MATRIX * MODEL_MATRIX;
	float sx = dot(m[0].xy, m[0].xy);
	float sy = dot(m[1].xy, m[1].xy);
	inv_scale = inversesqrt(max(sx, sy));
}

vec2 _smoothstep(vec2 x) {
	return x * x * (3.0 - 2.0 * x);
}

void fragment() {
	vec2 pixel_uv = UV * vec2(textureSize(TEXTURE, 0));
	
	float h = 0.49;
	ivec2 pmxmy = ivec2(pixel_uv + vec2(-h, -h));
	ivec2 ppxmy = ivec2(pixel_uv + vec2(+h, -h));
	ivec2 pmxpy = ivec2(pixel_uv + vec2(-h, +h));
	ivec2 ppxpy = ivec2(pixel_uv + vec2(+h, +h));
	
	// Disable atlas inter-cell AA
	ivec2 atlas_cell = ivec2(pixel_uv) / atlas_cell_size;
	ivec2 m_atlas_cell = pmxmy / atlas_cell_size;
	ivec2 p_atlas_cell = ppxpy / atlas_cell_size;
	ivec2 delta_m = ivec2(notEqual(atlas_cell, m_atlas_cell));
	ivec2 delta_p = -ivec2(notEqual(atlas_cell, p_atlas_cell));
	
	vec4 tmxmy = texelFetch(TEXTURE, pmxmy + ivec2(delta_m.x, delta_m.y), 0);
	vec4 tpxmy = texelFetch(TEXTURE, ppxmy + ivec2(delta_p.x, delta_m.y), 0);
	vec4 tmxpy = texelFetch(TEXTURE, pmxpy + ivec2(delta_m.x, delta_p.y), 0);
	vec4 tpxpy = texelFetch(TEXTURE, ppxpy + ivec2(delta_p.x, delta_p.y), 0);
	
	// Pixel AA
	float w = inv_scale; // width of AA (smoothstep from 0.5-w/2 to 0.5+w/2)
	vec2 weight = fract(pixel_uv + 0.5);
	vec2 k = (weight - (0.5 - w * 0.5)) / w;
	k = clamp(k, vec2(0), vec2(1));
	k = _smoothstep(k);
	
	vec4 tmy = mix(tmxmy, tpxmy, k.x);
	vec4 tpy = mix(tmxpy, tpxpy, k.x);
	vec4 t = mix(tmy, tpy, k.y);
	
	COLOR = t;
	//COLOR = texelFetch(TEXTURE, ivec2(pixel_uv), 0);
}
