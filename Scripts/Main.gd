extends Node2D

var GRID = {}
var tile_offset = Vector2(0, 32)

var TILE_DICT = ["TileGround.tscn"]
var TILE_SCENES = []
var NUM_LEVELS

# Converts vector3 to a string-version that is better for dictionaries
# (Plain vector3s give precision errors)
func v3_to_index(v3):
	return str(int(round(v3.x))) + "," + str(int(round(v3.y))) + "," + str(int(round(v3.z)))

func _ready():
	###
	# Attach resize signal to main node
	# 
	# This is needed to make the camera zoom and control size correct for different screen sizes
	# (Tried it with controls and stretch settings, but that gave no satisfactory results) 
	###
	get_tree().get_root().connect("size_changed", self, "window_resize")
	
	# call it once, to automatically set the right settings for the current size
	window_resize()

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
	
	for y in range(NUM_LEVELS):
		# get all the used cells within this map
		var cur_tilemap = get_node("Level" + str(y))
		var used_cells = cur_tilemap.get_used_cells()
		
		# for each cell ...
		for cell in used_cells:
			var cell_type = cur_tilemap.get_cell(cell.x, cell.y)
			
			# instantiate the correct scene
			# and add that to the world
			var new_block = TILE_SCENES[cell_type].instance()
			new_block.set_position( cur_tilemap.map_to_world(Vector2(cell.x,cell.y)) + tile_offset )
			
			# set cell type as metadata
			new_block.set_meta("cell_type", cell_type)
			
			# set correct z-index
			# cell.x and cell.y are coordinates within the isometric map
			# to convert them to (fake) 3D coordinates, we only need to add the height
			new_block.z_index = (cell.x + y) + y + (cell.y + y)
			
			# modulate this block in accordance with height
			var height_col_diff = ((y+1.0) / NUM_LEVELS)
			new_block.modulate = Color(height_col_diff, height_col_diff, height_col_diff)
			
			add_child(new_block)
			
			# finally, save the object in the grid
			GRID[v3_to_index(Vector3(cell.x, y, cell.y))] = new_block
	
	###
	# Once we have the grid ...
	#  => The players must be added to the Ysort as well
	#  => We no longer need the tilemaps (we only keep a reference map for easy coordinate calculation)
	###
	for player in get_tree().get_nodes_in_group("Players"):
		player.initialize(GRID)
	
	for y in range(NUM_LEVELS):
		get_node("Level" + str(y)).queue_free()
	
	###
	# Lastly, pause the tree
	#
	# Why? Because we want to create a zooming in effect, as if we "move to the new level"
	# We do NOT use this zooming effect on a level retry, as that would just annoy the player
	###
	get_node("PauseScreen").move_camera_start()


func window_resize():
	var new_size = get_viewport().size
	
	# Update camera zoom
	var base_dim = Vector2(512, 288)
	var base_zoom = Vector2(2,2)
	var preferred_x = base_zoom.x * (base_dim.x / new_size.x)
	var preferred_y = base_zoom.y * (base_dim.y / new_size.y)
	var final_zoom = max(preferred_x, preferred_y)
	
	# EXPERIMENT: see if setting zoom to an integer works better for visual effects
	final_zoom = ceil(final_zoom)
	
	$Camera.set_zoom(Vector2(final_zoom, final_zoom))
	
	# Get the correct font size, based on screen resolution
	var preferred_font_x = new_size.x / base_dim.x
	var preferred_font_y = new_size.y / base_dim.y
	var scale_level = round( min(preferred_font_x, preferred_font_y) )
	var font_size = scale_level * 16
	var path = "res://Fonts/BasicFont" + str(font_size) + ".tres"
	
	# Update all controls to the correct positions
	for node in get_tree().get_nodes_in_group("ResizableNodes"):
		if node is Label:
			node.add_font_override("font", load(path))
		
		# container nodes will always start at scale (1,1) and just use the scale level
		elif node is Node2D:
			node.set_scale( scale_level * Vector2(1,1) )
		
		elif node is TextureButton:
			# scale minimum size of button (otherwise, button isn't clickable and doesn't center align)
			node.rect_min_size = Vector2(56, 56) * scale_level

			# scale sprite(s) that are children
			# I make all buttons 4X the (56, 56) size to support all resolutions (and keep power of 2 scales)
			for child in node.get_children():
				if child is Sprite:
					child.set_scale( scale_level * Vector2(0.25,0.25) )

	# Update player control anchoring positions (only on mobile)
	if Global.get_device() == "Android":
		$GUI/Player1Controls.set_position(Vector2(0, new_size.y))
		$GUI/Player2Controls.set_position(Vector2(new_size.x, new_size.y))

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
