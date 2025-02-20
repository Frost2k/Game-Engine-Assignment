#include "debug_visualizer.h"

// Include necessary Godot classes
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/classes/static_body2d.hpp>
#include <godot_cpp/classes/rigid_body2d.hpp>
#include <godot_cpp/classes/character_body2d.hpp>
#include <godot_cpp/classes/collision_shape2d.hpp>
#include <godot_cpp/classes/collision_polygon2d.hpp>
#include <godot_cpp/classes/shape2d.hpp>
#include <godot_cpp/classes/rectangle_shape2d.hpp>
#include <godot_cpp/classes/circle_shape2d.hpp>
#include <godot_cpp/classes/canvas_item.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/font.hpp>  // For text rendering

// Include MagneticOrbit class if used for force visualization
#include "magnetic_orbit.h"

using namespace godot;

// Registers class methods and properties in Godot
void DebugVisualizer::_bind_methods() {
    // Bind methods for showing collision shapes
    ClassDB::bind_method(D_METHOD("set_show_collision_shapes", "p_show"), &DebugVisualizer::set_show_collision_shapes);
    ClassDB::bind_method(D_METHOD("is_show_collision_shapes"), &DebugVisualizer::is_show_collision_shapes);
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_collision_shapes"), "set_show_collision_shapes", "is_show_collision_shapes");

    // Bind methods for showing force vectors
    ClassDB::bind_method(D_METHOD("set_show_forces", "p_show"), &DebugVisualizer::set_show_forces);
    ClassDB::bind_method(D_METHOD("is_show_forces"), &DebugVisualizer::is_show_forces);
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_forces"), "set_show_forces", "is_show_forces");

    // Expose MagneticOrbit NodePath to connect to an external magnetic force system
    ClassDB::bind_method(D_METHOD("set_magnetic_orbit_path", "p_path"), &DebugVisualizer::set_magnetic_orbit_path);
    ClassDB::bind_method(D_METHOD("get_magnetic_orbit_path"), &DebugVisualizer::get_magnetic_orbit_path);
    ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "magnetic_orbit_path"), 
                 "set_magnetic_orbit_path", "get_magnetic_orbit_path");
}

// Constructor and destructor
DebugVisualizer::DebugVisualizer() {}
DebugVisualizer::~DebugVisualizer() {}

// Enable or disable collision shape visualization
void DebugVisualizer::set_show_collision_shapes(bool p_show) {
    show_collision_shapes = p_show;
    queue_redraw(); // Request re-rendering
}
bool DebugVisualizer::is_show_collision_shapes() const {
    return show_collision_shapes;
}

// Enable or disable force vector visualization
void DebugVisualizer::set_show_forces(bool p_show) {
    show_forces = p_show;
    queue_redraw(); // Request re-rendering
}
bool DebugVisualizer::is_show_forces() const {
    return show_forces;
}

// Setters and getters for the MagneticOrbit node path
void DebugVisualizer::set_magnetic_orbit_path(const NodePath &p_path) {
    magnetic_orbit_path = p_path;
}
NodePath DebugVisualizer::get_magnetic_orbit_path() const {
    return magnetic_orbit_path;
}

// Called when the node is ready in the scene
void DebugVisualizer::_ready() {
    set_process(true); // Enable `_process()` updates
}

// Called every frame to refresh the debug visualization
void DebugVisualizer::_process(double delta) {
    queue_redraw(); // Request re-rendering each frame
}

// Main drawing function for the debug visualizer
void DebugVisualizer::_draw() {
    Node *root = get_tree()->get_current_scene();
    if (!root) return;

    // Step 1: Draw collision shapes if enabled
    if (show_collision_shapes) {
        Vector<Node2D*> bodies;
        gather_physics_bodies(root, bodies); // Collect all physics bodies

        for (int i = 0; i < bodies.size(); i++) {
            Node2D *body2d = bodies[i];

            // Collect all collision shapes in the physics body
            Vector<Node*> shape_nodes;
            gather_collision_shapes(body2d, shape_nodes);

            for (int s = 0; s < shape_nodes.size(); s++) {
                // Handle CollisionShape2D
                CollisionShape2D *cshape = Object::cast_to<CollisionShape2D>(shape_nodes[s]);
                if (cshape && !cshape->is_disabled()) {
                    Ref<Shape2D> shape_ref = cshape->get_shape();
                    if (shape_ref.is_valid()) {
                        Transform2D gxf = cshape->get_global_transform();
                        draw_shape_outline(shape_ref, gxf);
                    }
                }
                // Handle CollisionPolygon2D
                CollisionPolygon2D *cpoly = Object::cast_to<CollisionPolygon2D>(shape_nodes[s]);
                if (cpoly && !cpoly->is_disabled()) {
                    PackedVector2Array local_pts = cpoly->get_polygon();
                    if (local_pts.size() > 2) {
                        Transform2D cxf = cpoly->get_global_transform();
                        PackedVector2Array xformed;
                        xformed.resize(local_pts.size());
                        for (int p = 0; p < local_pts.size(); p++) {
                            xformed.set(p, cxf.xform(local_pts[p]));
                        }
                        draw_polyline(xformed, Color(1,1,0), 2.0f, false);
                    }
                }
            }
        }
    }

    // Step 2: Draw force vectors from MagneticOrbit if enabled
    if (show_forces && !magnetic_orbit_path.is_empty()) {
        MagneticOrbit *orbit = root->get_node<MagneticOrbit>(magnetic_orbit_path);
        if (orbit) {
            Vector2 force_vec = orbit->get_last_force();
            if (force_vec.length() > 0.001f) {
                NodePath obj_path = orbit->get_orbit_object_path();
                if (!obj_path.is_empty()) {
                    RigidBody2D *body = root->get_node<RigidBody2D>(obj_path);
                    if (body) {
                        Vector2 body_pos = body->get_global_position();
                        float scale = 0.05f;
                        Vector2 end_pos = body_pos + (force_vec * scale);
                        draw_line(body_pos, end_pos, Color(1,0,0), 2.0f, false);
                    }
                }
            }
        }
    }
}

// Recursive function to collect physics bodies (RigidBody2D, CharacterBody2D, StaticBody2D)
void DebugVisualizer::gather_physics_bodies(Node *p_node, Vector<Node2D *> &bodies) {
    if (!p_node) return;
    if (Node2D *n2d = Object::cast_to<Node2D>(p_node)) {
        if (Object::cast_to<RigidBody2D>(n2d) ||
            Object::cast_to<CharacterBody2D>(n2d) ||
            Object::cast_to<StaticBody2D>(n2d))
        {
            bodies.push_back(n2d);
        }
    }
    int cc = p_node->get_child_count();
    for (int i = 0; i < cc; i++) {
        gather_physics_bodies(p_node->get_child(i), bodies);
    }
}

// Recursive function to collect collision shapes
void DebugVisualizer::gather_collision_shapes(Node *p_node, Vector<Node*> &shapes) {
    if (!p_node) return;
    if (Object::cast_to<CollisionShape2D>(p_node) ||
        Object::cast_to<CollisionPolygon2D>(p_node))
    {
        shapes.push_back(p_node);
    }
    int cc = p_node->get_child_count();
    for (int i = 0; i < cc; i++) {
        gather_collision_shapes(p_node->get_child(i), shapes);
    }
}

// Function to draw outlines of different shape types
void DebugVisualizer::draw_shape_outline(const Ref<Shape2D> &shape, const Transform2D &global_xform) {
    if (!shape.is_valid()) return;

    if (Object::cast_to<RectangleShape2D>(*shape)) {
        RectangleShape2D *rect_shape = Object::cast_to<RectangleShape2D>(*shape);
        Vector2 size = rect_shape->get_size();
        Rect2 local_rect(Vector2(-size.x * 0.5f, -size.y * 0.5f), size);
        draw_rect(local_rect, Color(1, 1, 0), false);

    } else if (Object::cast_to<CircleShape2D>(*shape)) {
        CircleShape2D *circle = Object::cast_to<CircleShape2D>(*shape);
        float radius = circle->get_radius();
        draw_arc(global_xform.get_origin(), radius, 0, 2 * Math_PI, 24, Color(1,0,0), 2.0f, false);

    } else {
        draw_string(Ref<Font>(), global_xform.get_origin(), "[Unknown Shape2D]", HORIZONTAL_ALIGNMENT_LEFT, -1, -1, Color(1,1,0,1));
    }
}
