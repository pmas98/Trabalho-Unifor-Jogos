extends Control

signal dialogue_finished

# Runtime data
var dialogues: Array = []
var current_index: int = 0
var tween: Tween

func _ready() -> void:
	hide()

# Begin a dialogue sequence: pass an Array of Dictionaries
func start(dialogue_array: Array) -> void:
	dialogues = dialogue_array
	current_index = 0
	show()
	show_line(dialogues[0])

func show_line(line: Dictionary) -> void:
	# line keys: "speaker","text","sprite","transition","position"
	# Position: "left" or "right"
	var pos = line.get("position", "left")
	
	# Adjust sprite position anchors
	match pos:
		"left":
			$CharPortrait.anchor_left = 0.0
			$CharPortrait.anchor_right = 0.2
		"right":
			$CharPortrait.anchor_left = 0.8
			$CharPortrait.anchor_right = 1.0
	
	$CharPortrait.texture = load(line.sprite)
	$DialoguePanel/Panel/CharacterName.text = line.speaker
	$DialoguePanel/DialogueText.text = line.text  # In Godot 4, bbcode_text is replaced with just text
	$DialoguePanel/DialogueText.visible_ratio = 0  # percent_visible is now visible_ratio
	
	# Handle panel fade-in
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
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if event.is_action_released("ui_accept"):
		set_process_input(false)
		current_index += 1
		if current_index >= dialogues.size():
			hide()
			dialogue_finished.emit()
		else:
			show_line(dialogues[current_index])
