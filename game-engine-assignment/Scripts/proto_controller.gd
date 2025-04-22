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

func _ready():
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
	
	# Setup health UI
	if has_node("HealthBar"):
		health_bar = $HealthBar
		update_health_ui()
	else:
		push_warning("HealthBar node missing - health UI won't update")

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if can_move:
			rotate_y(-event.relative.x * .005)
			$Head.rotate_x(-event.relative.y * .005)
			$Head.rotation.x = clamp($Head.rotation.x, -PI/2, PI/2)

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
			velocity.x = 0
			velocity.z = 0
	
		# Jumping
		if Input.is_action_just_pressed(input_jump) and is_on_floor() and can_jump:
			velocity.y = jump_strength
	
	move_and_slide()
	
	# Handle shooting
	if Input.is_action_pressed(input_shoot):
		shoot()

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

func take_damage(amount: float):
	current_health -= amount
	if current_health <= 0:
		current_health = 0
		die()
	update_health_ui()

func update_health_ui():
	if health_bar:
		health_bar.value = current_health

func die():
	# Implement death behavior here
	print("Player died!")
	
	# For now, just restart the current scene
	get_tree().reload_current_scene()

func _on_sprint_timeout():
	is_sprinting = false 