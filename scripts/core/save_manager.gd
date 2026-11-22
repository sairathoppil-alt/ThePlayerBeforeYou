extends Node

signal state_changed(new_state: Dictionary)
signal error_occurred(message: String)

const SAVE_PATH := "user://game_state.json"
const INITIAL_BUDGET := 70
const ACTION_COSTS := {
	"repair_dam": 30,
	"strengthen_bridge": 20,
	"improve_drainage": 15,
	"build_shelter": 20,
	"install_warning_system": 15,
}

var state: Dictionary = {}
var last_error := ""
var _save_path := SAVE_PATH


func _ready() -> void:
	if has_existing_save():
		load_game()
	else:
		state = _default_state()


func has_existing_save() -> bool:
	return FileAccess.file_exists(_save_path)


func get_state() -> Dictionary:
	return state.duplicate(true)


func initialize_new_mission() -> bool:
	var previous_state := state.duplicate(true)
	state = _default_state()
	if not save_game():
		state = previous_state
		return false
	state_changed.emit(get_state())
	return true


func save_game() -> bool:
	if not _validate_state(state):
		return _report_error("Refused to save invalid game data.")

	var file := FileAccess.open(_save_path, FileAccess.WRITE)
	if file == null:
		return _report_error("Could not open the save file for writing: %s" % error_string(FileAccess.get_open_error()))

	file.store_string(JSON.stringify(state, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return _report_error("Could not write the save file: %s" % error_string(write_error))

	last_error = ""
	return true


func load_game() -> bool:
	if not has_existing_save():
		state = _default_state()
		return false

	var file := FileAccess.open(_save_path, FileAccess.READ)
	if file == null:
		state = _default_state()
		return _report_error("Could not open the save file: %s" % error_string(FileAccess.get_open_error()))

	var contents := file.get_as_text()
	file.close()

	var parser := JSON.new()
	var parse_error := parser.parse(contents)
	if parse_error != OK:
		state = _default_state()
		return _report_error(
			"Save file is corrupted at line %d: %s" % [parser.get_error_line(), parser.get_error_message()]
		)
	var validation_error := _state_validation_error(parser.data)
	if not validation_error.is_empty():
		state = _default_state()
		return _report_error("Save file contains invalid game data: %s" % validation_error)

	state = parser.data
	last_error = ""
	state_changed.emit(get_state())
	return true


func reset_progress() -> bool:
	if has_existing_save():
		var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(_save_path))
		if remove_error != OK:
			return _report_error("Could not remove the save file: %s" % error_string(remove_error))

	state = _default_state()
	last_error = ""
	state_changed.emit(get_state())
	return true


func is_decision_selected(action_id: String) -> bool:
	var decisions: Dictionary = state.get("past_decisions", {})
	return bool(decisions.get(action_id, false))


func set_decision(action_id: String, selected: bool) -> bool:
	if state.get("phase", "") != "past_preparation":
		_set_error("Past decisions can only be changed during town preparation.", false)
		return false
	if not ACTION_COSTS.has(action_id):
		_set_error("Unknown improvement: %s" % action_id, false)
		return false
	if is_decision_selected(action_id) == selected:
		return false

	var updated_state := state.duplicate(true)
	var decisions: Dictionary = updated_state["past_decisions"]
	decisions[action_id] = selected
	var spent := 0
	for decision_id in ACTION_COSTS:
		if bool(decisions.get(decision_id, false)):
			spent += int(ACTION_COSTS[decision_id])
	var remaining := INITIAL_BUDGET - spent
	if remaining < 0:
		_set_error("Insufficient resource points for this improvement.", false)
		return false

	updated_state["remaining_budget"] = remaining
	var previous_state := state
	state = updated_state
	if not save_game():
		state = previous_state
		return false

	state_changed.emit(get_state())
	return true


func submit_decisions() -> bool:
	if state.get("phase", "") != "past_preparation":
		_set_error("Decisions have already been submitted.", false)
		return false

	var previous_state := state
	state = state.duplicate(true)
	state["phase"] = "future_investigation"
	if not save_game():
		state = previous_state
		return false

	state_changed.emit(get_state())
	return true


func _default_state() -> Dictionary:
	return {
		"schema_version": 1,
		"scenario": "flood_prevention",
		"phase": "past_preparation",
		"initial_budget": INITIAL_BUDGET,
		"remaining_budget": INITIAL_BUDGET,
		"past_decisions": {
			"repair_dam": false,
			"strengthen_bridge": false,
			"improve_drainage": false,
			"build_shelter": false,
			"install_warning_system": false,
		},
		"future_evidence": [],
		"time_echoes": [],
		"revised_decisions": {},
		"final_result": null,
	}


func _validate_state(value: Variant) -> bool:
	return _state_validation_error(value).is_empty()


func _state_validation_error(value: Variant) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return "the root value must be an object"
	var data: Dictionary = value
	for key in [
		"schema_version", "scenario", "phase", "initial_budget", "remaining_budget",
		"past_decisions", "future_evidence", "time_echoes", "revised_decisions", "final_result",
	]:
		if not data.has(key):
			return "required field '%s' is missing" % key

	if not _is_integer_number(data["schema_version"]) or int(data["schema_version"]) != 1:
		return "schema_version must be 1"
	if typeof(data["scenario"]) != TYPE_STRING or data["scenario"] != "flood_prevention":
		return "scenario must be 'flood_prevention'"
	if typeof(data["phase"]) != TYPE_STRING or not ["past_preparation", "future_investigation"].has(data["phase"]):
		return "phase is unsupported"
	if not _is_integer_number(data["initial_budget"]) or int(data["initial_budget"]) != INITIAL_BUDGET:
		return "initial_budget must be %d" % INITIAL_BUDGET
	if not _is_integer_number(data["remaining_budget"]):
		return "remaining_budget must be an integer"
	if typeof(data["past_decisions"]) != TYPE_DICTIONARY:
		return "past_decisions must be an object"
	var decisions: Dictionary = data["past_decisions"]
	var spent := 0
	for action_id in ACTION_COSTS:
		if not decisions.has(action_id) or typeof(decisions[action_id]) != TYPE_BOOL:
			return "past_decisions.%s must be a boolean" % action_id
		if decisions[action_id]:
			spent += int(ACTION_COSTS[action_id])
	if data["remaining_budget"] != INITIAL_BUDGET - spent:
		return "remaining_budget does not match the selected improvements"
	if typeof(data["future_evidence"]) != TYPE_ARRAY or typeof(data["time_echoes"]) != TYPE_ARRAY:
		return "future_evidence and time_echoes must be arrays"
	if typeof(data["revised_decisions"]) != TYPE_DICTIONARY:
		return "revised_decisions must be an object"
	if data["final_result"] != null and typeof(data["final_result"]) not in [TYPE_STRING, TYPE_DICTIONARY]:
		return "final_result must be null, a string, or an object"
	return ""


func _is_integer_number(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	return typeof(value) == TYPE_FLOAT and is_finite(value) and floorf(value) == value


func _report_error(message: String) -> bool:
	_set_error(message, true)
	return false


func _set_error(message: String, log_error: bool) -> void:
	last_error = message
	if log_error:
		push_error("[SaveManager] " + message)
	error_occurred.emit(message)
