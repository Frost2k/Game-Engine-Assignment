extends CharacterBody3D

# Enemy stats
@export_group("Stats")
@export var max_health: float = 200.0
@export var current_health: float = 200.0
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
@export var projectile_scene: PackedScene = preload("res://scenes/mage_projectile.tscn")
@export var projectile_speed: float = 8.0
@export var projectile_damage: float = 15.0
@export var attack_cooldown: float = 2.0  # Time between attacks
@export var projectile_color: Color = Color(0.5, 0.2, 0.8, 0.8)  # Default purple color

# Drop variables
@export_group("Drops")
@export var drop_gem_chance: float = 0.75  # Default chance to drop a gem
@export var gem_scene_path: String = "res://scenes/magic_gem.tscn"
@export_enum("Random", "Purple:0", "Red:1", "Blue:2", "Green:3", "Yellow:4") var fixed_gem_type: int = 0
@export var force_gem_drop: bool = false  # If true, always drops a gem

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
var damaged_timer: float = 0.0
var hit_effect_scene: PackedScene
var hit_sounds: Array = []
var is_dead: bool = false
var knockback_impulse = Vector3.ZERO

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

func _process(delta):
	# Update damaged timer for flashing effect
	if damaged_timer > 0:
		damaged_timer -= delta
	
	# Handle health bar if it exists
	if health_bar and health_bar.visible:
		# Make sure the health bar faces the camera 
		var camera = get_viewport().get_camera_3d()
		if camera:
			# Ensure sprite is the one that rotates to face camera, not the entire health bar node
			var sprite = health_bar.find_child("Sprite", true, false)
			if sprite:
				# The Sprite3D already has billboard mode enabled, so it automatically faces the camera
				# Just ensure it's positioned correctly above the enemy
				
				# If health is close to max, gradually fade out the health bar
				if current_health > max_health * 0.95 and current_health < max_health:
					if sprite.modulate.a > 0.1:
						sprite.modulate.a -= delta * 0.5
				
				# If enemy took damage recently, ensure the health bar is fully visible
				if damaged_timer > 0:
					sprite.modulate.a = 1.0

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
				
				# Stop movement when attacking
				velocity = Vector3.ZERO
			
			# Face the player with fixed orientation
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
			#rotate_y(PI)  # Rotate 180 degrees to fix model orientation
			
			
			
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
	
	# gravity
	if not is_on_floor():
		velocity.y += (get_gravity().y * delta)
	
	# knockback
	velocity += knockback_impulse
	knockback_impulse = Vector3.ZERO
	
	
	move_and_slide()
	
	# Check for collisions with walls or objects (after move_and_slide)
	if is_on_wall() and (current_state == State.WANDER or current_state == State.CHASE):
		_handle_obstacle_collision()

func _process_chase_state(delta):
	# Calculate direction to player
	var direction = (player.global_position - global_position).normalized()
	direction.y = 0  # Keep movement on horizontal plane
	
	# Face the player - add an offset to rotate the model 180 degrees
	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	#rotate_y(PI)  # Rotate 180 degrees to fix model orientation
	
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
			#rotate_y(PI)  # Rotate 180 degrees to fix model orientation
		
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
	
	# Set custom projectile color if the projectile supports it
	if projectile.has_method("set_projectile_color"):
		projectile.set_projectile_color(projectile_color)
	# Alternative approach if the projectile has a direct color property
	elif "projectile_color" in projectile:
		projectile.projectile_color = projectile_color
	
	print(name + " shoots magic ball at player")

func _on_attack_timer_timeout():
	can_attack = true

# Get current health for damage calculation
func get_current_health() -> float:
	return current_health

func setup_health_bar():
	print(name + ": Setting up health bar")
	
	# Check if we already have a health bar child
	if has_node("HealthBar3D"):
		health_bar = $HealthBar3D
		print(name + ": Using existing health bar")
		return
		
	print(name + ": Creating new health bar")
	
	# Create a 3D health bar using a SubViewport
	var health_bar_scene = Node3D.new()
	health_bar_scene.name = "HealthBar3D"
	
	# Create viewport for the health bar - doubled size
	var viewport = SubViewport.new()
	viewport.name = "Viewport"
	viewport.size = Vector2(300, 30)  # Wider but thinner (no label needed)
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	health_bar_scene.add_child(viewport)
	print(name + ": Created viewport")
	
	# Create a control node to hold all UI elements
	var control = Control.new()
	control.name = "HealthBarContainer"
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.size = Vector2(300, 30)
	viewport.add_child(control)
	
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
	panel_style.border_color = Color(0.5, 0.4, 0.2, 0.8)  # Gold-ish border
	panel_style.corner_radius_top_left = 3
	panel_style.corner_radius_top_right = 3
	panel_style.corner_radius_bottom_right = 3
	panel_style.corner_radius_bottom_left = 3
	panel_style.shadow_color = Color(0, 0, 0, 0.3)
	panel_style.shadow_size = 4
	panel.add_theme_stylebox_override("panel", panel_style)
	control.add_child(panel)
	
	# Create the progress bar - now fills most of the container
	var progress = ProgressBar.new()
	progress.name = "ProgressBar"
	progress.max_value = max_health
	progress.value = current_health
	progress.size = Vector2(280, 20)
	progress.position = Vector2(10, 5)  # Centered
	progress.show_percentage = false
	
	# Style the progress bar with a gradient from dark red to bright red
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.8, 0.0, 0.0, 0.9)  # Bright red
	fill_style.border_width_left = 0
	fill_style.border_width_top = 0
	fill_style.border_width_right = 0
	fill_style.border_width_bottom = 0
	fill_style.corner_radius_top_left = 2
	fill_style.corner_radius_top_right = 2
	fill_style.corner_radius_bottom_right = 2
	fill_style.corner_radius_bottom_left = 2
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.0, 0.0, 0.8)  # Dark red background
	bg_style.border_width_left = 1
	bg_style.border_width_top = 1
	bg_style.border_width_right = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = Color(0.3, 0.3, 0.3, 0.5)  # Subtle border
	bg_style.corner_radius_top_left = 2
	bg_style.corner_radius_top_right = 2
	bg_style.corner_radius_bottom_right = 2
	bg_style.corner_radius_bottom_left = 2
	
	progress.add_theme_stylebox_override("fill", fill_style)
	progress.add_theme_stylebox_override("background", bg_style)
	control.add_child(progress)
	print(name + ": Added progress bar")
	
	# Create sprite to display the viewport texture - double the size and much higher
	var sprite = Sprite3D.new()
	sprite.name = "Sprite"
	sprite.pixel_size = 0.007  # Increased size
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.position = Vector3(0, 3.5, 0)  # Positioned much higher above enemy
	sprite.no_depth_test = true  # Always show in front of other objects
	health_bar_scene.add_child(sprite)
	print(name + ": Added sprite")
	
	# Need to wait a frame for the viewport texture to be ready
	await get_tree().process_frame
	
	# Set texture AFTER viewport is added to scene tree
	sprite.texture = viewport.get_texture()
	print(name + ": Set sprite texture")
	
	# Add health bar to the enemy
	add_child(health_bar_scene)
	health_bar = health_bar_scene
	print(name + ": Health bar added to scene tree")
	
	# Start with healthbar hidden if at full health
	if current_health < max_health:
		health_bar.visible = true
		print(name + ": Health bar visible because health < max")
	else:
		health_bar.visible = false
		print(name + ": Health bar hidden because health = max")
	
	# Update the health bar
	call_deferred("update_health_bar")

func take_damage(amount: float):
	if is_dead:
		return
	
	damaged_timer = 0.3
	
	# Flash the enemy red
	if has_node("skeleton_mage"):
		play_hit_effect()
	
	# Reduce health
	current_health -= amount
	
	# Show hit effect if it exists
	if hit_effect_scene:
		var hit_effect = hit_effect_scene.instantiate()
		hit_effect.position = position + Vector3(0, 1.0, 0)
		get_parent().add_child(hit_effect)
	
	# Play hit sound - simple approach instead of using AudioManager
	if hit_sounds and hit_sounds.size() > 0:
		var sound_index = randi() % hit_sounds.size()
		if has_node("HitSound"):
			if $HitSound is AudioStreamPlayer:
				$HitSound.stream = hit_sounds[sound_index]
				$HitSound.play()
	
	# Make sure health bar is visible and fully opaque when taking damage
	if health_bar and current_health > 0 and current_health < max_health:
		print(name + ": Taking damage, showing health bar")
		health_bar.visible = true
		var sprite = health_bar.find_child("Sprite", true, false)
		if sprite:
			sprite.modulate.a = 1.0
	
	# Update the health bar
	update_health_bar()
	
	# Die if health reaches 0
	if current_health <= 0:
		current_health = 0
		die()

func update_health_bar():
	if not health_bar or not health_bar.has_node("Viewport"):
		return
		
	# Update the progress bar value
	var viewport = health_bar.get_node("Viewport")
	var progress_bar = viewport.find_child("ProgressBar", true, false)
	
	if progress_bar:
		# Set the progress bar max value to match the enemy's max health
		progress_bar.max_value = max_health
		# Set the progress bar value to the current health
		progress_bar.value = current_health
		
		# Calculate health percentage for color updates
		var health_percent = float(current_health) / float(max_health)
		
		# Get the fill style to update its color
		var fill_style = progress_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if fill_style:
			# Update fill color based on health
			if health_percent < 0.25:
				fill_style.bg_color = Color(1.0, 0.0, 0.0, 0.9)  # Red for low health
			elif health_percent < 0.5:
				fill_style.bg_color = Color(1.0, 0.5, 0.0, 0.9)  # Orange for medium health
			else:
				fill_style.bg_color = Color(0.0, 1.0, 0.0, 0.9)  # Green for good health
		
		# Show health bar when health is not full
		if current_health < max_health:
			health_bar.visible = true
			# Try to find the sprite if it exists
			var sprite = health_bar.find_child("Sprite", true, false)
			if sprite:
				# Make sure it's visible
				sprite.modulate.a = 1.0
		else:
			# Only hide the health bar if damage timer is also expired
			if damaged_timer <= 0:
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
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = true
	current_state = State.IDLE
	
	# Debug message
	#print(name + " has been defeated!")
	
	# Track enemy defeat in global stats
	if "Global" in get_node("/root"):
		Global.enemies_defeated += 1
	
	# Check if we should spawn a gem
	var should_spawn_gem = force_gem_drop
	
	if not should_spawn_gem:
		if "Global" in get_node("/root") and Global.has_method("apply_luck_to_chance"):
			# Apply luck to base drop chance
			var drop_chance = Global.apply_luck_to_chance(drop_gem_chance)
			
			# Random roll for gem drop
			var rng = RandomNumberGenerator.new()
			rng.randomize()
			should_spawn_gem = rng.randf() <= drop_chance
		else:
			# Default drop chance if Global singleton is missing or method not found
			var rng = RandomNumberGenerator.new()
			rng.randomize()
			should_spawn_gem = rng.randf() <= drop_gem_chance
	
	# Always drop from bosses or special enemies
	if name.to_lower().contains("boss") or name.to_lower().contains("elite"):
		should_spawn_gem = true
	
	# Spawn a gem if conditions are met
	if should_spawn_gem:
		# Create a visual effect at the enemy's position to show where the gem will spawn
		create_gem_spawn_effect()
		
		# Use a timer to delay the gem spawn slightly for better visual effect
		var spawn_timer = Timer.new()
		spawn_timer.one_shot = true
		spawn_timer.wait_time = 0.5
		add_child(spawn_timer)
		spawn_timer.timeout.connect(spawn_gem)
		spawn_timer.start()
	
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
		
		# Fade out the model by modifying materials
		var mesh_instances = []
		find_mesh_instances(model, mesh_instances)
		
		var fade_duration = 1.5
		var start_time = Time.get_ticks_msec() / 1000.0
		
		# Apply initial transparent materials
		for mesh in mesh_instances:
			for i in range(mesh.get_surface_override_material_count()):
				var current_material = mesh.get_surface_override_material(i)
				if current_material:
					var transparent_material = current_material.duplicate()
					if transparent_material is StandardMaterial3D:
						transparent_material.flags_transparent = true
						transparent_material.albedo_color.a = 1.0
						mesh.set_surface_override_material(i, transparent_material)
		
		# Create a timer to handle the fade animation
		var fade_timer = Timer.new()
		fade_timer.name = "FadeTimer"
		fade_timer.wait_time = 0.05  # Update several times per second
		add_child(fade_timer)
		
		# Create a function to update material alpha
		var update_alpha = func():
			var current_time = Time.get_ticks_msec() / 1000.0
			var elapsed = current_time - start_time
			var alpha = max(0, 1.0 - (elapsed / fade_duration))
			
			# Update all materials
			for mesh in mesh_instances:
				for i in range(mesh.get_surface_override_material_count()):
					var material = mesh.get_surface_override_material(i)
					if material is StandardMaterial3D:
						material.albedo_color.a = alpha
			
			# Move down slightly
			position.y -= 0.01
			
			# Stop when fully transparent
			if alpha <= 0:
				fade_timer.stop()
				fade_timer.queue_free()
		
		# Connect timer to the update function
		fade_timer.timeout.connect(update_alpha)
		fade_timer.start()
		
		# Wait until the fade completes
		await get_tree().create_timer(fade_duration).timeout
	
	# Remove from scene
	queue_free()

# Helper function to find all mesh instances in a node and its children
func find_mesh_instances(node, results):
	if node is MeshInstance3D:
		results.append(node)
		
	for child in node.get_children():
		find_mesh_instances(child, results)

# Creates a visual effect to highlight where the gem will spawn
func create_gem_spawn_effect():
	# Create a light to indicate gem spawn
	var light = OmniLight3D.new()
	light.name = "GemSpawnLight"
	light.light_color = Color(1, 1, 1)  # Bright white light
	light.light_energy = 5.0
	light.omni_range = 4.0
	light.position = global_position + Vector3(0, 0.5, 0)
	
	# Add to scene
	get_tree().current_scene.add_child(light)
	
	# Create a tween to animate the light
	var tween = create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.5)
	tween.tween_callback(func(): light.queue_free())

func spawn_gem():
	# Load the gem scene
	print("=== SPAWN GEM ATTEMPT ===")
	print("Attempting to spawn gem for " + name + " at position " + str(global_position))
	var gem_scene = load(gem_scene_path)
	
	if gem_scene:
		print("Gem scene loaded successfully")
		
		# Instance the gem
		var gem = gem_scene.instantiate()
		print("Gem instance created")
		
		# Use the scene as parent instead of relying on enemy's transform
		var main_scene = get_tree().current_scene
		print("Current scene: " + main_scene.name)
		
		# Store the position before we're removed from the tree
		# Ensure gem spawns ABOVE the floor by using a larger Y offset
		var spawn_position = global_position + Vector3(0, 3.0, 0)  # Increased from 2.0 to 3.0
		
		# Make sure the gem is at least at floor level (assuming floor is at y=0)
		# This ensures it doesn't spawn below even if enemy is in a pit
		if spawn_position.y < 0:
			spawn_position.y = 1.0  # Minimum height above zero
			
		print("Target spawn position: " + str(spawn_position))
		
		# Determine gem type - weighted random selection
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		
		var gem_type = 0  # Default to purple (magic)
		
		# Use fixed gem type if specified, otherwise use random
		if fixed_gem_type > 0:
			gem_type = fixed_gem_type - 1  # Adjust for enum offset (Random is 0)
		else:
			var gem_type_roll = rng.randf()
			
			# Different enemies could have different gem drop rates
			# For this example, we'll use a general probability distribution
			if gem_type_roll < 0.50:
				# 50% chance of purple gem (most common)
				gem_type = 0
			elif gem_type_roll < 0.75:
				# 25% chance of red gem (health)
				gem_type = 1
			elif gem_type_roll < 0.90:
				# 15% chance of blue gem (shield)
				gem_type = 2
			elif gem_type_roll < 0.97:
				# 7% chance of green gem (speed)
				gem_type = 3
			else:
				# 3% chance of yellow gem (luck - most rare)
				gem_type = 4
		
		# Set properties before adding to scene
		gem.gem_type = gem_type
		
		# Randomize gem value based on enemy strength and gem type
		var base_value = 10 + (gem_type * 5)
		gem.item_value = randi_range(base_value, base_value + 15)
		
		# Set effect power based on enemy level/difficulty
		gem.effect_power = 1.0 + (gem_type * 0.2)
		
		# Add the gem to the main scene
		main_scene.add_child(gem)
		#print("Gem added to scene tree")
		
		# Set position after adding to scene
		gem.global_position = spawn_position
		
		# Wait a frame to ensure the gem is properly initialized in the scene tree
		await get_tree().process_frame
		
		# Now configure additional properties after the gem is in the tree
		gem.update_gem_properties()
		gem.apply_gem_material()
		
		# Scale up the gem to make it more visible
		gem.scale = Vector3(1.5 + (gem_type * 0.1), 1.5 + (gem_type * 0.1), 1.5 + (gem_type * 0.1))
		
		# Increase collision radius for easier pickup
		if gem.has_node("CollisionShape3D"):
			# Adjust collision shape to match new scale
			gem.get_node("CollisionShape3D").scale = Vector3(1.2, 1.2, 1.2)
			
		print("Gem spawned successfully with type: " + str(gem_type))
		
		# Create a small particle effect to draw attention
		create_gem_spawn_particles(spawn_position)
	else:
		push_error("Failed to load gem scene from: " + gem_scene_path)

func create_gem_spawn_particles(position):
	# This function creates particles when a gem spawns to make it more noticeable
	var particles = CPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 16
	particles.lifetime = 1.0
	particles.mesh = SphereMesh.new()
	particles.mesh.radius = 0.1
	particles.mesh.height = 0.2
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 45.0
	particles.gravity = Vector3(0, -9.8, 0)
	particles.initial_velocity_min = 2.0
	particles.initial_velocity_max = 5.0
	
	# Add to scene
	get_tree().current_scene.add_child(particles)
	particles.global_position = position
	
	# Auto-delete after particles finish
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(func(): particles.queue_free())
	particles.add_child(timer)
	timer.start()

func _handle_obstacle_collision():
	# Debug message
	#print(name + " hit an obstacle, changing direction")
	
	# Play a brief reaction animation if available
	play_animation("hit")
	
	# If chasing player, take a small step back before trying a different path
	if current_state == State.CHASE and player != null:
		# Step back to prevent getting stuck
		var back_dir = -velocity.normalized()
		velocity = back_dir * speed * 0.5
		move_and_slide()
		
		# Calculate a new direction to the player that avoids the obstacle
		var direct_to_player = (player.global_position - global_position).normalized()
		
		# Try finding alternative directions by rotating the vector
		var alternative_directions = [
			Quaternion(Vector3.UP, PI/4).normalized() * direct_to_player,
			Quaternion(Vector3.UP, -PI/4).normalized() * direct_to_player,
			Quaternion(Vector3.UP, PI/2).normalized() * direct_to_player,
			Quaternion(Vector3.UP, -PI/2).normalized() * direct_to_player
		]
		
		# Cast rays to find a clear path
		var clear_direction = direct_to_player
		for dir in alternative_directions:
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(
				global_position + Vector3(0, 1, 0),  # Start ray from head level
				global_position + Vector3(0, 1, 0) + dir * 3.0
			)
			var result = space_state.intersect_ray(query)
			
			# If no obstacle hit, this is a clear direction
			if result.is_empty():
				clear_direction = dir
				break
		
		# Apply the new direction
		target_position = global_position + clear_direction * 5.0
		
	# If wandering, just pick a new random location
	else:
		# Choose a new random wandering target
		_start_wandering()
		
		# Add a small delay before moving again
		velocity = Vector3.ZERO
		await get_tree().create_timer(0.5).timeout 

func apply_knockback(vec):
	print("getting knocked back!")
	knockback_impulse += vec
	#move_and_slide()
	
