extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Area2D
@onready var collide: CollisionShape2D = $CollisionShape2D
@onready var original_scale_x: float = abs(animated_sprite_2d.scale.x)

const JUMP_VELOCITY = -400.0

var speed: float = 150.0
var score = 0
var hitbox_offset: Vector2
var collide_offset: Vector2
var last_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	hitbox_offset = hitbox.position
	collide_offset = collide.position
	
	# Load initial speed stat from Global
	speed = Global.stats.get("move_speed", 150.0)
	
	# Listen for stat upgrades bought while game is running
	Global.stat_updated.connect(_on_stat_updated)

func _physics_process(_delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		if direction < 0:
			animated_sprite_2d.scale.x = -original_scale_x
			last_direction = Vector2.LEFT
		else:
			animated_sprite_2d.scale.x = original_scale_x
			last_direction = Vector2.RIGHT

		animated_sprite_2d.play("walk")
		velocity.x = direction * speed
	else:
		animated_sprite_2d.play("idle")
		velocity.x = move_toward(velocity.x, 0, speed)
		last_direction = Vector2.ZERO
		
	update_collision_position()
	align_character()
	move_and_slide()

func update_collision_position() -> void:
	if last_direction.x == 0:
		return
	
	var dir_sign := signf(last_direction.x)
	hitbox.position = Vector2(hitbox_offset.x * dir_sign, hitbox_offset.y)
	collide.position = Vector2(collide_offset.x * dir_sign, collide_offset.y)

func align_character() -> void:
	var screen_size : Vector2 = get_viewport_rect().size
	
	var world_height = 0.0
	var anim_name = animated_sprite_2d.animation
	var frame_index = animated_sprite_2d.frame
	var texture = animated_sprite_2d.sprite_frames.get_frame_texture(anim_name, frame_index)
	
	if texture:
		world_height = texture.get_height() * animated_sprite_2d.scale.y
	position.y = screen_size.y - world_height - 20

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("leaves"):
		var payout: int = int(round(Global.stats.get("leaf_value", 1.0)))
		Global.add_leaves(payout)
		var bonus_time: float = Global.stats.get("leaf_time", 0.0)
		if bonus_time > 0.0:
			Global.add_time(bonus_time)
		area.queue_free()

func _on_stat_updated(stat_id: String, new_value: float) -> void:
	if stat_id == "move_speed":
		speed = new_value
