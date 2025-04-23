extends Control
const PORT := 7777 
# Path to the main game scene
@export var main_game_scene: String = "res://scenes/main.tscn"
@export var port:int      = 7777
@export var server_ip:String = "192.168.0.42" 
func _ready():
	# Show mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Add visual effects
	add_menu_effects()


func _on_host_pressed() -> void:
	var peer := ENetMultiplayerPeer.new()
	if peer.create_server(port, 2) != OK:
		push_error("Couldn’t start server")
		return
	multiplayer.multiplayer_peer = peer
	_enter_game()

func _on_join_pressed() -> void:
	var peer := ENetMultiplayerPeer.new()
	if peer.create_client(server_ip, port) != OK:
		push_error("Couldn’t connect to host at %s" % server_ip)
		return
	multiplayer.multiplayer_peer = peer
	_enter_game()


func _on_quit_button_pressed():
	# Quit the game
	get_tree().quit()
	
	

func add_menu_effects():
	# Add some visual effects to make the menu more dynamic
	
	# Subtle title animation
	var title_tween = create_tween().set_loops()
	title_tween.tween_property($Title, "theme_override_colors/font_color", 
		Color(0.9, 0.15, 0.15, 1.0), 2.0)
	title_tween.tween_property($Title, "theme_override_colors/font_color", 
		Color(0.7, 0.1, 0.1, 1.0), 2.0)
	
	# Background animation (optional)
	var bg_tween = create_tween().set_loops()
	bg_tween.tween_property($Background, "color", 
		Color(0.13, 0.08, 0.18, 1.0), 3.0)
	bg_tween.tween_property($Background, "color", 
		Color(0.10, 0.06, 0.15, 1.0), 3.0) 
		
func _enter_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
