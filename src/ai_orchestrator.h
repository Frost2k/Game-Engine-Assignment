#ifndef AI_ORCHESTRATOR_H
#define AI_ORCHESTRATOR_H

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/random_number_generator.hpp>

namespace godot {

class AIOrchestrator : public Node3D {
    GDCLASS(AIOrchestrator, Node3D)

private:
    static const int MAX_ATTACK_BUFFER_SIZE = 20;
    int player_attack_buffer[MAX_ATTACK_BUFFER_SIZE];
    int attack_buffer_index;
    int attack_buffer_count;
    
    // Godot's random number generator
    mutable Ref<RandomNumberGenerator> rng;

protected:
    static void _bind_methods();

public:
    // Enemy states
    enum {
        IDLE = 0,
        WANDER = 1,
        CHASE = 2,
        CHARGE = 4,
        SPELL = 8,
        FLEE = 16
    };
    
    // Player attack types
    enum {
        ATTACK_MELEE = 1,
        ATTACK_RANGED = 2
    };

    AIOrchestrator();
    ~AIOrchestrator();

    // Add an attack to the buffer
    void add_player_attack(int attack_type);
    
    // Clear the attack buffer
    void clear_attack_buffer();
    
    // Get statistics on player attack patterns
    float get_melee_ratio() const;
    float get_ranged_ratio() const;
    
    // Determine the next enemy state
    int next_enemy_state(int prev_state, float dist_to_player, float hp, int trait, float chase_range, float attack_range) const;
};

}

#endif // AI_ORCHESTRATOR_H