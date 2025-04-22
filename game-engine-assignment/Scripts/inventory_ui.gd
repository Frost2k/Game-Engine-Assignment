extends CanvasLayer

signal inventory_closed

@export var slot_scene: PackedScene

var inventory_system = null
var debug_colors = [Color.PURPLE, Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW]

func _ready():
	# Ensure UI is hidden at start
	$Background.visible = false
	$Panel.visible = false
	$DetailsPanel.visible = false
	
	# Load the slot scene if not set in editor
	if slot_scene == null:
		slot_scene = load("res://scenes/inventory_slot.tscn")
		if slot_scene == null:
			push_error("Failed to load inventory_slot.tscn")
	
	# Find inventory system - try different paths
	await get_tree().process_frame
	_find_inventory_system()

func _find_inventory_system():
	# Try to find inventory system in parent
	if get_parent() and get_parent().has_node("InventorySystem"):
		inventory_system = get_parent().get_node("InventorySystem")
	else:
		# Try to find inventory system in player
		var player = get_tree().get_first_node_in_group("Player")
		if player and player.has_node("InventorySystem"):
			inventory_system = player.get_node("InventorySystem")
		else:
			# Try to find at root level
			inventory_system = get_tree().get_first_node_in_group("InventorySystem")
	
	if inventory_system:
		print("Inventory UI connected to inventory system")
	else:
		push_warning("No inventory system found. Inventory UI won't function.")

# Toggle inventory visibility
func toggle():
	if $Panel.visible:
		close()
	else:
		open()

# Show inventory
func open():
	print("InventoryUI.open() called")
	$Background.visible = true
	$Panel.visible = true
	
	# Center the panel on screen
	var viewport_size = get_viewport().size
	$Panel.position = Vector2(viewport_size.x / 2 - $Panel.size.x / 2, 
	                           viewport_size.y / 2 - $Panel.size.y / 2)
	
	# Position the details panel next to the main panel
	if $DetailsPanel:
		$DetailsPanel.position = Vector2($Panel.position.x + $Panel.size.x + 10, 
		                                $Panel.position.y)
	
	# Add a border effect to make the UI more visible
	var panel_style = $Panel.get_theme_stylebox("panel").duplicate()
	if panel_style is StyleBoxFlat:
		panel_style.border_width_left = 3
		panel_style.border_width_top = 3
		panel_style.border_width_right = 3
		panel_style.border_width_bottom = 3
		panel_style.border_color = Color(0.9, 0.8, 0.3, 1.0)  # Gold border
		$Panel.add_theme_stylebox_override("panel", panel_style)
	
	refresh_slots()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Hide inventory
func close():
	$Background.visible = false
	$Panel.visible = false
	$DetailsPanel.visible = false
	inventory_closed.emit()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Refresh slots with current inventory content
func refresh_slots():
	if !inventory_system:
		_find_inventory_system()
		if !inventory_system:
			push_warning("Cannot refresh inventory - no inventory system")
			return
	
	var grid = $Panel/ItemGrid
	if !grid:
		push_warning("ItemGrid not found in Panel")
		return
	
	# Clear existing slots
	for child in grid.get_children():
		child.queue_free()
	
	# Get items from inventory system
	var items = inventory_system.get_inventory_items()
	if not items:
		push_warning("No items returned from inventory system")
		return
		
	print("Refreshing inventory with ", items.size(), " items")
	
	# Count non-null items for debugging
	var item_count = 0
	for item in items:
		if item != null:
			item_count += 1
	print("Non-null items in inventory: ", item_count)
	
	# Fill empty slots up to max inventory size
	var max_slots = inventory_system.max_slots
	for i in range(max_slots):
		var slot = slot_scene.instantiate()
		grid.add_child(slot)
		
		# If there's an item in this slot, show it
		if i < items.size() and items[i] != null:
			var item = items[i]
			var icon = slot.get_node("ItemIcon")
			
			# Debug item info
			print("Slot ", i, ": ", item.get("name", "Unknown"), " (Type: ", item.get("gem_type", "None"), ")")
			
			# Set texture if item has an icon
			if item.has("icon") and item.icon != null:
				icon.texture = item.icon
				icon.modulate = Color(1, 1, 1, 1)
				print("Using item icon for slot ", i)
			else:
				# Use a colored placeholder for debugging
				icon.modulate = debug_colors[item.get("gem_type", 0) % debug_colors.size()]
				print("Using color placeholder for slot ", i, ": ", debug_colors[item.get("gem_type", 0) % debug_colors.size()])
				
			# If stackable and quantity > 1, show count
			if item.has("quantity") and item.get("quantity", 1) > 1:
				var count = slot.get_node("ItemCount") 
				count.text = str(item.quantity)
				count.visible = true
				print("Item in slot ", i, " has quantity: ", item.quantity)
		
		# Connect slot to show details when clicked
		slot.gui_input.connect(_on_slot_gui_input.bind(i))
	
	# Make sure panel is visible
	$Panel.visible = true
	$Background.visible = true

# Handle slot input
func _on_slot_gui_input(event, slot_index):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if inventory_system:
			var item = inventory_system.get_item(slot_index)
			if item:
				show_item_details(item, slot_index)
			else:
				$DetailsPanel.visible = false

# Show item details
func show_item_details(item, index):
	$DetailsPanel.visible = true
	
	# Update details
	$DetailsPanel/ItemName.text = item.get("name", "Unknown Item")
	$DetailsPanel/ItemDescription.text = item.get("description", "No description")
	$DetailsPanel/ItemValue.text = "Value: " + str(item.get("value", 0))
	
	# Connect buttons (safely disconnect first)
	if $DetailsPanel/UseButton.is_connected("pressed", Callable(self, "_on_use_item")):
		$DetailsPanel/UseButton.disconnect("pressed", Callable(self, "_on_use_item"))
	$DetailsPanel/UseButton.pressed.connect(_on_use_item.bind(index))
	
	if $DetailsPanel/DropButton.is_connected("pressed", Callable(self, "_on_drop_item")):
		$DetailsPanel/DropButton.disconnect("pressed", Callable(self, "_on_drop_item"))
	$DetailsPanel/DropButton.pressed.connect(_on_drop_item.bind(index))

# Use selected item
func _on_use_item(index):
	if inventory_system:
		inventory_system.use_item(index)
		refresh_slots()
		$DetailsPanel.visible = false

# Drop selected item
func _on_drop_item(index):
	if inventory_system:
		inventory_system.drop_item(index)
		refresh_slots()
		$DetailsPanel.visible = false 