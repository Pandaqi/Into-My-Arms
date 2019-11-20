extends Node2D

var GRID = {}
var tile_offset = Vector2(0, 32)

onready var basic_tile = preload("res://Tiles/TileBasic.tscn")
var mirror_cells = [8,9,10,11,12,13,   
					16,17,18,19,20,21,
					24,25,26,27,28,29,30,31,
					32,33,34,35,36,37,38,39]
var interactive_mirror_cells = [16,17,18,19,20,21,
								24,25,26,27,28,29,30,31]
var upwards_mirror_cells = [24,25,26,27,   32,33,34,35]
var downwards_mirror_cells = [28,29,30,31,   36,37,38,39]

var mirror_normals = [Vector2(1,1), Vector2(1,-1), 
					  Vector2(1,1), Vector2(-1,1), Vector2(-1,-1), Vector2(1,-1),
					  Vector2(1,1), Vector2(1,-1),
					  Vector2(1,1), Vector2(1,-1),
					  Vector2(1,1), Vector2(1,-1),
					
					  Vector2(1,0), Vector2(0,1), Vector2(-1,0), Vector2(0,-1),
					  Vector2(1,0), Vector2(0,1), Vector2(-1,0), Vector2(0,-1),
					
					  Vector2(1,0), Vector2(0,1), Vector2(-1,0), Vector2(0,-1),
					  Vector2(1,0), Vector2(0,1), Vector2(-1,0), Vector2(0,-1)]
					
var mirror_closed = [false, false, 
					 true, true, true, true, 
					 false, false, 
					 false, false, 
					 false, false,
					
					 true,true,true,true,
					 true,true,true,true,
					
					 true, true, true, true,
					true, true, true, true]

var button_cells = [2,3,4]
var elevator_cells = [5,6,7]

var TILE_SCENES = []
var NUM_LEVELS

var SORT_DEPTH = 0
var ALL_SPRITES = []

var update_depth_sort = false
export (int) var cur_level = 0

# for caching a reference to both players
var players = []

# in this game, there are only three possible colors for interactive objects
# meaning there are only three possible connections between objects (dark blue, red, light blue)
# these connections are saved in this array for quick access
var button_objects = [[], [], []]

# these parameters are given to _whatever object_ each button is linked to
# (for example: elevators use this to determine their min/max movement height)
export (Array) var button_parameters = [Vector2(0,1), Vector2(0,1), Vector2(0,1)]

# move axes for elevators/platforms in the level (0 = X-axis, 1 = Y-axis, 2 = Z-axis)
export (Array) var elevator_move_axes = [2, 2, 2]

export (bool) var lights_enabled = false
var lights_list = [Vector3(3, 2, 1)]

# Converts vector3 to a string-version that is better for dictionaries
# (Plain vector3s give precision errors)
func v3_to_index(v3):
	return str(int(round(v3.x))) + "," + str(int(round(v3.y))) + "," + str(int(round(v3.z)))

func _ready():
	###
	# Preload all the tiles we need
	# NOT NECESSARY ANYMORE
	###
#	for tile in TILE_DICT:
#		TILE_SCENES.append( load("res://Tiles/" + tile) )
	
	Global.set_cur_level(cur_level)
	
	###
	# Determine how many "height levels" this stage has
	#
	# We don't count the reference tilemap, because that isn't in the TileMaps group
	###
	NUM_LEVELS = get_tree().get_nodes_in_group("TileMaps").size()
	
	# remove levels without any tiles in them (can happen on flat levels)
	for z in range(NUM_LEVELS):
		if get_node("Level" + str(z)).get_used_cells().size() <= 0:
			NUM_LEVELS -= 1
	
	###
	# If lights are enabled ...
	# Check 
	
	###
	# Build the game grid
	#
	# We loop through all the tilemaps/objects we have in the scene,
	# and save their position in a 3D grid,
	# which allows very quick and easy access during the level
	###

	for z in range(NUM_LEVELS):
		# get all the used cells within this map
		var cur_tilemap = get_node("Level" + str(z))
		var used_cells = cur_tilemap.get_used_cells()
		
		# for each cell ...
		for cell in used_cells:
			var cell_type = cur_tilemap.get_cell(cell.x, cell.y)
			
			# instantiate the correct scene
			# and add that to the world
			var new_block = basic_tile.instance()
			new_block.set_position( cur_tilemap.map_to_world(Vector2(cell.x,cell.y)) + tile_offset )
			
			# this is a grass cell!
			if cell_type == 1:
				# randomly swap it for different gras cells
				var rand_index = randi() % 3
				var grass_cells = [1,14,15,22,23]
				
				cell_type = grass_cells[rand_index]
				
				
				# check tile above
				# if it's a mirror, use default grass (without anything sticking out)
				if (z+1) < NUM_LEVELS:
					var above_tilemap = get_node("Level" + str(z + 1))
					var cell_above = above_tilemap.get_cell(cell.x - 1, cell.y - 1)
					
					if cell_above in mirror_cells:
						cell_type = 22
			
			# set block to correct frame
			new_block.frame = cell_type
			
			# attach script (if needed)
			# and set other parameters
			if cell_type in mirror_cells:
				# mirrors have their own script (which calculates reflections and stuff)
				new_block.script = load("res://Scripts/TileMirror.gd")
				
				# add it to the Mirrors group
				new_block.add_to_group("Mirrors")
				
				# set mirror normal and if it's closed or not (for proper reflection)
				new_block.closed = mirror_closed[ mirror_cells.find(cell_type) ]
				new_block.mirror_normal = mirror_normals[ mirror_cells.find(cell_type) ]
				
				# check if it's an interactive mirror
				if cell_type in interactive_mirror_cells:
					var ind = 0
					
					# to keep assets/game simplified, interactive mirrors are always red (aka interactive index 1)
					if cell_type in upwards_mirror_cells or cell_type in downwards_mirror_cells:
						ind = 1
					else:
						# if so, get the button index it should connect to
						ind = floor(interactive_mirror_cells.find(cell_type) * 0.5)
					
					button_objects[ind].append(new_block)
				
				# upwards/downwards mirrors do something special
				# they pretend the light is in a 2D plane, where the Y axis is the Z axis
				if cell_type in upwards_mirror_cells:
					new_block.vertical = true
					new_block.vertical_value = 1
				
				if cell_type in downwards_mirror_cells:
					new_block.vertical = true
					new_block.vertical_value = -1
				
				# TO DO: Attach child sprite for displaying reflection
			
			elif cell_type in elevator_cells:
				# elevators just need to save the button they should be connected with
				var ind = elevator_cells.find(cell_type)
				
				button_objects[ind].append(new_block)
				
				# and they get their own script
				new_block.script = load("res://Scripts/TileElevator.gd")
				new_block.movement_bounds = button_parameters[ind]
				new_block.movement_axis = elevator_move_axes[ind]
			
			###
			# TO DO: Assign correct variables/settings to the script
			# Mirrors: 
			#  => set mirror/reflection vector (based on frame), 
			#  => put into group "Mirrors"
			#  => attach child sprite that displays reflection??
			###
			
			
			# set cell type and position
			new_block.CELL_TYPE = cell_type
			new_block.TILEMAP_POS = Vector3(cell.x, cell.y, z)

			# modulate this block in accordance with height
			if true: #cell_type == 0:
				var height_col_diff = ((z + 1.0) / NUM_LEVELS)
				var modulate_range = Vector2(0.5, 1.0)
				var v = modulate_range.x + height_col_diff * (modulate_range.y - modulate_range.x)
				new_block.modulate = Color(v,v,v)
				
				new_block.base_modulate = Color(v,v,v)
			
			# add block to the world
			add_child(new_block)
			
			new_block.update_light_value()
			
			# save a reference to this block (for depth sorting)
			ALL_SPRITES.append(new_block)
			
			# finally, save the object in the grid
			GRID[v3_to_index(Vector3(cell.x, cell.y, z))] = new_block
	
	###
	# Once we have the grid ...
	#  => The players must be added to the Ysort as well
	#  => We no longer need the tilemaps (we only keep a reference map for easy coordinate calculation)
	###
	players = get_tree().get_nodes_in_group("Players")
	
	# if players are in the wrong order, switch them around
	if players[0].PLAYER_NUM == 1:
		players.invert()
	
	for player in players:
		var other_player = players[ (player.PLAYER_NUM + 1) % 2 ]
		player.initialize(GRID, other_player, button_cells, elevator_cells, mirror_cells)
		ALL_SPRITES.append(player)
	
	for z in range(NUM_LEVELS):
		get_node("Level" + str(z)).queue_free()
	
	###
	# Once ALL sprites have loaded, perform a single depth sort
	# to make the first entrance into the level look the proper way
	perform_depth_sort()
	update_sight_lines()
	
	###
	# Lastly, pause the tree
	#
	# Why? Because we want to create a zooming in effect, as if we "move to the new level"
	# We do NOT use this zooming effect on a level retry, as that would just annoy the player
	###
	get_node("PauseScreen").move_camera_start()

# The main script is mostly responsible for depth sorting the world
func _process(delta):
	# if ANYTHING is moving, the depth sort needs to be updated
	if update_depth_sort:
		perform_depth_sort()
		update_depth_sort = false

func update_sight_lines():
	for mirror in get_tree().get_nodes_in_group('Mirrors'):
		mirror.hide_reflection()
	
	for player in players:
		player.determine_line_of_sight()

func perform_depth_sort():
	# first, check which sprites are behind other sprites
	var behind_index
	for s1 in ALL_SPRITES:
		behind_index = 0
	
		for s2 in ALL_SPRITES:
			if s1 != s2:
				if (s2.x_bounds.x < s1.x_bounds.y and s2.y_bounds.x < s1.y_bounds.y and s2.z_bounds.x < s1.z_bounds.y):
					s1.sprites_behind[behind_index] = s2
					behind_index += 1
	
		s1.sorting_visited = false
	
	# then reset sort depth to zero
	# and visit all nodes to create a (topological) graph
	SORT_DEPTH = 0
	for s in ALL_SPRITES:
		visit_node(s)

func visit_node(s):
	# if this node has NOT been visited yet ...
	if not s.sorting_visited:
		# remember now that we visited
		s.sorting_visited = true
		
		# loop through sprites behind it
		var counter = 0
		for sprite in s.sprites_behind:
			# if this is null, we've reached the end of the list for this frame
			if sprite == null:
				break

			# otherwise, visit them, which recursively sets their depth value
			# (by the time this function returns, all sprites behind this one have been considered, 
			#  so the sort_depth variable is already at the right value for setting it directly)
			else:
				visit_node(sprite)
				s.sprites_behind[counter] = null

			counter += 1
		
		# finally, set the current depth value for this tile
		# NOTE: because we set z_index directly,
		# we don't need to loop through the tiles again to sort them visually
		#  => Godot handles this for us
		s.z_index = SORT_DEPTH
		
		# s.get_node("DepthLabel").set_text(str(SORT_DEPTH))
		
		SORT_DEPTH += 1


func end_level(did_we_win, pos, obj):
	# transform position to CanvasLayer position
	pos = 0.5 * get_node("Camera").get_viewport().size
	
	obj.is_disabled = true
	obj.other_player.is_disabled = true 
	
	# NOTE: Transforming coordinates isn't really necessary => camera average position, and players will be at the same position anyway!
	# + (pos - get_node("Camera").get_position() )
	
	# hand all the information (and control) over to the pause screen
	get_node("PauseScreen").display_screen(did_we_win, pos, obj)

func project_to_iso(x, y, z):
	return Vector2(x - y, (x / 2) + (y / 2) - z)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

