extends Node3D

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const FUTURE_TIMELINE_SCENE := "res://scenes/future/future_timeline.tscn"

@onready var town: Node3D = $TownEnvironment
@onready var player: CharacterBody3D = $Player
@onready var hud: CanvasLayer = $PastHUD

var _nearby_structures: Array[Node3D] = []
var _current_structure: Node3D
var _pause_open := false


func _ready() -> void:
	if not SaveManager.has_existing_save() and not SaveManager.initialize_new_mission():
		_show_save_error()

	player.interact_requested.connect(_on_interact_requested)
	player.pause_requested.connect(_on_pause_requested)
	player.cursor_toggle_requested.connect(_on_cursor_toggle_requested)
	hud.set_decision_requested.connect(_on_set_decision_requested)
	hud.close_modal_requested.connect(_on_close_modal_requested)
	hud.view_decisions_requested.connect(_on_view_decisions_requested)
	hud.submit_decisions_requested.connect(_on_submit_decisions_requested)
	hud.submit_confirmed.connect(_on_submit_confirmed)
	hud.submit_cancelled.connect(_on_submit_cancelled)
	hud.resume_requested.connect(_on_resume_requested)
	hud.main_menu_requested.connect(_on_main_menu_requested)
	hud.cursor_toggle_requested.connect(_on_cursor_toggle_requested)
	SaveManager.state_changed.connect(_on_save_state_changed)

	for structure in town.call("get_structures"):
		structure.connect("player_entered", _on_structure_entered)
		structure.connect("player_exited", _on_structure_exited)

	var save_data: Dictionary = SaveManager.get_state()
	_apply_saved_improvements(save_data)
	hud.call("refresh_status", int(save_data["remaining_budget"]), save_data["past_decisions"])
	hud.call("set_mouse_captured", true)
	if not SaveManager.last_error.is_empty():
		hud.call("show_notice", SaveManager.last_error)


func _on_structure_entered(structure: Node3D, body: Node3D) -> void:
	if body != player or _nearby_structures.has(structure):
		return
	_nearby_structures.append(structure)
	_update_interaction_prompt()


func _on_structure_exited(structure: Node3D, body: Node3D) -> void:
	if body != player:
		return
	_nearby_structures.erase(structure)
	if _current_structure == structure and hud.call("get_modal_mode") == "structure":
		_current_structure = null
		hud.call("close_modal")
		player.call("set_mouse_captured", true)
	_update_interaction_prompt()


func _on_interact_requested() -> void:
	if not hud.call("get_modal_mode").is_empty():
		return
	var structure := _nearest_structure()
	if structure == null:
		return
	_current_structure = structure
	player.call("set_mouse_captured", false)
	hud.call(
		"show_structure_panel",
		structure.call("get_interaction_data"),
		SaveManager.is_decision_selected(str(structure.get("action_id")))
	)
	_update_interaction_prompt()


func _on_set_decision_requested(action_id: String, selected: bool) -> void:
	if not SaveManager.set_decision(action_id, selected):
		var error_message := SaveManager.last_error
		if error_message.is_empty():
			error_message = "That improvement is already in its selected state."
		hud.call("show_notice", error_message)
		return

	var save_data: Dictionary = SaveManager.get_state()
	_apply_saved_improvements(save_data)
	if hud.call("get_modal_mode") == "structure" and _current_structure != null:
		hud.call(
			"show_structure_panel",
			_current_structure.call("get_interaction_data"),
			SaveManager.is_decision_selected(str(_current_structure.get("action_id")))
		)
	elif hud.call("get_modal_mode") == "summary":
		hud.call("show_decision_summary", save_data["past_decisions"], int(save_data["remaining_budget"]))


func _on_close_modal_requested() -> void:
	_resume_gameplay()


func _on_view_decisions_requested() -> void:
	_pause_open = false
	_current_structure = null
	player.call("set_mouse_captured", false)
	var save_data: Dictionary = SaveManager.get_state()
	hud.call("show_decision_summary", save_data["past_decisions"], int(save_data["remaining_budget"]))


func _on_submit_decisions_requested() -> void:
	_pause_open = false
	_current_structure = null
	player.call("set_mouse_captured", false)
	hud.call("show_submit_confirmation")


func _on_submit_confirmed() -> void:
	if not SaveManager.submit_decisions():
		hud.call("show_notice", SaveManager.last_error)
		_on_submit_cancelled()
		return

	var change_error := get_tree().change_scene_to_file(FUTURE_TIMELINE_SCENE)
	if change_error != OK:
		hud.call("show_notice", "Decisions were saved, but the future scene could not be opened: %s" % error_string(change_error))


func _on_submit_cancelled() -> void:
	var save_data: Dictionary = SaveManager.get_state()
	hud.call("show_decision_summary", save_data["past_decisions"], int(save_data["remaining_budget"]))


func _on_resume_requested() -> void:
	_resume_gameplay()


func _on_pause_requested() -> void:
	if _pause_open:
		_resume_gameplay()
		return
	_pause_open = true
	_current_structure = null
	player.call("set_mouse_captured", false)
	hud.call("show_pause_menu")
	_update_interaction_prompt()


func _on_main_menu_requested() -> void:
	var change_error := get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	if change_error != OK:
		hud.call("show_notice", "Could not return to the main menu: %s" % error_string(change_error))


func _on_cursor_toggle_requested() -> void:
	if not hud.call("get_modal_mode").is_empty():
		return
	var captured := Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	player.call("set_mouse_captured", captured)
	hud.call("set_mouse_captured", captured)


func _on_save_state_changed(save_data: Dictionary) -> void:
	_apply_saved_improvements(save_data)
	hud.call("refresh_status", int(save_data["remaining_budget"]), save_data["past_decisions"])


func _resume_gameplay() -> void:
	_pause_open = false
	_current_structure = null
	hud.call("close_modal")
	player.call("set_mouse_captured", true)
	hud.call("set_mouse_captured", true)
	_update_interaction_prompt()


func _nearest_structure() -> Node3D:
	var nearest: Node3D
	var nearest_distance := INF
	for structure in _nearby_structures:
		if not is_instance_valid(structure):
			continue
		var distance := player.global_position.distance_squared_to(structure.global_position)
		if distance < nearest_distance:
			nearest = structure
			nearest_distance = distance
	return nearest


func _update_interaction_prompt() -> void:
	if not hud.is_node_ready():
		return
	if not hud.call("get_modal_mode").is_empty():
		hud.call("set_interaction_prompt", "")
		return
	var nearest := _nearest_structure()
	if nearest == null:
		hud.call("set_interaction_prompt", "Explore the town  ·  E to inspect nearby structures")
	else:
		hud.call("set_interaction_prompt", "Press E to inspect %s" % str(nearest.get("structure_name")))


func _apply_saved_improvements(save_data: Dictionary) -> void:
	var decisions: Dictionary = save_data.get("past_decisions", {})
	for structure in town.call("get_structures"):
		var action_id := str(structure.get("action_id"))
		structure.call("set_improved", bool(decisions.get(action_id, false)))


func _show_save_error() -> void:
	push_error("[PastTimeline] Could not initialize the new mission: %s" % SaveManager.last_error)
