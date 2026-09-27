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

var parent_nodes: Array[Area2D] = []
var connection_lines: Array[Line2D] = []
var original_icon_pos: Vector2 = Vector2.ZERO
var exit_timer: SceneTreeTimer
var card_tween: Tween
var icon_tween: Tween

@onready var tooltip_card: Control = $TooltipCard
@onready var icon: Sprite2D = $Icon
@onready var progress_bar: ProgressBar = $TooltipCard/PanelContainer/VBoxContainer/ProgressBar

func _ready() -> void:
	# Pull base value directly from Global dictionary using stat_id
	if Global.stats.has(stat_id):
		base_stat_value = Global.stats[stat_id]
	
	original_icon_pos = icon.position
	current_cost = base_cost
	tooltip_card.scale = Vector2(0.7, 0.7)
	tooltip_card.hide()
	
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
	match current_state:
		NodeState.HIDDEN:
			visible = false
			modulate = Color(1, 1, 1, 0)
		NodeState.LOCKED:
			visible = true
			modulate = Color(0.3, 0.3, 0.3, 0.6)
		NodeState.UNLOCKED:
			visible = true
			modulate = Color(1, 1, 1, 1)

func reveal_child() -> void:
	if current_state == NodeState.HIDDEN:
		set_state(NodeState.LOCKED)
		
		scale = Vector2.ZERO
		modulate.a = 0.0

		var reveal_tween = create_tween().set_parallel(true)
		reveal_tween.tween_property(self, "modulate:a", 0.6, 0.25)
		reveal_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		reveal_tween.chain().tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func check_prerequisites() -> void:
	if current_state == NodeState.UNLOCKED:
		return
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
		set_state(NodeState.UNLOCKED)
		var pop = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		pop.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
		pop.tween_property(self, "scale", Vector2.ONE, 0.2)

func _process(delta: float) -> void:
	if is_maxed():
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
	if not is_hovered or is_maxed() or current_state != NodeState.UNLOCKED:
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
	if current_state != NodeState.UNLOCKED:
		return
	is_hovered = true
	show_card()

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
	var card_size: Vector2 = panel.get_combined_minimum_size()
	if panel.size.x > card_size.x:
		card_size.x = panel.size.x

	if card_side == 1:
		tooltip_card.position.x = card_offset_x
		tooltip_card.pivot_offset = Vector2(0.0, tooltip_card.pivot_offset.y)
	else:
		tooltip_card.position.x = -300.0 - card_offset_x
		tooltip_card.pivot_offset = Vector2(200.0, tooltip_card.pivot_offset.y)

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

	var current_val = Global.stats.get(stat_id, base_stat_value)
	var next_val = current_val + stat_step_per_level

	var cur_str: String = "%.2f" % current_val if abs(stat_step_per_level - round(stat_step_per_level)) > 0.001 else "%d" % int(round(current_val))
	var next_str: String = "%.2f" % next_val if abs(stat_step_per_level - round(stat_step_per_level)) > 0.001 else "%d" % int(round(next_val))

	if is_maxed():
		%StatLabel.text = cur_str + stat_suffix
		%CostLabel.text = "MAX!"
		progress_bar.value = 1.0
	else:
		%StatLabel.text = cur_str + " → " + next_str + stat_suffix
		%CostLabel.text = str(current_cost)
		progress_bar.value = 0.0

func complete_upgrade() -> void:
	if not Global.spend_leaves(current_cost):
		is_holding = false
		hold_progress = 0.0
		progress_bar.value = 0.0
		return

	current_level += 1
	is_holding = false
	hold_progress = 0.0
	icon.position = original_icon_pos

	var new_stat_value: float = Global.stats.get(stat_id, base_stat_value) + stat_step_per_level
	Global.apply_upgrade_stat(stat_id, new_stat_value)

	current_cost = int(round(current_cost * cost_multiplier))
	update_card_ui()

	if current_level == 1:
		for i in range(connected_upgrades.size()):
			var child = connected_upgrades[i]
			if child:
				get_tree().create_timer(i * 0.08).timeout.connect(child.reveal_child)

	if is_maxed():
		unlock_branches()

func unlock_branches() -> void:
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
