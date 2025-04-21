#include "minimap3d.h"
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/scene_tree.hpp>

using namespace godot;

/* ------------ binding ------------ */
void MiniMap3D::_bind_methods() {
    /* ------------ player_path ------------ */
    ClassDB::bind_method(D_METHOD("set_player_path", "p_path"),
                         &MiniMap3D::set_player_path);
    ClassDB::bind_method(D_METHOD("get_player_path"),
                         &MiniMap3D::get_player_path);
    ADD_PROPERTY(PropertyInfo(Variant::NODE_PATH, "player_path",
                              PROPERTY_HINT_NODE_PATH_VALID_TYPES, "Node3D"),
                 "set_player_path", "get_player_path");

    /* ------------ cam_height ------------ */
    ClassDB::bind_method(D_METHOD("set_cam_height", "val"),
                         &MiniMap3D::set_cam_height);
    ClassDB::bind_method(D_METHOD("get_cam_height"),
                         &MiniMap3D::get_cam_height);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "cam_height",
                              PROPERTY_HINT_RANGE, "1,1000,0.1,or_greater"),
                 "set_cam_height", "get_cam_height");

    /* ------------ ortho_size ------------ */
    ClassDB::bind_method(D_METHOD("set_ortho_size", "val"),
                         &MiniMap3D::set_ortho_size);
    ClassDB::bind_method(D_METHOD("get_ortho_size"),
                         &MiniMap3D::get_ortho_size);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "ortho_size",
                              PROPERTY_HINT_RANGE, "1,500,0.1,or_greater"),
                 "set_ortho_size", "get_ortho_size");

    /* ------------ world_min ------------ */
    ClassDB::bind_method(D_METHOD("set_world_min", "val"),
                         &MiniMap3D::set_world_min);
    ClassDB::bind_method(D_METHOD("get_world_min"),
                         &MiniMap3D::get_world_min);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "world_min"),
                 "set_world_min", "get_world_min");

    /* ------------ world_max ------------ */
    ClassDB::bind_method(D_METHOD("set_world_max", "val"),
                         &MiniMap3D::set_world_max);
    ClassDB::bind_method(D_METHOD("get_world_max"),
                         &MiniMap3D::get_world_max);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "world_max"),
                 "set_world_max", "get_world_max");

    /* ------------ colours & group ------------ */
    ClassDB::bind_method(D_METHOD("set_player_color", "val"),
    &MiniMap3D::set_player_color);
    ClassDB::bind_method(D_METHOD("get_player_color"),
    &MiniMap3D::get_player_color);
    ADD_PROPERTY(PropertyInfo(Variant::COLOR, "player_color"),
    "set_player_color", "get_player_color");

    ClassDB::bind_method(D_METHOD("set_enemy_color", "val"),
    &MiniMap3D::set_enemy_color);
    ClassDB::bind_method(D_METHOD("get_enemy_color"),
    &MiniMap3D::get_enemy_color);
    ADD_PROPERTY(PropertyInfo(Variant::COLOR, "enemy_color"),
    "set_enemy_color", "get_enemy_color");

    ClassDB::bind_method(D_METHOD("set_enemy_group", "val"),
    &MiniMap3D::set_enemy_group);
    ClassDB::bind_method(D_METHOD("get_enemy_group"),
    &MiniMap3D::get_enemy_group);
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "enemy_group"),
    "set_enemy_group", "get_enemy_group");

    /* ------------ dot radius ------------ */
    ClassDB::bind_method(D_METHOD("set_dot_radius", "val"),
    &MiniMap3D::set_dot_radius);
    ClassDB::bind_method(D_METHOD("get_dot_radius"),
    &MiniMap3D::get_dot_radius);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "dot_radius",
                             PROPERTY_HINT_RANGE, "1,20,0.1,or_greater"),
    "set_dot_radius", "get_dot_radius");

    /* ------------ enemy dot radius ------------ */
    ClassDB::bind_method(D_METHOD("set_enemy_dot_radius", "val"),
    &MiniMap3D::set_enemy_dot_radius);
    ClassDB::bind_method(D_METHOD("get_enemy_dot_radius"),
    &MiniMap3D::get_enemy_dot_radius);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "enemy_dot_radius",
                             PROPERTY_HINT_RANGE, "1,20,0.1,or_greater"),
    "set_enemy_dot_radius", "get_enemy_dot_radius");

    /* ------------ enemy glow ------------ */
    ClassDB::bind_method(D_METHOD("set_enemy_glow", "val"),
    &MiniMap3D::set_enemy_glow);
    ClassDB::bind_method(D_METHOD("get_enemy_glow"),
    &MiniMap3D::get_enemy_glow);
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "enemy_glow"),
    "set_enemy_glow", "get_enemy_glow");

    /* ------------ glow size ------------ */
    ClassDB::bind_method(D_METHOD("set_glow_size", "val"),
    &MiniMap3D::set_glow_size);
    ClassDB::bind_method(D_METHOD("get_glow_size"),
    &MiniMap3D::get_glow_size);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "glow_size",
                             PROPERTY_HINT_RANGE, "1,10,0.1,or_greater"),
    "set_glow_size", "get_glow_size");
}


/* ------------ life‑cycle ------------ */
void MiniMap3D::_ready() {
    /* Create the SubViewport that actually renders the world */
    mini_vp = memnew(SubViewport);

#if GODOT_VERSION_MINOR >= 2
    mini_vp->set_update_mode(SubViewport::UpdateMode::UPDATE_ALWAYS);
#endif
    mini_vp->set_disable_3d(false);
    
    // Set basic viewport properties - only use supported methods
    mini_vp->set_clear_mode(SubViewport::CLEAR_MODE_ALWAYS);
    
    /* Size match this container */
    mini_vp->set("size", Vector2i(get_size()));
    add_child(mini_vp);

    /* Create a top‑down orthographic Camera3D */
    cam = memnew(Camera3D);
    cam->set_projection(Camera3D::ProjectionType::PROJECTION_ORTHOGONAL);
    cam->set_cull_mask(0xFFFFFFFF);          // render everything
    cam->set_current(true);
    cam->set("size", ortho_size);
    cam->set_far(1000.0);
    cam->set_v_offset(0.0);
    cam->set_h_offset(0.0);

    mini_vp->add_child(cam);

    if (player_color == Color()) player_color = Color(0.2,0.5,1,1);
    if (enemy_color  == Color()) enemy_color  = Color(1,0.2,0.2,1);
    if (enemy_group.is_empty())  enemy_group  = "Enemy";
    
    // Print debug information when running in game mode
    if (!Engine::get_singleton()->is_editor_hint()) {
        // Delayed initialization to allow enemy nodes to register first
        call_deferred("_debug_enemy_groups");
    }
}

void MiniMap3D::_notification(int what) {
    if (what == NOTIFICATION_RESIZED && mini_vp) {
        mini_vp->set("size", Vector2i(get_size()));
    }
}

/* ------------ per‑frame ------------ */
void MiniMap3D::_process(double) {
    if (Engine::get_singleton()->is_editor_hint()) return;

    Node *n = get_node_or_null(player_path);
    if (!n || !cam) return;

    // Get current player position
    Vector3 player_pos = static_cast<Node3D *>(n)->get_global_position();
    
    // Clamp player position to world bounds
    player_pos.x = CLAMP(player_pos.x, world_min.x, world_max.x);
    player_pos.z = CLAMP(player_pos.z, world_min.z, world_max.z);

    // Position camera above player looking down
    Vector3 cam_pos = Vector3(player_pos.x, player_pos.y + cam_height, player_pos.z);
    cam->set_global_position(cam_pos);
    
    // Look directly down at player position
    cam->look_at(player_pos, Vector3(0, 0, -1));
    
    // Set orthographic size
    cam->set("size", ortho_size); 
    
    // Make sure viewport updates
#if GODOT_VERSION_MINOR >= 2
    mini_vp->set_update_mode(SubViewport::UpdateMode::UPDATE_ALWAYS);
#endif

    // Queue redraw of the minimap
    queue_redraw();
}

void MiniMap3D::_draw() {
    if (!cam) return;

    // Get player
    Node3D* player = Object::cast_to<Node3D>(get_node_or_null(player_path));
    if (!player) return;
    
    // Get player position
    Vector3 player_pos = player->get_global_position();
    
    // Debug player position periodically
    if (get_tree()->get_frame() % 60 == 0) {
        UtilityFunctions::print("Player position: (", player_pos.x, ", ", player_pos.y, ", ", player_pos.z, ")");
    }
    
    // Size of the viewport
    Vector2 viewport_size = mini_vp->get_visible_rect().size;
    Vector2 center = viewport_size * 0.5f;
    
    // Draw minimap background
    draw_rect(Rect2(Vector2(0, 0), viewport_size), Color(0.1, 0.1, 0.1, 0.5), true);
    
    // Draw minimap grid (for reference)
    Color grid_color = Color(0.3, 0.3, 0.3, 0.5);
    float grid_step = viewport_size.x / 10.0f;
    for (int i = 0; i <= 10; i++) {
        // Vertical lines
        draw_line(Vector2(i * grid_step, 0), Vector2(i * grid_step, viewport_size.y), grid_color);
        // Horizontal lines
        draw_line(Vector2(0, i * grid_step), Vector2(viewport_size.x, i * grid_step), grid_color);
    }
    
    // Draw coordinate axes for reference
    // X axis (left/right) - red
    draw_line(Vector2(center.x - 20, center.y), Vector2(center.x + 20, center.y), Color(0.8, 0.2, 0.2, 0.7), 2.0);
    // Z axis (forward/backward) - blue
    draw_line(Vector2(center.x, center.y - 20), Vector2(center.x, center.y + 20), Color(0.2, 0.2, 0.8, 0.7), 2.0);
    
    // Add coordinate labels
    draw_circle(Vector2(center.x + 20, center.y), 3.0, Color(0.8, 0.2, 0.2, 0.7)); // +X
    draw_circle(Vector2(center.x, center.y + 20), 3.0, Color(0.2, 0.2, 0.8, 0.7)); // +Z
    
    // Draw player at center
    draw_circle(center, dot_radius * 1.2f, Color(1, 1, 1, 0.5)); // White outline
    draw_circle(center, dot_radius, player_color);
    
    // Scale for converting world distances to minimap distances
    float scale = viewport_size.x / (ortho_size );
    
    // Get all enemies in the Enemy group
    Array enemies = get_tree()->get_nodes_in_group(enemy_group);
    
    // Debug enemy count periodically
    if (get_tree()->get_frame() % 60 == 0) {
        UtilityFunctions::print("Found ", enemies.size(), " enemies in group '", enemy_group, "'");
        
        // If no enemies found, try to scan for them
        if (enemies.size() == 0) {
            Node* root_node = get_tree()->get_current_scene();
            if (root_node) {
                _scan_for_enemies(root_node, 0);
                enemies = get_tree()->get_nodes_in_group(enemy_group);
                UtilityFunctions::print("After scan: Found ", enemies.size(), " enemies in group '", enemy_group, "'");
            }
        }
    }
    
    // Draw each enemy
    for (int i = 0; i < enemies.size(); ++i) {
        Node3D* enemy = Object::cast_to<Node3D>(enemies[i]);
        if (!enemy) continue;
        
        // Get enemy position
        Vector3 enemy_pos = enemy->get_global_position();
        
        // Calculate offset from player (in world coordinates)
        Vector3 enemy_offset = enemy_pos - player_pos;
        
        // Map world coordinates to minimap:
        // - X (left/right) maps to minimap X
        // - Z (forward/backward) maps to minimap Y
        // - Y (up/down) is ignored for 2D representation
        Vector2 enemy_minimap_offset = Vector2(enemy_offset.x, enemy_offset.z) * scale;
        
        // Position on minimap (player at center + offset)
        Vector2 enemy_minimap_pos = center + enemy_minimap_offset;
        
        // Debug enemy positions periodically
        if (get_tree()->get_frame() % 120 == 0) {
            UtilityFunctions::print("Enemy ", i, ": ", enemy->get_name(), " at position (", 
                            enemy_pos.x, " (left/right), ", enemy_pos.y, " (up/down), ", enemy_pos.z, " (forward/backward))");
            UtilityFunctions::print("  Offset from player: X=", enemy_offset.x, " (left/right), Z=", enemy_offset.z, " (forward/backward)");
            UtilityFunctions::print("  Minimap position: (", enemy_minimap_pos.x, ", ", enemy_minimap_pos.y, ")");
        }
        
        // Check if in viewport bounds
        if (enemy_minimap_pos.x >= 0 && enemy_minimap_pos.x <= viewport_size.x && 
            enemy_minimap_pos.y >= 0 && enemy_minimap_pos.y <= viewport_size.y) {
            
            // Draw line connecting player to enemy for better visualization
            draw_line(center, enemy_minimap_pos, Color(0.5, 0.5, 0.5, 0.3), 1.0);
            
            // Draw glow effect
            if (enemy_glow) {
                Color glow_color = enemy_color;
                glow_color.a = 0.3f;
                draw_circle(enemy_minimap_pos, enemy_dot_radius * glow_size, glow_color);
                
                glow_color.a = 0.5f;
                draw_circle(enemy_minimap_pos, enemy_dot_radius * (glow_size * 0.7f), glow_color);
            }
            
            // Draw enemy with different shapes based on index
            if (i == 0) {
                // First enemy as circle
                draw_circle(enemy_minimap_pos, enemy_dot_radius * 1.2f, Color(1, 1, 1, 0.5)); // White outline
                draw_circle(enemy_minimap_pos, enemy_dot_radius, enemy_color);
            } 
            else if (i == 1) {
                // Second enemy as diamond
                float size = enemy_dot_radius * 1.5f;
                PackedVector2Array points;
                points.push_back(Vector2(enemy_minimap_pos.x, enemy_minimap_pos.y - size));      // Top
                points.push_back(Vector2(enemy_minimap_pos.x + size, enemy_minimap_pos.y));      // Right
                points.push_back(Vector2(enemy_minimap_pos.x, enemy_minimap_pos.y + size));      // Bottom
                points.push_back(Vector2(enemy_minimap_pos.x - size, enemy_minimap_pos.y));      // Left
                
                // White outline
                Color outline_color = Color(1, 1, 1, 0.5);
                draw_colored_polygon(points, outline_color);
                
                // Scale down for inner shape
                size *= 0.8f;
                PackedVector2Array inner_points;
                inner_points.push_back(Vector2(enemy_minimap_pos.x, enemy_minimap_pos.y - size));
                inner_points.push_back(Vector2(enemy_minimap_pos.x + size, enemy_minimap_pos.y));
                inner_points.push_back(Vector2(enemy_minimap_pos.x, enemy_minimap_pos.y + size));
                inner_points.push_back(Vector2(enemy_minimap_pos.x - size, enemy_minimap_pos.y));
                draw_colored_polygon(inner_points, enemy_color);
            }
            else {
                // Other enemies as squares
                float size = enemy_dot_radius * 1.0f;
                draw_rect(Rect2(enemy_minimap_pos.x - size, enemy_minimap_pos.y - size, size * 2, size * 2), 
                        Color(1, 1, 1, 0.5), true); // White outline
                
                // Inner square
                float inner_size = size * 0.8f;
                draw_rect(Rect2(enemy_minimap_pos.x - inner_size, enemy_minimap_pos.y - inner_size, inner_size * 2, inner_size * 2), 
                        enemy_color, true);
            }
        }
    }
    
    // Draw border
    draw_rect(Rect2(Vector2(0, 0), viewport_size), Color(0.2, 0.2, 0.2, 0.7), false, 2.0);
}

/* helper: convert world 3‑D position to 2‑D SubViewport coords */
Vector2 MiniMap3D::_world_to_map(const Vector3 &world_pos) const {
    if (!cam) return Vector2();
    
    Node *n = get_node_or_null(player_path);
    if (!n) return Vector2();
    
    // Get player position
    Vector3 player_pos = static_cast<Node3D *>(n)->get_global_position();
    
    // Get viewport size and calculate center
    Vector2 vp_size = mini_vp->get_visible_rect().size;
    Vector2 center = vp_size * 0.5f;
    
    // Calculate world space offset from player to target position
    float offset_x = world_pos.x - player_pos.x;
    float offset_z = world_pos.z - player_pos.z;
    
    // Scale by minimap size factor (viewport size / world size)
    float scale = vp_size.x / (2.0f * ortho_size);
    
    // Apply scale and negate Z for Y (world Z+ is "forward", screen Y+ is "down")
    float screen_offset_x = offset_x * scale;
    float screen_offset_y = -offset_z * scale;
    
    // Return center point + offset
    return center + Vector2(screen_offset_x, screen_offset_y);
}

// Debug method to verify enemy groups
void MiniMap3D::_debug_enemy_groups() {
    if (Engine::get_singleton()->is_editor_hint()) return;
    
    // Debug output to help identify issues
    Array list = get_tree()->get_nodes_in_group(enemy_group);
    
    // Try alternative group names if none found in specified group
    if (list.size() == 0) {
        UtilityFunctions::print("MiniMap3D: No enemies found in group '", enemy_group, "'. Trying alternatives...");
        
        // List of possible enemy group names to try
        const char* possible_groups[] = {"Enemies", "enemy", "enemies", "Monster", "Monsters", "monster", "monsters"};
        
        for (const char* group : possible_groups) {
            Array test_list = get_tree()->get_nodes_in_group(group);
            if (test_list.size() > 0) {
                UtilityFunctions::print("Found ", test_list.size(), " enemies in alternative group: '", group, "'");
                enemy_group = group; // Update to use this group
                list = test_list;
                break;
            }
        }
    }
    
    UtilityFunctions::print("MiniMap3D: Found ", list.size(), " enemies in group '", enemy_group, "'");
    
    // Manually add skeleton_mage nodes if they're not in the group
    Node* root_node = get_tree()->get_current_scene();
    if (root_node) {
        _scan_for_enemies(root_node, 0);
        
        // Get the updated list
        list = get_tree()->get_nodes_in_group(enemy_group);
        UtilityFunctions::print("After scan: Found ", list.size(), " enemies in group '", enemy_group, "'");
    }
    
    // List detailed information about each enemy
    for (int i = 0; i < list.size(); ++i) {
        Node *node = Object::cast_to<Node>(list[i]);
        if (node) {
            Node3D *enemy = Object::cast_to<Node3D>(node);
            if (enemy) {
                Vector3 pos = enemy->get_global_position();
                UtilityFunctions::print("Enemy ", i, ": ", node->get_name(), " at position (", 
                                        pos.x, ", ", pos.y, ", ", pos.z, ")");
            } else {
                UtilityFunctions::print("Enemy ", i, ": ", node->get_name(), " (not a Node3D)");
            }
        }
    }
    
    // Check if our player exists
    Node *player = get_node_or_null(player_path);
    if (player) {
        Node3D *player3D = Object::cast_to<Node3D>(player);
        if (player3D) {
            Vector3 pos = player3D->get_global_position();
            UtilityFunctions::print("Found player at path: ", player_path, " at position (", 
                                    pos.x, ", ", pos.y, ", ", pos.z, ")");
        } else {
            UtilityFunctions::print("Found player at path: ", player_path, " (not a Node3D)");
        }
    } else {
        UtilityFunctions::print("WARNING: Player not found at path: ", player_path);
    }
}

// Helper method to scan the scene tree for enemy-like nodes
void MiniMap3D::_scan_for_enemies(Node* node, int depth) {
    if (!node) return;
    
    // Check if the current node might be an enemy based on name patterns
    String name = node->get_name().to_lower();
    if ((name.contains("enemy") || name.contains("monster") || name.contains("skeleton") || 
         name.contains("zombie") || name.contains("boss") || name.contains("mage")) && 
        Object::cast_to<Node3D>(node)) {
        
        Node3D* potential_enemy = Object::cast_to<Node3D>(node);
        Vector3 pos = potential_enemy->get_global_position();
        
        UtilityFunctions::print("  [Potential enemy found] ", node->get_path(), " at (", 
                                pos.x, ", ", pos.y, ", ", pos.z, ")");
        
        // Check for parent transforms that might affect positioning
        Node* parent = potential_enemy->get_parent();
        if (parent && Object::cast_to<Node3D>(parent)) {
            Node3D* parent3D = Object::cast_to<Node3D>(parent);
            Vector3 parent_pos = parent3D->get_global_position();
            UtilityFunctions::print("    Parent: ", parent->get_name(), " at (", 
                                   parent_pos.x, ", ", parent_pos.y, ", ", parent_pos.z, ")");
            
            // Check if there's a significant transform offset
            Vector3 local_pos = potential_enemy->get_position();
            UtilityFunctions::print("    Local position: (", 
                                   local_pos.x, ", ", local_pos.y, ", ", local_pos.z, ")");
        }
        
        // Add this to our enemy group automatically
        node->add_to_group(enemy_group);
    }
    
    // Only go a few levels deep to avoid excessive output
    if (depth < 6) {
        for (int i = 0; i < node->get_child_count(); i++) {
            _scan_for_enemies(node->get_child(i), depth + 1);
        }
    }
}



