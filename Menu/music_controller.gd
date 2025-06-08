extends Node2D

@onready var bgmusic: AudioStreamPlayer2D = $bgmusic

# Valores de volume
var volume_bus_1: float = 0.5



func _ready() -> void:
	apply_audio()
	play_music()


func apply_audio() -> void:
	var sfx_bus = AudioServer.get_bus_index("sfx")      # ou o nome real do bus de efeitos
	var music_bus = AudioServer.get_bus_index("music")
	AudioServer.set_bus_volume_db(1, linear_to_db(volume_bus_1))
	AudioServer.set_bus_mute(1, volume_bus_1 < 0.01)


func play_music():
	if not bgmusic.playing:
		bgmusic.play()
		
func linear_to_db(value: float) -> float:
	if value <= 0.01:
		return -80
	else:
		return 20 * (log(value) / log(10))
