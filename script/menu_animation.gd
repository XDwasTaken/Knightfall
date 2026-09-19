extends Node2D
#commit
@export var fade_duration: float = 0.6
@export var stagger_delay: float = 0.25
@export var ui_fade_duration: float = 1
@export var darken_amount: float = 0.4  # 1.0 = normal brightness, 0.0 = black
@export var darken_duration: float = 0.8

@onready var sun: Sprite2D = $sun
@onready var mountains: Sprite2D = $mountains
@onready var sky: Sprite2D = $sky
@onready var reflect: Sprite2D = $reflect
@onready var scenery: Sprite2D = $scenery

@onready var select: VBoxContainer = $"/root/MainMenu/Select"
@onready var title: Label = $"/root/MainMenu/Title"

func _ready() -> void:
	sun.modulate.a = 0.0
	mountains.modulate.a = 0.0
	sky.modulate.a = 0.0
	reflect.modulate.a = 0.0
	scenery.modulate.a = 0.0

	select.modulate.a = 0.0
	title.modulate.a = 0.0

	play_intro()

func play_intro() -> void:
	fade_in(sun)

	await get_tree().create_timer(stagger_delay).timeout
	fade_in(mountains)

	await get_tree().create_timer(stagger_delay).timeout
	fade_in(sky)
	fade_in(reflect)

	await get_tree().create_timer(stagger_delay).timeout
	fade_in(scenery)

	await get_tree().create_timer(fade_duration).timeout  # wait for scenery's fade to finish

	fade_in_ui()

func fade_in(sprite: Sprite2D) -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, fade_duration)

func fade_in_ui() -> void:
	var title_tween := create_tween()
	title_tween.tween_property(title, "modulate:a", 1.0, ui_fade_duration)

	var select_tween := create_tween()
	select_tween.tween_property(select, "modulate:a", 1.0, ui_fade_duration)

	await title_tween.finished
	await select_tween.finished

	darken_background()

func darken_background() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(darken_amount, darken_amount, darken_amount, 1.0), darken_duration)
