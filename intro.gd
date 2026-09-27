extends Control

@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton

var sfx_hover: AudioStream = preload("res://Assets/tree_hover.wav")
var sfx_click: AudioStream = preload("res://Assets/tree_upgrade.wav")
var audio_player: AudioStreamPlayer

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

	if start_button:
		start_button.pressed.connect(_on_start_pressed)
		start_button.mouse_entered.connect(_on_button_hover)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
		quit_button.mouse_entered.connect(_on_button_hover)

func _on_button_hover() -> void:
	if audio_player and sfx_hover:
		audio_player.stream = sfx_hover
		audio_player.pitch_scale = randf_range(0.95, 1.05)
		audio_player.play()

func _on_start_pressed() -> void:
	if audio_player and sfx_click:
		audio_player.stream = sfx_click
		audio_player.pitch_scale = 1.05
		audio_player.play()

	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.finished.connect(func():
		get_tree().change_scene_to_file("res://MainGame/game.tscn")
	)

func _on_quit_pressed() -> void:
	if audio_player and sfx_click:
		audio_player.stream = sfx_click
		audio_player.pitch_scale = 0.95
		audio_player.play()

	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.finished.connect(func():
		get_tree().quit()
	)
