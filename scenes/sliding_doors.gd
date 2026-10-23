extends Node3D
@onready var left_door = $left
@onready var right_door = $right
@onready var player_detector = $Area3D
var players_in_range = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if players_in_range.size() > 0:
		print(players_in_range)
		left_door.position = lerp(left_door.position, Vector3(-3, 2, 0), 0.1)
		right_door.position = lerp(right_door.position, Vector3(3, 2, 0), 0.1)
	else:
		left_door.position = lerp(left_door.position, Vector3(-1, 2, 0), 0.1)
		right_door.position = lerp(right_door.position, Vector3(1, 2, 0), 0.1)


func _on_area_3d_body_entered(body) -> void:
	if body.is_in_group("Player"):
		print(body.name + " entered")
		players_in_range[body] = body

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		players_in_range.erase(body)
		print(body.name + " exited")
