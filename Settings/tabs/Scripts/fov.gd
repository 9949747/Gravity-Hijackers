extends Control

@onready var fov_value: Label = $HBoxContainer/FOV_Value

@onready var fov_slider: HSlider = $HBoxContainer/FOVSlider

func _ready():
	fov_slider.value = Save.game_data["FOV"]
	fov_value.text = str(Save.game_data["FOV"])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_fov_slider_value_changed(value):
	Save.update_fov(value)
	fov_value.text = str(value)
