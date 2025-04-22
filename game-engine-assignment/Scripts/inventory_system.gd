extends Node

class_name InventorySystem

signal inventory_updated
signal item_added(item)
signal item_removed(item, index)
signal item_used(item, index)

@export var max_slots: int = 20
@export var default_icon: Texture2D
@export var inventory_ui_path := "res://scenes/inventory_ui.tscn"
@export var slot_scene_path := "res://scenes/inventory_slot.tscn"

var inventory = []
var inventory_visible = false
var inventory_ui = null
var ui_node = null
var item_slots = []
var gem_counts = {
	"Magic": 0,  # Purple
	"Health": 0, # Red
	"Shield": 0, # Blue
	"Speed": 0,  # Green
	"Luck": 0    # Yellow
}

func _init():
	# Initialize empty inventory
	inventory.resize(max_slots)

func _ready():
	print("Inventory system initializing with ", max_slots, " slots")
	# Initialize empty inventory
	for i in range(max_slots):
		inventory.append(null)
	
	# Wait a frame to ensure we're properly in the scene tree
	await get_tree().process_frame
	
	# Load UI scene
	call_deferred("_setup_ui")
	call_deferred("_setup_gem_ui")

func _setup_ui():
	print("Setting up inventory UI")
	
	# Make sure we're in the scene tree
	if !is_inside_tree():
		call_deferred("_setup_ui")
		return
	
	# Try to load the inventory UI scene
	var ui_scene = load(inventory_ui_path)
	if !ui_scene:
		push_error("ERROR: Could not load inventory UI scene from: " + inventory_ui_path)
		return
	
	# Create UI instance
	ui_node = ui_scene.instantiate()
	if !ui_node:
		push_error("ERROR: Failed to instantiate inventory UI scene")
		return
	
	# Add to scene tree - prioritize adding to player UI if available
	var parent_node = get_parent()
	var added = false
	
	# Try to add to PlayerUI canvas layer if it exists
	if parent_node and parent_node.has_node("PlayerUI"):
		parent_node.get_node("PlayerUI").add_child(ui_node)
		print("Added inventory UI to player's UI canvas layer")
		added = true
	# Otherwise try to add to parent directly if parent has add_child method
	elif parent_node and parent_node.has_method("add_child"):
		parent_node.add_child(ui_node)
		print("Added inventory UI to parent node: " + parent_node.name)
		added = true
	# Last resort: add to scene root
	else:
		get_tree().root.add_child(ui_node)
		print("Added inventory UI to scene root")
		added = true
	
	# Hide initially
	if added:
		call_deferred("_hide_ui")

func _hide_ui():
	if ui_node and is_instance_valid(ui_node):
		ui_node.visible = false
		if ui_node.has_method("close"):
			ui_node.close()

func _setup_gem_ui():
	print("Setting up gems UI")
	
	# Make sure we have a valid scene tree
	if !is_inside_tree():
		print("WARNING: Inventory system not in scene tree yet, deferring gem UI setup")
		call_deferred("_setup_gem_ui")
		return
		
	var gem_ui_scene = load("res://scenes/gem_ui.tscn")
	if !gem_ui_scene:
		push_error("ERROR: Could not load gem UI scene")
		return
		
	var gem_ui = gem_ui_scene.instantiate()
	if !gem_ui:
		push_error("ERROR: Failed to instantiate gem UI scene")
		return
		
	# Add it to the scene tree safely
	var scene_root = get_tree().get_root()
	if scene_root:
		scene_root.call_deferred("add_child", gem_ui)
		print("Added gem UI to scene tree")
	else:
		push_error("ERROR: Could not get scene root")
		return
	
	# Defer connecting signals until the UI is in the scene tree
	call_deferred("_connect_gem_ui_signals", gem_ui)

func _input(event):
	if event.is_action_pressed("inventory_toggle"):
		toggle_inventory()

func toggle_inventory(value = null):
	if value != null:
		inventory_visible = value
	else:
		inventory_visible = !inventory_visible
		
	print("Toggling inventory: " + str(inventory_visible))
	
	if !ui_node or !is_instance_valid(ui_node):
		print("No UI node available")
		return inventory_visible
	
	if inventory_visible:
		# Make sure UI is visible and centered on screen
		ui_node.visible = true
		
		# Make sure the Panel is positioned correctly in the center
		if ui_node.has_node("Panel"):
			var panel = ui_node.get_node("Panel")
			panel.visible = true
			panel.position = Vector2(get_viewport().size.x / 2 - panel.size.x / 2, 
									get_viewport().size.y / 2 - panel.size.y / 2)
			
		# Access specific UI components
		if ui_node.has_node("Background"):
			ui_node.get_node("Background").visible = true
		
		# If UI has an open method, call it
		if ui_node.has_method("open"):
			ui_node.open()
			
		# Don't set mouse mode here, let the controller handle it
	else:
		# Hide UI
		if ui_node.has_method("close"):
			ui_node.close()
		else:
			ui_node.visible = false
			if ui_node.has_node("Background"):
				ui_node.get_node("Background").visible = false
			if ui_node.has_node("Panel"):
				ui_node.get_node("Panel").visible = false
			if ui_node.has_node("DetailsPanel"):
				ui_node.get_node("DetailsPanel").visible = false
		
		# Don't set mouse mode here, let the controller handle it
	
	return inventory_visible

func show_inventory():
	print("Showing inventory UI...")
	if inventory_ui:
		inventory_ui.visible = true
		update_ui()
	else:
		create_inventory_ui()

func hide_inventory():
	print("Hiding inventory UI...")
	if inventory_ui:
		inventory_ui.visible = false

func create_inventory_ui():
	# Parent node (usually the player) should have a CanvasLayer for UI
	var canvas_layer = null
	
	if get_parent().has_node("PlayerUI"):
		canvas_layer = get_parent().get_node("PlayerUI")
		print("Using existing PlayerUI canvas layer")
	else:
		canvas_layer = CanvasLayer.new()
		canvas_layer.name = "PlayerUI"
		get_parent().add_child(canvas_layer)
		print("Created new PlayerUI canvas layer")
	
	# Create inventory panel
	var inventory_panel = Control.new()
	inventory_panel.name = "InventoryPanel"
	inventory_panel.set_anchors_preset(Control.PRESET_CENTER)
	inventory_panel.size = Vector2(600, 400)
	canvas_layer.add_child(inventory_panel)
	print("Created inventory panel control")
	
	# Add background panel
	var bg_panel = Panel.new()
	bg_panel.name = "Background"
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Style the panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.5, 0.4, 0.2, 0.8)  # Gold-ish border
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 8
	bg_panel.add_theme_stylebox_override("panel", panel_style)
	inventory_panel.add_child(bg_panel)
	
	# Title label
	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "INVENTORY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 10)
	title.size = Vector2(600, 30)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))  # Gold text
	inventory_panel.add_child(title)
	
	# Close button
	var close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "X"
	close_button.position = Vector2(550, 10)
	close_button.size = Vector2(30, 30)
	close_button.pressed.connect(_on_close_button_pressed)
	inventory_panel.add_child(close_button)
	
	# Create grid container for items
	var grid = GridContainer.new()
	grid.name = "ItemGrid"
	grid.columns = 5
	grid.position = Vector2(50, 50)
	grid.size = Vector2(500, 300)
	inventory_panel.add_child(grid)
	
	# Create slots
	for i in range(max_slots):
		var slot = Panel.new()
		slot.name = "Slot" + str(i)
		slot.custom_minimum_size = Vector2(80, 80)
		slot.size_flags_horizontal = Control.SIZE_FILL
		slot.size_flags_vertical = Control.SIZE_FILL
		
		# Style the slot
		var slot_style = StyleBoxFlat.new()
		slot_style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
		slot_style.border_width_left = 1
		slot_style.border_width_top = 1
		slot_style.border_width_right = 1
		slot_style.border_width_bottom = 1
		slot_style.border_color = Color(0.3, 0.3, 0.3, 0.8)
		slot_style.corner_radius_top_left = 3
		slot_style.corner_radius_top_right = 3
		slot_style.corner_radius_bottom_right = 3
		slot_style.corner_radius_bottom_left = 3
		slot.add_theme_stylebox_override("panel", slot_style)
		
		# Add the slot to the grid
		grid.add_child(slot)
		
		# Add an invisible button for handling clicks
		var button = Button.new()
		button.name = "Button"
		button.flat = true
		button.size = Vector2(80, 80)
		button.pressed.connect(_on_item_clicked.bind(i))
		slot.add_child(button)
	
	# Item details panel (right side)
	var details_panel = Panel.new()
	details_panel.name = "DetailsPanel"
	details_panel.position = Vector2(350, 100)
	details_panel.size = Vector2(200, 250)
	details_panel.visible = false  # Hidden until an item is selected
	
	# Style the details panel
	var details_style = StyleBoxFlat.new()
	details_style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	details_style.border_width_left = 2
	details_style.border_width_top = 2
	details_style.border_width_right = 2
	details_style.border_width_bottom = 2
	details_style.border_color = Color(0.5, 0.4, 0.2, 0.8)  # Gold-ish border
	details_style.corner_radius_top_left = 5
	details_style.corner_radius_top_right = 5
	details_style.corner_radius_bottom_right = 5
	details_style.corner_radius_bottom_left = 5
	details_panel.add_theme_stylebox_override("panel", details_style)
	
	# Item name label
	var item_name = Label.new()
	item_name.name = "ItemName"
	item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_name.position = Vector2(0, 10)
	item_name.size = Vector2(200, 30)
	item_name.add_theme_font_size_override("font_size", 16)
	item_name.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))  # Gold text
	details_panel.add_child(item_name)
	
	# Item description
	var item_desc = Label.new()
	item_desc.name = "ItemDescription"
	item_desc.position = Vector2(10, 50)
	item_desc.size = Vector2(180, 100)
	item_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_desc.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	details_panel.add_child(item_desc)
	
	# Item value
	var item_value = Label.new()
	item_value.name = "ItemValue"
	item_value.position = Vector2(10, 160)
	item_value.size = Vector2(180, 30)
	item_value.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	details_panel.add_child(item_value)
	
	# Use button
	var use_button = Button.new()
	use_button.name = "UseButton"
	use_button.text = "USE"
	use_button.position = Vector2(30, 200)
	use_button.size = Vector2(60, 30)
	use_button.pressed.connect(_on_use_button_pressed)
	details_panel.add_child(use_button)
	
	# Drop button
	var drop_button = Button.new()
	drop_button.name = "DropButton"
	drop_button.text = "DROP"
	drop_button.position = Vector2(110, 200)
	drop_button.size = Vector2(60, 30)
	drop_button.pressed.connect(_on_drop_button_pressed)
	details_panel.add_child(drop_button)
	
	# Add details panel to the inventory panel
	inventory_panel.add_child(details_panel)
	
	# Store reference and hide initially
	inventory_ui = inventory_panel
	inventory_ui.visible = false
	
	print("Inventory UI created successfully")
	
	# Update with initial content
	update_ui()

func update_ui():
	if !inventory_ui:
		return
		
	var grid = inventory_ui.get_node("ItemGrid")
	
	# Update each slot
	for i in range(max_slots):
		var slot = grid.get_node("Slot" + str(i))
		
		# Remove existing item texture if any
		if slot.has_node("ItemTexture"):
			slot.get_node("ItemTexture").queue_free()
		
		if slot.has_node("ItemCount"):
			slot.get_node("ItemCount").queue_free()
		
		# If there's an item, display it
		if i < inventory.size() and inventory[i] != null:
			var item = inventory[i]
			
			# Create texture rect for the item icon
			var texture_rect = TextureRect.new()
			texture_rect.name = "ItemTexture"
			
			# Use item icon or default
			if item.has("icon") and item.icon != null:
				texture_rect.texture = item.icon
			elif default_icon:
				texture_rect.texture = default_icon
				
			texture_rect.expand_mode = 1  # EXPAND_FIT = 1
			texture_rect.size = Vector2(60, 60)
			texture_rect.position = Vector2(10, 10)
			slot.add_child(texture_rect)
			
			# If stackable and quantity > 1, show count
			if item.get("stackable", false) and item.get("quantity", 1) > 1:
				var count_label = Label.new()
				count_label.name = "ItemCount"
				count_label.text = str(item.quantity)
				count_label.position = Vector2(50, 50)
				count_label.size = Vector2(30, 20)
				count_label.horizontal_alignment = 2  # RIGHT = 2
				count_label.add_theme_font_size_override("font_size", 14)
				count_label.add_theme_color_override("font_color", Color(1, 1, 1))
				slot.add_child(count_label)

func _on_item_clicked(slot_index):
	if slot_index >= inventory.size() or inventory[slot_index] == null:
		# Empty slot
		_hide_item_details()
		return
	
	# Show item details
	_show_item_details(inventory[slot_index], slot_index)

func _show_item_details(item, index):
	if !inventory_ui:
		return
		
	var details_panel = inventory_ui.get_node("DetailsPanel")
	details_panel.visible = true
	
	# Update item details
	details_panel.get_node("ItemName").text = item.get("name", "Unknown Item")
	details_panel.get_node("ItemDescription").text = item.get("description", "No description available.")
	details_panel.get_node("ItemValue").text = "Value: " + str(item.get("value", 0))
	
	# Store current item index
	details_panel.set_meta("current_item_index", index)

func _hide_item_details():
	if !inventory_ui:
		return
		
	var details_panel = inventory_ui.get_node("DetailsPanel")
	details_panel.visible = false

func _on_use_button_pressed():
	var details_panel = inventory_ui.get_node("DetailsPanel")
	var item_index = details_panel.get_meta("current_item_index")
	
	if item_index < inventory.size() and inventory[item_index] != null:
		use_item(item_index)

func _on_drop_button_pressed():
	var details_panel = inventory_ui.get_node("DetailsPanel")
	var item_index = details_panel.get_meta("current_item_index")
	
	if item_index < inventory.size() and inventory[item_index] != null:
		drop_item(item_index)

func add_to_inventory(item):
	# Check if inventory exists
	if !inventory:
		return false
		
	# Find an empty slot or stack with existing item
	var target_slot = -1
	
	# If item is stackable, check for existing stack first
	if "stackable" in item and item.stackable:
		for i in range(max_slots):
			if inventory[i] != null and inventory[i].id == item.id:
				# Found existing stack
				if "quantity" in inventory[i]:
					inventory[i].quantity += item.quantity
				else:
					inventory[i].quantity = 1 + item.quantity
					
				# Update gem UI if this is a gem
				if item.id == "magic_gem":
					# Don't call collect_gem here - it's already called in gem_item.gd
					print("Added gem to existing stack - UI should update via the original gem_collected signal")
					_update_gem_ui()
				
				emit_signal("inventory_updated")
				emit_signal("item_added", item)
				return true
	
	# If we didn't find an existing stack or item isn't stackable, find empty slot
	for i in range(max_slots):
		if inventory[i] == null:
			target_slot = i
			break
			
	# If we found an empty slot, add the item
	if target_slot != -1:
		inventory[target_slot] = item
		
		# If UI is visible, update it
		if inventory_visible and inventory_ui:
			update_ui()
			
		# If this is a gem, update gem tracking
		if item.id == "magic_gem":
			# Don't call collect_gem here - it's already called in gem_item.gd
			print("Added gem to new slot - UI should update via the original gem_collected signal")
			_update_gem_ui()
			
		emit_signal("inventory_updated")
		emit_signal("item_added", item)
		return true
		
	# If we got here, inventory is full
	return false

func remove_from_inventory(index):
	if index < inventory.size() and inventory[index] != null:
		var item = inventory[index]
		inventory[index] = null
		inventory_updated.emit()
		item_removed.emit(item, index)
		
		# Update UI if visible
		if inventory_visible and inventory_ui:
			update_ui()
			_hide_item_details()
			
		return item
		
	return null

func use_item(index):
	if index < inventory.size() and inventory[index] != null:
		var item = inventory[index]
		
		# Emit signal so player or other systems can handle item usage
		item_used.emit(item, index)
		
		# Reduce quantity if stackable
		if item.get("stackable", false) and item.get("quantity", 1) > 1:
			item.quantity -= 1
		else:
			# Remove completely if not stackable or last item
			inventory[index] = null
		
		inventory_updated.emit()
		
		# Update UI if visible
		if inventory_visible and inventory_ui:
			update_ui()
			
			# If item was completely used, hide details panel
			if inventory[index] == null:
				_hide_item_details()
			else:
				# Just update the details
				_show_item_details(inventory[index], index)
		
		return true
		
	return false

func drop_item(index):
	if index < inventory.size() and inventory[index] != null:
		var item = inventory[index]
		
		# Notify player script to handle creating a physical item in the world
		if get_parent().has_method("drop_item_from_inventory"):
			get_parent().drop_item_from_inventory(item, index)
		
		# Remove from inventory
		if item.get("stackable", false) and item.get("quantity", 1) > 1:
			# Just reduce count by 1
			item.quantity -= 1
		else:
			# Remove completely
			inventory[index] = null
		
		inventory_updated.emit()
		
		# Update UI if visible
		if inventory_visible and inventory_ui:
			update_ui()
			
			# If item was completely dropped, hide details panel
			if inventory[index] == null:
				_hide_item_details()
			else:
				# Just update the details
				_show_item_details(inventory[index], index)
		
		return true
		
	return false

func get_item(index):
	if index < inventory.size():
		return inventory[index]
	return null

func has_item(item_id, quantity = 1):
	var count = 0
	for item in inventory:
		if item != null and item.id == item_id:
			count += item.get("quantity", 1)
	return count >= quantity 

# Get all items in the inventory (returns array including null slots)
func get_inventory_items():
	return inventory
	
# Get all non-null items in the inventory
func get_all_items():
	var items = []
	for item in inventory:
		if item != null:
			items.append(item)
	return items 

func _on_close_button_pressed():
	# Used by the close button
	hide_inventory()
	inventory_visible = false
	
	# Reset mouse capture
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 

func _on_slot_gui_input(event, slot_index):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_slot_item_details(slot_index)

func _show_slot_item_details(slot_index):
	var item = inventory[slot_index]
	if item == null or inventory_ui == null:
		return
		
	var details_panel = inventory_ui.get_node("DetailsPanel")
	if details_panel:
		details_panel.visible = true
		details_panel.get_node("ItemName").text = item.get("name", "Unknown Item")
		details_panel.get_node("ItemDescription").text = item.get("description", "No description available.")
		details_panel.get_node("ItemValue").text = "Value: " + str(item.get("value", 0))
		
		# Connect use button
		var use_btn = details_panel.get_node("UseButton")
		if use_btn.is_connected("pressed", _on_use_item):
			use_btn.disconnect("pressed", _on_use_item)
		use_btn.connect("pressed", _on_use_item.bind(slot_index))
		
		# Connect drop button
		var drop_btn = details_panel.get_node("DropButton")
		if drop_btn.is_connected("pressed", _on_drop_item):
			drop_btn.disconnect("pressed", _on_drop_item)
		drop_btn.connect("pressed", _on_drop_item.bind(slot_index))

func _on_use_item(slot_index):
	var item = inventory[slot_index]
	if item != null:
		if item.has_method("use"):
			item.use()
			# If item is consumed on use
			if item.is_consumed_on_use:
				remove_from_inventory(slot_index)

func _on_drop_item(slot_index):
	remove_from_inventory(slot_index)
	# Hide details panel
	inventory_ui.get_node("DetailsPanel").visible = false

func get_gem_count(gem_type):
	if gem_counts.has(gem_type):
		return gem_counts[gem_type]
	return 0

func clear_inventory():
	for i in range(inventory.size()):
		inventory[i] = null
		_update_slot_display(i)
	
	for key in gem_counts.keys():
		gem_counts[key] = 0
		
	emit_signal("inventory_updated")

func _update_slot_display(slot_index):
	if inventory_ui == null or item_slots.size() <= slot_index:
		return
		
	var slot = item_slots[slot_index]
	var item = inventory[slot_index]
	
	if slot.has_node("ItemIcon"):
		var icon = slot.get_node("ItemIcon")
		if item != null:
			icon.texture = item.get_icon()
			icon.visible = true
		else:
			icon.texture = null
			icon.visible = false

func _connect_gem_ui_signals(gem_ui):
	# Make sure the gem UI is actually in the scene tree
	if !gem_ui.is_inside_tree():
		print("Gem UI not ready yet, retrying signal connection...")
		call_deferred("_connect_gem_ui_signals", gem_ui)
		return
		
	print("Connecting gem UI signals")
	
	# Connect signals for gem count updates - only if the method exists
	if gem_ui.has_method("update_gem_display"):
		# Avoid duplicate connections
		if !self.is_connected("inventory_updated", gem_ui.update_gem_display):
			self.connect("inventory_updated", gem_ui.update_gem_display)
			print("Connected inventory_updated signal to gem UI")
		
		# Initial update
		gem_ui.call_deferred("update_gem_display")
	else:
		push_error("Warning: gem_ui doesn't have an update_gem_display method")

func _on_item_added(item):
	# Check if the item is a gem
	if item.item_name.to_lower().contains("gem"):
		# NOTE: Don't call collect_gem here - it's already called in gem_item.gd
		# get_node("/root/Global").collect_gem(item.gem_type, item.item_value)
		
		# Update UI directly via the original gem_collected signal
		print("Item added to inventory: ", item.item_name, " with value ", item.item_value)

func refresh_ui():
	if !ui_node or !is_instance_valid(ui_node):
		return
		
	if ui_node.has_method("refresh_slots"):
		ui_node.refresh_slots(inventory)

func _on_item_used(item_index):
	print("Using item at index: " + str(item_index))
	
	if item_index < 0 or item_index >= inventory.size():
		return
		
	var item = inventory[item_index]
	if item == null:
		return
	
	# Handle gem effects
	if "gem_type" in item:
		apply_gem_effect(item)
		
	# Remove item after use
	inventory[item_index] = null
	emit_signal("item_used", item)
	
	# Update UI
	if inventory_visible and inventory_ui:
		update_ui()

func drop_inventory_item(item_index):
	if item_index < 0 or item_index >= inventory.size():
		return
		
	var item = inventory[item_index]
	inventory[item_index] = null
	emit_signal("item_dropped", item)
	
	# Update UI
	if inventory_visible and inventory_ui:
		update_ui()
	
	return item

func apply_gem_effect(gem_item):
	if !gem_item or !"gem_type" in gem_item:
		return
		
	print("Applying effect for gem type: " + str(gem_item.gem_type))
	
	# Different effects based on gem type
	match gem_item.gem_type:
		0: # Purple - Max health
			emit_signal("player_health_boost", 10)
		1: # Red - Attack boost
			emit_signal("player_attack_boost", 5, 30)
		2: # Blue - Speed boost
			emit_signal("player_speed_boost", 1.5, 20)
		3: # Green - Healing
			emit_signal("player_heal", 25)
		4: # Yellow - Money/score
			emit_signal("player_score_boost", 100)
			
	# Play gem use sound
	if has_node("GemUseSound"):
		$GemUseSound.play()

# Helper function to update the gem UI if it exists
func _update_gem_ui():
	# Find gem UI in the scene
	var gem_ui = get_tree().get_first_node_in_group("GemUI")
	if gem_ui and gem_ui.has_method("update_gem_display"):
		print("Updating gem UI display after inventory change")
		gem_ui.update_gem_display()
	else:
		print("No gem UI found in the scene")
