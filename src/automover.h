#ifndef AUTOMOVER_H
#define AUTOMOVER_H

#include <godot_cpp/classes/area2d.hpp>

namespace godot {

class AutoMover : public Area2D {
    GDCLASS(AutoMover, Area2D);

protected:
    static void _bind_methods();

private:
    float speed = 200.0f;
    float left_limit = 220.0f;
    float right_limit = 800.0f;
    int score = 0;             // track player score
    int win_threshold = 20;    // once score reaches this, game is won

public:
    AutoMover();
    ~AutoMover();

    void _ready() override;
    void _physics_process(double delta) override;

    void _on_area_entered(Area2D *other_area);
};

} // namespace godot

#endif
