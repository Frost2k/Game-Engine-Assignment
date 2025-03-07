shader_type spatial; 
// Indicates this is a spatial (3D) shader in Godot.

render_mode blend_mix, depth_draw_opaque, unshaded; 
/*
  - blend_mix: Normal blending mode for alpha.
  - depth_draw_opaque: Tells the engine to treat this as fully opaque for depth calculations 
    (makes sense since we’re not doing complex transparency).
  - unshaded: Disables built-in lighting so we can fully control the lighting in the shader.
*/

uniform sampler2D noise_texture;
// A texture used for generating noise values to animate or deform the mesh.

uniform sampler2D normal_noise : hint_normal;
// A texture that contains normal information (e.g., normal map), used for perturbed normals.

uniform vec4 base_color : source_color = vec4(0.0, 4.0, 0.0, 1.0);
/*
  - The base color of the toon-shaded material. 
  - Using ': source_color' (like in the new Godot 4 material inspector) 
    so we can pick the color from the editor’s color picker.
  - Default is a slightly exaggerated green (the second component is 4.0 for demonstration).
*/

uniform float toon_opacity : hint_range(0.0, 1.0) = 0.5;
// Opacity of the final toon shading.

uniform float deformation_strength : hint_range(0.0, 1.0) = 0.1;
// How strong the vertex displacement should be.

uniform float noise_scale : hint_range(0.1, 10.0) = 3.0;
// How much to scale the texture coordinates for both noise textures.

uniform vec3 directional_light_color = vec3(1.0);
// The color of the directional light we’re simulating in the fragment function.

uniform vec3 directional_light_direction = vec3(0.0, 1.0, 0.0);
// Direction from which the light shines. Default is from above (the +Y axis).

uniform int toon_levels : hint_range(1, 20) = 5;
// The number of discreet shading levels for the toon effect.

uniform float shadow_bias : hint_range(0.0, 1.0) = 0.001;
/*
  - A small offset used to reduce the darkness near the terminator (edge between light and shadow).
  - Helps avoid overly hard edges or shadow clipping.
*/

uniform bool cool_lighting_on = false;
// A toggle to see how it looks if we also multiply by directional_light_color for a “cool” effect.

void vertex() {
    // Scale the UV coordinates for the noise texture:
    vec2 noise_uv = UV * noise_scale;
    
    // Sample the noise texture and pull out the red channel (just a single float):
    float noise_val = texture(noise_texture, noise_uv).r;

    // Sample the normal map noise texture:
    vec3 nmap = texture(normal_noise, UV * noise_scale).rgb;
    // Normal maps are usually in [0,1], but actual normals are in [-1,1], so we convert:
    nmap = normalize(nmap * 2.0 - 1.0);

    // Blend half-and-half between the mesh’s original NORMAL and the noise-based normal:
    vec3 perturbed_normal = normalize(mix(NORMAL, nmap, 0.5));

    // Displace the vertex along the perturbed normal. 
    // (noise_val - 0.5) centers the noise around 0 (i.e., -0.5 to +0.5).
    VERTEX += perturbed_normal * (noise_val - 0.5) * deformation_strength;
}

void fragment() {
    // Once again, retrieve and normalize the perturbed normal:
    vec3 nmap = texture(normal_noise, UV * noise_scale).rgb;
    nmap = normalize(nmap * 2.0 - 1.0);

    // Blend between the original geometry normal and the noise-based normal:
    vec3 norm = normalize(mix(NORMAL, nmap, 0.5));

    // Compute directional light intensity:
    vec3 light_dir = normalize(directional_light_direction);
    float diff = max(dot(norm, light_dir), 0.0);

    // Apply the shadow bias so it's not fully black at the terminator:
    diff = (diff - shadow_bias) / (1.0 - shadow_bias);
    diff = clamp(diff, 0.0, 1.0);

    // Quantize the diffuse factor to get discrete “toon” steps:
    float toon_diff = floor(diff * float(toon_levels)) / float(toon_levels);

    // Decide whether to multiply by the directional light color:
    vec3 shading_col = !cool_lighting_on
        ? base_color.rgb * toon_diff
        : base_color.rgb * directional_light_color * toon_diff;

    // Output final fragment color and alpha (opacity).
    ALBEDO = shading_col;
    ALPHA = toon_opacity;
}
