extends Area2D

@export var exit_door_path: NodePath
@export var room_enemies_group: String = "room1_enemies"

@onready var exit_door: Node = get_node(exit_door_path)

var room_active: bool = false
var enemies_in_room: Array = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if room_active:
		return

	if body.is_in_group("player"):
		start_room()

func start_room() -> void:
	room_active = true

	enemies_in_room = get_tree().get_nodes_in_group(room_enemies_group)

	if enemies_in_room.is_empty():
		return

	lock_exit()

	for enemy in enemies_in_room:
		enemy.tree_exiting.connect(_on_enemy_removed.bind(enemy))

func _on_enemy_removed(enemy: Node) -> void:
	enemies_in_room.erase(enemy)

	if enemies_in_room.is_empty():
		unlock_exit()

func lock_exit() -> void:
	if exit_door and exit_door.has_method("set_locked"):
		exit_door.set_locked(true)

func unlock_exit() -> void:
	if exit_door and exit_door.has_method("set_locked"):
		exit_door.set_locked(false)
