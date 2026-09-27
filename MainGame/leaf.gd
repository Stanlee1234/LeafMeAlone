extends Area2D

@export var fall_speed: float = 150.0
@export var sway_speed: float = 3.0
@export var sway_amount: float = 50.0
@export var sway_tilt_strength: float = 0.35

var time_passed: float = 0.0
var initial_x: float = 0.0
var base_rotation: float = 0.0
var is_gold: bool = false
@export var gold_texture: Texture2D = preload("res://Assets/mapleFlowerGold.png")

func _ready() -> void:
	sway_amount = Global.stats.get("leaf_sway", sway_amount)
	Global.stat_updated.connect(update_sway)

	var gold_chance: float = Global.stats.get("gold_leaf_chance", 0.0)
	if gold_chance > 0.0 and randf() < gold_chance:
		is_gold = true
		var spr = get_node_or_null("Sprite2D")
		if spr and gold_texture:
			spr.texture = gold_texture

	initial_x = global_position.x
	base_rotation = randf_range(-PI, PI)
	rotation = base_rotation
	time_passed = randf_range(0.0, TAU)

func _process(delta: float) -> void:
	global_position.y += fall_speed * delta
	
	time_passed += delta * sway_speed
	global_position.x = initial_x + sin(time_passed) * sway_amount
	
	rotation = base_rotation + cos(time_passed) * sway_tilt_strength
	
	if global_position.y > 1100:
		queue_free()

func update_sway(upgrade, value) -> void:
	if upgrade == "leaf_sway":
		sway_amount = value
