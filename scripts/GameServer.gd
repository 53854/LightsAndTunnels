extends Node

signal state_changed(new_state)

const API_PORT = 5001
const API_URL = "http://127.0.0.1:%d" % API_PORT

var server_pid = -1
var current_state = "locked"
var http_request: HTTPRequest

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # Keep running even if game is paused
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		stop_server()

# --- Process Management ---

func get_api_dir() -> String:
	# In editor: res://api -> mapped to absolute path
	# Exported: look for "api" folder next to executable
	var path = ""
	if OS.has_feature("editor"):
		path = ProjectSettings.globalize_path("res://api")
	else:
		path = OS.get_executable_path().get_base_dir().path_join("api")
	return path

func install_dependencies() -> bool:
	var api_dir = get_api_dir()
	print("Installing dependencies in: ", api_dir)
	var output = []
	var exit_code = -1
	
	if OS.get_name() == "Windows":
		# Windows requires cmd /c to run npm (batch check)
		# We use --prefix to specify the folder
		exit_code = OS.execute("cmd", ["/c", "npm", "install", "--prefix", api_dir], output, true)
	else:
		# Unix-like
		exit_code = OS.execute("npm", ["install", "--prefix", api_dir], output, true)
		
	if exit_code != 0:
		printerr("npm install failed (Exit Code: %d): " % exit_code, output)
		return false
	print("npm install success: ", output)
	return true

func start_server() -> bool:
	if server_pid != -1:
		print("Server already running (PID: %d)" % server_pid)
		return true

	var api_dir = get_api_dir()
	var script_path = api_dir.path_join("PuzzleTemplate.js")
	
	print("Starting Node.js server at: ", script_path)
	
	# Create process non-blocking
	# open_console=true for debugging visibility
	var args = [script_path, "--port", str(API_PORT)]
	
	if OS.get_name() == "Windows":
		server_pid = OS.create_process("node", args, true)
	else:
		server_pid = OS.create_process("node", args, true)
	
	if server_pid == -1:
		printerr("Failed to create Node.js process.")
		return false
		
	print("Node.js server started with PID: ", server_pid)
	return true

func stop_server():
	if server_pid != -1:
		print("Stopping server (PID: %d)..." % server_pid)
		OS.kill(server_pid)
		server_pid = -1

# --- API Communication ---

func check_health() -> void:
	# specific check to see if server is up
	http_request.request(API_URL + "/getState")

func set_api_state(state: String) -> void:
	var json = JSON.stringify({"state": state})
	var headers = ["Content-Type: application/json"]
	http_request.request(API_URL + "/setState", headers, HTTPClient.METHOD_POST, json)

func poll_state() -> void:
	http_request.request(API_URL + "/getState")

func _on_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		# Server might not be ready yet or crashed
		return

	if response_code == 200:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		if parse_result == OK:
			var data = json.get_data()
			if "state" in data:
				var new_state = data["state"]
				if new_state != current_state:
					current_state = new_state
					state_changed.emit(current_state)
					print("API State Changed: ", current_state)

# Polling Helper
var _poll_timer: Timer
func start_polling(interval: float = 1.0):
	if not _poll_timer:
		_poll_timer = Timer.new()
		add_child(_poll_timer)
		_poll_timer.timeout.connect(poll_state)
	_poll_timer.wait_time = interval
	_poll_timer.start()
	poll_state()
