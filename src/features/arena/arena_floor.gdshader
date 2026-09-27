shader_type spatial;

// Ice pad: lifted base tone, thin grid, glowing border — reads apart from the void.

uniform vec3 base_color : source_color = vec3(0.07, 0.1, 0.14);
uniform vec3 grid_color : source_color = vec3(0.16, 0.42, 0.47);
uniform vec3 edge_color : source_color = vec3(0.16, 0.42, 0.47);
uniform float half_size = 6.0;
uniform float cell = 1.0;
uniform float line_width = 0.025;
uniform float grid_energy = 0.3;
uniform float edge_width = 1.2;
uniform float edge_energy = 0.55;
uniform float center_lift = 0.35;

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec2 p = local_pos.xz;

	// Distance to the nearest grid line, anti-aliased by screen-space derivative
	vec2 g = abs(fract(p / cell + 0.5) - 0.5) * cell;
	float d = min(g.x, g.y);
	float aa = fwidth(d) * 1.5;
	float line = 1.0 - smoothstep(line_width, line_width + aa, d);

	// Border glow fades inward from the pad edge
	float edge_d = half_size - max(abs(p.x), abs(p.y));
	float edge = 1.0 - smoothstep(0.0, edge_width, edge_d);

	// Soft lift toward the middle so the pad is never flat black
	float center = 1.0 - clamp(length(p) / (half_size * 1.4), 0.0, 1.0);

	ALBEDO = base_color * (1.0 + center * center_lift);
	ROUGHNESS = 0.12;
	METALLIC = 0.15;
	SPECULAR = 0.7;
	EMISSION = base_color * (0.35 + center * 0.4)
		+ grid_color * line * grid_energy
		+ edge_color * edge * edge * edge_energy;
}
