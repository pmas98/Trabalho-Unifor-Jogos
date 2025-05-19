extends Control

func _ready() -> void:
	for button in get_tree().get_nodes_in_group("buttongroup"):
		button.pressed.connect(Callable(self, "_on_button_pressed").bind(button))
		button.mouse_exited.connect(Callable(self, "_on_mouse_interaction").bind(button, "exited"))
		button.mouse_entered.connect(Callable(self, "_on_mouse_interaction").bind(button, "entered"))

func _on_mouse_interaction(button: Button, state: String) -> void:
	match state:
		"exited":
			button.modulate.a = 1.0
		"entered":
			button.modulate.a = 0.5

func _on_button_pressed(button: Button) -> void:
	match button.text:
		"NOVO JOGO":
			get_tree().change_scene_to_file("res://Chapters/Chapter1/Chapter1.tscn")
		"CONTINUAR":
			print("Lógica de continuar jogo ainda não implementada")
		"CONFIGURACOES":
			print("Abrir menu de configurações")
		"SAIR":
			get_tree().quit()
