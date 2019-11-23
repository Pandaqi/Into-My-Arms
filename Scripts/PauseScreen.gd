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

var players = []

var standing_player = null
var falling_player = null

var anim_center_pos = Vector2.ZERO
var play_rotating_anim = false
var anim_timestep = 0
var falling_player_start_frame = 0
var falling_player_start_rotation = 0

func display_options():
	# NOTE: This is called when the "death/win" animation is finished!
	# display the option screen (next level, retry, back to menu, etc.)
	get_node("Control").set_visible(true)

	# just to keep it clean, also hide the rest of the GUI
	if Global.get_device() == "Android":
		get_node("/root/Node2D/GUI/Player1Controls").set_visible(false)
		get_node("/root/Node2D/GUI/Player2Controls").set_visible(false)

func _process(delta):
	# if the game isn't paused, ignore our process function
	if not get_tree().paused:
		return
	
	# otherwise, if we're at the end of the level ...
	if not level_start:
		
		for tile in get_tree().get_nodes_in_group("LevelTiles"):
			tile.update_bounds()
		
		# if "falling"-tween is not playing anymore, start rotating the players around each other
		if play_rotating_anim:
			anim_timestep += delta
			
			# update position (through rotation)
			var rad_x = 32 # radius
			var rad_y = 16
			var angle = anim_timestep * 2 * PI + falling_player_start_rotation
			
			# angle = 0
			falling_player.position = Vector2(anim_center_pos.x + cos(angle) * rad_x, anim_center_pos.y + sin(angle) * rad_y)
			standing_player.position = Vector2(anim_center_pos.x + cos(angle + PI) * rad_x, anim_center_pos.y + sin(angle + PI) * rad_y)
			
			# update frames
			falling_player.frame = (falling_player_start_frame + int(ceil(anim_timestep*8))) % 8
			standing_player.frame = (falling_player.frame + 4) % 8
			
			falling_player.get_node("PosLabel").set_text(str(falling_player.TILEMAP_POS))
			standing_player.get_node("PosLabel").set_text(str(standing_player.TILEMAP_POS))
		
		if falling_player != null:
			for player in players:
				player.min_bounds = Vector3(1,1,1) * player.get_scale().x * 0.5
				player.max_bounds = Vector3(1,1,1) * player.get_scale().x * 0.5
				
				var transformed_pos = player.get_position() - Vector2(0, 32) * player.get_scale().x
				var pos_iso = get_node("/root/Node2D/EmptyTilemap").world_to_map(transformed_pos)
				
				player.TILEMAP_POS = Vector3(pos_iso.x, pos_iso.y, standing_player.TILEMAP_POS.z)
				
				#
				# NOTE: This is just a hack
				# I had trouble getting depth sorting to work with the falling animation => often, one of the players would render behind a falling blok
				# As such, we only update player bounds once only the players are left (and the single tile they stand on)
				if get_node("/root/Node2D").ALL_SPRITES.size() <= 3:
					player.update_bounds()
		
		# keep updating the depth sort (during the falling animation)
		get_node("/root/Node2D").perform_depth_sort()


#
# @parameter did_we_win => true if the player won, false if they lost
# @parameter pos => the position of the player, used for animating/focusing in the game-over-animation
# @parameter obj => the object ( = player) that caused the win/loss
#
func display_screen(did_we_win, pos, obj):
	# pause the game
	get_tree().paused = true
	
	players = get_tree().get_nodes_in_group("Players")
	
	###
	# LEVEL FALLING AWAY ANIMATION
	#
	# By making the level blocks fall away when you lose, I solve several visual problems
	# And of course it looks nice
	###
	
	# quickly save player positions
	# (more efficient for checking if a tile is below them => might make this even more general though)
	var player_pos_below = []
	for player in players:
		player_pos_below.append( player.TILEMAP_POS + Vector3(1, 1, -1) )
	
	# loop through all level tiles
	for tile in get_tree().get_nodes_in_group("LevelTiles"):
		# check if player is standing on top of this
		var pos_3d = tile.TILEMAP_POS
		if pos_3d == player_pos_below[0] or pos_3d == player_pos_below[1]:
			continue
		
		# get their HEIGHT
		var temp_height = pos_3d.z
		
		# make it fall down, but DELAY it based on height
		# also add some randomness to the delay (otherwise tiles fall down as one giant block)
		var delay = temp_height * 0.3 + rand_range(0.0, 0.3)
		var end_pos = tile.get_position() + Vector2(0, 1280)
		
		tw.interpolate_property(tile, "TILEMAP_POS",
								null, tile.TILEMAP_POS - Vector3(0,0,20),
								1.0, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR,
								delay)
		
		tw.interpolate_property(tile, "position",
								null, end_pos,
								1.0, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR,
								delay)
		
		
		tw.start()
	
	for label in get_tree().get_nodes_in_group("InstructionLabels"):
		label.hide()
	
	# remember if we won (for use in other functions)
	win = did_we_win

	# if the player won ...
	if did_we_win:
		# remember we made progress
		Global.save_progress(get_node("/root/Node2D").cur_level)
		
		# play the particle effect (that partly obscures the bad animation here)
		var wpe = get_node("WinParticleEffect")
		wpe.show()
		wpe.set_position(pos)
		wpe.set_emitting(true)
		
		# use heart cutout animation (make visible, set position to point at player)
		var hc = get_node("HeartCutout")
		hc.set_visible(true)
		
		$AnimationPlayer.play("Heart Cutout")

		tw.interpolate_property(hc, "modulate",
								Color(1.0, 0.5, 0.5, 1.0), Color(0.5, 0.0, 0.0, 0.5),
								1.0, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
		
		tw.start()

		# set the right text
		var rand_text = gamewin_texts[ randi() % gamewin_texts.size() ]
		container.get_node("ResultText").set('custom_colors/font_color', Color(1.0, 0.8, 0.8))
		container.get_node("ResultText").set_text(rand_text)
		
		###
		# create "falling in arms" animation
		###
		
		# first, get both players (and their roles)
		falling_player = obj
		standing_player = obj.other_player
		
		falling_player.get_node("Eyes").hide()
		standing_player.get_node("Eyes").hide()
		
		# check which way the falling player is facing
		# use this to determine player positions + rotations
		var face_vec = falling_player.get_dir_vector()
		var face_vec_iso = Vector2((face_vec.x - face_vec.y)*64, (face_vec.x + face_vec.y)*32)
		
		var pos_standing = standing_player.get_position() - 0.25*face_vec_iso
		var pos_falling = pos_standing + 0.5*face_vec_iso
		
		var frame_standing = falling_player.FORWARD_DIR * 2
		var frame_falling = ((falling_player.FORWARD_DIR + 2) % 4) * 2
		
		var tween_duration = 0.5
		# scale/position/rotate the falling player
		tw.interpolate_property(falling_player, "scale",
								null, Vector2(0.5, 0.5),
								tween_duration, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
		tw.interpolate_property(falling_player, "position",
								null, pos_falling,
								tween_duration, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
		tw.interpolate_property(falling_player, "frame",
								null, frame_falling,
								tween_duration, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
		tw.interpolate_property(falling_player, "TILEMAP_POS",
								null, standing_player.TILEMAP_POS,
								tween_duration, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
		
		# scale/position/rotate the standing player
		tw.interpolate_property(standing_player, "scale",
								null, Vector2(0.5, 0.5),
								tween_duration, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
		tw.interpolate_property(standing_player, "position",
								null, pos_standing,
								tween_duration, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
		tw.interpolate_property(standing_player, "frame",
								null, frame_standing,
								tween_duration, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
		
		tw.start()
		
		
	
	# if the player lost ...
	else:
		# display exclamation mark
		# (and tween it => when tween is done, display game over menu)
		var seo = obj.display_exclamation_mark()
		
		tw.interpolate_property(seo, "scale",
												Vector2(0,0), Vector2(1,1),
												1.0, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
		
		tw.start()
		
		# set the right text
		var rand_text = gameover_texts[ randi() % gameover_texts.size() ]
		container.get_node("ResultText").set_text(rand_text)
		
		# hide and disable next level button
		container.get_node("HBoxContainer/CenterContainer2/Next").modulate.a = 0.0
		container.get_node("HBoxContainer/CenterContainer2/Next").disabled = true
		

func move_camera_start():
	# make sure the pause screen isn't visible
	$Control.hide()
	
	get_tree().paused = true
	
	# on a retry, just position camera immediately, no tweening
	var camera = get_node("/root/Node2D/Camera")
	if Global.is_retry():
		camera.offset = Vector2(0,0)
		tw.interpolate_property(camera, "offset",
							null, Vector2(0,0),
							0.1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		tw.start()
		return
	
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
	# (for if the player decides to play again, from the main menu)
	Global.set_retry(false)
	
	get_tree().paused = false
	get_tree().change_scene("res://MainMenu.tscn")

func _on_Tween_tween_completed(object, key):
	# offset only changes at start/end of level
	if key == ":offset":
		
		# if it's the start of the level ...
		if level_start:
			# ... simply save the fact that we're not at the start anymore
			level_start = false
			
			get_tree().paused = false
		
		# if it's the end of the level ...
		else:
			# save old camera pos
			Global.set_prev_camera_pos( get_node("/root/Node2D/Camera").get_position() )
			
			# load next level
			var next_level = Global.get_cur_level()
			
			# if there is no next level (we finished the game), load outro animation
			if next_level >= Global.max_levels:
				get_tree().change_scene("res://OutroAnimation.tscn")
			
			# otherwise, simply change scene
			else:
				get_tree().change_scene("res://Levels/Level" + str(next_level) + ".tscn")
	
	# frame changes are for the falling-into-arms animation
	elif key == ":frame":
		if object.PLAYER_NUM == standing_player.PLAYER_NUM:
			anim_center_pos = (falling_player.position + standing_player.position) * 0.5
			falling_player_start_frame = falling_player.frame
			
			falling_player_start_rotation = get_rotation_from_frame(falling_player.frame)
			
			play_rotating_anim = true
			get_tree().paused = true
	
	# modulate/scale changes on game win/loss
	elif key == ":modulate" or key == ":scale":
		display_options()
	
	# delete tiles when they are out of view (their falling position tween is done)
	elif key == ":position":
		if object.is_in_group("LevelTiles"):
			get_node("/root/Node2D").ALL_SPRITES.erase(object)
			object.queue_free()

func get_rotation_from_frame(f):
	match f:
		0:
			return 1.25*PI
		
		2:
			return 1.75*PI
		
		4:
			return 0.25*PI
		
		6:
			return 0.75*PI
