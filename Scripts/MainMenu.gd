extends Node2D

onready var tw = $Tween
onready var cur_active_screen = $Play

var config_file_path = "user://config.cfg"
onready var level_select_node = $Play/Control/VBoxContainer/HBoxContainer/CenterContainer3/LevelSelect
onready var level_button_scene = preload("res://LevelButton.tscn")
onready var level_select_grid = $LevelSelect/Control/VBoxContainer/MarginContainer/ScrollContainer/GridContainer

var configFile = null

func _ready():
	randomize()
	
	# LINK: Very good post on Godot ConfigFiles
	#		https://godotengine.org/qa/315/saving-loading-files-there-any-build-file-parsing-can-use-how
	
	# Load ConfigFile
	configFile = ConfigFile.new() 
	configFile.load(config_file_path) 
	
	# set sliders (ambient sound and sound fx)
	var ambient_slider_val = configFile.get_value("Settings", "AmbientSlider") 
	var ambient_slider_node = $Settings/Control/CenterContainer/VBoxContainer/AmbientSound/AmbientSlider
	
	if ambient_slider_val != null:
		ambient_slider_node.set_value(ambient_slider_val)
		
		# actually set audio levels based on slider
		GlobalBackgroundAudio.volume_db = ambient_slider_val
	
	var soundfx_slider_val = configFile.get_value("Settings", "SoundSlider") 
	var soundfx_slider_node = $Settings/Control/CenterContainer/VBoxContainer/SoundFX/SoundFXSlider
	
	if soundfx_slider_val != null:
		Global.set_soundfx_level(soundfx_slider_val)
		soundfx_slider_node.set_value(soundfx_slider_val)
	
	var fullscreen_val = configFile.get_value("Settings", "Fullscreen")
	if fullscreen_val != null:
		OS.window_fullscreen = fullscreen_val
		$Settings/Control/CenterContainer/VBoxContainer/Fullscreen/Fullscreen.pressed = fullscreen_val
	else:
		OS.window_fullscreen = true
	
	# remove fullscreen settings on mobile
	if Global.get_device() == "Android":
		$Settings/Control/CenterContainer/VBoxContainer/Fullscreen.hide()
	
	# check if save file exists
	# => if so, get current level from it
	# => if not, create it
	Global.check_save_file()
	
	# Check if we have at least ONE level finished => display level select screen if so
	var cur_level = Global.get_cur_level()
	
	# Load "level select" buttons into container
	var number_of_levels = Global.max_levels
	if cur_level > 0:
		for i in range(number_of_levels):
			var new_button = level_button_scene.instance()
			new_button.get_node("Label").set_text( str(i+1) )
			
			# modulate buttons randomly, just for fun
			var rand_col = Color.from_hsv(rand_range(0, 360), rand_range(0.25, 0.75), rand_range(0.85, 0.95))
			new_button.modulate = rand_col
			
			new_button.get_node("Label").set('custom_colors/font_color', rand_col.darkened(0.6))
			
			if i > cur_level:
				new_button.disabled = true
				new_button.modulate.a = 0.25
			else:
				new_button.base_modulate = rand_col

			
			level_select_grid.add_child(new_button)
			
			get_node("/root/Node2D/ScaleManager").register_node_for_scaling(new_button)
			get_node("/root/Node2D/ScaleManager").register_node_for_scaling(new_button.get_node("Label"))
			
			new_button.connect("pressed", self, "_on_LevelButton_pressed", [i])
		
	# or hide level select button altogether
	else:
		level_select_node.modulate.a = 0.0
		level_select_node.disabled = true

# If a level button is pressed, load the corresponding scene!
func _on_LevelButton_pressed(which_btn):
	Global.set_cur_level(which_btn)
	get_tree().change_scene("res://Levels/Level" + str(which_btn) + ".tscn")

func _on_Play_pressed():
	var cur_level = Global.get_cur_level()
	if cur_level == 0 and Global.play_intro:
		get_tree().change_scene("res://IntroAnimation.tscn")
	else:
		# Switch to current level ( = latest level we unlocked)
		get_tree().change_scene("res://Levels/Level" + str(cur_level) + ".tscn")

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

func _on_LevelSelect_pressed():
	switch_screen($LevelSelect)


func _on_Quit_pressed():
	get_tree().quit()

func _on_Tween_tween_completed(object, key):
	if key == ":modulate" and object.get_parent() != cur_active_screen:
		object.set_visible(false)

func _on_AmbientSlider_value_changed(value):
	# Add values to file 
	configFile.set_value("Settings","AmbientSlider", value) 
	
	# actually set audio levels based on slider
	GlobalBackgroundAudio.volume_db = value
	
	# Save file 
	configFile.save(config_file_path)

func _on_SoundFXSlider_value_changed(value):
	# Add values to file 
	configFile.set_value("Settings","SoundSlider", value) 
	
	Global.set_soundfx_level(value)
	
	# Save file 
	configFile.save(config_file_path)

func _on_Fullscreen_toggled(button_pressed):
	configFile.set_value("Settings", "Fullscreen", button_pressed)
	configFile.save(config_file_path)
	
	OS.window_fullscreen = button_pressed



