#ifndef FLOATINGITEM_H
#define FLOATINGITEM_H

#include <godot_cpp/classes/area2d.hpp>

namespace godot {

class FloatingItem : public Area2D {
    GDCLASS(FloatingItem, Area2D);

protected:
    static void _bind_methods();

private:
    float time = 0.0f;
    float float_amplitude = 5.0f;
    float float_speed = 2.0f;
    float base_local_y = 0.0f;

    float distance = 50.0f; // default radius in inspector

public:
    FloatingItem();
    ~FloatingItem();

    // Godot callbacks
    void _ready() override;
    void _process(double delta) override;

    // If something enters collision, we handle it or call collect
    void _on_body_entered(Node *body);
    void collect_item(Node *player);

    // Floating amplitude/speed
    void set_float_amplitude(float amp);
    float get_float_amplitude() const;
    void set_float_speed(float spd);
    float get_float_speed() const;

    // Distance-based property
    void set_distance(float p_dist);
    float get_distance() const;
};

} // namespace godot

#endif // FLOATINGITEM_H
