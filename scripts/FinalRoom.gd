extends Area2D

# Audio references
@onready var win_player = $WinPlayer
@onready var ambiance_player = $AmbiancePlayer

# References to HUD and Final Room elements
var victory_title: Label
var victory_time_label: Label
var hud_fireworks: Node2D
var final_room_fireworks: Node2D
var main_script: Node

var wurde_aktiviert := false
var elapsed_time := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Get references after a small delay to allow scene to load
	await get_tree().process_frame
	
	var main = get_parent()
	if main:
		main_script = main
		victory_title = main.get_node("HUD/VictoryTitle")
		victory_time_label = main.get_node("HUD/VictoryTimeLabel")
		hud_fireworks = main.get_node("HUD/Fireworks")
		final_room_fireworks = get_node("Fireworks")


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not wurde_aktiviert:
		wurde_aktiviert = true
		sieges_sequenz_starten(body)


func sieges_sequenz_starten(player: CharacterBody2D) -> void:
	# Stop Main timer
	if main_script and main_script.has_method("stop_timer"):
		elapsed_time = main_script.elapsed_time
		main_script.stop_timer()
	
	# 1. Stop Player engine
	if player.has_node("EnginePlayer"):
		player.get_node("EnginePlayer").stop()
		player.is_moving = false
	
	# 2. Rainbow animation for Roomba (infinite loop)
	var sprite = player.get_node("Sprite2D")
	if sprite:
		var color_tween = create_tween().set_loops()
		color_tween.tween_property(sprite, "modulate", Color.RED, 0.4)
		color_tween.tween_property(sprite, "modulate", Color.YELLOW, 0.4)
		color_tween.tween_property(sprite, "modulate", Color.GREEN, 0.4)
		color_tween.tween_property(sprite, "modulate", Color.CYAN, 0.4)
		color_tween.tween_property(sprite, "modulate", Color.MAGENTA, 0.4)
		color_tween.tween_property(sprite, "modulate", Color.WHITE, 0.4)
	
# 3. Display victory text
	show_victory_screen()
	
	# 4. Son de victoire
	if win_player:
		win_player.play()
	
# 5. Start fireworks
	start_fireworks()
	
		# 6. Ambiance after 2 seconds
	await get_tree().create_timer(2.0).timeout
	if ambiance_player:
		ambiance_player.play()


func show_victory_screen() -> void:
	# Display victory title
	if victory_title:
		victory_title.visible = true
		victory_title.scale = Vector2(0.1, 0.1)
		victory_title.modulate.a = 0.0
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(victory_title, "scale", Vector2(1.2, 1.2), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(victory_title, "modulate:a", 1.0, 0.5)
	
	# Display time
	if victory_time_label:
		var time_text = get_time_string(elapsed_time)
		victory_time_label.text = "TIME: " + time_text
		victory_time_label.visible = true
		victory_time_label.scale = Vector2(0.1, 0.1)
		victory_time_label.modulate.a = 0.0
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(victory_time_label, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(victory_time_label, "modulate:a", 1.0, 0.5)
	else:
		print("ERROR: victory_time_label is null!")


func get_time_string(time: float) -> String:
	var minutes = int(time / 60)
	var seconds = int(time) % 60
	return "%02d:%02d" % [minutes, seconds]


func start_fireworks() -> void:
	# Display HUD and Final Room fireworks
	if hud_fireworks:
		hud_fireworks.visible = true
	
	# Infinite loop of fireworks while in victory state
	while true:
		# Sequence 1: Center explosion
		await burst_sequence([4], 0.2)
		await get_tree().create_timer(0.3).timeout
		
		# Sequence 2: Diagonal corners
		await burst_sequence([1, 3, 2, 5], 0.15)
		await get_tree().create_timer(0.4).timeout
		
		# Sequence 3: Top and bottom
		await burst_sequence([6, 8, 7], 0.1)
		await get_tree().create_timer(0.3).timeout
		
		# Sequence 4: Sides
		await burst_sequence([9, 11, 10, 12], 0.12)
		await get_tree().create_timer(0.4).timeout
		
		# Sequence 5: Final explosion - all together
		await burst_sequence([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], 0.08)
		await get_tree().create_timer(0.5).timeout
		
		# Sequence 6: Quick double finale
		await burst_sequence([2, 4, 7, 9, 11], 0.1)
		await get_tree().create_timer(0.2).timeout
		await burst_sequence([1, 3, 5, 8, 10, 12], 0.1)
		
		# Pause before restarting
		await get_tree().create_timer(1.0).timeout


func burst_sequence(firework_indices: Array, delay: float) -> void:
	for idx in firework_indices:
		var firework_name = get_firework_name(idx)
		_burst_firework_hud(firework_name)
		_burst_firework_final(firework_name)
		await get_tree().create_timer(delay).timeout


func get_firework_name(index: int) -> String:
	match index:
		1: return "Firework1"
		2: return "Firework2"
		3: return "Firework3"
		4: return "Firework4"
		5: return "Firework5"
		6: return "FireworkTop1"
		7: return "FireworkTop2"
		8: return "FireworkTop3"
		9: return "FireworkSideL1"
		10: return "FireworkSideL2"
		11: return "FireworkSideR1"
		12: return "FireworkSideR2"
		_: return "Firework1"


func _burst_firework_hud(fw_name: String) -> void:
	if not hud_fireworks:
		return
	var fw = hud_fireworks.get_node_or_null(fw_name)
	if fw:
		fw.emitting = false  # Reset one_shot
		fw.emitting = true   # Trigger emission


func _burst_firework_final(fw_name: String) -> void:
	if not final_room_fireworks:
		return
	var fw = final_room_fireworks.get_node_or_null(fw_name)
	if fw:
		fw.emitting = false  # Reset one_shot
		fw.emitting = true   # Trigger emission
