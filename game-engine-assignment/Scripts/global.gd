extends Node

# Global singleton for game-wide variables and constants

# Player stats
var player_current_attack = false

# Drop rate modifiers
var luck_multiplier: float = 1.0

# Gem system
var gem_drop_enabled: bool = true
var gem_drop_base_chance: float = 0.75  # 75% chance for an enemy to drop a gem

# Game stats
var gems_collected: int = 0
var enemies_defeated: int = 0

# Gem counts by type
var gem_counts = {
	0: 0,  # Purple (Magic)
	1: 0,  # Red (Health)
	2: 0,  # Blue (Shield)
	3: 0,  # Green (Speed)
	4: 0   # Yellow (Luck)
}

# Gem types and their probabilities
var gem_type_names = ["Magic", "Health", "Shield", "Speed", "Luck"]
var gem_type_colors = [
	Color(0.92, 0.2, 0.988), # Purple (Magic)
	Color(0.9, 0.2, 0.2),    # Red (Health)
	Color(0.2, 0.4, 0.9),    # Blue (Shield)
	Color(0.2, 0.9, 0.4),    # Green (Speed)
	Color(0.9, 0.8, 0.2)     # Yellow (Luck)
]

var current_scene_ = "world" #world or cliff_side
var transition_scene = false

var player_exit_cliffside_posx = 199
var player_exit_cliffside_posy = 18
var player_start_posx = 159
var player_start_posy = 127

var game_first_loadin = true

signal gem_collected(gem_type, value)

# Game state
var game_started: bool = false
var current_level: int = 1

func _ready():
	print("Global singleton initialized")
	
	# Connect to own signal to update internal gem counts
	gem_collected.connect(_on_gem_collected)

func finish_changescenes(current_scene):
	if transition_scene == true:
		transition_scene = false
		current_scene_ = current_scene
		print("This is in Global: ", current_scene_)
		
# Function to handle gem collection
func collect_gem(gem_type: int, value: int) -> void:
	gems_collected += 1
	
	# Increment specific gem type count
	if gem_type >= 0 and gem_type < 5:
		gem_counts[gem_type] += 1
		print("Incrementing " + gem_type_names[gem_type] + " gem count to " + str(gem_counts[gem_type]))
	
	# Log collection
	var gem_name = gem_type_names[gem_type] if gem_type < gem_type_names.size() else "Unknown"
	print("Collected " + gem_name + " gem worth " + str(value) + " points!")
	
	# Emit signal for gems collected
	emit_signal("gem_collected", gem_type, value)

# Apply luck to drop chances
func apply_luck_to_chance(base_chance: float) -> float:
	return min(base_chance * luck_multiplier, 1.0)
		
# Get count of specific gem type
func get_gem_count(gem_type: int) -> int:
	if gem_type >= 0 and gem_type < gem_counts.size():
		return gem_counts[gem_type]
	return 0

# Called when a gem is collected
func _on_gem_collected(gem_type: int, value: int) -> void:
	# This function ensures the internal counts stay updated
	# Already handled in collect_gem, but kept for future extensibility
	pass

func add_gem(gem_type: int):
	if gem_type >= 0 and gem_type < gem_counts.size():
		gem_counts[gem_type] += 1
		gems_collected += 1

func use_gem(gem_type: int) -> bool:
	if gem_type >= 0 and gem_type < gem_counts.size() and gem_counts[gem_type] > 0:
		gem_counts[gem_type] -= 1
		return true
	return false

# Reset game state
func reset_game():
	gems_collected = 0
	enemies_defeated = 0
	luck_multiplier = 1.0
	gem_counts = [0, 0, 0, 0, 0]
	current_level = 1
