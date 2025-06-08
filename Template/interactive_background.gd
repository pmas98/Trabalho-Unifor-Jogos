extends Control

signal area_clicked(area_id)

# Dictionary to store clickable areas
var clickable_areas: Dictionary = {}

func _ready() -> void:
	# Make sure the background is clickable
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Set the control to fill the entire parent
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

func add_clickable_area(area_id: String, rect: Rect2) -> void:
	print("\n=== Adding Clickable Area ===")
	print("Adding area: ", area_id, " at position: ", rect.position, " with size: ", rect.size)
	print("Current areas before adding: ", clickable_areas.keys())
	
	# Create a new ColorRect for the clickable area
	var area = ColorRect.new()
	area.position = rect.position
	area.size = rect.size
	area.color = Color(1, 1, 1, 0.1)  # Semi-transparent white
	area.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Add a border to make the area visible
	var border = ColorRect.new()
	border.position = Vector2(0, 0)
	border.size = rect.size
	border.color = Color(1, 0, 0, 0.5)  # Semi-transparent red
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Ignore mouse events for the border
	
	# Create a container to hold both the area and its border
	var container = Control.new()
	container.position = rect.position
	container.size = rect.size
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Add the border and area to the container
	container.add_child(border)
	container.add_child(area)
	
	# Store the container with its ID
	clickable_areas[area_id] = container
	add_child(container)
	
	# Connect mouse events for hover detection to the container instead of the area
	container.mouse_entered.connect(_on_area_mouse_entered.bind(area_id))
	container.mouse_exited.connect(_on_area_mouse_exited.bind(area_id))
	container.gui_input.connect(_on_area_clicked.bind(area_id))
	
	print("Areas after adding: ", clickable_areas.keys())
	print("=== Area Added ===\n")

func _on_area_mouse_entered(area_id: String) -> void:
	print("Mouse entered area: ", area_id)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_area_mouse_exited(area_id: String) -> void:
	print("Mouse exited area: ", area_id)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_area_clicked(event: InputEvent, area_id: String) -> void:
	print("\n=== Area Click Event ===")
	print("Area clicked: ", area_id)
	print("Current areas: ", clickable_areas.keys())
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Emitting area_clicked signal for: ", area_id)
		emit_signal("area_clicked", area_id)
	print("=== Click Event Handled ===\n")

func clear_areas() -> void:
	print("\n=== Clearing Interactive Areas ===")
	print("Current areas before clearing: ", clickable_areas.keys())
	for area_id in clickable_areas:
		var area = clickable_areas[area_id]
		print("Removing area: ", area_id)
		if is_instance_valid(area):
			area.queue_free()
	clickable_areas.clear()
	print("Areas after clearing: ", clickable_areas.keys())
	# Reset cursor when clearing areas
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	print("=== Areas Cleared ===\n")
