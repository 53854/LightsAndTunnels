extends Node2D

@onready var win_ui = $WinLayer/Label
@onready var quit_dialog = $HUD/QuitDialog

func _ready():
	if win_ui:
		win_ui.visible = false
	if quit_dialog:
		quit_dialog.visible = false


func _on_final_room_body_entered(body):
	if body.is_in_group("player"):
		print("Player entered final room!")
		if win_ui:
			win_ui.visible = true

func _on_reset_button_pressed():
	get_tree().reload_current_scene()

func _on_quit_button_pressed():
	if quit_dialog:
		quit_dialog.visible = true

func _on_confirm_quit_pressed():
	get_tree().quit()

func _on_cancel_quit_pressed():
	if quit_dialog:
		quit_dialog.visible = false
