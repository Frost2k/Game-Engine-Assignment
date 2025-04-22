extends Node3D

# Enemy stats
@export_group("Enemy Stats")
@export var health : float = 100.0
@export var max_health : float = 100.0
@export var damage : float = 20.0
@export var attack_range : float = 3.0
@export var attack_cooldown : float = 2.0
@export var detection_range : float = 15.0
@export var movement_speed : float = 2.0

# State management
var player_ref = null
var is_dead : bool = false
var can_attack : bool = true
var is_chasing : bool = false

# Components
@onready var healthbar = $HealthBar
@onready var attack_timer = $AttackTimer
@onready var animation_player = $AnimationPlayer
@onready var mesh_instance = $skeleton_mage if has_node("skeleton_mage") else get_node(".")

# Original material color for resetting after effects
var original_color = Color.WHITE

func _ready():
	# Make sure enemy is in the Enemy group for minimap
	if not is_in_group("Enemy"):
		add_to_group("Enemy")
	print(name, " added to 'Enemy' group")
	
	# Initialize health
	health = max_health
	
	# Setup attack timer
	if not has_node("AttackTimer"):
		attack_timer = Timer.new()
		attack_timer.name = "AttackTimer"
		attack_timer.wait_time = attack_cooldown
		attack_timer.one_shot = true
		add_child(attack_timer)
		attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	# Hide healthbar initially
	if healthbar:
		healthbar.max_value = max_health
		healthbar.value = max_health
		healthbar.visible = false
		
	# Store original material color if available
	store_original_material()

# Store the original material color for later resets
func store_original_material():
	# Check direct mesh instance
	if mesh_instance and mesh_instance is MeshInstance3D and mesh_instance.get_surface_override_material(0):
		var material = mesh_instance.get_surface_override_material(0)
		if material is BaseMaterial3D:
			original_color = material.albedo_color
	
	# If not found, check children for mesh instances
	if original_color == Color.WHITE:
		for child in get_children():
			if child is MeshInstance3D and child.get_surface_override_material(0):
				var material = child.get_surface_override_material(0)
				if material is BaseMaterial3D:
					original_color = material.albedo_color
					mesh_instance = child
					break

# Change mesh color for visual effects
func set_mesh_color(color: Color):
	# First try to find a MeshInstance3D
	var target_mesh = null
	
	if mesh_instance and mesh_instance is MeshInstance3D:
		target_mesh = mesh_instance
	else:
		# Search for mesh in children
		for child in get_children():
			if child is MeshInstance3D:
				target_mesh = child
				break
	
	# Apply color change if mesh found
	if target_mesh:
		# Check if the mesh already has a material
		var material = null
		if target_mesh.get_surface_override_material(0):
			material = target_mesh.get_surface_override_material(0).duplicate()
		else:
			material = StandardMaterial3D.new()
		
		# Apply new color
		if material is BaseMaterial3D:
			material.albedo_color = color
			target_mesh.set_surface_override_material(0, material)
	
	# If no mesh, print debug info
	else:
		print(name, " could not find a mesh to change color")

func _physics_process(delta):
	if is_dead:
		return
	
	# Try to find player if we don't have one
	if not player_ref:
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			player_ref = players[0]
		else:
			return
	
	# Check distance to player
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	# Detection logic
	if distance_to_player <= detection_range:
		is_chasing = true
		
		# Look at player (Y-axis only)
		var look_pos = player_ref.global_position
		look_pos.y = global_position.y  # Keep same height
		look_at(look_pos)
		
		# Attack if close enough
		if distance_to_player <= attack_range:
			if can_attack:
				attack()
			# Play attack animation
			if animation_player and animation_player.has_animation("attack"):
				animation_player.play("attack")
			else:
				# Visual feedback with material change instead of modulate
				set_mesh_color(Color.RED)
				await get_tree().create_timer(0.2).timeout
				set_mesh_color(original_color)
		else:
			# Move toward player
			var direction = (player_ref.global_position - global_position).normalized()
			direction.y = 0  # Keep movement on XZ plane
			
			# Apply movement
			global_position += direction * movement_speed * delta
			
			# Play walk animation
			if animation_player and animation_player.has_animation("walk"):
				animation_player.play("walk")
	else:
		is_chasing = false
		# Play idle animation
		if animation_player and animation_player.has_animation("idle"):
			animation_player.play("idle")

# Handle taking damage
func take_damage(amount):
	if is_dead:
		return
	
	health -= amount
	
	# Update health display
	if healthbar:
		healthbar.value = health
		healthbar.visible = true
	
	# Play hit effect/animation
	if animation_player and animation_player.has_animation("hit"):
		animation_player.play("hit")
	else:
		# Visual feedback with material change instead of modulate
		set_mesh_color(Color.RED)
		await get_tree().create_timer(0.2).timeout
		set_mesh_color(original_color)
	
	print(name, " took damage! Health: ", health)
	
	# Check if dead
	if health <= 0:
		die()

# Attack the player if in range
func attack():
	if is_dead or not can_attack or not player_ref:
		return
	
	# Deal damage to player
	if player_ref.has_method("take_damage"):
		player_ref.take_damage(damage)
		print(name, " attacked player!")
	
	# Start cooldown
	can_attack = false
	attack_timer.start()

# Handle death
func die():
	is_dead = true
	print(name, " died!")
	
	# Play death animation
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
		await animation_player.animation_finished
	else:
		# Use material for death effect instead of modulate
		var fade_color = Color(0.5, 0.5, 0.5, 0.5)
		set_mesh_color(fade_color)
	
	# Disable collision
	for child in get_children():
		if child is CollisionShape3D or child is CollisionPolygon3D:
			child.disabled = true
	
	# Remove after delay
	await get_tree().create_timer(2.0).timeout
	queue_free()

# Reset attack cooldown
func _on_attack_timer_timeout():
	can_attack = true
