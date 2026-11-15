extends Node2D

@onready var game_music: AudioStreamPlayer = $CanvasLayer/GameMusic

func _ready() -> void:
	game_music.finished.connect(_on_game_music_finished)
	game_music.play()

func _on_game_music_finished() -> void:
	game_music.play()
