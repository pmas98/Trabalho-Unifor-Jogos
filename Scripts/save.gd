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
	if save_file:
		save_file.store_var(save_data)
		save_file.close()
		print("Game saved successfully!")

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		print("No save file found. Using defaults.")
		return

	var save_file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if save_file:
		var save_data = save_file.get_var()
		save_file.close()

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

func apply_audio_settings() -> void:
	var audio_manager = get_node("/root/AutoLoad")
	audio_manager.volume_bus_1 = volume_bus_1
	audio_manager.volume_bus_2 = volume_bus_2
	audio_manager.apply_audio()

func sync_autoload() -> void:
	var audio_manager = get_node("/root/AutoLoad")
	audio_manager.volume_bus_1 = volume_bus_1
	audio_manager.volume_bus_2 = volume_bus_2

func update_save_data(save_info: Dictionary) -> void:
	current_chapter = save_info.get("chapter", 0)
	current_scene_id = save_info.get("scene_id", 0)
	current_scene_path = save_info.get("scene_path", "")
	player_choices = save_info.get("choices", [])

	volume_bus_1 = save_info.get("volume_bus_1", 0.5)
	volume_bus_2 = save_info.get("volume_bus_2", 0.5)

	sync_autoload()
	apply_audio_settings()
	save_game()

func add_choice(choice_data: Dictionary) -> void:
	player_choices.append(choice_data)
	save_game()

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE)

func clear_save_data() -> void:
	current_chapter = 0
	current_scene_id = 0
	current_scene_path = "res://Chapters/Chapter1/Chapter1.tscn"
	player_choices = []
	volume_bus_1 = 0.5
	volume_bus_2 = 0.5

	if FileAccess.file_exists(SAVE_FILE):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove(SAVE_FILE)
			print("Save file deleted successfully!")

	sync_autoload()
	apply_audio_settings()
	save_game()
