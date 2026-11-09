shader_type spatial;
// A "photo" material for the image-to-3D models: darkens the armour toward Luna's black,
// and lets the coloured light lines (the saturated parts of the texture) glow.
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap;
uniform float dark = 0.3;
uniform float glow = 1.8;

void fragment() {
	vec3 c = texture(albedo_tex, UV).rgb;
	float sat = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b));
	float line = smoothstep(0.16, 0.38, sat);
	ALBEDO = mix(c * dark, c, line * 0.4);
	METALLIC = 0.55;
	ROUGHNESS = 0.36;
	NORMAL_MAP = texture(normal_tex, UV).rgb;
	EMISSION = c * line * glow;
}
