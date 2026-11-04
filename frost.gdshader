shader_type canvas_item;
// Frosted glass behind the menu screens (Rudy, dev107): blurs whatever is drawn under
// this rect (the frozen Home battle) and darkens it a little. 17 samples in two rings;
// cheap enough for phones, and only on screen while a menu is open.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float radius = 14.0;           // blur size in screen pixels
uniform vec4 tint : source_color = vec4(0.02, 0.04, 0.11, 0.55);

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * radius;
	vec3 sum = texture(screen_tex, SCREEN_UV).rgb;
	float n = 1.0;
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.785398;
		vec2 d = vec2(cos(a), sin(a));
		sum += texture(screen_tex, SCREEN_UV + d * px * 0.5).rgb;
		sum += texture(screen_tex, SCREEN_UV + d.yx * vec2(1.0, -1.0) * px).rgb;
		n += 2.0;
	}
	vec3 blurred = sum / n;
	COLOR = vec4(mix(blurred, tint.rgb, tint.a), 1.0);
}
