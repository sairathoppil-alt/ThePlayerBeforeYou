extends Node

signal ability_state_changed(energy: float, active: Dictionary, seconds_left: float)
signal ability_ended(ability_id: String, reason: String)

@export_range(1.0, 500.0, 1.0) var maximum_energy := 100.0
@export_range(0.0, 100.0, 0.5) var minimum_activation_energy := 10.0
@export_range(0.1, 120.0, 0.5) var time_echo_duration := 20.0
@export_range(0.1, 120.0, 0.5) var temporal_vision_duration := 15.0
@export_range(0.0, 20.0, 0.1) var time_echo_drain := 2.0
@export_range(0.0, 20.0, 0.1) var temporal_vision_drain := 3.0
@export_range(0.0, 20.0, 0.1) var recharge_rate := 2.0
@export_range(0.0, 120.0, 0.5) var recharge_delay := 10.0

var energy := 100.0
var active: Dictionary = {}
var _elapsed: Dictionary = {}
var _recharge_wait := 0.0


func _ready() -> void:
	var saved_energy := float(AdventureState.get_state().get("temporal_energy", maximum_energy))
	energy = clampf(saved_energy, 0.0, maximum_energy)


func _process(delta: float) -> void:
	if active.is_empty():
		if energy < maximum_energy:
			if _recharge_wait > 0.0:
				_recharge_wait = maxf(0.0, _recharge_wait - delta)
			else:
				energy = minf(maximum_energy, energy + recharge_rate * delta)
				_emit_state()
		return

	var drain := 0.0
	for ability_id in active.keys():
		drain += _drain_rate(str(ability_id))
		_elapsed[ability_id] = float(_elapsed.get(ability_id, 0.0)) + delta
	energy = maxf(0.0, energy - drain * delta)

	var expired: Array[String] = []
	for ability_id in active.keys():
		if float(_elapsed[ability_id]) >= _duration(str(ability_id)):
			expired.append(str(ability_id))
	for ability_id in expired:
		deactivate(ability_id, "duration expired")
	if energy <= 0.0:
		for ability_id in active.keys().duplicate():
			deactivate(str(ability_id), "energy depleted")
	_emit_state()


func can_activate(ability_id: String) -> bool:
	if not ["time_echo", "temporal_vision"].has(ability_id):
		return false
	return not bool(active.get(ability_id, false)) and energy >= minimum_activation_energy


func activate(ability_id: String, partner_available: bool = false) -> bool:
	if not can_activate(ability_id):
		return false
	if ability_id == "time_echo" and not partner_available:
		return false
	active[ability_id] = true
	_elapsed[ability_id] = 0.0
	_recharge_wait = recharge_delay
	_emit_state()
	return true


func deactivate(ability_id: String, reason: String = "manual") -> void:
	if not bool(active.get(ability_id, false)):
		return
	active.erase(ability_id)
	_elapsed.erase(ability_id)
	if active.is_empty():
		_recharge_wait = recharge_delay
	ability_ended.emit(ability_id, reason)
	_emit_state()


func is_active(ability_id: String) -> bool:
	return bool(active.get(ability_id, false))


func get_seconds_left(ability_id: String) -> float:
	return maxf(0.0, _duration(ability_id) - float(_elapsed.get(ability_id, 0.0)))


func _duration(ability_id: String) -> float:
	return time_echo_duration if ability_id == "time_echo" else temporal_vision_duration


func _drain_rate(ability_id: String) -> float:
	return time_echo_drain if ability_id == "time_echo" else temporal_vision_drain


func _emit_state() -> void:
	var seconds_left := 0.0
	for ability_id in active.keys():
		seconds_left = maxf(seconds_left, get_seconds_left(str(ability_id)))
	ability_state_changed.emit(energy, active.duplicate(true), seconds_left)
