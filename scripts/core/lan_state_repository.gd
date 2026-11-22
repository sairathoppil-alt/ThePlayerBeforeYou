extends "res://scripts/core/local_json_repository.gd"


func publish_event(event: Dictionary) -> bool:
	match str(event.get("type", "")):
		"world_flag":
			return NetworkSession.send_world_flag(str(event.get("id", "")), bool(event.get("value", false)))
		"marker":
			return NetworkSession.send_marker(str(event.get("location_id", "")), str(event.get("label", "")))
		"journal":
			return NetworkSession.send_journal_entry(str(event.get("id", "")), str(event.get("text", "")))
		"mission":
			return NetworkSession.send_mission_objective(str(event.get("id", "")))
		"puzzle_state":
			return NetworkSession.send_puzzle_state(
				str(event.get("update_type", "")),
				event.get("payload", {})
			)
	return false
