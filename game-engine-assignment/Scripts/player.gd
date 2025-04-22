extends CharacterBody3D

# Player stats
var health = 100
var max_health = 100
var move_speed = 5.0
var jump_velocity = 4.5
var sensitivity = 0.003
var damage = 10  # Damage dealt by projectiles

# State tracking
var is_dead = false

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera = $Camera3D
@onready var projectile_launcher = $ProjectileLauncher
@onready var healthbar = $HealthBar  # Assuming you'll add a UI for health

func _ready():
	# Register with Player group for enemy targeting
	if not is_in_group("Player"):
		add_to_group("Player")
	
	# Capture mouse for camera look
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	# Camera look logic
	if event is InputEventMouseMotion and not is_dead:
		rotate_y(-event.relative.x * sensitivity)
		camera.rotate_x(-event.relative.y * sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	# Handle ESC key to release mouse
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	if is_dead:
		return
		
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# Movement direction relative to camera orientation
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Apply movement
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()

func take_damage(amount):
	if is_dead:
		return
		
	health -= amount
	
	# Update health bar
	if healthbar:
		healthbar.value = (float(health) / max_health) * 100
		healthbar.visible = health < max_health
	
	# Play hit animation/sound
	
	# Check if dead
	if health <= 0:
		die()

func die():
	is_dead = true
	# Play death animation
	
	# Show game over screen
	await get_tree().create_timer(2.0).timeout
	# Implement game over logic or respawn
