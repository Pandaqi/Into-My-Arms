extends CanvasLayer

onready var container = $Control/MarginContainer/ColorRect/CenterContainer/VBoxContainer

var gameover_texts = ["Oh ye of little faith ...", 
					  "Try again, I have faith in you!",
					  "Game over, but there's no limit on trying again"]

func display_screen(did_we_win):
	# pause the game
	get_tree().paused = true
	
	# display this screen
	get_node("Control").set_visible(true)
	
	# if the player won ...
	if did_we_win:
		# set the right text
		container.get_node("ResultText").set_text("You solved the puzzle!")
	
	# if the player lost ...
	else:
		# set the right text
		var rand_text = gameover_texts[ randi() % gameover_texts.size() ]
		
		container.get_node("ResultText").set_text(rand_text)
		
		# remove the next level button
		container.get_node("Next").set_visible(false)

func _on_Next_pressed():
	print("TO DO: Load next level")
	pass # Replace with function body.

func _on_Retry_pressed():
	# reload the current scene
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_Menu_pressed():
	print("TO DO: Go back to main menu")
	pass # Replace with function body.
