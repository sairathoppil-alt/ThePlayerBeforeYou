extends CanvasLayer

signal modal_closed
signal inventory_action(action: String, item_id: String)
signal chat_send_requested(text: String)
signal marker_requested(location_id: String, label: String)
signal dialogue_choice_requested(choice_id: String)
signal cement_message_save_requested(strokes: Array)
signal photo_requested
signal pause_action(action: String)

const PALE := Color("#edf6f6")
const MUTED := Color("#9cabb0")
const CYAN := Color("#61d4df")
const AMBER := Color("#f2b96f")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

var _root: Control
var _timeline_label: Label
var _prompt_label: Label
var _notice_label: Label
var _ability_label: Label
var _ability_ring: Control
var _shade: ColorRect
var _modal: PanelContainer
var _modal_content: VBoxContainer
var _modal_open := false
var _notice_remaining := 0.0
var _lens_viewport: SubViewport
var _lens_camera: Camera3D
var _lens_partner_avatar: CharacterBody3D
var _lens_texture: TextureRect
var _lens_frame: Control
var _main_camera: Camera3D
var _vision_tween: Tween
var _photo_viewport: SubViewport
var _photo_environment: Node3D
var _photo_scene: PackedScene
var _photo_viewports: Array[SubViewport] = []
var _last_energy := 100.0
var _last_active: Dictionary = {}


func _ready() -> void:
	_build_hud()


func _process(delta: float) -> void:
	if _notice_remaining > 0.0:
		_notice_remaining -= delta
		if _notice_remaining <= 0.0:
			_notice_label.hide()
	if _main_camera != null and is_instance_valid(_main_camera) and _lens_camera != null:
		_lens_camera.global_transform = _main_camera.global_transform
		_lens_camera.fov = _main_camera.fov


func set_timeline(year: int, role: String) -> void:
	var color := AMBER if year == 2046 else CYAN
	_timeline_label.text = "%s  —  %d" % ["FUTURE TIMELINE" if year == 2046 else "PAST TIMELINE", year]
	_timeline_label.add_theme_color_override("font_color", color)
	_timeline_label.tooltip_text = "Local role: %s" % role.capitalize()


func set_interaction_prompt(text: String) -> void:
	_prompt_label.text = text
	_prompt_label.visible = not text.is_empty()


func show_notice(text: String) -> void:
	_notice_label.text = text
	_notice_label.show()
	_notice_remaining = 3.8


func set_ability_status(energy: float, active: Dictionary, seconds_left: float) -> void:
	_last_energy = energy
	_last_active = active.duplicate(true)
	var any_active := not active.is_empty()
	_ability_label.visible = any_active
	_ability_ring.visible = any_active
	_ability_ring.set("active", any_active)
	if any_active:
		var ability_status: PackedStringArray = []
		for ability_id in active:
			var ability_name := "TIME ECHO" if ability_id == "time_echo" else "TEMPORAL VISION"
			ability_status.append("%s %02ds" % [ability_name, ceili(TemporalEnergy.get_seconds_left(str(ability_id)))])
		_ability_label.text = "%s  ·  %02d energy" % [" + ".join(ability_status), roundi(energy)]
		_ability_ring.queue_redraw()


func setup_temporal_view(town_scene: PackedScene, alternate_year: int, main_camera: Camera3D) -> void:
	_main_camera = main_camera
	_lens_partner_avatar = null
	if _lens_viewport != null:
		for child in _lens_viewport.get_children():
			child.queue_free()
	else:
		_lens_viewport = SubViewport.new()
		_lens_viewport.name = "AlternateTimelineViewport"
		_lens_viewport.size = Vector2i(640, 640)
		_lens_viewport.own_world_3d = true
		_lens_viewport.transparent_bg = false
		_lens_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		_lens_viewport.handle_input_locally = false
	if _lens_viewport.get_parent() == null:
		_root.add_child(_lens_viewport)
	var environment_scene := town_scene.instantiate() as Node3D
	environment_scene.set("create_interactive_structures", false)
	environment_scene.set("timeline_year", alternate_year)
	environment_scene.set("visual_only", true)
	_lens_viewport.add_child(environment_scene)
	_lens_camera = Camera3D.new()
	_lens_camera.name = "TemporalObservationCamera"
	_lens_camera.current = true
	_lens_viewport.add_child(_lens_camera)

	if _lens_texture == null:
		_lens_texture = TextureRect.new()
		_lens_texture.name = "TemporalObservationWindow"
		_lens_texture.set_anchors_preset(Control.PRESET_CENTER)
		_lens_texture.position = Vector2(-226, -226)
		_lens_texture.size = Vector2(452, 452)
		_lens_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_lens_texture.stretch_mode = TextureRect.STRETCH_SCALE
		_lens_texture.material = ShaderMaterial.new()
		_lens_texture.material.shader = load("res://assets/materials/temporal_lens.gdshader")
		_lens_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_lens_texture.visible = false
		_root.add_child(_lens_texture)
	_lens_texture.texture = _lens_viewport.get_texture()

	if _lens_frame == null:
		_lens_frame = Control.new()
		_lens_frame.name = "TemporalLensFrame"
		_lens_frame.set_anchors_preset(Control.PRESET_CENTER)
		_lens_frame.position = Vector2(-236, -236)
		_lens_frame.size = Vector2(472, 472)
		_lens_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_lens_frame.set_script(load("res://scripts/ui/temporal_lens_frame.gd"))
		_lens_frame.visible = false
		_root.add_child(_lens_frame)


func set_temporal_partner_state(
	visible: bool,
	transform: Transform3D,
	moving: bool,
	source_timeline: String,
	selected_item: String = ""
) -> void:
	if _lens_viewport == null:
		return
	if not visible:
		if _lens_partner_avatar != null:
			_lens_partner_avatar.visible = false
		return
	if _lens_partner_avatar == null or not is_instance_valid(_lens_partner_avatar):
		_lens_partner_avatar = PLAYER_SCENE.instantiate() as CharacterBody3D
		_lens_partner_avatar.name = "TemporalPartnerProjection"
		_lens_partner_avatar.set_meta("network_remote", true)
		_lens_partner_avatar.set_meta("timeline_role", source_timeline)
		_lens_viewport.add_child(_lens_partner_avatar)
		_lens_partner_avatar.call("set_spectral_mode", true, source_timeline)
	_lens_partner_avatar.visible = true
	_lens_partner_avatar.call("update_remote_state", transform, moving, selected_item)


func set_temporal_vision_active(value: bool) -> void:
	if _lens_texture == null or _lens_frame == null:
		return
	if _vision_tween != null and _vision_tween.is_running():
		_vision_tween.kill()
	_lens_texture.visible = true
	_lens_frame.visible = true
	_lens_frame.set("active", value)
	_lens_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if value else SubViewport.UPDATE_ONCE
	var target_alpha := 1.0 if value else 0.0
	_vision_tween = create_tween()
	_vision_tween.tween_property(_lens_texture, "modulate:a", target_alpha, 0.28)
	if not value:
		_vision_tween.tween_callback(func() -> void:
			_lens_texture.hide()
			_lens_frame.hide()
			_lens_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		)


func show_inventory(items: Array, selected_index: int) -> void:
	_open_modal("INVENTORY", "Six physical slots · select an item to equip")
	for slot_index in range(6):
		var item_data: Dictionary = items[slot_index] if slot_index < items.size() else {}
		var item_id := str(item_data.get("id", ""))
		var item_name := str(item_data.get("name", "Empty"))
		var button := _make_button(
			"%d  ·  %s%s" % [slot_index + 1, item_name, "  [EQUIPPED]" if slot_index == selected_index else ""],
			slot_index == selected_index
		)
		button.pressed.connect(func() -> void: inventory_action.emit("select", str(slot_index)))
		_modal_content.add_child(button)
		if item_id.is_empty():
			button.disabled = true
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	_modal_content.add_child(actions)
	var use_button := _make_button("USE SELECTED", true)
	use_button.pressed.connect(func() -> void: inventory_action.emit("use", ""))
	actions.add_child(use_button)
	var drop_button := _make_button("DROP SELECTED")
	drop_button.pressed.connect(func() -> void: inventory_action.emit("drop", ""))
	actions.add_child(drop_button)
	_add_close_button()


func show_map(
	locations: Dictionary,
	markers: Array,
	online: bool,
	player_position: Vector3,
	partner_position: Vector3,
	partner_visible: bool
) -> void:
	_open_modal("WILLOWBROOK MAP", "Shared coordinates · %s" % ("partner connected" if online else "offline demonstration"))
	var map_view := Control.new()
	map_view.set_script(load("res://scripts/ui/town_map_view.gd"))
	map_view.custom_minimum_size = Vector2(500, 220)
	map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_view.call(
		"set_map_data", locations, markers, player_position, partner_position, partner_visible
	)
	_modal_content.add_child(map_view)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500, 190)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_modal_content.add_child(scroll)
	var location_list := VBoxContainer.new()
	location_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	location_list.add_theme_constant_override("separation", 3)
	scroll.add_child(location_list)
	var location_ids: Array = locations.keys()
	location_ids.sort()
	for location_id in location_ids:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		location_list.add_child(row)
		var name_label := _make_label(str(location_id).replace(".", " ").capitalize(), 14, PALE)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(name_label)
		var mark := _make_button("MARK", false, 110)
		mark.pressed.connect(func() -> void: marker_requested.emit(str(location_id), "Meet here"))
		row.add_child(mark)
	if markers.size() > 0:
		_modal_content.add_child(_make_label("%d shared markers saved." % markers.size(), 13, AMBER))
	_add_close_button()


func show_journal(entries: Array, mission_info: Dictionary = {}) -> void:
	_open_modal("MISSION LOG", "Both timeline roles contribute to persistent, recoverable objectives.")
	var mission: Dictionary = mission_info.get("mission", {})
	if not mission.is_empty():
		_modal_content.add_child(_make_label(str(mission.get("title", "Current Mission")), 18, AMBER))
		_modal_content.add_child(_make_wrapped_label(str(mission.get("summary", "")), 13, MUTED))
		for objective in mission_info.get("objectives", []):
			var marker := "[DONE]" if bool(objective.get("complete", false)) else "[ ]"
			var role := str(objective.get("role", "either")).to_upper()
			_modal_content.add_child(_make_wrapped_label(
				"%s  [%s]  %s" % [marker, role, str(objective.get("text", ""))],
				12,
				PALE if bool(objective.get("complete", false)) else MUTED
			))
		_modal_content.add_child(HSeparator.new())
		_modal_content.add_child(_make_label("SHARED DISCOVERIES", 14, CYAN))
	if bool(mission_info.get("photo_available", false)):
		var photo_button := _make_button("COMPARE THE CHANGING PHOTOGRAPH", true, 420)
		photo_button.pressed.connect(func() -> void: photo_requested.emit())
		_modal_content.add_child(photo_button)
	if entries.is_empty():
		_modal_content.add_child(_make_label("No discoveries recorded yet. Inspect town landmarks with E.", 14, MUTED))
	for entry in entries.slice(maxi(0, entries.size() - 4), entries.size()):
		_modal_content.add_child(_make_wrapped_label(str(entry.get("text", "")), 14, PALE))
	_add_close_button()


func show_historical_photo(town_scene: PackedScene) -> void:
	_open_modal(
		"THE CHANGING PHOTOGRAPH",
		"An actual 3D reconstruction of Willowbrook in 2026. Persistent construction changes appear in the view."
	)
	_photo_scene = town_scene
	var comparison := HBoxContainer.new()
	comparison.add_theme_constant_override("separation", 10)
	comparison.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	comparison.add_child(_make_historical_photo_view(town_scene, true))
	comparison.add_child(_make_historical_photo_view(town_scene, false))
	_modal_content.add_child(comparison)
	_modal_content.add_child(_make_label("Both views render real 2026 town geometry. The AFTER view updates from saved changes.", 12, MUTED))
	_add_close_button()


func _make_historical_photo_view(town_scene: PackedScene, baseline: bool) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(_make_label("BEFORE" if baseline else "AFTER", 13, CYAN if baseline else AMBER))
	var container := SubViewportContainer.new()
	container.custom_minimum_size = Vector2(260, 210)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.stretch = true
	var photo_viewport := SubViewport.new()
	photo_viewport.name = "HistoricalPhotoViewport"
	photo_viewport.size = Vector2i(640, 480)
	photo_viewport.own_world_3d = true
	photo_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	photo_viewport.handle_input_locally = false
	container.add_child(photo_viewport)
	var environment := town_scene.instantiate() as Node3D
	environment.set("timeline_year", 2026)
	environment.set("create_interactive_structures", false)
	environment.set("visual_only", true)
	environment.set("photograph_baseline", baseline)
	photo_viewport.add_child(environment)
	var camera := Camera3D.new()
	camera.name = "HistoricalPhotographCamera"
	camera.position = Vector3(-38.0, 10.0, 13.0)
	camera.fov = 48.0
	photo_viewport.add_child(camera)
	camera.look_at_from_position(camera.position, Vector3(-22.0, 2.5, 0.0), Vector3.UP)
	camera.current = true
	column.add_child(container)
	_photo_viewports.append(photo_viewport)
	if not baseline:
		_photo_viewport = photo_viewport
		_photo_environment = environment
	return column


func refresh_historical_photo() -> void:
	if not _modal_open or _photo_viewport == null or not is_instance_valid(_photo_viewport):
		return
	if _photo_environment != null and is_instance_valid(_photo_environment):
		_photo_viewport.remove_child(_photo_environment)
		_photo_environment.queue_free()
	_photo_environment = _photo_scene.instantiate() as Node3D
	_photo_environment.set("timeline_year", 2026)
	_photo_environment.set("create_interactive_structures", false)
	_photo_environment.set("visual_only", true)
	_photo_viewport.add_child(_photo_environment)


func show_npc_dialogue(npc_name: String, dialogue: String) -> void:
	_open_modal(npc_name.to_upper(), "A conversation with a persistent world consequence.")
	_modal_content.add_child(_make_wrapped_label(dialogue, 15, PALE))
	var relocate := _make_button("MOVE THE EMERGENCY SUPPLIES UPSTAIRS", true, 460)
	relocate.pressed.connect(func() -> void:
		dialogue_choice_requested.emit("relocate_supplies")
		_close_modal()
	)
	_modal_content.add_child(relocate)
	var decline := _make_button("LEAVE THE SUPPLIES WHERE THEY ARE", false, 460)
	decline.pressed.connect(func() -> void:
		dialogue_choice_requested.emit("leave_supplies")
		_close_modal()
	)
	_modal_content.add_child(decline)
	_add_close_button()


func show_cement_canvas() -> void:
	_open_modal("WET CEMENT MESSAGE", "Draw a symbol, route or message. The same marks will appear on the 2046 surface.")
	var canvas := Control.new()
	canvas.name = "CementDrawingCanvas"
	canvas.set_script(load("res://scripts/ui/cement_drawing_canvas.gd"))
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_modal_content.add_child(canvas)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 8)
	_modal_content.add_child(actions)
	var clear := _make_button("CLEAR", false, 110)
	clear.pressed.connect(func() -> void: canvas.call("clear_strokes"))
	actions.add_child(clear)
	var undo := _make_button("UNDO STROKE", false, 140)
	undo.pressed.connect(func() -> void: canvas.call("undo_last_stroke"))
	actions.add_child(undo)
	var finish := _make_button("PRESERVE", true, 130)
	finish.pressed.connect(func() -> void:
		cement_message_save_requested.emit(canvas.call("get_normalized_strokes"))
		_close_modal()
	)
	actions.add_child(finish)
	var cancel := _make_button("CANCEL", false, 110)
	cancel.pressed.connect(func() -> void: _close_modal())
	actions.add_child(cancel)


func show_echo_link(messages: Array, online: bool) -> void:
	_open_modal("ECHO LINK", "Two-way LAN chat · %s" % ("partner connected" if online else "offline; sending disabled"))
	var history := RichTextLabel.new()
	history.custom_minimum_size = Vector2(480, 150)
	history.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history.bbcode_enabled = true
	history.scroll_following = true
	for message in messages.slice(maxi(0, messages.size() - 12), messages.size()):
		history.append_text("[color=#91a4b8]%s[/color]  %s\n" % [
			str(message.get("sender", "player")).capitalize(), str(message.get("text", ""))
		])
	_modal_content.add_child(history)
	var line := LineEdit.new()
	line.placeholder_text = "Write a message…"
	line.max_length = 240
	line.custom_minimum_size.x = 460
	line.editable = online
	_modal_content.add_child(line)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 8)
	_modal_content.add_child(actions)
	var send := _make_button("SEND", true, 110)
	send.disabled = not online
	send.pressed.connect(func() -> void:
		chat_send_requested.emit(line.text)
	)
	actions.add_child(send)
	for quick_text in ["I found something.", "Look at this.", "I need your help."]:
		var quick := _make_button(quick_text, false, 140)
		quick.disabled = not online
		quick.pressed.connect(func() -> void: chat_send_requested.emit(quick_text))
		actions.add_child(quick)
	_add_close_button()


func show_pause_menu() -> void:
	_open_modal("PAUSED", "Adventure progress is saved locally.")
	var resume := _make_button("RESUME", true)
	resume.pressed.connect(func() -> void: _close_modal())
	_modal_content.add_child(resume)
	var save := _make_button("SAVE CHECKPOINT")
	save.pressed.connect(func() -> void: pause_action.emit("save"))
	_modal_content.add_child(save)
	var menu := _make_button("RETURN TO MENU")
	menu.pressed.connect(func() -> void: pause_action.emit("menu"))
	_modal_content.add_child(menu)


func is_modal_open() -> bool:
	return _modal_open


func close_current_modal() -> void:
	if _modal_open:
		_close_modal()


func is_temporal_vision_active() -> bool:
	return _lens_texture != null and _lens_texture.visible


func set_mouse_captured(value: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value else Input.MOUSE_MODE_VISIBLE


func _build_hud() -> void:
	_root = Control.new()
	_root.name = "AdventureHUDRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var timeline_panel := _make_panel(CYAN)
	timeline_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	timeline_panel.position = Vector2(22, 18)
	timeline_panel.custom_minimum_size = Vector2(275, 48)
	timeline_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(timeline_panel)
	_timeline_label = _make_label("PAST TIMELINE  —  2026", 15, CYAN)
	timeline_panel.add_child(_timeline_label)
	_prompt_label = _make_label("", 15, PALE)
	_prompt_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt_label.offset_left = 300
	_prompt_label.offset_right = -300
	_prompt_label.offset_top = -76
	_prompt_label.offset_bottom = -28
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_stylebox_override("normal", _make_panel_style(CYAN))
	_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_label.hide()
	_root.add_child(_prompt_label)

	_notice_label = _make_label("", 15, PALE)
	_notice_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_notice_label.offset_left = 240
	_notice_label.offset_right = -240
	_notice_label.offset_top = 82
	_notice_label.offset_bottom = 128
	_notice_label.add_theme_stylebox_override("normal", _make_panel_style(AMBER))
	_notice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notice_label.hide()
	_root.add_child(_notice_label)

	_ability_label = _make_label("", 12, CYAN)
	_ability_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_ability_label.offset_left = -335
	_ability_label.offset_top = -75
	_ability_label.offset_right = -22
	_ability_label.offset_bottom = -25
	_ability_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ability_label.hide()
	_root.add_child(_ability_label)
	_ability_ring = Control.new()
	_ability_ring.set_script(load("res://scripts/ui/temporal_lens_frame.gd"))
	_ability_ring.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_ability_ring.position = Vector2(-58, -102)
	_ability_ring.size = Vector2(44, 44)
	_ability_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ability_ring.hide()
	_root.add_child(_ability_ring)

	_shade = ColorRect.new()
	_shade.name = "ModalShade"
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.color = Color(0.015, 0.04, 0.065, 0.78)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_shade.visible = false
	_root.add_child(_shade)
	_modal = _make_panel(CYAN)
	_modal.set_anchors_preset(Control.PRESET_CENTER)
	_modal.position = Vector2(-310, -280)
	_modal.size = Vector2(620, 560)
	_modal.custom_minimum_size = Vector2(620, 360)
	_root.resized.connect(_layout_modal)
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal.visible = false
	_root.add_child(_modal)
	_modal_content = VBoxContainer.new()
	_modal_content.add_theme_constant_override("separation", 10)
	_modal_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_modal.add_child(_modal_content)


func _open_modal(title: String, subtitle: String) -> void:
	_photo_viewport = null
	_photo_environment = null
	_photo_scene = null
	_photo_viewports.clear()
	_modal.remove_child(_modal_content)
	_modal_content.queue_free()
	_modal_content = VBoxContainer.new()
	_modal_content.add_theme_constant_override("separation", 10)
	_modal_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_modal.add_child(_modal_content)
	_modal_open = true
	_shade.show()
	_modal.show()
	_modal.modulate.a = 0.0
	_shade.modulate.a = 0.0
	_modal_content.add_child(_make_label(title, 24, CYAN))
	_modal_content.add_child(_make_wrapped_label(subtitle, 13, MUTED))
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_modal, "modulate:a", 1.0, 0.16)
	tween.tween_property(_shade, "modulate:a", 1.0, 0.16)
	_layout_modal()


func _layout_modal() -> void:
	if _modal == null or _root == null:
		return
	var available := _root.size * 0.9
	var modal_size := Vector2(minf(620.0, available.x), minf(560.0, available.y))
	_modal.size = modal_size
	_modal.custom_minimum_size = Vector2(modal_size.x, minf(360.0, modal_size.y))
	_modal.position = -modal_size * 0.5


func _close_modal() -> void:
	_modal_open = false
	_shade.hide()
	_modal.hide()
	for viewport_node in _root.find_children("*", "SubViewport", true, false):
		var historical_viewport := viewport_node as SubViewport
		if historical_viewport.name == "HistoricalPhotoViewport":
			historical_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	modal_closed.emit()


func _add_close_button() -> void:
	var close := _make_button("CLOSE", false, 160)
	close.pressed.connect(func() -> void: _close_modal())
	_modal_content.add_child(close)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_wrapped_label(text: String, font_size: int, color: Color) -> Label:
	var label := _make_label(text, font_size, color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _make_button(text: String, primary: bool = false, width: float = 260.0) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, 42)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", PALE)
	button.add_theme_stylebox_override("normal", _make_panel_style(AMBER if primary else CYAN))
	button.add_theme_stylebox_override("hover", _make_panel_style(AMBER if primary else CYAN, 1.0))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button


func _make_panel(accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(accent))
	return panel


func _make_panel_style(accent: Color, brightness: float = 0.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0a1823", 0.94)
	style.border_color = accent.lightened(brightness)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style
