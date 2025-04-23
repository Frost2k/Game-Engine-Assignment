#ifndef ENHANCED_INPUT_HANDLING_H
#define ENHANCED_INPUT_HANDLING_H

#include <godot_cpp/classes/node2d.hpp>

namespace godot {

class EnhancedInputHandling : public Node2D {
    GDCLASS(EnhancedInputHandling, Node2D);

protected:
    static void _bind_methods();

private:
    double base_speed = 100.0;   // Normal walking speed
    double sprint_speed = 300.0; // Speed while sprinting

    // For Inspector
    double current_speed = 100.0; // We expose this with get_speed/set_speed

public:
    EnhancedInputHandling();
    ~EnhancedInputHandling();

    double get_speed() const;
    void set_speed(const double p_speed);

    virtual void _init();
    virtual void _process(double delta) override;

    // The function that actually translates the node
    void move(Vector2 direction);
};

} // namespace godot

#endif // ENHANCED_INPUT_HANDLING_H