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
	print("Starting dialogue with array: ", dialogue_array)
	dialogues = dialogue_array
	current_index = 0
	show()
	show_line(dialogues[0])  # Always show the first line directly

func show_next_valid_line() -> void:
	print("Showing next valid line. Current index: ", current_index)
	# Find the next valid line that either has no requirements or meets them
	while current_index < dialogues.size():
		var line = dialogues[current_index]
		print("Checking line: ", line)
		if not line.has("requires_flag") or active_flags.has(line.requires_flag):
			show_line(line)
			return
		current_index += 1
	
	# If we've gone through all lines, end the dialogue
	if current_index >= dialogues.size():
		print("No more valid lines, ending dialogue")
		hide()
		dialogue_finished.emit()

func show_line(line: Dictionary) -> void:
	print("Showing line: ", line)
	# Set any flags this line might have
	if line.has("set_flag"):
		active_flags[line.set_flag] = true
		print("Set flag: ", line.set_flag)
	
	# Reset/Hide choices if any lingering
	choices_container.hide()
	# Clear all children from the choices container
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
		if audio_path != "":
			var audio_player = $DialogueAudioPlayer
			audio_player.stop() # Para o anterior, se estiver tocando
			audio_player.stream = load(audio_path)
			audio_player.play()


func _on_line_complete() -> void:
	print("Line complete. Current index: ", current_index)
	# If this line has choices, show them instead of normal input
	var line = dialogues[current_index]
	if line.has("choices"):
		print("Showing choices: ", line.choices)
		show_choices(line.choices)
	else:
		set_process_input(true)

func _input(event: InputEvent) -> void:
	# Only process input if no choices are showing
	if choices_container.visible:
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
			print("End of dialogue array reached")
			hide()
			dialogue_finished.emit()
		else:
			show_next_valid_line()

func show_choices(choices_array: Array) -> void:
	print("Setting up choices: ", choices_array)
	# Populate and display choice buttons
	for choice in choices_array:
		var btn = Button.new()
		btn.text = choice.text
		btn.pressed.connect(_on_choice_selected.bind(choice.next_scene))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choices_container.add_child(btn)
	choices_container.show()

func _on_choice_selected(next_scene_id: int) -> void:
	print("Choice selected with next_scene_id: ", next_scene_id)
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
