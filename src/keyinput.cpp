#include "keyinput.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/classes/sprite2d.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/viewport.hpp>

// Godot 4: keys are in the 'Key' enum
// #include <godot_cpp/classes/global_constants.hpp>  // Some older references, depends on version

using namespace godot;

void KeyInput::_bind_methods() {
    // Binding methods to Godot
    ClassDB::bind_method(D_METHOD("move", "direction"), &KeyInput::move);
    
    // Bind speed property with setter and getter
    ClassDB::bind_method(D_METHOD("get_speed"), &KeyInput::get_speed);
    ClassDB::bind_method(D_METHOD("set_speed", "p_speed"), &KeyInput::set_speed);
    
    // Expose 'speed' to the inspector
    // ClassDB::add_property("KeyInput", PropertyInfo(Variant::double, "speed"), "set_speed", "get_speed");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "speed"), "set_speed", "get_speed");
}

double KeyInput::get_speed() const {
    return speed;
}

void KeyInput::set_speed(const double p_speed) {
    speed = p_speed;
}

KeyInput::KeyInput() {
    // Constructor
    speed = 200.0;
}

KeyInput::~KeyInput() {
    // Destructor
}

void KeyInput::_process(double delta) {
    // 1) Move the player left/right if arrow keys are pressed
    move_player(delta);

    // 2) Check for space bar press to spawn a block
    //    is_key_pressed() returns true as long as it's held. 
    //    If you want "just pressed", you might store previous state or use 
    //    is_physical_key_pressed() with additional logic.
    Input* input = Input::get_singleton();
    if (input->is_action_pressed("ui_space")) {
        // Spawn a random block
        spawn_random_block();
    }
}

// Moves the player horizontally with raw arrow key checks
void KeyInput::move_player(double delta) {
    Input* input = Input::get_singleton();
    Vector2 dir(0, 0);

    if (input->is_action_pressed("ui_left")) {
        dir.x -= 1;
    }
    if (input->is_action_pressed("ui_right")) {
        dir.x += 1;
    }

    // Move horizontally
    translate(dir.normalized() * speed * delta);

    // OPTIONAL: clamp x so player stays on screen & fix y at bottom
    if (auto viewport = get_viewport()) {
        Rect2 visible = viewport->get_visible_rect();
        Vector2 pos = get_global_position();

        // Example clamp
        float sprite_half_width = 32; // Adjust for your sprite
        float left_limit  = visible.position.x + sprite_half_width;
        float right_limit = visible.position.x + visible.size.x - sprite_half_width;
        pos.x = CLAMP(pos.x, left_limit, right_limit);

        // Fix y near bottom
        pos.y = visible.position.y + visible.size.y - 50; // 50 px from bottom
        set_global_position(pos);
    }
}

// Randomly spawns one of four blocks above the player
void KeyInput::spawn_random_block() {
    // If you have distinct block textures, store them in an array
    static const String block_paths[4] = {
        "res://Block1.png",
        "res://Block2.png",
        "res://Block3.png",
        "res://Block4.png"
    };

    // Random pick 0..3
    int index = UtilityFunctions::randi() % 4;

    // Create a new Sprite2D
    Sprite2D* block = memnew(Sprite2D);
    Ref<Texture2D> tex = ResourceLoader::get_singleton()->load(block_paths[index]);
    if (tex.is_valid()) {
        block->set_texture(tex);
    }

    // Position it 150 px above the player's current position
    Vector2 spawn_pos = get_global_position() - Vector2(0, 150);
    block->set_global_position(spawn_pos);

    // Add to active scene
    Node* root = get_tree()->get_current_scene();
    if (root) {
        root->add_child(block);
        UtilityFunctions::print("Spawned block at: ", spawn_pos, " with texture: ", block_paths[index]);
    }
}

void KeyInput::move(Vector2 direction) {
    translate(direction);
}