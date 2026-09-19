extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	#print("CritEffect _ready, playing animation")
	animated_sprite.play("play")
	animated_sprite.animation_finished.connect(_on_finished)

func _on_finished() -> void:
	queue_free()
