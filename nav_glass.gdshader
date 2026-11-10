shader_type canvas_item;
// The bottom bar (nav_dock.gd, clean look): a floating GLASS PILL (the world behind it blurred and
// darkened, a thin light rim) and the BLUE CAPSULE on the open tab (blue glass, cyan rim, a soft cyan
// glow, taller than the pill). One shader draws both, so the pill's fill and rim are simply not drawn
// where the capsule is (Rudy: no bar lines through the capsule). A BackBufferCopy right before the dock
// (hub.gd) makes the blur see the page that is open.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform vec2 vp_size = vec2(480.0, 960.0);   // the logical viewport (blur steps are logical pixels)
uniform vec4 pill = vec4(0.0);               // x, y, w, h in the dock's own pixels
uniform vec4 cap = vec4(0.0);
uniform float cap_a = 1.0;                   // 0 hides the capsule
uniform float blur = 9.0;                    // blur size in logical pixels

varying vec2 local;

void vertex() {
	local = VERTEX;
}

float sd_round_box(vec2 p, vec4 r, float rad) {
	vec2 c = r.xy + r.zw * 0.5;
	vec2 q = abs(p - c) - r.zw * 0.5 + rad;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - rad;
}

vec3 blurred(vec2 uv) {
	vec2 px = blur / vp_size;
	vec3 s = texture(screen_tex, uv).rgb;
	float n = 1.0;
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.785398;
		vec2 d = vec2(cos(a), sin(a));
		s += texture(screen_tex, uv + d * px * 0.5).rgb;
		s += texture(screen_tex, uv + vec2(d.y, -d.x) * px).rgb;
		n += 2.0;
	}
	return s / n;
}

void fragment() {
	float dp = sd_round_box(local, pill, min(pill.w * 0.5, 40.0));
	float dc = sd_round_box(local, cap, min(24.0, min(cap.z, cap.w) * 0.5));
	float in_p = 1.0 - smoothstep(-0.5, 0.5, dp);
	float in_c = (1.0 - smoothstep(-0.5, 0.5, dc)) * cap_a;
	vec3 glow_col = vec3(0.31, 0.88, 1.0);
	float glow = cap_a * step(0.0, dc) * exp(-dc / 7.0) * 0.55;
	vec4 outc = vec4(glow_col, glow);
	if (in_p > 0.0 || in_c > 0.0) {
		vec3 b = blurred(SCREEN_UV);
		float l = dot(b, vec3(0.299, 0.587, 0.114));
		b = mix(vec3(l), b, 1.5);
		// the pill: dark navy glass, a 1 px light rim just inside its edge
		vec3 pc = mix(b, vec3(0.047, 0.078, 0.149), 0.5);
		pc = mix(pc, vec3(1.0), (1.0 - smoothstep(0.0, 1.0, abs(dp + 0.7))) * 0.16);
		pc = mix(pc, glow_col, glow);
		// the capsule: blue glass, a cyan rim, a faint white line along its top inside
		vec3 cc = mix(b, vec3(0.133, 0.408, 0.886), 0.45);
		cc = mix(cc, vec3(1.0), (1.0 - smoothstep(0.0, 1.2, abs(local.y - (cap.y + 2.6)))) * step(dc, -2.0) * 0.3);
		cc = mix(cc, vec3(0.47, 0.894, 1.0), (1.0 - smoothstep(0.0, 1.4, abs(dc + 0.9))) * 0.92);
		vec3 col = mix(pc, cc, in_c);
		float a = max(in_p, in_c);
		outc = vec4(mix(glow_col, col, a / max(max(a, glow), 0.0001)), max(a, glow));
	}
	COLOR = outc;
}
