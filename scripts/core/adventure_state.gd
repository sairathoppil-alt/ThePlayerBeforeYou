extends Node

const TownLocations = preload("res://scripts/core/town_locations.gd")

signal state_changed(state: Dictionary)
signal error_occurred(message: String)

const SAVE_PATH := "user://adventure_state.json"
const SCHEMA_VERSION := 4
const INVENTORY_CAPACITY := 6
const MAX_MESSAGES := 500
const MAX_EVENTS := 1000
const LOCAL_REPOSITORY_SCRIPT = preload("res://scripts/core/local_json_repository.gd")

var state: Dictionary = {}
var last_error := ""
var _event_serial := 0
var _repository: RefCounted


func _ready() -> void:
	_repository = LOCAL_REPOSITORY_SCRIPT.new(SAVE_PATH)
	if _repository.call("exists"):
		load_state()
	else:
		state = _default_state()


func has_save() -> bool:
	return bool(_repository.call("exists")) if _repository != null else FileAccess.file_exists(SAVE_PATH)


func get_state() -> Dictionary:
	return state.duplicate(true)


func begin_new_adventure(allow_overwrite: bool = false) -> bool:
	if has_save() and not allow_overwrite:
		return _set_error("An adventure save already exists. Confirm before starting over.")
	state = _default_state()
	return save_state()


func load_state() -> bool:
	if not has_save():
		state = _default_state()
		return true
	var read_result: Dictionary = _repository.call("read_document")
	if not bool(read_result.get("ok", false)):
		return _set_error(str(read_result.get("error", "Could not read adventure save.")))
	var raw_data: Variant = read_result.get("data")
	var was_migrated := (
		typeof(raw_data) == TYPE_DICTIONARY
		and int(raw_data.get("schema_version", -1)) < SCHEMA_VERSION
	)
	var loaded_data: Variant = _migrate_state(raw_data)
	var validation_error := _validation_error(loaded_data)
	if not validation_error.is_empty():
		return _set_error("Adventure save is invalid: %s" % validation_error)
	state = loaded_data
	last_error = ""
	if was_migrated and not save_state():
		return false
	state_changed.emit(get_state())
	return true


func save_state() -> bool:
	var validation_error := _validation_error(state)
	if not validation_error.is_empty():
		return _set_error("Refused to save invalid adventure data: %s" % validation_error)
	if _repository == null:
		_repository = LOCAL_REPOSITORY_SCRIPT.new(SAVE_PATH)
	var write_error := str(_repository.call("write_document", state))
	if not write_error.is_empty():
		return _set_error(write_error)
	last_error = ""
	state_changed.emit(get_state())
	return true


func set_timeline(value: String) -> bool:
	if not ["past", "future"].has(value):
		return _set_error("Timeline must be 'past' or 'future'.")
	state["timeline"] = value
	return save_state()


func set_player_checkpoint(position: Vector3, yaw: float) -> void:
	state["player"] = {
		"position": [position.x, position.y, position.z],
		"yaw": yaw,
	}


func set_temporal_energy(value: float) -> bool:
	state["temporal_energy"] = maxf(0.0, value)
	return save_state()


func get_player_checkpoint() -> Dictionary:
	var player_state: Dictionary = state.get("player", {})
	var coordinates: Array = player_state.get("position", [14.0, 0.0, 31.0])
	return {
		"position": Vector3(float(coordinates[0]), float(coordinates[1]), float(coordinates[2])),
		"yaw": float(player_state.get("yaw", 0.0)),
	}


func has_world_flag(flag_id: String) -> bool:
	var flags: Dictionary = state.get("world_flags", {})
	return bool(flags.get(flag_id, false))


func set_world_flag(flag_id: String, value: bool, reversible: bool = false) -> bool:
	if flag_id.is_empty() or flag_id.length() > 96:
		return _set_error("World-state flag ID must contain 1–96 characters.")
	var flags: Dictionary = state.get("world_flags", {})
	var previous_value := bool(flags.get(flag_id, false))
	flags[flag_id] = value
	state["world_flags"] = flags
	record_event("world_flag", {
		"id": flag_id,
		"value": value,
		"previous_value": previous_value,
		"reversible": reversible
	})
	return save_state()


func bury_item_in_capsule(capsule_id: String, item_id: String, position: Vector3) -> bool:
	if capsule_id.is_empty() or item_id.is_empty():
		return _set_error("Capsules require stable capsule and item IDs.")
	if not is_finite(position.x) or not is_finite(position.y) or not is_finite(position.z):
		return _set_error("Capsule coordinates must be finite.")
	var capsules: Array = state.get("time_capsules", [])
	for capsule in capsules:
		if str(capsule.get("id", "")) == capsule_id:
			return _set_error("This time capsule has already been used.")
	var inventory: Array = state.get("inventory", [])
	for index in range(inventory.size()):
		if str(inventory[index].get("id", "")) != item_id:
			continue
		var previous_state: Dictionary = state.duplicate(true)
		var item: Dictionary = inventory.pop_at(index)
		state["inventory"] = inventory
		var item_states: Dictionary = state.get("item_states", {})
		item_states[item_id] = "capsuled"
		state["item_states"] = item_states
		capsules.append({
			"id": capsule_id,
			"item": item,
			"position": [position.x, position.y, position.z],
			"buried": true,
			"retrieved": false,
			"buried_at": Time.get_unix_time_from_system()
		})
		state["time_capsules"] = capsules
		record_event("capsule_buried", {"capsule_id": capsule_id, "item_id": item_id})
		if save_state():
			return true
		state = previous_state
		return false
	return _set_error("The selected item is not available to bury.")


func retrieve_time_capsule(capsule_id: String) -> Dictionary:
	var capsules: Array = state.get("time_capsules", [])
	for index in range(capsules.size()):
		var capsule: Dictionary = capsules[index]
		if str(capsule.get("id", "")) != capsule_id:
			continue
		if not bool(capsule.get("buried", false)) or bool(capsule.get("retrieved", false)):
			_set_error("This capsule is not available for retrieval.")
			return {}
		var item: Variant = capsule.get("item", {})
		if typeof(item) != TYPE_DICTIONARY or str(item.get("id", "")).is_empty():
			_set_error("The capsule contents are invalid.")
			return {}
		var inventory: Array = state.get("inventory", [])
		if inventory.size() >= INVENTORY_CAPACITY:
			_set_error("Inventory is full. Make room before retrieving the capsule.")
			return {}
		var previous_state: Dictionary = state.duplicate(true)
		inventory.append(item.duplicate(true))
		state["inventory"] = inventory
		var item_states: Dictionary = state.get("item_states", {})
		item_states[str(item["id"])] = "held"
		state["item_states"] = item_states
		capsule["retrieved"] = true
		capsules[index] = capsule
		state["time_capsules"] = capsules
		record_event("capsule_retrieved", {"capsule_id": capsule_id, "item_id": str(item["id"])})
		if save_state():
			return item.duplicate(true)
		state = previous_state
		return {}
	_set_error("No buried capsule exists at this location.")
	return {}


func save_cement_message(strokes: Array, message_id: String = "") -> bool:
	var clean_strokes: Array = []
	var point_count := 0
	for stroke in strokes:
		if typeof(stroke) != TYPE_ARRAY or stroke.size() < 2:
			continue
		var clean_stroke: Array = []
		for point in stroke:
			if typeof(point) != TYPE_ARRAY or point.size() != 2:
				return _set_error("Cement strokes must contain normalized coordinate pairs.")
			var x_value: Variant = point[0]
			var y_value: Variant = point[1]
			if typeof(x_value) not in [TYPE_INT, TYPE_FLOAT] or typeof(y_value) not in [TYPE_INT, TYPE_FLOAT]:
				return _set_error("Cement stroke coordinates must be numbers.")
			var x := float(x_value)
			var y := float(y_value)
			if not is_finite(x) or not is_finite(y) or x < 0.0 or x > 1.0 or y < 0.0 or y > 1.0:
				return _set_error("Cement stroke coordinates must be normalized between zero and one.")
			clean_stroke.append([x, y])
			point_count += 1
		clean_strokes.append(clean_stroke)
		if clean_strokes.size() > 32 or point_count > 512:
			return _set_error("The cement message exceeds the drawing limits.")
	if clean_strokes.is_empty():
		return _set_error("Draw at least one mark before preserving the cement message.")
	var previous_state: Dictionary = state.duplicate(true)
	var messages: Array = state.get("cement_messages", [])
	if message_id.is_empty():
		message_id = "cement-%d-%d" % [Time.get_unix_time_from_system(), _event_serial + 1]
	else:
		for existing in messages:
			if str(existing.get("id", "")) == message_id:
				return true
	messages.append({
		"id": message_id,
		"strokes": clean_strokes,
		"created_at": Time.get_unix_time_from_system()
	})
	while messages.size() > 100:
		messages.pop_front()
	state["cement_messages"] = messages
	record_event("cement_message", {"id": message_id})
	if save_state():
		return true
	state = previous_state
	return false


func save_musical_sequence(notes: Array) -> bool:
	if notes.size() > 16:
		return _set_error("A musical recording must contain at most 16 notes.")
	if notes.is_empty():
		return clear_musical_sequence()
	var clean_notes: Array[int] = []
	for note in notes:
		if typeof(note) not in [TYPE_INT, TYPE_FLOAT] or int(note) < 0 or int(note) > 3:
			return _set_error("Musical notes must use one of the four recorder tones.")
		clean_notes.append(int(note))
	var previous_state: Dictionary = state.duplicate(true)
	state["musical_sequences"] = [{
		"id": "willowbrook-sequence",
		"notes": clean_notes,
		"recorded_at": Time.get_unix_time_from_system()
	}]
	record_event("musical_sequence_recorded", {"note_count": clean_notes.size()})
	if save_state():
		return true
	state = previous_state
	return false


func append_musical_note(note: int) -> bool:
	var notes := get_musical_sequence()
	if notes.size() >= 16:
		return _set_error("The recording is full. Clear it before recording a new sequence.")
	notes.append(note)
	return save_musical_sequence(notes)


func clear_musical_sequence() -> bool:
	var previous_state: Dictionary = state.duplicate(true)
	state["musical_sequences"] = []
	record_event("musical_sequence_cleared", {})
	if save_state():
		return true
	state = previous_state
	return false


func get_musical_sequence() -> Array:
	var sequences: Array = state.get("musical_sequences", [])
	if sequences.is_empty():
		return []
	return sequences.back().get("notes", []).duplicate()


func merge_shared_puzzle_update(update_type: String, payload: Dictionary) -> bool:
	match update_type:
		"capsule":
			var capsule_id := str(payload.get("id", ""))
			var item: Variant = payload.get("item", {})
			var position: Variant = payload.get("position", [])
			if capsule_id.is_empty() or typeof(item) != TYPE_DICTIONARY \
			or str(item.get("id", "")).is_empty() or typeof(position) != TYPE_ARRAY \
			or position.size() != 3:
				return _set_error("Shared capsule state is invalid.")
			for coordinate in position:
				if typeof(coordinate) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(coordinate)):
					return _set_error("Shared capsule coordinates must be finite.")
			var capsules: Array = state.get("time_capsules", [])
			var existing_index := -1
			for index in range(capsules.size()):
				if str(capsules[index].get("id", "")) == capsule_id:
					existing_index = index
					break
			if existing_index >= 0:
				var existing: Dictionary = capsules[existing_index]
				if str(existing.get("item", {}).get("id", "")) != str(item.get("id", "")):
					return _set_error("Shared capsule update attempted to replace a unique item.")
				existing["retrieved"] = bool(payload.get("retrieved", existing.get("retrieved", false)))
				capsules[existing_index] = existing
			else:
				capsules.append(payload.duplicate(true))
			state["time_capsules"] = capsules
			var item_id := str(item.get("id", ""))
			var item_states: Dictionary = state.get("item_states", {})
			var held_locally := false
			for held_item in state.get("inventory", []):
				if str(held_item.get("id", "")) == item_id:
					held_locally = true
					break
			if bool(payload.get("retrieved", false)):
				if not held_locally:
					item_states[item_id] = "spent"
			else:
				item_states[item_id] = "capsuled"
			state["item_states"] = item_states
			return save_state()
		"cement_message":
			return save_cement_message(payload.get("strokes", []), str(payload.get("id", "")))
		"music_sequence":
			return save_musical_sequence(payload.get("notes", []))
	return _set_error("Unknown shared puzzle update.")


func rewind_last_timeline_action() -> bool:
	var progress: Dictionary = state.get("mission_progress", {})
	if progress.get("objectives", {}).has("drainage.past.valve"):
		return _set_error("The completed drainage route is a locked story consequence.")
	var sequence := ["water.level.lower", "water.level.bypass", "water.level.release"]
	var reversible_mission_flags := {
		"room.wall_moved": "room.past.revise",
		"blueprint.left": "blueprint.past.left",
		"blueprint.right": "blueprint.past.right",
		"blueprint.deck": "blueprint.past.deck",
	}
	var flags: Dictionary = state.get("world_flags", {})
	var events: Array = state.get("event_history", [])
	for event_index in range(events.size() - 1, -1, -1):
		var event: Dictionary = events[event_index]
		if str(event.get("type", "")) != "world_flag":
			continue
		var payload: Dictionary = event.get("payload", {})
		var flag_id := str(payload.get("id", ""))
		var mission_objective := str(reversible_mission_flags.get(flag_id, ""))
		if not bool(payload.get("reversible", false)) or (not sequence.has(flag_id) and mission_objective.is_empty()):
			continue
		if sequence.has(flag_id):
			var sequence_index := sequence.find(flag_id)
			for later_index in range(sequence_index + 1, sequence.size()):
				if bool(flags.get(sequence[later_index], false)):
					return _set_error("A later drainage valve depends on this action; rewind it first.")
		if not bool(flags.get(flag_id, false)):
			continue
		var previous_state: Dictionary = state.duplicate(true)
		if not mission_objective.is_empty() and get_state().get("mission_progress", {}).get("objectives", {}).has(mission_objective):
			if not MissionSystem.rewind_objective(mission_objective):
				return _set_error(MissionSystem.last_error)
		else:
			flags[flag_id] = bool(payload.get("previous_value", false))
			state["world_flags"] = flags
		var removed_event_id := str(event.get("id", ""))
		events.remove_at(event_index)
		state["event_history"] = events
		record_event("timeline_rewind", {"event_id": removed_event_id, "flag_id": flag_id})
		if save_state():
			return true
		state = previous_state
		return false
	return _set_error("There is no safe, reversible environmental action to rewind.")


func add_inventory_item(item: Dictionary) -> bool:
	var inventory: Array = state.get("inventory", [])
	if inventory.size() >= INVENTORY_CAPACITY:
		return _set_error("Inventory is full. Drop an item before collecting another.")
	var item_id := str(item.get("id", ""))
	if item_id.is_empty():
		return _set_error("Persistent inventory items require a unique ID.")
	for held_item in inventory:
		if str(held_item.get("id", "")) == item_id:
			return _set_error("This item has already been collected.")
	if str(state.get("item_states", {}).get(item_id, "")) == "spent":
		return _set_error("This item has already been used.")
	inventory.append(item.duplicate(true))
	state["inventory"] = inventory
	var item_states: Dictionary = state.get("item_states", {})
	item_states[item_id] = "held"
	state["item_states"] = item_states
	var dropped: Array = state.get("dropped_items", [])
	for index in range(dropped.size() - 1, -1, -1):
		if str(dropped[index].get("id", "")) == item_id:
			dropped.remove_at(index)
	state["dropped_items"] = dropped
	record_event("item_collected", {"id": item_id})
	return save_state()


func remove_inventory_item(item_id: String) -> Dictionary:
	var inventory: Array = state.get("inventory", [])
	for index in range(inventory.size()):
		if str(inventory[index].get("id", "")) == item_id:
			var removed: Dictionary = inventory.pop_at(index)
			state["inventory"] = inventory
			var item_states: Dictionary = state.get("item_states", {})
			item_states[item_id] = "spent"
			state["item_states"] = item_states
			record_event("item_used", {"id": item_id})
			if save_state():
				return removed
			return {}
	_set_error("That item is not in the inventory.")
	return {}


func drop_inventory_item(item_id: String, position: Vector3) -> Dictionary:
	var previous_state := state.duplicate(true)
	var inventory: Array = state.get("inventory", [])
	var removed: Dictionary = {}
	for index in range(inventory.size()):
		if str(inventory[index].get("id", "")) == item_id:
			removed = inventory.pop_at(index)
			break
	if removed.is_empty():
		_set_error("That item is not in the inventory.")
		return {}
	state["inventory"] = inventory
	var item_states: Dictionary = state.get("item_states", {})
	item_states[item_id] = "dropped"
	state["item_states"] = item_states
	var dropped: Array = state.get("dropped_items", [])
	dropped.append({
		"id": item_id,
		"name": str(removed.get("name", item_id)),
		"category": str(removed.get("category", "tool")),
		"source": str(removed.get("source", "")),
		"position": [position.x, position.y, position.z],
	})
	state["dropped_items"] = dropped
	record_event("item_dropped", {"id": item_id})
	if save_state():
		return removed
	state = previous_state
	return {}


func restore_consumed_item(item: Dictionary) -> bool:
	var item_id := str(item.get("id", ""))
	if item_id.is_empty() or str(state.get("item_states", {}).get(item_id, "")) != "spent":
		return _set_error("Only a uniquely consumed item can be restored by rewind.")
	var inventory: Array = state.get("inventory", [])
	for held_item in inventory:
		if str(held_item.get("id", "")) == item_id:
			return _set_error("Rewind cannot duplicate an item already in inventory.")
	if inventory.size() >= INVENTORY_CAPACITY:
		return _set_error("Make room in inventory before rewinding this material placement.")
	var previous_state: Dictionary = state.duplicate(true)
	inventory.append(item.duplicate(true))
	state["inventory"] = inventory
	var item_states: Dictionary = state.get("item_states", {})
	item_states[item_id] = "held"
	state["item_states"] = item_states
	record_event("item_restored", {"id": item_id, "source": "timeline_rewind"})
	if save_state():
		return true
	state = previous_state
	return false


func get_dropped_items() -> Array:
	return state.get("dropped_items", []).duplicate(true)


func item_is_held_or_spent(item_id: String) -> bool:
	var status := str(state.get("item_states", {}).get(item_id, ""))
	return status == "held" or status == "spent"


func add_journal_entry(entry_id: String, text: String) -> bool:
	if entry_id.is_empty() or text.strip_edges().is_empty():
		return _set_error("Journal entries require an ID and text.")
	var entries: Array = state.get("journal", [])
	for entry in entries:
		if str(entry.get("id", "")) == entry_id:
			return true
	entries.append({"id": entry_id, "text": text, "time": Time.get_unix_time_from_system()})
	state["journal"] = entries
	record_event("journal_discovery", {"id": entry_id})
	return save_state()


func add_message(sender_id: String, text: String, quick_message: bool = false) -> bool:
	var clean_text := text.strip_edges()
	if clean_text.is_empty() or clean_text.length() > 240:
		return _set_error("Messages must contain 1–240 characters.")
	var messages: Array = state.get("messages", [])
	messages.append({
		"sender": sender_id,
		"text": clean_text,
		"quick": quick_message,
		"time": Time.get_unix_time_from_system(),
	})
	while messages.size() > MAX_MESSAGES:
		messages.pop_front()
	state["messages"] = messages
	return save_state()


func add_location_marker(location_id: String, label: String, sender_id: String) -> bool:
	if not TownLocations.LOCATIONS.has(location_id):
		return _set_error("Unknown shared location: %s" % location_id)
	var markers: Array = state.get("markers", [])
	markers.append({
		"id": "%s-%d-%d" % [location_id, Time.get_unix_time_from_system(), markers.size()],
		"location_id": location_id,
		"label": label.substr(0, 80),
		"sender": sender_id,
		"time": Time.get_unix_time_from_system(),
	})
	while markers.size() > 100:
		markers.pop_front()
	state["markers"] = markers
	record_event("location_marked", {"location_id": location_id})
	return save_state()


func record_echo_frame(source_timeline: String, transform: Transform3D, moving: bool, selected_item: String) -> void:
	if not ["past", "future"].has(source_timeline):
		return
	var echoes: Array = state.get("time_echoes", [])
	var track: Dictionary
	for candidate in echoes:
		if str(candidate.get("source_timeline", "")) == source_timeline:
			track = candidate
			break
	if track.is_empty():
		track = {"source_timeline": source_timeline, "frames": []}
		echoes.append(track)
	var frames: Array = track.get("frames", [])
	frames.append({
		"position": [transform.origin.x, transform.origin.y, transform.origin.z],
		"yaw": transform.basis.get_euler().y,
		"moving": moving,
		"selected_item": selected_item,
		"time": Time.get_unix_time_from_system(),
	})
	while frames.size() > 120:
		frames.pop_front()
	track["frames"] = frames
	for index in range(echoes.size()):
		if str(echoes[index].get("source_timeline", "")) == source_timeline:
			echoes[index] = track
			break
	state["time_echoes"] = echoes


func get_recorded_echo(source_timeline: String) -> Array:
	for track in state.get("time_echoes", []):
		if str(track.get("source_timeline", "")) == source_timeline:
			return track.get("frames", []).duplicate(true)
	return []


func merge_shared_snapshot(snapshot: Dictionary) -> bool:
	var incoming_flags: Variant = snapshot.get("world_flags", {})
	if typeof(incoming_flags) != TYPE_DICTIONARY:
		return _set_error("Shared snapshot world_flags must be an object.")
	var incoming_missions: Variant = snapshot.get("mission_progress", {})
	if typeof(incoming_missions) != TYPE_DICTIONARY:
		return _set_error("Shared snapshot mission_progress must be an object.")
	for field in ["journal", "markers", "messages"]:
		if typeof(snapshot.get(field, [])) != TYPE_ARRAY:
			return _set_error("Shared snapshot %s must be an array." % field)
	for field in ["time_capsules", "cement_messages", "musical_sequences"]:
		if typeof(snapshot.get(field, [])) != TYPE_ARRAY:
			return _set_error("Shared snapshot %s must be an array." % field)
	var flags: Dictionary = incoming_flags
	var current_flags: Dictionary = state.get("world_flags", {})
	for flag_id in flags:
		if not [
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
		].has(str(flag_id)):
			continue
		if typeof(flags[flag_id]) == TYPE_BOOL:
			current_flags[flag_id] = flags[flag_id]
	state["world_flags"] = current_flags
	_merge_entries("journal", snapshot.get("journal", []), "id")
	_merge_entries("markers", snapshot.get("markers", []), "id")
	_merge_messages(snapshot.get("messages", []))
	for capsule in snapshot.get("time_capsules", []):
		if typeof(capsule) == TYPE_DICTIONARY and not merge_shared_puzzle_update("capsule", capsule):
			return false
	for cement_message in snapshot.get("cement_messages", []):
		if typeof(cement_message) == TYPE_DICTIONARY and not merge_shared_puzzle_update("cement_message", cement_message):
			return false
	var sequences: Array = snapshot.get("musical_sequences", [])
	if not sequences.is_empty():
		var latest_sequence: Dictionary = sequences.back()
		if not merge_shared_puzzle_update("music_sequence", latest_sequence):
			return false
	if not incoming_missions.is_empty() and not MissionSystem.merge_progress(incoming_missions):
		return _set_error(MissionSystem.last_error)
	return save_state()


func _merge_entries(field: String, incoming: Variant, identity_field: String) -> void:
	if typeof(incoming) != TYPE_ARRAY:
		return
	var current: Array = state.get(field, [])
	for value in incoming:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var identity := str(value.get(identity_field, ""))
		if identity.is_empty():
			continue
		var exists := false
		for current_value in current:
			if typeof(current_value) != TYPE_DICTIONARY:
				continue
			if str(current_value.get(identity_field, "")) == identity:
				exists = true
				break
		if not exists:
			current.append(value.duplicate(true))
	while current.size() > 200:
		current.pop_front()
	state[field] = current


func _merge_messages(incoming: Variant) -> void:
	if typeof(incoming) != TYPE_ARRAY:
		return
	var current: Array = state.get("messages", [])
	for value in incoming:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var signature := "%s|%s|%s" % [
			str(value.get("sender", "")), str(value.get("time", "")), str(value.get("text", ""))
		]
		var exists := false
		for current_value in current:
			if typeof(current_value) != TYPE_DICTIONARY:
				continue
			var current_signature := "%s|%s|%s" % [
				str(current_value.get("sender", "")), str(current_value.get("time", "")), str(current_value.get("text", ""))
			]
			if current_signature == signature:
				exists = true
				break
		if not exists:
			current.append(value.duplicate(true))
	while current.size() > MAX_MESSAGES:
		current.pop_front()
	state["messages"] = current


func record_event(event_type: String, payload: Dictionary) -> void:
	_event_serial += 1
	var events: Array = state.get("event_history", [])
	events.append({
		"id": "%d-%d" % [Time.get_unix_time_from_system(), _event_serial],
		"type": event_type,
		"payload": payload.duplicate(true),
		"time": Time.get_unix_time_from_system(),
	})
	while events.size() > MAX_EVENTS:
		events.pop_front()
	state["event_history"] = events


func _default_state() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"timeline": "past",
		"player": {"position": [14.0, 0.0, 31.0], "yaw": 0.0},
		"inventory": [
			{
				"id": "item.time_echo_device",
				"name": "Time Echo Device",
				"category": "temporal_device",
				"source": "initial_equipment",
			},
		],
		"item_states": {"item.time_echo_device": "held"},
		"dropped_items": [],
		"world_flags": {},
		"journal": [],
		"messages": [],
		"markers": [],
		"event_history": [],
		"time_capsules": [],
		"cement_messages": [],
		"musical_sequences": [],
		"time_echoes": [],
		"mission_progress": {
			"active_mission": "echo_awakening",
			"completed_missions": [],
			"objectives": {},
			"contributions": [],
			"final_outcome": ""
		},
		"temporal_energy": 100.0,
		"settings": {"master_volume": 1.0, "mouse_sensitivity": 0.0026},
	}


func _migrate_state(value: Variant) -> Variant:
	if typeof(value) != TYPE_DICTIONARY:
		return value
	var version := int(value.get("schema_version", -1))
	if version < 1 or version >= SCHEMA_VERSION:
		return value
	var migrated: Dictionary = value.duplicate(true)
	var defaults := _default_state()
	for field in defaults:
		if not migrated.has(field):
			migrated[field] = defaults[field].duplicate(true) if typeof(defaults[field]) in [TYPE_ARRAY, TYPE_DICTIONARY] else defaults[field]
	if version == 1 and typeof(migrated.get("inventory")) == TYPE_ARRAY:
		var has_time_echo_device := false
		for item in migrated["inventory"]:
			if typeof(item) == TYPE_DICTIONARY and str(item.get("id", "")) == "item.time_echo_device":
				has_time_echo_device = true
				break
		if typeof(migrated.get("item_states")) != TYPE_DICTIONARY:
			return migrated
		var device_state := str(migrated["item_states"].get("item.time_echo_device", ""))
		var device_is_dropped := false
		for item in migrated.get("dropped_items", []):
			if typeof(item) == TYPE_DICTIONARY and str(item.get("id", "")) == "item.time_echo_device":
				device_is_dropped = true
				break
		if (
			not has_time_echo_device
			and not device_is_dropped
			and device_state not in ["held", "spent"]
			and migrated["inventory"].size() < INVENTORY_CAPACITY
		):
			migrated["inventory"].append(defaults["inventory"][0].duplicate(true))
			var item_states: Dictionary = migrated["item_states"]
			item_states["item.time_echo_device"] = "held"
			migrated["item_states"] = item_states
	migrated["schema_version"] = SCHEMA_VERSION
	return migrated


func _validation_error(value: Variant) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return "root value must be an object"
	var data: Dictionary = value
	if int(data.get("schema_version", -1)) != SCHEMA_VERSION:
		return "unsupported schema version"
	if not ["past", "future"].has(data.get("timeline", "")):
		return "timeline must be past or future"
	if typeof(data.get("player")) != TYPE_DICTIONARY:
		return "player checkpoint must be an object"
	var player_state: Dictionary = data["player"]
	if typeof(player_state.get("position")) != TYPE_ARRAY or player_state["position"].size() != 3:
		return "player position must contain three coordinates"
	for coordinate in player_state["position"]:
		if typeof(coordinate) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(coordinate)):
			return "player coordinates must be finite numbers"
	for field in [
		"inventory", "dropped_items", "journal", "messages", "markers", "event_history",
		"time_capsules", "cement_messages", "musical_sequences"
	]:
		if typeof(data.get(field)) != TYPE_ARRAY:
			return "%s must be an array" % field
	if data["inventory"].size() > INVENTORY_CAPACITY:
		return "inventory exceeds its six-slot capacity"
	if typeof(data.get("item_states")) != TYPE_DICTIONARY:
		return "item_states must be an object"
	if typeof(data.get("time_echoes")) != TYPE_ARRAY:
		return "time_echoes must be an array"
	if typeof(data.get("world_flags")) != TYPE_DICTIONARY:
		return "world_flags must be an object"
	if typeof(data.get("mission_progress")) != TYPE_DICTIONARY:
		return "mission_progress must be an object"
	if typeof(data.get("settings")) != TYPE_DICTIONARY:
		return "settings must be an object"
	var energy: Variant = data.get("temporal_energy", null)
	if typeof(energy) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(energy)):
		return "temporal_energy must be a finite number"
	return ""


func _set_error(message: String) -> bool:
	last_error = message
	error_occurred.emit(message)
	return false
