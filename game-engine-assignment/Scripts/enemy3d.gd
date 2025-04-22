extends CharacterBody3D

# Enemy stats
@export_group("Stats")
@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var damage: float = 10.0
@export var damage_cooldown: float = 0.3

# Behavior configuration
@export_group("Behavior")
@export var detection_range: float = 15.0
@export var attack_range: float = 8.0  # Increased to allow shooting from a distance
@export var speed: float = 3.0
@export var wander_radius: float = 10.0  # How far to wander from spawn
@export var wander_interval_min: float = 5.0  # Min time before picking new wander point
@export var wander_interval_max: float = 10.0  # Max time before picking new wander point

# Projectile settings
@export_group("Combat")
@export var projectile_scene: PackedScene = preload("res://Scenes/mage_projectile.tscn")
@export var projectile_speed: float = 8.0
@export var projectile_damage: float = 15.0
@export var attack_cooldown: float = 2.0  # Time between attacks

# State variables
enum State {IDLE, WANDER, CHASE, ATTACK}
var current_state = State.IDLE
var player = null
var can_take_damage = true
var can_attack = true
var target_position = Vector3.ZERO
var spawn_position = Vector3.ZERO
var health_bar
var wander_timer: Timer
var attack_timer: Timer
var rng = RandomNumberGenerator.new()
var animation_player: AnimationPlayer

# Called when the node enters the scene tree for the first time
func _ready():
	# Remember spawn position as wander center
	spawn_position = global_position
	
	# Get the animation player
	if has_node("skeleton_mage/AnimationPlayer"):
		animation_player = $skeleton_mage/AnimationPlayer
	elif has_node("AnimationPlayer"):
		animation_player = $AnimationPlayer
	
	# If animation player found, list available animations
	if animation_player:
		print("Available animations: ", animation_player.get_animation_list())
	else:
		print("No AnimationPlayer found! Animations will not work.")
	
	# Add to Enemy group for minimap detection
	if not is_in_group("Enemy"):
		add_to_group("Enemy")
	
	# Create health bar if it doesn't exist
	setup_health_bar()
	
	# Hide health bar initially
	if health_bar:
		health_bar.visible = false
		
	# Update debug label
	if has_node("DebugLabel"):
		$DebugLabel.text = "HP: " + str(current_health)
	
	# Create wander timer
	wander_timer = Timer.new()
	wander_timer.one_shot = true
	add_child(wander_timer)
	wander_timer.timeout.connect(_on_wander_timer_timeout)
	
	# Start wandering
	_start_wandering()
	
	# Create attack timer
	attack_timer = Timer.new()
	attack_timer.one_shot = true
	add_child(attack_timer)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
		
	# Print debug message to confirm the enemy is loaded
	print("Enemy initialized: " + name + " at position " + str(global_position))
	play_animation("idle")

func _physics_process(delta):
	# Get player reference if we don't have one
	if player == null:
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			player = players[0]
			print("Enemy found player: " + player.name)
	
	# If no player, just wander
	if player == null:
		if current_state != State.WANDER and current_state != State.IDLE:
			_start_wandering()
		_process_wander_state(delta)
		return
	
	# Calculate distance to player
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Check if player is within detection range
	if distance_to_player <= detection_range:
		# If player is within attack range
		if distance_to_player <= attack_range:
			if current_state != State.ATTACK:
				current_state = State.ATTACK
				print(name + " is now attacking player")
				play_animation("attack_charge")
			
			# Face the player with fixed orientation
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
			rotate_y(PI)  # Rotate 180 degrees to fix model orientation
			
			# Stop movement when attacking
			velocity = Vector3.ZERO
			
			# Attack if possible
			if can_attack:
				_attack_player()
		else:
			# Chase player if too far to attack but within detection range
			if current_state != State.CHASE:
				current_state = State.CHASE
				print(name + " is now chasing player")
				play_animation("walk")
			
			_process_chase_state(delta)
	else:
		# If player is out of detection range, go back to wandering
		if current_state != State.WANDER and current_state != State.IDLE:
			_start_wandering()
		
		_process_wander_state(delta)
	
	move_and_slide()

func _process_chase_state(delta):
	# Calculate direction to player
	var direction = (player.global_position - global_position).normalized()
	direction.y = 0  # Keep movement on horizontal plane
	
	# Face the player - add an offset to rotate the model 180 degrees
	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	rotate_y(PI)  # Rotate 180 degrees to fix model orientation
	
	# Set velocity to move toward player
	velocity = direction * speed
	
	# Play chase animation
	play_animation("walk")

func _process_wander_state(delta):
	# If we have a target position to wander to
	if current_state == State.WANDER and target_position != Vector3.ZERO:
		# Calculate direction to target
		var direction = (target_position - global_position).normalized()
		direction.y = 0  # Keep movement on horizontal plane
		
		# Face the target direction
		if direction.length() > 0.1:
			look_at(Vector3(target_position.x, global_position.y, target_position.z), Vector3.UP)
			rotate_y(PI)  # Rotate 180 degrees to fix model orientation
		
		# Check if we've reached the target position (with some tolerance)
		var distance_to_target = global_position.distance_to(target_position)
		if distance_to_target < 1.0:
			# Target reached, go idle
			current_state = State.IDLE
			velocity = Vector3.ZERO
			play_animation("idle")
			
			# Set timer for next wander
			wander_timer.wait_time = rng.randf_range(wander_interval_min, wander_interval_max)
			wander_timer.start()
		else:
			# Move toward target
			velocity = direction * speed * 0.7  # Wander slower than chase
			play_animation("walk")
	else:
		# If no target or idle, stop moving
		velocity = Vector3.ZERO
		play_animation("idle")

func _start_wandering():
	current_state = State.WANDER
	
	# Pick a random point within the wander radius of the spawn point
	var random_x = rng.randf_range(-wander_radius, wander_radius)
	var random_z = rng.randf_range(-wander_radius, wander_radius)
	target_position = spawn_position + Vector3(random_x, 0, random_z)
	
	print(name + " wandering to position: " + str(target_position))

func _on_wander_timer_timeout():
	if current_state == State.IDLE:
		_start_wandering()

func _attack_player():
	if not can_attack or not player:
		return
	
	# Start attack cooldown
	can_attack = false
	attack_timer.wait_time = attack_cooldown
	attack_timer.start()
	
	# Play attack animation
	play_animation("attack")
	
	# Create projectile
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	
	# Position the projectile using spawn point if available
	var spawn_point = global_position + Vector3(0, 1.0, 0)  # Default offset
	if has_node("ProjectileSpawnPoint"):
		spawn_point = $ProjectileSpawnPoint.global_position
	
	projectile.global_position = spawn_point
	
	# Calculate direction to player (lead the target a bit)
	var direction = (player.global_position - spawn_point).normalized()
	
	# Set projectile properties
	projectile.shooter = self
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	projectile.set_direction(direction)
	
	print(name + " shoots magic ball at player")

func _on_attack_timer_timeout():
	can_attack = true

# Get current health for damage calculation
func get_current_health() -> float:
	return current_health

func setup_health_bar():
	# Check if we already have a health bar child
	if has_node("HealthBar3D"):
		health_bar = $HealthBar3D
		return
		
	# Create a 3D health bar using a SubViewport
	var health_bar_scene = Node3D.new()
	health_bar_scene.name = "HealthBar3D"
	
	# Create viewport for the health bar
	var viewport = SubViewport.new()
	viewport.name = "Viewport"
	viewport.size = Vector2(100, 10)
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	
	# Create the progress bar
	var progress = ProgressBar.new()
	progress.name = "ProgressBar"
	progress.max_value = max_health
	progress.value = current_health
	progress.size = Vector2(100, 10)
	progress.show_percentage = false
	
	# Style the progress bar
	progress.add_theme_color_override("fill_bg_color", Color(0.2, 0.2, 0.2, 0.8))
	progress.add_theme_color_override("fill_color", Color(0.9, 0.1, 0.1, 0.9))
	
	# Add progress bar to viewport
	viewport.add_child(progress)
	
	# Create sprite to display the viewport texture
	var sprite = Sprite3D.new()
	sprite.name = "Sprite"
	sprite.texture = viewport.get_texture()
	sprite.pixel_size = 0.01
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.position = Vector3(0, 1.5, 0)  # Position above enemy
	
	# Add viewport to health bar scene
	health_bar_scene.add_child(viewport)
	health_bar_scene.add_child(sprite)
	
	# Add health bar to the enemy
	add_child(health_bar_scene)
	health_bar = health_bar_scene
	
	# Update the health bar
	update_health_bar()

func take_damage(amount: float):
	# Handle damage
	print(name + " taking damage: " + str(amount))
	
	if !can_take_damage:
		print(name + " on damage cooldown - not taking damage")
		return
		
	can_take_damage = false
	current_health -= amount
	
	# Interrupt current animation and play hit animation
	play_animation("hit")
	
	# Show health bar when damaged
	if health_bar:
		health_bar.visible = true
	
	# Update health bar display
	update_health_bar()
	
	# Update debug label
	if has_node("DebugLabel"):
		$DebugLabel.text = "HP: " + str(current_health)
	
	# Play hit effect/animation
	play_hit_effect()
	
	# Debug output
	print(name + " took " + str(amount) + " damage! Health: " + str(current_health))
	
	# Check if dead
	if current_health <= 0:
		die()
	else:
		# Start damage cooldown timer
		var timer = get_tree().create_timer(damage_cooldown)
		timer.timeout.connect(func(): 
			can_take_damage = true
			print(name + " can take damage again"))

func update_health_bar():
	if health_bar and health_bar.has_node("Viewport/ProgressBar"):
		var progress_bar = health_bar.get_node("Viewport/ProgressBar")
		progress_bar.value = current_health
		
		# Hide health bar if full health
		if current_health >= max_health:
			health_bar.visible = false

func play_hit_effect():
	# Flash the model red
	if has_node("skeleton_mage"):
		var model = $skeleton_mage
		
		# Create a red material for flashing
		var flash_material = StandardMaterial3D.new()
		flash_material.albedo_color = Color(1.0, 0.3, 0.3)
		flash_material.emission_enabled = true
		flash_material.emission = Color(1.0, 0.3, 0.3)
		flash_material.emission_energy_multiplier = 2.0
		
		# Store all original materials
		var original_materials = []
		for i in range(model.get_child_count()):
			var child = model.get_child(i)
			if child is MeshInstance3D:
				original_materials.append([])
				for j in range(child.get_surface_override_material_count()):
					original_materials[i].append(child.get_surface_override_material(j))
					# Apply flash material
					child.set_surface_override_material(j, flash_material)
		
		# Play hit sound if available
		if has_node("HitSound"):
			$HitSound.play()
		
		# After a short time, restore original materials
		await get_tree().create_timer(0.15).timeout
		
		# Restore original materials
		for i in range(model.get_child_count()):
			var child = model.get_child(i)
			if child is MeshInstance3D and i < original_materials.size():
				for j in range(child.get_surface_override_material_count()):
					if j < original_materials[i].size():
						child.set_surface_override_material(j, original_materials[i][j])

func play_animation(anim_name: String):
	if not animation_player:
		return
		
	# Map generic animation names to specific ones in the model
	var animation_map = {
		"idle": "idle",
		"walk": "walk",
		"attack": "attack",
		"attack_charge": "attack_anticipation",
		"hit": "hit",
		"death": "death"
	}
	
	# Check for animations in the map or use the name directly
	var actual_anim = animation_map.get(anim_name, anim_name)
	
	# Check if animation exists before playing
	if animation_player.has_animation(actual_anim):
		# Don't interrupt death animation
		if animation_player.current_animation == "death":
			return
			
		if animation_player.current_animation != actual_anim:
			animation_player.play(actual_anim)
	else:
		# If animation doesn't exist, try to find a similar one
		var available_anims = animation_player.get_animation_list()
		for anim in available_anims:
			if anim.to_lower().contains(anim_name.to_lower()):
				animation_player.play(anim)
				return
		
		# If not found at all, just print a warning
		print("Animation not found: ", actual_anim)

func die():
	# Disable collision and physics
	set_physics_process(false)
	$CollisionShape3D.disabled = true
	current_state = State.IDLE
	
	# Debug message
	print(name + " has been defeated!")
	
	# Play death animation
	play_animation("death")
	
	# Play death effect/visuals
	if has_node("skeleton_mage"):
		var model = $skeleton_mage
		
		# Create a dissolve material
		var dissolve_material = StandardMaterial3D.new()
		dissolve_material.albedo_color = Color(0.3, 0.0, 0.0)
		dissolve_material.emission_enabled = true
		dissolve_material.emission = Color(0.7, 0.0, 0.0)
		dissolve_material.emission_energy_multiplier = 3.0
		
		# Play death sound if available
		if has_node("DeathSound"):
			$DeathSound.play()
			
		# Create particles for death effect (optional)
		var particles = GPUParticles3D.new()
		particles.name = "DeathParticles"
		add_child(particles)
		
		# Wait for death animation to finish (or a fallback timer)
		if animation_player and animation_player.has_animation("death"):
			await animation_player.animation_finished
		else:
			await get_tree().create_timer(1.5).timeout
		
		# Fade out the model
		var tween = create_tween()
		tween.tween_property(model, "modulate:a", 0.0, 1.5)
		tween.parallel().tween_property(self, "position:y", position.y - 0.5, 1.5)
		
		# Wait for animation/effect to finish
		await tween.finished
	
	# Remove from scene
	queue_free() 