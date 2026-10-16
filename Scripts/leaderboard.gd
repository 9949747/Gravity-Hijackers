extends Control

@onready var red_team_playerlist = $RedTeam/ScrollContainer/RedPlayerList
@onready var blue_team_playerlist = $BlueTeam/ScrollContainer/BluePlayerList
@onready var red_team_entry = $RedTeam/TeamPanel
@onready var blue_team_entry = $BlueTeam/TeamPanel
@onready var update_timer = $UpdateTimer
@onready var leaderboard_entry_scene = preload("res://scenes/LeaderboardEntry.tscn")

var entry_list = {} # pid keys, leaderboard entry node values
var team_stat_mem = {"red": {}, "blue": {}}: # store all participating peers stats so overall team stats dont change when a player leaves
	set(value):
		if value != team_stat_mem:
			team_stat_mem = value
			update_team_entry("red")
			update_team_entry("blue")

func _ready() -> void:
	get_tree().current_scene.player_added.connect(add_entry)
	multiplayer.peer_disconnected.connect(remove_entry)

func add_entry(peer_id):
	await get_tree().create_timer(1).timeout # temporary solution
	
	var player_node = get_tree().current_scene.get_node_or_null(str(peer_id))
	var leaderboard_entry = leaderboard_entry_scene.instantiate()
	
	leaderboard_entry.name = str(peer_id)
	if player_node.is_in_group("Team1"):
		red_team_playerlist.add_child(leaderboard_entry)
	elif player_node.is_in_group("Team2"):
		blue_team_playerlist.add_child(leaderboard_entry)
	
	entry_list[peer_id] = leaderboard_entry
	leaderboard_entry.get_node("Username").text = player_node.username

func remove_entry(peer_id):
	if is_multiplayer_authority(): # only mpauth needs to delete entry since mpspawner syncs the instance
		entry_list[peer_id].queue_free()
		entry_list.erase(peer_id)

func update_entry(peer_id):
	var player_node = get_tree().current_scene.get_node_or_null(str(peer_id))
	var player_leaderboard_entry = entry_list[peer_id]
	
	player_leaderboard_entry.get_node("Username").text = player_node.username
	player_leaderboard_entry.get_node("Kills").text = str(player_node.kills)
	player_leaderboard_entry.get_node("Deaths").text = str(player_node.deaths)
	player_leaderboard_entry.get_node("KDR").text = str(player_node.kills / player_node.deaths if player_node.deaths != 0 else 0)
	player_leaderboard_entry.get_node("Flags").text = str(player_node.flags)

func update_team_entry(team: String):
	var team_stats = {"total_kills": 0, "total_deaths": 0, "total_kdr": 0, "total_flags": 0}
	
	for players in team_stat_mem[team]:
		team_stats["total_kills"] += team_stat_mem[team][players]["kills"]
		team_stats["total_deaths"] += team_stat_mem[team][players]["deaths"]
		team_stats["total_flags"] += team_stat_mem[team][players]["flags"]
	team_stats["total_kdr"] = team_stats["total_kills"] / team_stats["total_deaths"] if team_stats["total_deaths"] != 0 else 0
	
	if team == "red":
		red_team_entry.get_node("Kills").text = team_stats["total_kills"]
		red_team_entry.get_node("Deaths").text = team_stats["total_deaths"]
		red_team_entry.get_node("KDR").text = team_stats["total_kdr"]
		red_team_entry.get_node("Flags").text = team_stats["total_flags"]
	elif team == "blue":
		blue_team_entry.get_node("Kills").text = team_stats["total_kills"]
		blue_team_entry.get_node("Deaths").text = team_stats["total_deaths"]
		blue_team_entry.get_node("KDR").text = team_stats["total_kdr"]
		blue_team_entry.get_node("Flags").text = team_stats["total_flags"]

func update_round_data(peer_id):
	var player_node = get_tree().current_scene.get_node_or_null(str(peer_id))
	
	if player_node.is_in_group("Team1"):
		team_stat_mem["red"][peer_id] = {
			"kills": player_node.kills,
			"deaths": player_node.deaths,
			"flags": player_node.flags
			}
	elif player_node.is_in_group("Team2"):
		team_stat_mem["blue"][peer_id] = {
			"kills": player_node.kills,
			"deaths": player_node.deaths,
			"flags": player_node.flags
			}

func _on_update_timer_timeout() -> void: # polling rate for leaderboard updating
	if not is_multiplayer_authority() or not get_tree().get_multiplayer(): # prevent unnecessary work on peers
		return
	
	for peer_ids in entry_list:
		update_entry(peer_ids)
		update_round_data(peer_ids)
