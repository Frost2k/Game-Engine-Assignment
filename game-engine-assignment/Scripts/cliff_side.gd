extends Node2D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	change_scenes()


func _on_cliffside_exitpoint_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		Global.transition_scene = true
		Global.current_scene_ = "world"


func _on_cliffside_exitpoint_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		Global.transition_scene = false
		
func change_scenes():
	if Global.transition_scene == true:
		if Global.current_scene_ == "world":
			get_tree().change_scene_to_file("res://scenes/world.tscn")
			Global.current_scene_ == "world"
			Global.finish_changescenes("world")
