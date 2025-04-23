extends "res://Scripts/enemy3d.gd"

var movement_speed: float = 3.0

# If there is an offset between desired height and a player's real height
@export var height_offset_fix = 0.406784058


@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

@onready var proto_controller: CharacterBody3D = get_node_or_null("../ProtoController") if get_node_or_null("../ProtoController") else get_node_or_null("../../ProtoController")

@export_group("Movement")
@export var jump_impulse = 0.4
@export var chase_movement_speed: float = 3.0
@export var wander_movement_speed: float = 1.0

# detect the mage getting "stuck"
var last_position
var real_velocity

func _ready():
	
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5

	# Make sure to not await during _ready.
	actor_setup.call_deferred()
	

	# Remove from any existing groups to avoid duplicates
	if is_in_group("Enemy"):
		remove_from_group("Enemy")
	
	# Add to the enemy group and print confirmation
	add_to_group("Enemy")
	print(name, " added to 'Enemy' group")
	
	# Force trigger position update
	# Get the animation player
	if has_node("skeleton_mage/AnimationPlayer"):
		animation_player = $skeleton_mage/AnimationPlayer
	elif has_node("AnimationPlayer"):
		animation_player = $AnimationPlayer
	
	super._ready()
	

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame

	# Now that the navigation map is no longer empty, set the movement target.


func get_npc_state():
	return 'chase'

func nearest_player_position():
	return proto_controller.global_position

#func _physics_process(delta):
func _process_chase_state(delta):
	#if navigation_agent.is_navigation_finished():
		#return
	#if get_npc_state() == 'chase':
	movement_speed = chase_movement_speed
	navigation_agent.target_position = nearest_player_position()
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	_navigate_to(delta, next_path_position)
	
	if not is_on_floor():
		animation_player.play("Jump_Full_Long")
	elif velocity.length_squared() > 0.1:
		animation_player.play("Walking_A")
	else:
		animation_player.play("Idle")

func _navigate_to(delta, next_path_position):
	# navigate according to path
	var current_agent_position: Vector3 = global_position

	#var diff = current_agent_position.direction_to(next_path_position) 
	var diff = (next_path_position - current_agent_position)
	
	# correct the height offset
	diff = Vector3(diff.x, diff.y - height_offset_fix, diff.z)
	var diff_normal = diff.normalized()
	
	
	# path position (on ground) is always -18.4204998016357
	# real position is -18.8272838592529
	# offset is 0.406784058
	#print(next_path_position.y, current_agent_position.y)
	#print(diff.y)
	
	#var flat_diff = Vector3(diff.x, 0, diff.z)
	var want_velocity = diff_normal * movement_speed
	velocity.x = want_velocity.x
	velocity.z = want_velocity.z
	
	if not is_on_floor():
		velocity.y += (get_gravity().y * delta)
	
	#print(diff.y)
	#if diff.y >= 0.1 and is_on_wall():
		##pass
		### need to jump
		##$skeleton_mage2/AnimationPlayer.play("Idle")
		##print("Need to jump")
		#if not is_on_floor():
			###print("Is on air?")
			###velocity.y = 0.0
		###else:
			#print("Jumping")
			##animation_player.play("Jump_Full_Long")
			#velocity.y += jump_impulse
	#el

	
	
	# Gravity
	#if not is_on_floor():
		#velocity += get_gravity()
	#look_at(next_path_position)
 	# Create a temporary transform
	var temp_transform = global_transform
	
	# Make it look at the target
	var flat_path_position: Vector3 = Vector3(next_path_position)
	flat_path_position.y = current_agent_position.y
	temp_transform = temp_transform.looking_at(flat_path_position, Vector3.UP)

	global_transform.basis = global_transform.basis.slerp(temp_transform.basis, 0.1)

	move_and_slide()


func _start_wandering():
	# Generate a random angle in radians
	movement_speed = wander_movement_speed
	var random_angle = randf() * 2 * PI
	
	# Calculate target position using trigonometry
	var target_offset = Vector3(cos(random_angle), 0, sin(random_angle)) * wander_radius
	var target_position = spawn_position + target_offset

	# Set the navigation agent's target position
	navigation_agent.target_position = target_position


#func _physics_process(delta):
func _process_wander_state(delta):
	movement_speed = wander_movement_speed
	var current_agent_position: Vector3 = global_position
	if navigation_agent.is_navigation_finished():
		_start_wandering()
	
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	_navigate_to(delta, next_path_position)
	#print("wander")
	#animation_player.play("Walking_A")
	if not is_on_floor():
		animation_player.play("Jump_Full_Long")
	elif velocity.length_squared() > 0.1:
		animation_player.play("Walking_A")
	else:
		animation_player.play("Idle")

#func _on_timer_timeout():
	## On poll event
	#print("Timeout occured")
	#var proto_controller = get_node("../ProtoController")
	#
	#if not proto_controller:
		#proto_controller = get_node("../../ProtoController")
		#
	#if proto_controller:
		## Call the set_movement_target function with the ProtoController's position
		#set_movement_target(proto_controller.global_position)
	#else:
		#push_error("ProtoController not found")

func _handle_obstacle_collision():
	# try to jump
	pass

	
