extends Area2D

@export var fall_speed: float = 150.0
@export var sway_speed: float = 3.0
@export var sway_amount: float = 50.0
@export var sway_tilt_strength: float = 0.35 # Radians to tilt while swaying

var time_passed: float = 0.0
var initial_x: float = 0.0
var base_rotation: float = 0.0

func _ready() -> void:
	sway_amount = Global.stats.get("leaf_sway", sway_amount)
	Global.stat_updated.connect(update_sway)
	initial_x = global_position.x
	# Random initial orientation
	base_rotation = randf_range(-PI, PI)
	rotation = base_rotation
	# Random phase offset so clustered leaves don't sway in lockstep
	time_passed = randf_range(0.0, TAU)

func _process(delta: float) -> void:
	# Move down the screen
	global_position.y += fall_speed * delta
	
	# Side-to-side drift
	time_passed += delta * sway_speed
	global_position.x = initial_x + sin(time_passed) * sway_amount
	
	# cos(time_passed) is the velocity/direction of the sine wave
	# Leaf tilts toward the direction it's drifting, based on base orientation
	rotation = base_rotation + cos(time_passed) * sway_tilt_strength
	
	# Clean up if off bottom edge
	if global_position.y > 1100:
		queue_free()

func update_sway(upgrade, value) -> void:
	if upgrade == "leaf_sway":
		sway_amount = value
