extends Node

var prev_camera_pos = null
var is_retry = false

var cur_level = 0
var play_intro = false

var max_levels = 13
var soundfx_level = 0

# Checks if a save file exists
# If not => creates one
# If so => grab current level
func check_save_file():
	var check_file = File.new()
	if not check_file.file_exists("user://savegame.save"):
		var new_game_dict = { "cur_level": 0 }
		
		cur_level = 0
		play_intro = true
		
		var write_save_game = File.new()
		write_save_game.open("user://savegame.save", File.WRITE)
		write_save_game.store_line(to_json(new_game_dict))
		write_save_game.close()
	else:
		# Retrieves our current level (for starting the game from the main screen)
		var save_game = File.new()
		save_game.open("user://savegame.save", File.READ)
		var content = parse_json(save_game.get_as_text())
		save_game.close()
		
		cur_level = content.cur_level

func set_cur_level(lvl):
	cur_level = lvl

func get_cur_level():
	return cur_level

func set_soundfx_level(lvl):
	soundfx_level = lvl

func get_soundfx_level():
	return soundfx_level

# Saves your progress
# If you finished a new level, unlocks the next level
func save_progress(level_num):
	# load old data
	var save_game = File.new()
	save_game.open("user://savegame.save", File.READ)
	var content = parse_json(save_game.get_as_text())
	save_game.close()
	
	print(level_num)
	print(content["cur_level"])
	
	# increment level counter (if we just finished our current level)
	# (I set it to the next level number, because that allows me to test it more easily)
	# (Using equality ( == ) and incrementing would work just fine here)
	if level_num >= content["cur_level"]:
		content["cur_level"] = level_num + 1
	
	var write_save_game = File.new()
	write_save_game.open("user://savegame.save", File.WRITE)
	write_save_game.store_line(to_json(content))
	write_save_game.close()
	
	# update the cur level counter here
	cur_level += 1

func set_prev_camera_pos(pos):
	prev_camera_pos = pos

func get_prev_camera_pos():
	return prev_camera_pos

func set_retry(val):
	print("Retry? ", val)
	is_retry = val

func is_retry():
	return is_retry

func get_device():
	#return "Android"
	return OS.get_name()
