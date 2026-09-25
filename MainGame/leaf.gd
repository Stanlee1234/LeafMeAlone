extends Area2D

@export var fall_speed: float = 150.0
@export var sway_speed: float = 3.0
@export var sway_amount: float = 50.0

var time_passed: float = 0.0
var initial_x: float = 0.0

func _ready() -> void:
	initial_x = global_position.x
	# Optional: Randomize scale or rotation for variety
	#rotation = randf() * PI * 2

func _process(delta: float) -> void:
	# Move down the screen
	global_position.y += fall_speed * delta
	
	# Add a gentle side-to-side drift (sway)
	time_passed += delta * sway_speed
	global_position.x = initial_x + sin(time_passed) * sway_amount
	
	# Clean up if it falls off the bottom of the screen
	if global_position.y > 1100: # Adjust based on your screen height
		queue_free()
