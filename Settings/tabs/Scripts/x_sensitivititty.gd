extends Control

@onready var xsens_slider: HSlider = $HBoxContainer/XsensSlider

@onready var sens_val: Label = $HBoxContainer/Sens_Val

func _ready():
	xsens_slider.value = Save.game_data["X_Mouse_sens_Multi"]*10
	sens_val.text = str(Save.game_data["X_Mouse_sens_Multi"]*2000)


func _on_h_slider_value_changed(value: float):
	Save.X_update_mouse_sens(value/10)
	sens_val.text = str(value*200)
