extends Area2D

enum UnlockRequirement { ANY_PARENT, ALL_PARENTS }
enum NodeState { HIDDEN, LOCKED, UNLOCKED }

@export_enum("RIGHT:1", "LEFT:-1") var card_side: int = 1
@export var card_offset_x: float = 18.0
@export var sprite_image: Texture2D

@export_group("Upgrade Info")
@export var upgrade_name: String = "Name"
@export var description: String = "Lorem Ipsum"
@export var max_level: int = 1
@export var base_cost: int = 100
@export var cost_multiplier: float = 1.5
@export var hold_duration: float = 0.8

@export_group("Stat Display")
@export var stat_id: String = "move_speed"
@export var stat_step_per_level: float = 5.0
@export var stat_suffix: String = ""

@export_group("Ending / Outro")
@export var is_final_upgrade: bool = false
@export_file("*.tscn") var target_scene: String = ""

@export_group("Tree Progression")
@export var unlocked_by_default: bool = false
@export var connected_upgrades: Array[Area2D] = []

@export_group("Prerequisites")
@export var unlock_mode: UnlockRequirement = UnlockRequirement.ANY_PARENT

var base_stat_value: float = 0.0
var current_level: int = 0
var current_cost: int = 100
var current_state: NodeState = NodeState.HIDDEN

var is_hovered: bool = false
var is_holding: bool = false
var hold_progress: float = 0.0
var is_transitioning: bool = false

var parent_nodes: Array[Area2D] = []
var connection_lines: Array[Line2D] = []
var original_icon_pos: Vector2 = Vector2.ZERO
var exit_timer: SceneTreeTimer
var card_tween: Tween
var icon_tween: Tween
var state_tween: Tween

static var sfx_hover: AudioStream = preload("res://Assets/tree_hover.wav")
static var sfx_upgrade: AudioStream = preload("res://Assets/tree_upgrade.wav")
static var sfx_unlock: AudioStream = preload("res://Assets/tree_unlock.wav")
var audio_player: AudioStreamPlayer

@onready var tooltip_card: Control = $TooltipCard
@onready var icon: Sprite2D = $Icon
@onready var progress_bar: ProgressBar = $TooltipCard/PanelContainer/VBoxContainer/ProgressBar

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

	if Global.stats.has(stat_id):
		base_stat_value = Global.stats[stat_id]
	
	original_icon_pos = icon.position
	current_cost = base_cost
	tooltip_card.scale = Vector2(0.7, 0.7)
	tooltip_card.hide()
	
	var panel: Control = $TooltipCard/PanelContainer
	panel.position = Vector2.ZERO
	
	progress_bar.value = 0.0
	_ignore_mouse(tooltip_card)
	
	update_card_ui()
	_setup_connections()
	
	if sprite_image:
		icon.texture = sprite_image

	if unlocked_by_default:
		set_state(NodeState.UNLOCKED)
	else:
		set_state(NodeState.HIDDEN)

func play_sfx(stream: AudioStream, pitch: float = 1.0) -> void:
	if audio_player and stream:
		audio_player.stream = stream
		audio_player.pitch_scale = pitch
		audio_player.play()

func _ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)

func _setup_connections() -> void:
	for child_node in connected_upgrades:
		if not child_node:
			continue
		
		if not child_node.parent_nodes.has(self):
			child_node.parent_nodes.append(self)
		
		var line = Line2D.new()
		line.width = 4.0
		line.default_color = Color("2e1c3b")
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.z_index = -1
		
		var start_pt = Vector2.ZERO
		line.points = PackedVector2Array([start_pt, start_pt])
		add_child(line)
		connection_lines.append(line)

func set_state(new_state: NodeState) -> void:
	current_state = new_state
	if state_tween and state_tween.is_running():
		state_tween.kill()

	match current_state:
		NodeState.HIDDEN:
			visible = false
			modulate = Color(1, 1, 1, 0)
		NodeState.LOCKED:
			visible = true
			modulate = Color(0.4, 0.4, 0.4, 0.6)
		NodeState.UNLOCKED:
			visible = true
			modulate = Color(1, 1, 1, 1)

func reveal_child() -> void:
	if current_state != NodeState.HIDDEN:
		return

	set_state(NodeState.LOCKED)
	scale = Vector2.ZERO
	modulate.a = 0.0

	state_tween = create_tween().set_parallel(true)
	state_tween.tween_property(self, "modulate:a", 0.6, 0.25)
	state_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	state_tween.chain().tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func check_prerequisites() -> void:
	if parent_nodes.is_empty():
		return

	var maxed_count: int = 0
	for p in parent_nodes:
		if p.is_maxed():
			maxed_count += 1

	var should_unlock: bool = false
	if unlock_mode == UnlockRequirement.ANY_PARENT:
		should_unlock = maxed_count > 0
	elif unlock_mode == UnlockRequirement.ALL_PARENTS:
		should_unlock = maxed_count == parent_nodes.size()

	if should_unlock:
		if state_tween and state_tween.is_running():
			state_tween.kill()
		set_state(NodeState.UNLOCKED)
		modulate = Color(1, 1, 1, 1)
		var pop = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		pop.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
		pop.tween_property(self, "scale", Vector2.ONE, 0.2)
	elif current_state == NodeState.UNLOCKED:
		modulate = Color(1, 1, 1, 1)

func _process(delta: float) -> void:
	if is_transitioning or is_maxed():
		return

	if is_holding and is_hovered and current_state == NodeState.UNLOCKED:
		hold_progress += delta / hold_duration
		var shake_intensity: float = hold_progress * 2.5
		icon.position = original_icon_pos + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		if hold_progress >= 1.0:
			complete_upgrade()
	else:
		hold_progress = max(0.0, hold_progress - (delta * 2.5))
		icon.position = icon.position.lerp(original_icon_pos, 0.2)
	
	progress_bar.value = hold_progress

func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning or not is_hovered or is_maxed() or current_state != NodeState.UNLOCKED:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if Global.can_afford(current_cost):
				is_holding = true
			else:
				is_holding = false
				var reject = create_tween()
				reject.tween_property(tooltip_card, "modulate", Color(1, 0.4, 0.4), 0.08)
				reject.tween_property(tooltip_card, "modulate", Color.WHITE, 0.12)
		else:
			is_holding = false

func _on_mouse_entered() -> void:
	if is_transitioning or current_state != NodeState.UNLOCKED:
		return
	is_hovered = true
	show_card()
	play_sfx(sfx_hover, randf_range(0.95, 1.05))

	if icon_tween and icon_tween.is_running():
		icon_tween.kill()
	icon_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	icon_tween.tween_property(icon, "scale", Vector2(1.15, 1.15), 0.15)

func _on_mouse_exited() -> void:
	var timer = get_tree().create_timer(0.05)
	exit_timer = timer
	await timer.timeout
	
	if exit_timer == timer:
		is_hovered = false
		is_holding = false
		hide_card()

		if icon_tween and icon_tween.is_running():
			icon_tween.kill()
		icon_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		icon_tween.tween_property(icon, "scale", Vector2.ONE, 0.12)

func show_card() -> void:
	update_card_ui()
	if card_tween and card_tween.is_running():
		card_tween.kill()

	tooltip_card.show()

	var panel: Control = $TooltipCard/PanelContainer
	panel.position = Vector2.ZERO
	var card_size: Vector2 = panel.get_combined_minimum_size()
	var card_w: float = max(card_size.x, panel.size.x, 206.0)
	var card_h: float = max(card_size.y, panel.size.y, 119.0)
	var spacing: float = 36.0 + card_offset_x

	if card_side == 1:
		tooltip_card.position = Vector2(spacing, -card_h / 2.0)
		tooltip_card.pivot_offset = Vector2(0.0, card_h / 2.0)
	else:
		tooltip_card.position = Vector2(-spacing - card_w, -card_h / 2.0)
		tooltip_card.pivot_offset = Vector2(card_w, card_h / 2.0)

	tooltip_card.scale = Vector2(0.7, 0.7)

	card_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	card_tween.tween_property(tooltip_card, "scale", Vector2.ONE, 0.18)

func hide_card() -> void:
	if card_tween and card_tween.is_running():
		card_tween.kill()

	card_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	card_tween.tween_property(tooltip_card, "scale", Vector2(0.7, 0.7), 0.12)
	
	card_tween.finished.connect(func():
		if not is_hovered:
			tooltip_card.hide()
	, CONNECT_ONE_SHOT)

func is_maxed() -> bool:
	return current_level >= max_level

func update_card_ui() -> void:
	%TitleLabel.text = "%s %d/%d" % [upgrade_name, current_level, max_level]
	if "%DescLabel" in self or has_node("%DescLabel"):
		%DescLabel.text = description

	if is_ending_upgrade():
		if is_maxed():
			%StatLabel.text = "THE END"
			%CostLabel.text = "MAX!"
			progress_bar.value = 1.0
		else:
			%StatLabel.text = "Complete Journey"
			%CostLabel.text = str(current_cost)
			progress_bar.value = 0.0
		return

	if stat_id == "has_coffee":
		if is_maxed():
			%StatLabel.text = "COFFEE UNLOCKED!"
			%CostLabel.text = "MAX!"
			progress_bar.value = 1.0
		else:
			%StatLabel.text = "Press [R] in-game"
			%CostLabel.text = str(current_cost)
			progress_bar.value = 0.0
		return

	var my_current = current_level * stat_step_per_level
	var my_next = (current_level + 1) * stat_step_per_level

	var cur_str: String = format_stat_value(my_current)
	var next_str: String = format_stat_value(my_next)

	if is_maxed():
		%StatLabel.text = "%s%s (MAX)" % [cur_str, stat_suffix]
		%CostLabel.text = "MAX!"
		progress_bar.value = 1.0
	else:
		%StatLabel.text = "%s → %s%s" % [cur_str, next_str, stat_suffix]
		%CostLabel.text = str(current_cost)
		progress_bar.value = 0.0

func format_stat_value(val: float) -> String:
	var display_val = val * 100.0 if stat_suffix == "%" else val
	var prefix: String = "+" if display_val > 0.0 else ""
	if stat_suffix == "%":
		return prefix + ("%d" % int(round(display_val)))
	if abs(stat_step_per_level - round(stat_step_per_level)) > 0.001:
		return prefix + ("%.2f" % display_val)
	else:
		return prefix + ("%d" % int(round(display_val)))

func complete_upgrade() -> void:
	if is_transitioning:
		return

	if not Global.spend_leaves(current_cost):
		is_holding = false
		hold_progress = 0.0
		progress_bar.value = 0.0
		return

	current_level += 1
	is_holding = false
	hold_progress = 0.0
	icon.position = original_icon_pos

	play_sfx(sfx_upgrade, 1.0 + current_level * 0.08)

	current_cost = int(round(current_cost * cost_multiplier))
	update_card_ui()

	if is_ending_upgrade():
		is_transitioning = true
		trigger_outro_transition()
		return

	if stat_id == "has_coffee":
		Global.has_coffee = true
		Global.stats["has_coffee"] = 1.0
		Global.stat_updated.emit("has_coffee", 1.0)
	else:
		var new_stat_value: float = Global.stats.get(stat_id, base_stat_value) + stat_step_per_level
		Global.apply_upgrade_stat(stat_id, new_stat_value)

	if current_level == 1:
		for i in range(connected_upgrades.size()):
			var child = connected_upgrades[i]
			if child:
				get_tree().create_timer(i * 0.08).timeout.connect(child.reveal_child)

	if is_maxed():
		unlock_branches()

func is_ending_upgrade() -> bool:
	if is_final_upgrade:
		return true
	if not target_scene.is_empty():
		return true
	if stat_id == "outro" or stat_id == "final":
		return true
	var n: String = name.to_lower()
	if n.contains("final") or n.contains("outro"):
		return true
	var u: String = upgrade_name.to_lower()
	if u.contains("final") or u.contains("outro"):
		return true
	return false

func trigger_outro_transition() -> void:
	is_transitioning = true
	is_holding = false
	is_hovered = false
	if tooltip_card:
		tooltip_card.hide()

	var tree = get_tree()
	if not tree:
		return

	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 128
	tree.root.add_child(canvas_layer)

	var fade_rect = ColorRect.new()
	fade_rect.color = Color(1.0, 1.0, 1.0, 0.0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas_layer.add_child(fade_rect)

	play_sfx(sfx_unlock, 1.3)

	var in_tween = canvas_layer.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	in_tween.tween_property(fade_rect, "color:a", 1.0, 1.8)
	
	in_tween.finished.connect(func():
		var dest = target_scene if not target_scene.is_empty() else "res://outro.tscn"
		tree.change_scene_to_file(dest)

		var out_tween = canvas_layer.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		out_tween.tween_interval(0.2)
		out_tween.tween_property(fade_rect, "color:a", 0.0, 1.2)
		out_tween.finished.connect(canvas_layer.queue_free)
	)

func unlock_branches() -> void:
	play_sfx(sfx_unlock)
	for i in range(connected_upgrades.size()):
		var child_node = connected_upgrades[i]
		var line = connection_lines[i]
		if not child_node or not line:
			continue
		
		var target_point = to_local(child_node.global_position)
		line.default_color = Color("d78151ff")

		var line_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		line_tween.tween_method(
			func(current_end: Vector2):
				line.set_point_position(1, current_end),
			Vector2.ZERO,
			target_point,
			0.4
		)
		
		line_tween.finished.connect(func():
			child_node.check_prerequisites()
		)
