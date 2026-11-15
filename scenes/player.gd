extends CharacterBody2D

# Кристали
var collected_crystals: int = 0

# Шляхи до секцій кристалів (перетягніть їх у відповідні поля в Інспекторі)
@export var sec1_path: NodePath
@export var sec2_path: NodePath
@export var sec3_path: NodePath
@export var level_complete_label_path: NodePath

@onready var sec1: ProgressBar = get_node_or_null(sec1_path)
@onready var sec2: ProgressBar = get_node_or_null(sec2_path)
@onready var sec3: ProgressBar = get_node_or_null(sec3_path)
@onready var level_complete_label: TextureRect = get_node_or_null(level_complete_label_path)
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var wall_slide_speed: float = 60.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# Системні змінні здоров'я та падіння
@export var max_health: int = 100
var current_health: float = 100.0

# Посилання на вузол шкали на екрані
@export var health_bar_path: NodePath
@onready var health_bar: ProgressBar = get_node_or_null(health_bar_path)

var fall_start_y: float = 0.0
var was_airborne: bool = false
var is_jumping: bool = false
var wall_climb_paused: bool = false

func _ready() -> void:
	current_health = max_health
	update_health_bar()

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	var climbing_up_input := Input.is_action_pressed("ui_up")
	var climbing_down_input := Input.is_action_pressed("ui_down")
	var wall_at_start := is_on_wall()
	var wall_jump_requested := wall_at_start and not is_on_floor() and Input.is_action_just_pressed("ui_accept") and not climbing_up_input and not climbing_down_input and (velocity.y > 0.0 or wall_climb_paused)
	if not wall_at_start:
		wall_climb_paused = false
	elif climbing_up_input or climbing_down_input or wall_jump_requested:
		wall_climb_paused = false
	elif direction != 0.0:
		wall_climb_paused = true
	var wall_stationary_input := wall_at_start and wall_climb_paused and not climbing_up_input and not climbing_down_input

	# 1. Фізика та відстеження падіння
	if not is_on_floor():
		if wall_jump_requested:
			velocity.x = get_wall_normal().x * speed * 1.8
			velocity.y = jump_velocity
			is_jumping = true
		elif is_on_wall() and climbing_down_input:
			was_airborne = false
			velocity.y = speed
		elif is_on_wall() and climbing_up_input:
			was_airborne = false
			velocity.y = -speed
		elif wall_stationary_input:
			was_airborne = false
			velocity = Vector2.ZERO
		elif is_on_wall() and velocity.y > 0:
			was_airborne = false 
			velocity.y = min(velocity.y + gravity * delta, wall_slide_speed)
		else:
			if not was_airborne and velocity.y > 0:
				was_airborne = true
				fall_start_y = global_position.y
				
			velocity.y += gravity * delta
	else:
		is_jumping = false
		if was_airborne:
			was_airborne = false
			var fall_distance = global_position.y - fall_start_y
			
			if fall_distance >= 50:
				calculate_fall_damage(fall_distance)

	# 2. Стрибок із землі
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		was_airborne = false
		is_jumping = true

	# 3. Горизонтальний рух
	if direction != 0.0:
		animated_sprite.flip_h = direction < 0.0
	if wall_stationary_input:
		velocity.x = 0.0
	elif direction:
		velocity.x = direction * speed * (1.2 if is_jumping else 1.0)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

	var on_wall := is_on_wall()
	var climbing_down := on_wall and climbing_down_input
	var target_animation := "climb" if on_wall else ("jump" if is_jumping else ("idle" if is_on_floor() and is_zero_approx(velocity.x) else "run"))
	if animated_sprite.animation != target_animation:
		animated_sprite.play(target_animation)
	if target_animation == "climb":
		if wall_stationary_input and on_wall:
			animated_sprite.set_frame_and_progress(0, 0.0)
			animated_sprite.pause()
		else:
			animated_sprite.speed_scale = -1.0 if climbing_down else 1.0
			if not animated_sprite.is_playing():
				animated_sprite.play("climb")
	else:
		animated_sprite.speed_scale = -1.0 if climbing_down else 1.0
	var animation_scale := 0.4125 if target_animation == "climb" else 0.375
	animated_sprite.scale = Vector2(animation_scale, animation_scale)

# Калькулятор шкоди від падіння
func calculate_fall_damage(distance: float) -> void:
	var damage: float = 0.0
	
	if distance >= 551:
		damage = 50.0
	elif distance >= 251:
		damage = 35.0
	elif distance >= 151:
		damage = 20.0
	elif distance >= 150:
		damage = 7.5

	if damage > 0:
		print("Вільне падіння з висоти: ", int(distance), " пікселів. Отримано шкоди: ", damage)
		take_damage(damage)

# Завдання шкоди та перевірка на смерть
func take_damage(amount: float) -> void:
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
	if get_tree().get_nodes_in_group("crystals").is_empty():
		show_level_complete()

func show_level_complete() -> void:
	if not level_complete_label or level_complete_label.visible:
		return
	await get_tree().create_timer(1.5).timeout
	level_complete_label.visible = true
	level_complete_label.scale = Vector2(0.5, 0.5)
	var tween := create_tween()
	tween.tween_property(level_complete_label, "scale", Vector2(1.2, 1.2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(level_complete_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func update_crystal_ui() -> void:
	if sec1:
		sec1.value = 1 if collected_crystals >= 1 else 0
	if sec2:
		sec2.value = 1 if collected_crystals >= 2 else 0
	if sec3:
		sec3.value = 1 if collected_crystals >= 3 else 0
