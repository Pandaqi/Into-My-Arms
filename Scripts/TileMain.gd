extends Sprite

var TILEMAP_POS = Vector3.ZERO
var CELL_TYPE = 0

var min_bounds = Vector3(0.5, 0.5, 0.5)
var max_bounds = Vector3(0.5, 0.5, 0.5)

var x_bounds
var y_bounds
var z_bounds

var sprites_behind = []
var sorting_visited = false

var GRID = null

func update_bounds():
	var height = TILEMAP_POS.z
	
	x_bounds = Vector2((TILEMAP_POS.x + height) - min_bounds.x, (TILEMAP_POS.x + height) + max_bounds.x)
	y_bounds = Vector2((TILEMAP_POS.y + height) - min_bounds.y, (TILEMAP_POS.y + height) + max_bounds.y)
	z_bounds = Vector2(height - min_bounds.z, height + max_bounds.z)

func _ready():
	# TO DO: Change this to dynamically resize
	# (Now I just assume there will never be more than 50 sprites behind a tile :p)
	sprites_behind.resize(50)
	
	# when tile enters the tree, set the bounds once
	# (inheriting scripts might also call the function during the game)
	update_bounds()
	
	# cache main grid
	GRID = get_node("/root/Node2D").GRID

func v3_to_index(v3):
	return str(int(round(v3.x))) + "," + str(int(round(v3.y))) + "," + str(int(round(v3.z)))

func update_position_in_grid(new_position, old_position = null):
	# remove ourselves from the OLD position
	if not old_position == null:
		GRID.erase( v3_to_index(old_position) )
	
	# save our player number in the GRID
	# (negative values are for obstacles, positive values for tilemap tiles)
	GRID[v3_to_index(new_position)] = self

func _on_Tween_tween_completed(object, key):
	pass # Replace with function body.
