extends CharacterBody2D

@export var speed: float = 150.0
@export var acceleration: float = 800.0
@export var friction: float = 1000.0

func _physics_process(delta):
	# Mouse movement logic
	var target_velocity = Vector2.ZERO
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = get_global_mouse_position()
		var direction = (mouse_pos - global_position)
		
		# Look at mouse
		rotation = direction.angle()
		
		# Move if not super close
		if direction.length() > 5.0:
			target_velocity = direction.normalized() * speed
	
	if target_velocity != Vector2.ZERO:
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
	
	# Push rigid bodies
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody2D:
			c.get_collider().apply_central_impulse(-c.get_normal() * 10.0)
