#include "automover.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/classes/area2d.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/node.hpp>

using namespace godot;

void AutoMover::_bind_methods() {
    ClassDB::bind_method(D_METHOD("_on_area_entered", "other_area"), &AutoMover::_on_area_entered);
}

AutoMover::AutoMover() {
}

AutoMover::~AutoMover() {
}

void AutoMover::_ready() {
    // Connect the built-in "area_entered" signal
    connect("area_entered", Callable(this, "_on_area_entered"));
}

void AutoMover::_physics_process(double delta) {
    Vector2 pos = get_position();
    pos.x += speed * delta;

    // Debug print
    //UtilityFunctions::print("Before clamp: pos.x=", pos.x, " speed=", speed, " delta=", delta);

    if (pos.x >= right_limit) {
        pos.x = right_limit - 1;
        speed = -fabs(speed);
        //UtilityFunctions::print("Hit right edge, speed now=", speed, "delta=", delta);
    }

    if (pos.x <= left_limit) {
        pos.x = left_limit + 1;
        speed = fabs(speed);
        //UtilityFunctions::print("Hit left edge, speed now=", speed, "delta=", delta);
    }

    set_position(pos);
    //UtilityFunctions::print("Final: pos.x=", pos.x, " speed=", speed, "delta=", delta);
}

void AutoMover::_on_area_entered(Area2D *other_area) {
    if (!other_area) {
        return;
    }
    if (other_area == this) {
        // Ignore self-collision
        return;
    }

    // Every block that enters this area is removed and increments score
    other_area->queue_free();
    score++;

    UtilityFunctions::print("Block passed through! Score is now: ", score);

    // Check for win condition
    if (score >= win_threshold) {
        UtilityFunctions::print("YOU WIN!");

        // Display "YOU WIN!" on screen
        Label *win_label = get_node<Label>("/root/Main/WinLabel");
        if (win_label) {
            win_label->set_visible(true);
            win_label->set_text("YOU WIN!");
        }

        // Pause the game
        SceneTree *tree = get_tree();
        if (tree) {
            tree->set("paused", true);
            // Alternatively: tree->call("set_paused", true);
        }
    }
}
