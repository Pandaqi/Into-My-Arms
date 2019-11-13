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

func update_bounds():
	var height = TILEMAP_POS.z
	
	x_bounds = Vector2((TILEMAP_POS.x + height) - min_bounds.x, (TILEMAP_POS.x + height) + max_bounds.x)
	y_bounds = Vector2((TILEMAP_POS.y + height) - min_bounds.y, (TILEMAP_POS.y + height) + max_bounds.y)
	z_bounds = Vector2(height - min_bounds.z, height + max_bounds.z)

func _ready():
	# TO DO: Change this to dynamically resize
	# (Now I just assume there will never be more than 20 sprites behind a tile :p)
	sprites_behind.resize(20)
	
	# when tile enters the tree, set the bounds once
	# (inheriting scripts might also call the function during the game)
	update_bounds()
