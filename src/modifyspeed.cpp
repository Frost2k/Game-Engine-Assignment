#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <modifyspeed.h>

using namespace godot;

void ModifySpeed::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_multiplier", "value"), &ModifySpeed::set_multiplier);
    ClassDB::bind_method(D_METHOD("get_multiplier"), &ModifySpeed::get_multiplier);

    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "multiplier", PROPERTY_HINT_RANGE, "0.1,10,0.1"), "set_multiplier", "get_multiplier");

    ClassDB::bind_method(D_METHOD("process_secondary_script"), &ModifySpeed::process_secondary_script);
}

ModifySpeed::ModifySpeed() {
}

ModifySpeed::~ModifySpeed() {
}

void ModifySpeed::set_multiplier(float value) {
    multiplier = value;
}

float ModifySpeed::get_multiplier() const {
    return multiplier;
}

void ModifySpeed::_ready() {
    call_deferred("process_secondary_script");
}

void ModifySpeed::process_secondary_script() {
    Node *parent_node = get_parent();
    String x = "Node is = " + parent_node->get_name();
    UtilityFunctions::print(x);

    // Access the `speed` variable from the GDScript
    float speed = parent_node->get("speed");
    String y = "Speed is = " + String::num(speed);
    UtilityFunctions::print(y);

    float modified_speed = speed * multiplier;
    String z = "Modified Speed is = " + String::num(modified_speed);
    UtilityFunctions::print(z);

    // Call the `move` function from the GDScript
    Vector2 direction = Vector2(1, 0); // Example direction (right movement)
    Variant arg_direction = direction * modified_speed;
    parent_node->call("move", arg_direction);
}