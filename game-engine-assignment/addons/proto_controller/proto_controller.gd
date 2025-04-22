# ProtoController v1.0 by Brackeys - Modified with combat functionality
# CC0 License
# Intended for rapid prototyping of first-person games.

extends CharacterBody3D

@export_group("Pickup Settings")
@export var pickup_radius : float = 2.0
@export var input_pickup : String = "pickup"

@onready var pickup_message: Label = $CanvasLayer/PickMessage # Adjust path as needed
var pickup_message_timer := 0.0
var pickup_message_duration := 1.5  

var item_database = {
	"keyring": {
		"id": "keyring",
		"name": "Keyring",
		"description": "A small loop of keys.",
		"value": 50,
		"icon": null
	},
	"coin_sack": {
		"id": "coin_sack",
		"name": "Coin Sack",
		"description": "A stack of gold coins.",
		"value": 30,
		"icon": null
	},
	"chair": {
		"id": "chair",
		"name": "Wooden Chair",
		"description": "An old wooden chair.",
		"value": 15,
		"icon": null
	},
	"candles": {
		"id": "candles",
		"name": "Candles",
		"description": "A few melted wax candles.",
		"value": 10,
		"icon": null
	}
}

## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = false
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = false

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## Normal speed.
@export var base_speed : float = 7.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we run?
@export var sprint_speed : float = 10.0
## How fast do we freefly?
@export var freefly_speed : float = 25.0

@export_group("Combat")
## Player's maximum health
@export var max_health : float = 100.0
## Player's damage per projectile
@export var projectile_damage : float = 20.0
## Time between shots in seconds
@export var fire_cooldown : float = 0.5
## Projectile scene to instance
@export var projectile_scene : PackedScene = preload("res://scenes/projectile.tscn")

@export_group("Inventory")
## Enable inventory system
@export var has_inventory : bool = true
## Maximum inventory slots
@export var inventory_slots : int = 20
## Input action to toggle inventory
@export var input_inventory : String = "inventory_toggle"

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "move_left"
## Name of Input Action to move Right.
@export var input_right : String = "move_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "move_forward"
## Name of Input Action to move Backward.
@export var input_back : String = "move_backward"
## Name of Input Action to Jump.
@export var input_jump : String = "jump"
## Name of Input Action to Sprint.
@export var input_sprint : String = "sprint"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"
## Name of Input Action to shoot.
@export var input_shoot : String = "shoot"

# Runtime variables
var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var pickedObject

# Combat variables
var health : float = 100.0
var is_dead : bool = false
var can_shoot : bool = true

## IMPORTANT REFERENCES
@onready var head: Node3D = $Head if has_node("Head") else null
@onready var collider: CollisionShape3D = $Collider if has_node("Collider") else null
@onready var projectile_launcher = null
@onready var fire_timer = null 
@onready var health_bar = null
@onready var inventory_system = null

func _ready() -> void:
	# Check if Head exists, create if needed
	if not head:
		head = Node3D.new()
		head.name = "Head"
		add_child(head)
		print("Created missing Head node")
		
	# Check if Collider exists
	if not collider:
		print("Warning: Collider missing")
		
	# Create ProjectileLauncher if it doesn't exist
	if not head.has_node("ProjectileLauncher"):
		# Load the projectile launcher scene
		var launcher_scene = load("res://scenes/projectile_launcher.tscn")
		if launcher_scene:
			projectile_launcher = launcher_scene.instantiate()
		else:
			# Create a basic one if scene not found
			projectile_launcher = Node3D.new()
			projectile_launcher.name = "ProjectileLauncher"
			# Add a timer if needed
			if not projectile_launcher.has_node("Timer"):
				var timer = Timer.new()
				timer.name = "Timer"
				timer.one_shot = true
				projectile_launcher.add_child(timer)
		
		head.add_child(projectile_launcher)
		print("Created ProjectileLauncher in Head node")
	else:
		projectile_launcher = head.get_node("ProjectileLauncher")
		
	# Create FireTimer if it doesn't exist
	if not has_node("FireTimer"):
		fire_timer = Timer.new()
		fire_timer.name = "FireTimer"
		fire_timer.wait_time = fire_cooldown
		fire_timer.one_shot = true
		add_child(fire_timer)
		fire_timer.timeout.connect(_on_fire_timer_timeout)
		print("Created FireTimer node")
	else:
		fire_timer = get_node("FireTimer")
	
	# Create HealthBar if it doesn't exist
	if not has_node("HealthBar"):
		var hb = ProgressBar.new()
		hb.name = "HealthBar"
		hb.max_value = max_health
		hb.value = health
		hb.visible = false
		
		# Add HealthBar to a CanvasLayer for UI
		var canvas_layer = CanvasLayer.new()
		canvas_layer.name = "PlayerUI"
		add_child(canvas_layer)
		
		# Style the health bar
		hb.size = Vector2(200, 30)
		hb.position = Vector2(20, 20)
		canvas_layer.add_child(hb)
		health_bar = hb
		print("Created HealthBar and UI layer")
	else:
		health_bar = get_node("HealthBar")
	
	# Create inventory system if enabled
	if has_inventory:
		setup_inventory()
	
	# Initialize health
	health = max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
	
	# Register with Player group for enemy targeting
	if not is_in_group("Player"):
		add_to_group("Player")
	
	check_input_mappings()
	
	if head:
		look_rotation.y = rotation.y
		look_rotation.x = head.rotation.x
		
func extract_item_data(item: Node) -> Variant:
	# Assuming the item has these exported fields or properties
	if item.has_variable("item_name") and item.has_variable("item_description"):
		return {
			"id": item.get("id") if item.has_variable("id") else "unknown",
			"name": item.item_name,
			"description": item.item_description,
			"value": item.item_value if item.has_variable("item_value") else 0,
			"icon": item.item_icon if item.has_variable("item_icon") else null
		}
	return null
	
func pick_up_item(item: Node):
	var file_name := ""

	if item.has_method("get_scene_file_path"):
		file_name = item.get_scene_file_path().get_file().get_basename().to_lower().strip_edges()
	else:
		file_name = item.name.to_lower().strip_edges()

	print("Trying to pick up: '" + file_name + "'")

	if item_database.has(file_name):
		var item_data = item_database[file_name]
		if add_to_inventory(item_data):
			show_pickup_message("Picked up: " + item_data.name)
			item.queue_free()
		else:
			show_pickup_message("Inventory full! Could not pick up " + item_data.name)
	else:
		print("Item database keys: ", item_database.keys())
		show_pickup_message("Can't pick up: " + file_name)
	
func show_pickup_message(message: String):
	if pickup_message:
		pickup_message.text = message
		pickup_message.visible = true
		pickup_message_timer = pickup_message_duration

func _unhandled_input(event):
	# Default input handling (existing code)
	if is_dead:
		return
		
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()
			
	# Handle shooting
	if Input.is_action_pressed(input_shoot) and can_shoot:
		shoot()
		
	# Toggle inventory
	if has_inventory and Input.is_action_just_pressed(input_inventory):
		toggle_inventory()
	
	# Test: Press T key to take 50 damage
	if event is InputEventKey and event.pressed and event.keycode == KEY_T and not event.is_echo():
		print("TEST: Taking 50 damage")
		take_damage(50.0)
		
	if Input.is_action_just_pressed(input_pickup):
		var items = get_nearby_items()
		if items.size() > 0:
			for item in items:
				pick_up_item(item)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	# If freeflying, handle freefly and nothing else
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return
	
	# Apply gravity to velocity
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta

	# Apply jumping
	if can_jump:
		if Input.is_action_just_pressed(input_jump) and is_on_floor():
			velocity.y = jump_velocity

	# Modify speed based on sprinting
	if can_sprint and Input.is_action_pressed(input_sprint):
			move_speed = sprint_speed
	else:
		move_speed = base_speed

	# Apply desired movement to velocity
	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.y = 0
	
	# Use velocity to actually move
	move_and_slide()

## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)

func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false

func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

## Called when player takes damage
func take_damage(amount):
	if is_dead:
		return
		
	health -= amount
	
	# Update health bar
	if health_bar:
		health_bar.value = health
		health_bar.visible = true
	
	# Play hit animation or flash effect
	# You could add code here to flash the screen red or play a hit sound
	
	print("Player took damage! Health: ", health)
	
	# Check if dead
	if health <= 0:
		die()

## Handle player death
func die():
	is_dead = true
	print("Player died!")
	
	# Death effects, play sound, animation, etc.
	# You could add code here for death animation
	
	# Disable controls
	can_move = false
	can_jump = false
	can_sprint = false
	can_freefly = false
	
	# Implement game over logic
	show_death_menu()

## Show death menu with restart options
func show_death_menu():
	# Create a death menu if it doesn't exist
	if !has_node("PlayerUI") or !get_node("PlayerUI").has_node("DeathMenu"):
		var canvas_layer
		if has_node("PlayerUI"):
			canvas_layer = get_node("PlayerUI")
		else:
			canvas_layer = CanvasLayer.new()
			canvas_layer.name = "PlayerUI"
			add_child(canvas_layer)
			
		# Create the menu container
		var menu = Control.new()
		menu.name = "DeathMenu"
		menu.set_anchors_preset(Control.PRESET_FULL_RECT)
		menu.mouse_filter = Control.MOUSE_FILTER_STOP
		canvas_layer.add_child(menu)
		
		# Dark background overlay
		var overlay = ColorRect.new()
		overlay.name = "DarkOverlay"
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.color = Color(0, 0, 0, 0.7)
		menu.add_child(overlay)
		
		# Death message
		var title = Label.new()
		title.name = "DeathTitle"
		title.text = "YOU DIED"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title.set_anchors_preset(Control.PRESET_CENTER_TOP)
		title.position = Vector2(0, 150)
		title.add_theme_font_size_override("font_size", 64)
		title.add_theme_color_override("font_color", Color(0.8, 0.1, 0.1))
		menu.add_child(title)
		
		# Container for buttons
		var button_container = VBoxContainer.new()
		button_container.name = "ButtonContainer"
		button_container.set_anchors_preset(Control.PRESET_CENTER)
		button_container.position = Vector2(0, 50)
		button_container.custom_minimum_size = Vector2(200, 150)
		# Use theme_override for separation in Godot 4
		button_container.add_theme_constant_override("separation", 20)
		button_container.alignment = BoxContainer.ALIGNMENT_CENTER
		menu.add_child(button_container)
		
		# Restart button
		var restart_button = Button.new()
		restart_button.name = "RestartButton"
		restart_button.text = "RESTART"
		restart_button.custom_minimum_size = Vector2(200, 50)
		restart_button.pressed.connect(self.restart_game)
		button_container.add_child(restart_button)
		
		# Quit button
		var quit_button = Button.new()
		quit_button.name = "QuitButton"
		quit_button.text = "QUIT TO MENU"
		quit_button.custom_minimum_size = Vector2(200, 50)
		quit_button.pressed.connect(self.quit_to_menu)
		button_container.add_child(quit_button)
	
	# Show menu and enable mouse
	get_node("PlayerUI/DeathMenu").visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

## Restart the current game
func restart_game():
	# Hide death menu
	if has_node("PlayerUI") and get_node("PlayerUI").has_node("DeathMenu"):
		get_node("PlayerUI/DeathMenu").visible = false
	
	# Reload current scene
	get_tree().reload_current_scene()

## Quit to the main menu
func quit_to_menu():
	# Return to start menu scene
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")

## Shoot a projectile
func shoot():
	if is_dead or not projectile_launcher:
		return
	
	# If not using a preloaded scene, return
	if not projectile_scene:
		print("No projectile scene assigned!")
		return
	
	# Create the projectile
	var projectile = projectile_scene.instantiate()
	
	# Set its properties if needed
	if projectile.has_method("set_damage"):
		projectile.set_damage(projectile_damage)
	elif "damage" in projectile:
		projectile.damage = projectile_damage
	
	# Add it to the scene at the launcher position
	projectile_launcher.add_child(projectile)
	
	# Set its transform to match the launcher
	projectile.global_transform = projectile_launcher.global_transform
	
	# Start cooldown timer
	can_shoot = false
	if fire_timer:
		fire_timer.start()
	else:
		# If timer doesn't exist for some reason, create a temporary cooldown
		await get_tree().create_timer(fire_cooldown).timeout
		can_shoot = true
	
	print("Player fired projectile!")

## Called when fire cooldown is over
func _on_fire_timer_timeout():
	can_shoot = true

## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false
	if not InputMap.has_action(input_shoot):
		push_error("Shooting disabled. No InputAction found for input_shoot: " + input_shoot)
	
	# Check inventory input
	if has_inventory and not InputMap.has_action(input_inventory):
		push_error("Inventory disabled. No InputAction found for input_inventory: " + input_inventory)
		has_inventory = false

# Setup inventory system
func setup_inventory():
	# Check if we already have an inventory system
	if has_node("InventorySystem"):
		inventory_system = get_node("InventorySystem")
		return
		
	# Try to load the inventory system script
	var inventory_script = load("res://Scripts/inventory_system.gd")
	
	if inventory_script:
		inventory_system = inventory_script.new()
		inventory_system.name = "InventorySystem"
		inventory_system.max_slots = inventory_slots
		add_child(inventory_system)
		print("Created inventory system with " + str(inventory_slots) + " slots")
	else:
		print("ERROR: Could not load inventory system script!")

# Toggle inventory visibility
func toggle_inventory():
	if inventory_system:
		inventory_system.toggle_inventory()

# Function to add an item to the inventory
# Used by gem pickup system
func add_to_inventory(item):
	if inventory_system:
		return inventory_system.add_to_inventory(item)
	return false

# Function to drop an item from inventory into the world
func drop_item_from_inventory(item, index):
	# If this is a gem, spawn it in the world
	if item.id == "magic_gem":
		var gem_scene = load("res://scenes/magic_gem.tscn")
		if gem_scene:
			var gem = gem_scene.instantiate()
			
			# Copy item data to the gem
			gem.item_name = item.name
			gem.item_description = item.description
			gem.item_value = item.value
			gem.item_icon = item.icon
			
			# Position the gem in front of the player
			var spawn_pos = global_position + head.global_transform.basis.z * -2
			spawn_pos.y = global_position.y + 1
			gem.global_position = spawn_pos
			
			# Add to scene
			get_tree().current_scene.add_child(gem)
			print("Dropped " + item.name + " from inventory")
			
			return true
	
	return false
	
func get_nearby_items() -> Array:
	var nearby_items = []
	var space_state = get_world_3d().direct_space_state
	
	# Create a small sphere shape for the detection radius
	var sphere := SphereShape3D.new()
	sphere.radius = pickup_radius
	
	# Use the shape in a PhysicsShapeQuery3D
	var shape_query := PhysicsShapeQueryParameters3D.new()
	shape_query.shape = sphere
	shape_query.transform = Transform3D(Basis(), global_transform.origin)
	shape_query.collide_with_areas = true
	shape_query.collision_mask = 1  # Adjust if you use layers
	
	var result = space_state.intersect_shape(shape_query, 10)

	for hit in result:
		var obj = hit.get("collider")
		if obj and obj.is_in_group("pickup_items"):
			nearby_items.append(obj)

	return nearby_items
	
func _process(delta):
	if pickup_message.visible:
		pickup_message_timer -= delta
		if pickup_message_timer <= 0:
			pickup_message.visible = false

	
