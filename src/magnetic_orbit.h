#ifndef MAGNETICORBIT_H
#define MAGNETICORBIT_H


#include <godot_cpp/classes/rigid_body2d.hpp>
#include <godot_cpp/core/binder_common.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/classes/physics_direct_body_state2d.hpp>

namespace godot {

class PhysicsDirectBodyState2D;
class CharacterBody2D;
class RigidBody2D;

class MagneticOrbit : public RigidBody2D {
    GDCLASS(MagneticOrbit, RigidBody2D);

protected:
    static void _bind_methods();

private:
    // NodePaths to your "center" player and the "orbit object"
    NodePath player_path;
    NodePath orbit_object_path;

    // pointers once resolved
    CharacterBody2D *player = nullptr;
    RigidBody2D *orbit_object = nullptr;

    // custom magnet / orbit params
    float max_distance   = 300.0f;
    float orbit_distance = 80.0f;
    float magnetic_force = 10000.0f;
    float swirl_factor   = 0.5f;

    // store the final computed force for debugging
    Vector2 last_force = Vector2(0,0);

public:
    MagneticOrbit();
    ~MagneticOrbit();

    // NodePath getters/setters
    void set_player_path(const NodePath &p_path);
    NodePath get_player_path() const;

    void set_orbit_object_path(const NodePath &p_path);
    NodePath get_orbit_object_path() const;

    // Parameter getters/setters
    void set_max_distance(float val);
    float get_max_distance() const;

    void set_orbit_distance(float val);
    float get_orbit_distance() const;

    void set_magnetic_force(float val);
    float get_magnetic_force() const;

    void set_swirl_factor(float val);
    float get_swirl_factor() const;

    virtual void _integrate_forces(PhysicsDirectBodyState2D *state) override;

    // Debug getter
    Vector2 get_last_force() const { return last_force; }
};

} // namespace godot



#endif // MAGNETICORBIT_H