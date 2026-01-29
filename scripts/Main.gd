extends Node2D

@onready var quit_dialog = $HUD/QuitDialog
@onready var timer_label = $HUD/TimerLabel
@onready var player = $Player
@onready var reset_button = $HUD/ResetButton
@onready var quit_button = $HUD/QuitButton
@onready var button_sound = $HUD/ButtonSound

var elapsed_time := 0.0
var timer_running := true
var block_player_input := false


func _ready():
	if quit_dialog:
		quit_dialog.visible = false
	
	if reset_button:
		reset_button.pressed.connect(_on_reset_button_pressed)
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)


func _process(delta: float) -> void:
	if timer_running:
		elapsed_time += delta
		update_timer_display()


func update_timer_display() -> void:
	if timer_label:
		var minutes = int(elapsed_time / 60)
		var seconds = int(elapsed_time) % 60
		timer_label.text = "%02d:%02d" % [minutes, seconds]


func stop_timer() -> void:
	timer_running = false


func _input(event: InputEvent) -> void:
	# Consommer l'événement si on clique sur un bouton pour empêcher le roomba de réagir
	if event is InputEventMouseButton:
		if reset_button.get_global_rect().has_point(get_global_mouse_position()):
			get_tree().root.set_input_as_handled()
		elif quit_button.get_global_rect().has_point(get_global_mouse_position()):
			get_tree().root.set_input_as_handled()


func _on_reset_button_pressed():
	print("Reset button pressed, playing sound")
	block_player_input = true
	if button_sound:
		button_sound.play()
		print("Sound playing: ", button_sound.playing)
	else:
		print("ERROR: button_sound is null")
	await get_tree().create_timer(0.3).timeout
	get_tree().reload_current_scene()


func _on_quit_button_pressed():
	print("Quit button pressed, playing sound")
	block_player_input = true
	if button_sound:
		button_sound.play()
		print("Sound playing: ", button_sound.playing)
	else:
		print("ERROR: button_sound is null")
	if quit_dialog:
		quit_dialog.visible = true
	await get_tree().create_timer(0.2).timeout
	block_player_input = false


func _on_confirm_quit_pressed():
	print("Confirm quit pressed, playing sound")
	block_player_input = true
	if button_sound:
		button_sound.play()
		print("Sound playing: ", button_sound.playing)
	else:
		print("ERROR: button_sound is null")
	await get_tree().create_timer(0.35).timeout
	get_tree().quit()


func _on_cancel_quit_pressed():
	print("Cancel quit pressed, playing sound")
	block_player_input = true
	if button_sound:
		button_sound.play()
		print("Sound playing: ", button_sound.playing)
	else:
		print("ERROR: button_sound is null")
	if quit_dialog:
		quit_dialog.visible = false
	await get_tree().create_timer(0.2).timeout
	block_player_input = false
