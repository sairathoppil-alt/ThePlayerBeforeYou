extends Node

const TownLocations = preload("res://scripts/core/town_locations.gd")

signal connection_changed(connected: bool)
signal connection_failed(message: String)
signal remote_player_moved(peer_id: int, transform: Transform3D, moving: bool, selected_item: String)
signal chat_received(peer_id: int, text: String, sent_at: int)
signal marker_received(peer_id: int, location_id: String, label: String)
signal journal_received(peer_id: int, entry_id: String, text: String)
signal world_flag_received(peer_id: int, flag_id: String, value: bool)
signal mission_objective_received(objective_id: String, role: String)
signal puzzle_state_received(update_type: String, payload: Dictionary)

const DEFAULT_PORT := 24680
const MAX_CLIENTS := 1
const MAX_CHAT_LENGTH := 240
const SHARED_WORLD_FLAGS := [
	"drainage.valve_open",
	"water.level.lower",
	"water.level.bypass",
	"water.level.release",
	"electrical.power_routed",
	"electrical.route.cyan",
	"electrical.route.amber",
	"electrical.route.white",
	"photo.crate_moved",
	"photo.barrier_moved",
	"room.wall_moved",
	"capsule.capacitor_sent",
	"capsule.capacitor_retrieved",
	"machine.repaired",
	"npc.supplies_relocated",
	"npc.supplies_declined",
	"npc.supplies_retrieved",
	"blueprint.left",
	"blueprint.right",
	"blueprint.deck",
	"floodgate.configured"
]

var last_error := ""
var room_address := ""
var timeline_role := "past"
var _peer: ENetMultiplayerPeer
var _last_host_address := ""
var _last_host_port := DEFAULT_PORT
var _reconnecting := false


func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)


func create_room(port: int = DEFAULT_PORT) -> bool:
	leave_room()
	_peer = ENetMultiplayerPeer.new()
	var result := _peer.create_server(port, MAX_CLIENTS)
	if result != OK:
		_peer = null
		return _fail("Could not create a room on port %d: %s" % [port, error_string(result)])
	multiplayer.multiplayer_peer = _peer
	room_address = "HOST:%d" % port
	timeline_role = "past"
	last_error = ""
	connection_changed.emit(true)
	return true


func join_room(address: String, port: int = DEFAULT_PORT) -> bool:
	leave_room()
	var clean_address := address.strip_edges()
	if clean_address.is_empty():
		return _fail("Enter the host's IP address or hostname.")
	_peer = ENetMultiplayerPeer.new()
	var result := _peer.create_client(clean_address, port)
	if result != OK:
		_peer = null
		return _fail("Could not join %s:%d: %s" % [clean_address, port, error_string(result)])
	multiplayer.multiplayer_peer = _peer
	room_address = "%s:%d" % [clean_address, port]
	timeline_role = "future"
	_last_host_address = clean_address
	_last_host_port = port
	last_error = ""
	return true


func leave_room() -> void:
	if _peer != null:
		_peer.close()
		_peer = null
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	room_address = ""
	timeline_role = "past"
	_last_host_address = ""
	_last_host_port = DEFAULT_PORT
	_reconnecting = false
	connection_changed.emit(false)


func is_connected_to_partner() -> bool:
	return multiplayer.multiplayer_peer != null and multiplayer.get_peers().size() > 0


func is_host() -> bool:
	return multiplayer.is_server() and multiplayer.multiplayer_peer != null


func send_movement(transform: Transform3D, moving: bool, selected_item: String) -> void:
	if not is_connected_to_partner():
		return
	var peer_id := multiplayer.get_unique_id()
	if multiplayer.is_server():
		remote_player_moved.emit(peer_id, transform, moving, selected_item)
		rpc("relay_movement", peer_id, transform, moving, selected_item)
	else:
		rpc_id(1, "submit_movement", transform, moving, selected_item)


@rpc("any_peer", "call_remote", "unreliable")
func submit_movement(transform: Transform3D, moving: bool, selected_item: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id <= 1:
		return
	rpc("relay_movement", sender_id, transform, moving, selected_item)
	remote_player_moved.emit(sender_id, transform, moving, selected_item)


@rpc("authority", "call_remote", "unreliable")
func relay_movement(peer_id: int, transform: Transform3D, moving: bool, selected_item: String) -> void:
	remote_player_moved.emit(peer_id, transform, moving, selected_item)


func send_chat(text: String) -> bool:
	var clean_text := text.strip_edges()
	if clean_text.is_empty() or clean_text.length() > MAX_CHAT_LENGTH:
		return _fail("Messages must contain 1–240 characters.")
	if not is_connected_to_partner():
		return _fail("Echo Link is local-only until a partner joins the room.")
	var sender_id := multiplayer.get_unique_id()
	var sent_at := Time.get_unix_time_from_system()
	if multiplayer.is_server():
		chat_received.emit(sender_id, clean_text, sent_at)
		rpc("deliver_chat", sender_id, clean_text, sent_at)
	else:
		rpc_id(1, "submit_chat", clean_text, sent_at)
	return true


@rpc("any_peer", "call_remote", "reliable")
func submit_chat(text: String, sent_at: int) -> void:
	if not multiplayer.is_server():
		return
	var clean_text := text.strip_edges()
	if clean_text.is_empty() or clean_text.length() > MAX_CHAT_LENGTH:
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id <= 1:
		return
	chat_received.emit(sender_id, clean_text, sent_at)
	rpc("deliver_chat", sender_id, clean_text, sent_at)


@rpc("authority", "call_remote", "reliable")
func deliver_chat(peer_id: int, text: String, sent_at: int) -> void:
	chat_received.emit(peer_id, text, sent_at)


func send_marker(location_id: String, label: String) -> bool:
	if not is_connected_to_partner():
		return _fail("Location markers are shared only while connected to a partner.")
	if not TownLocations.LOCATIONS.has(location_id):
		return _fail("Unknown shared location: %s" % location_id)
	var sender_id := multiplayer.get_unique_id()
	if multiplayer.is_server():
		marker_received.emit(sender_id, location_id, label)
		rpc("deliver_marker", sender_id, location_id, label)
	else:
		rpc_id(1, "submit_marker", location_id, label)
	return true


func send_journal_entry(entry_id: String, text: String) -> bool:
	var clean_id := entry_id.strip_edges()
	var clean_text := text.strip_edges()
	if clean_id.is_empty() or clean_id.length() > 96 or clean_text.is_empty() or clean_text.length() > 500:
		return _fail("Shared discoveries require an ID and 1–500 characters of text.")
	if not is_connected_to_partner():
		return _fail("Journal entries remain local until a partner joins the room.")
	var sender_id := multiplayer.get_unique_id()
	if multiplayer.is_server():
		journal_received.emit(sender_id, clean_id, clean_text)
		rpc("deliver_journal_entry", sender_id, clean_id, clean_text)
	else:
		rpc_id(1, "submit_journal_entry", clean_id, clean_text)
	return true


func send_world_flag(flag_id: String, value: bool) -> bool:
	if not is_connected_to_partner() or not SHARED_WORLD_FLAGS.has(flag_id):
		return false
	var sender_id := multiplayer.get_unique_id()
	if multiplayer.is_server():
		rpc("deliver_world_flag", sender_id, flag_id, value)
	else:
		rpc_id(1, "submit_world_flag", flag_id, value)
	return true


func send_mission_objective(objective_id: String) -> bool:
	if not is_connected_to_partner() or not MissionSystem.is_valid_objective(objective_id):
		return _fail("Mission progress cannot be shared right now.")
	if multiplayer.is_server():
		rpc("deliver_mission_objective", 1, objective_id, "past")
	else:
		rpc_id(1, "submit_mission_objective", objective_id)
	return true


func send_shared_snapshot(peer_id: int) -> void:
	if not multiplayer.is_server() or peer_id <= 1:
		return
	var state: Dictionary = AdventureState.get_state()
	var messages: Array = state.get("messages", [])
	var journal: Array = state.get("journal", [])
	var markers: Array = state.get("markers", [])
	var snapshot := {
		"world_flags": state.get("world_flags", {}),
		"journal": journal.slice(maxi(0, journal.size() - 100), journal.size()),
		"messages": messages.slice(maxi(0, messages.size() - 100), messages.size()),
		"markers": markers.slice(maxi(0, markers.size() - 100), markers.size()),
		"mission_progress": state.get("mission_progress", {}),
		"time_capsules": state.get("time_capsules", []),
		"cement_messages": state.get("cement_messages", []),
		"musical_sequences": state.get("musical_sequences", []),
	}
	rpc_id(peer_id, "apply_shared_snapshot", snapshot)


@rpc("authority", "call_remote", "reliable")
func apply_shared_snapshot(snapshot: Dictionary) -> void:
	if snapshot.keys().size() > 9:
		return
	AdventureState.merge_shared_snapshot(snapshot)


func send_puzzle_state(update_type: String, payload: Dictionary) -> bool:
	if not is_connected_to_partner():
		return _fail("Puzzle state remains local until a partner joins the room.")
	if update_type not in ["capsule", "cement_message", "music_sequence"]:
		return _fail("Unsupported shared puzzle update.")
	var sender_id := multiplayer.get_unique_id()
	if not _puzzle_update_allowed(sender_id, update_type, payload):
		return _fail("This timeline role cannot publish that puzzle update.")
	if multiplayer.is_server():
		if not AdventureState.merge_shared_puzzle_update(update_type, payload):
			return _fail(AdventureState.last_error)
		puzzle_state_received.emit(update_type, payload)
		rpc("deliver_puzzle_state", sender_id, update_type, payload)
	else:
		rpc_id(1, "submit_puzzle_state", update_type, payload)
	return true


@rpc("any_peer", "call_remote", "reliable")
func submit_puzzle_state(update_type: String, payload: Dictionary) -> void:
	if not multiplayer.is_server() or str(payload).length() > 32768:
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id <= 1 or not _puzzle_update_allowed(sender_id, update_type, payload):
		return
	if AdventureState.merge_shared_puzzle_update(update_type, payload):
		puzzle_state_received.emit(update_type, payload)
		rpc("deliver_puzzle_state", sender_id, update_type, payload)


@rpc("authority", "call_remote", "reliable")
func deliver_puzzle_state(_sender_id: int, update_type: String, payload: Dictionary) -> void:
	if AdventureState.merge_shared_puzzle_update(update_type, payload):
		puzzle_state_received.emit(update_type, payload)


func _puzzle_update_allowed(sender_id: int, update_type: String, payload: Dictionary) -> bool:
	if update_type == "capsule":
		var is_retrieval := bool(payload.get("retrieved", false))
		return sender_id > 1 if is_retrieval else sender_id == 1
	return sender_id == 1


@rpc("any_peer", "call_remote", "reliable")
func submit_mission_objective(objective_id: String) -> void:
	if not multiplayer.is_server() or not MissionSystem.is_valid_objective(objective_id):
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id != 2 or not MissionSystem.apply_remote_objective(objective_id, "future"):
		return
	rpc("deliver_mission_objective", sender_id, objective_id, "future")


@rpc("authority", "call_remote", "reliable")
func deliver_mission_objective(_peer_id: int, objective_id: String, role: String) -> void:
	if MissionSystem.apply_remote_objective(objective_id, role):
		mission_objective_received.emit(objective_id, role)


@rpc("any_peer", "call_remote", "reliable")
func submit_world_flag(flag_id: String, value: bool) -> void:
	if not multiplayer.is_server() or not SHARED_WORLD_FLAGS.has(flag_id):
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id <= 1:
		return
	world_flag_received.emit(sender_id, flag_id, value)
	rpc("deliver_world_flag", sender_id, flag_id, value)


@rpc("authority", "call_remote", "reliable")
func deliver_world_flag(peer_id: int, flag_id: String, value: bool) -> void:
	world_flag_received.emit(peer_id, flag_id, value)


@rpc("any_peer", "call_remote", "reliable")
func submit_marker(location_id: String, label: String) -> void:
	if not multiplayer.is_server() or not TownLocations.LOCATIONS.has(location_id):
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id <= 1:
		return
	var clean_label := label.substr(0, 80)
	marker_received.emit(sender_id, location_id, clean_label)
	rpc("deliver_marker", sender_id, location_id, clean_label)


@rpc("authority", "call_remote", "reliable")
func deliver_marker(peer_id: int, location_id: String, label: String) -> void:
	marker_received.emit(peer_id, location_id, label)


@rpc("any_peer", "call_remote", "reliable")
func submit_journal_entry(entry_id: String, text: String) -> void:
	if not multiplayer.is_server():
		return
	var clean_id := entry_id.strip_edges()
	var clean_text := text.strip_edges()
	if clean_id.is_empty() or clean_id.length() > 96 or clean_text.is_empty() or clean_text.length() > 500:
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id <= 1:
		return
	journal_received.emit(sender_id, clean_id, clean_text)
	rpc("deliver_journal_entry", sender_id, clean_id, clean_text)


@rpc("authority", "call_remote", "reliable")
func deliver_journal_entry(peer_id: int, entry_id: String, text: String) -> void:
	journal_received.emit(peer_id, entry_id, text)


func _on_connected_to_server() -> void:
	last_error = ""
	connection_changed.emit(true)


func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		send_shared_snapshot(peer_id)


func _on_connection_failed() -> void:
	if _reconnecting:
		last_error = "Room reconnection attempt failed."
		return
	_fail("Room connection failed. Check the address, port and network firewall.")
	leave_room()
	connection_failed.emit(last_error)


func _on_server_disconnected() -> void:
	if _reconnecting:
		return
	var address := _last_host_address
	var port := _last_host_port
	leave_room()
	if address.is_empty():
		connection_failed.emit("The room host disconnected. Rejoin the room manually.")
		return
	connection_failed.emit("The room host disconnected. Retrying the saved room address.")
	call_deferred("_reconnect_to_host", address, port)


func _reconnect_to_host(address: String, port: int) -> void:
	_reconnecting = true
	for attempt in range(3):
		if not _reconnecting:
			return
		var candidate := ENetMultiplayerPeer.new()
		var result := candidate.create_client(address, port)
		if result == OK:
			_peer = candidate
			multiplayer.multiplayer_peer = _peer
			room_address = "%s:%d" % [address, port]
			timeline_role = "future"
			await get_tree().create_timer(1.5 * float(attempt + 1)).timeout
			if not _reconnecting:
				return
			if _peer != null and _peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				_last_host_address = address
				_last_host_port = port
				_reconnecting = false
				return
			if _peer != null:
				_peer.close()
			_peer = null
			multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
			room_address = ""
		else:
			last_error = "Reconnect attempt %d failed: %s" % [attempt + 1, error_string(result)]
			candidate.close()
		await get_tree().create_timer(0.5).timeout
	_reconnecting = false
	timeline_role = "past"
	room_address = ""
	connection_failed.emit("Automatic reconnection failed after three attempts. Rejoin the room manually.")


func _fail(message: String) -> bool:
	last_error = message
	return false
