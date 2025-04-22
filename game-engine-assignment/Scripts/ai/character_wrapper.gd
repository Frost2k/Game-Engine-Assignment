extends CharacterBody3D

var movement_speed: float = 2.0
var movement_target_position: Vector3 = Vector3(-3.0,0.0,2.0)

var timer: Timer

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

func _ready():
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5

	# Make sure to not await during _ready.
	actor_setup.call_deferred()
	
	# set target to position of $../ProtoController
	timer = Timer.new()
	
	# Set the timer to trigger every 10 seconds
	timer.wait_time = 1.5
	timer.autostart = true
	
	add_child(timer)
	# Connect the timer's timeout signal to our function
	timer.timeout.connect(_on_timer_timeout)
	
	

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame

	# Now that the navigation map is no longer empty, set the movement target.
	set_movement_target(movement_target_position)

func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)

func _physics_process(delta):
	if navigation_agent.is_navigation_finished():
		return

	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()

	velocity = current_agent_position.direction_to(next_path_position) * movement_speed
	
	if velocity.length_squared() > 1.0:
		$skeleton_mage2/AnimationPlayer.play("Walking_A")
	else:
		$skeleton_mage2/AnimationPlayer.play("Idle")
	
	#look_at(next_path_position)
 	# Create a temporary transform
	var temp_transform = global_transform
	
	# Make it look at the target
	temp_transform = temp_transform.looking_at(next_path_position, Vector3.UP)
	
	# Interpolate the current rotation to the desired rotation
	global_transform.basis = global_transform.basis.slerp(temp_transform.basis, 0.25)
	move_and_slide()

func _on_timer_timeout():
	# On poll event
	print("Timeout occured")
	var proto_controller = get_node("../ProtoController")
		
	if proto_controller:
		# Call the set_movement_target function with the ProtoController's position
		set_movement_target(proto_controller.global_position)
	else:
		push_error("ProtoController not found")
	
