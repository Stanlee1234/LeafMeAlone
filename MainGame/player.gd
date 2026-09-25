extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var score = 0
@onready var sprite_2d: Sprite2D = $Sprite2D

func _physics_process(_float) -> void:
	#Anchor the player to the bottom of the screen
	var screen_size : Vector2 = get_viewport_rect().size
	var player_height = sprite_2d.texture.get_height() * sprite_2d.scale.y
	
	position.y = screen_size.y - player_height/2.0 + 20
	
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		sprite_2d.flip_h = direction < 0
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()

func _on_area_2d_area_entered(area: Area2D) -> void:
	# This works for every single leaf, no matter what Godot renames it to!
	if area.is_in_group("leaves"):
		score += 1
		print("Caught a leaf! Score: ", score)
		area.queue_free()
