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

export (int) var PLAYER_NUM = 0

var player_offset = Vector2(0, 32)

# To make sure we don't move/rotate WHILE we're already doing that
var is_moving = false
var is_rotating = false

# Nodes we'll need often
onready var tween = get_node("Tween")
var tilemap

func _ready():
	tilemap = get_parent()
	
	# initialize tilemap_pos
	TILEMAP_POS = tilemap.world_to_map( get_position() )
	
	# and snap it to the position we found
	set_position( tilemap.map_to_world(TILEMAP_POS) + player_offset )
	
	# grab height from our tilemap
	# tilemaps are named "LevelX" => we only want the X, parsed as an int
	CUR_HEIGHT = int( tilemap.get_name().substr(5,1) )
	
	# intialize a faster speed for animations
	# $AnimationPlayer.set_speed_scale(2.5)

func _process(delta):
	# as long as we're moving, all other movements aren't even considered
	if not is_moving:
	
		# check if we should fall down because of gravity
		var ind_below = TILEMAP_POS + Vector2(1,1)
		var apply_gravity = true
		
		# only check the tilemap at our current height
		var tilemap_below = get_node("/root/Node2D/Level" + str(CUR_HEIGHT-1))
		if tilemap_below.get_cell(ind_below.x, ind_below.y) > -1:
			apply_gravity = false

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

func get_action(action_name):
	return action_name + str(PLAYER_NUM)

func _input(ev):
	if not is_rotating:
		if ev.is_action_released( get_action("left") ):
			rotate(-1)
		elif ev.is_action_released( get_action("right") ):
			rotate(1)

func rotate(rotate_dir):
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
	# disable moving (while we're moving/playing a tween)
	is_moving = true
	
	# find corresponding tile in the tilemap => use it to get the position
	var cell_pos = tilemap.map_to_world(TILEMAP_POS + Vector2(1,1)) + player_offset
	
	# now create a tween to move to our destination
	# (the tween object has a signal that's fired when we REACH the destination)
	var tween_duration = 0.5
	tween.interpolate_property(self, "position", 
								null, cell_pos, 
								tween_duration, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)

	tween.interpolate_property(self, "modulate", 
								null, Color(1.0, 1.0, 1.0), 
								0.5, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)

func move_forward(forward):
	# find the right vector that corresponds with the direction we're facing
	var temp_dir = Vector2.ZERO
	if FORWARD_DIR == 0:
		temp_dir = Vector2(1,0)
	elif FORWARD_DIR == 1:
		temp_dir = Vector2(0,1)
	elif FORWARD_DIR == 2:
		temp_dir = Vector2(-1, 0)
	elif FORWARD_DIR == 3:
		temp_dir = Vector2(0,-1)
	
	var temp_pos = TILEMAP_POS + temp_dir*forward
	
	###
	# CHECK IF WE'RE ALLOWED TO MOVE
	#  => Check for a tilemap cell in that direction
	#  => Check for a player in that direction
	# If not, break out of this function
	###
	var wanted_cell = tilemap.get_cell(temp_pos.x, temp_pos.y)
	
	# If there's something here, we can't move!
	# TO DO: Maybe need a more specific check, when there will be things I can pass through??
	if wanted_cell > -1:
		return
	
	# Go through all "obstacles" (which includes players)
	var obstacle_found = false
	for obj in get_tree().get_nodes_in_group("Obstacles"):
		if obj == self:
			continue
		
		# if the object is within the same tilemap ...
		if obj.tilemap == tilemap:
			# and it shares x and y coordinates
			var tilemap_pos = tilemap.world_to_map(obj.get_position())
			if tilemap_pos.x == temp_pos.x and tilemap_pos.y == temp_pos.y:
				obstacle_found = true
				break
	
	if obstacle_found:
		return
	
	###
	# ACTUALLY MOVE
	###
	
	# update the actual tilemap position
	TILEMAP_POS = temp_pos
	
	# disable moving (while we're moving/playing a tween)
	is_moving = true
	
	# find corresponding tile in the tilemap => use it to get the position
	var cell_pos = tilemap.map_to_world(TILEMAP_POS) + player_offset
	
	# now create a tween to move to our destination
	# (the tween object has a signal that's fired when we REACH the destination)
	var tween_duration = 0.5
	tween.interpolate_property(self, "position", 
								null, cell_pos, 
								tween_duration, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)

	# start the tween
	tween.start()

# I'm using some trickery here
# When you fall down, there's a tween that takes care of the position, BUT there's a second "meaningless" tween
# This tween has half the time. When it finishes, that's when it updates the player's height (and moves it around to the proper location)
# That tween calls this function
func update_height():
	print("Should update height")
	
	# update the actual tilemap position
	TILEMAP_POS += Vector2(1,1)
	
	# decrease our height
	CUR_HEIGHT -= 1
	
	var new_tilemap = get_node("/root/Node2D/Level" + str(CUR_HEIGHT))
	tilemap = new_tilemap

	# and become a child of the new tilemap
	get_parent().remove_child(self)
	new_tilemap.add_child(self)

func _on_Tween_tween_completed(object, key):
	# if this was a position tween ... (aka movement)
	if key == ":position":
		# ... reset movement variable
		is_moving = false
	elif key == ":modulate":
		update_height()
