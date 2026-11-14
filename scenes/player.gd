extends CharacterBody2D

# Кристали
var collected_crystals: int = 0

# Шляхи до секцій кристалів (перетягніть їх у відповідні поля в Інспекторі)
@export var sec1_path: NodePath
@export var sec2_path: NodePath
@export var sec3_path: NodePath

@onready var sec1: ProgressBar = get_node_or_null(sec1_path)
@onready var sec2: ProgressBar = get_node_or_null(sec2_path)
@onready var sec3: ProgressBar = get_node_or_null(sec3_path)

@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var wall_slide_speed: float = 60.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# Системні змінні здоров'я та падіння
@export var max_health: int = 100
var current_health: int = 100

# Посилання на вузол шкали на екрані
@export var health_bar_path: NodePath
@onready var health_bar: ProgressBar = get_node_or_null(health_bar_path)

var fall_start_y: float = 0.0
var was_airborne: bool = false

func _ready() -> void:
	current_health = max_health
	update_health_bar()

func _physics_process(delta: float) -> void:
	# 1. Фізика та відстеження падіння
	if not is_on_floor():
		if is_on_wall() and velocity.y > 0:
			was_airborne = false 
			velocity.y = min(velocity.y + gravity * delta, wall_slide_speed)
			
			if Input.is_action_just_pressed("ui_accept"):
				velocity.x = get_wall_normal().x * speed * 1.8
				velocity.y = jump_velocity
		else:
			if not was_airborne and velocity.y > 0:
				was_airborne = true
				fall_start_y = global_position.y
				
			velocity.y += gravity * delta
	else:
		if was_airborne:
			was_airborne = false
			var fall_distance = global_position.y - fall_start_y
			
			if fall_distance >= 50:
				calculate_fall_damage(fall_distance)

	# 2. Стрибок із землі
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		was_airborne = false

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
		print("Вільне падіння з висоти: ", int(distance), " пікселів. Отримано шкоди: ", damage)
		take_damage(damage)

# Завдання шкоди та перевірка на смерть
func take_damage(amount: int) -> void:
	current_health -= amount
	print("Залишок здоров'я: ", current_health)
	update_health_bar()
	
	if current_health <= 0:
		die()

# Функція лікування (для рослинки)
func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)
	print("Здоров'я поповнено! Поточне здоров'я: ", current_health)
	update_health_bar()

# Смерть і перезапуск сцени
func die() -> void:
	print("Персонаж загинув! Перезапуск рівня...")
	get_tree().reload_current_scene()


# ==========================================
func update_health_bar() -> void:
	if health_bar:
		health_bar.value = current_health
		
		# Отримуємо або створюємо стиль заповнення програмно
	var fill_style = health_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if not fill_style:
		fill_style = StyleBoxFlat.new()
		health_bar.add_theme_stylebox_override("fill", fill_style)
		
		# Змінюємо колір залежно від рівня здоров'я
	if current_health == 100:
		fill_style.bg_color = Color(0.2, 0.8, 0.2) # Зелений (100)
	elif current_health >= 50:
		fill_style.bg_color = Color(0.9, 0.9, 0.2) # Жовтий (50 - 99)
	else:
		fill_style.bg_color = Color(0.9, 0.2, 0.2) # Червоний (1 - 49)


# --- ФУНКЦІЇ КРИСТАЛІВ ---
func add_crystal() -> void:
	collected_crystals += 1
	print("Кристал зібрано! Всього: ", collected_crystals)
	update_crystal_ui()

func update_crystal_ui() -> void:
	if sec1:
		sec1.value = 1 if collected_crystals >= 1 else 0
	if sec2:
		sec2.value = 1 if collected_crystals >= 2 else 0
	if sec3:
		sec3.value = 1 if collected_crystals >= 3 else 0
