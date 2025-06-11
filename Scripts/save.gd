extends Node

const SAVE_FILE = "user://savegame.save"

# Dados do progresso
var current_chapter: int = 0
var current_scene_id: int = 0
var current_scene_path: String = ""
var player_choices: Array = []
var flags: Dictionary = {}  # Add flags dictionary to store game flags

var fullscreen_enabled: bool = true  # Changed default to true for fullscreen by default

# Valores dos sliders de áudio
var volume_bus_1: float = 0.5
var volume_bus_2: float = 0.5

# Save optimization variables
var save_timer: Timer
var pending_save: bool = false
var is_saving: bool = false

func _ready():
	# Create save timer for debouncing
	save_timer = Timer.new()
	save_timer.wait_time = 0.05  # 50ms debounce (reduced from 100ms)
	save_timer.one_shot = true
	save_timer.timeout.connect(_on_save_timer_timeout)
	add_child(save_timer)

func _on_save_timer_timeout():
	if pending_save:
		pending_save = false
		_perform_save()

func _perform_save() -> void:
	if is_saving:
		return  # Prevent concurrent saves
	
	is_saving = true
	
	var save_data = {
		"chapter": current_chapter,
		"scene_id": current_scene_id,
		"scene_path": current_scene_path,
		"choices": player_choices,
		"volume_bus_1": volume_bus_1,
		"volume_bus_2": volume_bus_2,
		"fullscreen_enabled": fullscreen_enabled,
		"flags": flags  # Add flags to save data
	}
	
	var save_file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if not save_file:
		print("Error: Could not open save file for writing!")
		is_saving = false
		return
		
	save_file.store_var(save_data)
	save_file.close()
	is_saving = false

func save_game() -> void:
	# Use debounced save instead of immediate save
	pending_save = true
	if not save_timer.is_stopped():
		save_timer.stop()
	save_timer.start()
	print("Save queued (debounced)")

func save_game_immediate() -> void:
	# For critical saves that need to happen immediately
	_perform_save()

func flush_pending_save() -> void:
	# Force any pending save to happen immediately
	if pending_save:
		print("Flushing pending save...")
		save_timer.stop()
		pending_save = false
		_perform_save()
	else:
		print("No pending save to flush")

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		print("No save file found. Using defaults.")
		# Set default values if no save file exists
		current_chapter = 0
		current_scene_id = 0
		current_scene_path = "res://Chapters/Chapter1/Chapter1.tscn"
		player_choices = []
		flags = {}  # Initialize empty flags
		volume_bus_1 = 0.5
		volume_bus_2 = 0.5
		fullscreen_enabled = true
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
		flags = {}  # Clear flags
		volume_bus_1 = 0.5
		volume_bus_2 = 0.5
		fullscreen_enabled = true
		apply_audio_settings()
		return

	# Atualizar dados locais
	current_chapter = save_data.get("chapter", 0)
	current_scene_id = save_data.get("scene_id", 0)
	current_scene_path = save_data.get("scene_path", "res://Chapters/Chapter1/Chapter1.tscn")
	player_choices = save_data.get("choices", [])
	flags = save_data.get("flags", {})  # Load flags from save data

	volume_bus_1 = save_data.get("volume_bus_1", 0.5)
	volume_bus_2 = save_data.get("volume_bus_2", 0.5)
	fullscreen_enabled = save_data.get("fullscreen_enabled", true)

	apply_fullscreen_setting()

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
	flags = save_info.get("flags", flags)

	volume_bus_1 = save_info.get("volume_bus_1", volume_bus_1)
	volume_bus_2 = save_info.get("volume_bus_2", volume_bus_2)
	fullscreen_enabled = save_info.get("fullscreen_enabled", fullscreen_enabled)

	# Apply fullscreen settings immediately if changed
	apply_fullscreen_setting()

	sync_autoload()
	apply_audio_settings()
	# Use debounced save instead of immediate save
	save_game()

func update_save_data_immediate(save_info: Dictionary) -> void:
	# Use .get() with a default value for robustness, in case a key is missing
	current_chapter = save_info.get("chapter", current_chapter)
	current_scene_id = save_info.get("scene_id", current_scene_id)
	current_scene_path = save_info.get("scene_path", current_scene_path)
	player_choices = save_info.get("choices", player_choices)
	flags = save_info.get("flags", flags)

	volume_bus_1 = save_info.get("volume_bus_1", volume_bus_1)
	volume_bus_2 = save_info.get("volume_bus_2", volume_bus_2)
	fullscreen_enabled = save_info.get("fullscreen_enabled", fullscreen_enabled)

	# Apply fullscreen settings immediately if changed
	apply_fullscreen_setting()

	sync_autoload()
	apply_audio_settings()
	# Use immediate save for scene transitions to avoid delays
	save_game_immediate()

func add_choice(choice_data: Dictionary) -> void:
	player_choices.append(choice_data)
	save_game_immediate()

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE)

func clear_save_data() -> void:
	# Store current audio and fullscreen settings before clearing
	var current_audio_bus_1 = volume_bus_1
	var current_audio_bus_2 = volume_bus_2
	var current_fullscreen = fullscreen_enabled
	
	# Reset all save data to initial values
	current_chapter = 0
	current_scene_id = 0
	current_scene_path = "res://Chapters/Chapter1/Chapter1.tscn"
	player_choices = []
	flags = {}  # Clear flags
	
	# Restore audio and fullscreen settings
	volume_bus_1 = current_audio_bus_1
	volume_bus_2 = current_audio_bus_2
	fullscreen_enabled = current_fullscreen

	# Delete the save file if it exists
	if FileAccess.file_exists(SAVE_FILE):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove(SAVE_FILE)
			print("Save file deleted successfully!")

	sync_autoload()
	apply_audio_settings()
	save_game_immediate() # Save the reset state with preserved settings

func clear_game_progress_only() -> void:
	# Clear only game progress data, preserving audio and fullscreen settings
	current_chapter = 0
	current_scene_id = 0
	current_scene_path = "res://Chapters/Chapter1/Chapter1.tscn"
	player_choices = []
	flags = {}  # Clear flags
	
	# Save the reset state with preserved audio and fullscreen settings
	save_game_immediate()

# Add new flag-related methods
func set_flag(flag_name: String, value: bool) -> void:
	print("Setting flag: ", flag_name, " = ", value)
	flags[flag_name] = value
	# Use immediate save for flags to avoid delays in dialogue choices
	save_game_immediate()

func set_flags_batch(flags_dict: Dictionary) -> void:
	# Set multiple flags at once to reduce save operations
	print("Setting multiple flags: ", flags_dict.keys())
	for flag_name in flags_dict:
		flags[flag_name] = flags_dict[flag_name]
	# Use immediate save for flags to avoid delays
	save_game_immediate()

func has_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

func get_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

func clear_flag(flag_name: String) -> void:
	if flags.has(flag_name):
		print("Clearing flag: ", flag_name)
		flags.erase(flag_name)
		# Use immediate save for flags to avoid delays
		save_game_immediate()

func _notification(what):
	# Force save when the game is about to exit
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		flush_pending_save()
	elif what == NOTIFICATION_PREDELETE:
		# Force save when the node is being deleted
		flush_pending_save()

func apply_fullscreen_setting() -> void:
	# Apply fullscreen setting to the window
	if fullscreen_enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
