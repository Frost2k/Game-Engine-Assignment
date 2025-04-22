extends Control

# Called when the node enters the scene tree for the first time
func _ready():
	# Add to GemUI group so it can be found easily by other scripts
	if not is_in_group("GemUI"):
		add_to_group("GemUI")
		print("GemUI added to 'GemUI' group")
	
	# Wait a frame to ensure everything is properly set up
	await get_tree().process_frame
	
	# Connect to Global's gem_collected signal if it exists
	var global = get_node_or_null("/root/Global")
	if global and global.has_signal("gem_collected"):
		if not global.is_connected("gem_collected", _on_gem_collected):
			global.connect("gem_collected", _on_gem_collected)
			print("Connected to Global's gem_collected signal")
	
	# Initialize UI
	update_gem_display()

# Handle gem_collected signal
func _on_gem_collected(gem_type, value):
	print("GemUI received gem_collected signal: type=" + str(gem_type) + ", value=" + str(value))
	update_gem_display()

# Update gem display based on inventory contents
func update_gem_display():
	# Get reference to gems container
	if !has_node("HBoxContainer"):
		print("Error: HBoxContainer not found in GemUI")
		return
		
	var gems_container = $HBoxContainer
	
	# Get gem counts from inventory or global
	var gem_counts = [0, 0, 0, 0, 0]
	
	# Check if Global singleton exists and has gems data
	var global_node = get_node_or_null("/root/Global")
	
	if global_node:
		# If Global tracks gem counts, use those values
		if global_node.has_method("get_gem_count"):
			for i in range(5):
				gem_counts[i] = global_node.get_gem_count(i)
				print("Global gem count for type " + str(i) + ": " + str(gem_counts[i]))
		# Otherwise check if it has direct gem count variables
		elif "gems_collected" in global_node:
			# Just use total count for first gem type
			gem_counts[0] = global_node.gems_collected
			print("Using global.gems_collected: " + str(gem_counts[0]))
	
	# Get gem panels
	var gem_types = ["Magic", "Health", "Shield", "Speed", "Luck"]
	for i in range(gem_types.size()):
		var gem_path = gem_types[i] + "Gem"
		var counter_path = gem_path + "/Counter"
		
		if gems_container.has_node(gem_path) and gems_container.get_node(gem_path).has_node("Counter"):
			var counter = gems_container.get_node(counter_path)
			counter.text = str(gem_counts[i])
			
			# Highlight gems that player has
			var panel = gems_container.get_node(gem_path)
			if gem_counts[i] > 0:
				panel.modulate = Color(1, 1, 1, 1)
			else:
				panel.modulate = Color(0.5, 0.5, 0.5, 0.7)
	
	print("Updated gem UI display") 
