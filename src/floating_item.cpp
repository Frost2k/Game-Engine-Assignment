#include "floating_item.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

// For positions, collisions, etc.
#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/classes/character_body2d.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/engine.hpp>

using namespace godot;

void FloatingItem::_bind_methods() {
    // Float amplitude
    ClassDB::bind_method(D_METHOD("set_float_amplitude", "amp"), &FloatingItem::set_float_amplitude);
    ClassDB::bind_method(D_METHOD("get_float_amplitude"), &FloatingItem::get_float_amplitude);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "float_amplitude"), "set_float_amplitude", "get_float_amplitude");

    // Float speed
    ClassDB::bind_method(D_METHOD("set_float_speed", "spd"), &FloatingItem::set_float_speed);
    ClassDB::bind_method(D_METHOD("get_float_speed"), &FloatingItem::get_float_speed);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "float_speed"), "set_float_speed", "get_float_speed");

    // Distance property (if you want an activation radius)
    ClassDB::bind_method(D_METHOD("set_distance", "dist"), &FloatingItem::set_distance);
    ClassDB::bind_method(D_METHOD("get_distance"), &FloatingItem::get_distance);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "distance"), "set_distance", "get_distance");

    // Collision callbacks
    ClassDB::bind_method(D_METHOD("_on_body_entered", "body"), &FloatingItem::_on_body_entered);
    ClassDB::bind_method(D_METHOD("collect_item", "player"), &FloatingItem::collect_item);
}

// Constructor / destructor
FloatingItem::FloatingItem() {
    float_amplitude = 5.0f;
    float_speed = 2.0f;
    distance = 50.0f; // default activation distance
}
FloatingItem::~FloatingItem() {
}

// Called once this Area2D enters the scene
void FloatingItem::_ready() {
    // Remember the local Y position so we can float around it
    base_local_y = get_position().y;

    // Connect collision detection
    connect("body_entered", Callable(this, "_on_body_entered"));
}

// Called every rendered frame
void FloatingItem::_process(double delta) {
    // Don’t run logic in the editor
    if (Engine::get_singleton()->is_editor_hint()) {
        return;
    }

    // Attempt to get the SceneTree
    SceneTree *tree = get_tree();
    if (!tree) {
        return;
    }

    // Current scene root
    Node *root = tree->get_current_scene();
    if (!root) {
        return;
    }

    // Find the player node by name. Adjust if your player is at a different path.
    CharacterBody2D *player_node = root->get_node<CharacterBody2D>(NodePath("Player"));

    if (!player_node) {
        return;
    }

    // Cast to CharacterBody2D (or Node2D if your player is just Node2D)
    CharacterBody2D *player = Object::cast_to<CharacterBody2D>(player_node);
    if (!player) {
        return;
    }

    // Now we can measure distance
    Vector2 player_pos = player->get_global_position();
    Vector2 item_pos = get_global_position();
    float dist_to_player = player_pos.distance_to(item_pos);

    // If within 'distance', do the floating bob, else remain at base Y
    if (dist_to_player <= distance) {
        // Apply simple sine wave
        time += static_cast<float>(delta) * float_speed;
        float offset = float_amplitude * sin(time);

        // Update local Y around base_local_y
        Vector2 local_pos = get_position();
        local_pos.y = base_local_y + offset;
        set_position(local_pos);
    } else {
        // If too far, you can optionally revert to base_local_y
        Vector2 local_pos = get_position();
        local_pos.y = base_local_y;
        set_position(local_pos);
    }
}

// Called when something enters our collision shape
void FloatingItem::_on_body_entered(Node *body) {
    // Possibly check if body is the player
    // For now, we call collect_item no matter who enters
    collect_item(body);
}

// Called to finalize collection logic
void FloatingItem::collect_item(Node *player) {
    UtilityFunctions::print("FloatingItem collected by: ", player->get_name());
    // Remove item from scene
    queue_free();
}

// Accessors for amplitude/speed
void FloatingItem::set_float_amplitude(float amp) {
    float_amplitude = amp;
}
float FloatingItem::get_float_amplitude() const {
    return float_amplitude;
}

void FloatingItem::set_float_speed(float spd) {
    float_speed = spd;
}
float FloatingItem::get_float_speed() const {
    return float_speed;
}

// Accessors for distance property
void FloatingItem::set_distance(float dist) {
    distance = dist;
}
float FloatingItem::get_distance() const {
    return distance;
}
