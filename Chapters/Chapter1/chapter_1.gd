extends Control

# Reference your DialogueBase instance
@onready var dialogue = $DialogueBase
@onready var save_system = get_node("/root/SaveSystem")
@onready var background_node = $BackgroundGame

# Storage for all chapters/scenes parsed from JSON
var dialogue_data : Dictionary
# Current position
var cur_chapter : int = 0
var cur_scene_id : int = 0  # Changed from cur_scene to cur_scene_id to be more explicit
var next_scene_id : int = -1  # Track the next scene we should go to

func _ready():
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
	
	# Load saved game if exists
	var save_data = save_system.load_game()
	if save_data != null and save_data.has("chapter") and save_data.has("scene_id"):
		if save_data.has("chapter") and save_data.has("scene_id"):
			cur_chapter = save_data["chapter"]
			cur_scene_id = save_data["scene_id"]
			# Start with the saved scene instead of always scene 0
			start_scene_by_id(cur_scene_id)
	else:
		# Only start with scene 0 if there's no save data
		start_scene_by_id(0)

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
	var scene = find_scene_by_id(scene_id)
	if scene.is_empty():
		print("Error: Scene with ID ", scene_id, " not found")
		return
		
	cur_scene_id = scene_id

	if scene.has("background"):
		set_background(scene["background"])

	# Start the dialogue with the found scene
	dialogue.start([scene])
	
	# Save current progress
	var save_info = {
		"chapter": cur_chapter,
		"scene_id": cur_scene_id,
		"scene_path": "res://Chapters/Chapter1/Chapter1.tscn"
	}
	save_system.update_save_data(save_info)

func _on_dialogue_finished():
	print("Dialogue finished for scene: ", cur_scene_id)
	
	# If we have a next scene ID set (from a choice), use that
	if next_scene_id >= 0:
		print("Using next scene from choice: ", next_scene_id)
		start_scene_by_id(next_scene_id)
		next_scene_id = -1  # Reset the next scene ID
		return
	
	# Otherwise, try to find the next scene in the current path
	var current_scene = find_scene_by_id(cur_scene_id)
	if current_scene and current_scene.has("next_scene"):
		print("Using next scene from current scene: ", current_scene.next_scene)
		start_scene_by_id(current_scene.next_scene)
		return
	
	# If no next scene is specified, try to find the next scene in sequence
	# that matches our current path's requirements
	#var next_scene_id = cur_scene_id + 1
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
