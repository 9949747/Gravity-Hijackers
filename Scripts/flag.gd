@tool # updates live in editor. note: this script is not synced across clients, all clients run this script.
extends Area3D 

var capturing_player_node: Node3D # the player who is currently capturing this flag

enum Teams {RED = 1, BLUE = 2}
@export var flag_team: Teams = Teams.RED:
	set(value):
		flag_team = value
		update_editor_visual()

func _ready():
	multiplayer.peer_connected.connect(load_capturing_player_node)

func load_capturing_player_node(peer_id):
	if not is_multiplayer_authority(): return
	if capturing_player_node:
		pick_up_flag.rpc_id(peer_id, null, get_path_to(capturing_player_node))

func update_editor_visual():
	var flag_color = StandardMaterial3D.new()
	flag_color.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	match flag_team:
		Teams.RED:
			flag_color.albedo_color = Color(1, 0, 0)
			$FlagIcon.modulate = Color(1, 0, 0)
		Teams.BLUE:
			flag_color.albedo_color = Color(0, 0, 1)
			$FlagIcon.modulate = Color(0, 0, 1)
	
	$FlagMesh.set_surface_override_material(0, flag_color)

@rpc("any_peer", "call_local") # rpc called by client who dies with a flag
func return_flag():
	if not capturing_player_node: return # ensure new players dont try access capturing_player_node
	
	show()
	capturing_player_node.get_node("Flag").hide()
	capturing_player_node.current_held_flag = null
	capturing_player_node = null

func secure_captured_flag(player: Node3D):
	if not player.current_held_flag: return # player must have a flag to secure it
	
	player.flags += 1 # only capturing player has auth over flags val
	player.current_held_flag.return_flag()

@rpc
func pick_up_flag(player: Node3D, player_path: NodePath = ""):
	if player_path: player = get_node(player_path) # only necessary when syncing flag states to new players
	
	if player.current_held_flag: return # player cant pick up more than one flag. also allow all peers to proceed below so capturing player knows what flag they're holding
	
	hide()
	player.current_held_flag = self
	capturing_player_node = player
	if not player.is_multiplayer_authority(): # only allow other peers to see flag indication
		player.get_node("Flag").show()

func _on_body_entered(body: Node3D): # let host handle all body entered signals
	if capturing_player_node: return # cant secure a flag if local flag is captured, also cant pick up a flag that has already been picked up
	
	match flag_team:
		Teams.RED:
			if body.is_in_group("BlueTeam"): pick_up_flag(body)
			elif body.is_in_group("RedTeam"): secure_captured_flag(body)
		Teams.BLUE:
			if body.is_in_group("RedTeam"): pick_up_flag(body)
			elif body.is_in_group("BlueTeam"): secure_captured_flag(body)
