extends Node

const SAVEFILE = "user://Settings.save"

@onready var X_Mouse_sens_Multi = 0.01
@onready var Y_Mouse_sens_Multi = 0.01
@onready var Vsync_mode
@onready var game_data = {}

func _ready():
	load_data()
	X_Mouse_sens_Multi = game_data.X_Mouse_sens_Multi
	Y_Mouse_sens_Multi = game_data.Y_Mouse_sens_Multi

func load_data():
	var file = FileAccess.open(SAVEFILE, FileAccess.READ)
	if not FileAccess.file_exists(SAVEFILE):
		game_data = {
			"Window_mode": "Fullscreen",
			"Vsync_on": false,
			"Display_fps": false,
			"Max_fps": 0,
			"Master_vol": 10,
			"Music_vol": 10,
			"SFX_vol": 10,
			"FOV": 70,
			"X_Mouse_sens_Multi": .01,
			"Y_Mouse_sens_Multi": .01,
		}
		save_data()
	FileAccess.open(SAVEFILE, FileAccess.READ)
	game_data = file.get_var()
	file.close()

func save_data():
	var file = FileAccess.open(SAVEFILE, FileAccess.WRITE)
	file.open(SAVEFILE, file.WRITE)
	file.store_var(game_data)
	file.close()
	

func toggle_vsync(value):
	if value == 1:
		DisplayServer.VSyncMode.VSYNC_ADAPTIVE
	elif value == 0:
		DisplayServer.VSyncMode.VSYNC_DISABLED

func update_fov(value):
	game_data.FOV = value
	print(game_data.FOV)
	save_data()

func X_update_mouse_sens(value):
	X_Mouse_sens_Multi = value
	game_data.X_Mouse_sens_Multi = value
	print(game_data.X_Mouse_sens_Multi)
	save_data()

func Y_update_mouse_sens(value):
	Y_Mouse_sens_Multi = value
	game_data.Y_Mouse_sens_Multi = value
	print(game_data.Y_Mouse_sens_Multi)
	save_data()

func Update_Vsync():
	print(game_data.Vsync_on)
	save_data()
	if game_data.Vsync_on == true:
		toggle_vsync(1)
	elif game_data.Vsync_on == false:
		toggle_vsync(0)
