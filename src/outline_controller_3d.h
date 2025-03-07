#ifndef OUTLINE_CONTROLLER_3D_H
#define OUTLINE_CONTROLLER_3D_H

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/shader_material.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

class OutlineController3D : public Node3D {
    GDCLASS(OutlineController3D, Node3D);

private:
    // A reference to the ShaderMaterial resource.
    Ref<ShaderMaterial> material;

    // Shader uniform properties that we want to expose in the editor.
    Color outline_color;
    float noise_scale;
    float deformation_strength;
    float outline_thickness;

protected:
    static void _bind_methods();

public:
    OutlineController3D();
    ~OutlineController3D();

    // Called every frame; we’ll update the shader parameters here.
    void _process(double delta) override;

    // -- Material Accessors --
    void set_material(const Ref<ShaderMaterial> &p_material);
    Ref<ShaderMaterial> get_material() const;

    // -- Outline Color Accessors --
    void set_outline_color(const Color &p_color);
    Color get_outline_color() const;

    // -- Noise Scale Accessors --
    void set_noise_scale(float p_scale);
    float get_noise_scale() const;

    // -- Deformation Strength Accessors --
    void set_deformation_strength(float p_strength);
    float get_deformation_strength() const;

    // -- Outline Thickness Accessors --
    void set_outline_thickness(float p_thickness);
    float get_outline_thickness() const;
};

#endif // OUTLINE_CONTROLLER_3D_H
