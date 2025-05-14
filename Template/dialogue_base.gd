extends Control
signal dialogue_finished
signal choice_made(next_scene_id)

# Runtime data
var dialogues: Array = []
var current_index: int = 0
var tween: Tween

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
	show()
	show_line(dialogues[0])

func show_line(line: Dictionary) -> void:
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
	
	$CharPortrait.texture = load(line.sprite)
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
			show_line(dialogues[current_index])

func show_choices(choices_array: Array) -> void:
	# Populate and display choice buttons
	for choice in choices_array:
		var btn = Button.new()
		btn.text = choice.text
		btn.pressed.connect(_on_choice_selected.bind(choice.next_scene))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choices_container.add_child(btn)
	choices_container.show()

func _on_choice_selected(next_scene_id: int) -> void:
	# Clear UI
	print("Choice selected with next_scene_id: ", next_scene_id)
	for child in choices_container.get_children():
		child.queue_free()
	choices_container.hide()
	
	# Emit signal with the chosen next_scene_id
	choice_made.emit(next_scene_id)
	
	# Don't hide or emit dialogue_finished here - let the chapter handle scene transition
	# hide()
	# dialogue_finished.emit()
