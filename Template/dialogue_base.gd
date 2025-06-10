extends Control
signal dialogue_finished
signal choice_made(next_scene_id)

# Runtime data
var dialogues: Array = []
var current_index: int = 0
var tween: Tween
var active_flags: Dictionary = {}  # Store active flags

# Reference to the choices container (VBoxContainer)
@onready var choices_container: VBoxContainer = $ChoicesContainer

func _ready() -> void:
	hide()
	# Ensure choices UI is hidden
	choices_container.hide()

# Begin a dialogue sequence: pass an Array of Dictionaries
func start(dialogue_array: Array) -> void:
	dialogues = dialogue_array
	current_index = 0
	print("DEBUG >>> Dialogue START iniciado com:", dialogues)
	show()
	show_line(dialogues[0])

func show_next_valid_line() -> void:
	# Find the next valid line that either has no requirements or meets them
	while current_index < dialogues.size():
		var line = dialogues[current_index]
		if not line.has("requires_flag") or active_flags.has(line.requires_flag):
			show_line(line)
			return
		current_index += 1
	
	# If we've gone through all lines, end the dialogue
	if current_index >= dialogues.size():
		hide()
		dialogue_finished.emit()

func show_line(line: Dictionary) -> void:
	print("DEBUG >>> show_line() chamado com texto:", line.text)

	# Set any flags this line might have
	if line.has("set_flag"):
		active_flags[line.set_flag] = true
	
	# Reset/Hide choices if any lingering
	if choices_container.visible:
		choices_container.hide()
	# Clear all children from the choices container
	if not choices_container.get_children().is_empty():
		for child in choices_container.get_children():
			child.queue_free()
	
	# line keys: "speaker","text","sprite","transition","position","choices"
	var pos = line.get("position", "left")
	match pos:
		"left":
			$CharPortrait.anchor_left = 0.0
			$CharPortrait.anchor_right = 0.2
			$CharPortrait.position.x = -75
			$CharPortrait.flip_h = true
			$DialoguePanel/Panel.position.x = 0
		"right":
			$CharPortrait.anchor_left = 0.8
			$CharPortrait.anchor_right = 1.0
			$CharPortrait.position.x = get_viewport_rect().size.x * 0.76
			$CharPortrait.flip_h = false
			
	# Only load and show sprite if it exists in the line
	if line.has("sprite"):
		$CharPortrait.texture = load(line.sprite)
		$CharPortrait.show()
	else:
		$CharPortrait.hide()
		
	$DialoguePanel/Panel/CharacterName.text = line.speaker
	$DialoguePanel/DialogueText.text = line.text
	$DialoguePanel/DialogueText.visible_ratio = 0
	
	# Fade-in panel if requested
	if line.get("transition") == "fade_in":
		$DialoguePanel.modulate.a = 0
		tween = create_tween()
		tween.tween_property($DialoguePanel, "modulate:a", 1.0, 0.5)
	
	# Type-on text
	var duration = max(0.5, line.text.length() * 0.02)
	tween = create_tween()
	tween.tween_property($DialoguePanel/DialogueText, "visible_ratio", 1.0, duration)
	tween.tween_callback(_on_line_complete)

	# TOCAR ÁUDIO SE EXISTIR NA CENA
	if line.has("audio"):
		var audio_path = line.audio
		print("Tentando tocar áudio:", audio_path)
		if audio_path != "":
			var player = get_tree().root.get_node("Chapter1/DialogueAudioPlayer")
			if player:
				player.stop()
				player.stream = load(audio_path)
				player.volume_db = 6
				player.play()
				print("Áudio tocando:", audio_path)
			else:
				print("ERRO: DialogueAudioPlayer não encontrado na cena Chapter1.")


func _on_line_complete() -> void:
	# If this line has choices, show them instead of normal input
	var line = dialogues[current_index]
	if line.has("choices"):
		show_choices(line.choices)
	else:
		set_process_input(true)

func _input(event: InputEvent) -> void:
	# Only process input if no choices are showing
	if choices_container.visible:
		# We want _input to *not* advance dialogue if choices are visible.
		# Buttons themselves handle input.
		return
	
	# Handle both mouse click and key press to advance dialogue
	if ((event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or 
		event.is_action_released("ui_accept")):
		# If text is still typing, complete it immediately
		if $DialoguePanel/DialogueText.visible_ratio < 1.0:
			if tween:
				tween.kill()
			$DialoguePanel/DialogueText.visible_ratio = 1.0
			_on_line_complete()
			return
			
		# Otherwise advance to next dialogue
		set_process_input(false)
		current_index += 1
		if current_index >= dialogues.size():
			hide()
			dialogue_finished.emit()
		else:
			show_next_valid_line()

func show_choices(choices_array: Array) -> void:
	if choices_array.is_empty():
		print("[DialogueSystem] Warning: Choices array is empty. No buttons to show.")
		return

	for choice_data in choices_array:
		var btn = Button.new()
		btn.text = choice_data.text
		# Add debug print to verify the signal connection
		print("[DialogueSystem] Connecting button '%s' to _on_choice_selected with next_scene: %s" % [choice_data.text, choice_data.next_scene])
		var err = btn.pressed.connect(_on_choice_selected.bind(choice_data.next_scene))
		if err != OK:
			print("[DialogueSystem] ERROR: Failed to connect button signal! Error code: ", err)
		else:
			print("[DialogueSystem] Successfully connected button signal")

		btn.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
		choices_container.add_child(btn)

	choices_container.show()

func _on_choice_selected(next_scene_id: int) -> void:
	print("[DialogueSystem] Button pressed! Next scene ID: ", next_scene_id)  # Debug print
	# Clear UI
	for child in choices_container.get_children():
		child.queue_free()
	choices_container.hide()
	
	# Emit signal with the chosen next_scene_id
	choice_made.emit(next_scene_id)
	
	# Don't try to show the next scene here - let the chapter handle it
	hide()

# Function to reset flags (useful when starting a new game)
func reset_flags() -> void:
	active_flags.clear()
