#include "custom_surface.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/physics_material.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

CustomSurface::CustomSurface() {
    // Default to ICE, friction=0.5 bounce=0.3 (these will be overwritten in set_surface_type)
}

CustomSurface::~CustomSurface() {
    // destructor if needed
}

void CustomSurface::_bind_methods() {
    // Expose "surface_type" as an integer property in the editor,
    // with an enum hint for the 4 types: "Ice,Sand,Metal,Rubber"
    ClassDB::bind_method(D_METHOD("set_surface_type", "p_type"), &CustomSurface::set_surface_type);
    ClassDB::bind_method(D_METHOD("get_surface_type"), &CustomSurface::get_surface_type);

    ADD_PROPERTY(
        PropertyInfo(Variant::INT, "surface_type", PROPERTY_HINT_ENUM, "Ice,Sand,Metal,Rubber"),
        "set_surface_type",
        "get_surface_type"
    );
}

void CustomSurface::set_surface_type(int p_type) {
    surface_type = p_type;

    // We'll pick friction and bounce based on the chosen surface
    switch (surface_type) {
        case SURFACE_ICE:
            friction = 0.1f;
            bounce   = 0.1f;
            break;
        case SURFACE_SAND:
            friction = 0.9f;
            bounce   = 0.0f;
            break;
        case SURFACE_METAL:
            friction = 0.4f;
            bounce   = 0.2f;
            break;
        case SURFACE_RUBBER:
            friction = 0.2f;
            bounce   = 0.8f;
            break;
        default:
            friction = 0.5f;
            bounce   = 0.3f;
            break;
    }

    // If the physics_material is already valid, update it now
    if (physics_material.is_valid()) {
        physics_material->set_friction(friction);
        physics_material->set_bounce(bounce);
    }
}

int CustomSurface::get_surface_type() const {
    return surface_type;
}

void CustomSurface::_ready() {
    // Create a PhysicsMaterial at runtime
    physics_material.instantiate();
    if (!physics_material.is_valid()) {
        UtilityFunctions::print("Failed to instantiate PhysicsMaterial.");
        return;
    }

    // set friction/bounce based on the current surface_type
    set_surface_type(surface_type);

    // Assign the material to override
    set("physics_material_override", physics_material);
}
