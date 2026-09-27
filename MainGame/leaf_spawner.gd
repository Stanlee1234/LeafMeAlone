extends Node2D

var leaf_scene: PackedScene = load("res://MainGame/leaf.tscn")

func spawn_leaf() -> void:
	
	var leaf = leaf_scene.instantiate() as Area2D
	var random_x = randf_range(50, 1100)
	leaf.global_position = Vector2(random_x, -50)
	
	leaf.add_to_group("leaves")
	
	var scene_root = get_tree().current_scene
	if scene_root:
		scene_root.add_child(leaf)
