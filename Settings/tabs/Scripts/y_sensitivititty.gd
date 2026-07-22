extends Control

@onready var sens_val: Label = $HBoxContainer/Sens_Val
@onready var ysens_slider: HSlider = $HBoxContainer/ysens_slider


func _ready():
	ysens_slider.value = Save.game_data["Y_Mouse_sens_Multi"]*10
	sens_val.text = str(Save.game_data["Y_Mouse_sens_Multi"]*2000)

func _on_h_slider_value_changed(value: float):
	Save.Y_update_mouse_sens(value/10)
	sens_val.text = str(value*200)
