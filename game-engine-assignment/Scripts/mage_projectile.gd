extends Area3D

@export var speed: float = 10.0
@export var damage: float = 10.0
@export var lifetime: float = 5.0
@export var gravity_affected: bool = false

var direction: Vector3 = Vector3.FORWARD
var shooter = null

func _ready():
	# Set visual effects
	if has_node("MeshInstance3D"):
		# Add emission to make it glow
		var material = StandardMaterial3D.new()
		material.emission_enabled = true
		material.emission = Color(0.8, 0.2, 1.0)  # Purple magic glow
		material.emission_energy_multiplier = 1.5
		material.albedo_color = Color(0.5, 0.1, 0.8, 0.8)  # Semi-transparent purple
		$MeshInstance3D.material_override = material
		
		# Add a scale animation
		var tween = create_tween().set_loops()
		tween.tween_property($MeshInstance3D, "scale", Vector3(1.2, 1.2, 1.2), 0.5)
		tween.tween_property($MeshInstance3D, "scale", Vector3(1.0, 1.0, 1.0), 0.5)
	
	# Add trail particle effect if it exists
	if has_node("GPUParticles3D"):
		$GPUParticles3D.emitting = true
	
	# Set lifetime
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)
	
	# Connect body entered signal
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Move in the forward direction
	position += direction * speed * delta
	
	# Apply minimal gravity if enabled
	if gravity_affected:
		direction.y -= 9.8 * delta * 0.1

func set_direction(dir: Vector3):
	direction = dir.normalized()
	look_at(global_position + direction, Vector3.UP)

func _on_body_entered(body):
	# Don't hit the shooter
	if body == shooter:
		return
		
	# Apply damage if it's the player
	if body.is_in_group("Player") and body.has_method("take_damage"):
		body.take_damage(damage)
		print("Player hit by mage projectile for ", damage, " damage!")
		
		# Create impact effect
		create_impact_effect()
		
		# Destroy projectile
		queue_free()
	
	# If it's a wall or other obstacle
	elif not body.is_in_group("Enemy"):
		# Create impact effect
		create_impact_effect()
		
		# Destroy projectile
		queue_free()

func create_impact_effect():
	# Create a simple flash effect
	var impact = Node3D.new()
	impact.name = "ImpactEffect"
	get_tree().current_scene.add_child(impact)
	impact.global_position = global_position
	
	# Add a light
	var light = OmniLight3D.new()
	light.light_color = Color(0.8, 0.2, 1.0)  # Purple
	light.light_energy = 2.0
	light.omni_range = 3.0
	impact.add_child(light)
	
	# Make the light fade out
	var tween = create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.3)
	tween.tween_callback(impact.queue_free) 