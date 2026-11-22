extends Node

signal objective_completed(objective_id: String, role: String, source: String)
signal mission_completed(mission_id: String, title: String)
signal mission_changed(mission_id: String)

const MISSIONS: Array[Dictionary] = [
	{
		"id": "echo_awakening",
		"title": "Echo Awakening",
		"summary": "Learn to observe both timelines and establish the first shared lead.",
		"next": "photograph_that_changes",
		"objectives": [
			{"id": "echo.past.arrival", "role": "past", "text": "Inspect the town square in 2026.", "requires": []},
			{"id": "echo.future.arrival", "role": "future", "text": "Inspect the flooded archive in 2046.", "requires": []},
			{"id": "echo.past.vision", "role": "past", "text": "Open Temporal Vision in 2026.", "requires": ["echo.past.arrival"]},
			{"id": "echo.future.vision", "role": "future", "text": "Open Temporal Vision in 2046.", "requires": ["echo.future.arrival"]},
			{"id": "echo.time_echo", "role": "either", "text": "Observe a real partner or saved echo with Time Echo.", "requires": [], "optional": true},
			{"id": "echo.link", "role": "either", "text": "Send a message through Echo Link.", "requires": [], "optional": true}
		]
	},
	{
		"id": "photograph_that_changes",
		"title": "The Photograph That Changes",
		"summary": "Compare a future photograph, move real equipment in the past, and uncover the maintenance access.",
		"next": "lost_room",
		"objectives": [
			{"id": "photo.future.discover", "role": "future", "text": "Find the photograph in the flooded archives.", "requires": []},
			{"id": "photo.past.crate", "role": "past", "text": "Move the crate beside the dam.", "requires": ["photo.future.discover"], "world_flag": "photo.crate_moved"},
			{"id": "photo.past.barrier", "role": "past", "text": "Clear the service barrier beside the dam.", "requires": ["photo.future.discover"], "world_flag": "photo.barrier_moved"},
			{"id": "photo.future.access", "role": "future", "text": "Inspect the newly revealed maintenance access.", "requires": ["photo.past.crate", "photo.past.barrier"]}
		]
	},
	{
		"id": "lost_room",
		"title": "The Lost Room",
		"summary": "Change the workshop's original construction layout and recover the hidden room's document.",
		"next": "broken_machine",
		"objectives": [
			{"id": "room.future.discover", "role": "future", "text": "Find the blocked room beside the old workshop.", "requires": []},
			{"id": "room.past.revise", "role": "past", "text": "Move the original wall module to open the doorway.", "requires": ["room.future.discover"], "world_flag": "room.wall_moved"},
			{"id": "room.future.enter", "role": "future", "text": "Enter the newly accessible room.", "requires": ["room.past.revise"]},
			{"id": "room.future.document", "role": "future", "text": "Recover the historical construction record.", "requires": ["room.future.enter"], "reward_item": {"id": "item.room_document", "name": "Hidden Room Record", "category": "document", "source": "lost_room"}}
		]
	},
	{
		"id": "broken_machine",
		"title": "The Broken Machine",
		"summary": "Compare the machine across timelines and transfer a missing capacitor through its time capsule.",
		"next": "town_remembers",
		"objectives": [
			{"id": "machine.future.inspect", "role": "future", "text": "Inspect the damaged pump and identify its missing component.", "requires": []},
			{"id": "machine.past.identify", "role": "past", "text": "Inspect the complete 2026 pump layout.", "requires": []},
			{"id": "machine.past.capsule", "role": "past", "text": "Physically bury the original pump capacitor in the waterproof capsule.", "requires": ["machine.future.inspect", "machine.past.identify"], "world_flag": "capsule.capacitor_sent"},
			{"id": "machine.future.retrieve", "role": "future", "text": "Retrieve the same unique component from its buried capsule.", "requires": ["machine.past.capsule"], "world_flag": "capsule.capacitor_retrieved"},
			{"id": "machine.future.repair", "role": "future", "text": "Install the recovered capacitor in the damaged pump.", "requires": ["machine.future.retrieve"], "item": "item.pump_capacitor", "world_flag": "machine.repaired"}
		]
	},
	{
		"id": "town_remembers",
		"title": "The Town That Remembers",
		"summary": "Convince the shopkeeper to protect essential supplies, then recover them in the flooded town.",
		"next": "blueprint_for_shelter",
		"objectives": [
			{"id": "town.past.preserve_supplies", "role": "past", "text": "Choose whether the shopkeeper moves the emergency supplies.", "requires": []},
			{"id": "town.future.retrieve_supplies", "role": "future", "text": "Investigate the storeroom and the consequences of the past decision.", "requires": ["town.past.preserve_supplies"], "world_flag": "npc.supplies_retrieved", "reward_item": {"id": "item.emergency_supplies", "name": "Preserved Emergency Supplies", "category": "equipment", "source": "general_store"}}
		]
	},
	{
		"id": "blueprint_for_shelter",
		"title": "Blueprint for Shelter",
		"summary": "Share a construction plan, physically assemble its supports, and verify the route in 2046.",
		"next": "silent_power_station",
		"objectives": [
			{"id": "blueprint.future.request", "role": "future", "text": "Request the shelter blueprint from the electrical station.", "requires": []},
			{"id": "blueprint.past.left", "role": "past", "text": "Place a timber at the left support.", "requires": ["blueprint.future.request"], "item": "item.plank_left", "world_flag": "blueprint.left"},
			{"id": "blueprint.past.right", "role": "past", "text": "Place a timber at the right support.", "requires": ["blueprint.future.request"], "item": "item.plank_right", "world_flag": "blueprint.right"},
			{"id": "blueprint.past.deck", "role": "past", "text": "Place the deck beam.", "requires": ["blueprint.future.request"], "item": "item.support_beam", "world_flag": "blueprint.deck"},
			{"id": "blueprint.future.traverse", "role": "future", "text": "Walk across the completed elevated route.", "requires": ["blueprint.past.left", "blueprint.past.right", "blueprint.past.deck"]}
		]
	},
	{
		"id": "silent_power_station",
		"title": "The Silent Power Station",
		"summary": "Read the future emergency-light pattern and restore the historical power route.",
		"next": "drainage_below",
		"objectives": [
			{"id": "power.future.pattern", "role": "future", "text": "Inspect the emergency-light pattern at the station.", "requires": []},
			{"id": "power.past.route", "role": "past", "text": "Route the copper cable using the observed pattern.", "requires": ["power.future.pattern"], "world_flag": "electrical.power_routed"},
			{"id": "power.future.restore", "role": "future", "text": "Confirm the emergency lights have returned.", "requires": ["power.past.route"]}
		]
	},
	{
		"id": "drainage_below",
		"title": "Drainage Below",
		"summary": "Read the flood marks, tune the drainage valves in sequence, and reach the lower control room.",
		"next": "the-floodgate",
		"objectives": [
			{"id": "drainage.future.survey", "role": "future", "text": "Read the lower-inlet, bypass, and relief sequence from the tunnel flood marks.", "requires": []},
			{"id": "drainage.past.valve", "role": "past", "text": "Set the lower inlet, bypass, and relief valves in order using the wrench.", "requires": ["drainage.future.survey"], "world_flag": "drainage.valve_open"},
			{"id": "drainage.future.control", "role": "future", "text": "Reach the lower control room after the water recedes.", "requires": ["drainage.past.valve"]}
		]
	},
	{
		"id": "the-floodgate",
		"title": "The Floodgate",
		"summary": "Use the future evidence to configure the floodgate in 2026 and verify the changed outcome.",
		"next": "",
		"objectives": [
			{"id": "flood.future.inspect", "role": "future", "text": "Inspect the damaged floodgate controls.", "requires": []},
			{"id": "flood.past.configure", "role": "past", "text": "Configure the floodgate with the maintenance key.", "requires": ["flood.future.inspect"], "item": "item.maintenance_key", "world_flag": "floodgate.configured"},
			{"id": "flood.future.confirm", "role": "future", "text": "Confirm the safer 2046 outcome.", "requires": ["flood.past.configure"]}
		]
	}
]

const REVERSIBLE_WORLD_FLAGS := [
	"room.wall_moved",
	"blueprint.left",
	"blueprint.right",
	"blueprint.deck"
]
var last_error := ""


func _ready() -> void:
	_ensure_progress()


func get_missions() -> Array[Dictionary]:
	return MISSIONS.duplicate(true)


func get_progress() -> Dictionary:
	_ensure_progress()
	return AdventureState.get_state().get("mission_progress", {}).duplicate(true)


func get_current_mission() -> Dictionary:
	var progress := get_progress()
	var mission_id := str(progress.get("active_mission", ""))
	for mission in MISSIONS:
		if str(mission["id"]) == mission_id:
			return mission.duplicate(true)
	return {}


func get_current_objectives(role: String = "") -> Array[Dictionary]:
	var mission := get_current_mission()
	if mission.is_empty():
		return []
	var progress := get_progress()
	var completed: Dictionary = progress.get("objectives", {})
	var result: Array[Dictionary] = []
	for objective in mission["objectives"]:
		var objective_role := str(objective["role"])
		if not role.is_empty() and objective_role not in [role, "either"]:
			continue
		var row: Dictionary = objective.duplicate(true)
		row["complete"] = completed.has(str(objective["id"]))
		result.append(row)
	return result


func is_objective_active(objective_id: String, role: String) -> bool:
	var objective_data := _find_objective(objective_id)
	if objective_data.is_empty() or not _role_matches(str(objective_data["role"]), role):
		return false
	var progress := get_progress()
	if str(progress.get("active_mission", "")) != str(objective_data["mission_id"]):
		return false
	if progress.get("objectives", {}).has(objective_id):
		return false
	for prerequisite in objective_data["requires"]:
		if not progress.get("objectives", {}).has(str(prerequisite)):
			return false
	return true


func is_valid_objective(objective_id: String) -> bool:
	return not _find_objective(objective_id).is_empty()


func complete_objective(objective_id: String, role: String, source: String = "local") -> bool:
	if source == "remote":
		return apply_remote_objective(objective_id, role)
	var objective_data := _find_objective(objective_id)
	if objective_data.is_empty():
		return _fail("Unknown mission objective: %s" % objective_id)
	if not is_objective_active(objective_id, role):
		return _fail("Mission objective is not available for the %s timeline." % role)
	return _record_objective(objective_data, role, source, str(objective_data.get("item", "")))


func complete_objective_with_flag(objective_id: String, role: String, flag_id: String) -> bool:
	if flag_id not in ["npc.supplies_relocated", "npc.supplies_declined"]:
		return _fail("That NPC decision is not a valid persistent outcome.")
	var objective_data := _find_objective(objective_id)
	if objective_data.is_empty() or not is_objective_active(objective_id, role):
		return _fail("The NPC decision is not currently available.")
	objective_data["world_flag"] = flag_id
	return _record_objective(objective_data, role, "local", "")


func apply_remote_objective(objective_id: String, role: String) -> bool:
	var objective_data := _find_objective(objective_id)
	if objective_data.is_empty() or not _role_matches(str(objective_data["role"]), role):
		return _fail("Rejected invalid remote mission objective.")
	if not is_objective_active(objective_id, role):
		if get_progress().get("objectives", {}).has(objective_id):
			return true
		return _fail("Rejected out-of-order remote mission objective.")
	return _record_objective(objective_data, role, "remote", "")


func rewind_objective(objective_id: String) -> bool:
	var objective_data := _find_objective(objective_id)
	if objective_data.is_empty():
		return _fail("The requested mission action cannot be rewound.")
	var current := get_progress()
	var objectives: Dictionary = current.get("objectives", {})
	if not objectives.has(objective_id):
		return _fail("That mission action is no longer recorded as complete.")
	for mission in MISSIONS:
		for candidate in mission.get("objectives", []):
			var candidate_id := str(candidate.get("id", ""))
			if not objectives.has(candidate_id):
				continue
			if candidate.get("requires", []).has(objective_id):
				return _fail("A later mission step depends on this action; undo that consequence first.")
	var completion_record: Dictionary = objectives[objective_id]
	var consumed_item: Variant = completion_record.get("consumed_item", {})
	var previous_state: Dictionary = AdventureState.state.duplicate(true)
	if typeof(consumed_item) == TYPE_DICTIONARY and not consumed_item.is_empty():
		if not AdventureState.restore_consumed_item(consumed_item):
			return _fail(AdventureState.last_error)
	var flag_id := str(objective_data.get("world_flag", ""))
	if not flag_id.is_empty():
		var flags: Dictionary = AdventureState.state.get("world_flags", {})
		flags[flag_id] = false
		AdventureState.state["world_flags"] = flags
	objectives.erase(objective_id)
	current["objectives"] = objectives
	var contributions: Array = current.get("contributions", [])
	for index in range(contributions.size() - 1, -1, -1):
		if str(contributions[index].get("objective_id", "")) == objective_id:
			contributions.remove_at(index)
	current["contributions"] = contributions
	var mission_id := str(objective_data["mission_id"])
	var completed_missions: Array = current.get("completed_missions", [])
	completed_missions.erase(mission_id)
	current["completed_missions"] = completed_missions
	current["active_mission"] = mission_id
	current["final_outcome"] = ""
	AdventureState.state["mission_progress"] = current
	if not AdventureState.save_state():
		AdventureState.state = previous_state
		return _fail(AdventureState.last_error)
	last_error = ""
	mission_changed.emit(mission_id)
	return true


func merge_progress(incoming: Dictionary) -> bool:
	var current := get_progress()
	var incoming_objectives: Variant = incoming.get("objectives", {})
	if typeof(incoming_objectives) != TYPE_DICTIONARY:
		return _fail("Incoming mission progress has an invalid objectives map.")
	var objectives: Dictionary = current.get("objectives", {})
	for objective_id in incoming_objectives:
		var objective_id_text := str(objective_id)
		var objective_data := _find_objective(objective_id_text)
		if objective_data.is_empty() or typeof(incoming_objectives[objective_id]) != TYPE_DICTIONARY:
			continue
		var record: Dictionary = incoming_objectives[objective_id]
		if _role_matches(str(objective_data["role"]), str(record.get("role", ""))):
			objectives[objective_id_text] = record.duplicate(true)
	current["objectives"] = objectives
	var completed: Array = current.get("completed_missions", [])
	for mission in MISSIONS:
		if _mission_is_complete(mission, objectives) and not completed.has(str(mission["id"])):
			completed.append(str(mission["id"]))
	current["completed_missions"] = completed
	current["active_mission"] = _furthest_unfinished_mission(completed)
	var previous_state: Dictionary = AdventureState.state.duplicate(true)
	AdventureState.state["mission_progress"] = current
	if AdventureState.save_state():
		mission_changed.emit(str(current["active_mission"]))
		return true
	AdventureState.state = previous_state
	return false


func _record_objective(objective_data: Dictionary, role: String, source: String, item_id: String) -> bool:
	var previous_state: Dictionary = AdventureState.state.duplicate(true)
	var current: Dictionary = AdventureState.state.get("mission_progress", {}).duplicate(true)
	var consumed_item: Dictionary = {}
	if not item_id.is_empty():
		for item in previous_state.get("inventory", []):
			if str(item.get("id", "")) == item_id:
				consumed_item = item.duplicate(true)
				break
	if not item_id.is_empty() and not _consume_item(item_id):
		return _fail("Required item is not available: %s" % item_id)
	if source != "remote" and not _grant_reward_item(objective_data.get("reward_item", {})):
		AdventureState.state = previous_state
		return false
	var objectives: Dictionary = current.get("objectives", {})
	if objectives.has(str(objective_data["id"])):
		return true
	objectives[str(objective_data["id"])] = {
		"role": role,
		"source": source,
		"completed_at": Time.get_unix_time_from_system(),
		"consumed_item": consumed_item
	}
	current["objectives"] = objectives
	var contributions: Array = current.get("contributions", [])
	contributions.append({
		"objective_id": str(objective_data["id"]),
		"role": role,
		"source": source,
		"time": Time.get_unix_time_from_system()
	})
	while contributions.size() > 200:
		contributions.pop_front()
	current["contributions"] = contributions
	var world_flag := str(objective_data.get("world_flag", ""))
	if not world_flag.is_empty():
		var flags: Dictionary = AdventureState.state.get("world_flags", {})
		var previous_value := bool(flags.get(world_flag, false))
		flags[world_flag] = true
		AdventureState.state["world_flags"] = flags
		AdventureState.record_event("world_flag", {
			"id": world_flag,
			"value": true,
			"previous_value": previous_value,
			"reversible": REVERSIBLE_WORLD_FLAGS.has(world_flag)
		})
	var mission_id := str(objective_data["mission_id"])
	var mission_data := _find_mission(mission_id)
	var did_complete_mission := _mission_is_complete(mission_data, objectives)
	if did_complete_mission:
		var completed: Array = current.get("completed_missions", [])
		if not completed.has(mission_id):
			completed.append(mission_id)
		current["completed_missions"] = completed
		var next_mission := str(mission_data.get("next", ""))
		current["active_mission"] = next_mission
		if next_mission.is_empty():
			current["final_outcome"] = "prevented"
	else:
		current["active_mission"] = mission_id
	AdventureState.state["mission_progress"] = current
	AdventureState.record_event("mission_objective", {
		"id": str(objective_data["id"]),
		"role": role,
		"source": source
	})
	if not AdventureState.save_state():
		AdventureState.state = previous_state
		return _fail(AdventureState.last_error)
	last_error = ""
	objective_completed.emit(str(objective_data["id"]), role, source)
	if did_complete_mission:
		mission_completed.emit(mission_id, str(mission_data["title"]))
		mission_changed.emit(str(current["active_mission"]))
	return true


func _grant_reward_item(reward: Variant) -> bool:
	if typeof(reward) != TYPE_DICTIONARY or reward.is_empty():
		return true
	if str(reward.get("source", "")) == "general_store" \
	and AdventureState.has_world_flag("npc.supplies_declined"):
		return true
	var item_id := str(reward.get("id", ""))
	if item_id.is_empty():
		return _fail("Mission reward is missing its persistent item ID.")
	var inventory: Array = AdventureState.state.get("inventory", [])
	for item in inventory:
		if str(item.get("id", "")) == item_id:
			return true
	var item_states: Dictionary = AdventureState.state.get("item_states", {})
	if str(item_states.get(item_id, "")) == "spent":
		return _fail("The mission reward was already used.")
	if inventory.size() >= AdventureState.INVENTORY_CAPACITY:
		return _fail("Inventory is full. Make room before recovering the mission item.")
	inventory.append(reward.duplicate(true))
	AdventureState.state["inventory"] = inventory
	item_states[item_id] = "held"
	AdventureState.state["item_states"] = item_states
	AdventureState.record_event("item_collected", {"id": item_id, "source": "mission_reward"})
	return true


func _consume_item(item_id: String) -> bool:
	var inventory: Array = AdventureState.state.get("inventory", [])
	for index in range(inventory.size()):
		if str(inventory[index].get("id", "")) != item_id:
			continue
		inventory.remove_at(index)
		AdventureState.state["inventory"] = inventory
		var item_states: Dictionary = AdventureState.state.get("item_states", {})
		item_states[item_id] = "spent"
		AdventureState.state["item_states"] = item_states
		return true
	return false


func _ensure_progress() -> void:
	if AdventureState.state.is_empty():
		return
	var progress: Variant = AdventureState.state.get("mission_progress")
	if typeof(progress) == TYPE_DICTIONARY:
		return
	AdventureState.state["mission_progress"] = {
		"active_mission": str(MISSIONS[0]["id"]),
		"completed_missions": [],
		"objectives": {},
		"contributions": [],
		"final_outcome": ""
	}


func _find_objective(objective_id: String) -> Dictionary:
	for mission in MISSIONS:
		for objective in mission["objectives"]:
			if str(objective["id"]) == objective_id:
				var result: Dictionary = objective.duplicate(true)
				result["mission_id"] = str(mission["id"])
				return result
	return {}


func _find_mission(mission_id: String) -> Dictionary:
	for mission in MISSIONS:
		if str(mission["id"]) == mission_id:
			return mission
	return {}


func _mission_is_complete(mission: Dictionary, completed: Dictionary) -> bool:
	for objective in mission.get("objectives", []):
		if bool(objective.get("optional", false)):
			continue
		if not completed.has(str(objective["id"])):
			return false
	return true


func _furthest_unfinished_mission(completed: Array) -> String:
	for mission in MISSIONS:
		if not completed.has(str(mission["id"])):
			return str(mission["id"])
	return ""


func _role_matches(expected: String, actual: String) -> bool:
	return expected == "either" or expected == actual


func _fail(message: String) -> bool:
	last_error = message
	return false
