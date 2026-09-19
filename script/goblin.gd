extends CharacterBody2D

@export var speed: float = 56.0
@export var chase_range: float = 92.0
@export var attack_range: float = 24.0
@export var attack_offset: float = 24.0
@export var attack_cooldown: float = 1.2
@export var knockback_strength: float = 100.0
@export var knockback_duration: float = 0.1
@export var max_health: int = 35

@export var flash_duration: float = 0.2
@export var flash_color: Color = Color(3, 3, 3, 1) # overbright white flash

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_zone: Area2D = $AttackZone

var facing_right: bool = true
var is_attacking: bool = false
var is_hurt: bool = false
var can_attack: bool = true
var health: int = max_health

var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0

var current_target: Node2D = null

func _ready() -> void:
	add_to_group("enemies")
	update_attack_zone_position()
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if is_hurt:
		knockback_timer -= delta
		velocity = knockback_velocity
		move_and_slide()

		if knockback_timer <= 0.0:
			is_hurt = false
		return

	var target := find_nearest_target()

	if target == null or is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		update_animation(Vector2.ZERO)
		return

	var distance_to_target := global_position.distance_to(target.global_position)
	var direction := Vector2.ZERO

	if distance_to_target <= attack_range:
		velocity = Vector2.ZERO
		move_and_slide()

		face_towards(target)

		if can_attack:
			perform_attack(target)

		update_animation(Vector2.ZERO)
		return

	elif distance_to_target <= chase_range:
		direction = (target.global_position - global_position).normalized()

	velocity = direction * speed
	move_and_slide()

	update_animation(velocity)

func find_nearest_target() -> Node2D:
	var targets: Array = []
	targets.append_array(get_tree().get_nodes_in_group("player"))
	targets.append_array(get_tree().get_nodes_in_group("allies"))

	var nearest: Node2D = null
	var nearest_dist := INF

	for target_node in targets:
		var target := target_node as Node2D
		if target == null:
			continue

		var dist := global_position.distance_to(target.global_position)
		if dist <= chase_range and dist < nearest_dist:
			nearest_dist = dist
			nearest = target

	return nearest

func face_towards(target: Node2D) -> void:
	if target.global_position.x < global_position.x:
		facing_right = false
	else:
		facing_right = true

	animated_sprite.flip_h = not facing_right
	update_attack_zone_position()

func update_attack_zone_position() -> void:
	if facing_right:
		attack_zone.position = Vector2(attack_offset, 0)
	else:
		attack_zone.position = Vector2(-attack_offset, 0)

func update_animation(vel: Vector2) -> void:
	if is_attacking or is_hurt:
		return

	if vel.length() > 5.0:
		animated_sprite.play("run")

		if vel.x < 0:
			animated_sprite.flip_h = true
			facing_right = false
			update_attack_zone_position()
		elif vel.x > 0:
			animated_sprite.flip_h = false
			facing_right = true
			update_attack_zone_position()
	else:
		animated_sprite.play("idle")

func perform_attack(target: Node2D) -> void:
	is_attacking = true
	can_attack = false

	var swing_anim := "swing1" if randi() % 2 == 0 else "swing2"
	animated_sprite.play(swing_anim)

	var bodies: Array = attack_zone.bodies_in_zone
	for body in bodies:
		if (body.is_in_group("player") or body.is_in_group("allies")) and body.has_method("take_damage"):
			body.take_damage(10)

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(amount: int) -> void:
	if is_hurt:
		return

	health -= amount
	flash_on_hit()

	if health <= 0:
		die()
		return

	is_hurt = true
	is_attacking = false

	var target := find_nearest_target()
	var knockback_dir := Vector2.RIGHT
	if target != null:
		knockback_dir = (global_position - target.global_position).normalized()

	knockback_velocity = knockback_dir * knockback_strength
	knockback_timer = knockback_duration

func flash_on_hit() -> void:
	animated_sprite.modulate = flash_color
	var tween := create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), flash_duration)

func die() -> void:
	queue_free()

func _on_animation_finished() -> void:
	if animated_sprite.animation == "swing1" or animated_sprite.animation == "swing2":
		is_attacking = false
