extends Area2D

func _ready():
	pass # Replace with function body.


func _on_Hitbox_body_entered(body):
	if body is Player:
		body.player_die()
		#get_tree().reload_current_scene()
