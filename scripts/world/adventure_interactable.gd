extends Area3D

signal interacted(interactable: Area3D, message: String)

@export var interaction_id := ""
@export var display_name := "Object"
@export_multiline var interaction_description := ""
@export_enum("inspect", "pickup", "toggle", "mission", "puzzle") var interaction_kind := "inspect"
@export var persistent_item_id := ""
@export var item_name := ""
@export var item_category := "tool"
@export_range(1.0, 12.0, 0.5) var interaction_radius := 4.5
@export var required_item_id := ""
@export var required_timeline := ""
@export var mission_objective_id := ""
@export var mission_world_flag := ""
@export var mission_action := ""


func _ready() -> void:
	add_to_group("adventure_interactable")
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = true
	if interaction_kind == "pickup" and _was_collected():
		queue_free()


func perform_interaction() -> String:
	var message := interaction_description
	match interaction_kind:
		"pickup":
			var item := {
				"id": persistent_item_id,
				"name": item_name,
				"category": item_category,
				"source": interaction_id,
			}
			if AdventureState.add_inventory_item(item):
				queue_free()
				message = "%s added to inventory." % item_name
			else:
				message = AdventureState.last_error
		"toggle":
			var new_value := not AdventureState.has_world_flag(interaction_id)
			if AdventureState.set_world_flag(interaction_id, new_value):
				message = "%s %s." % [display_name, "activated" if new_value else "deactivated"]
			else:
				message = AdventureState.last_error
		"inspect":
			if not interaction_description.is_empty():
				AdventureState.add_journal_entry(interaction_id, interaction_description)
		"mission":
			pass
		"puzzle":
			pass
	interacted.emit(self, message)
	return message


func _was_collected() -> bool:
	return AdventureState.item_is_held_or_spent(persistent_item_id)
