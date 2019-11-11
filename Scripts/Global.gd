extends Node

var prev_camera_pos = null
var is_retry = false

func set_prev_camera_pos(pos):
	prev_camera_pos = pos

func get_prev_camera_pos():
	return prev_camera_pos

func set_retry(val):
	print(val)
	is_retry = val

func is_retry():
	return is_retry

func get_device():
	return "Android"
	#return OS.get_name()
