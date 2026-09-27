extends Node

signal leaves_changed(new_amount: int)
signal stat_updated(stat_name: String, new_value: float)
signal timer_reset()
signal time_added(seconds: float)
signal coffee_activated(duration: float)
signal coffee_ended()
signal view_changed(is_underground: bool)

var leaves: int = 0
var spawn_timer: float = 0.0
var spawn_interval: float = 0.8
var is_underground: bool = false

var has_coffee: bool = false
var coffee_active: bool = false
var coffee_ready: bool = true
var coffee_timer: float = 0.0
const COFFEE_DURATION: float = 6.0
const COFFEE_SPEED_MULT: float = 1.75
const COFFEE_VALUE_MULT: float = 2.0

var stats: Dictionary = {
	"leaf_value": 1.0,
	"leaf_time": 0.0,
	"move_speed": 150.0,
	"leaf_sway": 50.0,
	"leaf_amount": 0.8,
	"has_coffee": 0.0,
	"gold_leaf_chance": 0.0,
	"gold_leaf_mult": 2.0,
}

func _ready() -> void:
	timer_reset.connect(_on_round_reset)

func _on_round_reset() -> void:
	coffee_active = false
	coffee_ready = true
	coffee_timer = 0.0

func activate_coffee() -> bool:
	if has_coffee and coffee_ready and not coffee_active:
		coffee_active = true
		coffee_ready = false
		coffee_timer = COFFEE_DURATION
		coffee_activated.emit(COFFEE_DURATION)
		return true
	return false

func _process(delta: float) -> void:
	if coffee_active:
		coffee_timer -= delta
		if coffee_timer <= 0.0:
			coffee_active = false
			coffee_ended.emit()

	if is_underground:
		return

	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		if LeafSpawner:
			LeafSpawner.spawn_leaf()

func can_afford(cost: int) -> bool:
	return leaves >= cost

func spend_leaves(cost: int) -> bool:
	if can_afford(cost):
		leaves -= cost
		leaves_changed.emit(leaves)
		return true
	return false

func add_leaves(amount: int) -> void:
	leaves += amount
	leaves_changed.emit(leaves)

func add_time(seconds: float) -> void:
	time_added.emit(seconds)

func apply_upgrade_stat(stat_id: String, value: float) -> void:
	if stat_id == "has_coffee":
		has_coffee = true
		stats["has_coffee"] = 1.0
		stat_updated.emit("has_coffee", 1.0)
		return

	if stats.has(stat_id):
		stats[stat_id] = value
		stat_updated.emit(stat_id, value)
		
		if stat_id == "leaf_amount":
			spawn_interval = value

func notify_view_changed(underground: bool) -> void:
	is_underground = underground
	view_changed.emit(is_underground)
