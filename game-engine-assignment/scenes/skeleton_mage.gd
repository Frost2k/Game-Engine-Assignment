extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Remove from any existing groups to avoid duplicates
	if is_in_group("Enemy"):
		remove_from_group("Enemy")
	
	# Add to the enemy group and print confirmation
	add_to_group("Enemy")
	print(name, " added to 'Enemy' group")
	
	# Force trigger position update
	_process(0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Ensure position is updated
	global_position = global_position
