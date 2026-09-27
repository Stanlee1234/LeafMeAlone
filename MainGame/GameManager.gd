extends Node

signal leaves_changed(new_amount: int)
signal stat_updated(stat_name: String, new_value: float)
signal timer_reset()
signal time_added(seconds: float)

var leaves: int = 10000000
var spawn_timer: float = 0.0
var spawn_interval: float = 0.8
var is_underground: bool = false

var stats: Dictionary = {
	"leaf_value": 1.0,
	"leaf_time": 0.0,
	"move_speed": 150.0,
	"round_duration": 10.0,
	"leaf_sway": 50.0, # Use a literal number here, not Leaf.sway_amount
	"leaf_amount": 0.8,
}

func _process(delta: float) -> void:
	if is_underground:
		return

	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		# Ensure LeafSpawner is an Autoload or call your spawner instance
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
	if stats.has(stat_id):
		stats[stat_id] = value
		stat_updated.emit(stat_id, value)
		
		# If upgrading spawn rate, sync interval immediately
		if stat_id == "leaf_amount":
			spawn_interval = value
