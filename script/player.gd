extends CharacterBody2D
const CRIT_EFFECT_SCENE := preload("res://scenes/crit_effect.tscn")
@onready var dialogue_box: CanvasLayer = get_tree().get_first_node_in_group("dialogue_box")
var in_dialogue: bool = false
@export var speed: float = 150.0
@export var attack_offset: float = 32.0
@export var swing_effect_offset: float = 9.0
@onready var animated_sprite: AnimatedSprite2D = $playerAnimation
@onready var attack_area: Area2D = $AttackArea
@onready var arrow_delay_timer: Timer = $ArrowDelayTimer
@export var max_health: int = 100
var health: int = max_health
var is_hurt: bool = false
const ARROW_SCENE := preload("res://scenes/arrow.tscn")
@export var flash_duration: float = 0.2
@export var flash_color: Color = Color(3, 3, 3, 1)  # overbright white flash

var cutscene_active: bool = false

var facing_right: bool = true
var is_attacking: bool = false
var movement_locked: bool = false
var is_shooting: bool = false
var shoot_held: bool = false
var shoot_direction: Vector2 = Vector2.RIGHT
const SWING_EFFECT_SCENE := preload("res://scenes/swing_effect.tscn")
  # locked in at release time

@onready var camera: Camera2D = $Camera2D

var shake_strength: float = 0.0
var shake_decay: float = 10.0  # how fast the shake fades out

func _process(delta: float) -> void:
	if shake_strength > 0.0:
		camera.offset = Vector2(
			randf_range(-1.0, 1.0) * shake_strength,
			randf_range(-1.0, 1.0) * shake_strength
		)
		shake_strength = max(shake_strength - shake_decay * delta, 0.0)*0.84

		if shake_strength <= 0.0:
			camera.offset = Vector2.ZERO

func shake_camera(strength: float) -> void:
	shake_strength = strength
func _ready() -> void:
	$Camera2D.enabled = true
	$Camera2D.position_smoothing_enabled = false
	$Camera2D.position_smoothing_speed = 8.0

	update_attack_position()

	arrow_delay_timer.one_shot = true  # enforce one-shot regardless of Inspector setting

	animated_sprite.animation_finished.connect(_on_animation_finished)
	arrow_delay_timer.timeout.connect(_on_arrow_delay_timeout)

func _physics_process(delta: float) -> void:
	if cutscene_active:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if in_dialogue:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if is_shooting and animated_sprite.frame >= 5:
		animated_sprite.pause()

	if movement_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_vector := Vector2.ZERO

	if Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
		speed = 81
	if Input.is_key_pressed(KEY_D):
		input_vector.x += 1
		speed = 81
	if Input.is_key_pressed(KEY_W):
		input_vector.y -= 1
		speed = 72
	if Input.is_key_pressed(KEY_S):
		input_vector.y += 1
		speed = 72

	input_vector = input_vector.normalized()

	velocity = input_vector * speed
	move_and_slide()

	update_animation(input_vector)

	if Input.is_action_just_pressed("ui_accept"):
		perform_crit()

func update_animation(input_vector: Vector2) -> void:
	if is_attacking:
		return

	if input_vector != Vector2.ZERO:
		animated_sprite.play("walk")

		if input_vector.x < 0:
			animated_sprite.flip_h = true
			facing_right = false
			update_attack_position()
		elif input_vector.x > 0:
			animated_sprite.flip_h = false
			facing_right = true
			update_attack_position()
	else:
		animated_sprite.play("idle")

func update_attack_position() -> void:
	var mouse_pos := get_global_mouse_position()
	var direction := (mouse_pos - global_position).normalized()

	attack_area.position = direction * attack_offset
	attack_area.rotation = direction.angle()

	# Keep sprite facing roughly the same side as the cursor
	if direction.x < 0:
		facing_right = false
		animated_sprite.flip_h = true
	elif direction.x > 0:
		facing_right = true
		animated_sprite.flip_h = false

func _unhandled_input(event: InputEvent) -> void:
	if in_dialogue:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			perform_attack()

		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				start_shoot()
				
			else:
				release_shoot()
				


func perform_attack() -> void:
	if is_attacking:
		return

	face_mouse_cursor()

	is_attacking = true
	animated_sprite.play("swing")

	for body in attack_area.bodies_in_zone:
		if body != self and not body.is_in_group("allies") and body.has_method("take_damage"):
			body.take_damage(10)
			shake_camera(3.0)
			spawn_swing_effect(body)

func face_mouse_cursor() -> void:
	var mouse_pos := get_global_mouse_position()

	if mouse_pos.x < global_position.x:
		facing_right = false
	else:
		facing_right = true

	animated_sprite.flip_h = not facing_right
	update_attack_position()

func perform_crit() -> void:
	if is_attacking:
		return

	is_attacking = true
	movement_locked = true
	animated_sprite.play("crit")

	for body in attack_area.bodies_in_zone:
		if body != self and not body.is_in_group("allies") and body.has_method("take_damage"):
			body.take_damage(25)
			shake_camera(5.0)
			spawn_crit_effect(body)

func start_shoot() -> void:
	if is_attacking:
		return

	is_attacking = true
	is_shooting = true
	shoot_held = true
	movement_locked = true  # lock movement while drawing/holding the shot
	animated_sprite.play("shoot")

func release_shoot() -> void:
	if not is_shooting:
		return

	shoot_held = false
	is_shooting = false
	animated_sprite.play("shoot")  # resumes from held frame to the end

	# Lock in aim direction toward the mouse at the moment of release
	shoot_direction = (get_global_mouse_position() - global_position).normalized()

	arrow_delay_timer.start()

func _on_arrow_delay_timeout() -> void:
	var arrow := ARROW_SCENE.instantiate()
	get_parent().add_child(arrow)

	arrow.global_position = global_position + shoot_direction * 20.0  # spawn 20px ahead
	arrow.direction = shoot_direction
	arrow.rotation = shoot_direction.angle()
	arrow.shooter = self # point the arrow sprite toward the aim direction


func _on_animation_finished() -> void:
	if animated_sprite.animation in ["swing", "crit", "shoot"]:
		is_attacking = false
		movement_locked = false

func take_damage(amount: int) -> void:

	health -= amount
	shake_camera(6.0)
	flash_on_hit()

	if health <= 1:
		print("ded")
		die()

func flash_on_hit() -> void:

	animated_sprite.modulate = flash_color
	var tween := create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), flash_duration)

func die() -> void:
	animated_sprite.play("death")
	 
func spawn_swing_effect(target: Node2D) -> void:
	var effect := SWING_EFFECT_SCENE.instantiate()
	get_parent().add_child(effect)

	effect.global_position = target.global_position

	var direction := (target.global_position - global_position).normalized()
	effect.rotation = direction.angle()

	if effect.has_node("AnimatedSprite2D"):
		var effect_sprite: AnimatedSprite2D = effect.get_node("AnimatedSprite2D")
		effect_sprite.flip_h = not facing_right
func spawn_crit_effect(target: Node2D) -> void:
	var effect := CRIT_EFFECT_SCENE.instantiate()
	get_parent().add_child(effect)

	effect.global_position = target.global_position
func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	
func test_dialogue() -> void:
	dialogue_box.show_dialogue(
		"Gilbert",
		"Watch out for the goblins ahead — they hit harder than they look.",
		["Got it.", "Thanks for the warning.", "I can handle it."]
	)
