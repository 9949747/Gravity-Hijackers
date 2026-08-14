extends Control
class_name RebindButton

@onready var label: Label = $HBoxContainer/Label as Label
@onready var button: Button = $HBoxContainer/Button as Button

@export var action_name: String = "Shoot"

var is_rebinding := false

func _ready():
	set_process_unhandled_input(false)
	set_process_input(false)
	button.focus_mode = Control.FOCUS_NONE
	set_action_name()
	Load()
	set_text_for_input()

func set_action_name():
	label.text = "Unassigned"

	match action_name:
		"shoot":
			label.text = "Shoot"
		"left":
			label.text = "Move Left"
		"right":
			label.text = "Move Right"
		"up":
			label.text = "Move forward"
		"down":
			label.text = "Move backwards"
		"player_jump":
			label.text = "Jump"
		"player_sprint":
			label.text = "Sprint"
		"player_crouch":
			label.text = "Crouch"
		"reload":
			label.text = "Reload"
		"quit":
			label.text = "Quit"


func set_text_for_input() -> void:
	var action_events = InputMap.action_get_events(action_name)
	if action_events.size() > 0:
		var action_event = action_events[0]
		var input_text = get_input_text(action_event)
		button.text = input_text
	else:
		button.text = "Unassigned"

func get_input_text(event: InputEvent) -> String:
	if event is InputEventKey and event.keycode != 0:
		return OS.get_keycode_string(event.keycode)
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				return "Mouse Left"
			MOUSE_BUTTON_RIGHT:
				return "Mouse Right"
			MOUSE_BUTTON_MIDDLE:
				return "Mouse Middle"
			MOUSE_BUTTON_WHEEL_UP:
				return "Wheel Up"
			MOUSE_BUTTON_WHEEL_DOWN:
				return "Wheel Down"
			_:
				return "Mouse " + str(event.button_index)
	return "Unassigned"

func _on_button_toggled(button_pressed):
	if button_pressed:
		button.text = "Press any key or mouse button..."
		is_rebinding = true
		set_process_input(true)
		set_process_unhandled_input(true)
		
		# Disable toggling on other buttons in the group
		for i in get_tree().get_nodes_in_group("hotkey_button"):
			if i is RebindButton:  # Ensure it's a RebindButton
				if i.action_name != self.action_name:
					i.button.toggle_mode = false
					i.set_process_input(false)
				i.set_process_unhandled_input(false)
	else:
		# Enable toggling again when button is not pressed
		for i in get_tree().get_nodes_in_group("hotkey_button"):
			if i is RebindButton:  # Ensure it's a RebindButton
				if i.action_name != self.action_name:
					i.button.toggle_mode = true
					i.set_process_input(false)
				i.set_process_unhandled_input(false)
			
		is_rebinding = false
		set_text_for_input()

func _input(event: InputEvent) -> void:
	if not is_rebinding:
		return
	
	if event is InputEventKey and event.pressed:
		accept_event()
		rebind_action_key(event)
		button.button_pressed = false
		return
	
	if event is InputEventMouseButton and event.pressed:
		accept_event()
		rebind_action_key(event)
		button.button_pressed = false

func rebind_action_key(event) -> void:
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, event)
	
	set_process_unhandled_input(false)
	set_process_input(false)
	set_text_for_input()
	set_action_name()
	
	var bind_text = get_bind_string(event)
	match action_name:
		"shoot":
			Save.game_data["shoot"] = bind_text
		"up":
			Save.game_data["up"] = bind_text
		"down":
			Save.game_data["down"] = bind_text
		"left":
			Save.game_data["left"] = bind_text
		"right":
			Save.game_data["right"] = bind_text
		"player_sprint":
			Save.game_data["player_sprint"] = bind_text
		"player_crouch":
			Save.game_data["player_crouch"] = bind_text
		"player_jump":
			Save.game_data["player_jump"] = bind_text
		"reload":
			Save.game_data["reload"] = bind_text
		"quit":
			Save.game_data["quit"] = bind_text
	Save.save_data()

func get_bind_string(event: InputEvent) -> String:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				return "Mouse Left"
			MOUSE_BUTTON_RIGHT:
				return "Mouse Right"
			MOUSE_BUTTON_MIDDLE:
				return "Mouse Middle"
			MOUSE_BUTTON_WHEEL_UP:
				return "Wheel Up"
			MOUSE_BUTTON_WHEEL_DOWN:
				return "Wheel Down"
			_:
				return "Mouse " + str(event.button_index)
	elif event is InputEventKey:
		var key_text = OS.get_keycode_string(event.keycode)
		if key_text == "" and event.physical_keycode != 0:
			key_text = OS.get_keycode_string(event.physical_keycode)
		return key_text
	return "Unassigned"

func Load():
	Save.load_saved_keybind(action_name)
