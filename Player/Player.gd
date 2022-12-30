extends KinematicBody2D
class_name Player
#BUGS: 
##1. Double jump is triple jump? 
##2. Can't jump while standing in front of flag. Possible collision/is colliding thing?

enum{ MOVE, CLIMB }

#allows you to adjust numbers in editor; casts for autocomplete
export(Resource) var moveData = preload("res://Player/FastPlayerMovementData.tres") as PlayerMovementData

#Velocity
var velocity : Vector2 = Vector2.ZERO
#FSM State MAchine State
var state = MOVE

#Jumps
var jumps_available = 1
var buffered_jump = false
var coyote_jump = false

onready var animatedSprite: = $AnimatedSprite
onready var ladderCheck: = $LadderCheck
onready var jumpBufferTimer: = $JumpBufferTimer
onready var coyoteJumpTimer = $CoyoteJumpTimer
onready var remoteTransform2D = $RemoteTransform2D
#func powerup(): 
	#moveData = load("res://FastPlayerMovementData.tres")
func _ready():
	#cast for autocompletion
	## moveData = moveData as PlayerMovementData
	animatedSprite.frames = load ("res://Player/PlayerGreenSkin.tres")
#default fps is 60fps, so delta is 1/60th
func _physics_process(delta):
	var input = Vector2.ZERO
	# old way: input.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	#new way:
	input.x = Input.get_axis("ui_left", "ui_right")
	input.y = Input.get_axis("ui_up", "ui_down")
	#match statement is like a switch case
	match state:
		MOVE: move_state(input, delta)
		CLIMB: climb_state(input, delta)
	
func is_on_ladder():
	if not ladderCheck.is_colliding(): return false
	var collider = ladderCheck.get_collider()
	if not collider is Ladder: return false
	return true

func move_state(input, delta):
	if is_on_ladder() and Input.is_action_just_pressed("ui_up"):
		state = CLIMB
	
	apply_gravity(delta)
	if input.x == 0:
		apply_friction(delta)
		animatedSprite.animation = "Idle"
	else:
		apply_acceleration(input.x, delta)
		animatedSprite.animation = "Run"
		#$AnimatedSprite.flip_h = true
		
		
	if not is_on_floor() and Input.is_action_just_pressed("ui_up"): 
		if jumps_available > 0:
			jump_sound()
			velocity.y = moveData.JUMP_FORCE
			jumps_available -= 1
	#	else: fast_fall(delta)
	if is_on_floor() or coyote_jump:
		if Input.is_action_just_pressed("ui_up") and not ladderCheck.is_colliding():
			if jumps_available > 1:
				jump_sound()
				velocity.y = moveData.JUMP_FORCE
				jumps_available -= 1
		else:
			if Input.is_action_just_released("ui_up") and velocity.y < moveData.JUMP_RELEASE_FORCE:
				velocity.y = moveData.JUMP_RELEASE_FORCE
			if velocity.y > 5:
				velocity.y += moveData.ADDITIONAL_FALL_GRAVITY * delta
				
		
	if Input.is_action_pressed("ui_up") and not is_on_floor():
		buffered_jump = true
		#jumpBufferTimer.start()
	
	if !is_on_floor(): 
		animatedSprite.animation = "Jump"
	if is_on_floor():
		jumps_available = 2
	#stuff 
	var was_in_air = !is_on_floor()
	var was_on_floor = is_on_floor()
	
	velocity = move_and_slide(velocity, Vector2.UP)
	var just_landed = is_on_floor() and was_in_air
	if just_landed:
		animatedSprite.animation = "Run"
		animatedSprite.frame = 1
	#checks if was in the air, and now is on the floor,
	#then checks for buffered jump, and checks jump is still pressed.
	#and blammo! A responsive buffered jump
	if just_landed and buffered_jump and Input.is_action_pressed("ui_up"):
			jump_sound()
			velocity.y = moveData.JUMP_FORCE
			buffered_jump = false
	
	var just_left_ground = not is_on_floor() and was_on_floor
	if just_left_ground and velocity.y >= 0:
		coyote_jump = true
		coyoteJumpTimer.start()
		
func climb_state(input, delta):
	if not is_on_ladder():
		state = MOVE
	if input.length() != 0:
		animatedSprite.animation = "Run"
	else:
		animatedSprite.animation = "Idle"
	velocity = input * moveData.CLIMB_SPEED
	velocity = move_and_slide(velocity, Vector2.UP)
	if Input.is_action_just_pressed("ui_right"):
		animatedSprite.flip_h = true
	elif Input.is_action_just_pressed("ui_left"):
		animatedSprite.flip_h = false

func connect_camera(camera):
	var camera_path = camera.get_path()
	remoteTransform2D.remote_path = camera_path
	

func jump_sound():
	SoundPlayer.play_sound(SoundPlayer.JUMP)
func hurt_sound():
	SoundPlayer.play_sound(SoundPlayer.HURT)
func player_die():
	hurt_sound()
	queue_free()
	#connected in World.gd script:
	Events.emit_signal("player_died")

func apply_gravity(delta):
		velocity.y += moveData.GRAVITY * delta
		velocity.y = min(velocity.y, 300)

func fast_fall(delta):
	pass
	#if velocity.y > 0:
		#velocity.y += moveData.ADDITIONAL_FALL_GRAVITY * delta
	
func apply_friction(delta):
	velocity.x = move_toward(velocity.x, 0, moveData.FRICTION * delta)

func apply_acceleration(amount, delta):
	animatedSprite.flip_h = velocity.x > 0
	velocity.x = move_toward(velocity.x, moveData.MAX_SPEED * amount, moveData.ACCELERATION * delta)

func _on_CoyoteJumpTimer_timeout():
	coyote_jump = false
	
