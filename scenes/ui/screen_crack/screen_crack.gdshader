shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float stage : hint_range(0.0, 3.0, 1.0) = 0.0;
uniform vec4 crack_color : source_color = vec4(0.90, 0.94, 0.96, 1.0);
uniform vec4 glow_color : source_color = vec4(0.62, 0.66, 0.66, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.05, 0.06, 0.07, 1.0);
uniform vec4 reflection_color : source_color = vec4(0.98, 0.98, 0.92, 1.0);
uniform vec4 darkness_color : source_color = vec4(0.01, 0.012, 0.016, 1.0);
uniform float main_width : hint_range(0.001, 0.035, 0.001) = 0.0022;
uniform float secondary_width : hint_range(0.0005, 0.02, 0.0005) = 0.00105;
uniform float micro_width : hint_range(0.0003, 0.01, 0.0003) = 0.00045;
uniform float opacity : hint_range(0.0, 1.0, 0.01) = 0.62;
uniform float max_darkness : hint_range(0.0, 0.9, 0.01) = 0.30;
uniform float random_seed : hint_range(0.0, 100.0, 1.0) = 17.0;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);

	float a = hash21(i + random_seed);
	float b = hash21(i + vec2(1.0, 0.0) + random_seed);
	float c = hash21(i + vec2(0.0, 1.0) + random_seed);
	float d = hash21(i + vec2(1.0, 1.0) + random_seed);

	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		v += value_noise(p) * amp;
		p *= 2.04;
		amp *= 0.5;
	}
	return v;
}

float segment_along(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	return clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
}

float segment_distance_at(vec2 p, vec2 a, vec2 b, float along) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	return length(pa - ba * along);
}

float glass_line(vec2 p, vec2 a, vec2 b, float width, float visible_from, float strength) {
	float visible = step(visible_from, stage);
	float along = segment_along(p, a, b);
	float d = segment_distance_at(p, a, b, along);
	float end_fade = smoothstep(0.0, 0.025, along) * (1.0 - smoothstep(0.88, 1.0, along));
	float uneven = mix(0.78, 1.08, fbm(vec2(along * 18.0, width * 1200.0 + random_seed)));
	float core = 1.0 - smoothstep(width * uneven, width * 2.1 * uneven, d);
	float bevel = 1.0 - smoothstep(width * 2.2, width * 5.4, d);
	return max(core, bevel * 0.22) * end_fade * visible * strength;
}

float kinked_glass_line(vec2 p, vec2 a, vec2 b, float width, float visible_from, float strength, float bend, float seed) {
	vec2 dir = normalize(b - a);
	vec2 normal = vec2(-dir.y, dir.x);
	float mid_t = mix(0.38, 0.62, hash21(vec2(seed, random_seed)));
	float side = mix(-1.0, 1.0, step(0.5, hash21(vec2(seed + 13.7, random_seed))));
	vec2 mid = mix(a, b, mid_t) + normal * bend * side * mix(0.45, 1.0, hash21(vec2(seed + 2.0, random_seed)));
	float first = glass_line(p, a, mid, width, visible_from, strength);
	float second = glass_line(p, mid, b, width * mix(0.72, 0.96, hash21(vec2(seed + 5.0, random_seed))), visible_from, strength * 0.92);
	return max(first, second);
}

float thin_scratch(vec2 p, vec2 a, vec2 b, float visible_from, float strength, float seed) {
	return kinked_glass_line(p, a, b, micro_width * mix(0.55, 0.95, hash21(vec2(seed, random_seed))), visible_from, strength, 0.014, seed);
}

float impact_ring(vec2 p, vec2 center, float radius, float width, float visible_from) {
	float visible = step(visible_from, stage);
	float d = abs(distance(p, center) - radius);
	float angle = atan(p.y - center.y, p.x - center.x);
	float broken = smoothstep(0.18, 0.72, fbm(vec2(angle * 2.8 + radius * 31.0, radius * 17.0) + random_seed));
	broken *= mix(0.55, 1.0, smoothstep(0.16, 0.94, fbm(p * 42.0 + center * 31.0 + random_seed)));
	return (1.0 - smoothstep(width, width * 2.2, d)) * broken * visible;
}

float crushed_core(vec2 p, vec2 center, float radius, float visible_from) {
	float visible = step(visible_from, stage);
	float d = distance(p, center);
	float dust = fbm((p - center) * 145.0 + random_seed);
	float bright = 1.0 - smoothstep(0.0, radius, d);
	float rough_edge = 1.0 - smoothstep(radius * 0.42, radius * 1.16, d + (dust - 0.5) * radius * 0.42);
	return max(bright * 0.82, rough_edge * smoothstep(0.22, 0.86, dust)) * visible;
}

float shard(vec2 p, vec2 center, float radius, float angle, float visible_from, float seed) {
	float visible = step(visible_from, stage);
	vec2 q = p - center;
	float c = cos(angle);
	float s = sin(angle);
	q = vec2(c * q.x - s * q.y, s * q.x + c * q.y);

	float tri = max(abs(q.x) * 0.86 + q.y * 0.62, -q.y);
	float shape = 1.0 - smoothstep(radius * 0.72, radius, tri);
	float inner = 1.0 - smoothstep(radius * 0.2, radius * 0.95, length(q));
	float speckle = smoothstep(0.28, 0.86, fbm(q * 80.0 + seed));

	return shape * inner * mix(0.42, 1.0, speckle) * visible;
}

void add_impact_cracks(
	vec2 p,
	vec2 center,
	float visible_from,
	float scale,
	float intensity,
	inout float main_cracks,
	inout float secondary_cracks,
	inout float micro_cracks,
	inout float debris
) {
	float mw = main_width * scale;
	float sw = secondary_width * scale;
	float uw = micro_width * scale;

	main_cracks = max(main_cracks, kinked_glass_line(p, center, center + vec2(-0.58, -0.08) * scale, mw, visible_from, 0.74 * intensity, 0.018 * scale, 11.0));
	main_cracks = max(main_cracks, kinked_glass_line(p, center, center + vec2(-0.42, -0.30) * scale, mw * 0.92, visible_from, 0.66 * intensity, 0.020 * scale, 13.0));
	main_cracks = max(main_cracks, kinked_glass_line(p, center, center + vec2(-0.06, -0.46) * scale, mw * 0.82, visible_from, 0.54 * intensity, 0.016 * scale, 17.0));
	main_cracks = max(main_cracks, kinked_glass_line(p, center, center + vec2(0.28, -0.36) * scale, mw * 0.92, visible_from, 0.70 * intensity, 0.018 * scale, 19.0));
	main_cracks = max(main_cracks, kinked_glass_line(p, center, center + vec2(0.50, -0.08) * scale, mw * 0.86, visible_from, 0.68 * intensity, 0.016 * scale, 23.0));
	main_cracks = max(main_cracks, kinked_glass_line(p, center, center + vec2(0.46, 0.22) * scale, mw * 0.82, visible_from, 0.54 * intensity, 0.018 * scale, 29.0));
	main_cracks = max(main_cracks, kinked_glass_line(p, center, center + vec2(0.14, 0.48) * scale, mw * 0.78, visible_from, 0.50 * intensity, 0.016 * scale, 31.0));
	main_cracks = max(main_cracks, kinked_glass_line(p, center, center + vec2(-0.18, 0.48) * scale, mw * 0.82, visible_from, 0.54 * intensity, 0.018 * scale, 37.0));
	main_cracks = max(main_cracks, kinked_glass_line(p, center, center + vec2(-0.42, 0.18) * scale, mw * 0.88, visible_from, 0.62 * intensity, 0.020 * scale, 41.0));

	secondary_cracks = max(secondary_cracks, kinked_glass_line(p, center + vec2(-0.24, -0.04) * scale, center + vec2(-0.39, 0.16) * scale, sw, visible_from, 0.54 * intensity, 0.016 * scale, 43.0));
	secondary_cracks = max(secondary_cracks, kinked_glass_line(p, center + vec2(-0.18, -0.18) * scale, center + vec2(-0.14, -0.38) * scale, sw * 0.9, visible_from, 0.46 * intensity, 0.014 * scale, 47.0));
	secondary_cracks = max(secondary_cracks, kinked_glass_line(p, center + vec2(0.13, -0.18) * scale, center + vec2(0.02, -0.40) * scale, sw * 0.86, visible_from, 0.42 * intensity, 0.016 * scale, 53.0));
	secondary_cracks = max(secondary_cracks, kinked_glass_line(p, center + vec2(0.24, -0.04) * scale, center + vec2(0.40, 0.10) * scale, sw * 0.84, visible_from, 0.42 * intensity, 0.015 * scale, 59.0));
	secondary_cracks = max(secondary_cracks, kinked_glass_line(p, center + vec2(0.23, 0.10) * scale, center + vec2(0.20, 0.34) * scale, sw * 0.82, visible_from, 0.36 * intensity, 0.014 * scale, 61.0));
	secondary_cracks = max(secondary_cracks, kinked_glass_line(p, center + vec2(-0.08, 0.24) * scale, center + vec2(-0.31, 0.30) * scale, sw * 0.86, visible_from, 0.40 * intensity, 0.016 * scale, 67.0));
	secondary_cracks = max(secondary_cracks, kinked_glass_line(p, center + vec2(-0.25, 0.14) * scale, center + vec2(-0.47, 0.06) * scale, sw * 0.82, visible_from, 0.38 * intensity, 0.015 * scale, 71.0));
	secondary_cracks = max(secondary_cracks, kinked_glass_line(p, center + vec2(0.02, -0.26) * scale, center + vec2(0.18, -0.44) * scale, sw * 0.72, visible_from, 0.32 * intensity, 0.014 * scale, 73.0));
	secondary_cracks = max(secondary_cracks, kinked_glass_line(p, center + vec2(0.31, 0.04) * scale, center + vec2(0.52, 0.00) * scale, sw * 0.68, visible_from, 0.30 * intensity, 0.014 * scale, 79.0));
	secondary_cracks = max(secondary_cracks, kinked_glass_line(p, center + vec2(-0.30, -0.05) * scale, center + vec2(-0.51, -0.18) * scale, sw * 0.66, visible_from, 0.28 * intensity, 0.014 * scale, 83.0));

	micro_cracks = max(micro_cracks, thin_scratch(p, center + vec2(-0.06, -0.02) * scale, center + vec2(-0.18, -0.13) * scale, visible_from, 0.32 * intensity, 89.0));
	micro_cracks = max(micro_cracks, thin_scratch(p, center + vec2(0.07, -0.04) * scale, center + vec2(0.20, -0.12) * scale, visible_from, 0.30 * intensity, 97.0));
	micro_cracks = max(micro_cracks, thin_scratch(p, center + vec2(0.05, 0.08) * scale, center + vec2(0.18, 0.18) * scale, visible_from, 0.30 * intensity, 101.0));
	micro_cracks = max(micro_cracks, thin_scratch(p, center + vec2(-0.05, 0.11) * scale, center + vec2(-0.18, 0.12) * scale, visible_from, 0.28 * intensity, 103.0));
	micro_cracks = max(micro_cracks, thin_scratch(p, center + vec2(-0.01, -0.09) * scale, center + vec2(0.04, -0.24) * scale, visible_from, 0.28 * intensity, 107.0));
	micro_cracks = max(micro_cracks, thin_scratch(p, center + vec2(0.10, 0.00) * scale, center + vec2(0.27, 0.04) * scale, visible_from, 0.26 * intensity, 109.0));
	micro_cracks = max(micro_cracks, thin_scratch(p, center + vec2(-0.16, 0.05) * scale, center + vec2(-0.30, -0.01) * scale, visible_from, 0.24 * intensity, 113.0));
	micro_cracks = max(micro_cracks, thin_scratch(p, center + vec2(0.15, 0.12) * scale, center + vec2(0.33, 0.22) * scale, visible_from, 0.24 * intensity, 127.0));
	micro_cracks = max(micro_cracks, thin_scratch(p, center + vec2(-0.12, -0.20) * scale, center + vec2(-0.28, -0.25) * scale, visible_from, 0.24 * intensity, 131.0));
	micro_cracks = max(micro_cracks, thin_scratch(p, center + vec2(0.02, 0.23) * scale, center + vec2(0.10, 0.40) * scale, visible_from, 0.22 * intensity, 137.0));

	main_cracks = max(main_cracks, crushed_core(p, center, 0.024 * scale, visible_from) * 0.62 * intensity);
	secondary_cracks = max(secondary_cracks, impact_ring(p, center, 0.043 * scale, sw * 1.0, visible_from) * 0.62 * intensity);
	secondary_cracks = max(secondary_cracks, impact_ring(p, center, 0.082 * scale, sw * 0.8, visible_from) * 0.40 * intensity);
	micro_cracks = max(micro_cracks, impact_ring(p, center, 0.120 * scale, uw * 1.5, visible_from) * 0.28 * intensity);
	debris = max(debris, shard(p, center + vec2(0.035, -0.018) * scale, 0.012 * scale, 0.7, visible_from, 3.0) * intensity);
	debris = max(debris, shard(p, center + vec2(-0.026, 0.026) * scale, 0.010 * scale, -0.6, visible_from, 5.0) * intensity);
}

void fragment() {
	float normalized_stage = clamp(stage / 3.0, 0.0, 1.0);
	vec2 p = UV;
	vec4 screen_color = texture(screen_texture, SCREEN_UV);

	float main_cracks = 0.0;
	float secondary_cracks = 0.0;
	float micro_cracks = 0.0;
	float debris = 0.0;

	// Reference style: one dominant hit around the upper-right area, then subtle extra stress cracks.
	add_impact_cracks(p, vec2(0.68, 0.34), 1.0, 1.08, 1.0, main_cracks, secondary_cracks, micro_cracks, debris);
	add_impact_cracks(p, vec2(0.42, 0.58), 2.0, 0.70, 0.38, main_cracks, secondary_cracks, micro_cracks, debris);
	add_impact_cracks(p, vec2(0.84, 0.22), 3.0, 0.62, 0.30, main_cracks, secondary_cracks, micro_cracks, debris);

	// Soft polygon edges and extra edge-origin cracks between fractured glass pieces.
	secondary_cracks = max(secondary_cracks, kinked_glass_line(p, vec2(0.28, 0.03), vec2(0.57, 0.25), secondary_width * 0.54, 1.0, 0.24, 0.018, 151.0));
	secondary_cracks = max(secondary_cracks, kinked_glass_line(p, vec2(0.57, 0.25), vec2(0.98, 0.13), secondary_width * 0.50, 1.0, 0.22, 0.020, 157.0));
	secondary_cracks = max(secondary_cracks, kinked_glass_line(p, vec2(0.32, 0.43), vec2(0.96, 0.42), secondary_width * 0.52, 1.0, 0.24, 0.016, 163.0));
	secondary_cracks = max(secondary_cracks, kinked_glass_line(p, vec2(0.96, 0.06), vec2(0.75, 0.28), secondary_width * 0.48, 1.0, 0.24, 0.022, 167.0));
	secondary_cracks = max(secondary_cracks, kinked_glass_line(p, vec2(0.17, 0.34), vec2(0.49, 0.44), secondary_width * 0.54, 2.0, 0.28, 0.020, 173.0));
	secondary_cracks = max(secondary_cracks, kinked_glass_line(p, vec2(0.28, 0.70), vec2(0.58, 0.52), secondary_width * 0.60, 2.0, 0.31, 0.022, 179.0));
	secondary_cracks = max(secondary_cracks, kinked_glass_line(p, vec2(0.58, 0.52), vec2(0.92, 0.62), secondary_width * 0.56, 2.0, 0.27, 0.020, 181.0));
	secondary_cracks = max(secondary_cracks, kinked_glass_line(p, vec2(0.00, 0.58), vec2(0.24, 0.49), secondary_width * 0.50, 2.0, 0.28, 0.020, 191.0));
	secondary_cracks = max(secondary_cracks, kinked_glass_line(p, vec2(0.42, 0.90), vec2(0.74, 0.58), secondary_width * 0.58, 3.0, 0.30, 0.023, 193.0));
	secondary_cracks = max(secondary_cracks, kinked_glass_line(p, vec2(0.74, 0.58), vec2(0.98, 0.76), secondary_width * 0.54, 3.0, 0.27, 0.021, 197.0));
	secondary_cracks = max(secondary_cracks, kinked_glass_line(p, vec2(0.86, 1.00), vec2(0.72, 0.74), secondary_width * 0.50, 3.0, 0.28, 0.022, 199.0));
	micro_cracks = max(micro_cracks, thin_scratch(p, vec2(0.92, 0.22), vec2(0.80, 0.16), 1.0, 0.24, 211.0));
	micro_cracks = max(micro_cracks, thin_scratch(p, vec2(0.82, 0.36), vec2(0.70, 0.46), 1.0, 0.24, 223.0));
	micro_cracks = max(micro_cracks, thin_scratch(p, vec2(0.26, 0.43), vec2(0.13, 0.50), 2.0, 0.24, 227.0));
	micro_cracks = max(micro_cracks, thin_scratch(p, vec2(0.50, 0.62), vec2(0.38, 0.74), 2.0, 0.22, 229.0));
	micro_cracks = max(micro_cracks, thin_scratch(p, vec2(0.74, 0.66), vec2(0.86, 0.58), 3.0, 0.22, 233.0));
	micro_cracks = max(micro_cracks, thin_scratch(p, vec2(0.62, 0.82), vec2(0.50, 0.94), 3.0, 0.22, 239.0));

	float crack_mask = clamp(main_cracks + secondary_cracks * 0.58 + micro_cracks * 0.30, 0.0, 1.0);
	float glow_mask = clamp(main_cracks * 0.54 + secondary_cracks * 0.26 + micro_cracks * 0.11 + debris * 0.14, 0.0, 1.0);
	float shadow_mask = clamp((main_cracks + secondary_cracks) * 0.26, 0.0, 1.0);

	float edge_distance = min(min(p.x, 1.0 - p.x), min(p.y, 1.0 - p.y));
	float edge_stress = (1.0 - smoothstep(0.0, 0.16, edge_distance)) * step(1.0, stage);
	float sparkle = smoothstep(0.82, 1.0, fbm(p * 115.0 + random_seed)) * crack_mask * 0.16;
	float reflection_noise = fbm(p * 16.0 + random_seed * 0.31);
	float broad_reflection = smoothstep(0.36, 0.92, reflection_noise) * crack_mask;
	float hair_reflection = smoothstep(0.74, 1.0, fbm(p * 72.0 + random_seed)) * (secondary_cracks + micro_cracks);
	float glass_shadow = smoothstep(0.20, 0.84, fbm(p * 24.0 - random_seed)) * shadow_mask;

	vec3 base_color = mix(shadow_color.rgb, glow_color.rgb, glow_mask * 0.62);
	vec3 final_color = mix(base_color, crack_color.rgb, main_cracks * 0.54 + sparkle);
	final_color = mix(final_color, reflection_color.rgb, broad_reflection * 0.30 + hair_reflection * 0.36);
	final_color = mix(final_color, shadow_color.rgb, glass_shadow * 0.25);
	final_color = mix(final_color, reflection_color.rgb, debris * 0.32 + edge_stress * 0.05);

	float alpha = clamp(
		main_cracks * 0.58 +
		secondary_cracks * 0.34 +
		micro_cracks * 0.17 +
		debris * 0.24 +
		edge_stress * 0.04 +
		shadow_mask * 0.11 +
		broad_reflection * 0.13 +
		hair_reflection * 0.10,
		0.0,
		1.0
	) * opacity * normalized_stage;

	float vignette = smoothstep(0.30, 0.88, distance(p, vec2(0.5, 0.5)) * 1.42);
	float darkness = max_darkness * normalized_stage;
	float edge_darkness = darkness * mix(0.78, 1.18, vignette);
	vec3 darkened_screen = mix(screen_color.rgb, darkness_color.rgb, edge_darkness);
	vec3 composed_color = mix(darkened_screen, final_color, alpha);

	COLOR = vec4(composed_color, 1.0);
}
