@tool
extends CharacterBody3D

func _physics_process(delta: float) -> void:
	rotate_z(PI/180)
	move_and_slide()
