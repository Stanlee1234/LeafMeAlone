class_name HUD
extends Control

@export var LeafAmount: Label

@onready var coffee_container: PanelContainer = $CoffeeContainer
@onready var coffee_status: Label = $CoffeeContainer/HBoxContainer/VBoxContainer/CoffeeStatus
@onready var end_round_button: Button = get_node_or_null("EndRoundButton")

var sfx_hover: AudioStream = preload("res://Assets/tree_hover.wav")
var sfx_click: AudioStream = preload("res://Assets/tree_upgrade.wav")
var audio_player: AudioStreamPlayer

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

	update_leaf_amount_label(Global.leaves)
	
	Global.leaves_changed.connect(update_leaf_amount_label)
	Global.stat_updated.connect(_on_stat_updated)
	Global.coffee_activated.connect(_on_coffee_activated)
	Global.coffee_ended.connect(_on_coffee_ended)
	Global.timer_reset.connect(_on_timer_reset)
	Global.view_changed.connect(_on_view_changed)
	
	if end_round_button:
		end_round_button.pressed.connect(_on_end_round_pressed)
		end_round_button.mouse_entered.connect(_on_end_round_hover)

	_on_view_changed(Global.is_underground)
	update_coffee_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			if not Global.is_underground and end_round_button and end_round_button.visible:
				_on_end_round_pressed()

func _process(_delta: float) -> void:
	if Global.coffee_active and coffee_status:
		coffee_status.text = "%.1fs" % max(0.0, Global.coffee_timer)

func update_leaf_amount_label(number: int) -> void:
	if LeafAmount:
		LeafAmount.text = "x " + str(number)

func _on_end_round_hover() -> void:
	if audio_player and sfx_hover:
		audio_player.stream = sfx_hover
		audio_player.pitch_scale = 1.15
		audio_player.play()

func _on_end_round_pressed() -> void:
	if audio_player and sfx_click:
		audio_player.stream = sfx_click
		audio_player.pitch_scale = 1.0
		audio_player.play()

	var controller = get_tree().root.find_child("SceneController", true, false) as SceneController
	if controller:
		controller.end_round()

func _on_view_changed(underground: bool) -> void:
	if underground:
		if end_round_button:
			end_round_button.hide()
		if coffee_container:
			coffee_container.hide()
	else:
		if end_round_button:
			end_round_button.show()
		update_coffee_ui()

func _on_stat_updated(stat_id: String, _val: float) -> void:
	if stat_id == "has_coffee":
		update_coffee_ui()

func _on_timer_reset() -> void:
	update_coffee_ui()

func _on_coffee_activated(_duration: float) -> void:
	if not coffee_container:
		return
	coffee_container.modulate = Color(1.3, 1.2, 0.6, 1.0)
	coffee_status.text = "BOOST!"
	var pop_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(coffee_container, "scale", Vector2(1.15, 1.15), 0.12)
	pop_tween.tween_property(coffee_container, "scale", Vector2.ONE, 0.12)

func _on_coffee_ended() -> void:
	update_coffee_ui()

func update_coffee_ui() -> void:
	if not coffee_container:
		return
	if Global.is_underground or not Global.has_coffee:
		coffee_container.hide()
		return
	
	coffee_container.show()
	if Global.coffee_active:
		coffee_container.modulate = Color(1.3, 1.2, 0.6, 1.0)
		coffee_status.text = "%.1fs" % max(0.0, Global.coffee_timer)
	elif Global.coffee_ready:
		coffee_container.modulate = Color(1.0, 1.0, 1.0, 1.0)
		coffee_status.text = "READY"
	else:
		coffee_container.modulate = Color(0.6, 0.6, 0.6, 0.6)
		coffee_status.text = "USED"
