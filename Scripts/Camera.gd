extends Camera2D

var players

func _ready():
	# if this isn't a retry ...
	if not Global.is_retry():
		# start off screen
		var camera = get_node("/root/Node2D/Camera")
		var vp_size = get_viewport().size * camera.get_zoom().x
		self.offset = Vector2(-vp_size.x,0)
	
	# and with the old camera pos (from previous level)
	if Global.get_prev_camera_pos() != null:
		position.y = Global.get_prev_camera_pos().y
	
	# cache players
	players = get_tree().get_nodes_in_group("Players")

func find_average_position():
	return 0.5 * ( players[0].get_position() + players[1].get_position() )

func _process(delta):
	set_position( find_average_position() )
