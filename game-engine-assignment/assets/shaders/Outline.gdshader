shader_type spatial;
render_mode unshaded, depth_draw_opaque, cull_front;

// Instead of `: hint_color`, use `: source_color`
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform sampler2D noise_texture;
uniform sampler2D normal_noise : hint_normal;
uniform float noise_scale : hint_range(0.1, 10.0) = 3.0;
uniform float deformation_strength : hint_range(0.0, 1.0) = 0.1;
uniform float outline_thickness : hint_range(0.0, 0.1) = 0.03;

void vertex() {
    vec2 noise_uv = UV * noise_scale;
    float noise_val = texture(noise_texture, noise_uv).r;

    vec3 nmap = texture(normal_noise, UV * noise_scale).rgb;
    nmap = normalize(nmap * 2.0 - 1.0);
    vec3 perturbed_normal = normalize(mix(NORMAL, nmap, 0.5));

    VERTEX += perturbed_normal * (noise_val - 0.5) * deformation_strength;
    VERTEX += perturbed_normal * outline_thickness;
}

void fragment() {
    ALBEDO = outline_color.rgb;
}
