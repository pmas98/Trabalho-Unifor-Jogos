extends Node

const SAVE_FILE = "user://savegame.save"

var current_chapter: int = 0
var current_scene_id: int = 0
var current_scene_path: String = ""
var player_choices: Array = []  # Array to store player choices

func save_game() -> void:
    var save_data = {
        "chapter": current_chapter,
        "scene_id": current_scene_id,
        "scene_path": current_scene_path,
        "choices": player_choices  # Save the choices array
    }
    
    var save_file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
    if save_file:
        save_file.store_var(save_data)
        save_file.close()
        print("Game saved successfully!")

func load_game() -> Dictionary:
    if not FileAccess.file_exists(SAVE_FILE):
        return {
            "chapter": 0,
            "scene_id": 0,
            "scene_path": "res://Chapters/Chapter1/Chapter1.tscn",
            "choices": []  # Initialize empty choices array
        }
    
    var save_file = FileAccess.open(SAVE_FILE, FileAccess.READ)
    if save_file:
        var save_data = save_file.get_var()
        save_file.close()
        return save_data
    
    return {
        "chapter": 0,
        "scene_id": 0,
        "scene_path": "res://Chapters/Chapter1/Chapter1.tscn",
        "choices": []  # Initialize empty choices array
    }

func update_save_data(save_info: Dictionary) -> void:
    current_chapter = save_info["chapter"]
    current_scene_id = save_info["scene_id"]
    current_scene_path = save_info["scene_path"]
    if save_info.has("choices"):
        player_choices = save_info["choices"]
    save_game()

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
    
    # Delete the save file if it exists
    if FileAccess.file_exists(SAVE_FILE):
        var dir = DirAccess.open("user://")
        if dir:
            dir.remove(SAVE_FILE)
            print("Save file deleted successfully!")
    
    # Save the initial state
    save_game() 