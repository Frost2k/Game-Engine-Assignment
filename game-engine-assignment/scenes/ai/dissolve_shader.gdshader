// NOTE: Shader automatically converted from Godot Engine 4.3.stable.mono's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

// New uniforms for controlling the effect externally.
//uniform bool explosion_on = false;
uniform float explosion_time = 0.0; // <-- Controlled by script (reset to 0 each time)
uniform float explosion_speed : hint_range(0.0,10.0) = 0.5;
uniform float dissolve_delay   : hint_range(0.0,10.0) = 0.1;
uniform float dissolve_speed   : hint_range(0.0,10.0) = 10.0;

uniform float noise_scale : hint_range(0.1,10.0) = 3.0;
uniform sampler2D noise_texture;


void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
    if (explosion_time > 0.0) {
        float local_time = explosion_time;
        //float explosion_strength = clamp(local_time * explosion_speed, 0.0, 1.0);
        //VERTEX += NORMAL * explosion_strength;
    }
}

void fragment() {
	
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	
	if (explosion_time > 0.0) {
        float local_time = explosion_time;
        float t = max(local_time - dissolve_delay, 0.0);
        float dissolve_threshold = clamp(t * dissolve_speed, 0.0, 1.0);
        vec2 dissolve_uv = UV * noise_scale;
        float noise_value_dissolve = texture(noise_texture, dissolve_uv).r;
        if (noise_value_dissolve < dissolve_threshold) {
            discard;
        }
		
        // Calculate darkening factor (0.0 = no darkening, 1.0 = fully black)
        float darkening = clamp(explosion_time / dissolve_delay / 4.0, 0.0, 1.0);
        
        // Smoothly transition to black as explosion_time increases
        ALBEDO = mix(ALBEDO, vec3(0.0, 0.0, 0.0), darkening);
        // Add alpha fadeout as explosion_time increases
        // Start with fully opaque (1.0) and gradually fade to transparent
        float alpha_fade = clamp(1.0 - (explosion_time / dissolve_delay / 2.0), 0.0, 1.0);
        ALPHA = alpha_fade;
    }

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
}
