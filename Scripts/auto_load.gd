extends Node

# Dados do jogo
var current_chapter: int = 0
var current_scene_id: int = 0
var current_scene_path: String = ""
var player_choices: Array = []

# Valores de volume
var volume_bus_1: float = 0.5
var volume_bus_2: float = 0.5


func apply_audio() -> void:
	AudioServer.set_bus_volume_db(1, linear_to_db(volume_bus_1))
	AudioServer.set_bus_mute(1, volume_bus_1 < 0.01)

	AudioServer.set_bus_volume_db(2, linear_to_db(volume_bus_2))
	AudioServer.set_bus_mute(2, volume_bus_2 < 0.01)
