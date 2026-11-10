shader_type canvas_item;
// A nav tab icon (nav_icon.gd): grey = 1 turns it into the soft grey shape of a closed tab
// (no colours, lighter, half see-through); grey = 0 is Luna's full colours.

uniform float grey = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 g = vec3(min(l * 2.1 + 0.08, 1.0));
	c.rgb = mix(c.rgb, g, grey);
	c.a *= 1.0 - 0.42 * grey;
	COLOR = c;
}
