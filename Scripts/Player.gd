extends CharacterBody3D

#Assets
@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var flip_anim_player = $FlipAnimationPlayer
@onready var muzzle_flash = $Camera3D/Pistol/MuzzleFlash
@onready var raycast = $Camera3D/RayCast3D
@onready var camera_3d: Camera3D = $Camera3D
@onready var hud = Global.worldNode.hud
@onready var crosshair = hud.get_node("Crosshair")
@onready var ammo_display = hud.get_node("AmmoDisplay")
@onready var grav_slider = hud.get_node("GravitySlider")
@onready var flip_cd_label = hud.get_node("FlipCooldownLabel")
@onready var spawn_immunity_label = hud.get_node("SpawnImmunityLabel")
@onready var health_bar: ProgressBar = Global.worldNode.health_bar
@onready var grav_flip_timer = $GravFlipTimer
@onready var weaponsManager = $weaponsManager
@onready var SpeedPickupTimer = $SpeedPickupTimer

@onready var leaderboard = Global.worldNode.leaderboard
@onready var esc_menu = Global.worldNode.esc_menu

#Preloads
@onready var damage_billboard = preload("res://scenes/DamageIndicator.tscn")
@onready var hit_marker = preload("res://scenes/HitMarker.tscn")
@onready var player_scene = preload("res://scenes/player.tscn")
@onready var world_scene = preload("res://scenes/environment.tscn")
@onready var speed_pickup_scene = preload("res://scenes/speed_pickup.tscn")

#Pickups
@onready var default_gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var speed_pickups = get_tree().get_nodes_in_group("speed_pickups")
#speed_pickup_scene_instantiated = get_tree().get_nodes_in_group("speed_pickups")
#get_parent().get_node("Speed_Pickup")
@onready var speed_pickup_multiplier = 1

#Crouching
@export var ANIMATIONPLAYER : AnimationPlayer
@export var CROUCH_SPEED : float = 0
@export var is_crouching: bool = false

#Instantiation
@onready var player_scene_instantiated = player_scene.instantiate()
@onready var world_scene_instantiated = world_scene.instantiate()

#Guns
var pistol_ammo_count = 15
var perry_ammo_count = 30
var shotgun_ammo_count = 5
var next_shot_time = 0.0
var FIRE_RATE = 0.4

#Stats
var bullet_damage = 2
var SPEED = 5.5
var JUMP_VELOCITY = 10
var gravity_strengths = [3, 1.5, 0.75, 0.375]
var knockback_strength = 12
const max_health = 20
@export var health = max_health

#Leaderboard Stats
@export var username = "Default" # username is set in func _ready()
@export var kills = 0
@export var deaths = 0
@export var flags = 0

#MISC
@export var X_mouse_sensitivity = 0.01
@export var Y_mouse_sensitivity = 0.01
var current_held_flag: Node3D

var reloading = false
const LOOK_SPEED = 5 #Existed since the begginning, Charles is scared to remove it

func _enter_tree(): #Starts the game, gives multiplayer authority for your controls
	set_multiplayer_authority(str(name).to_int())

func _ready(): #Plays on first entering the game
	for pickup in speed_pickups:
		pickup.speed_pickup_pickedup.connect(_on_speed_pickup_pickedup)
	if not is_multiplayer_authority(): return
	
	SpeedPickupTimer.timeout.connect(_speed_pickup_timer_timeout)
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED #Allows you to move camera
	camera.current = true
	
	if weaponsManager and is_multiplayer_authority():
		weaponsManager.request_weapon_change(0)
	username = Global.worldNode.username_entry.text
	$UsernameLabel.text = username
	$UsernameLabel.hide() # hide locally
	
	health_bar.max_value = max_health
	health_bar.value = max_health

func _exit_tree() -> void: #for when you leave the actual game for the main menu
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED: #Allows you to move mouse in game
		rotate_object_local(Vector3.UP, -event.relative.x * X_mouse_sensitivity) # left right
		camera.rotate_object_local(Vector3.RIGHT, -event.relative.y * Y_mouse_sensitivity) # up down
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	if Input.is_action_pressed("unlock_cursor"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif not esc_menu.visible:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if Input.is_action_just_pressed("toggle_leaderboard") and not esc_menu.visible:
		if leaderboard.visible:
			leaderboard.hide()
		else:
			leaderboard.show()
	
	if Input.is_action_just_pressed("quit"):
		if esc_menu.visible:
			esc_menu.hide()
			hud.show()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			esc_menu.show()
			leaderboard.hide()
			hud.hide()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if event.is_pressed() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED: # check if pressed so scrolls dont fire twice. also prevent grav raising/lowering when scrolling in leaderboard
		if Input.is_action_just_pressed("decrease_gravity") and event.is_pressed(): 
			grav_slider.value -= 1
		
		if Input.is_action_just_pressed("increase_gravity") and event.is_pressed():
			grav_slider.value += 1
	
	if Input.is_action_just_pressed("reload") and !reloading and anim_player.current_animation != "shoot":
		upd_ammo(0, true) # call reload update
	
	#ALL SHOOTING STUFF, IT WORKS, DO NOT CHANGE IT UNLESS RHYS
	if Input.is_action_just_pressed("shoot") and anim_player.current_animation != "shoot" and anim_player.current_animation != "shoot2" and anim_player.current_animation != "shoot3":
		if Global.currentWeapon == "Pistol" and pistol_ammo_count > 0 or Global.currentWeapon == "Gun2" and perry_ammo_count > 0 or Global.currentWeapon == "Doofenshotgun" and shotgun_ammo_count > 0:
			var now = Time.get_ticks_msec() / 1000.0
			if now >= next_shot_time:
				next_shot_time = now + FIRE_RATE
				upd_ammo(-1)
				play_shoot_effects.rpc()
				
				if not raycast.is_colliding():
					return
				
				var hit_obj = raycast.get_collider()
				var hit_coords = raycast.get_collision_point()
				var hit_direction = (hit_coords - raycast.global_position).normalized()
				var relative_hit_coords = hit_coords - hit_obj.position # relative to the colliding object
				var headshot = true if relative_hit_coords.y >= 1.4 else false # above 1.4 is roughly where the player's head is
				
				# avoids nesting, also prevents friendly fire
				if !hit_obj.is_in_group("Player") or (is_in_group("RedTeam") and hit_obj.is_in_group("RedTeam")) or (is_in_group("BlueTeam") and hit_obj.is_in_group("BlueTeam")):
					return
				
				# instance new clientside hitmarker gui
				var new_hit_marker = hit_marker.instantiate()
				Global.worldNode.get_node("CanvasLayer/HUD").add_child(new_hit_marker)
				new_hit_marker.position = Vector2(crosshair.position.x - (new_hit_marker.size.x / 2), crosshair.position.y - (new_hit_marker.size.y / 2))
				new_hit_marker.scale = Vector2(0.5, 0.5)
				
				# instance new damage count billboard gui where ray collides
				var new_damage_billboard = damage_billboard.instantiate()
				var billboard_label = new_damage_billboard.get_node("Label3D") 
				Global.worldNode.add_child(new_damage_billboard)
				new_damage_billboard.position = Vector3(hit_coords)
				if headshot:
					billboard_label.text = str(-bullet_damage*2)
					billboard_label.modulate = Color("e10006")
					billboard_label.outline_modulate = Color("400000")
				else: 
					billboard_label.text = str(-bullet_damage)
				
				# damage player
				if hit_obj in get_tree().get_nodes_in_group("Player"):
					var damage = bullet_damage*2 if headshot else bullet_damage
					if hit_obj.health - damage <= 0: 
						kills += 1
					hit_obj.receive_damage.rpc_id(hit_obj.get_multiplayer_authority(), damage, multiplayer.get_unique_id(), hit_direction)

func _physics_process(delta): #Occurs every delta frame
	#speed_pickup_scene_instantiated = speed_pickup_scene.instantiate
	#get_parent().get_node("Speed_Pickup") #Speed Changing, WIP: TALK TO JAYDAN
	if not is_multiplayer_authority(): return
	
	
	# Get the input direction and handle the movement/deceleration.
	#MOVEMENT AND CONTROLS
	move_and_slide()
	
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var dir_change_strength = SPEED if is_on_floor() else 10 * gravity_strengths[int(grav_slider.value)] * delta
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * SPEED, dir_change_strength)
		velocity.z = move_toward(velocity.z, direction.z * SPEED, dir_change_strength)
	else:
		velocity.x = move_toward(velocity.x, 0, dir_change_strength)
		velocity.z = move_toward(velocity.z, 0, dir_change_strength)
	
	#JUMPING AND GRAVITY
	if Input.is_action_just_pressed("flip_gravity") and grav_flip_timer.time_left == 0:
		if up_direction.y == -1: flip_anim_player.play("flip_upright")
		elif up_direction.y == 1: flip_anim_player.play("flip_upsidedown")
		
		up_direction.y = -up_direction.y # turns the ceiling into the floor/floor into the ceiling
		grav_flip_timer.start()
	
	rotation.x = 0 # this stops flipping from breaking if the player turns their camera mid animation
	if grav_flip_timer.time_left == 0:
		flip_cd_label.text = ""
	else:
		flip_cd_label.text = "CD %.2fs" % grav_flip_timer.time_left
	
	if not is_on_floor(): # gravity
		velocity.y -= default_gravity * up_direction.y * gravity_strengths[int(grav_slider.value)] * delta
	
	if Input.is_action_pressed("player_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY * up_direction.y

	#SPRINTING AND CROUCHING
	if Input.is_action_pressed("player_sprint"):
		SPEED = 8 * speed_pickup_multiplier
	else:
		SPEED = 5.5 * speed_pickup_multiplier
	
	if Input.is_action_just_pressed("player_crouch"):
		if !is_multiplayer_authority():
			return
		crouch.rpc()
	
	if Input.is_action_just_pressed("equip_perry"):
		weaponsManager.request_weapon_change(1)
		bullet_damage = 1
		FIRE_RATE = 0.1
		ammo_display.text = "%d / 30" % perry_ammo_count
	if Input.is_action_just_pressed("equip_shotgun"):
		weaponsManager.request_weapon_change(2)
		bullet_damage = 6
		FIRE_RATE = 0.8
		ammo_display.text = "%d / 5" % shotgun_ammo_count
	if Input.is_action_just_pressed("equip_pistol"):
		weaponsManager.request_weapon_change(0)
		bullet_damage = 2
		FIRE_RATE = 0.4
		ammo_display.text = "%d / 15" % pistol_ammo_count

	# THIS WAS DONE AT THE TEMPLATE AND CHARLES IS TOO SCARED TO REMOVE IT
	var look_dir = Input.get_vector("look_left", "look_right", "look_up", "look_down") # SUPPOSED CONTROLLER SENSITIVITY STUFF
	if look_dir != Vector2.ZERO:
		# Rotate Player (Yaw) - Horizontal movement of the stick
		rotate_y(-look_dir.x * LOOK_SPEED * delta)
		
		# Rotate Camera (Pitch) - Vertical movement of the stick
		camera.rotate_x(-look_dir.y * LOOK_SPEED * delta)
		
		# Clamp camera pitch rotation (same as your mouse look code)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

	#Settings stuff
	_on_fov_updated(Save.game_data["FOV"])
	_X_on_mouse_sens_updated(Save.game_data["X_Mouse_sens_Multi"])
	_Y_on_mouse_sens_updated(Save.game_data["Y_Mouse_sens_Multi"])
	
	#Shoot animation
	if anim_player.is_playing() and anim_player.current_animation in ["shoot", "shoot2", "shoot3", "Reload", "Crouch", "Uncrouch"]:
		pass
	else:
		anim_player.play("idle")
	
	var health_color = StyleBoxFlat.new()
	if $SpawnImmunityTimer.time_left == 0:
		spawn_immunity_label.text = ""
		health_color.bg_color = Color(0, 1, 0)
	else:
		spawn_immunity_label.text = "Protected %.2fs" % $SpawnImmunityTimer.time_left
		health_color.bg_color = Color(0, 1, 1)
	health_bar.add_theme_stylebox_override("fill", health_color)

	if input_dir != Vector2.ZERO and is_on_floor():
		anim_player.play("move")
	else:
		anim_player.play("idle")

#ANIMATION FUNCTIONS
@rpc("call_local")
func crouch():
	#print(is_crouching)
	#print($".".name)
	if is_crouching == true:
		#print("Crouch2")
		anim_player.play("Uncrouch")
		is_crouching = false

	elif is_crouching == false:
		#print("Crouch1")
		anim_player.play("Crouch")
		is_crouching = true

@rpc("any_peer")
func receive_damage(damage, from_peer_id, hit_direction):
	if $SpawnImmunityTimer.time_left > 0: return
	
	velocity = hit_direction * knockback_strength
	health -= damage
	if health <= 0:
		deaths += 1
		health = max_health
		if is_in_group("RedTeam"): get_tree().get_nodes_in_group("RedSpawn").pick_random().spawn_player(self)
		elif is_in_group("BlueTeam"): get_tree().get_nodes_in_group("BlueSpawn").pick_random().spawn_player(self)
		$SpawnImmunityTimer.start()
		if current_held_flag:
			current_held_flag.return_flag.rpc()
	health_bar.value = health

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot" or anim_name == "shoot2" or anim_name == "shoot3":
		anim_player.play("idle")
		
#MULTIPLAYER STUFF
@rpc("call_local")
func play_shoot_effects():
	anim_player.stop()
	if Global.currentWeapon == "Pistol":
		anim_player.play("shoot")
	elif Global.currentWeapon == "Gun2":
		anim_player.play("shoot2")
	elif Global.currentWeapon == "Doofenshotgun":
		anim_player.play("shoot3")
	$AudioStreamPlayer3D.play()
	muzzle_flash.restart()
	muzzle_flash.emitting = true

#SETTINGS FUNCTIONS
func _on_fov_updated(value):
	if not is_multiplayer_authority(): return
	#print(Save.game_data["FOV"])
	camera.fov = value
func _X_on_mouse_sens_updated(value):
	if not is_multiplayer_authority(): return
	X_mouse_sensitivity = value
func _Y_on_mouse_sens_updated(value):
	if not is_multiplayer_authority(): return
	Y_mouse_sensitivity = value

#MISCELLANEOUS
func upd_ammo(num: int, reload: bool = false):
	if reload:
		reloading = true
		anim_player.play("Reload")
		crosshair.hide()
		await get_tree().create_timer(1).timeout
		crosshair.show()
		if Global.currentWeapon == "Pistol":
			pistol_ammo_count = 15
		elif Global.currentWeapon == "Gun2":
			perry_ammo_count = 30
		elif Global.currentWeapon == "Doofenshotgun":
			shotgun_ammo_count = 5
		reloading = false
	else:
		if Global.currentWeapon == "Pistol":
			pistol_ammo_count += num
		elif Global.currentWeapon == "Gun2":
			perry_ammo_count += num
		elif Global.currentWeapon == "Doofenshotgun":
			shotgun_ammo_count += num
		if Global.currentWeapon == "Pistol":
			ammo_display.text = "%d / 15" % pistol_ammo_count
		elif Global.currentWeapon == "Gun2":
			ammo_display.text = "%d / 30" % perry_ammo_count
		elif Global.currentWeapon == "Doofenshotgun":
			ammo_display.text = "%d / 5" % shotgun_ammo_count
	

@rpc("call_local")
func _on_speed_pickup_pickedup(value):
	print("SPEED_PICKUP")
	speed_pickup_multiplier = value
	SpeedPickupTimer.start()

func _speed_pickup_multiplier_changed() -> void:
	if speed_pickup_multiplier == 1:
		pass
	else:
		SpeedPickupTimer.start()

func _speed_pickup_timer_timeout() -> void:
	print("Speed pickup timed out.")
	speed_pickup_multiplier = 1
