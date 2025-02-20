extends Node2D


var transition_scene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Global.game_first_loadin == true:
		$Player.position.x = Global.player_start_posx
		$Player.position.y = Global.player_start_posy
	else:
		$Player.position.x = Global.player_exit_cliffside_posx
		$Player.position.y = Global.player_exit_cliffside_posy


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	change_scene()


func _on_cliffside_transistion_point_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		Global.transition_scene = true
		Global.current_scene_ = "cliff_side"
		transition_scene = "cliffside"


func _on_cliffside_transistion_point_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		Global.transition_scene = false
		Global.current_scene_ = "cliff_side"
		transition_scene = "cliff_side"
		
func change_scene():
	if Global.transition_scene == true:
		if transition_scene == "cliffside":
			get_tree().change_scene_to_file("res://scenes/cliff_side.tscn")
			Global.game_first_loadin = false
			Global.finish_changescenes("cliffside")
		if transition_scene == "multi_terrain":
			get_tree().change_scene_to_file("res://scenes/multi_terrain.tscn")
			Global.game_first_loadin = false
			Global.finish_changescenes("multi_terrain")
			


func _on_multi_terrain_transition_point_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		Global.transition_scene = true
		transition_scene = "multi_terrain"
		Global.current_scene_ = "multi_terrain"


func _on_multi_terrain_transition_point_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		Global.transition_scene = false
		transition_scene = "multi_terrain"
		Global.current_scene_ = "multi_terrain"
