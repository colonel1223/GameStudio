// ============================================================================
// UMBRAL — shadow_dissolve.gdshader
// Sumi-e Ink Dissolution Effect · Sprint 1/2
// ============================================================================
// Dissolves the shadow character with an ink-painting aesthetic when
// exposed to light. Edges break apart into brush-stroke particles,
// ink bleeds into the paper texture beneath.
//
// Controlled by:
//   dissolve_amount (0.0 = solid, 1.0 = fully dissolved)
//   light_direction (normalized vec2 pointing toward light source)
//   shadow_integrity (overall health/form coherence)
// ============================================================================
shader_type canvas_item;
render_mode blend_premul_alpha;

// ── Uniforms ────────────────────────────────────────────────────────────────
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform float shadow_integrity : hint_range(0.0, 1.0) = 1.0;
uniform vec2 light_direction = vec2(0.0, -1.0);
uniform float light_intensity : hint_range(0.0, 2.0) = 0.0;

// Colors from art direction doc
uniform vec4 shadow_color : source_color = vec4(0.04, 0.04, 0.04, 0.92);
uniform vec4 ink_stain_color : source_color = vec4(0.12, 0.12, 0.12, 0.4);
uniform vec4 dissolution_edge_color : source_color = vec4(0.2, 0.15, 0.1, 0.6);

// Brush stroke parameters
uniform float brush_noise_scale : hint_range(1.0, 20.0) = 8.0;
uniform float brush_stroke_thickness : hint_range(0.5, 4.0) = 2.0;
uniform float edge_erosion_speed : hint_range(0.5, 3.0) = 1.2;

// Paper texture influence
uniform sampler2D paper_noise_texture : hint_default_white;
uniform float paper_influence : hint_range(0.0, 1.0) = 0.4;

// Time for animation
uniform float time_offset = 0.0;

// ── Noise Functions ─────────────────────────────────────────────────────────

// Simplex-style hash
vec2 hash22(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)),
             dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

// Value noise
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);

    float a = dot(hash22(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0));
    float b = dot(hash22(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0));
    float c = dot(hash22(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0));
    float d = dot(hash22(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y) * 0.5 + 0.5;
}

// Fractal noise for brush texture
float fbm(vec2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

// Sumi-e brush stroke pattern
float brush_pattern(vec2 uv, float time) {
    // Directional streaks mimicking brush loading
    vec2 brush_uv = uv * brush_noise_scale;
    brush_uv.x += time * 0.3;  // Slow horizontal drift

    float streaks = noise(brush_uv * vec2(1.0, 4.0));
    float grain = fbm(brush_uv * 3.0, 3);

    // Pressure variance (thick-to-thin tapering per art doc)
    float pressure = smoothstep(0.0, 1.0, uv.x) * smoothstep(1.0, 0.0, uv.x);

    return mix(streaks, grain, 0.4) * pressure;
}

// ── Main Fragment ───────────────────────────────────────────────────────────
void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    float time = TIME + time_offset;

    // Skip fully transparent pixels
    if (tex_color.a < 0.01) {
        discard;
    }

    // ── Base shadow with brush texture ──────────────────────────────────
    float brush = brush_pattern(UV, time);
    vec4 base_color = shadow_color;
    base_color.rgb = mix(base_color.rgb, base_color.rgb * 0.7, brush * 0.3);

    // ── Integrity-based edge shimmer ────────────────────────────────────
    // Per art doc: "Edges shimmer when near light (dissolving effect
    // via particle displacement)"
    float edge_mask = 1.0 - smoothstep(0.0, 0.15, min(UV.x, min(UV.y,
                     min(1.0 - UV.x, 1.0 - UV.y))));

    float shimmer = sin(time * 6.0 + UV.x * 20.0 + UV.y * 15.0) * 0.5 + 0.5;
    float edge_dissolve = edge_mask * (1.0 - shadow_integrity) * shimmer;

    // ── Dissolution ─────────────────────────────────────────────────────
    if (dissolve_amount > 0.001) {
        // Sample paper noise for organic dissolution pattern
        float paper = texture(paper_noise_texture, UV * 0.5).r;
        float dissolution_noise = fbm(UV * brush_noise_scale + time * 0.5, 4);

        // Directional dissolution — dissolves from light-facing side first
        vec2 norm_light = normalize(light_direction);
        float directional_bias = dot(UV - vec2(0.5), norm_light) * 0.5 + 0.5;

        // Combined dissolution threshold
        float threshold = mix(dissolution_noise, paper, paper_influence);
        threshold = mix(threshold, directional_bias, 0.3);

        // Edge erosion with brush-stroke character
        float eroded = smoothstep(
            dissolve_amount - 0.05 * brush_stroke_thickness,
            dissolve_amount + 0.02,
            threshold
        );

        // Dissolution edge glow — warm edge like ink catching light
        float edge_width = 0.08 * brush_stroke_thickness;
        float edge_band = smoothstep(dissolve_amount - edge_width, dissolve_amount, threshold)
                        - smoothstep(dissolve_amount, dissolve_amount + edge_width * 0.5, threshold);

        // Mix dissolution edge color
        base_color.rgb = mix(base_color.rgb, dissolution_edge_color.rgb, edge_band * 0.8);

        // Apply dissolution to alpha
        base_color.a *= eroded;

        // Ink stain remnant — faint trace left behind on the "paper"
        float stain = smoothstep(dissolve_amount + 0.1, dissolve_amount - 0.1, threshold);
        stain *= ink_stain_color.a * dissolve_amount;

        if (base_color.a < 0.01 && stain > 0.01) {
            base_color = vec4(ink_stain_color.rgb, stain * 0.3);
        }
    }

    // ── Light vulnerability visual ──────────────────────────────────────
    if (light_intensity > 0.01) {
        // Warm edge glow when light is near
        float light_glow = edge_mask * light_intensity * 0.4;
        vec3 warm = vec3(0.85, 0.55, 0.25);  // Burnt Umber from palette
        base_color.rgb = mix(base_color.rgb, warm, light_glow);

        // Subtle alpha reduction from light exposure
        base_color.a *= mix(1.0, 0.7, light_intensity * edge_mask);
    }

    // ── Edge shimmer application ────────────────────────────────────────
    base_color.a -= edge_dissolve * 0.3;

    // ── Form language response ──────────────────────────────────────────
    // Per art doc: "Organic curves when confident, angular fragments when afraid"
    // This is subtle — modifies the noise character based on integrity
    float angular_mix = 1.0 - shadow_integrity;
    float angular_noise = step(0.5, noise(UV * 12.0 + time * 0.2));
    base_color.a -= angular_mix * angular_noise * 0.15 * edge_mask;

    // ── Final composite ─────────────────────────────────────────────────
    base_color.a = clamp(base_color.a, 0.0, shadow_color.a) * tex_color.a;

    COLOR = base_color;
}

