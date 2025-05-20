extends Control

@onready var save_system = get_node("/root/SaveSystem")

func _ready() -> void:
	for button in get_tree().get_nodes_in_group("buttongroup"):
		button.pressed.connect(Callable(self, "_on_button_pressed").bind(button))
		button.mouse_exited.connect(Callable(self, "_on_mouse_interaction").bind(button, "exited"))
		button.mouse_entered.connect(Callable(self, "_on_mouse_interaction").bind(button, "entered"))
	
	# Update continue button state
	var continue_button = get_node("ContinueButton")  # Adjust the path to your continue button
	if continue_button:
		continue_button.disabled = !save_system.has_save_file()

func _on_mouse_interaction(button: Button, state: String) -> void:
	match state:
		"exited":
			button.modulate.a = 1.0
		"entered":
			button.modulate.a = 0.5

func _on_button_pressed(button: Button) -> void:
	match button.text:
		"NOVO JOGO":
			save_system.clear_save_data()  # Clear save data before starting new game
			get_tree().change_scene_to_file("res://Chapters/Chapter1/Chapter1.tscn")
		"CONTINUAR":
			var save_data = save_system.load_game()
			if save_data.has("scene_path"):
				get_tree().change_scene_to_file(save_data["scene_path"])
		"CONFIGURACOES":
			print("Abrir menu de configurações")
		"SAIR":
			get_tree().quit()
