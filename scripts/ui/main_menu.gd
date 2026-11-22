extends "res://scripts/ui/screen_base.gd"

const TOWN_SCENE: PackedScene = preload("res://scenes/world/town_environment.tscn")
const ADVENTURE_SCENE := "res://scenes/world/adventure_world.tscn"
const MAIN_MENU_ACCENT := Color("#61d4df")

var _join_window: Window
var _join_address: LineEdit
var _menu_camera: Camera3D


func _ready() -> void:
	accent_color = MAIN_MENU_ACCENT
	super._ready()
	_add_cinematic_background()
	var page := create_page("A COOPERATIVE TIME-TRAVEL ADVENTURE", "THE PLAYER BEFORE YOU", "Your past. Their future. One shared fate.")
	page.add_theme_constant_override("separation", 8)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 7)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page.add_child(buttons)

	var play_friend := make_button("PLAY WITH A FRIEND", true, AMBER)
	play_friend.custom_minimum_size.y = 46
	play_friend.pressed.connect(_show_friend_options)
	buttons.add_child(play_friend)

	var create_room := make_button("CREATE LAN ROOM")
	create_room.custom_minimum_size.y = 44
	create_room.pressed.connect(_create_room)
	buttons.add_child(create_room)

	var join_room := make_button("JOIN ROOM")
	join_room.custom_minimum_size.y = 44
	join_room.pressed.connect(_show_join_dialog)
	buttons.add_child(join_room)

	var local_demo := make_button("LOCAL DEMONSTRATION")
	local_demo.custom_minimum_size.y = 44
	local_demo.pressed.connect(_choose_local_timeline)
	buttons.add_child(local_demo)

	var continue_button := make_button("CONTINUE ADVENTURE")
	continue_button.custom_minimum_size.y = 44
	continue_button.disabled = not AdventureState.has_save()
	continue_button.pressed.connect(_continue_adventure)
	buttons.add_child(continue_button)

	var new_adventure := make_button("START NEW ADVENTURE")
	new_adventure.custom_minimum_size.y = 44
	new_adventure.pressed.connect(_confirm_new_adventure)
	buttons.add_child(new_adventure)

	var how_to_play := make_button("HOW TO PLAY")
	how_to_play.custom_minimum_size.y = 40
	how_to_play.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/ui/how_to_play.tscn"))
	buttons.add_child(how_to_play)

	var settings := make_button("SETTINGS")
	settings.custom_minimum_size.y = 40
	settings.pressed.connect(_show_settings)
	buttons.add_child(settings)

	var exit := make_button("EXIT")
	exit.custom_minimum_size.y = 40
	exit.pressed.connect(func() -> void: get_tree().quit())
	buttons.add_child(exit)

	if not AdventureState.last_error.is_empty():
		_show_warning(AdventureState.last_error)


func _add_cinematic_background() -> void:
	var viewport_container := SubViewportContainer.new()
	viewport_container.name = "CinematicWillowbrook"
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(viewport_container)
	move_child(viewport_container, 0)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	viewport_container.add_child(viewport)
	var town := TOWN_SCENE.instantiate() as Node3D
	town.set("timeline_year", 2026)
	town.set("create_interactive_structures", false)
	town.set("visual_only", true)
	viewport.add_child(town)
	_menu_camera = Camera3D.new()
	_menu_camera.name = "MenuCamera"
	_menu_camera.position = Vector3(40, 35, 67)
	_menu_camera.fov = 54.0
	viewport.add_child(_menu_camera)
	_menu_camera.look_at(Vector3(0, 2, 14), Vector3.UP)
	var tint := ColorRect.new()
	tint.name = "CinematicTint"
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.color = Color("#07131e", 0.38)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tint)


func _show_friend_options() -> void:
	var dialog := Window.new()
	dialog.title = "PLAY WITH A FRIEND"
	dialog.size = Vector2i(410, 250)
	dialog.min_size = Vector2i(360, 220)
	dialog.transient = true
	dialog.exclusive = true
	add_child(dialog)
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 12)
	content.add_theme_constant_override("margin_left", 24)
	content.add_theme_constant_override("margin_right", 24)
	content.add_theme_constant_override("margin_top", 20)
	content.add_theme_constant_override("margin_bottom", 20)
	dialog.add_child(content)
	content.add_child(make_body_label("Create a room on your local network, or join your friend's host address. Internet matchmaking is not configured."))
	var host := make_button("CREATE ROOM", true)
	host.pressed.connect(func() -> void:
		dialog.queue_free()
		_create_room()
	)
	content.add_child(host)
	var join := make_button("JOIN ROOM")
	join.pressed.connect(func() -> void:
		dialog.queue_free()
		_show_join_dialog()
	)
	content.add_child(join)
	dialog.popup_centered()


func _create_room() -> void:
	if not _ensure_adventure():
		return
	if not NetworkSession.create_room():
		_show_warning(NetworkSession.last_error)
		return
	AdventureState.set_timeline("past")
	NetworkSession.timeline_role = "past"
	_open_adventure()


func _show_join_dialog() -> void:
	if _join_window != null and is_instance_valid(_join_window):
		_join_window.popup_centered()
		return
	_join_window = Window.new()
	_join_window.title = "JOIN A LAN ROOM"
	_join_window.size = Vector2i(440, 210)
	_join_window.min_size = Vector2i(380, 190)
	_join_window.transient = true
	_join_window.exclusive = true
	add_child(_join_window)
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 12)
	content.add_theme_constant_override("margin_left", 22)
	content.add_theme_constant_override("margin_right", 22)
	content.add_theme_constant_override("margin_top", 18)
	content.add_theme_constant_override("margin_bottom", 18)
	_join_window.add_child(content)
	content.add_child(make_body_label("Enter the host's LAN IP address. Both clients use UDP port %d." % NetworkSession.DEFAULT_PORT))
	_join_address = LineEdit.new()
	_join_address.placeholder_text = "e.g. 192.168.1.25"
	_join_address.text = "127.0.0.1"
	content.add_child(_join_address)
	var join_button := make_button("JOIN", true)
	join_button.pressed.connect(_join_room)
	content.add_child(join_button)
	_join_window.popup_centered()


func _join_room() -> void:
	if _join_address == null or not _ensure_adventure():
		return
	var address := _join_address.text.strip_edges()
	if not NetworkSession.join_room(address):
		_show_warning(NetworkSession.last_error)
		return
	NetworkSession.timeline_role = "future"
	AdventureState.set_timeline("future")
	_join_window.hide()
	_open_adventure()


func _continue_adventure() -> void:
	if not _ensure_adventure():
		return
	NetworkSession.leave_room()
	_open_adventure()


func _choose_local_timeline() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "LOCAL DEMONSTRATION"
	dialog.dialog_text = "Choose which timeline to explore. Press F4 while playing to switch roles locally."
	var past_button := dialog.add_button("2026 — THE PAST", true, "past")
	var future_button := dialog.add_button("2046 — THE FUTURE", true, "future")
	past_button.pressed.connect(func() -> void: _start_local_role("past", dialog))
	future_button.pressed.connect(func() -> void: _start_local_role("future", dialog))
	add_child(dialog)
	dialog.popup_centered()


func _start_local_role(role: String, dialog: ConfirmationDialog) -> void:
	if not _ensure_adventure():
		return
	NetworkSession.leave_room()
	AdventureState.set_timeline(role)
	dialog.hide()
	_open_adventure()


func _confirm_new_adventure() -> void:
	var confirmation := ConfirmationDialog.new()
	confirmation.title = "START A NEW ADVENTURE?"
	confirmation.dialog_text = "Starting over replaces only the new adventure save. Your legacy flood-preparation save is kept separately."
	confirmation.confirmed.connect(func() -> void:
		if AdventureState.begin_new_adventure(true):
			NetworkSession.leave_room()
			_open_adventure()
		else:
			_show_warning(AdventureState.last_error)
	)
	add_child(confirmation)
	confirmation.popup_centered()


func _ensure_adventure() -> bool:
	if AdventureState.has_save():
		if not AdventureState.load_state():
			_show_warning(AdventureState.last_error)
			return false
		return true
	if not AdventureState.begin_new_adventure():
		_show_warning(AdventureState.last_error)
		return false
	return true


func _open_adventure() -> void:
	var result := get_tree().change_scene_to_file(ADVENTURE_SCENE)
	if result != OK:
		NetworkSession.leave_room()
		_show_warning("Could not open Willowbrook: %s" % error_string(result))


func _show_settings() -> void:
	var dialog := Window.new()
	dialog.title = "SETTINGS"
	dialog.size = Vector2i(440, 260)
	dialog.transient = true
	dialog.exclusive = true
	add_child(dialog)
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 12)
	content.add_theme_constant_override("margin_left", 24)
	content.add_theme_constant_override("margin_right", 24)
	content.add_theme_constant_override("margin_top", 20)
	content.add_theme_constant_override("margin_bottom", 20)
	dialog.add_child(content)
	var settings: Dictionary = AdventureState.get_state().get("settings", {})
	content.add_child(make_body_label("Master volume"))
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = float(settings.get("master_volume", 1.0))
	content.add_child(volume)
	content.add_child(make_body_label("Mouse sensitivity"))
	var sensitivity := HSlider.new()
	sensitivity.min_value = 0.001
	sensitivity.max_value = 0.006
	sensitivity.step = 0.0001
	sensitivity.value = float(settings.get("mouse_sensitivity", 0.0026))
	content.add_child(sensitivity)
	var save := make_button("APPLY", true)
	save.pressed.connect(func() -> void:
		var updated: Dictionary = AdventureState.get_state()
		updated["settings"]["master_volume"] = volume.value
		updated["settings"]["mouse_sensitivity"] = sensitivity.value
		AdventureState.state = updated
		AdventureState.save_state()
		var master_bus := AudioServer.get_bus_index("Master")
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(volume.value, 0.0001)))
		dialog.queue_free()
	)
	content.add_child(save)
	dialog.popup_centered()


func _show_warning(message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "THE PLAYER BEFORE YOU"
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()
