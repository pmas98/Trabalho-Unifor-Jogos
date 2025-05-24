extends Control

@onready var save_system = get_node("/root/SaveSystem")
var slider_block := true  # Flag para bloquear os handlers ao iniciar

func _ready() -> void:
	# Conecta os botões
	for button in get_tree().get_nodes_in_group("buttongroup"):
		button.pressed.connect(Callable(self, "_on_button_pressed").bind(button))
		button.mouse_exited.connect(Callable(self, "_on_mouse_interaction").bind(button, "exited"))
		button.mouse_entered.connect(Callable(self, "_on_mouse_interaction").bind(button, "entered"))
	
	
	
	# Setar valores dos sliders sem disparar os sinais
	slider_block = true
	$Control/HBoxContainer/HSlider.value = save_system.volume_bus_1
	$Control/HBoxContainer/HSlider2.value = save_system.volume_bus_2
	slider_block = false
	$Control/HBoxContainer/CheckButton.button_pressed = save_system.fullscreen_enabled
	
func _on_mouse_interaction(button: Button, state: String) -> void:
	match state:
		"exited":
			button.modulate.a = 1.0
		"entered":
			button.modulate.a = 0.5
			play_button_sound()

func _on_button_pressed(button: Button) -> void:
	play_button_sound()

	match button.text:
		"<- BACK":
			_on_voltar_pressed()

func _on_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://Menu/Menu.tscn")

func _on_h_slider_value_changed(value: float) -> void:
	if slider_block:
		return  # Ignora se estamos bloqueando os handlers
	save_system.volume_bus_1 = value
	save_system.apply_audio_settings()
	save_system.save_game()

func _on_h_slider_2_value_changed(value: float) -> void:
	if slider_block:
		return  # Ignora se estamos bloqueando os handlers
	save_system.volume_bus_2 = value
	save_system.apply_audio_settings()
	save_system.save_game()

func _on_check_button_toggled(toggled_on: bool) -> void:
	save_system.fullscreen_enabled = toggled_on
	save_system.save_game()

	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
func play_button_sound():
	var sound = $ClickSound
	if sound and sound.is_inside_tree():
		sound.stream = load("res://Assets/Audio/SFX/buttonpress.wav")
		sound.play()
