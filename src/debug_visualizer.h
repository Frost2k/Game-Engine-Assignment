#ifndef DEBUGVISUALIZER_H
#define DEBUGVISUALIZER_H



#pragma once

#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/core/binder_common.hpp>

namespace godot {

class DebugVisualizer : public Node2D {
    GDCLASS(DebugVisualizer, Node2D);

protected:
    static void _bind_methods();

private:
    bool show_collision_shapes = true;
    bool show_forces = true;

    // If you know exactly where your MagneticOrbit is, store a NodePath here:
    NodePath magnetic_orbit_path = NodePath("MagneticOrbit");

public:
    DebugVisualizer();
    ~DebugVisualizer();

    void set_show_collision_shapes(bool p_show);
    bool is_show_collision_shapes() const;

    void set_show_forces(bool p_show);
    bool is_show_forces() const;

    // For the typed get_node approach to find MagneticOrbit:
    void set_magnetic_orbit_path(const NodePath &p_path);
    NodePath get_magnetic_orbit_path() const;

    // Godot callbacks
    void _ready() override;
    void _process(double delta) override;
    void _draw() override;

private:
    // Recursively gather physics bodies
    void gather_physics_bodies(Node *p_node, Vector<Node2D *> &bodies);
    // Recursively gather shapes
    void gather_collision_shapes(Node *p_node, Vector<Node*> &shapes);

    // Actually draw shape outlines
    void draw_shape_outline(const Ref<class Shape2D> &shape, const Transform2D &global_xform);
};

} // namespace godot



#endif // DEBUGVISUALIZER_H