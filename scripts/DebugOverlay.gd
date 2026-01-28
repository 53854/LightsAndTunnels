extends CanvasLayer

@onready var log_display = $Panel/VBoxContainer/LogDisplay
@onready var panel = $Panel

var timer = 0.0
const POLL_INTERVAL = 0.5

func _ready():
	visible = false # Hidden by default
	
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		visible = not visible

func _process(delta):
	if not visible:
		return
		
	timer += delta
	if timer > POLL_INTERVAL:
		timer = 0.0
		update_logs()

func update_logs():
	log_display.text = GameServer.get_latest_logs(30)

func _on_close_button_pressed():
	visible = false
