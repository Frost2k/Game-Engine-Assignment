extends Area3D

@export var item_name: String = "Magic Gem"
@export var item_description: String = "A mystical gem that contains pure magical energy"
@export var item_value: int = 10
@export var item_icon: Texture2D
@export var rotation_speed: float = 1.0
@export var hover_height: float = 0.5
@export var hover_speed: float = 1.0
@export var pickup_range: float = 2.0
@export var auto_pickup: bool = false
@export var pickup_sound: AudioStream

# Gem type properties
@export_enum("Purple:0", "Red:1", "Blue:2", "Green:3", "Yellow:4") var gem_type: int = 0
@export var effect_power: float = 1.0

signal item_pickup(item)

var item_data = {
	"id": "magic_gem",
	"name": item_name,
	"description": item_description,
	"value": item_value,
	"icon": null,  # Will be set at runtime if available
	"quantity": 1,
	"stackable": true,
	"max_stack": 99,
	"gem_type": 0,
	"effect_power": 1.0
}

var start_y_pos: float = 0.0
var time_offset: float = 0.0
var gem_colors = [
	Color(0.8, 0.2, 1.0),  # Purple (default)
	Color(1.0, 0.2, 0.2),  # Red
	Color(0.2, 0.4, 1.0),  # Blue
	Color(0.2, 0.8, 0.4),  # Green
	Color(1.0, 0.8, 0.2)   # Yellow
]
var gem_effects = [
	"Magic", # Purple - Basic magic (default)
	"Health", # Red - Health restoration
	"Shield", # Blue - Temporary shield
	"Speed", # Green - Movement speed boost
	"Luck" # Yellow - Increased rare item chance
]

var hover_time: float = 0.0
var player: Node = null
var highlighted = false
var starting_scale = Vector3(1, 1, 1)
var is_being_picked_up = false
var main_material = null
var inner_material = null

func _ready():
	# Connect signals
	body_entered.connect(_on_body_entered)
	
	# Store starting position for hover effect
	start_y_pos = global_position.y
	
	# Random time offset for each gem to prevent all gems from hovering in sync
	time_offset = randf() * 10.0
	
	# Update item data with gem type
	item_data.gem_type = gem_type
	item_data.effect_power = effect_power
	
	# Update name and description based on gem type
	update_gem_properties()
	
	# Create glowing material if it has a MeshInstance3D
	apply_gem_material()
	
	# Add a point light to make it glow
	var light = OmniLight3D.new()
	light.name = "GemLight"
	light.light_color = gem_colors[gem_type]
	light.light_energy = 0.7
	light.omni_range = 2.0
	add_child(light)
	
	# Add a vertical beam to make it more visible
	create_vertical_beam()
	
	# Set item icon if not set
	if item_icon == null and item_data.icon == null:
		# Don't try to load a missing icon, just leave it null
		item_data.icon = null
		
	# Start the beacon effect
	create_beacon_effect()
	
	# Store initial position and scale
	starting_scale = scale
	
	# Initialize audio if needed
	if has_node("PickupSound") and pickup_sound != null:
		$PickupSound.stream = pickup_sound
	
	# Add to Interactable group if not already
	if not is_in_group("Interactable"):
		add_to_group("Interactable")
	if not is_in_group("Item"):
		add_to_group("Item")

func _physics_process(delta):
	if is_being_picked_up:
		return
		
	# Hovering animation
	hover_time += delta * hover_speed
	global_position.y = start_y_pos + sin(hover_time) * hover_height
	
	# Slow rotation
	rotate_y(delta * 0.5)
	
	# Handle auto pickup if enabled
	if auto_pickup and player != null:
		var distance = global_position.distance_to(player.global_position)
		if distance <= pickup_range * 2:  # Double range for auto pickup
			pickup_item(player)

func update_gem_properties():
	# Update name, description and value based on gem type
	item_data.name = gem_effects[gem_type] + " Gem"
	
	match gem_type:
		0: # Purple - Magic
			item_data.description = "A purple gem that restores magical energy."
		1: # Red - Health
			item_data.description = "A red gem that restores health when used."
		2: # Blue - Shield
			item_data.description = "A blue gem that provides a temporary shield."
		3: # Green - Speed
			item_data.description = "A green gem that temporarily increases movement speed."
		4: # Yellow - Luck
			item_data.description = "A golden gem that increases your luck finding rare items."
	
	# Update the exported values to match item_data
	item_name = item_data.name
	item_description = item_data.description
	item_value = round(10 * effect_power)

# Updates the gem's appearance based on the current gem_type
func update_gem_appearance():
	# Update properties first to ensure consistent state
	update_gem_properties()
	
	# Update the material for visual appearance
	apply_gem_material()
	
	# Update the light color if it exists
	if has_node("OmniLight3D"):
		$OmniLight3D.light_color = gem_colors[gem_type]
	
	# Update any other visual elements
	if has_node("GemLight"):
		$GemLight.light_color = gem_colors[gem_type]
	
	# Update the item icon if we're using different icons per type
	var icon_path = "res://assets/Rocks and Gems/" + str(gem_type + 1) + ".png"
	var icon = load(icon_path)
	if icon:
		item_icon = icon
		item_data.icon = icon
		print("Updated gem icon to: " + icon_path)
	
	# Log the update
	print("Updated gem appearance to type: " + gem_effects[gem_type])

func apply_gem_material():
	if has_node("MeshInstance3D"):
		var mesh_instance = $MeshInstance3D
		
		# Create a new standard material
		var material = StandardMaterial3D.new()
		
		# Set the emission color to match the gem type
		material.emission_enabled = true
		material.emission = gem_colors[gem_type]
		material.emission_energy_multiplier = 1.2
		
		# Set base color (slightly darker than emission)
		var base_color = gem_colors[gem_type]
		base_color = base_color.darkened(0.3)
		base_color.a = 0.9
		material.albedo_color = base_color
		
		# Add some metallic and specular reflection
		material.metallic = 0.7
		material.roughness = 0.1
		
		# Apply the material
		mesh_instance.material_override = material
		
		# Also apply to inner gem if it exists
		if has_node("InnerGem"):
			$InnerGem.material_override = material

func _on_body_entered(body):
	# Check if it's the player
	if body.is_in_group("Player"):
		# Check if player is close enough (to prevent picking through walls)
		var distance = global_position.distance_to(body.global_position)
		if distance <= pickup_range:
			pickup_item(body)

func pickup_item(player):
	if is_being_picked_up:
		return
		
	is_being_picked_up = true
	self.player = player
	
	# Check if player can pick up (has inventory system)
	if player.has_method("add_to_inventory"):
		# Create a copy of the item data for the player
		var item_copy = {
			"id": "magic_gem",
			"name": item_name,
			"description": item_description,
			"value": item_value,
			"icon": item_icon,
			"gem_type": gem_type,
			"effect_power": effect_power,
			"stackable": true,
			"quantity": 1
		}
		
		# Print debug info
		print("Attempting to add gem to inventory: " + item_name + " (Type: " + str(gem_type) + ")")
		
		# Add to player inventory
		if player.add_to_inventory(item_copy):
			# Play pickup sound if available
			if has_node("PickupSound") and $PickupSound is AudioStreamPlayer3D:
				$PickupSound.global_position = global_position
				$PickupSound.play()
				
			# Emit the signal with the item data
			emit_signal("item_pickup", item_copy)
			
			# Update global stats if available
			if get_node_or_null("/root/Global"):
				# This is the ONLY place where collect_gem should be called
				get_node("/root/Global").collect_gem(gem_type, item_value)
				print("Global.collect_gem called with type: " + str(gem_type) + ", value: " + str(item_value))
			
			# Get the current position before we're removed
			var gem_position = global_position
			
			# Create particle effect
			create_pickup_particles(gem_position)
			
			# Wait for sound to finish before removing
			await get_tree().create_timer(0.5).timeout
			
			# Remove the gem from the scene
			queue_free()
			print("Gem successfully added to inventory and removed from scene")
		else:
			# Failed to add to inventory
			is_being_picked_up = false
			print("Failed to add gem to inventory - inventory might be full")
	else:
		# Player does not have method to add to inventory
		is_being_picked_up = false
		print("Player does not have add_to_inventory method")

# Creates particle effects for gem pickup
func create_pickup_particles(position):
	var main_scene = get_tree().current_scene
	
	# Create the particle node
	var particles = GPUParticles3D.new()
	particles.name = "GemPickupParticles"
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.global_position = position
	particles.amount = 24
	particles.lifetime = 1.0
	
	# Particles automatically remove themselves when done
	particles.process_material = create_particle_material()
	
	# Add a mesh to particles - simple sphere
	var mesh = SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1
	particles.draw_pass_1 = mesh
	
	# Add to scene
	main_scene.add_child(particles)
	
	# Self-destruct after particles finish
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.autostart = true
	particles.add_child(timer)
	timer.timeout.connect(func(): particles.queue_free())

# Creates a particle material based on gem type
func create_particle_material():
	var particle_material = ParticleProcessMaterial.new()
	
	# Common settings
	particle_material.direction = Vector3(0, 1, 0)
	particle_material.spread = 60.0
	particle_material.initial_velocity_min = 2.0
	particle_material.initial_velocity_max = 5.0
	particle_material.gravity = Vector3(0, -9.8, 0)
	particle_material.scale_min = 0.8
	particle_material.scale_max = 1.2
	
	# Color based on gem type
	particle_material.color = gem_colors[gem_type]
	
	# Remove the trail_enabled property as it's causing errors
	# particle_material.trail_enabled = true
	# particle_material.trail_lifetime = 0.2
	
	return particle_material

# Called when the player is in range but needs to press a key to pick up
func interact():
	# This is called when player presses the interaction key while looking at the gem
	if player != null:
		pickup_item(player)

func get_player_in_range():
	# Get all overlapping bodies and check if player is among them
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("Player"):
			return body
	return null

# Optional method to highlight when player is near
func highlight(enable: bool = true):
	if highlighted == enable:
		return
	
	highlighted = enable
	
	if enable:
		# Scale up slightly
		var tween = create_tween()
		tween.tween_property(self, "scale", starting_scale * 1.2, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		# Increase glow/emission
		if main_material and main_material is StandardMaterial3D:
			var mat_tween = create_tween()
			mat_tween.tween_property(main_material, "emission_energy_multiplier", 5.0, 0.2)
		
		# Increase light intensity
		if has_node("GemLight"):
			var light_tween = create_tween()
			light_tween.tween_property($GemLight, "light_energy", 4.0 + effect_power, 0.2)
	else:
		# Scale back to normal
		var tween = create_tween()
		tween.tween_property(self, "scale", starting_scale, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		# Reset glow/emission
		if main_material and main_material is StandardMaterial3D:
			var mat_tween = create_tween()
			mat_tween.tween_property(main_material, "emission_energy_multiplier", 3.0, 0.2)
		
		# Reset light intensity
		if has_node("GemLight"):
			var light_tween = create_tween()
			light_tween.tween_property($GemLight, "light_energy", 2.0 + (effect_power * 0.5), 0.2)

# Creates a vertical beam of light to make gem visible from a distance
func create_vertical_beam():
	# Create a vertical line mesh
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "VerticalBeam"
	
	# Create a cylinder mesh for the beam
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.1  # Increased from 0.05
	cylinder.bottom_radius = 0.3  # Wider at bottom for better visibility
	cylinder.height = 15.0  # Increased from 10.0 for better visibility
	
	# Create material for beam
	var material = StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = gem_colors[gem_type]
	material.emission_energy_multiplier = 5.0  # Increased from 3.0
	material.albedo_color = Color(1, 1, 1, 0.6)  # More opaque for better visibility
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# Apply material to mesh
	cylinder.material = material
	mesh_instance.mesh = cylinder
	
	# Position beam to extend upward (Y-axis is up in Godot)
	# Adjust position to place bottom of beam at gem level
	# Since cylinder origin is at center, move up by half the height
	mesh_instance.position = Vector3(0, cylinder.height/2, 0)
	
	# Add to gem
	add_child(mesh_instance)
	
	# Add a floor marker directly below the gem
	create_floor_marker()

# Creates a marker on the floor to help locate the gem
func create_floor_marker():
	# Create a flat disk to mark the floor below the gem
	var marker = MeshInstance3D.new()
	marker.name = "FloorMarker"
	
	# Create a circular mesh
	var circle = CylinderMesh.new()
	circle.top_radius = 0.7  # Wider than the beam
	circle.bottom_radius = 0.7
	circle.height = 0.05  # Very thin
	
	# Create material for marker
	var material = StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = gem_colors[gem_type]
	material.emission_energy_multiplier = 3.0
	material.albedo_color = Color(1, 1, 1, 0.8)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# Apply material to mesh
	circle.material = material
	marker.mesh = circle
	
	# Cast ray to find floor position
	var space_state = get_world_3d().direct_space_state
	var ray_origin = global_position
	var ray_end = ray_origin + Vector3(0, -50, 0)  # Cast ray downward
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result:
		# Place marker at hit position, slightly above to prevent z-fighting
		marker.global_position = result.position + Vector3(0, 0.05, 0)
	else:
		# If no floor found, place marker at a fixed distance below
		marker.global_position = global_position + Vector3(0, -5, 0)
	
	# Add marker to scene (not as child of gem)
	get_tree().current_scene.add_child(marker)
	
	# Animate the marker to pulse
	var tween = create_tween()
	tween.set_loops()
	
	if marker.mesh.material is StandardMaterial3D:
		var marker_material = marker.mesh.material
		tween.tween_property(marker_material, "emission_energy_multiplier", 5.0, 1.0)
		tween.tween_property(marker_material, "emission_energy_multiplier", 2.0, 1.0)

# Creates a pulsing beacon effect to draw attention to the gem
func create_beacon_effect():
	# Create a repeating animation to pulse the gem's light intensity
	var tween = create_tween()
	tween.set_loops()  # Repeat indefinitely
	
	# Get the light node
	var light = get_node_or_null("GemLight")
	if light:
		# Pulse the light intensity
		tween.tween_property(light, "light_energy", 2.0, 1.0)
		tween.tween_property(light, "light_energy", 0.7, 1.0)
		
	# Also animate the emission energy of the vertical beam
	var beam = get_node_or_null("VerticalBeam")
	if beam and beam.mesh.material is StandardMaterial3D:
		var beam_material = beam.mesh.material
		tween.tween_property(beam_material, "emission_energy_multiplier", 5.0, 1.0)
		tween.tween_property(beam_material, "emission_energy_multiplier", 2.0, 1.0) 
