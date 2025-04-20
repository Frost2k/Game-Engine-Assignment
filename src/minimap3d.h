#ifndef MINIMAP3D_H
#define MINIMAP3D_H

#include <godot_cpp/classes/sub_viewport_container.hpp>
#include <godot_cpp/classes/sub_viewport.hpp>
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/core/binder_common.hpp>
#include <godot_cpp/core/version.hpp>
#include <godot_cpp/variant/color.hpp> 
#include <godot_cpp/classes/scene_tree.hpp>

namespace godot {

class MiniMap3D : public SubViewportContainer {
    GDCLASS(MiniMap3D, SubViewportContainer);

    /* Inspector‑exposed */
    NodePath player_path;              // player to follow
    float    cam_height   = 30.0f;     // Y offset above player
    float    ortho_size   = 50.0f;     // orthographic half‑extents
    Vector3  world_min    = Vector3(-999, -999, -999);
    Vector3  world_max    = Vector3( 999,  999,  999);

    String enemy_group   = "Enemy";                 // group name to query
    Color  player_color  = Color(0.2, 0.5, 1.0, 1); // blue
    Color  enemy_color   = Color(1.0, 0.2, 0.2, 1); // red
    float  dot_radius    = 4.0f;

    /* Runtime */
    SubViewport *mini_vp = nullptr;
    Camera3D    *cam     = nullptr;

protected:
    static void _bind_methods();
    void _notification(int p_what);

public:
    void _ready() override;
    void _process(double delta) override;

    /* setters / getters */
    void set_player_path(const NodePath &p) { player_path = p; }
    NodePath get_player_path() const        { return player_path; }

    void set_cam_height(float h) { cam_height = h; }
    float get_cam_height() const { return cam_height; }

    void set_ortho_size(float s) { ortho_size = s; }
    float get_ortho_size() const { return ortho_size; }

    void set_world_min(Vector3 v) { world_min = v; }
    Vector3 get_world_min() const { return world_min; }

    void set_world_max(Vector3 v) { world_max = v; }
    Vector3 get_world_max() const { return world_max; }

    /* color + group accessors */
    void set_player_color(Color c) { player_color = c; }
    Color get_player_color() const { return player_color; }

    void set_enemy_color(Color c)  { enemy_color = c; }
    Color get_enemy_color() const  { return enemy_color; }

    void set_enemy_group(String g) { enemy_group = g; }
    String get_enemy_group() const { return enemy_group; }

     void _draw() override;   

private:
    Vector2 _world_to_map(const Vector3 &world_pos) const;

};

} // namespace godot
#endif
