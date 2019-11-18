tool
extends TextureButton

export (Vector2) var scale = Vector2(56, 56) setget scale_changed
export (int) var frame = 0 setget frame_changed
export (bool) var particles_enabled = true

var modulate_values = [null, null, null, null, 
					   Color(1.0, 0.0, 0.0), Color(0.0, 1.0, 0.0), Color(0.5, 0.5, 0.5), Color(230/255.0, 100/255.0, 14/255.0),
					   Color(110 / 255, 1.0, 0.0), Color(134/255.0, 134/255.0, 134/255.0), Color(1.0, 71/255.0, 71/255.0), null]

var base_modulate = Color(1.0, 1.0, 1.0)

func on_resize(val):
	scale_changed(val)
	
	if not particles_enabled:
		$Particles.hide()
		$Particles.set_emitting(false)

func scale_changed(v):
	if not has_node("Sprite"):
		return
	
	scale = v
	
	# update scale of texture button
	self.rect_min_size = scale
	
	# update scale of sprite
	$Sprite.set_scale(Vector2(scale.x / 56 / 4, scale.y / 56 / 4))
	$Sprite.set_position(Vector2(scale.x * 0.5, scale.y * 0.5))
	
	# update scale (and other settings) on the particles
	$Particles.emission_rect_extents = Vector2(scale.x / 4, 1)
	$Particles.lifetime = 4
	$Particles.set_position( Vector2(scale.x*0.5, scale.y*0.9))
	$Particles.scale_amount = scale.x / 56 / 4
	$Particles.initial_velocity = scale.y * 0.5

func frame_changed(v):
	if not has_node("Sprite"):
		return
	
	frame = v
	
	$Sprite.frame = frame
	
	var new_mod = modulate_values[frame]
	
	if new_mod != null:
		$Sprite.modulate = new_mod
		base_modulate = new_mod

func change_state(new_state):
	match new_state:
		'default':
			$Sprite.modulate.a = 0.8
			$Sprite.modulate = base_modulate
			
		'hover':
			$Sprite.modulate.a = 1.0
			$Sprite.modulate = base_modulate.lightened(0.5)

		'click':
			$Sprite.modulate.a = 1.0
			$Sprite.modulate = base_modulate.darkened(0.5)
	
	var cur_frame = $Sprite.frame
	var rotation = 0
	
	if new_state != 'default':
		rotation = 2*PI
		match cur_frame:
			4:
				rotation = 0.15*PI
			
			5:
				rotation = -0.15*PI
			
			7:
				rotation = 0
			
			8:
				rotation = 0.15*PI
	
	$Tween.interpolate_property($Sprite, "rotation",
								null, rotation, 
								0.2, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
	
	$Tween.start()

# Called when the node enters the scene tree for the first time.
func _ready():
	change_state('default')


func _on_TextureButton_mouse_entered():
	change_state('hover')

func _on_TextureButton_button_down():
	change_state('click')

func _on_TextureButton_button_up():
	change_state('hover')

func _on_TextureButton_mouse_exited():
	change_state('default')
