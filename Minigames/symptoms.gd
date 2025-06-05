extends CanvasLayer

# References to UI elements
@onready var patient_avatar = $Prontuary/ProntuaryContent/MarginContainer/VBoxContainer/PatientHeader/PatientAvatar
@onready var patient_name = $Prontuary/ProntuaryContent/MarginContainer/VBoxContainer/PatientHeader/PatientInfo/PatientName
@onready var patient_details = $Prontuary/ProntuaryContent/MarginContainer/VBoxContainer/PatientHeader/PatientInfo/PatientDetails
@onready var symptoms_list = $Prontuary/ProntuaryContent/MarginContainer/VBoxContainer/SymptomsList
@onready var hr_value = $Prontuary/ProntuaryContent/MarginContainer/VBoxContainer/VitalSigns/HRValue
@onready var spo2_value = $Prontuary/ProntuaryContent/MarginContainer/VBoxContainer/VitalSigns/SpO2Value
@onready var speech_content = $SpeechBubble/SpeechContent

# Action buttons
@onready var request_info_button = $ActionButtons/RequestInfoButton
@onready var diagnose_button = $ActionButtons/DiagnoseButton

# Manual elements
@onready var manual = $Manual
@onready var manual_close_button = $Manual/CloseButton
@onready var manual_content = $Manual/ManualContent
@onready var illness_list = $Manual/ManualContent/MarginContainer/VBoxContainer/IllnessList

# Queue elements
@onready var queue_container = $QueueContainer
@onready var queue_label = $QueueLabel

# Manual animation properties
var manual_normal_scale = Vector2(0.07, 0.07)
var manual_hover_scale = Vector2(0.08, 0.08)
var manual_expanded_scale = Vector2(0.25, 0.25)
var manual_animation_speed = 5.0
var is_manual_expanded = false
var manual_normal_position = Vector2(38, 429)
var manual_expanded_position = Vector2.ZERO

# Vital signs colors
const NORMAL_COLOR = Color(0.95, 0.95, 0.95, 1)
const WARNING_COLOR = Color(1, 0.8, 0, 1)
const DANGER_COLOR = Color(1, 0.3, 0.3, 1)

# Vital signs ranges
const HR_NORMAL = [60, 100]
const SPO2_NORMAL = [95, 100]

# Game state
var vitals_timer: Timer
var current_patient_data: Dictionary = {}
var queue_patients: Array = []
var available_illnesses: Array = [
	{"name": "Common Cold", "symptoms": ["Runny nose", "Sore throat", "Cough", "Fever"], "vitals": {"hr": [60, 100], "spo2": [95, 100]}},
	{"name": "Pneumonia", "symptoms": ["Chest pain", "Shortness of breath", "Fever", "Cough with phlegm"], "vitals": {"hr": [90, 120], "spo2": [85, 95]}},
	{"name": "Heart Attack", "symptoms": ["Chest pain", "Shortness of breath", "Dizziness", "Nausea"], "vitals": {"hr": [100, 140], "spo2": [85, 95]}},
	{"name": "Stroke", "symptoms": ["Sudden numbness", "Confusion", "Trouble speaking", "Dizziness"], "vitals": {"hr": [70, 110], "spo2": [90, 100]}},
	{"name": "Appendicitis", "symptoms": ["Abdominal pain", "Nausea", "Fever", "Loss of appetite"], "vitals": {"hr": [80, 110], "spo2": [95, 100]}}
]

func _ready():
	# Initialize timer for vitals updates
	vitals_timer = Timer.new()
	vitals_timer.wait_time = 1.0  # Update every second
	vitals_timer.timeout.connect(_on_vitals_timer_timeout)
	add_child(vitals_timer)
	
	# Calculate manual expanded position to center it
	var viewport_size = get_viewport().get_visible_rect().size
	manual_expanded_position = (viewport_size - manual.size * manual_expanded_scale) / 2
	
	# Connect button signals
	request_info_button.pressed.connect(_on_request_info_pressed)
	diagnose_button.pressed.connect(_on_diagnose_pressed)
	manual_close_button.pressed.connect(_on_manual_close_pressed)
	
	# Initialize illness list
	illness_list.clear()
	for illness in available_illnesses:
		var symptoms_text = " | ".join(illness.symptoms)
		illness_list.add_item("%s\n%s" % [illness.name, symptoms_text])
	
	# Set initial manual state
	manual_content.process_mode = Node.PROCESS_MODE_DISABLED
	manual_content.visible = false
	manual.scale = manual_normal_scale
	manual_close_button.visible = false
	manual_close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	manual_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Initialize queue
	generate_queue()
	
	# Generate initial patient
	generate_patient()
	
	# Setup tooltips
	_setup_tooltips()
	
	# In _ready() or after loading the font resource
	var custom_font = load("res://path_to_your_font.tres")
	illness_list.add_theme_font_override("font", custom_font)
	illness_list.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1)) # Dark brown

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.95, 0.9, 0.8, 1) # Fully opaque light tan
	bg_style.set_border_width_all(0)
	illness_list.add_theme_stylebox_override("bg", bg_style)

	var select_style = StyleBoxFlat.new()
	select_style.bg_color = Color(0.85, 0.8, 0.65, 0.7) # Subtle tan highlight
	select_style.set_border_width_all(0)
	illness_list.add_theme_stylebox_override("selected", select_style)

	var item_style = StyleBoxFlat.new()
	item_style.bg_color = Color(0, 0, 0, 0) # Fully transparent
	illness_list.add_theme_stylebox_override("item", item_style)

	illness_list.add_theme_constant_override("hseparation", 20)
	illness_list.add_theme_constant_override("vseparation", 10)
	illness_list.add_theme_constant_override("item_margin", 10)

	# Remove the panel background (Godot 4+)
	var panel_style = StyleBoxEmpty.new()
	illness_list.add_theme_stylebox_override("panel", panel_style)

	# Remove ItemList panel background
	illness_list.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	# (Optional) Remove parent panel background if needed
	manual_content.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

func _setup_tooltips():
	# Add tooltips to vital signs
	var hr_tooltip = "Normal range: %d-%d bpm\nHigh: Tachycardia\nLow: Bradycardia" % [HR_NORMAL[0], HR_NORMAL[1]]
	var spo2_tooltip = "Normal range: %d-%d%%\nLow: Hypoxemia\nCritical: <90%%" % [SPO2_NORMAL[0], SPO2_NORMAL[1]]
	
	hr_value.tooltip_text = hr_tooltip
	spo2_value.tooltip_text = spo2_tooltip

func generate_queue():
	queue_patients.clear()
	for i in range(3):
		var illness = available_illnesses[randi() % available_illnesses.size()]
		queue_patients.append({
			"name": "Patient %d" % randi_range(1, 999),
			"age": randi_range(18, 80),
			"sex": "Male" if randf() > 0.5 else "Female",
			"illness": illness
		})
	queue_label.text = "Patients in Queue: %d" % queue_patients.size()

func update_vitals(vitals_data: Dictionary):
	var hr = vitals_data.get("hr", 0)
	var spo2 = vitals_data.get("spo2", 0)
	
	# Update HR with color
	hr_value.text = "%d bpm" % hr
	hr_value.modulate = _get_vital_color(hr, HR_NORMAL[0], HR_NORMAL[1])
	
	# Update SpO2 with color
	spo2_value.text = "%d%%" % spo2
	spo2_value.modulate = _get_vital_color(spo2, SPO2_NORMAL[0], SPO2_NORMAL[1])

func _get_vital_color(value: int, min_normal: int, max_normal: int) -> Color:
	if value < min_normal or value > max_normal:
		if value < min_normal * 0.8 or value > max_normal * 1.2:
			return DANGER_COLOR
		return WARNING_COLOR
	return NORMAL_COLOR

func _format_symptoms(symptoms: Array) -> String:
	var formatted = "[indent]"
	for symptom in symptoms:
		var icon = _get_symptom_icon(symptom)
		var color = _get_symptom_color(symptom)
		formatted += "• [color=%s]%s[/color] %s\n" % [color, icon, symptom]
	formatted += "[/indent]"
	return formatted

func _get_symptom_icon(symptom: String) -> String:
	var icons = {
		"Chest pain": "⚠️",
		"Shortness of breath": "💨",
		"Dizziness": "💫",
		"Fever": "🌡️",
		"Cough": "🤧",
		"Runny nose": "🤧",
		"Sore throat": "😷",
		"Nausea": "🤢",
		"Abdominal pain": "🤕",
		"Loss of appetite": "🍽️",
		"Sudden numbness": "🫥",
		"Confusion": "😵‍💫",
		"Trouble speaking": "🗣️"
	}
	return icons.get(symptom, "•")

func _get_symptom_color(symptom: String) -> String:
	var colors = {
		"Chest pain": "#ff6b6b",
		"Shortness of breath": "#4ecdc4",
		"Dizziness": "#ffe66d",
		"Fever": "#ff9f1c",
		"Cough": "#ff6b6b",
		"Runny nose": "#4ecdc4",
		"Sore throat": "#ff6b6b",
		"Nausea": "#ff9f1c",
		"Abdominal pain": "#ff6b6b",
		"Loss of appetite": "#ffe66d",
		"Sudden numbness": "#ff6b6b",
		"Confusion": "#ffe66d",
		"Trouble speaking": "#ff6b6b"
	}
	return colors.get(symptom, "#ffffff")

func _format_speech_bubble(symptoms: Array) -> String:
	var phrases = [
		"I'm feeling %s",
		"I have %s",
		"I'm experiencing %s",
		"I've been having %s",
		"I can't stop %s",
		"I've got %s"
	]
	
	var symptom_phrases = []
	for symptom in symptoms:
		var phrase = phrases[randi() % phrases.size()]
		var symptom_text = symptom.to_lower()
		
		# Add some variety to the symptom descriptions
		match symptom:
			"Chest pain":
				symptom_text = "this terrible pain in my chest"
			"Shortness of breath":
				symptom_text = "trouble breathing"
			"Dizziness":
				symptom_text = "been feeling dizzy"
			"Fever":
				symptom_text = "a high fever"
			"Cough":
				symptom_text = "been coughing a lot"
			"Runny nose":
				symptom_text = "a runny nose"
			"Sore throat":
				symptom_text = "a really sore throat"
			"Nausea":
				symptom_text = "been feeling nauseous"
			"Abdominal pain":
				symptom_text = "pain in my stomach"
			"Loss of appetite":
				symptom_text = "no appetite at all"
			"Sudden numbness":
				symptom_text = "numbness in my limbs"
			"Confusion":
				symptom_text = "been feeling confused"
			"Trouble speaking":
				symptom_text = "trouble speaking clearly"
		
		symptom_phrases.append(phrase % symptom_text)
	
	# Join phrases with appropriate punctuation
	var speech = ""
	for i in range(symptom_phrases.size()):
		if i == 0:
			speech = symptom_phrases[i]
		elif i == symptom_phrases.size() - 1:
			speech += ", and " + symptom_phrases[i]
		else:
			speech += ", " + symptom_phrases[i]
	
	return speech + "..."

func generate_patient():
	var illness = available_illnesses[randi() % available_illnesses.size()]
	current_patient_data = {
		"name": "Patient %d" % randi_range(1, 999),
		"age": randi_range(18, 80),
		"sex": "Male" if randf() > 0.5 else "Female",
		"illness": illness,
		"avatar": "res://assets/patient_%d.png" % (randi() % 5 + 1)
	}
	
	# Update UI
	patient_name.text = current_patient_data.name
	patient_details.text = "Age: %d | Sex: %s" % [current_patient_data.age, current_patient_data.sex]
	
	# Update symptoms with icons and colors
	symptoms_list.text = _format_symptoms(current_patient_data.illness.symptoms)
	
	# Update speech bubble with conversational symptoms
	speech_content.text = _format_speech_bubble(current_patient_data.illness.symptoms)
	
	# Start vitals timer
	vitals_timer.start()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_manual_expanded:
			var mouse_pos = get_viewport().get_mouse_position()
			var manual_rect = Rect2(manual.position, manual.size * manual.scale)
			
			if manual_rect.has_point(mouse_pos):
				_on_manual_clicked()

func _process(delta):
	if is_manual_expanded:
		# Animate to expanded position and scale
		manual.position = manual.position.lerp(manual_expanded_position, delta * manual_animation_speed)
		manual.scale = manual.scale.lerp(manual_expanded_scale, delta * manual_animation_speed)
		manual_content.scale = manual.scale / manual_normal_scale  # Scale content to match manual
	else:
		# Handle hover effect
		var mouse_pos = get_viewport().get_mouse_position()
		var manual_rect = Rect2(manual.position, manual.size * manual.scale)
		
		if manual_rect.has_point(mouse_pos):
			manual.scale = manual.scale.lerp(manual_hover_scale, delta * manual_animation_speed)
		else:
			manual.position = manual.position.lerp(manual_normal_position, delta * manual_animation_speed)
			manual.scale = manual.scale.lerp(manual_normal_scale, delta * manual_animation_speed)
		manual_content.scale = Vector2(1, 1)  # Reset content scale

func _on_vitals_timer_timeout():
	if current_patient_data.is_empty():
		return
		
	var illness = current_patient_data.illness
	var vitals = {
		"hr": randi_range(illness.vitals.hr[0], illness.vitals.hr[1]),
		"spo2": randi_range(illness.vitals.spo2[0], illness.vitals.spo2[1])
	}
	update_vitals(vitals)

func _on_request_info_pressed():
	if current_patient_data.is_empty():
		return
		
	# Add a random additional symptom or detail
	var additional_info = [
		"Patient reports feeling worse",
		"Patient has a history of %s" % ["hypertension", "diabetes", "asthma", "heart disease"][randi() % 4],
		"Patient is allergic to %s" % ["penicillin", "aspirin", "sulfa drugs"][randi() % 3],
		"Patient's symptoms started %d hours ago" % randi_range(1, 48)
	]
	
	var additional_speech = [
		"It's getting worse...",
		"I have a history of %s" % ["hypertension", "diabetes", "asthma", "heart disease"][randi() % 4],
		"I'm allergic to %s" % ["penicillin", "aspirin", "sulfa drugs"][randi() % 3],
		"This started about %d hours ago" % randi_range(1, 48)
	]
	
	# Add the new information to symptoms list
	var current_text = symptoms_list.text
	symptoms_list.text = current_text + "\n• " + additional_info[randi() % additional_info.size()]
	
	# Update speech bubble with additional information
	speech_content.text = speech_content.text + "\n\n" + additional_speech[randi() % additional_speech.size()]

func _on_diagnose_pressed():
	if current_patient_data.is_empty() or illness_list.get_selected_items().is_empty():
		return
		
	var selected_illness = available_illnesses[illness_list.get_selected_items()[0]]
	var is_correct = selected_illness.name == current_patient_data.illness.name
	
	# Show diagnosis result
	var result_text = "Diagnosis: %s - %s" % [
		selected_illness.name,
		"Correct!" if is_correct else "Incorrect. Actual condition: %s" % current_patient_data.illness.name
	]
	
	# You might want to show this in a popup or dedicated result area
	print(result_text)  # For now, just print to console

func _on_manual_clicked():
	is_manual_expanded = true
	manual_content.process_mode = Node.PROCESS_MODE_INHERIT
	manual_content.visible = true
	manual_close_button.visible = true
	# Hide action buttons when manual is open
	request_info_button.visible = false
	diagnose_button.visible = false

func _on_manual_close_pressed():
	is_manual_expanded = false
	manual_content.process_mode = Node.PROCESS_MODE_DISABLED
	manual_content.visible = false
	manual_close_button.visible = false
	# Show action buttons when manual is closed
	request_info_button.visible = true
	diagnose_button.visible = true
	# Instantly reset manual to closed state
	manual.scale = manual_normal_scale
	manual.position = manual_normal_position
	manual_content.scale = Vector2(1, 1)

# Remove _on_next_patient_pressed function since it's no longer needed 
