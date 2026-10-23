extends Node3D


@onready var origin_pickup = $"../Speed_Pickup"
#
@onready var spawn_marker1 = $SpawnPoints/PickupSpawnMarker1
#@onready var spawn_marker2 = $SpawnPoints/PickupSpawnMarker2
#@onready var spawn_marker3 = $SpawnPoints/PickupSpawnMarker3
#
@onready var marker_1_position = spawn_marker1.global_position
#@onready var marker_2_position = spawn_marker2.global_position
#@onready var marker_3_position = spawn_marker3.global_position
#
@onready var PickupSpawnTimer = $PickupSpawnTimer

func _ready() -> void:
	PickupSpawnTimer.timeout.connect(_speed_pickup_timer_timeout)

func _speed_pickup_timer_timeout() -> void:
	var speed_pickup_copy = origin_pickup.duplicate(10)
	#speed_pickup_copy.request_ready()
	#speed_pickup_copy.name = "Speed_Pickup"
	add_child(speed_pickup_copy)
	speed_pickup_copy.global_position = marker_1_position
	#speed_pickup_copy.global_position = marker_2_position
	#speed_pickup_copy.global_position = marker_3_position
