extends CanvasLayer

# References to UI elements
@onready var patient_avatar = $Prontuary/ProntuaryContent/MarginContainer/VBoxContainer/PatientHeader/PatientAvatar
@onready var patient_asset = $PatientAsset
@onready var patient_name = $Prontuary/ProntuaryContent/MarginContainer/VBoxContainer/PatientHeader/PatientInfo/PatientName
@onready var patient_details = $Prontuary/ProntuaryContent/MarginContainer/VBoxContainer/PatientHeader/PatientInfo/PatientDetails
@onready var symptoms_list = $Prontuary/ProntuaryContent/MarginContainer/VBoxContainer/SymptomsList
@onready var hr_value = $Prontuary/ProntuaryContent/MarginContainer/VBoxContainer/VitalSigns/HRValue
@onready var spo2_value = $Prontuary/ProntuaryContent/MarginContainer/VBoxContainer/VitalSigns/SpO2Value
@onready var speech_content = $SpeechBubble/SpeechContent
@onready var request_info_button = $ActionButtons/RequestInfoButton
@onready var diagnose_button = $ActionButtons/DiagnoseButton
@onready var next_patient_button = $ActionButtons/NextPatientButton

# Manual elements
@onready var manual = $Manual
@onready var manual_close_button = $ManualContent/CloseButton
@onready var manual_content = $ManualContent
@onready var illness_list_col1 = $ManualContent/MarginContainer/VBoxContainer/PageContent/IllnessGrid/Column1
@onready var illness_list_col2 = $ManualContent/MarginContainer/VBoxContainer/PageContent/IllnessGrid/Column2
@onready var prev_page_button = $ManualContent/MarginContainer/VBoxContainer/PaginationButtons/PrevPageButton
@onready var next_page_button = $ManualContent/MarginContainer/VBoxContainer/PaginationButtons/NextPageButton
@onready var page_label = $ManualContent/MarginContainer/VBoxContainer/PaginationButtons/PageLabel

# Queue elements
@onready var queue_container = $QueueContainer
@onready var queue_label = $QueueLabel

# Manual animation properties
var manual_normal_scale = Vector2(0.12, 0.12)
var manual_hover_scale = Vector2(0.13, 0.13)
var manual_expanded_scale = Vector2(0.35, 0.25)
var manual_animation_speed = 5.0
var is_manual_expanded = false
var manual_normal_position = Vector2(38, 379)
var manual_expanded_position = Vector2.ZERO # This will be calculated in _ready()

# Book Textures
var manual_open_texture = preload("res://Assets/book.png")
var manual_closed_texture = preload("res://Assets/sintomas.png")
var how_to_treat_open_texture = preload("res://Assets/book.png")
var how_to_treat_closed_texture = preload("res://Assets/Tratamentos.png")

# Vital signs colors
const NORMAL_COLOR = Color(0.95, 0.95, 0.95, 1)
const WARNING_COLOR = Color(1, 0.8, 0, 1)
const DANGER_COLOR = Color(1, 0.3, 0.3, 1)
const CRITICAL_COLOR = Color(0.8, 0.1, 0.1, 1) # New color for critical state

# Vital signs ranges
const HR_NORMAL = [60, 100]
const SPO2_NORMAL = [95, 100]
const HR_CRITICAL = [140, 180] # New critical ranges
const SPO2_CRITICAL = [70, 85]

# Game state
var health_update_timer: Timer
var patient_arrival_timer: Timer
var queue_patient_stylebox: StyleBoxFlat
var current_patient_data: Dictionary = {}
var queue_patients: Array = []
var patient_health: float = 100.0 # Patient health percentage
var patient_count: int = 0
var critical_health_threshold: float = 20.0 # Game over when health drops below this
var game_over_popup: PopupPanel
var game_over_label: Label
var available_illnesses: Array = [
	{
		"name": "Common Cold",
		"symptoms": ["Runny nose", "Sore throat", "Cough", "Fever"],
		"vitals": {"hr": [60, 100], "spo2": [95, 100]}
	},
	{
		"name": "Pneumonia",
		"symptoms": ["Chest pain", "Shortness of breath", "Fever", "Cough with phlegm"],
		"vitals": {"hr": [90, 120], "spo2": [85, 95]}
	},
	{
		"name": "Heart Attack",
		"symptoms": ["Chest pain", "Shortness of breath", "Dizziness", "Nausea"],
		"vitals": {"hr": [100, 140], "spo2": [85, 95]}
	},
	{
		"name": "Stroke",
		"symptoms": ["Sudden numbness", "Confusion", "Trouble speaking", "Dizziness"],
		"vitals": {"hr": [70, 110], "spo2": [90, 100]}
	},
	{
		"name": "Appendicitis",
		"symptoms": ["Abdominal pain", "Nausea", "Fever", "Loss of appetite"],
		"vitals": {"hr": [80, 110], "spo2": [95, 100]}
	},
	{
		"name": "Asthma Attack",
		"symptoms": ["Shortness of breath", "Wheezing", "Chest tightness", "Cough"],
		"vitals": {"hr": [90, 130], "spo2": [85, 95]}
	},
	{
		"name": "Diabetes Crisis",
		"symptoms": ["Confusion", "Dizziness", "Nausea", "Excessive thirst"],
		"vitals": {"hr": [80, 120], "spo2": [90, 100]}
	},
	{
		"name": "Septic Shock",
		"symptoms": ["Fever", "Rapid breathing", "Confusion", "Low blood pressure"],
		"vitals": {"hr": [120, 160], "spo2": [80, 90]}
	},
	{
		"name": "Kidney Infection",
		"symptoms": ["Fever", "Back pain", "Nausea", "Frequent urination"],
		"vitals": {"hr": [85, 115], "spo2": [90, 100]}
	},
	{
		"name": "Gastroenteritis",
		"symptoms": ["Abdominal pain", "Nausea", "Diarrhea", "Fever"],
		"vitals": {"hr": [75, 105], "spo2": [95, 100]}
	},
	{
		"name": "Meningitis",
		"symptoms": ["Severe headache", "Fever", "Stiff neck", "Confusion"],
		"vitals": {"hr": [90, 130], "spo2": [90, 100]}
	},
	{
		"name": "Pulmonary Embolism",
		"symptoms": ["Chest pain", "Shortness of breath", "Rapid breathing", "Cough"],
		"vitals": {"hr": [100, 140], "spo2": [80, 90]}
	},
	{
		"name": "Panic Attack",
		"symptoms": ["Chest pain", "Shortness of breath", "Dizziness", "Rapid heartbeat"],
		"vitals": {"hr": [100, 150], "spo2": [95, 100]}
	},
	{
		"name": "Dehydration",
		"symptoms": ["Dizziness", "Confusion", "Dry mouth", "Excessive thirst"],
		"vitals": {"hr": [90, 130], "spo2": [90, 100]}
	},
	{
		"name": "Hypothermia",
		"symptoms": ["Shivering", "Confusion", "Dizziness", "Slow breathing"],
		"vitals": {"hr": [50, 80], "spo2": [90, 100]}
	}
]

# New mapping of symptoms to potential illnesses
var symptoms_to_illnesses: Dictionary = {
	"Chest pain": ["Heart Attack", "Pneumonia"],
	"Shortness of breath": ["Heart Attack", "Pneumonia", "Asthma Attack"],
	"Dizziness": ["Heart Attack", "Stroke"],
	"Fever": ["Common Cold", "Pneumonia", "Appendicitis"],
	"Cough": ["Common Cold", "Pneumonia", "Asthma Attack"],
	"Runny nose": ["Common Cold"],
	"Sore throat": ["Common Cold"],
	"Nausea": ["Heart Attack", "Appendicitis"],
	"Abdominal pain": ["Appendicitis"],
	"Loss of appetite": ["Appendicitis"],
	"Sudden numbness": ["Stroke"],
	"Confusion": ["Stroke"],
	"Trouble speaking": ["Stroke"],
	"Cough with phlegm": ["Pneumonia"],
	"Wheezing": ["Asthma Attack"],
	"Chest tightness": ["Asthma Attack"]
}

# Get all unique symptoms for the manual
var all_symptoms: Array = symptoms_to_illnesses.keys()

# Typing effect variables
var typing_timer: Timer
var current_message_index: int = 0
var messages_to_type: Array = []
var is_typing: bool = false
var typing_speed: float = 0.05 # Time between each character
var current_typed_text: String = ""

# Manual pagination
var current_page: int = 0
var items_per_page: int = 6
var total_pages: int = 0

# Treatment data
var available_treatments: Array = [
	{
		"name": "Antibiotics",
		"good_for": ["Pneumonia", "Kidney Infection", "Meningitis", "Appendicitis", "Septic Shock"], # Added "Septic Shock"
		"contraindications": ["Dizziness", "Nausea"]
	},
	{
		"name": "Bronchodilators",
		"good_for": ["Asthma Attack", "Pneumonia"],
		"contraindications": ["Chest pain", "Rapid heartbeat"]
	},
	{
		"name": "Anticoagulants",
		"good_for": ["Pulmonary Embolism", "Heart Attack"],
		"contraindications": ["Chest pain", "Shortness of breath"]
	},
	{
		"name": "Antipyretics",
		"good_for": ["Common Cold", "Pneumonia", "Meningitis", "Appendicitis", "Gastroenteritis"],
		"contraindications": ["Low blood pressure", "Dehydration"]
	},
	{
		"name": "Corticosteroids",
		"good_for": ["Asthma Attack", "Pneumonia"],
		"contraindications": ["Diabetes Crisis", "High blood pressure"]
	},
	{
		"name": "Antiemetics",
		"good_for": ["Gastroenteritis", "Kidney Infection", "Appendicitis"],
		"contraindications": ["Dizziness", "Confusion"]
	},
	{
		"name": "Insulin",
		"good_for": ["Diabetes Crisis"],
		"contraindications": ["Low blood sugar", "Dehydration"]
	},
	{
		"name": "Antivirals",
		"good_for": ["Common Cold", "Meningitis"],
		"contraindications": ["Kidney problems", "Liver problems"]
	},
	{
		"name": "Surgery",
		"good_for": ["Appendicitis"],
		"contraindications": ["Heart Attack", "Stroke"]
	},
	{
		"name": "Thrombolytics",
		"good_for": ["Stroke", "Heart Attack"],
		"contraindications": ["Recent surgery", "Bleeding disorders"]
	},
	{
		"name": "IV Fluids",
		"good_for": ["Dehydration", "Gastroenteritis", "Septic Shock"], # Added "Septic Shock"
		"contraindications": ["Heart failure", "Kidney failure"]
	},
	{
		"name": "Warming Treatment",
		"good_for": ["Hypothermia"],
		"contraindications": ["Burns", "Fever"]
	},
	{
		"name": "Anti-anxiety Medication",
		"good_for": ["Panic Attack"],
		"contraindications": ["Severe respiratory depression", "Acute narrow-angle glaucoma"]
	}
]

# References to HowToTreat UI elements
@onready var how_to_treat = $HowToTreat
@onready var how_to_treat_close_button = $HowToTreatContent/CloseButton
@onready var how_to_treat_content = $HowToTreatContent
@onready var treatment_list_col1 = $HowToTreatContent/MarginContainer/VBoxContainer/PageContent/TreatmentGrid/TreatmentColumn1
@onready var treatment_list_col2 = $HowToTreatContent/MarginContainer/VBoxContainer/PageContent/TreatmentGrid/TreatmentColumn2
@onready var how_to_treat_prev_page_button = $HowToTreatContent/MarginContainer/VBoxContainer/PaginationButtons/PrevPageButton
@onready var how_to_treat_next_page_button = $HowToTreatContent/MarginContainer/VBoxContainer/PaginationButtons/NextPageButton
@onready var how_to_treat_page_label = $HowToTreatContent/MarginContainer/VBoxContainer/PaginationButtons/PageLabel

# HowToTreat manual state
var is_how_to_treat_expanded = false
var current_treatment_page = 0
var treatments_per_page = 6
var total_treatment_pages = 0

# Treatment selection popup
var treatment_popup: PopupPanel
var treatment_list_container: VBoxContainer
var selected_treatment: Dictionary = {}
var patient_diagnosed_correctly: bool = false # New variable to track correct diagnosis

func _ready():
	# Initialize timers
	health_update_timer = Timer.new()
	health_update_timer.wait_time = 1.0 # Update every second
	health_update_timer.timeout.connect(_on_health_update_timer_timeout)
	add_child(health_update_timer)

	patient_arrival_timer = Timer.new()
	patient_arrival_timer.wait_time = 30.0 # New patient every 30s
	patient_arrival_timer.timeout.connect(_on_patient_arrival_timer_timeout)
	add_child(patient_arrival_timer)

	# Initialize typing timer
	typing_timer = Timer.new()
	typing_timer.wait_time = typing_speed
	typing_timer.timeout.connect(_on_typing_timer_timeout)
	add_child(typing_timer)

	# Create game over popup
	_create_game_over_popup()

	# Calculate manual expanded position to center it, but slightly to the right
	var viewport_size = get_viewport().get_visible_rect().size
	# Center horizontally and vertically
	manual_expanded_position = Vector2(
		viewport_size.x * 0.4 - (manual.size.x * manual_expanded_scale.x / 2),
		(viewport_size.y - manual.size.y * manual_expanded_scale.y) / 2
	)

	# Connect button signals
	request_info_button.pressed.connect(_on_request_info_pressed)
	diagnose_button.pressed.connect(_on_diagnose_pressed)
	# Disconnect and reconnect the close button signal to ensure it's fresh
	if manual_close_button.pressed.is_connected(_on_manual_close_pressed):
		manual_close_button.pressed.disconnect(_on_manual_close_pressed)
	manual_close_button.pressed.connect(_on_manual_close_pressed)
	next_patient_button.pressed.connect(_on_next_patient_pressed)
	prev_page_button.pressed.connect(_on_prev_page_pressed)
	next_page_button.pressed.connect(_on_next_page_pressed)

	print("=== Button Signal Debug ===")
	print(
		"Close button signal connected: ",
		manual_close_button.pressed.is_connected(_on_manual_close_pressed)
	)
	print("Close button process mode: ", manual_close_button.process_mode)
	print("Close button mouse filter: ", manual_close_button.mouse_filter)
	print("Close button visible: ", manual_close_button.visible)
	print("=====================")

	# Initialize illness list and pagination
	_initialize_manual_pages()

	# Set initial manual state
	manual_content.process_mode = Node.PROCESS_MODE_DISABLED
	manual_content.visible = false
	manual.scale = manual_normal_scale
	manual_close_button.visible = false
	manual_close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	manual_content.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Store queue style and initialize queue
	if !queue_container.get_children().is_empty():
		queue_patient_stylebox = queue_container.get_child(0).get_theme_stylebox("panel")
	generate_queue()

	# Load initial patient
	load_next_patient()
	patient_arrival_timer.start()

	# Setup tooltips
	_setup_tooltips()

	# Disable scroll bars in speech content
	speech_content.scroll_active = false

	# Connect HowToTreat button signals
	how_to_treat_close_button.pressed.connect(_on_how_to_treat_close_pressed)
	how_to_treat_prev_page_button.pressed.connect(_on_how_to_treat_prev_page_pressed)
	how_to_treat_next_page_button.pressed.connect(_on_how_to_treat_next_page_pressed)

	# Initialize HowToTreat manual
	_initialize_how_to_treat_pages()

	# Set initial HowToTreat state
	how_to_treat_content.process_mode = Node.PROCESS_MODE_DISABLED
	how_to_treat_content.visible = false
	how_to_treat.scale = manual_normal_scale
	how_to_treat_close_button.visible = false
	how_to_treat_close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	how_to_treat_content.mouse_filter = Control.MOUSE_FILTER_IGNORE

	illness_list_col1.scroll_active = true
	illness_list_col2.scroll_active = true
	treatment_list_col1.scroll_active = true
	treatment_list_col2.scroll_active = true

	# Create treatment selection popup
	_create_treatment_popup()

func _setup_tooltips():
	# Add tooltips to vital signs
	var hr_tooltip = (
		"Normal range: %d-%d bpm\nHigh: Tachycardia\nLow: Bradycardia"
		% [HR_NORMAL[0], HR_NORMAL[1]]
	)
	var spo2_tooltip = (
		"Normal range: %d-%d%%\nLow: Hypoxemia\nCritical: <90%%" % [SPO2_NORMAL[0], SPO2_NORMAL[1]]
	)
	hr_value.tooltip_text = hr_tooltip
	spo2_value.tooltip_text = spo2_tooltip

func create_new_patient():
	var illness = available_illnesses[randi() % available_illnesses.size()]
	return {
		"name": "Patient %d" % randi_range(1, 999),
		"age": randi_range(18, 80),
		"sex": "Male" if randf() > 0.5 else "Female",
		"illness": illness,
		"avatar": "res://assets/patient%d.png" % randi_range(1, 6), # Random number between 1 and 6
		"time_elapsed": 0
	}

func generate_queue():
	queue_patients.clear()
	for i in range(3):
		queue_patients.append(create_new_patient())
	update_queue_display()

func update_queue_display():
	# Clear existing queue display
	for child in queue_container.get_children():
		child.queue_free()
	if queue_patient_stylebox:
		# Add new panels for each patient in queue
		for _patient in queue_patients:
			var panel = Panel.new()
			panel.custom_minimum_size = Vector2(60, 60)
			panel.add_theme_stylebox_override("panel", queue_patient_stylebox)
			queue_container.add_child(panel)
	queue_label.text = "Patients in Queue: %d" % queue_patients.size()
	queue_label.visible = true

func load_next_patient():
	if queue_patients.is_empty():
		health_update_timer.stop()
		speech_content.text = "No patients in queue."
		current_patient_data = {}
		# Clear patient UI
		patient_name.text = "No Patient"
		patient_details.text = ""
		symptoms_list.text = ""
		hr_value.text = "N/A"
		spo2_value.text = "N/A"
		hr_value.modulate = NORMAL_COLOR
		spo2_value.modulate = NORMAL_COLOR
		patient_asset.texture = null
		patient_avatar.texture = null
		patient_avatar.visible = false
		request_info_button.disabled = true
		diagnose_button.disabled = true
		next_patient_button.visible = false # Ensure next patient button is hidden
		patient_diagnosed_correctly = false # Reset diagnosis status for the new patient
		return

	patient_count += 1
	request_info_button.disabled = false
	diagnose_button.disabled = false
	next_patient_button.visible = false # Ensure next patient button is hidden when loading new patient

	if patient_count == 6:
		current_patient_data = {
			"name": "Patient Zero",
			"age": randi_range(20, 60),
			"sex": "Male" if randf() > 0.5 else "Female",
			"illness": {
				"name": "COVID-19",
				"symptoms": ["Fever", "Cough", "Shortness of breath", "Loss of taste or smell"],
				"vitals": {"hr": [90, 130], "spo2": [80, 94]}
			},
			"avatar": "res://assets/patient%d.png" % randi_range(1, 6),
			"time_elapsed": 0,
			"is_covid_patient": true
		}
		queue_patients.pop_front() # Remove a patient from queue to keep it flowing
	else:
		current_patient_data = queue_patients.pop_front()

	# If the patient has stored vitals from being in queue, use them
	if current_patient_data.has("current_vitals"):
		update_vitals(current_patient_data.current_vitals)
		current_patient_data.erase("current_vitals") # Remove stored vitals after using them
	update_patient_ui()
	update_queue_display()
	patient_health = 100.0 # Reset patient health for the new patient
	patient_diagnosed_correctly = false # Reset diagnosis status for the new patient
	health_update_timer.start()

	# Debugging: Print patient's disease and correct treatment
	print("--- New Patient Loaded ---")
	print("Patient Name: ", current_patient_data.name)
	print("Patient Disease: ", current_patient_data.illness.name)
	var correct_treatments = []
	for treatment in available_treatments:
		if current_patient_data.illness.name in treatment.good_for:
			correct_treatments.append(treatment.name)
	print(
		"Correct Treatment(s): ",
		"None found" if correct_treatments.is_empty() else ", ".join(correct_treatments)
	)
	print("--------------------------")

func update_patient_ui():
	# Update UI
	patient_name.text = current_patient_data.name
	patient_details.text = (
		"Age: %d | Sex: %s" % [current_patient_data.age, current_patient_data.sex]
	)
	# Update patient avatar texture
	var avatar_texture = load(current_patient_data.avatar)
	if avatar_texture:
		patient_asset.texture = avatar_texture
		patient_avatar.texture = avatar_texture
		patient_avatar.visible = true
	else:
		patient_asset.texture = null
		patient_avatar.texture = null
		patient_avatar.visible = false
	# Update symptoms with icons and colors
	symptoms_list.text = _format_symptoms(current_patient_data.illness.symptoms)
	# Update speech bubble with conversational symptoms
	_format_speech_bubble(current_patient_data.illness.symptoms)
	# Update vitals immediately
	_update_patient_vitals()

func update_vitals(vitals_data: Dictionary):
	var hr = vitals_data.get("hr", 0)
	var spo2 = vitals_data.get("spo2", 0)
	var is_critical = vitals_data.get("is_critical", false)

	# Update HR with color and warning indicator
	hr_value.text = "%d bpm" % hr
	if is_critical:
		hr_value.text += " ⚠️" # Add warning symbol
	hr_value.modulate = _get_vital_color(hr, HR_NORMAL[0], HR_NORMAL[1], is_critical)

	# Update SpO2 with color and warning indicator
	spo2_value.text = "%d%%" % spo2
	if is_critical:
		spo2_value.text += " ⚠️" # Add warning symbol
	spo2_value.modulate = _get_vital_color(spo2, SPO2_NORMAL[0], SPO2_NORMAL[1], is_critical)

func _get_vital_color(
	value: int, min_normal: int, max_normal: int, is_critical: bool = false
) -> Color:
	if is_critical:
		return CRITICAL_COLOR
	if value < min_normal * 0.9 or value > max_normal * 1.1: # Adjusted warning range slightly
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
		"Trouble speaking": "🗣️",
		"Loss of taste or smell": "👅"
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

func _format_speech_bubble(symptoms: Array) -> void:
	# Map each symptom to a short, conversational phrase
	var symptom_to_phrase = {
		"Chest pain": "My chest hurts...",
		"Shortness of breath": "I can't breathe well...",
		"Dizziness": "I feel dizzy...",
		"Fever": "I have a fever...",
		"Cough": "I keep coughing...",
		"Runny nose": "My nose won't stop running...",
		"Sore throat": "My throat is sore...",
		"Nausea": "I feel sick...",
		"Abdominal pain": "My stomach hurts...",
		"Loss of appetite": "I don't want to eat...",
		"Sudden numbness": "I can't feel my limbs...",
		"Confusion": "I'm confused...",
		"Trouble speaking": "I can't speak clearly...",
		"Loss of taste or smell": "I can't taste or smell anything..."
	}
	messages_to_type.clear()
	for symptom in symptoms:
		if symptom_to_phrase.has(symptom):
			messages_to_type.append(symptom_to_phrase[symptom])
		else:
			messages_to_type.append("I'm experiencing %s..." % symptom.to_lower())

	# Start typing the first message
	current_message_index = 0
	current_typed_text = ""
	speech_content.text = ""
	is_typing = true
	typing_timer.start()

func _on_typing_timer_timeout():
	if not is_typing or messages_to_type.is_empty():
		typing_timer.stop()
		is_typing = false
		return
	var current_message = messages_to_type[current_message_index]
	if current_typed_text.length() < current_message.length():
		current_typed_text += current_message[current_typed_text.length()]
		speech_content.text = current_typed_text
	else:
		# Message is complete
		typing_timer.stop()
		is_typing = false

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_viewport().get_mouse_position()
		var manual_rect = Rect2(manual.position, manual.size * manual.scale)
		var close_button_rect = Rect2(manual_close_button.global_position, manual_close_button.size)
		var how_to_treat_rect = Rect2(how_to_treat.position, how_to_treat.size * how_to_treat.scale)
		var how_to_treat_close_button_rect = Rect2(
			how_to_treat_close_button.global_position, how_to_treat_close_button.size
		)
		print("=== Input Debug ===")
		print("Mouse position: ", mouse_pos)
		print("Manual rect: ", manual_rect)
		print("Close button rect: ", close_button_rect)
		print("Is manual expanded: ", is_manual_expanded)
		print("Is mouse in manual: ", manual_rect.has_point(mouse_pos))
		print("Is mouse in close button: ", close_button_rect.has_point(mouse_pos))
		print("Close button process mode: ", manual_close_button.process_mode)
		print("Close button mouse filter: ", manual_close_button.mouse_filter)
		print("Close button visible: ", manual_close_button.visible)
		print(
			"Close button signal connected: ",
			manual_close_button.pressed.is_connected(_on_manual_close_pressed)
		)
		print("HowToTreat rect: ", how_to_treat_rect)
		print("Is mouse in HowToTreat: ", how_to_treat_rect.has_point(mouse_pos))
		print(
			"Is mouse in HowToTreat close button: ",
			how_to_treat_close_button_rect.has_point(mouse_pos)
		)
		print("=================")

		if is_manual_expanded and close_button_rect.has_point(mouse_pos):
			print("Direct close button click detected")
			_on_manual_close_pressed()
		elif (
			not is_manual_expanded
			and not is_how_to_treat_expanded
			and manual_rect.has_point(mouse_pos)
		):
			_on_manual_clicked()
		elif is_how_to_treat_expanded and how_to_treat_close_button_rect.has_point(mouse_pos):
			_on_how_to_treat_close_pressed()
		elif (
			not is_how_to_treat_expanded
			and not is_manual_expanded
			and how_to_treat_rect.has_point(mouse_pos)
		):
			_on_how_to_treat_clicked()

func _process(delta):
	if is_manual_expanded:
		# Animate to expanded position and scale
		manual.position = manual.position.lerp(
			manual_expanded_position, delta * manual_animation_speed
		)
		manual_content.position = manual.position.lerp(
			manual_expanded_position, delta * manual_animation_speed
		)
		manual.scale = manual.scale.lerp(manual_expanded_scale, delta * manual_animation_speed)
		# Corrected line: Apply inverse scale to keep content size consistent
		manual_content.scale = Vector2(1, 1)
	else:
		# Handle hover effect
		var mouse_pos = get_viewport().get_mouse_position()
		var manual_rect = Rect2(manual.position, manual.size * manual.scale)
		manual.position = manual.position.lerp(
			manual_normal_position, delta * manual_animation_speed
		)
		manual_content.position = manual_content.position.lerp(
			manual_normal_position, delta * manual_animation_speed
		)
		if manual_rect.has_point(mouse_pos):
			manual.scale = manual.scale.lerp(manual_hover_scale, delta * manual_animation_speed)
		else:
			manual.scale = manual.scale.lerp(manual_normal_scale, delta * manual_animation_speed)
		manual_content.scale = Vector2(1, 1) # Reset content scale

	# Add HowToTreat animation
	if is_how_to_treat_expanded:
		how_to_treat.position = how_to_treat.position.lerp(
			manual_expanded_position, delta * manual_animation_speed
		)
		how_to_treat_content.position = how_to_treat_content.position.lerp(
			manual_expanded_position, delta * manual_animation_speed
		)
		how_to_treat.scale = how_to_treat.scale.lerp(
			manual_expanded_scale, delta * manual_animation_speed
		)
		# Corrected line for the second manual
		how_to_treat_content.scale = Vector2(1, 1)
	else:
		var mouse_pos = get_viewport().get_mouse_position()
		var how_to_treat_rect = Rect2(how_to_treat.position, how_to_treat.size * how_to_treat.scale)
		var how_to_treat_normal_position = Vector2(357.065, 379.0)
		how_to_treat.position = how_to_treat.position.lerp(
			how_to_treat_normal_position, delta * manual_animation_speed
		)
		how_to_treat_content.position = how_to_treat_content.position.lerp(
			how_to_treat_normal_position, delta * manual_animation_speed
		)
		if how_to_treat_rect.has_point(mouse_pos):
			how_to_treat.scale = how_to_treat.scale.lerp(
				manual_hover_scale, delta * manual_animation_speed
			)
		else:
			how_to_treat.scale = how_to_treat.scale.lerp(
				manual_normal_scale, delta * manual_animation_speed
			)
		how_to_treat_content.scale = Vector2(1, 1)

func _update_patient_vitals():
	if current_patient_data.is_empty():
		return

	# If the patient has been correctly diagnosed, prevent health from dropping
	if patient_diagnosed_correctly:
		patient_health = 100.0 # Keep health at maximum
		# Apply normal vitals, regardless of time elapsed
		var hr_range = current_patient_data.illness.vitals.hr
		var spo2_range = current_patient_data.illness.vitals.spo2
		var hr = randi_range(hr_range[0], hr_range[1])
		var spo2 = randi_range(spo2_range[0], spo2_range[1])
		var vitals = {"hr": hr, "spo2": spo2, "is_critical": false} # No longer critical once correctly diagnosed
		update_vitals(vitals)
		return # Exit here to prevent further degradation calculations

	var illness = current_patient_data.illness
	var time_elapsed = current_patient_data.time_elapsed

	# INCREASED: Degradation factor reaches 1 after 120 seconds (2 minutes) instead of 60 seconds.
	var degradation_factor = clamp(time_elapsed / 120.0, 0, 1)

	# Update patient health based on time elapsed
	patient_health = max(0.0, 100.0 - (degradation_factor * 100.0))

	# Check for critical condition
	var is_critical = patient_health <= critical_health_threshold
	if is_critical:
		_trigger_game_over()
		return

	# Calculate how close we are to critical state (0 to 1)
	var critical_proximity = 1.0 - (patient_health / 100.0)

	# HR: Increases more dramatically as health decreases
	var hr_range = illness.vitals.hr
	var hr_degraded_min = int(
		lerp(float(hr_range[0]), float(HR_CRITICAL[0]), critical_proximity * 1.5) # More dramatic increase
	)
	var hr_degraded_max = int(
		lerp(float(hr_range[1]), float(HR_CRITICAL[1]), critical_proximity * 1.5) # More dramatic increase
	)
	var hr = randi_range(hr_degraded_min, hr_degraded_max)

	# SpO2: Decreases more dramatically as health decreases
	var spo2_range = illness.vitals.spo2
	var spo2_degraded_min = int(
		lerp(float(spo2_range[0]), float(SPO2_CRITICAL[0]), critical_proximity * 1.5) # More dramatic decrease
	)
	var spo2_degraded_max = int(
		lerp(float(spo2_range[1]), float(SPO2_CRITICAL[1]), critical_proximity * 1.5) # More dramatic decrease
	)
	var spo2 = randi_range(spo2_degraded_min, spo2_degraded_max)

	# Add some randomness to make it more dynamic
	hr += randi_range(-5, 5)
	spo2 += randi_range(-2, 2)

	# Ensure values stay within reasonable bounds
	hr = clamp(hr, 40, 200)
	spo2 = clamp(spo2, 60, 100)

	var vitals = {"hr": hr, "spo2": spo2, "is_critical": patient_health <= 30.0} # Show critical indicators when health is below 30%
	update_vitals(vitals)

func _on_health_update_timer_timeout():
	if not current_patient_data.is_empty():
		current_patient_data.time_elapsed += 1
		_update_patient_vitals()

	# Apply slower degradation to queued patients
	var queue_degradation_factor = 0.3 # Queue patients deteriorate at 30% of the normal rate
	for patient in queue_patients:
		patient.time_elapsed += queue_degradation_factor # Add a fraction of the time elapsed
		# Update queue patient vitals if they're getting close to critical
		if patient.time_elapsed > 90: # Only update vitals if they've been waiting a while
			var degradation_factor = clamp(patient.time_elapsed / 120.0, 0, 1)
			var patient_health = max(0.0, 100.0 - (degradation_factor * 100.0))
			if patient_health <= 30.0: # If health is getting low, update their vitals
				var illness = patient.illness
				var critical_proximity = 1.0 - (patient_health / 100.0)
				# Update HR
				var hr_range = illness.vitals.hr
				var hr_degraded_min = int(
					lerp(float(hr_range[0]), float(HR_CRITICAL[0]), critical_proximity * 1.5)
				)
				var hr_degraded_max = int(
					lerp(float(hr_range[1]), float(HR_CRITICAL[1]), critical_proximity * 1.5)
				)
				# Update SpO2
				var spo2_range = illness.vitals.spo2
				var spo2_degraded_min = int(
					lerp(float(spo2_range[0]), float(SPO2_CRITICAL[0]), critical_proximity * 1.5)
				)
				var spo2_degraded_max = int(
					lerp(float(spo2_range[1]), float(SPO2_CRITICAL[1]), critical_proximity * 1.5)
				)
				# Store updated vitals in patient data for when they become current patient
				patient.current_vitals = {
					"hr": randi_range(hr_degraded_min, hr_degraded_max),
					"spo2": randi_range(spo2_degraded_min, spo2_degraded_max),
					"is_critical": patient_health <= 30.0
				}

func _on_patient_arrival_timer_timeout():
	if queue_patients.size() >= 5: # Max queue size of 5
		return
	var new_patient = create_new_patient()
	queue_patients.append(new_patient)
	update_queue_display()
	# If there was no patient before, load this one.
	if current_patient_data.is_empty():
		load_next_patient()

func _on_request_info_pressed():
	if current_patient_data.is_empty():
		return
	# Add a random additional symptom or detail
	var additional_info = [
		"Patient reports feeling worse",
		(
			"Patient has a history of %s"
			% ["hypertension", "diabetes", "asthma", "heart disease"][randi() % 4]
		),
		"Patient is allergic to %s" % ["penicillin", "aspirin", "sulfa drugs"][randi() % 3],
		"Patient's symptoms started %d hours ago" % randi_range(1, 48)
	]
	var additional_speech = [
		"It's getting worse...",
		"I have %s..." % ["hypertension", "diabetes", "asthma", "heart disease"][randi() % 4],
		"I'm allergic to %s..." % ["penicillin", "aspirin", "sulfa drugs"][randi() % 3],
		"This started %d hours ago..." % randi_range(1, 48)
	]
	# Add the new information to symptoms list
	var current_text = symptoms_list.text
	symptoms_list.text = current_text + "\n• " + additional_info[randi() % additional_info.size()]
	# Add new message to typing queue
	messages_to_type.append(additional_speech[randi() % additional_speech.size()])
	if not is_typing:
		current_message_index = messages_to_type.size() - 1
		current_typed_text = ""
		is_typing = true
		typing_timer.start()

func _on_diagnose_pressed():
	if current_patient_data.is_empty():
		return
	# Show treatment options instead of just a message
	_show_treatment_options()

func _on_manual_clicked():
	print("=== Manual Clicked ===")
	print("Current manual state - is_expanded: ", is_manual_expanded)
	print("Close button visible: ", manual_close_button.visible)
	print("Close button process mode: ", manual_close_button.process_mode)
	is_manual_expanded = true
	manual.texture = manual_open_texture
	manual_content.process_mode = Node.PROCESS_MODE_ALWAYS
	manual_content.visible = true
	manual_close_button.visible = true # Make the close button visible
	manual_close_button.process_mode = Node.PROCESS_MODE_ALWAYS
	manual_content.mouse_filter = Control.MOUSE_FILTER_STOP # Allow mouse interaction
	# Reset to first page when opening manual
	current_page = 0
	_update_page_display()
	_update_illness_list()
	# Hide action buttons when manual is open
	request_info_button.visible = false
	diagnose_button.visible = false
	# Ensure the manual and its content are on top by moving them to the end of the scene tree
	var parent = manual.get_parent()
	parent.move_child(manual, -1)
	parent.move_child(manual_content, -1)
	print("After opening - is_expanded: ", is_manual_expanded)
	print("Close button visible: ", manual_close_button.visible)
	print("Close button process mode: ", manual_close_button.process_mode)
	print("=====================")

func _on_manual_close_pressed():
	print("=== Manual Close Button Pressed ===")
	print("Current manual state - is_expanded: ", is_manual_expanded)
	print("Close button visible: ", manual_close_button.visible)
	print("Close button process mode: ", manual_close_button.process_mode)
	is_manual_expanded = false
	manual.texture = manual_closed_texture
	manual_content.process_mode = Node.PROCESS_MODE_DISABLED
	manual_content.visible = false
	manual_close_button.visible = false # Hide the close button
	manual_close_button.process_mode = Node.PROCESS_MODE_DISABLED
	manual_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Show action buttons when manual is closed
	request_info_button.visible = true
	diagnose_button.visible = true
	# Instantly reset manual to closed state
	manual.scale = manual_normal_scale
	manual.position = manual_normal_position
	manual_content.position = manual_normal_position
	manual_content.scale = Vector2(1, 1)
	print("After closing - is_expanded: ", is_manual_expanded)
	print("Close button visible: ", manual_close_button.visible)
	print("Close button process mode: ", manual_close_button.process_mode)
	print("=====================")

func _on_next_patient_pressed():
	# Reset patient health and diagnosis state
	patient_health = 100.0
	patient_diagnosed_correctly = false # Reset the flag for the next patient
	# Clear any ongoing typing
	typing_timer.stop()
	is_typing = false
	speech_content.text = ""
	# Reset UI state
	next_patient_button.visible = false
	next_patient_button.disabled = false # Ensure button is enabled for next use
	diagnose_button.disabled = false
	request_info_button.disabled = false
	# Load next patient
	load_next_patient()
	# Ensure speech content is updated for the new patient
	if not current_patient_data.is_empty():
		_format_speech_bubble(current_patient_data.illness.symptoms)

func _on_prev_page_pressed():
	print("=== Pagination Debug ===")
	print("Previous page pressed")
	print("Current page before change: ", current_page)
	print("Total pages: ", total_pages)
	print("Items per page: ", items_per_page)
	print("Total illnesses: ", available_illnesses.size())
	if current_page > 0:
		current_page -= 1
		print("Moving to page: ", current_page)
		_update_page_display()
		_update_illness_list()
		print("Page display updated")
	print("=====================")

func _on_next_page_pressed():
	print("=== Pagination Debug ===")
	print("Next page pressed")
	print("Current page before change: ", current_page)
	print("Total pages: ", total_pages)
	print("Items per page: ", items_per_page)
	print("Total illnesses: ", available_illnesses.size())
	if current_page < total_pages - 1:
		current_page += 1
		print("Moving to page: ", current_page)
		_update_page_display()
		_update_illness_list()
		print("Page display updated")
	else:
		print("Already on last page, cannot go forward")
	print("=====================")

func _create_game_over_popup():
	game_over_popup = PopupPanel.new()
	game_over_popup.size = get_viewport().get_visible_rect().size
	game_over_popup.title = "Game Over"
	# Create a style for the popup - full black background
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.95) # Almost black with slight transparency
	game_over_popup.add_theme_stylebox_override("panel", style)

	# Create a VBoxContainer to stack the message and button
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 30) # Space between message and button

	# Create game over message label
	var message_label = Label.new()
	message_label.text = "GAME OVER\nThe patient has died.\nYou took too long to make the correct diagnosis."
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 32)
	message_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2)) # Red color
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Create a center container for the button
	var center_container = CenterContainer.new()

	# Create a style for the restart button
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.4, 0.8, 1)
	button_style.border_width_left = 2
	button_style.border_width_top = 2
	button_style.border_width_right = 2
	button_style.border_width_bottom = 2
	button_style.border_color = Color(0.3, 0.5, 0.9, 1)
	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	button_style.corner_radius_bottom_right = 8
	button_style.corner_radius_bottom_left = 8

	var restart_button = Button.new()
	restart_button.text = "Restart Game"
	restart_button.custom_minimum_size = Vector2(200, 50)
	restart_button.pressed.connect(_on_restart_game_pressed)
	restart_button.add_theme_font_size_override("font_size", 24)
	restart_button.add_theme_stylebox_override("normal", button_style)

	# Add hover style
	var button_hover_style = button_style.duplicate()
	button_hover_style.bg_color = Color(0.25, 0.45, 0.85, 1)
	restart_button.add_theme_stylebox_override("hover", button_hover_style)

	# Add pressed style
	var button_pressed_style = button_style.duplicate()
	button_pressed_style.bg_color = Color(0.15, 0.35, 0.75, 1)
	restart_button.add_theme_stylebox_override("pressed", button_pressed_style)

	center_container.add_child(restart_button)
	vbox.add_child(message_label)
	vbox.add_child(center_container)
	game_over_popup.add_child(vbox)
	add_child(game_over_popup)

func _on_restart_game_pressed():
	# Reset game state
	patient_health = 100.0
	patient_count = 0
	patient_diagnosed_correctly = false # Reset this flag
	queue_patients.clear()
	generate_queue()
	load_next_patient()
	game_over_popup.hide()
	health_update_timer.start()
	patient_arrival_timer.start()
	# Reset UI state
	next_patient_button.visible = false
	next_patient_button.disabled = false # Ensure button is enabled
	diagnose_button.disabled = false
	request_info_button.disabled = false
func _trigger_game_over():
	# Check if the patient is the special COVID-19 patient.
	if current_patient_data.get("is_covid_patient", false):
		# Instead of a game over, this unique situation transitions the story.
		_start_chapter_1_transition()
		return # Prevents the standard game over pop-up from appearing.

	health_update_timer.stop()
	patient_arrival_timer.stop()
	game_over_popup.popup_centered()
	# Disable all game controls
	request_info_button.disabled = true
	diagnose_button.disabled = true
	next_patient_button.disabled = true
	
func _start_chapter_1_transition():
	health_update_timer.stop()
	patient_arrival_timer.stop()

	request_info_button.disabled = true
	diagnose_button.disabled = true
	next_patient_button.disabled = true

	# Create the PopupPanel
	var covid_popup = PopupPanel.new()

	# Style the background to be nearly opaque
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.95)
	covid_popup.add_theme_stylebox_override("panel", style)

	# Set a minimum size to make it wider
	covid_popup.min_size = Vector2(1200, 200)

	# Create a container for internal margins
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 30)

	# Create a label with centered text and autowrap
	var message_label = Label.new()
	message_label.text = "E assim começou, no dia 14 de Dezembro de 2019, um dos primeiros casos de COVID-19, marcando o início de uma pandemia global."
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Set autowrap mode to handle line breaks correctly
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD

	message_label.add_theme_font_size_override("font_size", 32)
	message_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	# Assemble the popup scene
	margin.add_child(message_label)
	covid_popup.add_child(margin)
	add_child(covid_popup)

	# Display the popup
	print("Transition popup displayed. Waiting for 5 seconds...")
	covid_popup.popup_centered()

	# Wait for 5 seconds before changing the scene
	await get_tree().create_timer(5.0).timeout

	print("Timer finished. Attempting to change scene...")
	
	# --- SOLUTION ---
	# Attempt to change the scene and check for errors
	var scene_path = "res://Chapters/Chapter1/Chapter1.tscn"
	var error = get_tree().change_scene_to_file(scene_path)
	
	# If the scene change fails, print the error code
	if error != OK:
		print("Error changing scene to '%s'. Error code: %s" % [scene_path, error])
func _initialize_manual_pages():
	print("=== Manual Initialization ===")
	# Calculate total pages based on number of illnesses
	total_pages = ceil(float(available_illnesses.size()) / items_per_page)
	current_page = 0
	print("Total illnesses: ", available_illnesses.size())
	print("Items per page: ", items_per_page)
	print("Total pages calculated: ", total_pages)
	# Update UI
	_update_page_display()
	_update_illness_list()
	print("Manual initialization complete")
	print("=====================")

func _update_page_display():
	print("=== Page Display Update ===")
	print("Updating page display")
	print("Current page: ", current_page)
	print("Total pages: ", total_pages)
	# Update page label
	page_label.text = "Page %d/%d" % [current_page + 1, total_pages]
	# Update button states
	prev_page_button.disabled = current_page == 0
	next_page_button.disabled = current_page >= total_pages - 1
	print("Prev button disabled: ", prev_page_button.disabled)
	print("Next button disabled: ", next_page_button.disabled)
	print("=====================")

func _update_illness_list():
	print("=== Illness List Update ===")
	print("Updating illness list")
	print("Current page: ", current_page)
	# Clear current list
	illness_list_col1.text = ""
	illness_list_col2.text = ""
	# Get all unique symptoms
	var all_symptoms = symptoms_to_illnesses.keys()
	# Calculate start and end indices for current page
	var start_idx = current_page * items_per_page
	var end_idx = min(start_idx + items_per_page, all_symptoms.size())
	print("Start index: ", start_idx)
	print("End index: ", end_idx)
	var items_on_this_page = end_idx - start_idx
	if items_on_this_page <= 0:
		print("No items to display on this page.")
		print("=====================")
		return
	var midpoint_idx = start_idx + int(ceil(float(items_on_this_page) / 2.0))
	# Add symptoms to column 1
	var formatted_text1 = ""
	for i in range(start_idx, midpoint_idx):
		var symptom = all_symptoms[i]
		var potential_illnesses = symptoms_to_illnesses[symptom]
		var illnesses_text = ", ".join(potential_illnesses)
		formatted_text1 += "[b]%s:[/b]\nIndicates: %s\n\n" % [symptom, illnesses_text]
		print("Added symptom to col1: ", symptom)
	illness_list_col1.text = formatted_text1

	# Add symptoms to column 2
	var formatted_text2 = ""
	if midpoint_idx < end_idx:
		for i in range(midpoint_idx, end_idx):
			var symptom = all_symptoms[i]
			var potential_illnesses = symptoms_to_illnesses[symptom]
			var illnesses_text = ", ".join(potential_illnesses)
			formatted_text2 += "[b]%s:[/b]\nIndicates: %s\n\n" % [symptom, illnesses_text]
			print("Added symptom to col2: ", symptom)
	illness_list_col2.text = formatted_text2
	print("Text updated in illness list columns")
	print("Number of symptoms on current page: ", end_idx - start_idx)
	print("=====================")

func _initialize_how_to_treat_pages():
	total_treatment_pages = ceil(float(available_treatments.size()) / treatments_per_page)
	current_treatment_page = 0
	_update_treatment_page_display()
	_update_treatment_list()

func _update_treatment_page_display():
	how_to_treat_page_label.text = (
		"Page %d/%d" % [current_treatment_page + 1, total_treatment_pages]
	)
	how_to_treat_prev_page_button.disabled = current_treatment_page == 0
	how_to_treat_next_page_button.disabled = current_treatment_page >= total_treatment_pages - 1

func _update_treatment_list():
	treatment_list_col1.text = ""
	treatment_list_col2.text = ""
	var start_idx = current_treatment_page * treatments_per_page
	var end_idx = min(start_idx + treatments_per_page, available_treatments.size())
	var items_on_this_page = end_idx - start_idx
	if items_on_this_page <= 0:
		return
	var midpoint_idx = start_idx + int(ceil(float(items_on_this_page) / 2.0))
	# Column 1
	var formatted_text1 = ""
	for i in range(start_idx, midpoint_idx):
		var treatment = available_treatments[i]
		formatted_text1 += "[b]%s:[/b]\n" % treatment.name
		formatted_text1 += "Good for: %s\n" % ", ".join(treatment.good_for)
		formatted_text1 += "Do not use if: %s\n\n" % ", ".join(treatment.contraindications)
	treatment_list_col1.text = formatted_text1

	# Column 2
	var formatted_text2 = ""
	if midpoint_idx < end_idx:
		for i in range(midpoint_idx, end_idx):
			var treatment = available_treatments[i]
			formatted_text2 += "[b]%s:[/b]\n" % treatment.name
			formatted_text2 += "Good for: %s\n" % ", ".join(treatment.good_for)
			formatted_text2 += "Do not use if: %s\n\n" % ", ".join(treatment.contraindications)
		treatment_list_col2.text = formatted_text2

func _on_how_to_treat_prev_page_pressed():
	if current_treatment_page > 0:
		current_treatment_page -= 1
		_update_treatment_page_display()
		_update_treatment_list()

func _on_how_to_treat_next_page_pressed():
	if current_treatment_page < total_treatment_pages - 1:
		current_treatment_page += 1
		_update_treatment_page_display()
		_update_treatment_list()

func _on_how_to_treat_close_pressed():
	is_how_to_treat_expanded = false
	how_to_treat.texture = how_to_treat_closed_texture
	how_to_treat_content.process_mode = Node.PROCESS_MODE_DISABLED
	how_to_treat_content.visible = false
	how_to_treat_close_button.visible = false
	how_to_treat_close_button.process_mode = Node.PROCESS_MODE_DISABLED
	how_to_treat_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	request_info_button.visible = true
	diagnose_button.visible = true
	how_to_treat.scale = manual_normal_scale
	var normal_pos = Vector2(357.065, 429.0)
	how_to_treat.position = normal_pos # Reset to original position
	how_to_treat_content.position = normal_pos
	how_to_treat_content.scale = Vector2(1, 1)

func _on_how_to_treat_clicked():
	is_how_to_treat_expanded = true
	how_to_treat.texture = how_to_treat_open_texture
	how_to_treat_content.process_mode = Node.PROCESS_MODE_ALWAYS
	how_to_treat_content.visible = true
	how_to_treat_close_button.visible = true
	how_to_treat_close_button.process_mode = Node.PROCESS_MODE_ALWAYS
	how_to_treat_content.mouse_filter = Control.MOUSE_FILTER_STOP
	current_treatment_page = 0
	_update_treatment_page_display()
	_update_treatment_list()
	request_info_button.visible = false
	diagnose_button.visible = false
	# Ensure the manual and its content are on top by moving them to the end of the scene tree
	var parent = how_to_treat.get_parent()
	parent.move_child(how_to_treat, -1)
	parent.move_child(how_to_treat_content, -1)

func _create_treatment_popup():
	treatment_popup = PopupPanel.new()
	treatment_popup.size = Vector2(600, 400)
	treatment_popup.title = "Select Treatment"
	# Create a style for the popup
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.6, 1, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	treatment_popup.add_theme_stylebox_override("panel", style)

	# Create a VBoxContainer for the content
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	vbox.add_theme_constant_override("margin_left", 20)
	vbox.add_theme_constant_override("margin_top", 20)
	vbox.add_theme_constant_override("margin_right", 20)
	vbox.add_theme_constant_override("margin_bottom", 20)

	# Add title label
	var title_label = Label.new()
	title_label.text = "Select a Treatment"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	vbox.add_child(title_label)

	# Add description label
	var desc_label = Label.new()
	desc_label.text = "Choose the most appropriate treatment for the patient's condition:"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	vbox.add_child(desc_label)

	# Create scroll container for treatment list
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	# Create container for treatment buttons
	treatment_list_container = VBoxContainer.new()
	treatment_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	treatment_list_container.add_theme_constant_override("separation", 10)
	scroll.add_child(treatment_list_container)
	vbox.add_child(scroll)

	# Add cancel button
	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(200, 40)
	cancel_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel_button.pressed.connect(_on_treatment_cancel_pressed)
	vbox.add_child(cancel_button)
	treatment_popup.add_child(vbox)
	add_child(treatment_popup)

func _show_treatment_options():
	if current_patient_data.is_empty():
		return
	# Clear previous treatment buttons
	for child in treatment_list_container.get_children():
		child.queue_free()

	# Create buttons for all available treatments
	for treatment in available_treatments:
		var button = Button.new()
		button.text = treatment.name
		button.custom_minimum_size = Vector2(0, 50)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 18)

		# Add tooltip with treatment details
		var tooltip = (
			"Good for: %s\nDo not use if: %s"
			% [", ".join(treatment.good_for), ", ".join(treatment.contraindications)]
		)
		button.tooltip_text = tooltip
		# Connect button press
		button.pressed.connect(_on_treatment_selected.bind(treatment))
		treatment_list_container.add_child(button)

	# Show popup
	treatment_popup.popup_centered()

func _on_treatment_selected(treatment: Dictionary):
	selected_treatment = treatment
	treatment_popup.hide()

	if current_patient_data.get("is_covid_patient", false):
		_start_chapter_1_transition()
		return

	var is_correct_treatment = false
	var patient_illness = current_patient_data.illness.name

	# Debug logging
	print("=== Treatment Selection Debug ===")
	print("Selected treatment: ", treatment.name)
	print("Patient illness: ", patient_illness)
	print("Treatment good for: ", treatment.good_for)

	# Check if any of the treatment's good_for illnesses match the patient's illness
	# Use case-insensitive comparison and partial matching
	for good_illness in treatment.good_for:
		if good_illness.to_lower() == patient_illness.to_lower():
			is_correct_treatment = true
			print("Found exact match: ", good_illness)
			break
		elif (
			good_illness.to_lower() in patient_illness.to_lower()
			or patient_illness.to_lower() in good_illness.to_lower()
		):
			is_correct_treatment = true
			print("Found partial match: ", good_illness)
			break
	print("Is correct treatment: ", is_correct_treatment)
	print("=====================")

	# Stop any ongoing typing animation
	typing_timer.stop()
	is_typing = false
	messages_to_type.clear()

	if is_correct_treatment:
		patient_diagnosed_correctly = true # Set the flag to true
		var feedback = (
			"Thank you doctor! I'm starting to feel better already. The %s seems to be helping with my %s."
			% [treatment.name.to_lower(), patient_illness.to_lower()]
		)
		messages_to_type.append(feedback)
		print("Added positive feedback message")
	else:
		patient_diagnosed_correctly = false # Ensure the flag is false if an incorrect diagnosis is made
		var helped_symptoms = []
		var unhelped_symptoms = []
		for symptom in current_patient_data.illness.symptoms:
			var symptom_helped = false
			for illness in treatment.good_for:
				if symptoms_to_illnesses.has(symptom) and illness in symptoms_to_illnesses[symptom]:
					symptom_helped = true
					helped_symptoms.append(symptom)
					break
			if not symptom_helped:
				unhelped_symptoms.append(symptom)
		print("Helped symptoms: ", helped_symptoms)
		print("Unhelped symptoms: ", unhelped_symptoms)

		if helped_symptoms.size() > 0:
			# If some symptoms are helped, give partial feedback
			var random_helped = helped_symptoms[randi() % helped_symptoms.size()]
			var feedback_1 = (
				"The %s is helping with my %s, but I still have other symptoms..."
				% [treatment.name.to_lower(), random_helped.to_lower()]
			)
			messages_to_type.append(feedback_1)
			print("Added partial help feedback")
		else:
			# If no symptoms are helped, give negative feedback
			var random_symptom = unhelped_symptoms[randi() % unhelped_symptoms.size()]
			var feedback_1 = "I'm not feeling much better..."
			var feedback_2 = (
				"The %s doesn't seem to help with my %s."
				% [treatment.name.to_lower(), random_symptom.to_lower()]
			)
			messages_to_type.append(feedback_1)
			messages_to_type.append(feedback_2)
			print("Added negative feedback")

	current_message_index = 0
	current_typed_text = ""
	speech_content.text = ""
	is_typing = true
	typing_timer.start()
	
	if patient_diagnosed_correctly: # Check the new flag
		next_patient_button.visible = true
		diagnose_button.disabled = true
		request_info_button.disabled = true
	else:
		diagnose_button.disabled = true
		await get_tree().create_timer(2.0).timeout
		diagnose_button.disabled = false

func _on_treatment_cancel_pressed():
	treatment_popup.hide()
