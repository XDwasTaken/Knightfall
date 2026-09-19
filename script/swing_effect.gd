extends Node2D

@export var fade_duration: float = 0.32  # how long the fade takes

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	animated_sprite.play("play")
	animated_sprite.animation_finished.connect(_on_finished)

	fade_out()

func fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 0.0, fade_duration)

func _on_finished() -> void:
	queue_free()
