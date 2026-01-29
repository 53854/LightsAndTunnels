extends RigidBody2D

func _ready() -> void:
	freeze = true
	# Wir lassen den Standard-Modus auf STATIC für den gefrorenen Zustand
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	lock_rotation = true
	gravity_scale = 0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	# Hohes Damp sorgt dafür, dass die Barriere nach dem Stoß schnell stoppt
	linear_damp = 12.0 
	angular_damp = 12.0
	can_sleep = true
	sleeping = true

func make_pushable() -> void:
	# WICHTIG: Einfach nur freeze ausschalten. 
	# Den freeze_mode müssen wir nicht auf KINEMATIC setzen.
	freeze = false
	sleeping = false
