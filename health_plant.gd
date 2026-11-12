extends Area2D

@export var heal_amount: int = 30

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Перевіряємо, чи зіткнувся саме гравець і чи має він функцію heal
	if body.name == "Player" and body.has_method("heal"):
		body.heal(heal_amount)
		queue_free() # Зникає після того, як персонаж її "з'їв"
