extends Node2D

var start_point = null
var end_point = null

func create_view_line(start_point, end_point):
	self.start_point = start_point
	self.end_point = end_point
	
	update()

func _draw():
	if start_point != null and end_point != null:
		draw_line( start_point, end_point, Color(255, 0, 0), 10)
