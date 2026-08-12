extends Node

const SAVEFILE = "user://SAVEFILE.save"
const DEFAULT_GAME_DATA = {
	"Resolution": Vector2i(1920, 1080),
	"Window_mode": "Fullscreen",
	"Vsync_on": false,
	"Master_volume": 10,
	"SFX_volume": 10,
	"Music_volume": 10,
	"FOV": 75,
	"X_Mouse_sens_Multi": 0.05,
	"Y_Mouse_sens_Multi": 0.05,
	"shoot": "Mouse Left",
	"left": "A",
	"right": "D",
	"up": "W",
	"down": "S",
	"player_jump": "Space",
	"player_sprint": "Shift",
	"player_crouch": "Ctrl",
	"reload": "R",
	"quit": "Esc",
}
var game_data

func _ready():
	load_data()
	load_saved_keybinds()
	print(game_data)
	#print(game_data["Resolution"])
	#print(game_data["Window_mode"])
	Set_Window()
	get_window().set_size(game_data["Resolution"] as Vector2i)

func load_data():
	if not FileAccess.file_exists(SAVEFILE):
		game_data = DEFAULT_GAME_DATA.duplicate(true)
		var file = FileAccess.open(SAVEFILE, FileAccess.WRITE)
		file.store_var(game_data)
		file.close()
	else:
		var file = FileAccess.open(SAVEFILE, FileAccess.READ)
		var loaded_data = file.get_var()
		file.close()

		if loaded_data == null or typeof(loaded_data) != TYPE_DICTIONARY:
			print("Save file corrupted or empty, creating new data")
			game_data = DEFAULT_GAME_DATA.duplicate(true)
			var new_file = FileAccess.open(SAVEFILE, FileAccess.WRITE)
			new_file.store_var(game_data)
			new_file.close()
		else:
			game_data = DEFAULT_GAME_DATA.duplicate(true)
			for key in DEFAULT_GAME_DATA.keys():
				if loaded_data.has(key):
					game_data[key] = loaded_data[key]

func save_data():
	var file = FileAccess.open(SAVEFILE, FileAccess.WRITE)
	file.store_var(game_data)
	file.close()

func get_input_event_from_string(bind_string: String) -> InputEvent:
	var button_index = -1
	var upper = bind_string.to_upper()
	if upper.begins_with("MOUSE "):
		var button_name = upper.substr(6)
		if button_name == "LEFT" or button_name == "MOUSE_BUTTON_LEFT":
			button_index = MOUSE_BUTTON_LEFT
		elif button_name == "RIGHT" or button_name == "MOUSE_BUTTON_RIGHT":
			button_index = MOUSE_BUTTON_RIGHT
		elif button_name == "MIDDLE" or button_name == "MOUSE_BUTTON_MIDDLE":
			button_index = MOUSE_BUTTON_MIDDLE
		elif button_name == "WHEEL UP" or button_name == "MOUSE_BUTTON_WHEEL_UP":
			button_index = MOUSE_BUTTON_WHEEL_UP
		elif button_name == "WHEEL DOWN" or button_name == "MOUSE_BUTTON_WHEEL_DOWN":
			button_index = MOUSE_BUTTON_WHEEL_DOWN
	elif upper == "WHEEL UP" or upper == "MOUSE_BUTTON_WHEEL_UP":
		button_index = MOUSE_BUTTON_WHEEL_UP
	elif upper == "WHEEL DOWN" or upper == "MOUSE_BUTTON_WHEEL_DOWN":
		button_index = MOUSE_BUTTON_WHEEL_DOWN

	if button_index != -1:
		var mouse_event = InputEventMouseButton.new()
		mouse_event.button_index = button_index
		return mouse_event

	var keycode = OS.find_keycode_from_string(bind_string)
	if keycode != 0:
		var key_event = InputEventKey.new()
		key_event.keycode = keycode
		return key_event

	return null

func load_saved_keybind(action_name: String) -> void:
	InputMap.action_erase_events(action_name)
	if not game_data.has(action_name):
		return
	var bind_string = str(game_data[action_name])
	var event = get_input_event_from_string(bind_string)
	if event:
		InputMap.action_add_event(action_name, event)

func load_saved_keybinds() -> void:
	for action_name in ["shoot", "left", "right", "up", "down", "player_jump", "player_sprint", "player_crouch", "reload", "quit"]:
		load_saved_keybind(action_name)
	

func toggle_vsync(value):
	# TODO: apply VSync mode once the correct DisplayServer API is confirmed.
	game_data["Vsync_on"] = value == 1
	save_data()

func update_fov(value):
	#print(game_data["FOV"])
	game_data["FOV"] = value
	#print(game_data["FOV"])
	save_data()

func X_update_mouse_sens(value):
	#print(game_data["X_Mouse_sens_Multi"])
	game_data["X_Mouse_sens_Multi"] = value
	#print(game_data["X_Mouse_sens_Multi"])
	save_data()

func Y_update_mouse_sens(value):
	game_data["Y_Mouse_sens_Multi"] = value
	#print(game_data["Y_Mouse_sens_Multi"])
	save_data()

func Update_Vsync():
	print(game_data["Vsync_on"])
	if game_data["Vsync_on"] == true:
		toggle_vsync(1)
	elif game_data["Vsync_on"] == false:
		toggle_vsync(0)
	save_data()

func Set_Window():
	if game_data["Window_mode"] == "Fullscreen":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,false)
	elif game_data["Window_mode"] == "Windowed":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,false)
	elif game_data["Window_mode"] == "Borderless Fullscreen":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,true)
	elif game_data["Window_mode"] == "Borderless Window":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,true)
	else:
		pass
