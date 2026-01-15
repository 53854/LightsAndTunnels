extends CharacterBody2D

@export var speed := 150.0
@export var acceleration := 800.0
@export var friction := 1000.0

@export var push_strength := 70.0
@export var max_push_impulse := 140.0

func _physics_process(delta: float) -> void:
	var target_velocity := Vector2.ZERO

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos := get_global_mouse_position()
		var direction := mouse_pos - global_position
		rotation = direction.angle()

		if direction.length() > 5.0:
			target_velocity = direction.normalized() * speed

	if target_velocity != Vector2.ZERO:
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()

	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var rb := col.get_collider() as RigidBody2D
		if rb == null:
			continue

		if rb.has_method("make_pushable"):
			rb.call("make_pushable")

		var push_dir := -col.get_normal()
		push_dir.y = 0
		push_dir = push_dir.normalized()

		var impulse := push_dir * push_strength
		if impulse.length() > max_push_impulse:
			impulse = impulse.normalized() * max_push_impulse

		rb.apply_central_impulse(impulse)
