@onready var arrow_delay_timer: Timer = $ArrowDelayTimer

func _ready() -> void:
	$Camera2D.enabled = true
	$Camera2D.position_smoothing_enabled = false
	$Camera2D.position_smoothing_speed = 8.0

	update_attack_position()

	animated_sprite.animation_finished.connect(_on_animation_finished)
	arrow_delay_timer.timeout.connect(_on_arrow_delay_timeout)

func release_shoot() -> void:
	if not is_shooting:
		return

	shoot_held = false
	is_shooting = false
	animated_sprite.play("shoot")  # resumes from held frame to the end

	print("release_shoot called, starting timer")
	arrow_delay_timer.start()

func _on_arrow_delay_timeout() -> void:
	print("Timer finished, spawning arrow")

	var arrow := ARROW_SCENE.instantiate()
	get_parent().add_child(arrow)

	arrow.global_position = global_position
	arrow.direction = Vector2.RIGHT if facing_right else Vector2.LEFT

	if arrow.has_node("Sprite2D"):
		arrow.get_node("Sprite2D").flip_h = not facing_right
