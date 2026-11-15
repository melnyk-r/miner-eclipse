extends Control

@onready var menu_music: AudioStreamPlayer = $MenuMusic
@onready var ui_click: AudioStreamPlayer = $UIClick
var starting_game: bool = false

func _ready() -> void:
	menu_music.finished.connect(_on_menu_music_finished)
	menu_music.play()

func _on_play_pressed() -> void:
	if starting_game:
		return
	starting_game = true
	ui_click.play()
	await get_tree().create_timer(0.16).timeout
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_controls_pressed() -> void:
	ui_click.play()
	$ControlsPanel.visible = not $ControlsPanel.visible

func _on_menu_music_finished() -> void:
	menu_music.play()
