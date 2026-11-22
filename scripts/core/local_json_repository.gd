extends "res://scripts/core/state_repository.gd"

var save_path := ""


func _init(path: String = "user://adventure_state.json") -> void:
	save_path = path


func exists() -> bool:
	return FileAccess.file_exists(save_path)


func read_document() -> Dictionary:
	if not exists():
		return {"ok": true, "exists": false, "data": {}}
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not open save: %s" % error_string(FileAccess.get_open_error())}
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		return {
			"ok": false,
			"error": "Save is corrupted at line %d: %s" % [parser.get_error_line(), parser.get_error_message()],
		}
	return {"ok": true, "exists": true, "data": parser.data}


func write_document(document: Dictionary) -> String:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return "Could not open save for writing: %s" % error_string(FileAccess.get_open_error())
	file.store_string(JSON.stringify(document, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return "Could not write save: %s" % error_string(write_error)
	return ""
