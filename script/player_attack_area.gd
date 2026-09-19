extends Area2D

var bodies_in_zone: Array = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	bodies_in_zone.append(body)

func _on_body_exited(body: Node2D) -> void:
	bodies_in_zone.erase(body)
