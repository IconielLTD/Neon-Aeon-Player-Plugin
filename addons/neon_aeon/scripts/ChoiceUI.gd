extends Control

signal choice_selected(choice: Dictionary)

var choices: Array = []
var choice_buttons: Array = []

# UI Elements
var choices_container: VBoxContainer

func _ready():
	setup_ui()
	visible = false

func setup_ui():
	# Create the choice UI layout - centered buttons
	# Container for choice buttons
	choices_container = VBoxContainer.new()
	choices_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	choices_container.add_theme_constant_override("separation", 10)
	add_child(choices_container)

func show_choices(choice_list: Array, question_text: String = ""):
	# Display choices to the player
	choices = choice_list
	
	# Clear previous buttons
	for button in choice_buttons:
		button.queue_free()
	choice_buttons.clear()
	
	# Create buttons for each choice
	for i in range(choices.size()):
		var choice = choices[i]
		var button = create_choice_button(choice, i)
		choices_container.add_child(button)
		choice_buttons.append(button)
	
	visible = true

func create_choice_button(choice: Dictionary, index: int) -> Button:
	"""Create a styled button for a choice"""
	var button = Button.new()
	
	# Button text: [Button] Choice text
	var button_key = choice.get("button", "?")
	var choice_text = choice.get("text", "Choice")
	button.text = "[" + button_key + "]  " + choice_text
	
	# Set button size based on number of choices
	if choices.size() == 1:
		button.custom_minimum_size = Vector2(200, 50)
	elif choices.size() == 2:
		button.custom_minimum_size = Vector2(250, 40)
	else:
		button.custom_minimum_size = Vector2(200, 35)
	
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Style the button
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.3, 0.3, 0.35, 0.9)
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	normal_style.content_margin_left = 10
	normal_style.content_margin_right = 10
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.4, 0.4, 0.45, 0.95)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.5, 0.5, 0.55, 1.0)
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	button.add_theme_font_size_override("font_size", 18)
	
	# Connect button press
	button.pressed.connect(func(): on_choice_clicked(index))
	
	return button
	
func on_choice_clicked(index: int):
	# 	Handle choice selection via mouse/touch
	if index >= 0 and index < choices.size():
		emit_signal("choice_selected", choices[index])
		hide_choices()
	
func hide_choices():
	visible = false

func _input(event: InputEvent):
	# Handle controller/keyboard input
	if not visible:
		return
	
	# Check for button presses matching choice buttons
	for i in range(choices.size()):
		var choice = choices[i]
		var button_key = choice.get("button", "").to_lower()
		
		# Map common button names
		var action_name = ""
		match button_key:
			"a": action_name = "ui_accept"
			"b": action_name = "ui_cancel"
			"x": action_name = "ui_left"
			"y": action_name = "ui_right"
		
		# Check for keyboard key press (literal key)
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == button_key.unicode_at(0):
				on_choice_clicked(i)
				get_viewport().set_input_as_handled()
				return
		
		# Check for action press (controller buttons)
		if action_name != "" and event.is_action_pressed(action_name):
			on_choice_clicked(i)
			get_viewport().set_input_as_handled()
			return
