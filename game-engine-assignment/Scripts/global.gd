extends Node


var player_current_attack = false

var current_scene_ = "world" #world or cliff_side
var transition_scene = false

var player_exit_cliffside_posx = 199
var player_exit_cliffside_posy = 18
var player_start_posx = 159
var player_start_posy = 127

var game_first_loadin = true

func finish_changescenes(current_scene):
	if transition_scene == true:
		transition_scene = false
		current_scene_ = current_scene
		print("This is in Global: ", current_scene_)
		
