#include "minimap3d.h"
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/engine.hpp>

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
}


/* ------------ life‑cycle ------------ */
void MiniMap3D::_ready() {
    /* Create the SubViewport that actually renders the world */
    mini_vp = memnew(SubViewport);

#if GODOT_VERSION_MINOR >= 2
    mini_vp->set_update_mode(SubViewport::UpdateMode::UPDATE_ONCE);
#endif
    mini_vp->set_disable_3d(false);
    

    /* Size match this container */
    mini_vp->set("size", Vector2i(get_size()));
    add_child(mini_vp);

    /* Create a top‑down orthographic Camera3D */
    cam = memnew(Camera3D);
    cam->set_projection(Camera3D::ProjectionType::PROJECTION_ORTHOGONAL);
    cam->set_cull_mask(0xFFFFFFFF);          // render everything
    cam->set_current(true);
    // cam->set_orthogonal_size(ortho_size);
    cam->set("size", ortho_size);

    mini_vp->add_child(cam);

    if (player_color == Color()) player_color = Color(0.2,0.5,1,1);
    if (enemy_color  == Color()) enemy_color  = Color(1,0.2,0.2,1);
    if (enemy_group.is_empty())  enemy_group  = "Enemy";

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

    Vector3 target_pos = static_cast<Node3D *>(n)->get_global_position();
    target_pos.x = CLAMP(target_pos.x, world_min.x, world_max.x);
    target_pos.z = CLAMP(target_pos.z, world_min.z, world_max.z);

    cam->set_global_position(Vector3(target_pos.x, cam_height, target_pos.z));
    cam->look_at(target_pos, Vector3(0, 0, -1));
    cam->set("size", ortho_size); 
    
    #if GODOT_VERSION_MINOR >= 2
        mini_vp->set_update_mode(SubViewport::UpdateMode::UPDATE_ONCE);
    #endif
    queue_redraw();          // (not update())


}

void MiniMap3D::_draw() {
    if (!cam) return;

    /* --- player dot --- */
    if (Node3D *p = Object::cast_to<Node3D>(get_node_or_null(player_path))) {
        draw_circle(_world_to_map(p->get_global_position()),
                    dot_radius, player_color);
    }

    /* --- enemies dot --- */
    Array list = get_tree()->get_nodes_in_group(enemy_group);
    for (int i = 0; i < list.size(); ++i) {
        Node3D *e = Object::cast_to<Node3D>(list[i]);
        if (!e) continue;
        draw_circle(_world_to_map(e->get_global_position()),
                    dot_radius, enemy_color);
    }
}

/* helper: convert world 3‑D position to 2‑D SubViewport coords */
Vector2 MiniMap3D::_world_to_map(const Vector3 &world_pos) const {
    Vector3 cam_pos = cam->get_global_position();

    /* offset in X‑Z plane relative to camera */
    float dx = (world_pos.x - cam_pos.x);
    float dz = (world_pos.z - cam_pos.z);  // +Z = south

    float half = ortho_size;               // world units half‑extent
    if (half == 0) half = 1.0f;            // avoid div‑by‑zero

    /* normalised −1..1 range */
    Vector2 norm(dx / half, dz / half);

    /* convert to viewport pixels */
    Vector2 vp_size = mini_vp->get_visible_rect().size;
    return vp_size * 0.5 + Vector2(norm.x, -norm.y) * (vp_size * 0.5);
}



