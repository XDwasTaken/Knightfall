extends Control

@onready var start_button: Button = $Select/start
@onready var options_button: Button = $Select/options
@onready var leave_button: Button = $Select/leave
@onready var option_panel: Control = $OptionPanel
@onready var volume_slider: HSlider = $OptionPanel/VolumeSlider
@onready var fullscreen_toggle: CheckButton = $OptionPanel/VBoxContainer/Fullscreen
@onready var back_button: Button = $OptionPanel/BackButton

func _ready() -> void:
	modulate.a = 0.0
	fade_in()

	
	options_button.pressed.connect(open_options)
	

	back_button.pressed.connect(close_options)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)

	option_panel.hide()

	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0)) * 100.0
	fullscreen_toggle.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value / 100.0))

func fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)

func start() -> void:
	get_tree().change_scene_to_file("res://scenes/lvl1.tscn")

func open_options() -> void:
	option_panel.show()

func close_options() -> void:
	option_panel.hide()

func leave() -> void:
	get_tree().quit()



func _on_fullscreen_toggled(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
