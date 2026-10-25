extends Node

# cache actual Node references (use $ or get_node)
@onready var Pistol_node    := $"../Camera3D/Pistol"
@onready var Gun2_node   := $"../Camera3D/Gun2"
@onready var Doofenshotgun_node   := $"../Camera3D/Doofenshotgun"


# AFTER DEVELOPMENT: change all entries to be 'unlocked': false for the purposes of gameplay
@export var weapons: Array[Dictionary] = [
	{ "name": "Pistol", "unlocked": true },
	{ "name": "Gun2", "unlocked": true },
	{ "name": "Doofenshotgun", "unlocked": true },
]
var weapon_nodes: Array = []

func _ready() -> void:
	# build the nodes array so indexing matches weapons[]
	weapon_nodes = [Pistol_node, Gun2_node, Doofenshotgun_node]
	# optionally include sniper_node where appropriate

# Call this locally when the local player changes weapon
func request_weapon_change(weapon_index: int) -> void:
	if not _valid_index(weapon_index):
		return
	if not _unlocked_weapon(weapon_index):
		return
	# change locally for instant feedback
	_apply_weapon_local(weapon_index)
	# broadcast to other peers (exclude self)
	rpc_id(0, "rpc_apply_weapon", weapon_index)

# The RPC handler run on remote peers
@rpc("any_peer", "reliable")
func rpc_apply_weapon(weapon_index: int) -> void:
	if not _valid_index(weapon_index):
		return
	_apply_weapon_local(weapon_index)
	#print("RPC applied on peer", get_tree().get_multiplayer().get_unique_id(), "weapon", weapon_index)

func _apply_weapon_local(weapon_index: int) -> void:
	# hide all
	for node in weapon_nodes:
		if node:
			node.visible = false
			node.position = Vector3(-0.5, -0.35, -0.7)
	# show the selected one
	var n = weapon_nodes[weapon_index]
	n.visible = true
	if n == Pistol_node:
		n.position = Vector3(0.5, -0.186, -0.5)
	elif n == Gun2_node:
		n.position = Vector3(0.393, -0.516, -0.136)
	elif n == Doofenshotgun_node:
		n.position = Vector3(0.516, -0.338, -0.295)
	Global.currentWeapon = weapons[weapon_index]["name"]
	print("Local weapon set to ", Global.currentWeapon)

func _valid_index(i: int) -> bool:
	return i >= 0 and i < weapon_nodes.size()

func _unlocked_weapon(i):
	# this function will ensure the weapon is actually unlocked before swapping. This is 
	# relevant to the upgrades system which will gradually offer these to the player.
	if weapons[i]["unlocked"] == true:
		#print("index is: " + str(weapons[i]))
		return true

func unlock_weapon(name: String):
	for entry in weapons:
		if entry['name'] == name:
			entry['unlocked'] = true
