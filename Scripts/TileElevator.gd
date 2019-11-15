extends "res://Scripts/TileMain.gd"

var is_moving = false
var move_dir = 1
onready var tween = $Tween

var obj_above_us = null
var movement_bounds = Vector2(0,0)
var start_pos
var should_activate = false

func _ready():
	# save our starting position
	start_pos = TILEMAP_POS
	
	check_move_bounds()
	
	# elevators have half bounds on the Z-axis (up axis)
	min_bounds = Vector3(0.5, 0.5, 0.25)
	max_bounds = Vector3(0.5, 0.5, 0.25)
	
	# call parent ready
	._ready()

func activate():
	# remember we're moving (this is reset once the position tween ends)
	is_moving = true
	
	# determine our moving direction
	var delta_pos = Vector3(-1 * move_dir, -1 * move_dir, 1 * move_dir)
	var player_above = null
	
	# Check if there's something in our path
	var next_ind = v3_to_index(TILEMAP_POS + delta_pos)
	obj_above_us = null
	if GRID.has(next_ind):
		var val = GRID[next_ind]
		
		# if we're going down, something blocking us always means our movement ends
		if move_dir == -1:
			return
		
		# if a PLAYER is above us, move them with us
		var blocked = true
		if val.CELL_TYPE < 0:
			# but only if they aren't moving
			if not val.is_moving:
				val.move(delta_pos, true) # second parameter (true) tells the player he is being dragged
				obj_above_us = val
				blocked = false
		
		# if we end up being blocked, stop doing anything
		if blocked:
			return
	
	# move the elevator
	var elevator_move_speed = 0.3
	tween.interpolate_property(self, "position",
							   null, get_position() - Vector2(0,64)*move_dir,
							   elevator_move_speed, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)

	var new_pos = TILEMAP_POS + delta_pos
	tween.interpolate_property(self, "TILEMAP_POS",
							   null, new_pos,
							   elevator_move_speed, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
	
	tween.start()
	
	# update position in the global grid
	update_position_in_grid(new_pos, TILEMAP_POS)

func check_move_bounds():
	if move_dir == 1 and (TILEMAP_POS.z) >= (start_pos.z + movement_bounds[1]):
		move_dir = -1
		return true
	
	elif move_dir == -1 and (TILEMAP_POS.z) <= (start_pos.z + movement_bounds[0]):
		move_dir = 1
		return true
	return false

func _on_Tween_tween_completed(object, key):
	if key == ":TILEMAP_POS":
		# check if we're above/below our maximum bounds
		# if so, make sure our next move is in the other direction
		var changed_dir = check_move_bounds()
		
		if changed_dir:
			# if we are at the edge, stop moving and do one last sorting update
			is_moving = false
			
			update_bounds()
			get_node("/root/Node2D").update_depth_sort = true
		
		# if not, keep moving!
		# (but wait a frame, so the player can catch up => otherwise, the player falls through and imprecisions happen)
		else:
			should_activate = true

func _process(delta):
	if should_activate:
		should_activate = false
		activate()
	
	if is_moving:
		update_bounds()
		get_node("/root/Node2D").update_depth_sort = true
