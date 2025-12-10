extends CharacterBody3D

@export_range(1.0, 10.0, 0.5, "or_greater") var move_speed: float = 3.0
@export_range(1.0, 20.0, 0.5, "or_greater") var acceleration: float = 8.0
@export var mouse_sensitivity: float = 0.003
@export var gravity_scale: float = 1.0

@onready var _camera: Camera3D = $Camera3D

# --- SOUND ---
@onready var drive_sound: AudioStreamPlayer3D = $DriveSound
@onready var bonk_sound: AudioStreamPlayer3D = $BonkSound

var _pitch: float = 0.0
var _default_gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))

# Mobile Control Flags
var turning_left: bool = false
var turning_right: bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw_pitch(event.relative)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _yaw_pitch(relative: Vector2) -> void:
	rotation.y -= relative.x * mouse_sensitivity
	_pitch = clamp(_pitch - relative.y * mouse_sensitivity, deg_to_rad(-60), deg_to_rad(60))
	_camera.rotation.x = _pitch

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Tank Controls Rotation
	if turning_left:
		rotation.y += 2.0 * delta
	if turning_right:
		rotation.y -= 2.0 * delta

	# Movement
	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

	if not is_on_floor():
		velocity.y -= _default_gravity * gravity_scale * delta
	else:
		velocity.y = 0.0

	# --- DRIVE SOUND: play when moving, stop when idle ---
	if input_dir.length() > 0:
		if not drive_sound.playing:
			drive_sound.play()
	else:
		if drive_sound.playing:
			drive_sound.stop()

	# Apply movement
	move_and_slide()

	# --- BONK SOUND: play when sliding into walls ---
	#if get_slide_collision_count() > 0:
	#	if not bonk_sound.playing:
	#		bonk_sound.play()
