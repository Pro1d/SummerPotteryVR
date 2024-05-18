shader_type spatial;
render_mode unshaded, depth_draw_always;

uniform vec3 color : source_color = vec3(1);
const float half_thickness = 0.02 / 2.0;
const float handle_radius = 0.05;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 delta_border = abs(UV - 0.5) * 2.0 - vec2(0.8);
	float dist_border = max(delta_border.x, delta_border.y);
	float dist_corner = sqrt(dot(delta_border, delta_border));
	 if ((abs(dist_border) < half_thickness || dist_corner < handle_radius)) {
		ALBEDO = color;
		ALPHA = 1.0;
	}
	else if (dist_border < 0.0) {
		ALBEDO = color;
		ALPHA = 0.0;
	}
	else{
		ALPHA = 0.0;
	}
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
