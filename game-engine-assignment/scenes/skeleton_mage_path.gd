extends PathFollow3D

@export var speed := 5.0
@export var attack_range := 1000.0
@export var attack_interval := 2.0

var skeleton_mage
var anim_player
var player
var attack_timer = 0.0

enum State { WANDER, ATTACK }
var state = State.WANDER

func _ready():
	skeleton_mage = get_node("skeleton_mage")
	anim_player = skeleton_mage.get_node("AnimationPlayer")
	player = get_tree().get_current_scene().get_node("ProtoController")
	anim_player.play("Walking_A")

func _process(delta):
	if not player:
		return

	var distance_to_player = global_position.distance_to(player.global_position)
	attack_timer -= delta

	# Switch states
	if distance_to_player < attack_range:
		state = State.ATTACK
	else:
		state = State.WANDER

	match state:
		State.WANDER:
			anim_player.play("Walking_A")
			progress += speed * delta
		State.ATTACK:
			if attack_timer <= 0.0:
				attack_timer = attack_interval
				var action = randi() % 2
				if action == 0:
					anim_player.play("Spellcast_Long")
				else:
					anim_player.play("Spellcast_Shoot")
