extends CharacterBody2D

@export var speed: float = 150.0
@export var acceleration: float = 800.0
@export var friction: float = 1000.0
@export var fade_duration: float = 0.5

@onready var propeller = $Propeller
@onready var engine_player = $EnginePlayer
@onready var sfx_player = $SfxPlayer
@onready var start_player = $StartPlayer

var sound_start = preload("res://assets/Audio/roomba_start.ogg")
var sound_stop = preload("res://assets/Audio/stop.ogg")
var sound_engine = preload("res://assets/Audio/roomba_during.ogg")

var propeller_speed := 0.0
var max_spin_speed := 15.0
var is_moving := false
var engine_max_volume_db := 0.0
var volume_tween: Tween
var stop_tween: Tween


func _ready():
	if start_player:
		start_player.stream = sound_start
		start_player.play()


func _physics_process(delta):
	# Check if player input is blocked (button clicked)
	var main = get_tree().root.find_child("Main", true, false)
	if main and main.block_player_input:
		# Stop roomba completely
		velocity = Vector2.ZERO
		move_and_slide()
		
		# Stop roomba sounds with quick fade out
		if is_moving:
			# Quick fade out (0.05s)
			if volume_tween:
				volume_tween.kill()
			volume_tween = create_tween()
			volume_tween.set_trans(Tween.TRANS_LINEAR)
			volume_tween.set_ease(Tween.EASE_IN)
			volume_tween.tween_property(engine_player, "volume_db", -80.0, 0.05)
			volume_tween.tween_callback(engine_player.stop)
			
# Stop SFX
			if sfx_player.playing:
				sfx_player.stop()
			
			is_moving = false
		
		return
	
	# Mouse movement logic
	var target_velocity = Vector2.ZERO
	
	var mouse_pos = get_global_mouse_position()
	var reset_button = get_tree().root.find_child("ResetButton", true, false)
	var quit_button = get_tree().root.find_child("QuitButton", true, false)
	var is_over_button = false
	
	if reset_button:
		var reset_rect = reset_button.get_global_rect()

		reset_rect = reset_rect.grow(5.0)
		if reset_rect.has_point(mouse_pos):
			is_over_button = true
	
	if quit_button:
		var quit_rect = quit_button.get_global_rect()
	
		quit_rect = quit_rect.grow(5.0)
		if quit_rect.has_point(mouse_pos):
			is_over_button = true
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not is_over_button:
		var direction = (mouse_pos - global_position)
		
		# Look at mouse
		rotation = direction.angle()
		
		# Move if not super close
		if direction.length() > 5.0:
			target_velocity = direction.normalized() * speed
	
	if target_velocity != Vector2.ZERO:
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
		
		# Start roomba with smooth fade in
		if not is_moving:
			is_moving = true
			
			# Cancel previous tween if exists
			if volume_tween:
				volume_tween.kill()
			
			# Start engine with loop
			if not engine_player.playing:
				engine_player.volume_db = -80.0
				engine_player.stream = sound_engine
				engine_player.bus = "SFX"
				engine_player.play()
			
			# Smooth fade in (0.3s)
			volume_tween = create_tween()
			volume_tween.set_trans(Tween.TRANS_SINE)
			volume_tween.set_ease(Tween.EASE_OUT)
			volume_tween.tween_property(engine_player, "volume_db", engine_max_volume_db, 0.3)
		
		# Restart engine if stopped (for loop)
		if engine_player and not engine_player.playing and is_moving:
			engine_player.play()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
		# Stop roomba with smooth fade out
		if is_moving:
			is_moving = false
			
			# Cancel previous tween if exists
			if volume_tween:
				volume_tween.kill()
			
			# Smooth fade out (0.6s)
			volume_tween = create_tween()
			volume_tween.set_trans(Tween.TRANS_SINE)
			volume_tween.set_ease(Tween.EASE_IN)
			volume_tween.tween_property(engine_player, "volume_db", -80.0, 0.6)
			volume_tween.tween_callback(engine_player.stop)
			
			# Play stop sound with fade out
			sfx_player.stream = sound_stop
			sfx_player.volume_db = 0.0
			sfx_player.play()
			
			# Cancel previous stop tween if exists
			if stop_tween:
				stop_tween.kill()
			
			# Fade out stop sound (0.3s)
			stop_tween = create_tween()
			stop_tween.set_trans(Tween.TRANS_SINE)
			stop_tween.set_ease(Tween.EASE_IN)
			stop_tween.tween_property(sfx_player, "volume_db", -80.0, 0.3)

	move_and_slide()
	
	# Propeller rotation based on movement
	var movement_strength = velocity.length()
	var target_spin = movement_strength / speed * max_spin_speed

	propeller_speed = lerp(propeller_speed, target_spin, 6 * delta)
	propeller.rotation += propeller_speed * delta
