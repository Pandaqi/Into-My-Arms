extends Camera2D

var players

func _ready():
	players = get_tree().get_nodes_in_group("Players")

func _process(delta):
	var average_pos = players[0].get_position()
	
	set_position( average_pos )
