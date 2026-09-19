extends CanvasLayer

@onready var speaker_name: Label = $Panel/SpeakerName
@onready var dialogue_text: RichTextLabel = $Panel/DialogueText
@onready var choices_container: VBoxContainer = $Panel/ChoicesContainer
@export var choice_font: FontFile  # drag your font file into this in the Inspector
@export var choice_font_size: int = 20
@export var typewriter_speed: float = 0.01  # seconds per character
@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")

var full_text: String = ""
var is_typing: bool = false
var skip_requested: bool = false

signal dialogue_finished

func _ready() -> void:
	add_to_group("dialogue_box")
	hide()

func show_dialogue(speaker: String, text: String, choices: Array = []) -> void:
	if player:
		player.in_dialogue = true

	show()
	speaker_name.text = speaker
	full_text = text
	dialogue_text.text = text
	dialogue_text.visible_characters = 0

	clear_choices()

	await type_text()

	if choices.size() > 0:
		show_choices(choices)

func type_text() -> void:
	is_typing = true
	skip_requested = false

	var char_count := full_text.length()
	var i := 0

	while i <= char_count:
		if skip_requested:
			dialogue_text.visible_characters = char_count
			break

		dialogue_text.visible_characters = i
		i += 1
		await get_tree().create_timer(typewriter_speed).timeout

	is_typing = false

func skip_typewriter() -> void:
	if is_typing:
		skip_requested = true

func show_choices(choices: Array) -> void:
	for choice_text in choices:
		var button := Button.new()
		button.text = choice_text

		if choice_font:
			button.add_theme_font_override("font", choice_font)

		button.add_theme_font_size_override("font_size", choice_font_size)

		button.pressed.connect(_on_choice_selected.bind(choice_text))
		choices_container.add_child(button)

func _on_choice_selected(choice_text: String) -> void:
	print("Player chose: ", choice_text)  # doesn't affect outcome, just logs/could trigger a line
	clear_choices()
	close_dialogue()

func clear_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()

func close_dialogue() -> void:
	hide()

	if player:
		player.in_dialogue = false

	dialogue_finished.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton and event.pressed:
		if is_typing:
			skip_typewriter()
