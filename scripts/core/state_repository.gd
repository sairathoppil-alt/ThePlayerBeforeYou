extends RefCounted


func read_document() -> Dictionary:
	return {"ok": false, "error": "State repository does not implement document reads."}


func write_document(_document: Dictionary) -> String:
	return "State repository does not implement document writes."


func publish_event(_event: Dictionary) -> bool:
	return false
