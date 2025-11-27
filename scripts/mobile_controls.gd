extends CanvasLayer

@onready var player = $".."

func _on_forward_button_down() -> void:
	Input.action_press("move_forward")

func _on_forward_button_up() -> void:
	Input.action_release("move_forward")

func _on_backward_button_down() -> void:
	Input.action_press("move_back")

func _on_backward_button_up() -> void:
	Input.action_release("move_back")

func _on_left_button_down() -> void:
	if player: player.turning_left = true

func _on_left_button_up() -> void:
	if player: player.turning_left = false

func _on_right_button_down() -> void:
	if player: player.turning_right = true

func _on_right_button_up() -> void:
	if player: player.turning_right = false
