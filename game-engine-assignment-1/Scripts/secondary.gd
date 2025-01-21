extends Node2D

@export var speed = 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	var cpp_node = $".."
	var x = Vector2(600, 600)
	move(x)
	speed = 10000


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# pass
	var direction = Vector2(0, 0)
	
	if (Input.is_action_pressed("ui_up")):
		direction.y -= 1
	
	if (Input.is_action_pressed("ui_down")):
		direction.y += 1
	
	if (Input.is_action_pressed("ui_left")):
		direction.x -= 1
	
	if (Input.is_action_pressed("ui_right")):
		direction.x += 1
	
	move(direction.normalized() * speed * delta)

func move(direction: Vector2) -> void:
	translate(direction)
