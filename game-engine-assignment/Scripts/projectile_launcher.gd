extends Node3D

const PROJECTILE = preload("res://scenes/projectile.tscn")

@onready var timer: Timer = $Timer

func _physics_process(delta: float) -> void:
	if timer.is_stopped():
		if Input.is_action_pressed("shoot"):
			timer.start()
			var attack = PROJECTILE.instantiate() as RayCast3D
			add_child(attack)
			attack.global_transform = global_transform
