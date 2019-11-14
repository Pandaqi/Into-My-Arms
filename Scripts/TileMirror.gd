extends "res://Scripts/TileMain.gd"

export (Vector2) var mirror_normal = Vector2(1,1)
export (bool) var closed = false

func convert_dir_to_frame(vec):
	match vec:
		Vector2(1,0):
			return 0
		
		Vector2(0,1):
			return 1
		
		Vector2(-1,0):
			return 2
		
		Vector2(0,-1):
			return 3

func convert_dir_to_vec(forward_dir):
	match forward_dir:
		0:
			return Vector2(1,0)
		
		1: 
			return Vector2(0,1)
		
		2:
			return Vector2(-1,0)
		
		3:
			return Vector2(0,-1)

func hide_reflection():
	$Player.hide()

func show_reflection(my_pos, player_pos, player_obj):
	var player_forward_vec = convert_dir_to_vec(player_obj.FORWARD_DIR)
	
	if my_pos.x != player_pos.x:
		player_forward_vec.x *= -1
	
	if my_pos.y != player_pos.y:
		player_forward_vec.y *= -1
	
	# show player in the mirror
	$Player.show()
	$Player.frame = convert_dir_to_frame(player_forward_vec)
	$Player.modulate = player_obj.modulate
	$Player.modulate.a = 0.5
	
	#$Player.frame = convert_dir_to_frame(vec)

func get_reflection_vector(vec):
	# normalize both vectors
	# (and turn 3d into 2d; ignore Z-axis for now)
	var temp_normal = mirror_normal.normalized()
	var temp_vec = Vector2(vec.x, vec.y).normalized()
	
	if closed:
		# check if mirror normal points the same way
		# if not, this reflection is not allowed
		# NOTE: Someone said we should negate the normal, but I haven't found any need to do that?
		if temp_normal.dot(temp_vec) > 0:
			return Vector3(0,0,0)
	
	var reflec_vec = temp_vec - 2.0 * temp_normal.dot(temp_vec) * temp_normal
	
	return Vector3(reflec_vec.x, reflec_vec.y, 0)
