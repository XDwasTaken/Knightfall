extends Area2D

@export var entrance_proximity_path: NodePath
@export var exit_proximity_path: NodePath

@onready var entrance_proximity: Node = get_node(entrance_proximity_path)
@onready var exit_proximity: Node = get_node(exit_proximity_path)

var doors_locked: bool = false
var player_inside: bool = false
var room_cleared: bool = false  # once true, never locks again

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false

func _physics_process(delta: float) -> void:
	if room_cleared:
		return  # permanently unlocked, skip all checks

	var enemy_count := count_enemies_inside()

	if player_inside and enemy_count > 0 and not doors_locked:
		lock_doors()
	elif doors_locked and enemy_count == 0:
		unlock_doors()
		room_cleared = true  # lock in the "cleared" state forever

func count_enemies_inside() -> int:
	var count := 0
	for body in get_overlapping_bodies():
		if body.is_in_group("enemies"):
			count += 1
	return count

func lock_doors() -> void:
	doors_locked = true
	entrance_proximity.room_locked = true
	exit_proximity.room_locked = true

	entrance_proximity.door.set_locked(true)
	exit_proximity.door.set_locked(true)

func unlock_doors() -> void:
	doors_locked = false
	entrance_proximity.room_locked = false
	exit_proximity.room_locked = false
	entrance_proximity.permanently_open = true
	exit_proximity.permanently_open = true

	entrance_proximity.door.set_locked(false)
	exit_proximity.door.set_locked(false)
