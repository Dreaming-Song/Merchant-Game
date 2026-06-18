extends Node
## 联机网络管理器 - Phase 3
## Godot WebSocket 客户端，与 FastAPI 后端通信

signal connected()
signal disconnected()
signal room_created(room_id: String)
signal room_joined(room_id: String)
signal player_joined(player_id: String)
signal player_left(player_id: String)
signal player_state_received(player_id: String, state: Dictionary)
signal chat_received(player_id: String, message: String)
signal connection_error(message: String)
signal rooms_list_received(rooms: Array)

# ---------- 配置 ----------
@export var server_url: String = "ws://localhost:8765/ws"
@export var http_url: String = "http://localhost:8765"
@export var reconnect_interval: float = 3.0

# ---------- 状态 ----------
var player_id: String = ""
var current_room_id: String = ""
var is_connected: bool = false

var _socket: WebSocketPeer = WebSocketPeer.new()
var _reconnect_timer: float = 0.0
var _should_reconnect: bool = false

func _ready() -> void:
	# 生成玩家 ID
	player_id = _generate_player_id()

func _process(delta: float) -> void:
	_socket.poll()

	if _socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		while _socket.get_available_packet_count() > 0:
			var raw = _socket.get_packet().get_string_from_utf8()
			_handle_message(raw)
	elif _socket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		if _should_reconnect and not is_connected:
			_reconnect_timer += delta
			if _reconnect_timer >= reconnect_interval:
				_reconnect_timer = 0.0
				connect_to_server()

# ===================== 连接管理 =====================

func connect_to_server() -> void:
	"""连接服务端"""
	var url = server_url + "/" + player_id
	var err = _socket.connect_to_url(url)
	if err != OK:
		connection_error.emit("连接失败: " + str(err))
		return
	_should_reconnect = true
	print("📡 正在连接服务端...")

func disconnect_from_server() -> void:
	"""断开连接"""
	_should_reconnect = false
	_socket.close()
	is_connected = false
	current_room_id = ""
	disconnected.emit()

func _handle_message(raw: String) -> void:
	"""处理服务端消息"""
	var json: JSON = JSON.new()
	var err = json.parse(raw)
	if err != OK:
		return
	var msg: Dictionary = json.data
	var msg_type: String = msg.get("type", "")

	match msg_type:
		# 连接状态
		"connected":
			is_connected = true
			connected.emit()
			print("✅ 已连接服务端")

		# 房间
		"room_created":
			current_room_id = msg.room_id
			room_created.emit(msg.room_id)
			print("🏠 房间已创建: " + msg.room_id)

		"room_joined":
			current_room_id = msg.room_id
			room_joined.emit(msg.room_id)
			print("🚪 已加入房间: " + msg.room_id)

		"player_joined":
			player_joined.emit(msg.player_id)
			print("👤 玩家加入: " + msg.player_id)

		"player_left":
			player_left.emit(msg.player_id)
			print("👋 玩家离开: " + msg.player_id)

		# 同步
		"player_state":
			player_state_received.emit(msg.player_id, msg.state)

		# 聊天
		"chat":
			chat_received.emit(msg.player_id, msg.message)

		# 错误
		"error":
			connection_error.emit(msg.get("message", "未知错误"))

# ===================== 发送消息 =====================

func _send(data: Dictionary) -> void:
	if _socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	_socket.send_text(JSON.stringify(data))

func send_player_state(x: float, y: float, z: float, rot_x: float, rot_y: float,
	hp: int, mp: int, is_flying: bool, pet_id: String = "") -> void:
	"""发送玩家位置状态"""
	_send({
		"type": "player_update",
		"x": x, "y": y, "z": z,
		"rot_x": rot_x, "rot_y": rot_y,
		"hp": hp, "mp": mp,
		"is_flying": is_flying
	})

func create_room(name: String = "新房间", max_players: int = 4) -> void:
	"""创建房间"""
	_send({
		"type": "create_room",
		"name": name,
		"max_players": max_players,
	})

func join_room(room_id: String, password: String = "") -> void:
	"""加入房间"""
	_send({
		"type": "join_room",
		"room_id": room_id,
		"password": password,
	})

func leave_room() -> void:
	"""离开房间"""
	_send({"type": "leave_room"})
	current_room_id = ""

func send_chat(message: String) -> void:
	"""发送聊天消息"""
	_send({"type": "chat", "message": message})

# ===================== HTTP 接口 =====================

func fetch_rooms_list() -> void:
	"""HTTP 获取房间列表"""
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_rooms_list_received)
	http.request(http_url + "/api/rooms")

func _on_rooms_list_received(result: int, code: int, headers: Array, body: PackedByteArray) -> void:
	if code == 200:
		var json: JSON = JSON.new()
		json.parse(body.get_string_from_utf8())
		rooms_list_received.emit(json.data.get("rooms", []))
	else:
		connection_error.emit("获取房间列表失败")

# ===================== 工具 =====================

func _generate_player_id() -> String:
	"""生成唯一玩家 ID"""
	var chars = "abcdefghijklmnopqrstuvwxyz0123456789"
	var id = "player_"
	for i in range(6):
		id += chars[randi() % chars.length()]
	return id
