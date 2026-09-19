extends CharacterBody2D

@export var interval_min: float = 0.5
@export var interval_max: float = 4.0
@export var damage_amount: int = 3
@export var damage_interval: float = 0.5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_zone: Area2D = $DamageZone

var is_spiking: bool = false
var playing_reverse: bool = false
var bodies_in_zone: Array = []
var damage_timers: Dictionary = {}

func _ready() -> void:
	damage_zone.body_entered.connect(_on_body_entered)
	damage_zone.body_exited.connect(_on_body_exited)
	animated_sprite.animation_finished.connect(_on_animation_finished)

	start_random_timer()

func start_random_timer() -> void:
	var wait_time := randf_range(interval_min, interval_max)
	await get_tree().create_timer(wait_time).timeout
	trigger_spikes()

func trigger_spikes() -> void:
	is_spiking = true
	playing_reverse = false
	animated_sprite.play("spiking")

func _on_animation_finished() -> void:
	if animated_sprite.animation != "spiking":
		return

	if not playing_reverse:
		# Forward playback just finished — now play it backwards
		playing_reverse = true
		animated_sprite.play_backwards("spiking")
	else:
		# Backward playback just finished — fully done, reset and queue next cycle
		is_spiking = false
		playing_reverse = false
		damage_timers.clear()
		start_random_timer()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("allies"):
		bodies_in_zone.append(body)
		damage_timers[body] = 0.0

func _on_body_exited(body: Node2D) -> void:
	bodies_in_zone.erase(body)
	damage_timers.erase(body)

func _physics_process(delta: float) -> void:
	if not is_spiking:
		return

	for body in bodies_in_zone.duplicate():  # iterate over a copy, safe to modify original during loop
		if not is_instance_valid(body):
			bodies_in_zone.erase(body)
			damage_timers.erase(body)
			continue

		if not damage_timers.has(body):
			damage_timers[body] = 0.0

		damage_timers[body] += delta

		if damage_timers[body] >= damage_interval:
			damage_timers[body] = 0.0
			if body.has_method("take_damage"):
				body.take_damage(damage_amount)
