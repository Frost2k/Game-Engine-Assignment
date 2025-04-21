extends Node3D  # or KinematicBody2D if you're on Godot 3.x

@export var speed := 50
@export var attack_range := 100
@export var attack_interval := 2.0  # seconds between attacks

var player
var anim_player
var attack_timer := 0.0

func _ready():
	anim_player = get_node("AnimationPlayer")

	player = get_node("/root/Main/ProtoController")
	if not player:
		print("Warning: ProtoController not found!")

func _process(delta):
	if not player:
		return

	var distance_to_player = global_position.distance_to(player.global_position)
	attack_timer -= delta

	if distance_to_player < attack_range:
		_attack_player()
	else:
		_wander(delta)

func _wander(delta):
	# Example idle animation logic — could be patrolling or pacing
	anim_player.play("Walking_A")

	# Optional pacing behavior:
	# move_and_slide(Vector2.LEFT * speed)  # Replace with real movement pattern

func _attack_player():
	if attack_timer <= 0.0:
		attack_timer = attack_interval

		var action = randi() % 2  # Random: 0 = cast, 1 = shoot
		if action == 0:
			anim_player.play("Spellcast_Long")
			# Add projectile or spell logic here
		else:
			anim_player.play("Spellcast_Shoot")
			# Add projectile or shoot logic here
