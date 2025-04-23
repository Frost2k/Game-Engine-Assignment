#include "enhanced_input_handling.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/engine.hpp>

using namespace godot;

void EnhancedInputHandling::_bind_methods() {
    // Expose 'speed' to the inspector
    ClassDB::bind_method(D_METHOD("get_speed"), &EnhancedInputHandling::get_speed);
    ClassDB::bind_method(D_METHOD("set_speed", "p_speed"), &EnhancedInputHandling::set_speed);

    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "speed", PROPERTY_HINT_RANGE, "0,9999,1"), 
                 "set_speed", "get_speed");

    // Binding the "move" method if you want to call it from GDScript (optional)
    ClassDB::bind_method(D_METHOD("move", "direction"), &EnhancedInputHandling::move);
}

EnhancedInputHandling::EnhancedInputHandling() {
    // Default constructor
    base_speed = 100.0;
    sprint_speed = 300.0;
    current_speed = base_speed;
}

EnhancedInputHandling::~EnhancedInputHandling() {
    // Destructor
}

void EnhancedInputHandling::_init() {
    // Called once on creation (not always used)
    if (Engine::get_singleton()->is_editor_hint()) {
        // Skip runtime-specific init in the editor
        return;
    }
}

void EnhancedInputHandling::_process(double delta) {
    // Skip logic in editor
    if (Engine::get_singleton()->is_editor_hint()) {
        return;
    }

    Input* input = Input::get_singleton();
    if (!input) return;

    // 1) Check if the "sprint" action is pressed (mapped to Space in Input Map)
    bool sprint_pressed = input->is_action_pressed("sprint");
    
    if( sprint_pressed){
        //UtilityFunctions::print("EnhancedInputHandling: Sprint triggered!");
    }

    // If sprint is pressed, use sprint_speed, else base_speed
    double effective_speed = sprint_pressed ? sprint_speed : base_speed;
    //UtilityFunctions::print("Effective speed: ", effective_speed);

    // 2) Movement logic: is_action_pressed for "ui_up", "ui_left", etc.
    Vector2 direction(0, 0);
    if (input->is_action_pressed("ui_up")) {
        direction.y -= 1;
    }
    if (input->is_action_pressed("ui_down")) {
        direction.y += 1;
    }
    if (input->is_action_pressed("ui_left")) {
        direction.x -= 1;
    }
    if (input->is_action_pressed("ui_right")) {
        direction.x += 1;
    }

    // 3) Attack logic: If "attack" action is just pressed (mapped to F)
    if (input->is_action_just_pressed("attack")) {

        //UtilityFunctions::print("EnhancedInputHandling: Attack triggered!");
    }

    // 4) Move the node
    move(direction.normalized() * (float)effective_speed * (float)delta);

    // Let the GDScript see the new speed
    Node *parent = get_parent(); // the CharacterBody2D
    parent->set("speed", effective_speed);
    //UtilityFunctions::print("EnhancedInputHandling: Speed set to ", effective_speed);
}

void EnhancedInputHandling::move(Vector2 direction) {
    translate(direction);
}

double EnhancedInputHandling::get_speed() const {
    // Return the currently set speed in the inspector (the "base" speed)
    return current_speed;
}

void EnhancedInputHandling::set_speed(const double p_speed) {
    // If user changes speed in the inspector, we treat that as the "base" speed
    current_speed = p_speed;
    base_speed = p_speed; 
}
