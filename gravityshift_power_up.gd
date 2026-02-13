extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass





func _on_area_3d_body_entered(body: Node3D) -> void:
	if (body.name == "Player"):
		var player_node = get_node("/root/player/Player")

#get_tree().current_scene.get_node("Player")
		print(player_node.name)
		Player.gravity_scale = 0.2
		queue_free()

#physics/3d/default_gravity
