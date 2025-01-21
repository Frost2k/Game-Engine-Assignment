#ifndef MODIFYSPEED_H
#define MODIFYSPEED_H

#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/core/class_db.hpp>

namespace godot{
	class ModifySpeed : public Node2D {
	GDCLASS(ModifySpeed, Node2D)

	private:
		float multiplier = 2.0f;
		
	protected:
		static void _bind_methods();

	public:
		ModifySpeed();
		~ModifySpeed();

		void _ready() override;
		void set_multiplier(float value);
    	float get_multiplier() const;

    	void process_secondary_script();
	};
}

#endif