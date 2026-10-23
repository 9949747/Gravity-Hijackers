@tool
extends Node3D

## applies positive/negative gravity to players who have just spawned on this particular spawnpoint
@export_enum("Positive", "Negative") var initial_gravity: String = "Positive"
enum Teams {RED = 1, BLUE = 2}
@export var spawn_team: Teams = Teams.BLUE:
	set(value):
		spawn_team = value
		update_editor_visual()

func _ready() -> void:
	update_editor_visual()

func update_editor_visual():
	var spawn_color = StandardMaterial3D.new()
	
	match spawn_team:
		Teams.RED:
			name = "RedSpawnPoint"
			spawn_color.albedo_color = Color(1, 0, 0)
			remove_from_group("BlueSpawn")
			add_to_group("RedSpawn")
		Teams.BLUE:
			name = "BlueSpawnPoint"
			spawn_color.albedo_color = Color(0, 0, 1)
			remove_from_group("RedSpawn")
			add_to_group("BlueSpawn")
	
	$Platform.set_surface_override_material(0, spawn_color)

func respawn_player(player: Node3D):
	player.velocity = Vector3.ZERO
	player.global_position = global_position
	if initial_gravity == "Positive":
		player.rotation.z = 0.0 # upright
		player.gravity_direction = 1
		player.global_position += Vector3(0, 1, 0)
	elif initial_gravity == "Negative":
		player.rotation.z = PI # upsidedown
		player.gravity_direction = -1
		player.global_position -= Vector3(0, 1, 0)
