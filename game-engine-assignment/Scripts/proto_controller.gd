extends CharacterBody3D

# Movement Capabilities
@export_category("Movement")
@export var can_move: bool = true
@export var can_jump: bool = true
@export var can_sprint: bool = true
@export var can_crouch: bool = true
@export var sprint_ui: bool = true
@export var gravity_modifier: float = 1.0
@export var gravity_accelerator: float = 0.1
@export var forward_speed: float = 5.0
@export var sprinting_speed_multiplier: float = 1.5
@export var side_speed_multiplier: float = 0.75
@export var backward_speed_multiplier: float = 0.5
@export var jump_strength: float = 8.0
@export var sprint_cost: float = 1
@export var sprint_restore: float = 0.5

# Combat
@export_category("Combat")
@export var max_health: float = 100.0
@export var projectile_damage: float = 10.0
@export var projectile_fire_rate: float = 0.5  # Seconds between shots
@export var projectile_speed: float = 20.0
@export var max_projectile_delta: float = 10.0
@export var crosshair_ui: bool = true

# Inventory
@export_category("Inventory")
@export var inventory_size: int = 20
@export var gem_pickup_sound: AudioStream

# Input Actions
@export_category("Input Actions")
@export var input_left: String = "move_left"
@export var input_right: String = "move_right"
@export var input_forward: String = "move_forward"
@export var input_backward: String = "move_backward"
@export var input_jump: String = "jump"
@export var input_sprint: String = "sprint"
@export var input_crouch: String = "crouch"
@export var input_shoot: String = "shoot"
@export var input_inventory: String = "inventory_toggle"
@export var input_interact: String = "interact"

# Runtime Variables
var cur_speed_multiplier: float = 1.0
var cur_speed: float = forward_speed
var cur_height: float = 0.0
var crouch_height: float = 0.5
var is_sprinting: bool = false
var is_jumping: bool = false
var is_crouching: bool = false
var sprint_meter: float = 100.0

var projectile_launcher
var fire_timer

# Health
var current_health: float = 100.0
var health_bar

# Inventory system
var inventory_system
var pickup_range: float = 2.5
var interactable_items = []

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Initialize the launcher position if needed
	if !$Head.has_node("ProjectileLauncher"):
		var launch_position = Marker3D.new()
		launch_position.name = "ProjectileLauncher"
		$Head.add_child(launch_position)
		
		# Position it slightly in front of the camera/head
		launch_position.transform.origin = Vector3(0, 0, -1)
	
	projectile_launcher = $Head/ProjectileLauncher
	
	# Create fire timer if it doesn't exist
	if !has_node("FireTimer"):
		fire_timer = Timer.new()
		fire_timer.name = "FireTimer"
		fire_timer.one_shot = true
		add_child(fire_timer)
	else:
		fire_timer = $FireTimer
		
	# Add to Player group
	if not is_in_group("Player"):
		add_to_group("Player")
	
	# Set up inventory system
	setup_inventory()
	
	# Setup health UI with fancy style
	setup_stylish_health_ui()
	
	# Initialize health
	current_health = max_health
	update_health_ui()
	
	# Force health UI to appear by calling update
	if health_bar:
		health_bar.value = current_health
		
	# Set up gems UI
	setup_gems_ui()
		
	# Set up input actions
	ensure_input_actions_exist()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if can_move:
			rotate_y(-event.relative.x * .005)
			$Head.rotate_x(-event.relative.y * .005)
			$Head.rotation.x = clamp($Head.rotation.x, -PI/2, PI/2)
	
	# Toggle inventory with key press but only on press, not release
	if event.is_action_pressed(input_inventory) and not event.is_echo():
		toggle_inventory()
		# Prevent this event from being processed further
		get_viewport().set_input_as_handled()
		
	# Interact with items
	if event.is_action_pressed(input_interact):
		interact_with_nearby_object()

func _physics_process(delta):
	if health_bar and crosshair_ui:
		update_health_ui()
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= 9.8 * gravity_modifier * delta
		gravity_modifier += gravity_accelerator
	else:
		gravity_modifier = 1.0
	
	if can_move:
		# Get the input direction
		var input_dir = Input.get_vector(input_left, input_right, input_forward, input_backward)
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		# Sprinting
		if Input.is_action_pressed(input_sprint) and can_sprint and sprint_meter > 0 and not is_crouching:
			is_sprinting = true
			sprint_meter -= sprint_cost * delta
			if sprint_meter < 0:
				sprint_meter = 0
				is_sprinting = false
		else:
			is_sprinting = false
			if sprint_meter < 100:
				sprint_meter += sprint_restore * delta
			if sprint_meter > 100:
				sprint_meter = 100
		
		# Crouching
		if Input.is_action_pressed(input_crouch) and can_crouch:
			is_crouching = true
			cur_height = -crouch_height
		else:
			is_crouching = false
			cur_height = 0
		
		$CollisionShape3D.position.y = cur_height
		
		# Movement speed
		cur_speed_multiplier = 1.0
		if is_sprinting:
			cur_speed_multiplier = sprinting_speed_multiplier
		elif is_crouching:
			cur_speed_multiplier = 0.5
		
		if direction.z > 0:
			cur_speed = forward_speed * backward_speed_multiplier * cur_speed_multiplier
		elif direction.z < 0:
			cur_speed = forward_speed * cur_speed_multiplier
		
		if direction.x != 0:
			cur_speed = forward_speed * side_speed_multiplier * cur_speed_multiplier
		
		# Apply movement
		if direction:
			velocity.x = direction.x * cur_speed
			velocity.z = direction.z * cur_speed
		else:
			velocity.x = move_toward(velocity.x, 0, cur_speed)
			velocity.z = move_toward(velocity.z, 0, cur_speed)
	
		# Jumping
		if Input.is_action_just_pressed(input_jump) and is_on_floor() and can_jump:
			velocity.y = jump_strength
	
	move_and_slide()
	
	# Handle shooting
	if Input.is_action_pressed(input_shoot):
		shoot()
		
	# Check for nearby interactables
	check_for_interactables()

func setup_inventory():
	# Create inventory system if it doesn't exist
	if !has_node("InventorySystem"):
		print("Creating new InventorySystem")
		var InventorySystemClass = load("res://Scripts/inventory_system.gd")
		if InventorySystemClass:
			inventory_system = InventorySystemClass.new()
			inventory_system.name = "InventorySystem"
			inventory_system.max_slots = inventory_size
			add_child(inventory_system)
			
			# Connect signals
			if inventory_system.has_signal("item_added"):
				inventory_system.item_added.connect(_on_item_added_to_inventory)
			if inventory_system.has_signal("item_used"):
				inventory_system.item_used.connect(_on_item_used_from_inventory)
			
			print("Inventory system created with " + str(inventory_size) + " slots")
		else:
			push_error("Failed to load InventorySystem class")
			return
	else:
		print("Using existing inventory system")
		inventory_system = $InventorySystem
		
		# Make sure signals are connected
		if inventory_system.has_signal("item_added") and !inventory_system.item_added.is_connected(_on_item_added_to_inventory):
			inventory_system.item_added.connect(_on_item_added_to_inventory)
		
		if inventory_system.has_signal("item_used") and !inventory_system.item_used.is_connected(_on_item_used_from_inventory):
			inventory_system.item_used.connect(_on_item_used_from_inventory)
		
	# For debugging: check icons path
	print("Looking for gem icons in: res://assets/Rocks and Gems/1.png")
	var test_icon = load("res://assets/Rocks and Gems/1.png")
	if test_icon:
		print("Successfully loaded gem icon!")
	else:
		print("Failed to load gem icon!")

func toggle_inventory():
	if inventory_system:
		print("Proto controller toggling inventory...")
		var is_visible = inventory_system.toggle_inventory()
		
		# Handle mouse mode based on inventory state
		if is_visible:
			print("Setting mouse mode to VISIBLE")
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			print("Setting mouse mode to CAPTURED")
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
		# Force refresh of inventory UI if it's visible
		if is_visible and inventory_system.ui_node and inventory_system.ui_node.has_method("refresh_slots"):
			print("Forcing refresh of inventory slots")
			inventory_system.ui_node.refresh_slots()

func check_for_interactables():
	# Clear previous interactables
	interactable_items.clear()
	
	# Check for interactable objects in range
	var space_state = get_world_3d().direct_space_state
	var ray_origin = $Head.global_position
	var ray_direction = -$Head.global_transform.basis.z * pickup_range
	var ray_end = ray_origin + ray_direction
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.collider
		if collider is Area3D and (collider.is_in_group("Item") or collider.is_in_group("Interactable")):
			if !interactable_items.has(collider):
				interactable_items.append(collider)
				print("Found interactable: " + collider.name + " at distance: " + str(global_position.distance_to(collider.global_position)))
				if collider.has_method("highlight"):
					collider.highlight(true)
	
	# Also check for nearby gems using a sphere cast
	var sphere_query = PhysicsShapeQueryParameters3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = pickup_range
	sphere_query.set_shape(sphere_shape)
	sphere_query.transform = Transform3D(Basis(), global_position)
	sphere_query.collide_with_areas = true
	sphere_query.collide_with_bodies = false
	
	var sphere_results = space_state.intersect_shape(sphere_query, 10)
	for sphere_result in sphere_results:
		var collider = sphere_result.collider
		if collider is Area3D and (collider.is_in_group("Item") or collider.is_in_group("Interactable")):
			if !interactable_items.has(collider):
				interactable_items.append(collider)
				print("Found nearby gem: " + collider.name + " at distance: " + str(global_position.distance_to(collider.global_position)))
				if collider.has_method("highlight"):
					collider.highlight(true)

func interact_with_nearby_object():
	# Interact with closest object
	if interactable_items.size() > 0:
		var closest_item = interactable_items[0]
		print("Interacting with: " + closest_item.name)
		
		if closest_item.has_method("interact"):
			closest_item.interact()
			print("Called interact() on: " + closest_item.name)
		elif closest_item.has_method("pickup_item"):
			closest_item.pickup_item(self)
			print("Called pickup_item() on: " + closest_item.name)
	else:
		print("No interactable items found")

func add_to_inventory(item):
	if inventory_system:
		var success = inventory_system.add_to_inventory(item)
		if success:
			# Play pickup sound
			play_sound("pickup", gem_pickup_sound)
			
			# Update the gems UI
			update_gems_ui()
			
			print("Added " + item.name + " to inventory")
		else:
			print("Failed to add item to inventory - inventory full?")
		return success
	return false

func _on_item_added_to_inventory(item):
	# Handle item added to inventory (play sound, show notification, etc.)
	print("Added to inventory: " + item.name)
	
	# Update the gems UI
	update_gems_ui()

func _on_item_used_from_inventory(item, index):
	# Apply item effects when used from inventory
	if item.id == "magic_gem":
		var effect_message = ""
		var gem_type = item.get("gem_type", 0)  # Default to type 0 if not specified
		var effect_power = item.get("effect_power", 1.0)
		
		match gem_type:
			0:  # Purple - Magic gem
				# Magic gems restore mana/energy if you have a mana system
				# For now just heal a small amount
				heal(10 * effect_power)
				effect_message = "Used Magic Gem - restored energy!"
				
			1:  # Red - Health gem
				# Red gems restore health
				var heal_amount = 20 * effect_power
				heal(heal_amount)
				effect_message = "Used Health Gem - restored " + str(round(heal_amount)) + " health!"
				
			2:  # Blue - Shield gem
				# Blue gems give temporary shield
				var shield_amount = 30 * effect_power
				apply_shield(shield_amount)
				effect_message = "Used Shield Gem - gained " + str(round(shield_amount)) + " shield points!"
				
			3:  # Green - Speed gem
				# Green gems give speed boost
				var speed_multiplier = 1.3 * effect_power
				var duration = 10.0  # seconds
				apply_speed_boost(speed_multiplier, duration)
				effect_message = "Used Speed Gem - movement speed increased for " + str(duration) + " seconds!"
				
			4:  # Yellow - Luck gem
				# Yellow gems increase luck/drop rates
				var luck_multiplier = 1.5 * effect_power
				var duration = 60.0  # seconds
				apply_luck_boost(luck_multiplier, duration)
				effect_message = "Used Luck Gem - item drop rates increased for " + str(duration) + " seconds!"
				
		print(effect_message)

func drop_item_from_inventory(item, index):
	# Create physical item in the world
	if item.id == "magic_gem":
		var gem_scene = load("res://Scenes/magic_gem.tscn")
		if gem_scene:
			var gem = gem_scene.instantiate()
			get_tree().current_scene.add_child(gem)
			
			# Place in front of player
			var drop_pos = global_position + (-global_transform.basis.z * 1.5)
			drop_pos.y = global_position.y # Keep at same height
			gem.global_position = drop_pos
			
			print("Dropped item: " + item.name)

func heal(amount):
	current_health = min(current_health + amount, max_health)
	update_health_ui()

func play_sound(sound_type, stream = null):
	var sound_player
	
	# Create or get a sound player
	if has_node(sound_type + "Sound"):
		sound_player = get_node(sound_type + "Sound")
	else:
		sound_player = AudioStreamPlayer.new()
		sound_player.name = sound_type + "Sound"
		add_child(sound_player)
	
	# Set audio stream if provided
	if stream:
		sound_player.stream = stream
	
	# Play the sound
	if sound_player.stream:
		sound_player.play()

func shoot():
	if !fire_timer.is_stopped():
		return
		
	fire_timer.wait_time = projectile_fire_rate
	fire_timer.start()
	
	# Create a new projectile
	var projectile_scene = preload("res://Scenes/projectile.tscn")
	var projectile = projectile_scene.instantiate()
	
	# Set properties
	if projectile.has_method("set_damage"):
		projectile.set_damage(projectile_damage)
	
	# Add projectile to scene tree (not as child of launcher)
	get_tree().current_scene.add_child(projectile)
	
	# Set position and direction
	projectile.global_transform = projectile_launcher.global_transform
	
	# Make sure raycast is aiming in the right direction (forward)
	if projectile.has_method("set_direction"):
		var forward_dir = -projectile_launcher.global_transform.basis.z.normalized()
		projectile.set_direction(forward_dir)
	elif projectile is RigidBody3D:
		projectile.apply_central_impulse(-projectile_launcher.global_transform.basis.z * projectile_speed)
	
	# Debug
	print("Fired projectile toward direction: " + str(-projectile_launcher.global_transform.basis.z))
	
	# Play sound effect if available
	if has_node("ShootSound"):
		$ShootSound.play()

func setup_stylish_health_ui():
	# Create a CanvasLayer for the UI if it doesn't exist
	var canvas_layer
	if has_node("PlayerUI"):
		canvas_layer = $PlayerUI
	else:
		canvas_layer = CanvasLayer.new()
		canvas_layer.name = "PlayerUI"
		add_child(canvas_layer)
	
	# Check if we already have a health bar
	if canvas_layer.has_node("HealthBarContainer"):
		health_bar = canvas_layer.get_node("HealthBarContainer/HealthBar")
		return
	
	# Create a control container for health UI
	var container = Control.new()
	container.name = "HealthBarContainer"
	container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	container.position = Vector2(20, 20)
	container.size = Vector2(300, 60)
	canvas_layer.add_child(container)
	
	# Create background panel with fantasy style
	var panel = Panel.new()
	panel.name = "Background"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Style the panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.12, 0.7)  # Dark background
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.3, 0.5, 0.7, 0.8)  # Blue-ish border for player (different from enemy)
	panel_style.corner_radius_top_left = 5
	panel_style.corner_radius_top_right = 5
	panel_style.corner_radius_bottom_right = 5
	panel_style.corner_radius_bottom_left = 5
	panel_style.shadow_color = Color(0, 0, 0, 0.4)
	panel_style.shadow_size = 5
	panel.add_theme_stylebox_override("panel", panel_style)
	container.add_child(panel)
	
	# Add health icon (optional)
	var health_icon = Label.new()
	health_icon.name = "HealthIcon"
	health_icon.text = "♥"  # Heart symbol
	health_icon.position = Vector2(10, 5)
	health_icon.add_theme_font_size_override("font_size", 25)
	health_icon.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	container.add_child(health_icon)
	
	# Add health label
	var health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.text = "HEALTH"
	health_label.position = Vector2(40, 8)
	health_label.add_theme_font_size_override("font_size", 16)
	health_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	container.add_child(health_label)
	
	# Create the progress bar
	var progress = ProgressBar.new()
	progress.name = "HealthBar"
	progress.max_value = max_health
	progress.value = max_health
	progress.show_percentage = false
	progress.position = Vector2(10, 35)
	progress.size = Vector2(280, 20)
	
	# Style the progress bar with a gradient from dark blue to bright blue (player colors)
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 0.6, 1.0, 0.9)  # Bright blue
	fill_style.border_width_left = 0
	fill_style.border_width_top = 0
	fill_style.border_width_right = 0
	fill_style.border_width_bottom = 0
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_right = 3
	fill_style.corner_radius_bottom_left = 3
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.05, 0.1, 0.2, 0.8)  # Dark blue background
	bg_style.border_width_left = 1
	bg_style.border_width_top = 1
	bg_style.border_width_right = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = Color(0.3, 0.3, 0.5, 0.5)  # Subtle border
	bg_style.corner_radius_top_left = 3
	bg_style.corner_radius_top_right = 3
	bg_style.corner_radius_bottom_right = 3
	bg_style.corner_radius_bottom_left = 3
	
	progress.add_theme_stylebox_override("fill", fill_style)
	progress.add_theme_stylebox_override("background", bg_style)
	container.add_child(progress)
	
	# Store reference to health bar
	health_bar = progress
	
	# Explicitly set initial state
	update_health_ui()
	
	# Also create a stats panel
	if has_node("PlayerUI") and !$PlayerUI.has_node("StatsPanel"):
		setup_stats_panel()

func update_health_ui():
	if !health_bar:
		return
		
	# Get current value for animation
	var current_value = health_bar.value
	
	# Create smooth animation for health changes
	var tween = create_tween()
	tween.tween_property(health_bar, "value", current_health, 0.3).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	# Update health label color based on health percentage
	if has_node("PlayerUI/HealthBarContainer/HealthLabel"):
		var label = get_node("PlayerUI/HealthBarContainer/HealthLabel")
		var percent = int((float(current_health) / max_health) * 100)
		
		# Change text color based on health percentage
		if percent < 30:
			label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))  # Red for low health
		elif percent < 60:
			label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))  # Orange for medium health
		else:
			label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))  # Blue for high health
			
	# Also update fill color
	if health_bar:
		var fill_style = health_bar.get_theme_stylebox("fill")
		if fill_style is StyleBoxFlat:
			var percent = float(current_health) / max_health
			if percent < 0.3:
				fill_style.bg_color = Color(0.9, 0.2, 0.2, 0.9)  # Red for low health
			elif percent < 0.6:
				fill_style.bg_color = Color(0.9, 0.6, 0.1, 0.9)  # Orange for medium health
			else:
				fill_style.bg_color = Color(0.2, 0.6, 1.0, 0.9)  # Blue for high health
	
	# Play damage effect if health decreased
	if current_health < current_value:
		play_damage_effect()

func play_damage_effect():
	# Flash screen red when taking damage
	if has_node("PlayerUI"):
		var canvas_layer = $PlayerUI
		
		# Create damage flash overlay if it doesn't exist
		if !canvas_layer.has_node("DamageFlash"):
			var flash = ColorRect.new()
			flash.name = "DamageFlash"
			flash.set_anchors_preset(Control.PRESET_FULL_RECT)
			flash.color = Color(0.8, 0, 0, 0)  # Start transparent
			canvas_layer.add_child(flash)
		
		# Flash the overlay
		var flash = canvas_layer.get_node("DamageFlash")
		var tween = create_tween()
		tween.tween_property(flash, "color", Color(0.8, 0, 0, 0.3), 0.05)
		tween.tween_property(flash, "color", Color(0.8, 0, 0, 0), 0.2)

func take_damage(amount: float):
	current_health -= amount
	if current_health <= 0:
		current_health = 0
		die()
	
	# Update health UI
	update_health_ui()
	
	print("Player took damage! Health: ", current_health)

func die():
	# Implement death behavior here
	print("Player died!")
	
	# Show death menu instead of immediately restarting
	show_death_menu()

func show_death_menu():
	# Create a death menu if it doesn't exist
	if !has_node("PlayerUI") or !$PlayerUI.has_node("DeathMenu"):
		var canvas_layer
		if has_node("PlayerUI"):
			canvas_layer = $PlayerUI
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
		button_container.separation = 20
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
	$PlayerUI/DeathMenu.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func restart_game():
	# Hide death menu
	if has_node("PlayerUI") and $PlayerUI.has_node("DeathMenu"):
		$PlayerUI/DeathMenu.visible = false
	
	# Reload current scene
	get_tree().reload_current_scene()

func quit_to_menu():
	# Return to start menu scene
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")

func ensure_input_actions_exist():
	# Make sure all input actions exist
	if !InputMap.has_action("inventory_toggle"):
		InputMap.add_action("inventory_toggle")
		
		# Add 'I' key as default for inventory
		var event = InputEventKey.new()
		event.keycode = KEY_I
		InputMap.action_add_event("inventory_toggle", event)
	
	if !InputMap.has_action("interact"):
		InputMap.add_action("interact")
		
		# Add 'E' key as default for interact
		var event = InputEventKey.new()
		event.keycode = KEY_E
		InputMap.action_add_event("interact", event)

# Apply temporary shield
func apply_shield(amount):
	# If you have a shield system, implement it here
	# For now, we'll just add to health as a simple implementation
	current_health = min(current_health + amount, max_health + amount)
	update_health_ui()
	
	# Visual effect
	if has_node("PlayerUI"):
		var canvas_layer = $PlayerUI
		
		# Create shield flash effect
		if !canvas_layer.has_node("ShieldEffect"):
			var effect = ColorRect.new()
			effect.name = "ShieldEffect"
			effect.set_anchors_preset(Control.PRESET_FULL_RECT)
			effect.color = Color(0.2, 0.4, 1.0, 0)  # Start transparent
			canvas_layer.add_child(effect)
		
		# Flash the shield effect
		var effect = canvas_layer.get_node("ShieldEffect")
		var tween = create_tween()
		tween.tween_property(effect, "color", Color(0.2, 0.4, 1.0, 0.3), 0.2)
		tween.tween_property(effect, "color", Color(0.2, 0.4, 1.0, 0), 0.5)

# Apply temporary speed boost
func apply_speed_boost(multiplier, duration):
	# Store original speed
	var original_speed = forward_speed
	
	# Apply speed boost
	forward_speed *= multiplier
	
	# Visual effect
	if has_node("PlayerUI"):
		var canvas_layer = $PlayerUI
		
		# Create speed lines effect
		if !canvas_layer.has_node("SpeedEffect"):
			var effect = ColorRect.new()
			effect.name = "SpeedEffect"
			effect.set_anchors_preset(Control.PRESET_FULL_RECT)
			effect.color = Color(0.2, 0.8, 0.4, 0.2)  # Green, slightly transparent
			canvas_layer.add_child(effect)
		
		# Show speed effect
		var effect = canvas_layer.get_node("SpeedEffect")
		effect.visible = true
	
	# Create timer to reset speed
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		# Reset speed
		forward_speed = original_speed
		
		# Hide speed effect
		if has_node("PlayerUI") and $PlayerUI.has_node("SpeedEffect"):
			$PlayerUI.get_node("SpeedEffect").visible = false
	)

# Apply temporary luck boost
func apply_luck_boost(multiplier, duration):
	# Set a global luck multiplier
	# This would be checked when determining loot drops
	Global.luck_multiplier = multiplier
	
	# Visual effect
	if has_node("PlayerUI"):
		var canvas_layer = $PlayerUI
		
		# Create luck indicator
		if !canvas_layer.has_node("LuckIndicator"):
			var indicator = Label.new()
			indicator.name = "LuckIndicator"
			indicator.text = "LUCK BOOST ACTIVE"
			indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			indicator.position = Vector2(20, 80)
			indicator.size = Vector2(200, 30)
			indicator.add_theme_font_size_override("font_size", 16)
			indicator.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))  # Gold/yellow
			canvas_layer.add_child(indicator)
		
		# Show luck indicator
		var indicator = canvas_layer.get_node("LuckIndicator")
		indicator.visible = true
	
	# Create timer to reset luck
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		# Reset luck multiplier
		Global.luck_multiplier = 1.0
		
		# Hide luck indicator
		if has_node("PlayerUI") and $PlayerUI.has_node("LuckIndicator"):
			$PlayerUI.get_node("LuckIndicator").visible = false
	)

# Create a panel to display game stats (gems collected, enemies defeated)
func setup_stats_panel():
	var canvas_layer = $PlayerUI
	
	# Create a control container for stats UI
	var container = Control.new()
	container.name = "StatsPanel"
	container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	container.position = Vector2(-220, 20)
	container.size = Vector2(200, 100)
	canvas_layer.add_child(container)
	
	# Create background panel with style
	var panel = Panel.new()
	panel.name = "Background"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Style the panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.12, 0.7)  # Dark background
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.7, 0.6, 0.3, 0.8)  # Gold-ish border
	panel_style.corner_radius_top_left = 5
	panel_style.corner_radius_top_right = 5
	panel_style.corner_radius_bottom_right = 5
	panel_style.corner_radius_bottom_left = 5
	panel_style.shadow_color = Color(0, 0, 0, 0.4)
	panel_style.shadow_size = 5
	panel.add_theme_stylebox_override("panel", panel_style)
	container.add_child(panel)
	
	# Add title
	var title = Label.new()
	title.name = "Title"
	title.text = "PLAYER STATS"
	title.position = Vector2(10, 5)
	title.size = Vector2(180, 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))  # Gold text
	container.add_child(title)
	
	# Add gems collected counter
	var gems_label = Label.new()
	gems_label.name = "GemsLabel"
	gems_label.text = "Gems Collected: 0"
	gems_label.position = Vector2(10, 30)
	gems_label.size = Vector2(180, 20)
	gems_label.add_theme_font_size_override("font_size", 14)
	gems_label.add_theme_color_override("font_color", Color(0.8, 0.2, 1.0))  # Purple for gems
	container.add_child(gems_label)
	
	# Add enemies defeated counter
	var enemies_label = Label.new()
	enemies_label.name = "EnemiesLabel"
	enemies_label.text = "Enemies Defeated: 0"
	enemies_label.position = Vector2(10, 50)
	enemies_label.size = Vector2(180, 20)
	enemies_label.add_theme_font_size_override("font_size", 14)
	enemies_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))  # Red for enemies
	container.add_child(enemies_label)
	
	# Add luck status
	var luck_label = Label.new()
	luck_label.name = "LuckLabel"
	luck_label.text = "Luck Multiplier: x1.0"
	luck_label.position = Vector2(10, 70)
	luck_label.size = Vector2(180, 20)
	luck_label.add_theme_font_size_override("font_size", 14)
	luck_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))  # Gold for luck
	container.add_child(luck_label)

func _process(delta):
	# Update stats display if it exists
	update_stats_display()
	
	# Update gems UI if it exists
	update_gems_ui()

func update_stats_display():
	if has_node("PlayerUI") and $PlayerUI.has_node("StatsPanel"):
		var stats_panel = $PlayerUI.get_node("StatsPanel")
		
		# Only update if Global singleton exists
		if "Global" in get_node("/root"):
			# Update gems collected
			if stats_panel.has_node("GemsLabel"):
				stats_panel.get_node("GemsLabel").text = "Gems Collected: " + str(Global.gems_collected)
			
			# Update enemies defeated
			if stats_panel.has_node("EnemiesLabel"):
				stats_panel.get_node("EnemiesLabel").text = "Enemies Defeated: " + str(Global.enemies_defeated)
			
			# Update luck multiplier (formatted to 1 decimal place)
			if stats_panel.has_node("LuckLabel"):
				var luck_text = "Luck Multiplier: x%.1f" % Global.luck_multiplier
				stats_panel.get_node("LuckLabel").text = luck_text 

# Setup gems UI at the bottom of the screen
func setup_gems_ui():
	# Check if we already have the UI
	if has_node("PlayerUI") and $PlayerUI.has_node("GemsUIContainer/GemsUI"):
		return
		
	print("Setting up gems UI...")
		
	# Get or create the canvas layer
	var canvas_layer
	if has_node("PlayerUI"):
		canvas_layer = $PlayerUI
	else:
		canvas_layer = CanvasLayer.new()
		canvas_layer.name = "PlayerUI"
		add_child(canvas_layer)
	
	# Create a control to hold the gems UI
	var gems_container = Control.new()
	gems_container.name = "GemsUIContainer"
	gems_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	gems_container.position = Vector2(0, -100)  # Position from bottom
	canvas_layer.add_child(gems_container)
	
	# Create a horizontal container for gems
	var gems_ui = HBoxContainer.new()
	gems_ui.name = "GemsUI"
	gems_ui.alignment = BoxContainer.ALIGNMENT_CENTER
	gems_ui.custom_minimum_size = Vector2(600, 80)
	gems_ui.size_flags_horizontal = Control.SIZE_FILL
	gems_ui.size_flags_vertical = Control.SIZE_SHRINK_END
	gems_container.add_child(gems_ui)
	
	# Style for each gem counter
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 0.95) # More opaque background
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	style.shadow_color = Color(0, 0, 0, 0.7) # Darker shadow
	style.shadow_size = 5
	
	# Create a panel for each gem type
	var gem_types = ["Magic", "Health", "Shield", "Speed", "Luck"]
	var gem_colors = [
		Color(0.92, 0.2, 0.988), # Purple (Magic)
		Color(0.9, 0.2, 0.2),    # Red (Health)
		Color(0.2, 0.4, 0.9),    # Blue (Shield)
		Color(0.2, 0.9, 0.4),    # Green (Speed)
		Color(0.9, 0.8, 0.2)     # Yellow (Luck)
	]
	
	# Load the gem icons directly - use numbered textures
	var gem_icons = []
	for i in range(1, 6): # Assuming gems are numbered 1-5 in assets
		var icon_path = "res://assets/Rocks and Gems/" + str(i) + ".png"
		var icon = load(icon_path)
		if icon:
			gem_icons.append(icon)
			print("Loaded gem icon: " + icon_path)
		else:
			print("Failed to load gem icon: " + icon_path)
			# Create a colored placeholder
			var placeholder = PlaceholderTexture2D.new()
			placeholder.size = Vector2(32, 32)
			gem_icons.append(placeholder)
	
	# Create UI elements for each gem type
	for i in range(gem_types.size()):
		var gem_panel = Panel.new()
		gem_panel.name = gem_types[i] + "Gem"
		gem_panel.custom_minimum_size = Vector2(100, 70)
		gem_panel.add_theme_stylebox_override("panel", style.duplicate())
		gems_ui.add_child(gem_panel)
		
		# Gem icon (using a TextureRect)
		var icon = TextureRect.new()
		icon.name = "Icon"
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(40, 40)
		icon.position = Vector2(30, 5)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		
		# Try to use icon from assets, fallback to colored rect
		if i < gem_icons.size() and gem_icons[i]:
			icon.texture = gem_icons[i]
		else:
			print("Using fallback colored rect for gem icon " + str(i))
			# Create colored rect as fallback
			var placeholder = ColorRect.new()
			placeholder.color = gem_colors[i]
			placeholder.custom_minimum_size = Vector2(30, 30)
			icon.add_child(placeholder)
		
		gem_panel.add_child(icon)
		
		# Counter label
		var counter = Label.new()
		counter.name = "Counter"
		counter.text = "0"
		counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		counter.position = Vector2(25, 45)
		counter.size = Vector2(50, 20)
		counter.add_theme_font_size_override("font_size", 18) # Larger font
		counter.add_theme_color_override("font_color", gem_colors[i])
		gem_panel.add_child(counter)
		
		# Update the panel color based on gem type
		var panel_style = gem_panel.get_theme_stylebox("panel").duplicate()
		panel_style.border_color = gem_colors[i]
		gem_panel.add_theme_stylebox_override("panel", panel_style)
		
	# Initial update of gem counts
	update_gems_ui()
	
	print("Gems UI setup complete")

# Update gems UI to show collected gems
func update_gems_ui():
	if !has_node("PlayerUI") or !$PlayerUI.has_node("GemsUIContainer/GemsUI"):
		print("GemsUI not found at PlayerUI/GemsUIContainer/GemsUI - cannot update")
		return
		
	var gems_ui = $PlayerUI.get_node("GemsUIContainer/GemsUI")
	
	# Get collected gem counts from Global singleton
	var gem_counts = [0, 0, 0, 0, 0]
	
	# Check if Global singleton exists
	if get_node_or_null("/root/Global"):
		var global = get_node("/root/Global")
		print("Using Global singleton for gem counts")
		
		# Use Global's get_gem_count method to get accurate counts
		if global.has_method("get_gem_count"):
			for i in range(5):
				gem_counts[i] = global.get_gem_count(i)
				print("Global gem count for type " + str(i) + ": " + str(gem_counts[i]))
		else:
			print("Global has no get_gem_count method")
	else:
		# Fallback to counting in inventory if Global doesn't exist
		if inventory_system and inventory_system.has_method("get_inventory_items"):
			var items = inventory_system.get_inventory_items()
			
			print("Fallback: Checking inventory with " + str(items.size()) + " slots")
			var total_gems = 0
			
			for item in items:
				if item != null and item.id == "magic_gem" and "gem_type" in item:
					var gem_type = item.get("gem_type", 0)
					if gem_type >= 0 and gem_type < gem_counts.size():
						gem_counts[gem_type] += 1
						total_gems += 1
			
			print("Total gems in inventory: " + str(total_gems))
		else:
			print("Inventory system not available or missing method")
	
	# Update the counter labels
	var gem_types = ["Magic", "Health", "Shield", "Speed", "Luck"]
	for i in range(gem_types.size()):
		if gems_ui.has_node(gem_types[i] + "Gem/Counter"):
			var counter = gems_ui.get_node(gem_types[i] + "Gem/Counter")
			counter.text = str(gem_counts[i])
			print("Updated " + gem_types[i] + " gem count to " + str(gem_counts[i]))
			
			# Highlight gems that player has
			var panel = gems_ui.get_node(gem_types[i] + "Gem")
			if gem_counts[i] > 0:
				panel.modulate = Color(1, 1, 1, 1)
			else:
				panel.modulate = Color(0.5, 0.5, 0.5, 0.7) 