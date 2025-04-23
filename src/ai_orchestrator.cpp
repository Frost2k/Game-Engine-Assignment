#include "ai_orchestrator.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/random_number_generator.hpp>

using namespace godot;

// Register methods and properties for the class
void AIOrchestrator::_bind_methods() {
    ClassDB::bind_method(D_METHOD("add_player_attack", "attack_type"), &AIOrchestrator::add_player_attack);
    ClassDB::bind_method(D_METHOD("next_enemy_state", "prev_state", "dist_to_player", "hp", "trait", "chase_range", "attack_range"), &AIOrchestrator::next_enemy_state);
    ClassDB::bind_method(D_METHOD("get_melee_ratio"), &AIOrchestrator::get_melee_ratio);
    ClassDB::bind_method(D_METHOD("get_ranged_ratio"), &AIOrchestrator::get_ranged_ratio);
    ClassDB::bind_method(D_METHOD("clear_attack_buffer"), &AIOrchestrator::clear_attack_buffer);
    
    // Constants for enemy states
    BIND_CONSTANT(IDLE);
    BIND_CONSTANT(WANDER);
    BIND_CONSTANT(CHASE);
    BIND_CONSTANT(CHARGE);
    BIND_CONSTANT(SPELL);
    BIND_CONSTANT(FLEE);
    
    // Constants for player attack types
    BIND_CONSTANT(ATTACK_MELEE);
    BIND_CONSTANT(ATTACK_RANGED);
}

// Constructor
AIOrchestrator::AIOrchestrator() {
    // Initialize the attack buffer with zeros
    for (int i = 0; i < MAX_ATTACK_BUFFER_SIZE; i++) {
        player_attack_buffer[i] = 0;
    }
    attack_buffer_index = 0;
    attack_buffer_count = 0;
    
    // Initialize random number generator
    rng.instantiate();
    rng->randomize(); // Use a different seed each time
}

// Destructor
AIOrchestrator::~AIOrchestrator() {
    // Nothing specific to clean up
}

// Add a player attack to the cyclic buffer
void AIOrchestrator::add_player_attack(int attack_type) {
    // Only accept valid attack types (1 for melee, 2 for ranged)
    if (attack_type != ATTACK_MELEE && attack_type != ATTACK_RANGED) {
        UtilityFunctions::printerr("Invalid attack type! Use 1 for melee or 2 for ranged.");
        return;
    }
    
    // Add to buffer
    player_attack_buffer[attack_buffer_index] = attack_type;
    
    // Update index and count
    attack_buffer_index = (attack_buffer_index + 1) % MAX_ATTACK_BUFFER_SIZE;
    if (attack_buffer_count < MAX_ATTACK_BUFFER_SIZE) {
        attack_buffer_count++;
    }
}

// Clear the attack buffer
void AIOrchestrator::clear_attack_buffer() {
    for (int i = 0; i < MAX_ATTACK_BUFFER_SIZE; i++) {
        player_attack_buffer[i] = 0;
    }
    attack_buffer_index = 0;
    attack_buffer_count = 0;
}

// Calculate the ratio of melee attacks in the buffer
float AIOrchestrator::get_melee_ratio() const {
    if (attack_buffer_count == 0) return 0.5f; // Default to balanced if no data
    
    int melee_count = 0;
    for (int i = 0; i < attack_buffer_count; i++) {
        if (player_attack_buffer[i] == ATTACK_MELEE) {
            melee_count++;
        }
    }
    
    return static_cast<float>(melee_count + 5.0) / (attack_buffer_count + 10.0);
}

// Calculate the ratio of ranged attacks in the buffer
float AIOrchestrator::get_ranged_ratio() const {
    if (attack_buffer_count == 0) return 0.5f; // Default to balanced if no data
    
    int ranged_count = 0;
    for (int i = 0; i < attack_buffer_count; i++) {
        if (player_attack_buffer[i] == ATTACK_RANGED) {
            ranged_count++;
        }
    }
    
    return static_cast<float>(ranged_count + 5.0) / (attack_buffer_count + 10.0);
}

// Determine the next enemy state based on various factors
int AIOrchestrator::next_enemy_state(int prev_state, float dist_to_player, float hp, int trait, float chase_range, float attack_range) const {
    // Get attack ratios
    float ranged_ratio = get_ranged_ratio();
    float melee_ratio = get_melee_ratio();
    
    // Base probabilities for different states
    float p_idle = 0.00f;
    float p_wander = 0.00f;
    float p_chase = 0.0f;
    float p_charge = 0.0f;
    float p_spell = 0.0f;
    float p_flee = 0.0f;

    if (hp < 50) {
        p_flee = 1.0f;
        p_charge = 0.0f + (ranged_ratio * 0.1f); // Increase chance of charge if player uses ranged attacks
        p_spell = 0.3f + (melee_ratio * 0.3f);   // Default attack, slightly more likely if player uses melee
    } else if (hp < 25) {
        p_flee = 1.0f;
    } else if (dist_to_player > chase_range) {
        p_wander = 0.45f;
        p_chase = 0.05f;
    } else if (dist_to_player < attack_range) {
        p_charge = 0.0f + (ranged_ratio * 0.4f); // Increase chance of charge if player uses ranged attacks
        p_spell = 0.3f + (melee_ratio * 0.3f);   // Default attack, slightly more likely if player uses melee
    } else {
        // chase
        p_chase = 1.0f;
    }
    
    
    // Normalize probabilities to sum to 1.0
    float total = p_idle + p_wander + p_chase + p_charge + p_spell + p_flee;
    p_idle /= total;
    p_wander /= total;
    p_chase /= total;
    p_charge /= total;
    p_spell /= total;
    p_flee /= total;
    
    // Create a probability table for state selection
    float cumulative_prob = 0.0f;
    float random_val = rng->randf(); // Generate random value between 0 and 1
    
    // State values in order
    const int state_values[] = {IDLE, WANDER, CHASE, CHARGE, SPELL, FLEE};
    const float probs[] = {p_idle, p_wander, p_chase, p_charge, p_spell, p_flee};
    
    // Select state based on probability
    for (int i = 0; i < 6; i++) {
        cumulative_prob += probs[i];
        if (random_val <= cumulative_prob) {
            return state_values[i];
        }
    }
    
    // Fallback (should rarely happen due to normalized probabilities)
    return SPELL;
}