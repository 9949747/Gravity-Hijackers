extends Control

var Vsync_disabled = "Vsync: Disabled"
var Vsync_enabled = "Vsync: Enabled"
@onready var label: Label = $HBoxContainer/Label
@onready var Vsync = 0

func _onVsyncBtn_toggled(button_pressed):
	Save.toggle_vsync(button_pressed)

func _on_X_MouseSens_value_changed(value):
	Save.X_update_mouse_sens(value)

func _on_Y_MouseSens_value_changed(value):
	Save.Y_update_mouse_sens(value)

func _on_check_button_toggled(toggled_on: bool):
	if Save.game_data.Vsync_on == false:
		Save.game_data.Vsync_on = true
		Save.Update_Vsync()
		label.text = Vsync_enabled
	elif Save.game_data.Vsync_on == true:
		Save.game_data.Vsync_on = false
		Save.Update_Vsync()
		label.text = Vsync_disabled
