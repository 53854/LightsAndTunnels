extends Node2D

@onready var win_ui = $WinLayer/Label
@onready var quit_dialog = $HUD/QuitDialog
@onready var locked_layer = $LockedLayer

func _ready():
	if win_ui:
		win_ui.visible = false
	if quit_dialog:
		quit_dialog.visible = false
	if locked_layer:
		locked_layer.visible = true # Default to locked until we know otherwise
		get_tree().paused = true
	
	# Connect to Global GameServer signals
	GameServer.state_changed.connect(_on_api_state_changed)
	
	# Handle "starting" state handshake
	if GameServer.current_state == "starting":
		GameServer.send_restart_complete()
	
	# In case we entered with a state already set (e.g. from Boot)
	_on_api_state_changed(GameServer.current_state)

func _on_api_state_changed(new_state):
	if not is_inside_tree():
		return
		
	print("Game: API State is now ", new_state)
	
	if new_state == "starting":
		# API requested a restart
		get_tree().paused = false
		get_tree().reload_current_scene()
		
	elif new_state == "locked" or new_state == "starting":
		if locked_layer: locked_layer.visible = true
		get_tree().paused = true
		
	elif new_state == "running":
		if locked_layer: locked_layer.visible = false
		get_tree().paused = false # Unpause
		if win_ui: win_ui.visible = false
		
	elif new_state == "solved":
		# API says we are solved
		get_tree().paused = false
		if win_ui: win_ui.visible = true

func _on_final_room_body_entered(body):
	if body.is_in_group("player"):
		print("Player entered final room!")
		if win_ui:
			win_ui.visible = true
		
		# Wait 4 seconds before telling API to solve (so player sees win message)
		# Note: We must ensure we don't spam this if player enters/exits.
		# Ideally we disable the Area or use a "won" flag.
		
		# Simple debounce/one-shot check could be good but for now let's just wait.
		await get_tree().create_timer(4.0).timeout
		
		# Report to API
		GameServer.set_api_state("solved")

func _on_reset_button_pressed():
	# Local reset or API reset?
	# For now, let's keep it local, but maybe we should tell API we are 'starting' again?
	# GameServer.set_api_state("starting") # If we want to sync
	get_tree().reload_current_scene()

func _on_quit_button_pressed():
	if quit_dialog:
		quit_dialog.visible = true

func _on_confirm_quit_pressed():
	get_tree().quit()

func _on_cancel_quit_pressed():
	if quit_dialog:
		quit_dialog.visible = false
