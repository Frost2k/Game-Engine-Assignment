extends Node2D

var block_paths := [
	"res://assets/blocks/Block1.svg",
	"res://assets/blocks/Block2.svg",
	"res://assets/blocks/Block3.svg",
	"res://assets/blocks/Block4.svg"
]

var space_was_pressed: bool = false
var next_block_index: int = 0

@onready var next_block_display: Sprite2D = $"/root/Main/NextBlockDisplay"

func _ready() -> void:
	randomize()
	next_block_index = randi() % block_paths.size()
	update_next_block_display()

func _process(delta: float) -> void:
	handle_spawning()

func handle_spawning() -> void:
	# Raw check for space bar 
	var space_pressed = Input.is_physical_key_pressed(KEY_SPACE)
	# "just pressed" logic
	if space_pressed and not space_was_pressed:
		spawn_block_above_player()
	space_was_pressed = space_pressed

func spawn_block_above_player() -> void:
	# 1) Load the block scene (or create a new sprite if desired)
	var block_scene: PackedScene = load("res://block_drop.tscn") as PackedScene
	var block_root = block_scene.instantiate()

	# 2) Add to the scene
	get_tree().get_current_scene().add_child(block_root)

	# 3) Optionally pick a random texture from block_paths
	var sprite_node = block_root.get_node("Sprite2D") as Sprite2D
	if sprite_node:
		var random_index = randi() % block_paths.size()
		var random_path = block_paths[random_index]
		sprite_node.texture = load(random_path)

	# 4) Position the block above the "player" node
	#    If your player node is a sibling, do: get_node("../Player").global_position
	#    Or store a reference to the player if needed
	var player = get_node("/root/Main/PlayerNode/KeyInput") # adjust path
	if player:
		block_root.global_position = player.global_position - Vector2(0, 150)

	print("Spawned block at", block_root.global_position, "with random texture")

	# Update the "next block" display
	next_block_index = randi() % block_paths.size()
	update_next_block_display()

func update_next_block_display() -> void:
	var tex_path = block_paths[next_block_index]
	var tex = load(tex_path)
	if next_block_display and tex:
		next_block_display.texture = tex
