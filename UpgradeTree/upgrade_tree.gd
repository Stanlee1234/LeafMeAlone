extends Node2D

func _on_button_pressed() -> void:
	var controller = get_tree().root.find_child("SceneController", true, false) as SceneController
	if controller:
		controller.switch_view()
