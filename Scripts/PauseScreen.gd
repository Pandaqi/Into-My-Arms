extends CanvasLayer

onready var container = $Control/VBoxContainer

var gamewin_texts = ["You solved the puzzle!", 
					 "Yes! You had faith!", 
					 "May the faith be with you",
					 "Congratulations on being smart!",
					 "That was a nice, soft landing",
					 "Problem solved!"]

var gameover_texts = ["Oh ye of little faith ...", 
					  "Try again, I have faith in you!",
					  "Game over, but there's no limit on trying again",
					  "You lost this time. But next time ...",
					  "Maybe try something else?"]

var win = false
var level_start = true
onready var tw = get_node("Tween")

func display_options():
	# NOTE: This is called when the "death/win" animation is finished!
	# display the option screen (next level, retry, back to menu, etc.)
	get_node("Control").set_visible(true)

	# just to keep it clean, also hide the rest of the GUI
	if Global.get_device() == "Android":
		get_node("/root/Node2D/GUI/Player1Controls").set_visible(false)
		get_node("/root/Node2D/GUI/Player2Controls").set_visible(false)

#
# @parameter did_we_win => true if the player won, false if they lost
# @parameter pos => the position of the player, used for animating/focusing in the game-over-animation
# @parameter obj => the object ( = player) that caused the win/loss
#
func display_screen(did_we_win, pos, obj):
	# pause the game
	get_tree().paused = true
	
	# remember if we won (for use in other functions)
	win = did_we_win

	# if the player won ...
	if did_we_win:
		# play the particle effect (that partly obscures the bad animation here)
		var wpe = get_node("WinParticleEffect")
		wpe.set_position(pos)
		wpe.set_emitting(true)
		
		# use heart cutout animation (make visible, set position to point at player)
		var hc = get_node("HeartCutout")
		hc.set_visible(true)
		hc.set_position(pos)
		
		var cur_camera_zoom = get_node("/root/Node2D/Camera").get_zoom()
		var start_scale = 10.0 / cur_camera_zoom.x * Vector2(1,1)
		var end_scale = 3.0 / cur_camera_zoom.x * Vector2(1,1)
		
		tw.interpolate_property(hc, "scale",
								start_scale, end_scale,
								1.0, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
		
		tw.interpolate_property(hc, "modulate",
								Color(1.0, 0.5, 0.5), Color(0.2, 0.0, 0.0),
								1.0, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
		
		tw.start()

		# set the right text
		var rand_text = gamewin_texts[ randi() % gamewin_texts.size() ]
		container.get_node("ResultText").set_text(rand_text)
	
	# if the player lost ...
	else:
		# display exclamation mark
		# (and tween it => when tween is done, display game over menu)
		var sea = obj.get_node("SeeingEachOther")
		sea.set_visible(true)
		
		tw.interpolate_property(sea, "scale",
												Vector2(0,0), Vector2(1,1),
												1.0, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
		
		tw.start()
		
		# set the right text
		var rand_text = gameover_texts[ randi() % gameover_texts.size() ]
		container.get_node("ResultText").set_text(rand_text)

func move_camera_start():
	var camera = get_node("/root/Node2D/Camera")
	
	# on a retry, just position camera immediately, no tweening
	if Global.is_retry():
		camera.offset = Vector2(0,0)
		tw.interpolate_property(camera, "offset",
							null, Vector2(0,0),
							0.1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		return
	
	get_tree().paused = true
	
	# tween OFFSET and POSITION
	# (camera might end with a different position in the previous level)
	
	var vp_size = get_viewport().size * camera.get_zoom().x
	
	tw.interpolate_property(camera, "offset",
							Vector2(-vp_size.x,0), Vector2(0,0),
							1.0, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	tw.interpolate_property(camera, "position",
							null, camera.find_average_position(),
							1.0, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	tw.start()

func move_camera_end():
	var camera = get_node("/root/Node2D/Camera")
	var vp_size = get_viewport().size * camera.get_zoom().x
	tw.interpolate_property(camera, "offset",
							Vector2(0,0), Vector2(vp_size.x,0),
							1.0, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	tw.start()

func _on_Next_pressed():
	# remember this is a new level, not a retry
	Global.set_retry(false)
	
	# disable cutout
	get_node("HeartCutout").set_visible(false)
	
	# remove menu
	get_node("Control").set_visible(false)
	
	# tween camera "moving to the new level"
	move_camera_end()

func _on_Retry_pressed():
	# remember this is a retry, not a new level
	Global.set_retry(true)
	
	# reload the current scene
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_Menu_pressed():
	print("TO DO: Go back to main menu")
	pass # Replace with function body.

func _on_Tween_tween_completed(object, key):
	# offset only changes at start/end of level
	if key == ":offset":
		get_tree().paused = false
		
		# if it's the start of the level ...
		if level_start:
			# ... simply save the fact that we're not at the start anymore
			level_start = false
		
		# if it's the end of the level ...
		else:
			# save old camera pos
			Global.set_prev_camera_pos( get_node("/root/Node2D/Camera").get_position() )
			
			# load next level
			print("TO DO: Actually load next level, instead of reloading current")
			
			get_tree().reload_current_scene()
	
	# scale changes on game win/loss
	elif key == ":scale":
		display_options()
