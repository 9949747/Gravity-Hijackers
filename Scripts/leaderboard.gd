extends Control

@onready var red_team_playerlist = $RedTeam/ScrollContainer/RedPlayerList
@onready var blue_team_playerlist = $BlueTeam/ScrollContainer/BluePlayerList
@onready var red_team_entry = $RedTeam/TeamPanel
@onready var blue_team_entry = $BlueTeam/TeamPanel
@onready var update_timer = $UpdateTimer
@onready var leaderboard_entry_scene = preload("res://scenes/LeaderboardEntry.tscn")

var entry_list = {} # pid keys, leaderboard entry node values
var team_stats_memory = {"red": {}, "blue": {}} # store all participating peers stats so overall team stats dont change when a player leaves

func _ready() -> void:
	get_tree().current_scene.player_added.connect(add_entry)
	multiplayer.peer_disconnected.connect(remove_entry)

func add_entry(peer_id):
	await get_tree().create_timer(1).timeout # temporary solution
	
	var player_node = get_tree().current_scene.get_node_or_null(str(peer_id))
	var leaderboard_entry = leaderboard_entry_scene.instantiate()
	
	leaderboard_entry.name = str(peer_id)
	if player_node.is_in_group("RedTeam"):
		red_team_playerlist.add_child(leaderboard_entry)
	elif player_node.is_in_group("BlueTeam"):
		blue_team_playerlist.add_child(leaderboard_entry)
	
	entry_list[peer_id] = leaderboard_entry
	leaderboard_entry.get_node("Username").text = player_node.username

func remove_entry(peer_id):
	if is_multiplayer_authority(): # only mpauth needs to delete entry since mpspawner syncs the instance
		var player_node = get_tree().current_scene.get_node_or_null(str(peer_id))
		
		# reset kills and deaths for exiting players
		var plr_team
		if player_node.is_in_group("RedTeam"): plr_team = "red"
		elif player_node.is_in_group("BlueTeam"): plr_team = "blue"
		team_stats_memory[plr_team][peer_id]["kills"] = 0
		team_stats_memory[plr_team][peer_id]["deaths"] = 0
		
		entry_list[peer_id].queue_free()
		entry_list.erase(peer_id)

func update_entry(peer_id):
	var player_node = get_tree().current_scene.get_node_or_null(str(peer_id))
	var player_leaderboard_entry = entry_list[peer_id]
	
	player_leaderboard_entry.get_node("Username").text = player_node.username
	player_leaderboard_entry.get_node("Kills").text = str(player_node.kills)
	player_leaderboard_entry.get_node("Deaths").text = str(player_node.deaths)
	player_leaderboard_entry.get_node("KDR").text = "%.2f" % (float(player_node.kills) / float(max(player_node.deaths, 1))) # need to wrap operands as floats otherwise operation returns int for some reason
	player_leaderboard_entry.get_node("Flags").text = str(player_node.flags)

func update_team_entry(team: String):
	var total_kills = 0
	var total_deaths = 0
	var total_kdr = 0
	var total_flags = 0
	
	for players in team_stats_memory[team]:
		total_kills += team_stats_memory[team][players]["kills"]
		total_deaths += team_stats_memory[team][players]["deaths"]
		total_flags += team_stats_memory[team][players]["flags"]
	total_kdr = float(total_kills) / float(max(total_deaths, 1))
	
	var team_entry
	if team == "red": team_entry = red_team_entry
	elif team == "blue": team_entry = blue_team_entry
	
	team_entry.get_node("Kills").text = str(total_kills)
	team_entry.get_node("Deaths").text = str(total_deaths)
	team_entry.get_node("KDR").text = "%.2f" % total_kdr
	team_entry.get_node("Flags").text = str(total_flags)

func update_round_data(peer_id):
	var player_node = get_tree().current_scene.get_node_or_null(str(peer_id))
	
	var plr_team
	if player_node.is_in_group("RedTeam"): plr_team = "red"
	elif player_node.is_in_group("BlueTeam"): plr_team = "blue"
	
	team_stats_memory[plr_team][peer_id] = {
		"kills": player_node.kills,
		"deaths": player_node.deaths,
		"flags": player_node.flags
	}
	
	update_team_entry(plr_team)

func _on_update_timer_timeout() -> void: # polling rate for leaderboard updating
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED or not is_multiplayer_authority(): # prevent unnecessary work on peers
		return
	
	for peer_ids in entry_list:
		update_entry(peer_ids)
		update_round_data(peer_ids)
