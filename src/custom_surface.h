#ifndef CUSTOM_SURFACE_H
#define CUSTOM_SURFACE_H

#include <godot_cpp/classes/static_body2d.hpp>
#include <godot_cpp/classes/physics_material.hpp>
#include <godot_cpp/core/binder_common.hpp>

namespace godot {

class CustomSurface : public StaticBody2D {
    GDCLASS(CustomSurface, StaticBody2D);

public:
    enum SurfaceType {
        SURFACE_ICE = 0,
        SURFACE_SAND,
        SURFACE_METAL,
        SURFACE_RUBBER
    };

protected:
    static void _bind_methods();

private:
    // We'll store which surface is chosen: 0=ICE, 1=SAND, 2=METAL, 3=RUBBER
    int surface_type = SURFACE_ICE;

    // We'll store friction/bounce after picking the surface
    float friction = 0.5f;
    float bounce   = 0.3f;

    // A reference to the runtime PhysicsMaterial
    Ref<PhysicsMaterial> physics_material;

public:
    CustomSurface();
    ~CustomSurface();

    void set_surface_type(int p_type);
    int get_surface_type() const;

    void _ready();

    // (Optional) If you want direct read of friction/bounce in code or GDScript
    float get_friction() const { return friction; }
    float get_bounce()   const { return bounce; }
};

} // namespace godot

#endif // CUSTOM_SURFACE_H