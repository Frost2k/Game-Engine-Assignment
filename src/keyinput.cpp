#include "keyinput.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/viewport.hpp>

using namespace godot;

void KeyInput::_bind_methods() {
    ClassDB::bind_method(D_METHOD("move", "direction"), &KeyInput::move);
    ClassDB::bind_method(D_METHOD("get_speed"), &KeyInput::get_speed);
    ClassDB::bind_method(D_METHOD("set_speed", "p_speed"), &KeyInput::set_speed);

    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "speed"), "set_speed", "get_speed");
}

KeyInput::KeyInput() {
    speed = 200.0; // default movement speed
}

KeyInput::~KeyInput() {
}

double KeyInput::get_speed() const {
    return speed;
}

void KeyInput::set_speed(const double p_speed) {
    speed = p_speed;
}

// Called every frame by Godot
void KeyInput::_process(double delta) {
    Input* input = Input::get_singleton();
    Vector2 dir(0, 0);

    // Move left/right using custom actions or raw checks
    if (input->is_action_pressed("ui_left")) {
        dir.x -= 1;
    }
    if (input->is_action_pressed("ui_right")) {
        dir.x += 1;
    }

    // Move the player
    translate(dir.normalized() * speed * delta);

    // Optional: clamp to screen & fix at bottom
    if (auto viewport = get_viewport()) {
        Rect2 visible = viewport->get_visible_rect();
        Vector2 pos = get_global_position();

        float sprite_half_width = 32.0; // Adjust if sprite is wider
        float left_limit  = visible.position.x + sprite_half_width;
        float right_limit = visible.position.x + visible.size.x - sprite_half_width;
        pos.x = CLAMP(pos.x, left_limit, right_limit);

        // Keep y near bottom
        set_global_position(pos);
    }
}

void KeyInput::move(Vector2 direction) {
    translate(direction);
}
