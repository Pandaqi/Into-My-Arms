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

var light_value = 1.0
var base_modulate = Color(1.0, 1.0, 1.0)


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

func update_light_value():
	# if lights aren't enabled don't do anything
	if not get_node("/root/Node2D").lights_enabled:
		return
	
	# otherwise, get the list of lights (which is just their position, currently)
	var lights_list = get_node("/root/Node2D").lights_list
	
	# modulate according to light value
	var light_value = 0.0
	var max_light_distance = 2
	for light in lights_list:
		var pos_3d = Vector3(TILEMAP_POS.x + TILEMAP_POS.z, TILEMAP_POS.y + TILEMAP_POS.z, TILEMAP_POS.z)
		# MANHATTAN DISTANCE: var dist = abs(pos_3d.x - light.x) + abs(pos_3d.y - light.y) + abs(pos_3d.z - light.z)
		# EUCLIDIAN DISTANCE:
		var dist = (pos_3d - light).length()
		
		# also save the light value
		light_value += max(1.0 - dist*(1.0/max_light_distance), 0)
	
	# clamp the value
	light_value = clamp(light_value, 0.15, 1.0)
	
	# apply modulation
	modulate = Color(base_modulate.r * light_value, base_modulate.g * light_value, base_modulate.b * light_value, 1.0)

func _on_Tween_tween_completed(object, key):
	pass # Replace with function body.
