extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var wall_slide_speed: float = 60.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# Системні змінні здоров'я та падіння
@export var max_health: int = 100
var current_health: int = 100

var fall_start_y: float = 0.0
var was_airborne: bool = false

func _ready() -> void:
	current_health = max_health

func _physics_process(delta: float) -> void:
	# 1. Відстеження падіння та висоти
	if not is_on_floor():
		if not was_airborne:
			was_airborne = true
			fall_start_y = global_position.y # Запам'ятовуємо точку початку падіння/стрибка
			
		# Ковзання по стіні або звичайна гравітація
		if is_on_wall() and velocity.y > 0:
			velocity.y = min(velocity.y + gravity * delta, wall_slide_speed)
			if Input.is_action_just_pressed("ui_accept"):
				velocity.x = get_wall_normal().x * speed * 1.8
				velocity.y = jump_velocity
		else:
			velocity.y += gravity * delta
	else:
		# Щойно приземлилися
		if was_airborne:
			was_airborne = false
			var fall_distance = global_position.y - fall_start_y
			if fall_distance > 0:
				calculate_fall_damage(fall_distance)
			fall_start_y = global_position.y

	# 2. Стрибок із землі
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		was_airborne = true
		fall_start_y = global_position.y

	# 3. Горизонтальний рух
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

# Калькулятор шкоди від падіння
func calculate_fall_damage(distance: float) -> void:
	var damage: int = 0
	
	if distance >= 501:
		damage = 100
	elif distance >= 201:
		damage = 70
	elif distance >= 101:
		damage = 40
	elif distance >= 50:
		damage = 15

	if damage > 0:
		print("Висота падіння: ", int(distance), " пікселів. Отримано шкоди: ", damage)
		take_damage(damage)

# Завдання шкоди та перевірка на смерть
func take_damage(amount: int) -> void:
	current_health -= amount
	print("Залишок здоров'я: ", current_health)
	
	if current_health <= 0:
		die()

# Функція лікування (для рослинки)
func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)
	print("Здоров'я поповнено! Поточне здоров'я: ", current_health)

# Смерть і перезапуск сцени
func die() -> void:
	print("Персонаж загинув! Перезапуск рівня...")
	get_tree().reload_current_scene()
