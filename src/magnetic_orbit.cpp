#include "magnetic_orbit.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/character_body2d.hpp>
#include <godot_cpp/classes/rigid_body2d.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/physics_direct_body_state2d.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

// Registers class methods and properties in Godot
void MagneticOrbit::_bind_methods() {
    // Binding player node path setter and getter
    ClassDB::bind_method(D_METHOD("set_player_path", "p_path"), &MagneticOrbit::set_player_path);
    ClassDB::bind_method(D_METHOD("get_player_path"), &MagneticOrbit::get_player_path);
    ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "player_path"), "set_player_path", "get_player_path");

    // Binding orbit object node path setter and getter
    ClassDB::bind_method(D_METHOD("set_orbit_object_path", "p_path"), &MagneticOrbit::set_orbit_object_path);
    ClassDB::bind_method(D_METHOD("get_orbit_object_path"), &MagneticOrbit::get_orbit_object_path);
    ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "orbit_object_path"), "set_orbit_object_path", "get_orbit_object_path");

    // Binding magnetic/orbit parameters
    ClassDB::bind_method(D_METHOD("set_max_distance", "val"), &MagneticOrbit::set_max_distance);
    ClassDB::bind_method(D_METHOD("get_max_distance"), &MagneticOrbit::get_max_distance);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "max_distance"), "set_max_distance", "get_max_distance");

    ClassDB::bind_method(D_METHOD("set_orbit_distance", "val"), &MagneticOrbit::set_orbit_distance);
    ClassDB::bind_method(D_METHOD("get_orbit_distance"), &MagneticOrbit::get_orbit_distance);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "orbit_distance"), "set_orbit_distance", "get_orbit_distance");

    ClassDB::bind_method(D_METHOD("set_magnetic_force", "val"), &MagneticOrbit::set_magnetic_force);
    ClassDB::bind_method(D_METHOD("get_magnetic_force"), &MagneticOrbit::get_magnetic_force);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "magnetic_force"), "set_magnetic_force", "get_magnetic_force");

    ClassDB::bind_method(D_METHOD("set_swirl_factor", "val"), &MagneticOrbit::set_swirl_factor);
    ClassDB::bind_method(D_METHOD("get_swirl_factor"), &MagneticOrbit::get_swirl_factor);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "swirl_factor"), "set_swirl_factor", "get_swirl_factor");
}

// Constructor: Initializes default values
MagneticOrbit::MagneticOrbit() {
    max_distance   = 300.0f;   // Maximum distance for magnetic effect
    orbit_distance = 80.0f;    // Distance at which the object orbits
    magnetic_force = 10000.0f; // Strength of magnetic attraction
    swirl_factor   = 0.5f;     // Controls rotational force around the target
    last_force     = Vector2(0,0); // Stores last applied force (for debugging)
}

// Destructor
MagneticOrbit::~MagneticOrbit() {
}

// Setters and getters for player node path
void MagneticOrbit::set_player_path(const NodePath &p_path) {
    player_path = p_path;
}
NodePath MagneticOrbit::get_player_path() const {
    return player_path;
}

// Setters and getters for orbit object node path
void MagneticOrbit::set_orbit_object_path(const NodePath &p_path) {
    orbit_object_path = p_path;
}
NodePath MagneticOrbit::get_orbit_object_path() const {
    return orbit_object_path;
}

// Setters and getters for magnetic/orbit parameters
void MagneticOrbit::set_max_distance(float val) {
    max_distance = val;
}
float MagneticOrbit::get_max_distance() const {
    return max_distance;
}

void MagneticOrbit::set_orbit_distance(float val) {
    orbit_distance = val;
}
float MagneticOrbit::get_orbit_distance() const {
    return orbit_distance;
}

void MagneticOrbit::set_magnetic_force(float val) {
    magnetic_force = val;
}
float MagneticOrbit::get_magnetic_force() const {
    return magnetic_force;
}

void MagneticOrbit::set_swirl_factor(float val) {
    swirl_factor = val;
}
float MagneticOrbit::get_swirl_factor() const {
    return swirl_factor;
}

// Overriding _integrate_forces to apply magnetic force in physics step
void MagneticOrbit::_integrate_forces(PhysicsDirectBodyState2D *state) {
    // Step 1: Resolve the player node reference if it's not already found
    if (!player && !player_path.is_empty()) {
        Node *maybe_player = get_node<Node>(player_path);
        if (maybe_player) {
            player = Object::cast_to<CharacterBody2D>(maybe_player);
            if (!player) {
                UtilityFunctions::print("MagneticOrbit: 'player_path' node is not a CharacterBody2D!");
            }
        }
    }

    // Step 2: Resolve the orbit object reference if applicable
    if (!orbit_object && !orbit_object_path.is_empty()) {
        Node *maybe_orbit = get_node<Node>(orbit_object_path);
        if (maybe_orbit) {
            orbit_object = Object::cast_to<RigidBody2D>(maybe_orbit);
            if (!orbit_object) {
                UtilityFunctions::print("MagneticOrbit: 'orbit_object_path' is not RigidBody2D!");
            }
        }
    }

    // If there's no valid player node, we cannot compute forces, so exit early
    if (!player) {
        last_force = Vector2(0,0);
        return;
    }

    // Get the positions of the player and orbiting object
    Vector2 player_pos = player->get_global_position();
    Vector2 orbit_pos;

    // Determine whether to use a separate orbit object or this node
    if (orbit_object) {
        orbit_pos = orbit_object->get_global_position();
    } else {
        orbit_pos = state->get_transform().get_origin();
    }

    // Compute direction vector from orbit object to player
    Vector2 dir = player_pos - orbit_pos;
    float dist = dir.length(); // Distance between objects

    // If distance is too small or exceeds max range, apply no force
    if (dist <= 0.001f || dist > max_distance) {
        last_force = Vector2(0,0);
        return;
    }

    // Compute radial magnetic force: follows an inverse square law (F ∝ 1/d²)
    float force_mag = magnetic_force / (dist * dist);
    Vector2 radial_force = dir.normalized() * force_mag;

    // Compute tangential (swirl) force if within orbit distance
    Vector2 tangential_force(0,0);
    if (dist < orbit_distance) {
        Vector2 tangent = Vector2(-dir.y, dir.x).normalized(); // Perpendicular vector
        tangential_force = tangent * (force_mag * swirl_factor);
    }

    // Sum up radial and tangential forces
    Vector2 total_force = radial_force + tangential_force;
    last_force = total_force; // Store for debugging

    // Step 3: Apply force
    if (orbit_object) {
        // Apply force to the separate orbit object (RigidBody2D)
        orbit_object->apply_central_impulse(total_force);
    } else {
        // Apply force directly to this object
        state->apply_central_impulse(total_force);
    }
}
