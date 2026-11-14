extends Area2D

@export var score_value: int = 10 # Скільки очок дає кристал

func _ready() -> void:
	# Примусово підключаємо сигнал дотику через код (надійно, якщо в редакторі пропустили)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Перевіряємо, чи зайшов у зону саме гравець
	if body is CharacterBody2D:
		print("Кристал підібрано! Нараховано очок: ", score_value)
		
		if body.has_method("add_crystal"):
			body.add_crystal()
		
		# НАЙГОЛОВНІШЕ: повністю видаляємо кристал із гри
		queue_free()
