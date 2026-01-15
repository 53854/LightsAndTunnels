extends Node2D

@onready var win_ui = $WinLayer/Label

func _ready():
	if win_ui:
		win_ui.visible = false

func _on_final_room_body_entered(body):
	if body.is_in_group("player"):
		print("Player entered final room!")
		if win_ui:
			win_ui.visible = true

func _on_reset_button_pressed():
	get_tree().reload_current_scene()
