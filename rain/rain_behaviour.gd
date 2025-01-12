extends Node3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var player = get_node("%Player") as Node3D
	var player_pos = player.position

	position.x = player_pos.x
	position.z = player_pos.z
	if player_pos.y > 0:
		position.y = player_pos.y
		
