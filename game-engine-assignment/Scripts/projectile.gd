extends RayCast3D

@export var speed := 50.0
@export var damage := 20.0
@export var lifetime := 5.0  # How long the projectile lives before auto-destroying

@onready var remote_transform = RemoteTransform3D.new()

func _ready():
	# Set collision mask to properly detect enemies (layer 2)
	set_collision_mask_value(1, true)  # Default layer (world)
	set_collision_mask_value(2, true)  # Enemy layer
	
	# Set proper length for raycast
	target_position = Vector3(0, 0, -2.0)
	
	# Start lifetime timer
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(cleanup)
	
	# Debug
	print("Projectile created at " + str(global_position) + " with direction " + str(-global_transform.basis.z))

func _physics_process(delta: float) -> void:
	# Move forward
	position += global_basis * Vector3.FORWARD * delta * speed
	
	# Force update raycast to detect collisions immediately
	force_raycast_update()
	
	if is_colliding():
		var collider = get_collider()
		global_position = get_collision_point()
		set_physics_process(false)
		
		# Debug collision - convert NodePath to String
		print("Projectile hit: " + str(collider.get_path()))
		
		# Deal damage to enemies or player
		if collider.has_method("take_damage"):
			# Store pre-damage health if available
			var pre_damage_health = null
			if collider.has_method("get_current_health"):
				pre_damage_health = collider.get_current_health()
			
			# Apply damage
			collider.take_damage(damage)
			
			# Check if damage was applied by comparing health
			var damage_applied = true
			if pre_damage_health != null and collider.has_method("get_current_health"):
				var post_damage_health = collider.get_current_health()
				damage_applied = post_damage_health < pre_damage_health
				
				if damage_applied:
					print("Hit " + collider.name + " for " + str(damage) + " damage!")
				else:
					print("Hit " + collider.name + " but no damage was applied (on cooldown)")
			else:
				# If we can't check health, use default message
				print("Hit " + collider.name + " for " + str(damage) + " damage!")
		
		# Stick arrow to whatever was hit
		if is_instance_valid(collider) and collider is Node3D:
			collider.add_child(remote_transform)
			remote_transform.global_transform = global_transform
			remote_transform.global_position = global_position
			remote_transform.remote_path = remote_transform.get_path_to(self)
			
			# Connect to tree_exited signal if the collider gets deleted
			if collider.has_method("die"):
				remote_transform.tree_exited.connect(cleanup)
		else:
			# If we can't stick to the collider, just remove after a delay
			var timer = get_tree().create_timer(3.0)
			timer.timeout.connect(cleanup)
			
func set_damage(value: float) -> void:
	damage = value
			
func set_direction(direction: Vector3) -> void:
	look_at(global_position + direction, Vector3.UP)
	print("Projectile direction set to: " + str(direction))
			
func cleanup() -> void:
	queue_free()
