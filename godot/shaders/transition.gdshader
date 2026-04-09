// Pattern-based scene transition shader.
// Source: https://godotshaders.com/shader/transition-shader-with-patterns/ (CC0)
// Modified: COLOR.rgb now respects `base_color` (was hardcoded to vec3(0.0)).
//
// Usage: drive `factor` 1.0 -> 0.0 to cover the screen, then 0.0 -> 1.0 to reveal.

shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec2 node_resolution = vec2(1920.0, 1080.0);

uniform float factor : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float width : hint_range(0.0, 1.0, 0.01) = 0.4;

group_uniforms gradient;
uniform sampler2D gradient_texture : filter_linear, repeat_disable;
uniform bool gradient_fixed = false;

group_uniforms shape;
uniform sampler2D shape_texture : filter_linear, repeat_enable;
uniform float shape_tiling = 16.0;
uniform float shape_rotation = 0.0;
uniform vec2 shape_scroll = vec2(0.0);
uniform float shape_feathering : hint_range(0.0, 1.0, 0.01) = 0.05;
uniform float shape_treshold : hint_range(0.0, 2.0, 0.01) = 1.0;


float sample_gradient(vec2 uv, vec2 fixed_uv, bool fixed) {
	if (fixed) {
		return texture(gradient_texture, fixed_uv).r;
	}
	return texture(gradient_texture, uv).r;
}


vec2 rotate(vec2 uv, vec2 pivot, float angle) {
	mat2 rotation = mat2(vec2(sin(angle), -cos(angle)),
						 vec2(cos(angle),  sin(angle)));
	uv -= pivot;
	uv = uv * rotation;
	uv += pivot;
	return uv;
}


void fragment() {
	float progress = mix(-width, 1.0, factor);
	float aspect = node_resolution.y / node_resolution.x;

	vec2 aspect_uv = ((UV - vec2(0.0, 0.5)) * vec2(1.0, aspect)) + vec2(0.0, 0.5);

	float value = clamp((sample_gradient(UV, aspect_uv, gradient_fixed) - progress) / width, 0.0, 1.0);

	vec2 tiled_uv = rotate(
		mod((aspect_uv + vec2(TIME) * shape_scroll) * shape_tiling, 1.0),
		vec2(0.5),
		radians(shape_rotation)
	);
	float shape_value = 1.0 - texture(shape_texture, tiled_uv).r;

	shape_value = mix(shape_feathering * 0.5, 1.0 - shape_feathering * 0.5, shape_value);
	float shaped_gradient = smoothstep(
		value - (shape_feathering * 0.5),
		value + (shape_feathering * 0.5),
		shape_treshold - shape_value
	);

	COLOR.rgb = base_color.rgb;
	COLOR.a = shaped_gradient * base_color.a;
}
