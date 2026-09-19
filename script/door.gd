extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	set_locked(true)  # closed by default

func set_locked(locked: bool) -> void:
	if locked:
		animated_sprite.play("closed")
		collision.set_deferred("disabled", false)
	else:
		animated_sprite.play("open")
		collision.set_deferred("disabled", true)
