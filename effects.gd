extends Node

@onready var click_sound: AudioStreamPlayer = $ClickSound

var volume_bus_2: float = 0.5

func _ready():
	click_sound.bus = "sfx"  # Certifique-se que esse bus existe
	click_sound.stream = preload("res://Assets/Audio/SFX/buttonpress.wav")
	apply_sfx_volume()

func play_button_sound():
	if click_sound and click_sound.is_inside_tree():
		if click_sound.playing:
			click_sound.stop()
		click_sound.play()

func apply_sfx_volume():
	var sfx_bus = AudioServer.get_bus_index("sfx")  # Bus chamado "sfx"
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(volume_bus_2))  # Corrigido!
	AudioServer.set_bus_mute(sfx_bus, volume_bus_2 < 0.01)  # Corrigido!

func linear_to_db(value: float) -> float:
	return -80 if value <= 0.01 else 20 * (log(value) / log(10))
