extends Area2D

@export var door_path: NodePath
@export var room_center_path: NodePath   # optional: a Marker2D placed at the room's center

@onready var door: Node = get_node(door_path)
@onready var room_center: Node2D = get_node(room_center_path) if room_center_path != NodePath("") else null

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

		if room_center:
			body.global_position = room_center.global_position

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
