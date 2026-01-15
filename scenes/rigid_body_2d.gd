extends RigidBody2D

func _ready() -> void:
	freeze = true
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	lock_rotation = true
	gravity_scale = 0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	linear_damp = 12.0
	angular_damp = 12.0
	can_sleep = true
	sleeping = true

func make_pushable() -> void:
	freeze = false
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	sleeping = false
