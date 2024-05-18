shader_type spatial;
render_mode unshaded, skip_vertex_transform, cull_disabled, depth_draw_never;

uniform float size_y = 0.5;
uniform vec3 color : source_color = vec3(1);
varying float height;
varying float vertical;
varying vec2 horizontal;

vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise31(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

float random (vec2 st) {
    return fract(
		sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123
	);
}
float random3 (vec3 st) {
    return fract(
		sin(dot(st.xyz, vec3(12.9898, 78.233, 57.687))) * 43758.5453123
	);
}

float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    vec2 u = f*f*(3.0-2.0*f);
    // u = smoothstep(0.,1.,f);

    // Mix 4 coorners percentages
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

float noise3 (in vec3 st) {
    vec3 i = floor(st);
    vec3 f = fract(st);

    // Four corners in 2D of a tile
    float a = noise31(i);
    float b = noise31(i + vec3(1.0, 0.0, 0.0));
    float c = noise31(i + vec3(0.0, 1.0, 0.0));
    float d = noise31(i + vec3(1.0, 1.0, 0.0));
    float a2 = noise31(i + vec3(0.0, 0.0, 1.0));
    float b2 = noise31(i + vec3(1.0, 0.0, 1.0));
    float c2 = noise31(i + vec3(0.0, 1.0, 1.0));
    float d2 = noise31(i + vec3(1.0, 1.0, 1.0));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    vec3 u = f*f*(3.0-2.0*f);
    // u = smoothstep(0.,1.,f);

    // Mix 4 coorners percentages
    float k = mix(a, b, u.x) + ((c - a) * (1.0 - u.x) + (d - b) * u.x) * u.y;
    float k2 = mix(a2, b2, u.x) + ((c2 - a2) * (1.0 - u.x) + (d2 - b2) * u.x) * u.y;
	return mix(k, k2, u.z);
}

void vertex() {
	height = VERTEX.y / size_y + .5;
	horizontal = VERTEX.xz + 0.5;
	vertical = abs(NORMAL.y) < 0.01 ? 1.0 : 0.0;
    VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (vertical < 0.1) discard;
	vec2 scaled = horizontal * 25.0;
	float t = 0.25 * TIME;
	float r = noise3(vec3(scaled + vec2(0.6*t), t));
	r = min(r * 0.9 + 0.4, 1);
	float h = clamp(height / (r * r), 0, 1);
	float k = (h - 1.0) * (h - 1.0);
	float mix_ground = clamp(height * 5.0, 0, 1);
	mix_ground = 1.0 - (1.0 - mix_ground) * (1.0 - mix_ground);
	ALPHA = mix(1.0, k, mix_ground);//k*k*(3.0-2.0*k);
	ALBEDO = color;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
