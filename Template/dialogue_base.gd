extends Control
signal dialogue_finished
signal choice_made(next_scene_id)

# Runtime data
var dialogues: Array = []
var current_index: int = 0
var tween: Tween
var active_flags: Dictionary = {}  # Store active flags
var choice_was_made: bool = false  # Flag to prevent duplicate processing after choice

# Reference to the choices container (VBoxContainer)
@onready var choices_container: VBoxContainer = $ChoicesContainer

func _ready() -> void:
	hide()
	# Ensure choices UI is hidden
	choices_container.hide()

# Begin a dialogue sequence: pass an Array of Dictionaries
func start(dialogue_array: Array) -> void:
	print("[DialogueSystem] Starting dialogue with array: ", dialogue_array)
	
	# Reset the dialogue system first
	reset_dialogue()
	
	dialogues = dialogue_array
	current_index = 0
	print("DEBUG >>> Dialogue START iniciado com:", dialogues)
	
	# Sync flags from save system
	sync_flags_from_save_system()
	
	show()
	print("[DialogueSystem] Dialogue system is now visible")
	show_line(dialogues[0])
	print("[DialogueSystem] First line displayed")

# Function to sync flags from save system
func sync_flags_from_save_system() -> void:
	var save_system = get_node_or_null("/root/SaveSystem")
	if save_system:
		# Clear current flags and reload from save system
		active_flags.clear()
		# Note: We can't directly access save_system.flags, so we'll rely on the save system
		# to set flags as they're encountered in the dialogue
		print("[DialogueSystem] Synced with save system")
	else:
		print("[DialogueSystem] WARNING: SaveSystem not found during sync!")

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
	print("[DialogueSystem] Showing line for speaker: ", line.get("speaker", "Unknown"))

	# Set any flags this line might have
	if line.has("set_flag"):
		active_flags[line.set_flag] = true
		print("[DialogueSystem] Setting flag from line: ", line.set_flag)
		
		# Also set flag in save system
		var save_system = get_node_or_null("/root/SaveSystem")
		if save_system:
			save_system.set_flag(line.set_flag, true)
			print("[DialogueSystem] Flag saved to save system from line: ", line.set_flag)
		else:
			print("[DialogueSystem] WARNING: SaveSystem not found!")
	
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
		print("[DialogueSystem] Character portrait shown")
	else:
		$CharPortrait.hide()
		print("[DialogueSystem] Character portrait hidden")
		
	$DialoguePanel/Panel/CharacterName.text = line.speaker
	$DialoguePanel/DialogueText.text = line.text
	$DialoguePanel/DialogueText.visible_ratio = 0
	
	print("[DialogueSystem] Dialogue text set, starting type-on effect")
	
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
				player.play()
				print("Áudio tocando:", audio_path)
			else:
				print("ERRO: DialogueAudioPlayer não encontrado na cena Chapter1.")

func _on_line_complete() -> void:
	print("[DialogueSystem] Line complete, checking for choices")
	# If this line has choices, show them instead of normal input
	var line = dialogues[current_index]
	if line.has("choices"):
		print("[DialogueSystem] Line has choices, showing them")
		show_choices(line.choices)
	else:
		print("[DialogueSystem] Line has no choices, enabling input")
		set_process_input(true)

func _input(event: InputEvent) -> void:
	# Don't process input if a choice has been made
	if choice_was_made:
		print("[DialogueSystem] Input ignored - choice already made")
		return
	
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
		var err = btn.pressed.connect(_on_choice_selected.bind(choice_data))
		if err != OK:
			print("[DialogueSystem] ERROR: Failed to connect button signal! Error code: ", err)
		else:
			print("[DialogueSystem] Successfully connected button signal")

		btn.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
		choices_container.add_child(btn)

	choices_container.show()

func _on_choice_selected(choice_data: Dictionary) -> void:
	print("[DialogueSystem] Button pressed! Choice data: ", choice_data)  # Debug print
	
	# Set flag to prevent duplicate processing
	choice_was_made = true
	print("[DialogueSystem] Choice made flag set to true")
	
	# Set flag in both local active_flags and save system if present
	if choice_data.has("set_flag"):
		var flag_name = choice_data["set_flag"]
		active_flags[flag_name] = true
		print("[DialogueSystem] Setting flag: ", flag_name)
		
		# Also set flag in save system
		var save_system = get_node_or_null("/root/SaveSystem")
		if save_system:
			save_system.set_flag(flag_name, true)
			print("[DialogueSystem] Flag saved to save system: ", flag_name)
		else:
			print("[DialogueSystem] WARNING: SaveSystem not found!")
	
	# Clear UI
	for child in choices_container.get_children():
		child.queue_free()
	choices_container.hide()
	
	# Disable input processing to prevent duplicate signals
	set_process_input(false)
	print("[DialogueSystem] Input processing disabled")
	
	# Emit signal with the chosen next_scene_id
	choice_made.emit(choice_data["next_scene"])
	print("[DialogueSystem] Choice signal emitted with next_scene: ", choice_data["next_scene"])
	
	# Don't hide the dialogue system - let the chapter handle the transition
	# The chapter will call start_scene_by_id which will restart the dialogue

# Function to reset flags (useful when starting a new game)
func reset_flags() -> void:
	active_flags.clear()

# Function to reset the dialogue system
func reset_dialogue() -> void:
	print("[DialogueSystem] Resetting dialogue system")
	
	# Reset choice flag
	choice_was_made = false
	
	# Stop any ongoing tweens
	if tween:
		tween.kill()
		tween = null
	
	# Clear choices
	if choices_container.visible:
		choices_container.hide()
	for child in choices_container.get_children():
		child.queue_free()
	
	# Reset text
	$DialoguePanel/DialogueText.visible_ratio = 0
	$DialoguePanel/DialogueText.text = ""
	
	# Reset character portrait
	$CharPortrait.hide()
	
	# Reset dialogue panel
	$DialoguePanel.modulate.a = 1.0
	
	# Disable input processing
	set_process_input(false)
	
	print("[DialogueSystem] Dialogue system reset completed")
