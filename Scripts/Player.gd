extends "res://Scripts/TileMain.gd"

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
onready var view_drawer = get_node("/root/Node2D/PlayerView" + str(PLAYER_NUM))
var tilemap

var previous_blocking_objects = []

var blink_timer = null

var fall_tween_duration = 0.3
var move_tween_duration = 0.3
var rotate_speed_scale = 1.0

# this variable saves the four "lines of sight" we generate (left/right/up/down)
var light_paths = [[],[],[],[]]

var button_cells = []
var elevator_cells = []
var mirror_cells = []

var other_player
var is_disabled = false
var wait_frames = 0

func _ready():
	tilemap = get_parent()
	
	# initialize tilemap_pos
	var temp_pos = tilemap.world_to_map( get_position() )
	TILEMAP_POS.x = temp_pos.x
	TILEMAP_POS.y = temp_pos.y

	# and snap it to the position we found
	set_position( tilemap.map_to_world(Vector2(TILEMAP_POS.x, TILEMAP_POS.y)) + player_offset )
	
	# grab height from our tilemap
	# tilemaps are named "LevelX" => we only want the X, parsed as an int
	TILEMAP_POS.z = int( tilemap.get_name().substr(5,1) )
	
	# intialize a faster speed for animations
	$AnimationPlayer.set_speed_scale(rotate_speed_scale)
	
	# color the sprite (player 1 and 2 have distinct colors)
	var player_colors = [Color(1.0, 83/255.0, 83/255.0), Color(193/255.0, 83/255.0, 1.0)]
	modulate = player_colors[PLAYER_NUM]
	
	base_modulate = player_colors[PLAYER_NUM]
	
	# start blink timer
	blink_timer = Timer.new()
	add_child(blink_timer)
	
	blink_timer.connect("timeout", self, "blink") 
	blink_timer.set_one_shot(false)
	blink_timer.set_wait_time(rand_range(3,8))
	blink_timer.start()
	
	# call our parent ready function ("TileMain.gd")
	._ready()

func initialize(grid, other_player, button_cells, elevator_cells, mirror_cells):
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
	
	# give ourselves the right metadata
	CELL_TYPE = -(PLAYER_NUM+1)
	
	# and keep a reference to the main grid for the game
	GRID = grid

	# save a quick link to special cell types (takes more memory, but is better for performance)
	self.button_cells = button_cells
	self.elevator_cells = elevator_cells
	self.mirror_cells = mirror_cells

	# save ourselves into the general GRID variable
	update_position_in_grid(TILEMAP_POS)
	
	self.other_player = other_player

func update_position_in_grid(new_position, old_position = null):
	# remove ourselves from the OLD position
	if not old_position == null:
		GRID.erase( v3_to_index(old_position) )
	
	# save our player number in the GRID
	# (negative values are for obstacles, positive values for tilemap tiles)
	GRID[v3_to_index(new_position)] = self

func v3_to_index(v3):
	return str(int(round(v3.x))) + "," + str(int(round(v3.y))) + "," + str(int(round(v3.z)))

func blink():
	if not is_rotating:
		var cur_frame = $Eyes.frame
		$AnimPlayerEyes.play("Blink " + str(cur_frame))
	
	# plan the next blink
	blink_timer.set_wait_time(rand_range(3,8))

func _process(delta):
	if is_disabled:
		return
	
	if wait_frames > 0:
		wait_frames -= 1

	$PosLabel.set_text(v3_to_index(TILEMAP_POS))
	
	# if we're NOT moving ...
	if not is_moving:
		# check if we should fall down because of gravity
		var pos_3d_below = TILEMAP_POS + Vector3(1,1,-1)
		var apply_gravity = true
		
		# if there is SOMETHING below us, disable the gravity for this tick
		if GRID.has(v3_to_index(pos_3d_below)):
			# check if it's the other player!
			# if we satisfied the "leap of faith" win condition, we win!
			var val_below = GRID[v3_to_index(pos_3d_below)]
			var other_player = (PLAYER_NUM + 1) % 2
			if val_below.CELL_TYPE == -(other_player+1):
				if last_move_backward and fall_counter >= 1:
					# tell the main node to end the level
					play_sound('game_win')
					get_node("/root/Node2D").end_level(true, get_position(), self )
			
			# in any case, if there's an object below us, reset gravity
			apply_gravity = false
			fall_counter = 0
		
		if apply_gravity:
			move_down()
	else:
		# update our bounds, if we're moving
		update_bounds()
		
		# tell main node we're moving
		get_node("/root/Node2D").update_depth_sort = true

func check_blocking_objects():
	for obj in previous_blocking_objects:
		obj.modulate.a = 1.0
	
	previous_blocking_objects.clear()
	
	# an object can only block player view if it's at these positions (left, right, front, above)
	# we just check two heights above us => most levels won't be higher than that
	var block_positions = [Vector3(0,-1,1), Vector3(-1,0,1), Vector3(-1,-1,1), Vector3(0,0,1),
						   Vector3(0,-1,2), Vector3(-1,0,2), Vector3(-1,-1,2), Vector3(0,0,2),
						   Vector3(0,-1,3), Vector3(-1,0,3), Vector3(-1,-1,3), Vector3(0,0,3)]
	
	for pos in block_positions:
		var cell = v3_to_index(TILEMAP_POS + pos)
		
		# if this object exists ...
		if GRID.has(cell):
			var cur_obj = GRID[cell]
			
			# if it's a player, don't do anything
			if cur_obj.CELL_TYPE < 0:
				continue
			
			# otherwise, hide it, and remember we hid it
			cur_obj.modulate.a = 0.25
			previous_blocking_objects.append(cur_obj)

func next_sight_step(pos, dir, num_steps):
	var path = []
	
	# get the next block
	var next_block = pos + dir
	var ind = v3_to_index(next_block)
	
	# increase number of steps taken
	num_steps += 1
	
	# add the (3D) position to the path
	path.append( pos )
	
	# after 5 steps where nothing happened, the sight ray dies
	if num_steps > 5:
		return path
	
	# if there is SOMETHING here
	if GRID.has(ind):
		var val = GRID[ind]
		
		# if it's a mirror (type 1, 2 or 3)
		if val.CELL_TYPE in mirror_cells:
			# change light direction
			# also reset number of steps
			# and add the resulting path to the path we already found
			dir = val.get_reflection_vector(dir)
			
			# if dir returns an empty vector, this reflection is impossible/not allowed for some reason
			if dir.length() == 0:
				return path
		
			val.show_reflection( next_block, TILEMAP_POS, self )

			#dir = Vector3(-dir.y, dir.x, dir.z) # 90 degree angle to the RIGHT
			# dir = Vector3(0, 0, 1) # straight up
			
			path = path + next_sight_step(next_block, dir, 0)
		
		# if it's another player
		elif val.CELL_TYPE < 0:
			path.append( next_block)
			return path
		
		# if not, stop the ray
		else:
			return path
	
	# if there is NOTHING here, go to next step
	else:
		path = path + next_sight_step(next_block, dir, num_steps)
	
	return path

func determine_line_of_sight():
	# for each of the four directions (left/right/up/down)
	# emit a "sight" ray
	var light_path
	var has_lost = false
	for i in range(4):
		var dir = get_custom_dir_vector(i)
		
		light_paths[i] = next_sight_step(TILEMAP_POS, dir, 0)
		
		# if this is the direction we're looking in ...
		if i == FORWARD_DIR:
			# if it's the other player ...
			var other_player = (PLAYER_NUM + 1) % 2
			
			# get cell at last light path index
			# (index -1 checks the LAST element in the array)
			var last_ind = v3_to_index(light_paths[i][-1])
			if GRID.has(last_ind) and GRID[last_ind].CELL_TYPE == -(other_player+1):
				# LOSE! LOSE! LOSE!
				has_lost = true
				play_sound("game_loss")
				get_node("/root/Node2D").end_level(false, null, self)
				break
			
			# TO DO: Only count this when the other (target) player is NOT moving?

	if has_lost:
		view_drawer.create_line_of_sight( light_paths[FORWARD_DIR] )

func get_action(action_name):
	return action_name + str(PLAYER_NUM)

func _input(ev):
	if is_disabled or wait_frames > 0:
		return
	
	if not is_rotating:
		if ev.is_action_released( get_action("left") ) and not ev.is_echo():
			print("I want to rotate LEFT!")
			rotate(-1)
		elif ev.is_action_released( get_action("right") ) and not ev.is_echo():
			print("I want to rotate RIGHT!")
			rotate(1)
	
	if not is_rotating and not is_moving:
		if ev.is_action_released( get_action("forward") ):
			move_forward(1)
		elif ev.is_action_pressed( get_action("backward") ):
			move_forward(-1)

func rotate(rotate_dir):
	if is_rotating or wait_frames > 0:
		return
	
	play_sound('rotate2', true)
	
	# disable rotating while we're playing the animation
	is_rotating = true
	
	# stop blinking animation
	$AnimPlayerEyes.stop()
	
	# Play rotation animation (which is a custom spritesheet I made)
	# NOTE: Once that's finished, rotation is allowed again
	if rotate_dir < 0:
		$AnimationPlayer.play_backwards("Rotate Player")
	else:
		$AnimationPlayer.play("Rotate Player")

func rotation_finished(arg):
	
	# if we found a different forward direction, stop
	# (otherwise, you need to press twice when switching directions)
	if FORWARD_DIR != arg:
		# pause the animation
		# (just stopping it with stop() would reset it every time)
		$AnimationPlayer.stop(false)
		
		wait_frames = 3.0
		
		# ensure we have the right frame
		# TO DO: If I ever make a more detailed rotating animation, we need to update this line of code
		frame = arg * 2

		# remember we're done rotating
		is_rotating = false
		
		# set the forward direction from the argument passed in
		FORWARD_DIR = arg
		
		# tell the world sight lines should update
		get_node("/root/Node2D").update_sight_lines()

func move_down():
	# if we have a negative height, we're below level bounds, and have thus lost the level
	if (TILEMAP_POS.z - 1) < 0:
		play_sound("game_loss")
		get_node("/root/Node2D").end_level(false, null, self)
		return

	# increase fall counter
	fall_counter += 1
	
	# disable moving (while we're moving/playing a tween)
	is_moving = true
	
	# find corresponding tile in the tilemap => use it to get the position
	var old_tilemap_position = TILEMAP_POS
	var new_tilemap_position = TILEMAP_POS + Vector3(1,1,-1)
	var cell_pos = tilemap.map_to_world(Vector2(new_tilemap_position.x, new_tilemap_position.y)) + player_offset
	
	# now create a tween to move to our destination
	# (the tween object has a signal that's fired when we REACH the destination)
	tween.interpolate_property(self, "position", 
								null, cell_pos, 
								fall_tween_duration, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
	
	update_position_in_grid(new_tilemap_position, old_tilemap_position)

	tween.interpolate_property(self, "TILEMAP_POS", 
								null, new_tilemap_position, 
								fall_tween_duration, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)


	tween.start()

func get_custom_dir_vector(vec):
	match vec:
		0:
			return Vector3(1,0,0)
		1:
			return Vector3(0,1,0)
		2:
			return Vector3(-1,0,0)
		3:
			return Vector3(0,-1,0)

func get_dir_vector():
	if FORWARD_DIR == 0:
		return Vector3(1,0,0)
	elif FORWARD_DIR == 1:
		return Vector3(0,1,0)
	elif FORWARD_DIR == 2:
		return Vector3(-1,0,0)
	elif FORWARD_DIR == 3:
		return Vector3(0,-1,0)

func move(move_vec, being_dragged = false):
	# find the right vector that corresponds with the direction we're facing
	var temp_pos = TILEMAP_POS + move_vec
	
	# if we're being dragged by another
	# override win conditions
	if being_dragged:
		last_move_backward = false
		fall_counter = 0.0
	
	###
	# CHECK IF WE'RE ALLOWED TO MOVE
	#  => Check for a tilemap cell in that direction
	#  => Check for a player in that direction
	# If not, break out of this function
	##
	
	# If there's something here, we can't move!
	# TO DO: Maybe need a more specific check, when there will be things I can pass through??
	if GRID.has(v3_to_index(temp_pos)):
		
		# turn off particles, just in case
		$MovementParticles.emitting = false
		
		return

	###
	# ACTUALLY MOVE
	###
	
	wait_frames = 3.0
	
	# check if the other player is standing on top of us
	# => if so, drag them with us!
	var ind_above = v3_to_index(TILEMAP_POS + Vector3(-1, -1, 1))
	if GRID.has(ind_above):
		var other_player = (PLAYER_NUM + 1) % 2
		var val = GRID[ind_above]
		if val.CELL_TYPE == -(other_player+1):
			val.move(move_vec, true)
	
	#TILEMAP_POS = temp_pos
	
	update_position_in_grid(temp_pos, TILEMAP_POS)
	
	# disable moving (while we're moving/playing a tween)
	is_moving = true
	
	# find corresponding tile in the tilemap => use it to get the position
	var cell_pos = tilemap.map_to_world(Vector2(temp_pos.x, temp_pos.y)) + player_offset
	
	# now create a tween to move to our destination
	# (the tween object has a signal that's fired when we REACH the destination)
	tween.interpolate_property(self, "position", 
								null, cell_pos, 
								move_tween_duration, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)

	# update the actual tilemap position (via a tween)
	tween.interpolate_property(self, "TILEMAP_POS", 
							   null, temp_pos,
								move_tween_duration, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)

	# start the tween
	tween.start()

func move_forward(forward):
	# we are NOT allowed to move simultaneously with the other player
	if is_moving or is_rotating or other_player.is_moving or wait_frames > 0:
		return
	
	# position particles near our backside
	var pos = get_dir_vector() * forward * -1
	var pos_iso = Vector2((pos.x - pos.y) * 65, (pos.x + pos.y) * 32)
	$MovementParticles.set_position(pos_iso)
	
	# emit movement particles
	$MovementParticles.emitting = true
	
	# only play sliding sound if we're actually moving on the ground, of course
	play_sound("slide")
	
	if forward < 0:
		last_move_backward = true
	else:
		last_move_backward = false
	
	move( get_dir_vector()*forward )

func _on_Tween_tween_completed(object, key):
	# if this was a position tween ... (aka movement)
	# NOTE: Previously, I checked the ":position" property => DON'T DO THIS
	#       It caused slight imprecisions in TILEMAP_POS, because position tween ended _before_ the TILEMAP_POS
	#		These imprecisions caused huge depth sorting issues over time.
	if key == ":TILEMAP_POS":
		# ... reset movement variable
		is_moving = false
		
		# always reset particles
		# (they might not be on, because we're being dragged or something)
		# (but hey, just to be sure)
		$MovementParticles.emitting = false
		
		# update bounds one last time
		update_bounds()
		
		# update depth sort one last time
		get_node("/root/Node2D").update_depth_sort = true
		
		# update light value
		update_light_value()
		
		# check what this player can see
		# (this also takes into account mirrors, lights, etc.)
		# (if we can see the other player, it's GAME OVER)
		# IMPORTANT: We only do this once something is done moving and the world is static again => huge performance improvement
		get_node("/root/Node2D").update_sight_lines()

		# check if there's something blocking the view towards this player
		check_blocking_objects()
		
		# check if we're standing on a BUTTON that should be activated
		var pos_3d_below = v3_to_index(TILEMAP_POS + Vector3(1,1,-1))
		if GRID.has(pos_3d_below):
			var val = GRID[pos_3d_below]
			
			if val.CELL_TYPE in button_cells:
				# find the connected object (whatever it is; an elevator, mirror, light, etc.)
				var ind = button_cells.find(val.CELL_TYPE)
				var objects = get_node("/root/Node2D").button_objects[ind]
				
				# play sound
				play_sound("switch")
				
				# activate it!
				for obj in objects:
					obj.activate()

func play_sound(path, wav = false):
#	# don't play if something is already playing
#	# (mainly to prevent duplicate sounds)
#	if $AudioStreamPlayer2D.playing:
#		return
	
	$AudioStreamPlayer2D.volume_db = Global.get_soundfx_level()

	# if path = null, it means I want the thing to stop
	if path == null:
		$AudioStreamPlayer2D.playing = false
		return
	
	# otherwise, play the sound at specified path
	if wav:
		$AudioStreamPlayer2D.stream = load("res://Sound/" + str(path) + ".wav")
	else:
		$AudioStreamPlayer2D.stream = load("res://Sound/" + str(path) + ".ogg")
	$AudioStreamPlayer2D.pitch_scale = rand_range(0.95,1.05)
	$AudioStreamPlayer2D.playing = true

func display_exclamation_mark():
	var seo = get_node("SeeingEachOther")
	seo.set_visible(true)
	
	#seo.z_index = TILEMAP_POS.x + (CUR_HEIGHT + 1) * 3.0 + TILEMAP_POS.y
	
	return seo
