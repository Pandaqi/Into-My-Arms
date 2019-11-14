extends Node2D

var GRID = {}
var tile_offset = Vector2(0, 32)

var TILE_DICT = ["TileGround.tscn", "TileMirror.tscn", "TileMirror2.tscn", "TileMirrorClosed.tscn"]
var TILE_SCENES = []
var NUM_LEVELS

var SORT_DEPTH = 0
var ALL_SPRITES = []

var update_depth_sort = false
export (int) var cur_level = 0

# for caching a reference to both players
var players = []

# Converts vector3 to a string-version that is better for dictionaries
# (Plain vector3s give precision errors)
func v3_to_index(v3):
	return str(int(round(v3.x))) + "," + str(int(round(v3.y))) + "," + str(int(round(v3.z)))

func _ready():
	###
	# Preload all the tiles we need
	###
	for tile in TILE_DICT:
		TILE_SCENES.append( load("res://Tiles/" + tile) )
	
	###
	# Determine how many "height levels" this stage has
	#
	# We don't count the reference tilemap, because that isn't in the TileMaps group
	###
	NUM_LEVELS = get_tree().get_nodes_in_group("TileMaps").size()
	
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
			var new_block = TILE_SCENES[cell_type].instance()
			new_block.set_position( cur_tilemap.map_to_world(Vector2(cell.x,cell.y)) + tile_offset )
			
			# set cell type and position
			new_block.CELL_TYPE = cell_type
			new_block.TILEMAP_POS = Vector3(cell.x, cell.y, z)

			# modulate this block in accordance with height
			if cell_type == 0:
				var height_col_diff = ((z + 1.0) / NUM_LEVELS)
				new_block.modulate = Color(height_col_diff, height_col_diff, height_col_diff)
			
			# add block to the world
			add_child(new_block)
			
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
	for player in players:
		player.initialize(GRID)
		ALL_SPRITES.append(player)
	
	for z in range(NUM_LEVELS):
		get_node("Level" + str(z)).queue_free()
	
	###
	# Once ALL sprites have loaded, perform a single depth sort
	# to make the first entrance into the level look the proper way
	perform_depth_sort()
	
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
	
	# NOTE: Transforming coordinates isn't really necessary => camera average position, and players will be at the same position anyway!
	# + (pos - get_node("Camera").get_position() )
	
	# hand all the information (and control) over to the pause screen
	get_node("PauseScreen").display_screen(did_we_win, pos, obj)

func project_to_iso(x, y, z):
	return Vector2(x - y, (x / 2) + (y / 2) - z)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
