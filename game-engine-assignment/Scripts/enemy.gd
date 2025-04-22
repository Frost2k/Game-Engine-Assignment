extends CharacterBody2D

var speed = 40
var player_chase = false
var player = null

var health = 100
var player_inattack_zone = false
var can_take_damage = true

# Exported drop variables for configuration in editor
@export_group("Drops")
@export var drop_gem_chance: float = 0.75  # Default 75% chance to drop a gem
@export var gem_scene_path: String = "res://scenes/magic_gem.tscn"
@export_enum("Random", "Purple:0", "Red:1", "Blue:2", "Green:3", "Yellow:4") var fixed_gem_type: int = 0
@export var force_gem_drop: bool = false  # If true, always drops a gem

func _physics_process(delta):
	deal_with_damage()
	update_health()
	
	if player_chase:
		position += (player.position - position)/speed
		
		$AnimatedSprite2D.play("walk")
		
		if(player.position.x - position.x) < 0:
			$AnimatedSprite2D.flip_h = true
		else:
			$AnimatedSprite2D.flip_h = false
	else:
		$AnimatedSprite2D.play("idle")


func _on_detection_area_body_entered(body: Node2D) -> void:
	player = body
	player_chase = true


func _on_detection_area_body_exited(body: Node2D) -> void:
	player = null
	player_chase = false
	
func enemy():
	pass


func _on_ememy_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		player_inattack_zone = true


func _on_ememy_hitbox_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		player_inattack_zone = false
		
func deal_with_damage():
	if player_inattack_zone and Global.player_current_attack == true:
		if can_take_damage == true:
			health = health - 20
			$take_damage_cooldown.start()
			can_take_damage = false
			#print("slime health = ", health)
			if health <= 0:
				# Check if we should spawn a gem
				var should_spawn_gem = force_gem_drop
				
				if not should_spawn_gem:
					# Check global settings if available
					if "Global" in get_node("/root") and Global.has_method("apply_luck_to_chance"):
						var drop_chance = Global.apply_luck_to_chance(drop_gem_chance)
						var rng = RandomNumberGenerator.new()
						rng.randomize()
						should_spawn_gem = rng.randf() <= drop_chance
					else:
						# Default chance if Global isn't available
						var rng = RandomNumberGenerator.new()
						rng.randomize()
						should_spawn_gem = rng.randf() <= drop_gem_chance
				
				# Always drop gems for special enemies
				if name.to_lower().contains("boss") or name.to_lower().contains("elite"):
					should_spawn_gem = true
				
				if should_spawn_gem:
					spawn_gem()
				
				self.queue_free()
	


func _on_take_damage_cooldown_timeout() -> void:
	can_take_damage = true
	
func update_health():
	var healthbar = $healthbar
	
	healthbar.value = health
	
	if health >= 100:
		healthbar.visible = false
	else:
		healthbar.visible = true

# Function to spawn a gem when the enemy is defeated
func spawn_gem():
	# Load the gem scene
	print("=== SPAWN GEM ATTEMPT ===")
	print("Attempting to spawn gem at position " + str(global_position))
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
		var spawn_position = global_position + Vector2(0, -10)  # Slightly above the enemy
		print("Target spawn position: " + str(spawn_position))
		
		# Add the gem to the main scene
		main_scene.add_child(gem)
		print("Gem added to scene tree")
		
		# Set position after adding to scene
		gem.global_position = spawn_position
		
		# Determine gem type
		var gem_type = 0  # Default to purple (magic)
		
		# Use fixed gem type if specified, otherwise use random
		if fixed_gem_type > 0:
			gem_type = fixed_gem_type - 1  # Adjust for enum offset (Random is 0)
		else:
			# Randomize gem type with weighted probabilities
			var rng = RandomNumberGenerator.new()
			rng.randomize()
			var rarity_roll = rng.randf()
			
			if rarity_roll < 0.45:  # 45% chance for purple (magic)
				gem_type = 0
			elif rarity_roll < 0.70:  # 25% chance for red (health)
				gem_type = 1
			elif rarity_roll < 0.85:  # 15% chance for blue (shield)
				gem_type = 2
			elif rarity_roll < 0.95:  # 10% chance for green (speed)
				gem_type = 3
			else:  # 5% chance for yellow (luck - rarest)
				gem_type = 4
		
		# Set the gem type
		gem.gem_type = gem_type
		
		# Randomize gem value based on enemy strength and gem type
		var base_value = 5 + (gem_type * 3)  # Higher types are worth more
		gem.item_value = randi_range(base_value, base_value + 10)
		
		# Set effect power based on enemy type
		gem.effect_power = 1.0 + (gem_type * 0.15)
		
		# Make sure the gem updates its appearance based on the type
		if gem.has_method("update_gem_appearance"):
			gem.update_gem_appearance()
		elif gem.has_method("update_gem_properties"):
			gem.update_gem_properties()
			if gem.has_method("apply_gem_material"):
				gem.apply_gem_material()
		
		# Make sure it's visible
		gem.visible = true
		
		# Add a "pop-up" effect
		gem.scale = Vector2(0.1, 0.1)  # Start small
		var tween = create_tween()
		tween.tween_property(gem, "scale", Vector2(1, 1), 0.3).set_ease(Tween.EASE_OUT)
		
		print("Gem successfully spawned with type: " + str(gem_type))
	else:
		push_error("Failed to load gem scene from: " + gem_scene_path)
