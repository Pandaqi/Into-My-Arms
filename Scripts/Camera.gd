extends Camera2D

var players

func _ready():
	# start off screen
	var vp_size = get_viewport().size
	self.offset = Vector2(-vp_size.x,0)
	
	# and with the old camera pos (from previous level)
	if Global.get_prev_camera_pos() != null:
		set_position( Global.get_prev_camera_pos() )
	
	# cache players
	players = get_tree().get_nodes_in_group("Players")

func find_average_position():
	return 0.5 * ( players[0].get_position() + players[1].get_position() )

func _process(delta):
	set_position( find_average_position() )
