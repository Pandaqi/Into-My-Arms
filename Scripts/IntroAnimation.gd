extends Control

func _ready():
	get_tree().paused = false

func stop_audio():
	GlobalBackgroundAudio.stop()

func next_scene():
	GlobalBackgroundAudio.play()
	get_tree().change_scene("res://Levels/Level0.tscn")

func back_to_main():
	GlobalBackgroundAudio.play()
	get_tree().change_scene("res://MainMenu.tscn")
