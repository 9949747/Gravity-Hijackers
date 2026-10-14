extends Control

@onready var red_team_playerlist = $RedTeam/ScrollContainer/RedPlayerList
@onready var blue_team_playerlist = $BlueTeam/ScrollContainer/BluePlayerList
@onready var leaderboard_entry_scene = preload("res://scenes/LeaderboardEntry.tscn")

var entry_list = {}

func _ready() -> void:
	get_tree().current_scene.player_added.connect(add_entry)
	multiplayer.peer_disconnected.connect(remove_entry)

func add_entry(peer_id):
	await get_tree().create_timer(1).timeout # temporary solution
	
	var player = get_tree().current_scene.get_node_or_null(str(peer_id))
	var leaderboard_entry = leaderboard_entry_scene.instantiate()
	
	leaderboard_entry.name = str(peer_id)
	if player.is_in_group("Team1"):
		red_team_playerlist.add_child(leaderboard_entry)
	elif player.is_in_group("Team2"):
		blue_team_playerlist.add_child(leaderboard_entry)
	
	entry_list[peer_id] = leaderboard_entry
	
	leaderboard_entry.get_node("Username").text = player.username
	leaderboard_entry.get_node("Kills").text = str(player.kills)

func remove_entry(peer_id):
	if is_multiplayer_authority(): # only one client needs to delete entry since mp spawner syncs the instance
		entry_list[peer_id].queue_free()
		entry_list.erase(peer_id)

@rpc("any_peer")
func update_entry(peer_id):
	print("updating entry for %s" % peer_id)
	var player = get_tree().current_scene.get_node_or_null(str(peer_id))
	var player_leaderboard_entry = entry_list[peer_id]
	
	print("player username is %s and they have %s kills" % [player.username, player.kills])
	
	player_leaderboard_entry.get_node("Username").text = player.username
	player_leaderboard_entry.get_node("Kills").text = str(player.kills)

func _process(delta: float) -> void:
	pass
