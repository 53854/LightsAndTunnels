extends Control

@onready var status_label = $CenterContainer/VBoxContainer/StatusLabel
@onready var retry_button = $CenterContainer/VBoxContainer/RetryButton

func _ready():
	retry_button.visible = false
	retry_button.pressed.connect(start_sequence)
	start_sequence()

func start_sequence():
	retry_button.visible = false
	status_label.text = "Initializing..."
	
	# Step 1: Install Dependencies
	await get_tree().create_timer(0.1).timeout # UI Update
	
	var install_ok = GameServer.install_dependencies()
	if not install_ok:
		status_label.text = "Error: Failed to install dependencies (npm install)."
		retry_button.visible = true
		return
		
	status_label.text = "Dependencies OK.\nStarting API Server..."
	await get_tree().create_timer(0.1).timeout # UI Update
	
	# Step 2: Start Server
	var start_ok = GameServer.start_server()
	if not start_ok:
		status_label.text = "Error: Failed to start Node.js server."
		retry_button.visible = true
		return
		
	status_label.text = "Server Started.\nWaiting for connection..."
	
	# Step 3: Wait for Health Check
	check_connection_loop()

func check_connection_loop(attempts = 0):
	if attempts > 20: # Increased attempts (20 seconds)
		status_label.text = "Error: Connection timeout. Check console window."
		retry_button.visible = true
		return
		
	# specific local check to see if server is up
	var http = HTTPRequest.new()
	add_child(http)
	
	# We use a short timeout (e.g. 1s) for the request itself if possible, 
	# but HTTPRequest doesn't have a simple timeout property easily accessible in 4.x without settings.
	# We'll just rely on the request return.
	
	var err = http.request(GameServer.API_URL + "/getState")
	if err != OK:
		# Request failed to even start (e.g. busy?)
		print("HTTP Request failed to start: ", err)
		http.queue_free()
		await get_tree().create_timer(1.0).timeout
		check_connection_loop(attempts + 1)
		return

	# Wait for response
	var result = await http.request_completed
	http.queue_free()
	
	var result_code = result[0]
	var response_code = result[1]
	
	# Result 0 is RESULT_SUCCESS, 4 is RESULT_CANT_CONNECT.
	if result_code == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		status_label.text = "Connected! Launching Game..."
		await get_tree().create_timer(0.5).timeout
		GameServer.start_polling() # Start the global poll loop
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
	else:
		# Server might be starting up (connection refused or 404/500)
		status_label.text = "Waiting for server... (%d)" % (attempts + 1)
		await get_tree().create_timer(1.0).timeout
		check_connection_loop(attempts + 1)
