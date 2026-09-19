extends AnimationPlayer

func _ready() -> void:
	print("Available animations: ", get_animation_list())

	Player_lock_during_intro()
	play("filter")
	animation_finished.connect(_on_intro_finished)

func Player_lock_during_intro() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.cutscene_active = true

func _on_intro_finished(anim_name: String) -> void:
	if anim_name == "filter":
		var player := get_tree().get_first_node_in_group("player")
		if player:
			player.cutscene_active = false
