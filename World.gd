extends Node2D

const PlayerScene = preload("res://Player.tscn")

var player_spawn_location = Vector2.ZERO

onready var camera: = $Camera2D
onready var player: = $Player
onready var timer = $Timer


func _ready():
	VisualServer.set_default_clear_color(Color.lightblue)
	player.connect_camera(camera)
	player_spawn_location = player.global_position
	#connect autoloaded signal in code: [signal, obj with func, func]
	Events.connect("player_died", self, "_on_player_died")
	Events.connect("hit_checkpoint", self, "_on_hit_checkpoint")

func _on_hit_checkpoint(checkpoint_position):
	player_spawn_location = checkpoint_position

func _on_player_died():
	timer.start(1.0)
	#yield exits function and waits for signal, defers until condition met.
	#timer is the signal it's listening to. When it emits via its method 'timeout'
	#then when condition is met, it resumes function
	yield(timer, "timeout")
	var player = PlayerScene.instance()
	player.position = player_spawn_location
	add_child(player)
	#Yield for a single frame: ->
	#yield(get_tree(), "idle_frame")
	player.connect_camera(camera)
