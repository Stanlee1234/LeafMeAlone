extends Label

@export var total_time: float = 10.0
var time_left: float

func _ready() -> void:
	total_time = Global.stats.get("round_duration", total_time)
	time_left = total_time
	update_display()
	Global.timer_reset.connect(reset_time)
	Global.time_added.connect(add_time)
	Global.stat_updated.connect(_on_stat_updated)

func add_time(seconds: float) -> void:
	time_left += seconds
	update_display()

func _on_stat_updated(stat_id: String, new_value: float) -> void:
	if stat_id == "round_duration":
		total_time = new_value

func _process(delta: float) -> void:
	if time_left > 0.0 and %SceneController.is_game_active:
		time_left = max(0.0, time_left - delta)
		update_display()
		if time_left == 0.0:
			on_time_expired()

func update_display() -> void:
	var total_seconds: int = int(time_left)
	var minutes: int = int(total_seconds / 60.0)
	var seconds: int = total_seconds % 60
	var milliseconds: int = int(fposmod(time_left, 1.0) * 1000.0)
	text = "%02d:%02d.%03d" % [minutes, seconds, milliseconds]


func on_time_expired() -> void:
	%SceneController.switch_view()

func reset_time() -> void:
	time_left = Global.stats["round_duration"]
