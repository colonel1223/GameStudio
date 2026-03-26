// ============================================================================
// UMBRAL — light_bloom.gdshader
// Watercolor Light Bloom · Sprint 2
// ============================================================================
// "All light sources use watercolor diffusion shader with 80-pixel
// soft falloff" — Art Director
//
// Creates organic, painterly light bloom that feels like wet watercolor
// bleeding into the paper surface. Each light type has distinct warmth.
// ============================================================================
shader_type canvas_item;
render_mode blend_add;

uniform float bloom_intensity : hint_range(0.0, 2.0) = 0.6;
uniform float bloom_radius : hint_range(10.0, 200.0) = 80.0;
uniform vec4 bloom_color : source_color = vec4(1.0, 0.65, 0.3, 0.08);
uniform float watercolor_wetness : hint_range(0.0, 1.0) = 0.6;
uniform float breathing_phase = 0.0;

// Paper texture absorption
uniform sampler2D paper_texture : hint_default_white;
uniform float paper_absorption : hint_range(0.0, 1.0) = 0.3;

// Watercolor noise
float watercolor_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);  // Quintic interpolation

    float a = fract(sin(dot(i, vec2(127.1, 311.7))) * 43758.5453);
    float b = fract(sin(dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453);
    float c = fract(sin(dot(i + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
    float d = fract(sin(dot(i + vec2(1.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(UV, center) * 2.0;  // 0 at center, 1 at edge

    // Breathing modulation (15% variance at 0.8s period)
    float breath = 1.0 + sin(breathing_phase) * 0.15;
    float effective_dist = dist / breath;

    // Watercolor edge — organic, uneven falloff
    float wc_noise = watercolor_noise(UV * 8.0 + TIME * 0.1);
    float wc_edge = effective_dist + (wc_noise - 0.5) * watercolor_wetness * 0.3;

    // Multi-ring bloom (concentric watercolor rings per art doc)
    float ring1 = smoothstep(1.0, 0.0, wc_edge) * 0.4;
    float ring2 = smoothstep(0.7, 0.0, wc_edge) * 0.3;
    float ring3 = smoothstep(0.4, 0.0, wc_edge) * 0.2;
    float ring4 = smoothstep(0.15, 0.0, wc_edge) * 0.1;

    float bloom = (ring1 + ring2 + ring3 + ring4) * bloom_intensity;

    // Paper absorption — light catches in paper grain
    float paper = texture(paper_texture, UV * 2.0).r;
    bloom *= mix(1.0, paper, paper_absorption);

    // Color with slight warm-to-cool gradient from center
    vec3 inner_color = bloom_color.rgb;
    vec3 outer_color = bloom_color.rgb * vec3(0.8, 0.9, 1.1);  // Slightly cooler edge
    vec3 final_color = mix(outer_color, inner_color, smoothstep(1.0, 0.0, effective_dist));

    COLOR = vec4(final_color * bloom, bloom * bloom_color.a);
}

