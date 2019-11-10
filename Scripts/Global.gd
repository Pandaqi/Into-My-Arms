extends Node

var prev_camera_pos = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_prev_camera_pos(pos):
	prev_camera_pos = pos

func get_prev_camera_pos():
	return prev_camera_pos

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
