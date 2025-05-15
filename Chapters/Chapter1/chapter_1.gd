extends Control
# 1) Reference your DialogueBase instance
@onready var dialogue = $DialogueBase
# 2) Storage for all chapters/scenes parsed from JSON
var dialogue_data : Dictionary
# Current position
var cur_chapter : int = 0
var cur_scene   : int = 0
# To track which choice was selected
var next_scene_id : int = -1

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
	
	# Kick off scene 0
	start_current_scene()

func start_current_scene():
	# Check if the scene index is valid
	if cur_scene >= dialogue_data["chapters"][cur_chapter]["scenes"].size():
		print("End of chapter reached")
		return
		
	var scene = dialogue_data["chapters"][cur_chapter]["scenes"][cur_scene]
	# Wrap the scene in an array since dialogue.start expects an Array of Dictionaries
	dialogue.start([scene])

func _on_dialogue_finished():
	# Only handle automatic progression if no choice was made
	if next_scene_id < 0:
		cur_scene += 1
		# Wrap to next chapter if needed
		if cur_scene >= dialogue_data["chapters"][cur_chapter]["scenes"].size():
			cur_chapter += 1
			cur_scene = 0
			
			# Check if we've reached the end of all chapters
			if cur_chapter >= dialogue_data["chapters"].size():
				print("End of dialogue reached")
				return
				
		start_current_scene()
	else:
		# Reset the choice flag
		next_scene_id = -1

func _on_choice_made(scene_id):
	print("===> _on_choice_made called with scene_id:", scene_id)
	next_scene_id = scene_id
	print("Set next_scene_id to:", next_scene_id)
	
	# Find the scene with the specified ID in the current chapter
	var found = false
	print("Current chapter index:", cur_chapter)
	var scenes = dialogue_data["chapters"][cur_chapter]["scenes"]
	print("Number of scenes in current chapter:", scenes.size())
	
	for i in range(scenes.size()):
		var scene = scenes[i]
		print("Checking scene at index", i, "with contents:", scene)
		
		if scene.has("id"):
			print("Scene has ID:", scene["id"])
			if float(scene["id"]) == float(scene_id):
				print("Match found! Scene index:", i)
				cur_scene = i
				found = true
				print("Set cur_scene to:", cur_scene)
				# Start the new scene immediately
				var new_scene = dialogue_data["chapters"][cur_chapter]["scenes"][cur_scene]
				dialogue.start([new_scene])
				break
		else:
			print("Warning: Scene at index", i, "does not have an 'id' key")
	
	# If the scene ID wasn't found, print an error
	if not found:
		print("Error: Could not find scene with ID ", scene_id)
