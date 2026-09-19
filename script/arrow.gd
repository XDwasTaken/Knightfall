extends Area2D

@export var arrow_speed: float = 560.0
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var shooter: Node = null  # who fired this arrow, so we can ignore them

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += direction * arrow_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return

	if body.is_in_group("allies"):
		return  # arrows don't hurt allies either

	if body.has_method("take_damage"):
		body.take_damage(15)
	queue_free()
