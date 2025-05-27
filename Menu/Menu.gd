extends Control

@onready var save_system = get_node("/root/SaveSystem")

func _ready() -> void:
	# Conectar botões
	for button in get_tree().get_nodes_in_group("buttongroup"):
		button.pressed.connect(Callable(self, "_on_button_pressed").bind(button))
		button.mouse_exited.connect(Callable(self, "_on_mouse_interaction").bind(button, "exited"))
		button.mouse_entered.connect(Callable(self, "_on_mouse_interaction").bind(button, "entered"))


	# Ativa/desativa o botão "Continuar"
	var continue_button = get_node("MainContainer/HBoxContainer/VBoxContainer/CONTINUAR")  # ajuste o caminho se necessário
	if continue_button:
		continue_button.disabled = !save_system.has_save_file()

func _on_mouse_interaction(button: Button, state: String) -> void:
	match state:
		"exited":
			button.modulate.a = 1.0
		"entered":
			button.modulate.a = 0.5
			play_button_sound()

func _on_button_pressed(button: Button) -> void:
	
	print("Botão pressionado:", button.text)
	play_button_sound()
	match button.name:
		"NOVO JOGO":
			save_system.clear_save_data()
			get_tree().change_scene_to_file("res://Chapters/Chapter1/Chapter1.tscn")
		
		"CONTINUAR":
			save_system.load_game()  # garante que os dados estejam atualizados
			if save_system.current_scene_path != "":
				get_tree().change_scene_to_file(save_system.current_scene_path)
		"CONFIGURACOES":
			get_tree().change_scene_to_file("res://Menu/settings.tscn")
		"SAIR":
			get_tree().quit()
			
func _on_botao_qualquer_pressed():
	$ClickSound.stream = load("res://Assets/Audio/SFX/buttonpress.wav")
	$ClickSound.play()

func _on_botao_qualquer_mouse_entered():
	$ClickSound.stream = load("res://Assets/Audio/SFX/buttonpress.wav")
	$ClickSound.play()

func play_button_sound():
	var sound = $ClickSound
	sound.stream = load("res://Assets/Audio/SFX/buttonpress.wav")
	sound.play()
