extends Area2D

@export var fall_speed: float = 50.0

func _process(delta: float) -> void:
	# Move the block straight down
	position.y += fall_speed * delta
	
	# Optional: remove the block if it goes off-screen
	if position.y > get_viewport_rect().size.y + 50:
		queue_free()
