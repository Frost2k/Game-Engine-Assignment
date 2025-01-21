extends Node2D

var speed: float = 200.0
var block_paths := [
	"res://assets/blocks/Block1.svg",
	"res://assets/blocks/Block2.svg",
	"res://assets/blocks/Block3.svg",
	"res://assets/blocks/Block4.svg"
]

var space_was_pressed: bool = false

# This is our "next" block index (which texture we'll spawn next)
var next_block_index: int = 0

@onready var next_block_display: Sprite2D = $"/root/Main/NextBlockDisplay"


func _ready() -> void:
	randomize()
	
	# Place player near bottom
	var view_rect = get_viewport_rect()
	position = Vector2(view_rect.size.x / 2, view_rect.size.y - 50)
	
	# Pick an initial "next block" to show
	next_block_index = randi() % block_paths.size()
	update_next_block_display()

func _process(delta: float) -> void:
	handle_movement(delta)
	handle_spawning()

func handle_movement(delta: float) -> void:
	var dir = Vector2.ZERO

	if Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1

	translate(dir.normalized() * speed * delta)

	# Optional clamp to screen
	var view_rect = get_viewport_rect()
	var half_width = 32.0
	position.x = clamp(position.x, half_width, view_rect.size.x - half_width)
	position.y = view_rect.size.y - 50

func handle_spawning() -> void:
	var space_pressed = Input.is_physical_key_pressed(KEY_SPACE)
	if space_pressed and not space_was_pressed:
		spawn_block_above_player()
	space_was_pressed = space_pressed

func spawn_block_above_player() -> void:
	# 1) Load the scene
	var block_scene: PackedScene = load("res://block_drop.tscn") as PackedScene
	var block_root = block_scene.instantiate()

	# 2) Add it to the scene
	get_tree().get_current_scene().add_child(block_root)

	# 3) Get child Sprite2D to assign the texture
	var sprite_node = block_root.get_node("Sprite2D") as Sprite2D
	if sprite_node:
		# Pick a random block texture from the array
		var random_index = randi() % block_paths.size()
		var random_path = block_paths[random_index]
		sprite_node.texture = load(random_path)

	# 4) Position above the player
	block_root.global_position = global_position - Vector2(0, 500)

	# Print debugging info
	print("Spawned block at", block_root.global_position, "using sprite node:", sprite_node)

	# Update the next block
	next_block_index = randi() % block_paths.size()
	update_next_block_display()


func update_next_block_display() -> void:
	# Loads the texture corresponding to 'next_block_index'
	var tex_path = block_paths[next_block_index]
	var tex = load(tex_path)
	if next_block_display and tex:
		next_block_display.texture = tex
