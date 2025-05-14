extends Control
# 1) Reference your DialogueBase instance
@onready var dialogue = $DialogueBase
# 2) Storage for all chapters/scenes parsed from JSON
var dialogue_data : Dictionary
# Current position
var cur_chapter : int = 0
var cur_scene   : int = 0

func _ready():
	# Load+parse the JSON once
	var file = FileAccess.open("res://dialogues.json", FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	# Parse JSON (Godot 4 uses JSON.parse_string instead of JSON.parse)
	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		dialogue_data = json.data
	else:
		print("JSON Parse Error: ", json.get_error_message())
	
	# Connect finished signal (Godot 4 uses a different signal connection syntax)
	dialogue.dialogue_finished.connect(_on_dialogue_finished)
	
	# Kick off scene 0
	start_current_scene()

func start_current_scene():
	var scene = dialogue_data["chapters"][cur_chapter]["scenes"][cur_scene]
	# Wrap the scene in an array since dialogue.start expects an Array of Dictionaries
	dialogue.start([scene])

func _on_dialogue_finished():
	# Grab last element of the current scene
	var scene_array = dialogue_data["chapters"][cur_chapter]["scenes"][cur_scene]
	var last = scene_array[scene_array.size() - 1]
	
	if last.has("choice"):
		# Branching point
		show_choices(last["choice"])
	else:
		# No choice → linear advance
		cur_scene += 1
		# Wrap to next chapter if needed
		if cur_scene >= dialogue_data["chapters"][cur_chapter]["scenes"].size():
			cur_chapter += 1
			cur_scene = 0
		start_current_scene()

func show_choices(choices):
	# This function would be implemented to show the choice UI
	# For this example, I'll leave it empty as we don't have the implementation details
	pass
