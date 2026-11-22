extends Node

const ADVENTURE_SCENE: PackedScene = preload("res://scenes/world/adventure_world.tscn")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await get_tree().process_frame
	var saved_state: Dictionary = AdventureState.get_state()
	var spawn_position := Vector3(14.0, 0.0, 31.0)
	var spawn_yaw := 0.65
	AdventureState.state["mission_progress"] = {
		"active_mission": "echo_awakening",
		"completed_missions": [],
		"contributions": [],
		"final_outcome": "",
		"objectives": {},
	}
	for timeline in ["past", "future"]:
		AdventureState.state["timeline"] = timeline
		AdventureState.state["player"] = {
			"position": [-23.6, 0.0, -13.2],
			"yaw": -0.86,
		}
		var first_mission_world := ADVENTURE_SCENE.instantiate()
		add_child(first_mission_world)
		await get_tree().process_frame
		var first_mission_player := first_mission_world.get_node("WorldRoot/LocalPlayer") as CharacterBody3D
		if first_mission_player.global_position.distance_to(spawn_position) > 0.05:
			push_error("%s first-mission checkpoint was not moved clear of the dam." % timeline)
			get_tree().quit(1)
			return
		if not is_equal_approx(first_mission_player.get_node("CameraPivot").rotation.y, 0.0):
			push_error("%s first-mission camera did not reset to a clear heading." % timeline)
			get_tree().quit(1)
			return
		first_mission_world.queue_free()
		await get_tree().process_frame
	for timeline in ["past", "future"]:
		AdventureState.state["timeline"] = timeline
		AdventureState.state["player"] = {
			"position": [spawn_position.x, spawn_position.y, spawn_position.z],
			"yaw": spawn_yaw,
		}
		var adventure := ADVENTURE_SCENE.instantiate()
		add_child(adventure)
		await get_tree().process_frame
		var player := adventure.get_node("WorldRoot/LocalPlayer") as CharacterBody3D
		var camera_pivot := player.get_node("CameraPivot") as Node3D
		if not is_equal_approx(camera_pivot.rotation.y, spawn_yaw):
			push_error("%s camera yaw did not restore from checkpoint." % timeline)
			get_tree().quit(1)
			return
		if player.global_position.distance_to(spawn_position) > 0.05:
			push_error("%s player position did not restore from checkpoint." % timeline)
			get_tree().quit(1)
			return
		adventure.queue_free()
		await get_tree().process_frame
	AdventureState.state = saved_state
	print("Camera spawn smoke test passed for both timelines.")
	get_tree().quit()
