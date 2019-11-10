extends Sprite

### 
# INTERESTING LINKS
#
# Isometric height finding: https://stackoverflow.com/questions/21842814/mouse-position-to-isometric-tile-including-height
# Godot Ysort in tilemap: https://www.reddit.com/r/godot/comments/b1xtan/help_with_ysort_tilemap_kinematicbody2d/
#
# Godot demo (v2.1) for isometric lighting: https://github.com/godotengine/godot-demo-projects/tree/2.1/2d/isometric_light
# About PORTING that demo to v3.0: https://godotengine.org/qa/25920/2d-isometric-lighting
#
# Isometric drawing tools in Affinity Designer (v1.7): https://affinityspotlight.com/article/how-to-use-the-new-isometric-drawing-tools-in-affinity-designer-17/
#
# About intuitive axis-aligned movement in isometric games: https://ux.stackexchange.com/questions/80890/controlling-movement-direction-in-isometric-view



# Keep track of our current ROTATION ( = forward facing direction)
# Also keep track of our current POSITION
var FORWARD_DIR = 0
var TILEMAP_POS = Vector3.ZERO
var CUR_HEIGHT = 1

var GRID

export (int) var PLAYER_NUM = 0

var player_offset = Vector2(0, 32)

# These variables are for checking the win-condition
# In order for something to be a "leap of faith", you need to:
#  => Step backward
#  => Fall for at least one block
var last_move_backward = false
var fall_counter = 0

# To make sure we don't move/rotate WHILE we're already doing that
var is_moving = false
var is_rotating = false

# Nodes we'll need often
onready var tween = get_node("Tween")
var tilemap

# For checking/remembering what we're seeing
var VIEW_POINT = null

func _ready():
	tilemap = get_parent()
	
	# initialize tilemap_pos
	TILEMAP_POS = tilemap.world_to_map( get_position() )
	
	# and snap it to the position we found
	set_position( tilemap.map_to_world(TILEMAP_POS) + player_offset )
	
	# grab height from our tilemap
	# tilemaps are named "LevelX" => we only want the X, parsed as an int
	CUR_HEIGHT = int( tilemap.get_name().substr(5,1) )
	
	print(TILEMAP_POS)
	print(CUR_HEIGHT)
	
	# intialize a faster speed for animations
	$AnimationPlayer.set_speed_scale(2.0)

func initialize(grid):
	# get root node
	# NOTE: It's important to do this BEFORE we remove ourselves,
	#       because "can't use get_node() with absolute paths from outside the active scene tree" (Godot error message)
	var root = get_node("/root/Node2D")
	
	# remove ourselves from current tilemap
	get_parent().remove_child(self)
	root.add_child(self)
	
	# change tilemap to the reference one
	# (the others will soon be removed, after this function is called)
	tilemap = get_node("/root/Node2D/EmptyTilemap")
	
	# and keep a reference to the main grid for the game
	GRID = grid
	
	# save ourselves into the general GRID variable
	update_position_in_grid(Vector3(TILEMAP_POS.x, CUR_HEIGHT, TILEMAP_POS.y))

func update_position_in_grid(new_position, old_position = null):
	# remove ourselves from the OLD position
	if not old_position == null:
		GRID.erase( v3_to_index(old_position) )
	
	# save our player number in the GRID
	# (negative values are for obstacles, positive values for tilemap tiles)
	GRID[v3_to_index(new_position)] = -(PLAYER_NUM+1)

func v3_to_index(v3):
	return str(int(round(v3.x))) + "," + str(int(round(v3.y))) + "," + str(int(round(v3.z)))

func _process(delta):
	var pos_3d = Vector3(TILEMAP_POS.x, CUR_HEIGHT, TILEMAP_POS.y)
	
	# NOTE: By rounding/ceiling the Z here, moving in FRONT of stuff looks great, but moving behind stuff is weird
	# Essentially, I need a way to differentiate between these situations?
	# TO DO: See if I can convert isometric to 3D coordinates within tilemap, so things should just work
	z_index = pos_3d.x + 3*pos_3d.y + pos_3d.z
	
	# check what this player can see
	# (if we can see the other player, it's GAME OVER)
	determine_fov()
	
	# as long as we're moving, all other movements aren't even considered
	if not is_moving:
	
		# check if we should fall down because of gravity
		var pos_3d_below = Vector3(TILEMAP_POS.x + 1, CUR_HEIGHT - 1, TILEMAP_POS.y + 1)
		var apply_gravity = true
		
		# if there is SOMETHING below us, disable the gravity for this tick
		if GRID.has(v3_to_index(pos_3d_below)):
			
			# check if it's the other player!
			# if we satisfied the "leap of faith" win condition, we win!
			var val_below = GRID[v3_to_index(pos_3d_below)]
			var other_player = (PLAYER_NUM + 1) % 2
			if val_below == -(other_player+1):
				if last_move_backward and fall_counter >= 1:
					print("YOU WIN!")
			
			apply_gravity = false
			fall_counter = 0

		if apply_gravity:
			move_down()
	
		# if we're not falling due to gravity ...
		else:
			# ... and we're rotating, allow player input
			if not is_rotating:
			
				if Input.is_action_pressed( get_action("forward") ):
					move_forward(1)
				elif Input.is_action_pressed( get_action("backward") ):
					move_forward(-1)

func determine_fov():
	# get forward direction vector
	var dir = get_dir_vector()
	
	# step through the grid until we find something
	var found_something = false
	var max_steps = 10
	var step_counter = 1
	
	while not found_something:
		var next_cell = Vector3(TILEMAP_POS.x + step_counter * dir.x, CUR_HEIGHT, TILEMAP_POS.y + step_counter * dir.y)
		
		if GRID.has(v3_to_index(next_cell)):
			# if it's the other player, we LOSE
			var val = GRID[v3_to_index(next_cell)]
			
			var other_player = (PLAYER_NUM + 1) % 2
			if val == -(other_player+1):
				print("YOU LOSE")
				break
			
			# save that we found something and WHERE we found it
			found_something = true
			VIEW_POINT = tilemap.map_to_world(Vector2(next_cell.x, next_cell.z))
			break
		
		if step_counter >= max_steps:
			break
		
		step_counter += 1
	
	if not found_something:
		VIEW_POINT = null
	
	update()

func _draw():
	if VIEW_POINT != null:
		draw_line( Vector2.ZERO, VIEW_POINT - get_position(), Color(255, 0, 0), 1)

func get_action(action_name):
	return action_name + str(PLAYER_NUM)

func _input(ev):
	if not is_rotating:
		if ev.is_action_released( get_action("left") ):
			rotate(-1)
		elif ev.is_action_released( get_action("right") ):
			rotate(1)

func rotate(rotate_dir):
	if is_rotating:
		return
	
	# disable rotating while we're playing the animation
	is_rotating = true
	
	# Play rotation animation (which is a custom spritesheet I made)
	# NOTE: Once that's finished, rotation is allowed again
	if rotate_dir < 0:
		$AnimationPlayer.play_backwards("Rotate Player")
	else:
		$AnimationPlayer.play("Rotate Player")
	
	print($AnimationPlayer.is_playing())

func rotation_finished(arg):
	# if we found a different forward direction, stop
	# (otherwise, you need to press twice when switching directions)
	if FORWARD_DIR != arg:
		# pause the animation
		# (just stopping it with stop() would reset it every time)
		$AnimationPlayer.stop(false)
	
	# remember we're done rotating
	is_rotating = false
	
	# set the forward direction from the argument passed in
	FORWARD_DIR = arg

func move_down():
	print("Moving down?? Player num: ", PLAYER_NUM)
	
	# increase fall counter
	fall_counter += 1
	
	# disable moving (while we're moving/playing a tween)
	is_moving = true
	
	# find corresponding tile in the tilemap => use it to get the position
	var old_tilemap_position = TILEMAP_POS
	var new_tilemap_position = TILEMAP_POS + Vector2(1,1)
	var cell_pos = tilemap.map_to_world(new_tilemap_position) + player_offset
	
	# now create a tween to move to our destination
	# (the tween object has a signal that's fired when we REACH the destination)
	var tween_duration = 0.5
	tween.interpolate_property(self, "position", 
								null, cell_pos, 
								tween_duration, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
	TILEMAP_POS = new_tilemap_position
	CUR_HEIGHT -= 1
	
	update_position_in_grid(Vector3(TILEMAP_POS.x, CUR_HEIGHT, TILEMAP_POS.y), 
							Vector3(old_tilemap_position.x, CUR_HEIGHT+1, old_tilemap_position.y))

#	tween.interpolate_property(self, "TILEMAP_POS", 
#								null, new_tilemap_position, 
#								tween_duration, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
#
#	tween.interpolate_property(self, "CUR_HEIGHT", 
#								null, (CUR_HEIGHT - 1), 
#								tween_duration, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
#
	tween.start()

func get_dir_vector():
	if FORWARD_DIR == 0:
		return Vector2(1,0)
	elif FORWARD_DIR == 1:
		return Vector2(0,1)
	elif FORWARD_DIR == 2:
		return Vector2(-1, 0)
	elif FORWARD_DIR == 3:
		return Vector2(0,-1)

func move_forward(forward):
	if is_moving or is_rotating:
		return
	
	# find the right vector that corresponds with the direction we're facing
	var temp_dir = get_dir_vector()
	var temp_pos = TILEMAP_POS + temp_dir*forward
	
	if forward < 0:
		last_move_backward = true
	else:
		last_move_backward = false
	
	###
	# CHECK IF WE'RE ALLOWED TO MOVE
	#  => Check for a tilemap cell in that direction
	#  => Check for a player in that direction
	# If not, break out of this function
	###
	var wanted_cell = Vector3(temp_pos.x, CUR_HEIGHT, temp_pos.y)

	# If there's something here, we can't move!
	# TO DO: Maybe need a more specific check, when there will be things I can pass through??
	if GRID.has(v3_to_index(wanted_cell)):
		return

	###
	# ACTUALLY MOVE
	###
	
	#TILEMAP_POS = temp_pos
	
	update_position_in_grid(Vector3(temp_pos.x, CUR_HEIGHT, temp_pos.y), 
							Vector3(TILEMAP_POS.x, CUR_HEIGHT, TILEMAP_POS.y))
	
	# disable moving (while we're moving/playing a tween)
	is_moving = true
	
	# find corresponding tile in the tilemap => use it to get the position
	var cell_pos = tilemap.map_to_world(temp_pos) + player_offset
	
	# now create a tween to move to our destination
	# (the tween object has a signal that's fired when we REACH the destination)
	var tween_duration = 0.5
	tween.interpolate_property(self, "position", 
								null, cell_pos, 
								tween_duration, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)

	# update the actual tilemap position (via a tween)
	tween.interpolate_property(self, "TILEMAP_POS", 
							   null, temp_pos,
							tween_duration, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)

	# start the tween
	tween.start()

func _on_Tween_tween_completed(object, key):
	# if this was a position tween ... (aka movement)
	if key == ":position":
		# ... reset movement variable
		is_moving = false
