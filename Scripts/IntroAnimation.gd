extends Control

func stop_audio():
	GlobalBackgroundAudio.stop()

func next_scene():
	GlobalBackgroundAudio.play()
	get_tree().change_scene("res://Levels/Level0.tscn")
