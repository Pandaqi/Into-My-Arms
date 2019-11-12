extends Node2D

onready var tw = $Tween
onready var cur_active_screen = $Play

func _ready():
	# check the save file => creates one if needed
	
	# start fullscreen
	OS.window_fullscreen = true

func _on_Play_pressed():
	# Switch to current level ( = latest level we unlocked)
	get_tree().change_scene("res://Levels/Level" + str(Global.get_cur_level()) + ".tscn")

func _on_Settings_pressed():
	switch_screen($Settings)

func switch_screen(new_screen):
	# remove current screen
	if cur_active_screen != null:
		tw.interpolate_property(cur_active_screen.get_node('Control'), "modulate",
								Color(1,1,1,1.0), Color(1,1,1,0.0),
								0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		tw.start()
	
	# show new screen
	new_screen.get_node("Control").set_visible(true)
	tw.interpolate_property(new_screen.get_node("Control"), "modulate",
							Color(1,1,1,0.0), Color(1,1,1,1.0),
							0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tw.start()
	
	cur_active_screen = new_screen

func _on_CloseSettings_pressed():
	switch_screen($Play)

func _on_Quit_pressed():
	get_tree().quit()

func _on_Tween_tween_completed(object, key):
	if key == ":modulate" and object.get_parent() != cur_active_screen:
		object.set_visible(false)


