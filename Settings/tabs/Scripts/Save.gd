extends Node

const SAVEFILE = "user://SAVEFILE.save"
var game_data = {}

func _ready():
	load_data()
	print(game_data["Resolution"])
	print(game_data["Window_mode"])
	get_window().set_size(game_data["Resolution"] as Vector2i)

func load_data():
	if not FileAccess.file_exists(SAVEFILE):
		game_data = {
			"Resolution": Vector2i(1920, 1080),
			"Window_mode": "Fullscreen",
			"Vsync_on": false,
			"master_volume": 10,
			"SFX_volume": 10,
			"Music_volume": 10,
			"FOV": 75,
			"X_Mouse_sens_Multi": 0.05,
			"Y_Mouse_sens_Multi": 0.05,
		}
		var file = FileAccess.open(SAVEFILE, FileAccess.WRITE)
		file.store_var(game_data)
		print(game_data)
		file.close()
	else:
		var file = FileAccess.open(SAVEFILE, FileAccess.READ)
		game_data = file.get_var()
		file.close()
		
		if game_data == null:
			print("Save file corrupted or empty, creating new data")
			game_data = {
			"Resolution": "1920x1080",
			"Window_mode": false,
			"Vsync_on": false,
			"master_volume": 10,
			"SFX_volume": 10,
			"Music_volume": 10,
			"FOV": 75,
			"X_Mouse_sens_Multi": 0.05,
			"Y_Mouse_sens_Multi": 0.05,
			}
			var new_file = FileAccess.open(SAVEFILE, FileAccess.WRITE)
			new_file.store_var(game_data)
			new_file.close()

func save_data():
	var file = FileAccess.open(SAVEFILE, FileAccess.WRITE)
	file.store_var(game_data)
	file.close()
	

func toggle_vsync(value):
	if value == 1:
		DisplayServer.VSyncMode.VSYNC_ADAPTIVE
	elif value == 0:
		DisplayServer.VSyncMode.VSYNC_DISABLED

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
	save_data()
	if game_data["Vsync_on"] == true:
		toggle_vsync(1)
	elif game_data["Vsync_on"] == false:
		toggle_vsync(0)
