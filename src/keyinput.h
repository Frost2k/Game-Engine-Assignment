#ifndef KEYINPUT_H
#define KEYINPUT_H

#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/core/class_db.hpp>

namespace godot{
	class KeyInput : public Node2D {
	GDCLASS(KeyInput, Node2D)

	private:
		double speed;

	protected:
		static void _bind_methods();

	public:
		KeyInput();
		~KeyInput();

		void _process(double delta) override;
		void move(Vector2 direction);

		// Getter and Setter
		double get_speed() const;
		void set_speed(const double p_speed);

	};
}

#endif