extends "res://scripts/ui/screen_base.gd"


func _ready() -> void:
	accent_color = CYAN
	super._ready()

	var page := create_page("AN ASYNCHRONOUS CO-OP EXPERIENCE", "THE PLAYER BEFORE YOU", "Your past. Their future. One shared fate.")
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page.add_child(buttons)

	var start := make_button("START GAME", true)
	start.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/ui/scenario_selection.tscn"))
	buttons.add_child(start)

	var how_to_play := make_button("HOW TO PLAY")
	how_to_play.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/ui/how_to_play.tscn"))
	buttons.add_child(how_to_play)

	var credits := make_button("CREDITS")
	credits.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/ui/credits.tscn"))
	buttons.add_child(credits)

	var exit := make_button("EXIT GAME")
	exit.pressed.connect(func() -> void: get_tree().quit())
	buttons.add_child(exit)
