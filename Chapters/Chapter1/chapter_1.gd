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
@onready var menu_transition_timer = $MenuTransitionTimer  # Add menu transition timer reference

# Storage for all chapters/scenes parsed from JSON
var dialogue_data : Dictionary
# Current position
var cur_chapter : int = 0
var cur_scene_id : int = 0  # Changed from cur_scene to cur_scene_id to be more explicit

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
		print("Cena 0 do JSON:", dialogue_data["chapters"][0]["scenes"][0])

	
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
			$DialogueAudioPlayer.stream = audio_stream
			$DialogueAudioPlayer.stream.loop = true  # Enable looping
			$DialogueAudioPlayer.play()
			$DialogueAudioPlayer.volume_db = -22
			print("Playing audio for highlighted scene: ", audio_path)
		else:
			print("Audio file not found: ", audio_path)

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
			# Force immediate save for critical transition
			save_system.flush_pending_save()
			# Don't update local variables from save system as this can cause loops

func _on_menu_transition_timer_timeout() -> void:
	print("Menu transition timer finished, returning to menu")
	get_tree().change_scene_to_file("res://Menu/Menu.tscn")

func start_scene_by_id(scene_id: int) -> void:
	print("Starting scene with ID: ", scene_id)
	print("Current chapter: ", cur_chapter)
	
	# Store the previous scene ID to check if this is a transition
	var previous_scene_id = cur_scene_id
	
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
	
	# Play audio if exists in scene data
	if scene.has("audio"):
		var audio_path = scene["audio"]
		if ResourceLoader.exists(audio_path):
			var audio_stream = load(audio_path)
			$DialogueAudioPlayer.stream = audio_stream
			$DialogueAudioPlayer.stream.loop = true  # Enable looping
			$DialogueAudioPlayer.play()
			print("Playing audio: ", audio_path)
		else:
			print("Audio file not found: ", audio_path)
	
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
	print("DEBUG >>> dialogue.start() chamado com:", scene)

	# Only save progress when transitioning to a new scene, not on every scene start
	# This prevents redundant saves during normal dialogue progression
	if scene_id != previous_scene_id:
		var save_info = {
			"chapter": cur_chapter,
			"scene_id": cur_scene_id,
			"scene_path": "res://Chapters/Chapter1/Chapter1.tscn"
		}
		print("Saving game state: ", save_info)
		save_system.update_save_data_immediate(save_info)

func _on_dialogue_finished():
	print("=== DIALOGUE FINISHED DEBUG ===")
	print("Current scene ID: ", cur_scene_id)
	
	var current_scene = find_scene_by_id(cur_scene_id)
	print("Current scene data: ", current_scene)
	print("Has next_scene property: ", current_scene.has("next_scene"))
	if current_scene.has("next_scene"):
		print("Next scene value: ", current_scene.next_scene)

	# GUARD: Don't process highlighted scenes in dialogue_finished
	# Highlighted scenes should only be handled by _input and _on_interactive_area_clicked
	if current_scene.has("highlight") and current_scene["highlight"] == true:
		print("Ignoring dialogue_finished for highlighted scene - should be handled by input functions")
		return

	# Verifica se há uma "next_scene" definida no JSON para transições lineares.
	if current_scene.has("next_scene"):
		var next_scene_id = current_scene.next_scene
		if next_scene_id is int or next_scene_id is float:  # Handle both int and float values
			next_scene_id = int(next_scene_id)  # Convert to int to ensure consistent type
			
			# Check if the next scene has flag requirements
			var next_scene = find_scene_by_id(next_scene_id)
			if next_scene.has("requires_flag"):
				var required_flag = next_scene["requires_flag"]
				if not save_system.has_flag(required_flag):
					# If we don't have the required flag, look for an alternative scene
					print("Scene ", next_scene_id, " requires flag '", required_flag, "' which we don't have")
					print("Looking for alternative scene...")
					
					# Search through all scenes to find one that matches our flags
					var alternative_scene_id = find_alternative_scene_for_flags()
					if alternative_scene_id >= 0:
						print("Found alternative scene: ", alternative_scene_id)
						start_scene_by_id(alternative_scene_id)
						return
					else:
						print("No alternative scene found, skipping to scene after ", next_scene_id)
						# If no alternative found, try to find the next scene after the conditional one
						var scene_after_conditional = find_next_scene_after_conditional(next_scene_id)
						if scene_after_conditional >= 0:
							start_scene_by_id(scene_after_conditional)
							return
			
			print("Transitioning to next scene: ", next_scene_id)
			start_scene_by_id(next_scene_id)
			return
	
	# Se a cena tem áreas interativas, espera pela ação do jogador.
	if current_scene.has("interactive_areas") and not current_scene["interactive_areas"].is_empty():
		print("Scene has interactive areas, waiting for player input")
		return
	
	print("No valid next scene found, ending dialogue")
	# Force save before ending the chapter
	save_system.flush_pending_save()
	
	# Check if this is the last scene (no next_scene property)
	if not current_scene.has("next_scene"):
		print("Last scene reached, starting 5-second timer to return to menu")
		menu_transition_timer.start()
	else:
		# If there should be a next scene but we couldn't find it, hide immediately
		hide()
	
	print("=== END DIALOGUE FINISHED DEBUG ===")

# Helper function to find an alternative scene based on current flags
func find_alternative_scene_for_flags() -> int:
	var scenes = dialogue_data["chapters"][cur_chapter]["scenes"]
	
	# Look for scenes that have requires_flag and match our current flags
	for scene in scenes:
		if scene.has("requires_flag"):
			var required_flag = scene["requires_flag"]
			if save_system.has_flag(required_flag):
				print("Found scene ", scene["id"], " that matches flag '", required_flag, "'")
				return scene["id"]
	
	return -1

# Helper function to find the next scene after a conditional scene
func find_next_scene_after_conditional(conditional_scene_id: int) -> int:
	var scenes = dialogue_data["chapters"][cur_chapter]["scenes"]
	
	# Find the conditional scene and get its next_scene
	for scene in scenes:
		if scene["id"] == conditional_scene_id and scene.has("next_scene"):
			return scene["next_scene"]
	
	return -1

func _on_choice_made(scene_id: int) -> void:
	print("Choice made, transitioning to scene: ", scene_id)
	# The 'scene_id' parameter directly holds the ID of the chosen scene.
	# No need for an intermediate 'next_scene_id' variable here.
	print("DEBUG: About to start scene by ID: ", scene_id)
	start_scene_by_id(scene_id)
	print("DEBUG: Scene transition completed")
	
func _on_interactive_area_clicked(area_id: String) -> void:
	print("=== INTERACTIVE AREA CLICKED DEBUG ===")
	print("Area ID clicked: ", area_id)
	
	# Se o texto estiver sendo revelado, o primeiro clique irá completá-lo instantaneamente.
	if is_revealing_text:
		print("Text is still revealing, completing it")
		text_reveal_timer.stop()
		is_revealing_text = false
		highlight_label.text = full_text
		# Não retorne aqui. Deixe a lógica continuar para que o primeiro clique
		# também possa acionar a transição, tornando a experiência mais fluida.

	var current_scene = find_scene_by_id(cur_scene_id)
	print("Current scene ID: ", cur_scene_id)
	print("Current scene highlight: ", current_scene.has("highlight") and current_scene["highlight"] == true)

	# LÓGICA CORRIGIDA: Verifica se estamos em uma cena 'highlight'.
	if current_scene.has("highlight") and current_scene["highlight"] == true:
		print("Processing highlighted scene in interactive area clicked")
		# Se a cena de highlight deve chamar um minigame, faça isso.
		if current_scene.has("trigger_minigame"):
			var minigame_name = current_scene["trigger_minigame"]
			if minigame_name == "symptoms":
				print("Transitioning to symptoms minigame from highlight scene")
				# Force immediate save before transitioning to minigame
				save_system.flush_pending_save()
				get_tree().change_scene_to_file("res://Minigames/symptoms.tscn")
				return # Transição feita, encerra a função.

		# Se não houver minigame, vá para a próxima cena definida no JSON.
		elif current_scene.has("next_scene"):
			print("Transitioning to next scene: ", current_scene.next_scene)
			start_scene_by_id(current_scene.next_scene)
			return # Transição feita, encerra a função.
		else:
			# This is the last scene, start the menu transition timer
			print("Last highlighted scene reached, starting 5-second timer to return to menu")
			save_system.flush_pending_save()
			menu_transition_timer.start()
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
	print("=== END INTERACTIVE AREA CLICKED DEBUG ===")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("=== INPUT EVENT DEBUG ===")
		print("Mouse click detected")
		var current_scene = find_scene_by_id(cur_scene_id)
		print("Current scene ID: ", cur_scene_id)
		print("Current scene highlight: ", current_scene.has("highlight") and current_scene["highlight"] == true)
		print("Is revealing text: ", is_revealing_text)
		
		# If we're in a highlighted scene and the text is fully revealed
		if current_scene.has("highlight") and current_scene["highlight"] == true and not is_revealing_text:
			print("Processing click on highlighted scene")
			# If the scene has a minigame trigger
			if current_scene.has("trigger_minigame"):
				var minigame_name = current_scene["trigger_minigame"]
				if minigame_name == "symptoms":
					print("Transitioning to symptoms minigame from highlight scene")
					# Force immediate save before transitioning to minigame
					save_system.flush_pending_save()
					get_tree().change_scene_to_file("res://Minigames/symptoms.tscn")
					return
			
			# If no minigame, proceed to next scene
			if current_scene.has("next_scene"):
				print("Transitioning to next scene: ", current_scene["next_scene"])
				start_scene_by_id(current_scene["next_scene"])
				return
			else:
				# This is the last scene, start the menu transition timer
				print("Last highlighted scene reached, starting 5-second timer to return to menu")
				save_system.flush_pending_save()
				menu_transition_timer.start()
				return
		print("=== END INPUT EVENT DEBUG ===")

func _notification(what):
	# Force save when the scene is being freed
	if what == NOTIFICATION_PREDELETE:
		save_system.flush_pending_save()
