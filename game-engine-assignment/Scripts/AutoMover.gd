extends Area2D

@export var speed: float = 100.0
@export var left_limit: float = 100.0
@export var right_limit: float = 1000.0

var direction := 1
var score := 0

func _ready() -> void:
	# When another Area2D overlaps this one, call _on_area_entered()
	connect("area_entered", Callable(self, "_on_area_entered"))
	
func _process(delta: float) -> void:
	# Move left or right
	position.x += direction * speed * delta
	
	# Bounce at left/right edges
	if position.x >= right_limit:
		position.x = right_limit
		direction = -1
	elif position.x <= left_limit:
		position.x = left_limit
		direction = 1

func _on_area_entered(overlapping_area: Area2D) -> void:
	# Check if the overlapping area is one of our falling blocks
	# For example, if your script name is "BlockDrop",
	# you can check the node's class or script instance:
	if overlapping_area.get_class() == "BlockDrop":
		score += 1
		print("AutoMover scored! Current score =", score)
		# Optionally remove the block so it doesn't keep scoring:
		# overlapping_area.queue_free()
