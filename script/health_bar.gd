extends ProgressBar

var player: Node = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

	if player:
		max_value = player.max_health
		value = player.health

func _process(delta: float) -> void:
	if player and is_instance_valid(player):
		value = player.health
