extends CharacterBody2D

@export var speed: float = 150.0
@export var acceleration: float = 800.0
@export var friction: float = 1000.0

@export var min_volume_db: float = -12.0
@export var max_volume_db: float = 0.0
@export var volume_ramp_time: float = 1.0
@export var volume_fall_speed: float = 2.0
@export var move_threshold: float = 5.0

@onready var move_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

var press_time: float = 0.0

func _ready() -> void:
	move_sound.volume_db = min_volume_db

func _physics_process(delta: float) -> void:
	var target_velocity: Vector2 = Vector2.ZERO
	var pressed: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if pressed:
		var mouse_pos: Vector2 = get_global_mouse_position()
		var direction: Vector2 = mouse_pos - global_position
		rotation = direction.angle()
		if direction.length() > 5.0:
			target_velocity = direction.normalized() * speed

	if target_velocity != Vector2.ZERO:
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()

	if pressed:
		press_time += delta
	else:
		press_time = maxf(0.0, press_time - delta * volume_fall_speed)

	var t: float = clampf(press_time / maxf(volume_ramp_time, 0.001), 0.0, 1.0)
	move_sound.volume_db = lerpf(min_volume_db, max_volume_db, t)

	if velocity.length() > move_threshold:
		if not move_sound.playing:
			move_sound.play()
	else:
		if move_sound.playing:
			move_sound.stop()
