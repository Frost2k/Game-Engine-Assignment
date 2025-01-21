extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# pass # Replace with function body.
	var cpp_node = $".."
	var x = Vector2(600, 600)
	cpp_node.move(x)
	cpp_node.speed = 10000


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
