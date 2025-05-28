extends Node

const SAVE_FILE = "user://savegame.save"

# Dados do progresso
var current_chapter: int = 0
var current_scene_id: int = 0
var current_scene_path: String = ""
var player_choices: Array = []

var fullscreen_enabled: bool = false

# Valores dos sliders de áudio
var volume_bus_1: float = 0.5
var volume_bus_2: float = 0.5

func save_game() -> void:
	var save_data = {
		"chapter": current_chapter,
		"scene_id": current_scene_id,
		"scene_path": current_scene_path,
		"choices": player_choices,
		"volume_bus_1": volume_bus_1,
		"volume_bus_2": volume_bus_2,
		"fullscreen_enabled": fullscreen_enabled
	}
	
	var save_file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if not save_file:
		print("Error: Could not open save file for writing!")
		return
		
	save_file.store_var(save_data)
	save_file.close()
	print("Game saved successfully!")

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		print("No save file found. Using defaults.")
		# Set default values if no save file exists
		current_chapter = 0
		current_scene_id = 0
		current_scene_path = "res://Chapters/Chapter1/Chapter1.tscn"
		player_choices = []
		volume_bus_1 = 0.5
		volume_bus_2 = 0.5
		fullscreen_enabled = false
		apply_audio_settings() # Apply default audio settings
		return

	var save_file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if not save_file:
		print("Error: Could not open save file for reading!")
		return

	var save_data = save_file.get_var()
	save_file.close()

	if save_data == null:
		print("Error: Save file is corrupted or empty!")
		# Reset to defaults
		current_chapter = 0
		current_scene_id = 0
		current_scene_path = "res://Chapters/Chapter1/Chapter1.tscn"
		player_choices = []
		volume_bus_1 = 0.5
		volume_bus_2 = 0.5
		fullscreen_enabled = false
		apply_audio_settings()
		return

	# Atualizar dados locais
	current_chapter = save_data.get("chapter", 0)
	current_scene_id = save_data.get("scene_id", 0)
	current_scene_path = save_data.get("scene_path", "res://Chapters/Chapter1/Chapter1.tscn")
	player_choices = save_data.get("choices", [])

	volume_bus_1 = save_data.get("volume_bus_1", 0.5)
	volume_bus_2 = save_data.get("volume_bus_2", 0.5)
	fullscreen_enabled = save_data.get("fullscreen_enabled", false)

	if fullscreen_enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	sync_autoload()
	apply_audio_settings()
	print("Game loaded successfully!")

func apply_audio_settings() -> void:
	# Ensure this path is correct for your AutoLoad singleton
	var audio_manager = get_node_or_null("/root/AutoLoad")
	if audio_manager:
		audio_manager.volume_bus_1 = volume_bus_1
		audio_manager.volume_bus_2 = volume_bus_2
		# Assuming AutoLoad has a method to actually apply these volumes to the audio buses
		audio_manager.apply_audio()
	else:
		print("Warning: AutoLoad audio manager not found!")

func sync_autoload() -> void:
	# Ensure this path is correct for your AutoLoad singleton
	var audio_manager = get_node_or_null("/root/AutoLoad")
	if audio_manager:
		audio_manager.volume_bus_1 = volume_bus_1
		audio_manager.volume_bus_2 = volume_bus_2
	else:
		print("Warning: AutoLoad audio manager not found!")

func update_save_data(save_info: Dictionary) -> void:
	# Use .get() with a default value for robustness, in case a key is missing
	current_chapter = save_info.get("chapter", current_chapter)
	current_scene_id = save_info.get("scene_id", current_scene_id)
	current_scene_path = save_info.get("scene_path", current_scene_path)
	player_choices = save_info.get("choices", player_choices)

	volume_bus_1 = save_info.get("volume_bus_1", volume_bus_1)
	volume_bus_2 = save_info.get("volume_bus_2", volume_bus_2)
	fullscreen_enabled = save_info.get("fullscreen_enabled", fullscreen_enabled)

	# Apply fullscreen settings immediately if changed
	if fullscreen_enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	sync_autoload()
	apply_audio_settings()
	save_game() # Save after updating data and applying settings

func add_choice(choice_data: Dictionary) -> void:
	player_choices.append(choice_data)
	save_game()

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE)

func clear_save_data() -> void:
	# Reset all save data to initial values
	current_chapter = 0
	current_scene_id = 0
	current_scene_path = "res://Chapters/Chapter1/Chapter1.tscn"
	player_choices = []
	volume_bus_1 = 0.5
	volume_bus_2 = 0.5
	fullscreen_enabled = false

	# Delete the save file if it exists
	if FileAccess.file_exists(SAVE_FILE):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove(SAVE_FILE)
			print("Save file deleted successfully!")

	sync_autoload()
	apply_audio_settings()
	save_game() # Save the reset state
