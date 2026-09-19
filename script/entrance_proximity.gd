extends Area2D

@export var door_path: NodePath
@onready var door: Node = get_node(door_path)

var room_locked: bool = false
var permanently_open: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if room_locked or permanently_open:
		return

	if body.is_in_group("player"):
		if door.has_method("set_locked"):
			door.set_locked(false)

		teleport_allies_to(body)

func _on_body_exited(body: Node2D) -> void:
	if room_locked or permanently_open:
		return

	if body.is_in_group("player") and door.has_method("set_locked"):
		door.set_locked(true)

func teleport_allies_to(player: Node2D) -> void:
	for ally in get_tree().get_nodes_in_group("allies"):
		if ally is Node2D:
			ally.global_position = player.global_position
