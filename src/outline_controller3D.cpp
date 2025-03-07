#include "outline_controller_3d.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

void OutlineController3D::_bind_methods() {
    // Material property binding
    ClassDB::bind_method(D_METHOD("set_material", "material"), &OutlineController3D::set_material);
    ClassDB::bind_method(D_METHOD("get_material"), &OutlineController3D::get_material);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "material", PROPERTY_HINT_RESOURCE_TYPE, "ShaderMaterial"),
                 "set_material", "get_material");

    // Outline color
    ClassDB::bind_method(D_METHOD("set_outline_color", "color"), &OutlineController3D::set_outline_color);
    ClassDB::bind_method(D_METHOD("get_outline_color"), &OutlineController3D::get_outline_color);
    ADD_PROPERTY(PropertyInfo(Variant::COLOR, "outline_color"),
                 "set_outline_color", "get_outline_color");

    // Noise scale
    ClassDB::bind_method(D_METHOD("set_noise_scale", "scale"), &OutlineController3D::set_noise_scale);
    ClassDB::bind_method(D_METHOD("get_noise_scale"), &OutlineController3D::get_noise_scale);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "noise_scale"),
                 "set_noise_scale", "get_noise_scale");

    // Deformation strength
    ClassDB::bind_method(D_METHOD("set_deformation_strength", "strength"), &OutlineController3D::set_deformation_strength);
    ClassDB::bind_method(D_METHOD("get_deformation_strength"), &OutlineController3D::get_deformation_strength);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "deformation_strength"),
                 "set_deformation_strength", "get_deformation_strength");

    // Outline thickness
    ClassDB::bind_method(D_METHOD("set_outline_thickness", "thickness"), &OutlineController3D::set_outline_thickness);
    ClassDB::bind_method(D_METHOD("get_outline_thickness"), &OutlineController3D::get_outline_thickness);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "outline_thickness"),
                 "set_outline_thickness", "get_outline_thickness");
}

OutlineController3D::OutlineController3D() {
    // Default property values, matching your shader defaults
    outline_color = Color(0.0, 0.0, 0.0, 1.0);
    noise_scale = 3.0f;
    deformation_strength = 0.1f;
    outline_thickness = 0.03f;
}

OutlineController3D::~OutlineController3D() {
}

void OutlineController3D::set_material(const Ref<ShaderMaterial> &p_material) {
    material = p_material;
}

Ref<ShaderMaterial> OutlineController3D::get_material() const {
    return material;
}

void OutlineController3D::set_outline_color(const Color &p_color) {
    outline_color = p_color;
}

Color OutlineController3D::get_outline_color() const {
    return outline_color;
}

void OutlineController3D::set_noise_scale(float p_scale) {
    noise_scale = p_scale;
}

float OutlineController3D::get_noise_scale() const {
    return noise_scale;
}

void OutlineController3D::set_deformation_strength(float p_strength) {
    deformation_strength = p_strength;
}

float OutlineController3D::get_deformation_strength() const {
    return deformation_strength;
}

void OutlineController3D::set_outline_thickness(float p_thickness) {
    outline_thickness = p_thickness;
}

float OutlineController3D::get_outline_thickness() const {
    return outline_thickness;
}

void OutlineController3D::_process(double delta) {
    // If we have a valid ShaderMaterial, keep pushing our property values into the shader.
    // This allows real-time tweaking of the shader’s uniforms from the editor or at runtime.
    if (material.is_valid()) {
        material->set_shader_parameter("outline_color", outline_color);
        material->set_shader_parameter("noise_scale", noise_scale);
        material->set_shader_parameter("deformation_strength", deformation_strength);
        material->set_shader_parameter("outline_thickness", outline_thickness);
    }
}
