extends Node2D

@onready var back_button: Button = get_node_or_null("Button")
var sfx_player: AudioStreamPlayer

func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	if back_button:
		back_button.mouse_entered.connect(_on_button_hover)

func _on_button_hover() -> void:
	if sfx_player:
		sfx_player.stream = preload("res://Assets/tree_hover.wav")
		sfx_player.pitch_scale = 1.15
		sfx_player.play()

func _on_button_pressed() -> void:
	if sfx_player:
		sfx_player.stream = preload("res://Assets/tree_upgrade.wav")
		sfx_player.pitch_scale = 1.0
		sfx_player.play()
	var controller = get_tree().root.find_child("SceneController", true, false) as SceneController
	if controller:
		controller.switch_view()
