shader_type canvas_item;

// Black ellipse with radial glow falloff
void fragment() {
	vec2 uv = UV - vec2(0.5);
	// Ellipse matching sprite proportions (slightly wider than tall)
	uv.x *= 0.85;
	float dist = length(uv) * 2.0;
	// Soft glow falloff
	float glow = 1.0 - smoothstep(0.0, 1.0, dist);
	glow = pow(glow, 0.6);
	// Pulsing animation — size breathes in/out
	float pulse_size = 1.0 + 0.15 * sin(TIME * 2.0);
	dist /= pulse_size;
	glow = 1.0 - smoothstep(0.0, 1.0, dist);
	glow = pow(glow, 0.6);
	// Alpha pulse
	float pulse_alpha = 0.75 + 0.25 * sin(TIME * 2.0 + 0.5);
	glow *= pulse_alpha;
	glow = clamp(glow * 1.15, 0.0, 1.0);
	COLOR = vec4(0.0, 0.0, 0.0, glow * 0.35);
}
