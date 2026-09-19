extends CharacterBody2D

@export var speed: float = 81.0
@export var min_distance_to_player: float = 30.0
@export var follow_distance: float = 72.0
@export var wander_radius: float = 48.0
@export var wander_pause_min: float = 2.0
@export var wander_pause_max: float = 5.0
@export var wander_move_min: float = 1.0
@export var wander_move_max: float = 2.0
@export var flash_duration: float = 0.15
@export var flash_color: Color = Color(1, 1, 1, 1)

@export var separation_distance: float = 15.0
@export var separation_strength: float = 2.5

@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.5
@export var attack_damage: int = 15

@export var shield_chance: float = 0.15       # chance per decision cycle to shield instead of attacking
@export var shield_duration: float = 1.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: Node2D = null
var facing_right: bool = true
var wander_target: Vector2 = Vector2.ZERO
var state: String = "idle"
var state_timer: float = 0.0

var is_attacking: bool = false
var can_attack: bool = true
var is_shielding: bool = false

var current_target: Node2D = null

func _ready() -> void:
	add_to_group("allies")
	player = get_tree().get_first_node_in_group("player")
	pick_new_wander_pause()
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if player == null:
		return

	if is_attacking or is_shielding:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var nearby_enemy := find_nearest_enemy()

	if nearby_enemy != null:
		var dist_to_enemy := global_position.distance_to(nearby_enemy.global_position)

		if dist_to_enemy <= attack_range:
			face_target(nearby_enemy)
			velocity = Vector2.ZERO
			move_and_slide()
			update_animation(Vector2.ZERO)

			if can_attack:
				decide_attack_or_shield(nearby_enemy)
			return
		else:
			# Move toward the enemy
			var direction := (nearby_enemy.global_position - global_position).normalized()
			direction = apply_separation(direction)
			velocity = direction * speed
			move_and_slide()
			update_animation(velocity)
			return

	# No enemy nearby — fall back to normal wander/follow behavior
	var distance_to_player := global_position.distance_to(player.global_position)
	var direction := Vector2.ZERO

	if distance_to_player > follow_distance:
		state = "follow"
	elif state == "follow" and distance_to_player <= min_distance_to_player * 1.5:
		pick_new_wander_pause()

	match state:
		"follow":
			if distance_to_player > min_distance_to_player:
				direction = (player.global_position - global_position).normalized()
			else:
				pick_new_wander_pause()

		"wander":
			state_timer -= delta
			var to_target := wander_target - global_position
			if to_target.length() < 5.0 or state_timer <= 0.0:
				pick_new_wander_pause()
			else:
				direction = to_target.normalized()

		"idle":
			state_timer -= delta
			if state_timer <= 0.0:
				pick_new_wander_target()

	direction = apply_separation(direction)

	velocity = direction * speed
	move_and_slide()

	update_animation(velocity)

func apply_separation(direction: Vector2) -> Vector2:
	var separation := get_separation_vector()
	var combined := direction + separation * separation_strength

	if combined.length() > 1.0:
		combined = combined.normalized()

	return combined

func find_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist := INF

	for enemy in enemies:
		if not enemy is Node2D:
			continue

		var dist := global_position.distance_to(enemy.global_position)
		if dist < nearest_dist and dist <= chase_enemy_range():
			nearest_dist = dist
			nearest = enemy

	return nearest

func chase_enemy_range() -> float:
	return attack_range * 3.0  # how far Gilbert will notice and approach an enemy

func face_target(target: Node2D) -> void:
	if target.global_position.x < global_position.x:
		facing_right = false
	else:
		facing_right = true

	animated_sprite.flip_h = not facing_right

func decide_attack_or_shield(target: Node2D) -> void:
	if randf() < shield_chance:
		perform_shield()
	else:
		perform_attack(target)

func perform_attack(target: Node2D) -> void:
	is_attacking = true
	can_attack = false

	var swing_anim := "swing1" if randi() % 2 == 0 else "swing2"
	animated_sprite.play(swing_anim)

	if target.has_method("take_damage"):
		target.take_damage(attack_damage)

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func perform_shield() -> void:
	is_shielding = true
	animated_sprite.play("idle")  # or a dedicated "shield" animation if you have one

	await get_tree().create_timer(shield_duration).timeout
	is_shielding = false

func take_damage(amount: int) -> void:
	if is_shielding:
		return  # no damage while shielding

	# ... your existing hurt/health logic here

func pick_new_wander_pause() -> void:
	state = "idle"
	state_timer = randf_range(wander_pause_min, wander_pause_max)

func pick_new_wander_target() -> void:
	state = "wander"
	state_timer = randf_range(wander_move_min, wander_move_max)

	var angle := randf_range(0, TAU)
	var offset := Vector2(cos(angle), sin(angle)) * randf_range(20.0, wander_radius)
	var target := global_position + offset

	if target.distance_to(player.global_position) < min_distance_to_player:
		target = player.global_position + (target - player.global_position).normalized() * min_distance_to_player

	wander_target = target

func get_separation_vector() -> Vector2:
	var push := Vector2.ZERO

	var player_dist := global_position.distance_to(player.global_position)
	if player_dist < min_distance_to_player and player_dist > 0.0:
		var away: Vector2 = (global_position - player.global_position).normalized()
		var strength := (min_distance_to_player - player_dist) / min_distance_to_player
		push += away * strength

	for ally_node in get_tree().get_nodes_in_group("allies"):
		var ally := ally_node as Node2D
		if ally == null or ally == self:
			continue

		var dist := global_position.distance_to(ally.global_position)
		if dist < separation_distance and dist > 0.0:
			var away: Vector2 = (global_position - ally.global_position).normalized()
			var strength := (separation_distance - dist) / separation_distance
			push += away * strength

	return push

func update_animation(vel: Vector2) -> void:
	if is_attacking or is_shielding:
		return

	if vel.length() > 5.0:
		animated_sprite.play("run")

		if vel.x < 0:
			animated_sprite.flip_h = true
			facing_right = false
		elif vel.x > 0:
			animated_sprite.flip_h = false
			facing_right = true
	else:
		animated_sprite.play("idle")
func _on_animation_finished() -> void:
	if animated_sprite.animation == "swing1" or animated_sprite.animation == "swing2":
		is_attacking = false
func flash_on_hit() -> void:
	animated_sprite.modulate = flash_color
	var tween := create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), flash_duration)
