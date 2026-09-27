class_name SceneController
extends Node2D

@onready var camera_2d: Camera2D = $Camera2D

@export var pop_sound: AudioStream = preload("res://Assets/pop_3.wav")
var sfx_player: AudioStreamPlayer

const SCREEN_HEIGHT: float = 600.0
const TRANSITION_TIME: float = 2.0

var is_underground: bool = false
var is_game_active: bool = false
var tween: Tween

func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = pop_sound
	add_child(sfx_player)

	start_ready_sequence()

func play_pop(pitch: float = 1.0) -> void:
	if sfx_player and pop_sound:
		sfx_player.pitch_scale = pitch
		sfx_player.play()

func start_ready_sequence() -> void:
	Global.timer_reset.emit()
	is_game_active = false
	var label: Label = %CountdownLabel
	
	label.pivot_offset = label.size / 2.0
	label.show()
	label.modulate.a = 1.0
	label.text = "READY?"
	
	play_pop(1.0)
	
	label.scale = Vector2(0.5, 0.5)
	var t1 = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t1.tween_property(label, "scale", Vector2(1.2, 1.2), 0.3)
	
	await get_tree().create_timer(1.5).timeout

	label.text = "GO!"
	
	play_pop(1.3)
	
	label.scale = Vector2(0.6, 0.6)
	var t2 = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t2.tween_property(label, "scale", Vector2(1.5, 1.5), 0.2)

	is_game_active = true

	await get_tree().create_timer(1.5).timeout
	var fade_tween = create_tween()
	fade_tween.tween_property(label, "modulate:a", 0.0, 0.3)
	await fade_tween.finished
	label.hide()

func end_round() -> void:
	if not Global.is_underground and is_game_active:
		play_pop(0.9)
		switch_view()

func switch_view() -> void:
	if tween and tween.is_running():
		tween.kill()

	Global.notify_view_changed(!Global.is_underground)

	if Global.is_underground:
		is_game_active = false
		Global.coffee_active = false
		Global.coffee_ended.emit()
		get_tree().call_group("leaves", "queue_free")

	var target_y = SCREEN_HEIGHT if Global.is_underground else 0.0

	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera_2d, "position:y", target_y, TRANSITION_TIME)

	if not Global.is_underground:
		tween.finished.connect(func():
			start_ready_sequence()
		, CONNECT_ONE_SHOT)
