extends Node2D

@export var leaf_scene: PackedScene # Drag your Leaf.tscn here in the Inspector

var spawn_timer: float = 0.0
@export var spawn_interval: float = 0.8

func _process(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_leaf()

func spawn_leaf() -> void:
	var leaf = leaf_scene.instantiate() as Area2D
	
	var random_x = randf_range(50, 1100)
	leaf.global_position = Vector2(random_x, -50)
	
	get_tree().current_scene.add_child(leaf)
