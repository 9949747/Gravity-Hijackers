extends Node

signal player_added(peer_id)

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var username_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/UsernameEntry
@onready var hud = $CanvasLayer/HUD
@onready var leaderboard = $CanvasLayer/Leaderboard
@onready var team1_playerlist = $CanvasLayer/Leaderboard/RedTeam/ScrollContainer/RedPlayerList
@onready var team2_playerlist = $CanvasLayer/Leaderboard/BlueTeam/ScrollContainer/BluePlayerList
@onready var health_bar = $CanvasLayer/HUD/HealthBar
# @onready var radio = $CanvasLayer/Radio
var world_gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var playerScene = preload("res://scenes/player.tscn")
@onready var leaderboard_entry_scene = preload("res://scenes/LeaderboardEntry.tscn")

var tracked = false
var player
var connected_player_ids = []

const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

func _ready() -> void:
	#$AudioStreamPlayer.play()
	Global.worldNode = self
	#print(Save.game_data)

func _on_host_button_pressed():
	if not username_entry.text:
		username_entry.placeholder_text = "Enter a username before joining/hosting"
		return
	
	main_menu.hide()
	hud.show()
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())
	
	#upnp_setup()
func _on_join_button_pressed():
	if not username_entry.text:
		username_entry.placeholder_text = "Enter a username before joining/hosting"
		return
	
	main_menu.hide()
	hud.show()
	
	enet_peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer

func _on_multiplayer_spawner_spawned(node):
	if node.is_multiplayer_authority():
		pass
		#node.health_changed.connect(update_health_bar)

func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP Discover Failed! Error %s" % discover_result)

	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), "UPNP Invalid Gateway!")

	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Success! Join Address: %s" % upnp.query_external_address())

func _physics_process(delta):
	if tracked and player:
		get_tree().call_group("enemy", "update_target_location", player.global_transform.origin)

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func add_player(peer_id):
	player = playerScene.instantiate()
	player.name = str(peer_id)
	add_child(player)
	tracked = true
	if player.is_multiplayer_authority():
		pass
		#player.health_changed.connect(update_health_bar)
	
	var group_counts = {get_tree().get_node_count_in_group("Team1"): "Team1", get_tree().get_node_count_in_group("Team2"): "Team2"} # team 2 will override team 1 when both are even since keys match
	var smallest_team = group_counts[min(get_tree().get_node_count_in_group("Team1"), get_tree().get_node_count_in_group("Team2"))] if len(group_counts) > 1 else ["Team1", "Team2"].pick_random() # removes bias to one team when both teams are even

	update_player_data(peer_id, {"groups": [smallest_team]}) # load new player on host
	update_player_data.rpc(peer_id, {"groups": [smallest_team]}) # load new player on peers
	for connected_players in connected_player_ids: # load existing players on new peer
		update_player_data.rpc_id(peer_id, connected_players, get_player_data(connected_players))
	connected_player_ids.append(peer_id)
	
	player_added.emit(peer_id) # currently only used by leaderboard.gd

func remove_player(peer_id):
	var exiting_player = get_node_or_null(str(peer_id))
	if not exiting_player:
		return
	
	exiting_player.queue_free()

func get_player_data(peer_id):
	var player_node = get_node_or_null(str(peer_id))
	if not player_node:
		return

	return {"groups": player_node.get_groups()}

@rpc
func update_player_data(peer_id, data):
	var player_node = get_node_or_null(str(peer_id))
	if not player_node:
		return
	
	for group in data.groups:
		player_node.add_to_group(group)

	# inits
	var plr_mat = player_node.get_node("MeshInstance3D").get_active_material(0).duplicate()
	if player_node.is_in_group("Team1"):
		plr_mat.albedo_color = Color(1, 0, 0)
	elif player_node.is_in_group("Team2"):
		plr_mat.albedo_color = Color(0, 0, 1)
	else:
		print("player %s has not been assigned a team" % peer_id)
	
	player_node.get_node("MeshInstance3D").set_surface_override_material(0, plr_mat)

@rpc
func remove_player_data(peer_id):
	pass

func update_health_bar(health_value):
	health_bar.value = health_value

'''
func radio_enable(event: InputEvent) -> void:
	print("1")
	if event.is_action_just_pressed("radio_toggle"):
		if radio.visible == false:
			radio.show()
			radio.visible = true
		else:
			radio.hide()
			radio.visible = false
'''
func _on_button_pressed():
	get_tree().change_scene_to_file("res://Settings/SettingsMenu.tscn")
