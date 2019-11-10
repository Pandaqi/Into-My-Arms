extends CanvasLayer

onready var players = get_tree().get_nodes_in_group("Players")

func _ready():
	###
	# Here we turn certain tutorial/interface parts on/off
	# based on the PLATFORM/OS on which the game is running
	###
	var platform = OS.get_name()
	
	# We ONLY want to see the mobile controls on actual mobile screens
	if platform != "Android":
		$Player1Controls.hide()
		$Player2Controls.hide()
	
	# But if we're on mobile, we DON't want to see the keyboard controls!
	else:
		get_node("/root/Node2D/Player1ControlInstructions").hide()
		get_node("/root/Node2D/Player2ControlInstructions").hide()

###
# Button signals for player 1 (rotate and move)
###
func _on_Left1_pressed():
	players[0].rotate(-1)

func _on_Forward1_pressed():
	players[0].move_forward(1)

func _on_Reverse1_pressed():
	players[0].move_forward(-1)

func _on_Right1_pressed():
	players[0].rotate(1)

###
# Button signals for player 2 (rotate and move)
###
func _on_Left2_pressed():
	players[1].rotate(-1)

func _on_Forward2_pressed():
	players[1].move_forward(1)

func _on_Reverse2_pressed():
	players[1].move_forward(-1)

func _on_Right2_pressed():
	players[1].rotate(1)
