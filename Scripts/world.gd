extends Node
# Ough.,,

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var hud = $CanvasLayer/HUD
@onready var health_bar = $CanvasLayer/HUD/HealthBar
# @onready var radio = $CanvasLayer/Radio
var world_gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
#var default_gravity_3d
#func grav_shift():
	#if is_on_floor():
		#world_gravity = 0

@onready var playerScene = preload("res://scenes/player.tscn")

var tracked = false
var player

const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

func _ready() -> void:
	#$AudioStreamPlayer.play()
	Global.worldNode = self
	print(Save.game_data)

func _on_host_button_pressed():
	main_menu.hide()
	hud.show()
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())
	
	#upnp_setup()
func _on_join_button_pressed():
	main_menu.hide()
	hud.show()
	
	enet_peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer

func _on_multiplayer_spawner_spawned(node):
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)

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

func _on_single_player_button_pressed():
	main_menu.hide()
	hud.show()
	#multiplayer.multiplayer_peer = enet_peer
	add_player(multiplayer.get_unique_id())


func add_player(peer_id):
	player = playerScene.instantiate()
	player.name = str(peer_id)
	add_child(player)
	tracked = true
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)
	
	var group_counts = {get_tree().get_node_count_in_group("Team1"): "Team1", get_tree().get_node_count_in_group("Team2"): "Team2"} # team 2 will override team 1 when both are even since keys match
	var smallest_team = group_counts[min(get_tree().get_node_count_in_group("Team1"), get_tree().get_node_count_in_group("Team2"))] if len(group_counts) > 1 else ["Team1", "Team2"].pick_random() # removes bias to one team when both teams are even
	apply_team(peer_id, smallest_team) # host must skip straight to apply_team since they need to add the peer to their group so others can replicate
	filter_loaded_players.rpc(get_tree().get_nodes_in_group("Team1").map(func(node): return node.name), get_tree().get_nodes_in_group("Team2").map(func(node): return node.name)) # converts nodes in each team to peer ids before sending rpc
	
	# gets synced via mp synchronizer node
	$CanvasLayer/HUD/Team1.text = "Team1: " + str(get_tree().get_node_count_in_group("Team1")) + " players"
	$CanvasLayer/HUD/Team2.text = "Team2: " + str(get_tree().get_node_count_in_group("Team2")) + " players"

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if not player:
		return
	
	player.queue_free()
	await get_tree().create_timer(0.1).timeout # breifly pause thread so print statement below returns accurate info
	$CanvasLayer/HUD/Team1.text = "Team1: " + str(get_tree().get_node_count_in_group("Team1")) + " players"
	$CanvasLayer/HUD/Team2.text = "Team2: " + str(get_tree().get_node_count_in_group("Team2")) + " players"

@rpc
func filter_loaded_players(team1, team2):
	# filter out players who are already loaded locally (sorry for the lambda slop)
	var unloaded_team1_players = team1.filter(func(id): return not get_tree().get_nodes_in_group("Team1").map(func(node): return node.name).has(id))
	var unloaded_team2_players = team2.filter(func(id): return not get_tree().get_nodes_in_group("Team2").map(func(node): return node.name).has(id))
	print("unloaded team 1 players: ", unloaded_team1_players, " unloaded team 2 players: ", unloaded_team2_players, " on client: ", multiplayer.get_unique_id())
	
	for ids in unloaded_team1_players:
		apply_team(ids, "Team1")
	for ids in unloaded_team2_players:
		apply_team(ids, "Team2")

func apply_team(plr_id, team): # keeps filter_loaded_players relatively dry and resolves host group conflict
	var player_node = get_node(str(plr_id))
	var plr_mat = player_node.get_node("MeshInstance3D").get_active_material(0).duplicate()
	plr_mat.albedo_color = Color(1, 0, 0) if team == "Team1" else Color(0, 0, 1)
	player_node.get_node("MeshInstance3D").set_surface_override_material(0, plr_mat)
	player_node.add_to_group(team)

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
