extends Control

# Reference your DialogueBase instance
@onready var dialogue = $DialogueBase
@onready var save_system = get_node("/root/SaveSystem")
@onready var background_node = $BackgroundGame
@onready var interactive_background = $InteractiveBackground
@onready var highlight_label = $HighlightLabel/Label  # Updated path to just the Label
@onready var highlight_background = $HighlightLabel/ColorRect  # Add reference to background
@onready var highlight_container = $HighlightLabel  # Add reference to container
@onready var text_reveal_timer = $TextRevealTimer  # Add timer reference

# Storage for all chapters/scenes parsed from JSON
var dialogue_data : Dictionary
# Current position
var cur_chapter : int = 0
var cur_scene_id : int = 0  # Changed from cur_scene to cur_scene_id to be more explicit
var next_scene_id : int = -1  # Track the next scene we should go to

# Text reveal variables
var full_text : String = ""
var current_text_length : int = 0
var reveal_speed : float = 0.05  # Time between each character reveal
var is_revealing_text : bool = false

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
	interactive_background.area_clicked.connect(_on_interactive_area_clicked)
	
	# Initialize highlight elements
	highlight_container.hide()
	highlight_label.text = ""
	
	# Make sure the highlight container can receive input
	highlight_container.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Load saved game if exists
	save_system.load_game()  # This loads the data into save_system's variables
	
	# Check if we're returning from the minigame
	if save_system.has_flag("completed_intro"):
		# If we've completed the intro, start at scene 1 (now this logic might need adjustment depending on where you want to return)
		cur_chapter = save_system.current_chapter
		# We can decide where to continue after the minigame, for now, let's go to scene 2.
		cur_scene_id = 2 
		start_scene_by_id(2)
	else:
		# If we haven't completed the intro, start at the saved scene or scene 0
		if save_system.current_chapter >= 0 and save_system.current_scene_id >= 0:
			cur_chapter = save_system.current_chapter
			cur_scene_id = save_system.current_scene_id
			start_scene_by_id(cur_scene_id)
		else:
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

func show_highlighted_scene(scene: Dictionary) -> void:
	# Hide dialogue UI and background
	dialogue.hide()
	background_node.hide()
	
	# Set up text reveal
	full_text = scene.get("text", "")
	current_text_length = 0
	highlight_label.text = ""
	highlight_container.show()
	
	# Make sure the highlight container can receive input
	highlight_container.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Start text reveal
	is_revealing_text = true
	text_reveal_timer.wait_time = reveal_speed
	text_reveal_timer.start()
	
	# Play audio if exists
	if scene.has("audio"):
		var audio_path = scene["audio"]
		if ResourceLoader.exists(audio_path):
			var audio_stream = load(audio_path)
			var audio_player = get_node("AudioPlayer")
			if audio_player:
				audio_player.stream = audio_stream
				audio_player.play()

func _on_text_reveal_timer_timeout() -> void:
	if is_revealing_text and current_text_length < full_text.length():
		current_text_length += 1
		highlight_label.text = full_text.substr(0, current_text_length)
		
		# Add a small random delay for more natural feel
		text_reveal_timer.wait_time = reveal_speed + randf_range(-0.01, 0.01)
		text_reveal_timer.start()
	else:
		text_reveal_timer.stop()
		is_revealing_text = false
		# The user can now click to continue, which will fire _on_dialogue_finished
		# The old flag logic is kept as requested, setting the flag after the text is revealed.
		if cur_scene_id == 1:
			save_system.set_flag("completed_intro", true)
			var save_info = {
				"chapter": cur_chapter,
				"scene_id": cur_scene_id,
				"scene_path": "res://Chapters/Chapter1/Chapter1.tscn"
			}
			save_system.update_save_data(save_info)


func start_scene_by_id(scene_id: int) -> void:
	print("Starting scene with ID: ", scene_id)
	print("Current chapter: ", cur_chapter)
	
	# Always clear interactive areas first
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
	
	# Check if this is a highlighted scene
	if scene.has("highlight") and scene["highlight"] == true:
		show_highlighted_scene(scene)
		# For highlighted scenes, we'll wait for a click to continue
		# The dialogue_finished signal will be emitted when the player clicks
		return
	
	# For non-highlighted scenes, proceed with normal dialogue
	highlight_container.hide()
	dialogue.show()
	background_node.show()  # Make sure background is visible for normal scenes
	
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
	
	var current_scene = find_scene_by_id(cur_scene_id)

	# Se uma escolha foi feita, ela já definiu o next_scene_id.
	if next_scene_id >= 0:
		print("Using next scene from choice: ", next_scene_id)
		start_scene_by_id(next_scene_id)
		next_scene_id = -1  # Reseta o ID da próxima cena
		return
	
	# Verifica se há uma "next_scene" definida no JSON para transições lineares.
	if current_scene.has("next_scene"):
		var next_scene = current_scene.next_scene
		if next_scene is int:
			print("Using next scene from current scene: ", next_scene)
			start_scene_by_id(next_scene)
			return
	
	# Se a cena tem áreas interativas, espera pela ação do jogador.
	if current_scene.has("interactive_areas") and not current_scene["interactive_areas"].is_empty():
		print("Scene has interactive areas, waiting for player input")
		return
	
	# Lógica fallback para encontrar a próxima cena na sequência
	var next_sequential_id = cur_scene_id + 1
	# ... (o resto da função pode permanecer como está)
func _on_choice_made(scene_id: int) -> void:
	print("Choice made, transitioning to scene: ", scene_id)
	next_scene_id = scene_id  # Store the next scene ID
	start_scene_by_id(scene_id)

func _on_interactive_area_clicked(area_id: String) -> void:
	# Se o texto estiver sendo revelado, o primeiro clique irá completá-lo instantaneamente.
	if is_revealing_text:
		text_reveal_timer.stop()
		is_revealing_text = false
		highlight_label.text = full_text
		# Não retorne aqui. Deixe a lógica continuar para que o primeiro clique
		# também possa acionar a transição, tornando a experiência mais fluida.

	var current_scene = find_scene_by_id(cur_scene_id)

	# LÓGICA CORRIGIDA: Verifica se estamos em uma cena 'highlight'.
	if current_scene.has("highlight") and current_scene["highlight"] == true:
		# Se a cena de highlight deve chamar um minigame, faça isso.
		if current_scene.has("trigger_minigame"):
			var minigame_name = current_scene["trigger_minigame"]
			if minigame_name == "symptoms":
				print("Transitioning to symptoms minigame from highlight scene")
				get_tree().change_scene_to_file("res://Minigames/symptoms.tscn")
				return # Transição feita, encerra a função.

		# Se não houver minigame, vá para a próxima cena definida no JSON.
		elif current_scene.has("next_scene"):
			start_scene_by_id(current_scene.next_scene)
			return # Transição feita, encerra a função.

	# O código abaixo só será executado para cenas normais com áreas interativas definidas.
	print("\n=== Interactive Area Clicked (Standard Scene) ===")
	print("Area ID clicked: ", area_id)
	
	if current_scene.has("interactive_areas"):
		for area in current_scene["interactive_areas"]:
			if area.id == area_id:
				if area.has("next_scene"):
					print("Transitioning to scene: ", area.next_scene)
					start_scene_by_id(area.next_scene)
					return
	
	print("WARNING: No next scene found for area: ", area_id)
	print("=== End of Interactive Area Click ===\n")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var current_scene = find_scene_by_id(cur_scene_id)
		
		# If we're in a highlighted scene and the text is fully revealed
		if current_scene.has("highlight") and current_scene["highlight"] == true and not is_revealing_text:
			# If the scene has a minigame trigger
			if current_scene.has("trigger_minigame"):
				var minigame_name = current_scene["trigger_minigame"]
				if minigame_name == "symptoms":
					print("Transitioning to symptoms minigame from highlight scene")
					get_tree().change_scene_to_file("res://Minigames/symptoms.tscn")
					return
			
			# If no minigame, proceed to next scene
			if current_scene.has("next_scene"):
				start_scene_by_id(current_scene["next_scene"])
				return
