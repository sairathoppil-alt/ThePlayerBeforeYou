extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	accent_color = CYAN
	super._ready()

	var page := create_page("PAST TIMELINE", "Year: 2026", "Mission: Prepare the Town")
	var panel := make_panel(CYAN)
	panel.custom_minimum_size = Vector2(640, 150)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page.add_child(panel)
	var message := make_label("Town preparation gameplay will be implemented in Stage 2.", 18, MUTED)
	message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(message)

	var back := make_back_button("res://scenes/ui/disaster_introduction.tscn")
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page.add_child(back)
