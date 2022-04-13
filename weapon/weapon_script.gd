extends Node3D
#Lakamfo MIT LICENSE 2022

class_name Weapon_Base

#Base stats
#enum _weapon_type {Shotgun,Auto_Rifle,Sniper_Rifle,Pistol}
enum _weapon_type {Pistol}
enum  _fire_mode {None,Semi,Auto,Burst}
@export var fire_mode = _fire_mode
@export var damage :int = 30
@export var firerate :int = 200
@export var magazine_size :int = 30
@export var ammo_size :int = 300
@export var burst_size :int = 3
@export var head_multiplayer :float = 1.50
@export var torso_multiplayer :float = 1

#accuracy
@export var min_camera_kick :Vector3 = Vector3()
@export var max_camera_kick :Vector3 = Vector3()

@export var spread_factor : float = 0.5
@export var recovery_speed : float = 1
@export var spread_damping : float = 1

@export var hipfire_camera_recovery_speed : float = 1
@export var sight_camera_recovery_speed : float = 1
@export var sight_accuracy_mult: float = 0.7


#Weapon handling
@export var equip_speed :float = 1
@export var aiming_speed : float = 1
@export var crosshair_size : float = 1

#Mis 
@export var weapon_walkspeed :float = 1
@export var aiming_walkspeed :float = 1
@export var round_in_chamber :int = 1

#Nodes
@export_node_path(AnimatedSprite3D) var muzzle_flash_sprite
@export_node_path(OmniLight3D) var muzzle_flash_light
@export_node_path(AnimationPlayer) var animation_player
@export var animations_fire : String = "fire_1,fire_2" 
@export var animations_reload : String = "reload_1,reload_2" 
@export var animations_reload_empty_mag : String = "empty_reload_1"
@export_node_path(Position3D) var shell_drop_position
@export_node_path(RayCast3D) var raycast
@export_node_path(Node3D) var camera_joint

#other
@export var interact_in_group = "weapon_interact"
@export var interact_method = "get_hit"

#Internal script variables
var current_magazine_size = magazine_size
var fire_rate_seconds
var camera_tween : Tween
var timer = Timer.new()
var non_stop_counter = 0
var is_reloading = false
var in_sight = false
var recoil_recovery_speed = 1

func _ready():
	randomize()
	fire_rate_seconds = 60.0 / firerate
	timer.one_shot = true
	
	add_child(timer)
	camera_tween = create_tween()
	if animation_player:animation_player = get_node_or_null(animation_player)
	if camera_joint:camera_joint = get_node_or_null(camera_joint)
	if muzzle_flash_sprite:muzzle_flash_sprite = get_node_or_null(muzzle_flash_sprite)
	if muzzle_flash_light:muzzle_flash_light = get_node_or_null(muzzle_flash_light)
	if raycast:raycast = get_node_or_null(raycast)
	if shell_drop_position:shell_drop_position = get_node_or_null(shell_drop_position)
	
	animation_player.animation_finished.connect(_animation_finished)
	timer.timeout.connect(_counter)

func _process(_delta):
	if timer.is_stopped() and not is_reloading:
		if fire_mode == 1 and Input.is_action_just_pressed("mouse_1"):
			_fire(false)
		elif fire_mode == 2 and Input.is_action_pressed("mouse_1"):
			_fire(false)
		elif fire_mode == 3 and Input.is_action_just_pressed("mouse_1"):
			_fire(true)
		
		if Input.is_action_pressed("mouse_2"):
			in_sight = true
			recoil_recovery_speed = sight_camera_recovery_speed
		else:
			in_sight = false
			recoil_recovery_speed = hipfire_camera_recovery_speed
		
		if Input.is_action_just_pressed("r"):
			_reload()

func _fire(burst: bool):
	timer.start(fire_rate_seconds)
	non_stop_counter += fire_rate_seconds
	non_stop_counter = clamp(non_stop_counter,0,1)
	if burst:
		for i in burst_size:
			if current_magazine_size != 0:
				current_magazine_size -= 1
				_animation_controller()
				_hitreg()
				_apply_camera_recoil()
			else:
				break
	else:
		if current_magazine_size != 0:
			current_magazine_size -= 1
			_animation_controller()
			_hitreg()
			_apply_camera_recoil()

func _hitreg():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider.is_in_group(interact_in_group):
			if collider.has_method(interact_method):
				collider.call(interact_method,damage)
				return true
	else:return false

func _reload():
	if ammo_size != 0:
		if current_magazine_size < magazine_size + round_in_chamber:
			is_reloading = true
			var bullet_shoted = (magazine_size + round_in_chamber) - current_magazine_size
			if bullet_shoted >= magazine_size:
				_animation_controller(true,true)
			else:
				_animation_controller(true)
			
			if ammo_size <= bullet_shoted:
				current_magazine_size += ammo_size
				ammo_size = 0
			elif ammo_size >= bullet_shoted:
				current_magazine_size = magazine_size + round_in_chamber
				ammo_size -= bullet_shoted
			bullet_shoted = 0

func _get_random_recoil():
	var recoil_kick : Vector3 = Vector3()
	
	recoil_kick.x = deg2rad(randf_range(min_camera_kick.x,max_camera_kick.x)) * non_stop_counter
	recoil_kick.y = deg2rad(randf_range(min_camera_kick.y,max_camera_kick.y)) * non_stop_counter
	recoil_kick.z = deg2rad(randf_range(min_camera_kick.z,max_camera_kick.z)) * non_stop_counter
	
	if in_sight:
		recoil_kick = recoil_kick * sight_accuracy_mult
	
	return recoil_kick

func _get_random_pos():
	var recoil_pos : Vector3 = Vector3()
	
	recoil_pos.z = (randf_range(min_camera_kick.z,max_camera_kick.z) * non_stop_counter) / 50
	
	if in_sight:
		recoil_pos = recoil_pos * sight_accuracy_mult
	
	return recoil_pos

func _apply_camera_recoil():
	camera_tween = create_tween()
	camera_tween.set_trans(Tween.TRANS_BACK)
	var recoil = _get_random_recoil()
	var pos = _get_random_pos()
	
	camera_tween.parallel().tween_property(camera_joint,"rotation",recoil,fire_rate_seconds)
	camera_tween.parallel().tween_property(camera_joint,"position",pos,fire_rate_seconds)
	
	camera_tween.tween_interval(recoil_recovery_speed)
	camera_tween.parallel().tween_property(camera_joint,"position",Vector3(),recoil_recovery_speed)
	camera_tween.parallel().tween_property(camera_joint,"rotation",Vector3(),recoil_recovery_speed)

func _animation_controller(is_reload: bool = false,empty_magazine: bool = false):
	var rand_anim := String()
	if is_reload:
		if empty_magazine:
			rand_anim = animations_reload_empty_mag.split(",")[randi() % animations_reload_empty_mag.split(",").size()]
		else:
			rand_anim = animations_reload.split(",")[randi() % animations_reload.split(",").size()]
	else:
		rand_anim = animations_fire.split(",")[randi() % animations_fire.split(",").size()]
	
	animation_player.play(rand_anim)

func _counter():
	if not Input.is_action_pressed("mouse_1"):
		non_stop_counter = 0

func _animation_finished(animation_name: String):
	if animation_name in (animations_reload + "," +animations_reload_empty_mag).split(","):
		is_reloading = false
