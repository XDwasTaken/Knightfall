extends CharacterBody2D

@export var heal_amount: int = 25

@onready var pickup_area: Area2D = $Area2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	pickup_area.body_entered.connect(_on_body_entered)
	animated_sprite.play("flow")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("heal"):
		body.heal(heal_amount)
		queue_free()
