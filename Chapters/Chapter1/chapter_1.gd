extends Control

# Reference your DialogueBase instance
@onready var dialogue = $DialogueBase
@onready var save_system = get_node("/root/SaveSystem")
@onready var background_node = $BackgroundGame
@onready var interactive_background = $InteractiveBackground

# Storage for all chapters/scenes parsed from JSON
var dialogue_data : Dictionary
# Current position
var cur_chapter : int = 0
var cur_scene_id : int = 0  # Changed from cur_scene to cur_scene_id to be more explicit
var next_scene_id : int = -1  # Track the next scene we should go to

func _ready():
	save_system.load_game()
	# Load+parse the JSON once
	var file = FileAccess.open("res://dialogues.json", FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	# Parse JSON (Godot 4.4 uses JSON.parse_string directly)
	var json_data = JSON.parse_string(json_string)
	if json_data:
		dialogue_data = json_data
	else:
		print("JSON Parse Error")
	
	# Connect signals
	dialogue.dialogue_finished.connect(_on_dialogue_finished)
	dialogue.choice_made.connect(_on_choice_made)
	# Add this line in your chapter_1.gd _ready() function
	interactive_background.area_clicked.connect(_on_interactive_area_clicked)
	# Load saved game if exists
	save_system.load_game()  # This loads the data into save_system's variables
	if save_system.current_chapter >= 0 and save_system.current_scene_id >= 0:
		cur_chapter = save_system.current_chapter
		cur_scene_id = save_system.current_scene_id
		# Start with the saved scene instead of always scene 0
		start_scene_by_id(cur_scene_id)
	else:
		# Only start with scene 0 if there's no save data
		start_scene_by_id(0)
	var audio_manager = get_node("/root/MusicController") # ou o nome correto do seu AutoLoad
	if audio_manager:
		MusicController.apply_audio()

func find_scene_by_id(scene_id: int) -> Dictionary:
	print("Finding scene with ID: ", scene_id)
	# Search through all scenes in the current chapter to find the one with matching ID
	for scene in dialogue_data["chapters"][cur_chapter]["scenes"]:
		if scene.has("id") and scene["id"] == scene_id:
			print("Found scene: ", scene)
			return scene
	print("Scene not found!")
	return {}

func set_background(texture_path: String) -> void:
	if ResourceLoader.exists(texture_path):
		var texture = load(texture_path)
		background_node.texture = texture
	else:
		print("Background não encontrado: ", texture_path)

func start_scene_by_id(scene_id: int) -> void:
	print("Starting scene with ID: ", scene_id)
	print("Current chapter: ", cur_chapter)
	
	# Always clear interactive areas first, regardless of whether the new scene has them
	print("Clearing all interactive areas")
	interactive_background.clear_areas()
	
	var scene = find_scene_by_id(scene_id)
	print("Found scene data: ", scene)
	
	if scene.is_empty():
		print("Error: Scene with ID ", scene_id, " not found")
		return
		
	cur_scene_id = scene_id
	print("Updated current scene ID to: ", cur_scene_id)

	if scene.has("background"):
		print("Setting background: ", scene["background"])
		set_background(scene["background"])
	
	# Set up new interactive areas if they exist
	if scene.has("interactive_areas"):
		print("Setting up interactive areas for scene: ", scene_id)
		for area in scene["interactive_areas"]:
			print("Setting up interactive area: ", area)
			var rect = Rect2(area.x, area.y, area.width, area.height)
			interactive_background.add_clickable_area(area.id, rect)
			print("Added interactive area: ", area.id, " with rect: ", rect)
	else:
		print("No interactive areas for scene: ", scene_id)

	# Start the dialogue with the found scene
	print("Starting dialogue with scene: ", scene)
	dialogue.start([scene])
	
	# Save current progress
	var save_info = {
		"chapter": cur_chapter,
		"scene_id": cur_scene_id,
		"scene_path": "res://Chapters/Chapter1/Chapter1.tscn"
	}
	print("Saving game state: ", save_info)
	save_system.update_save_data(save_info)

func _on_dialogue_finished():
	print("Dialogue finished for scene: ", cur_scene_id)
	
	# If we have a next scene ID set (from a choice), use that
	if next_scene_id >= 0:
		print("Using next scene from choice: ", next_scene_id)
		start_scene_by_id(next_scene_id)
		next_scene_id = -1  # Reset the next scene ID
		return
	
	# Get the current scene data
	var current_scene = find_scene_by_id(cur_scene_id)
	
	# If the scene has interactive areas, don't auto-transition
	# Wait for the player to click an area
	if current_scene.has("interactive_areas") and not current_scene["interactive_areas"].is_empty():
		print("Scene has interactive areas, waiting for player input")
		return
	
	# Otherwise, try to find the next scene in the current path
	if current_scene.has("next_scene"):
		print("Using next scene from current scene: ", current_scene.next_scene)
		start_scene_by_id(current_scene.next_scene)
		return
	
	# If no next scene is specified, try to find the next scene in sequence
	# that matches our current path's requirements
	var next_scene_id = cur_scene_id + 1
	while true:
		var next_scene = find_scene_by_id(next_scene_id)
		if next_scene.is_empty():
			print("No more scenes in sequence")
			break
			
		# Check if this scene has any requirements
		if next_scene.has("requires_flag"):
			# If we have the required flag, show this scene
			if dialogue.active_flags.has(next_scene.requires_flag):
				print("Found next valid scene with required flag: ", next_scene_id)
				start_scene_by_id(next_scene_id)
				return
		else:
			# If no requirements, show this scene
			print("Found next valid scene without requirements: ", next_scene_id)
			start_scene_by_id(next_scene_id)
			return
			
		next_scene_id += 1

func _on_choice_made(scene_id: int) -> void:
	print("Choice made, transitioning to scene: ", scene_id)
	next_scene_id = scene_id  # Store the next scene ID
	start_scene_by_id(scene_id)

func _on_interactive_area_clicked(area_id: String) -> void:
	print("\n=== Interactive Area Clicked ===")
	print("Area ID clicked: ", area_id)
	print("Current scene ID before transition: ", cur_scene_id)
	
	var current_scene = find_scene_by_id(cur_scene_id)
	print("Current scene data: ", current_scene)
	print("Current scene ID from data: ", current_scene.get("id", "no id"))
	
	if current_scene.has("interactive_areas"):
		print("\nInteractive areas in current scene:")
		for area in current_scene["interactive_areas"]:
			print("\nArea details:")
			print("- ID: ", area.id)
			print("- Next scene: ", area.get("next_scene", "none"))
			print("- Full area data: ", area)
			
			if area.id == area_id:
				print("\nMATCH FOUND!")
				print("Area ID matches clicked area: ", area_id)
				if area.has("next_scene"):
					print("Transitioning to scene: ", area.next_scene)
					start_scene_by_id(area.next_scene)
					print("Scene transition completed")
					return
				else:
					print("ERROR: Matching area has no next_scene defined")
			else:
				print("Area ID does not match: ", area.id, " != ", area_id)
	else:
		print("ERROR: Current scene has no interactive_areas")
		print("Current scene data: ", current_scene)
	print("WARNING: No next scene found for area: ", area_id)
	print("=== End of Interactive Area Click ===\n")
