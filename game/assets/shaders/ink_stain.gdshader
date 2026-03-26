// ============================================================================
// UMBRAL — ink_stain.gdshader
// Permanent Ink Stain Trail Effect · Sprint 2
// ============================================================================
// Areas touched by the shadow leave permanent light gray stains on
// the paper world. "Ink pools where shadows have lingered too long,
// staining white walls with memory." — Art Director
// ============================================================================
shader_type canvas_item;

uniform float stain_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float stain_age : hint_range(0.0, 1.0) = 0.0;
uniform vec2 stain_center = vec2(0.5, 0.5);
uniform float stain_radius : hint_range(0.0, 1.0) = 0.3;

uniform vec4 fresh_stain_color : source_color = vec4(0.08, 0.08, 0.08, 0.3);
uniform vec4 aged_stain_color : source_color = vec4(0.92, 0.92, 0.90, 0.12);

uniform float paper_grain_scale : hint_range(1.0, 30.0) = 15.0;
uniform float bleed_speed : hint_range(0.1, 2.0) = 0.5;

// Paper grain noise
float paper_noise(vec2 uv) {
    vec2 p = uv * paper_grain_scale;
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = fract(sin(dot(i, vec2(12.9898, 78.233))) * 43758.5453);
    float b = fract(sin(dot(i + vec2(1.0, 0.0), vec2(12.9898, 78.233))) * 43758.5453);
    float c = fract(sin(dot(i + vec2(0.0, 1.0), vec2(12.9898, 78.233))) * 43758.5453);
    float d = fract(sin(dot(i + vec2(1.0, 1.0), vec2(12.9898, 78.233))) * 43758.5453);

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float dist = distance(UV, stain_center);

    // Organic edge with paper grain influence
    float grain = paper_noise(UV);
    float edge = smoothstep(stain_radius, stain_radius * 0.6, dist + grain * 0.08);

    // Bleed effect — stain spreads slightly over time
    float bleed = stain_radius + stain_age * bleed_speed * 0.05;
    float bleed_edge = smoothstep(bleed, bleed * 0.7, dist + grain * 0.1);

    float mask = max(edge, bleed_edge * 0.3) * stain_intensity;

    // Color ages from dark ink to faded gray
    vec4 stain_color = mix(fresh_stain_color, aged_stain_color, stain_age);

    // Paper texture absorption — darker in grain valleys
    stain_color.a *= (1.0 - grain * 0.3);

    COLOR = mix(tex, stain_color, mask);
}

