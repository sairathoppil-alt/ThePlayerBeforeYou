extends "res://scripts/ui/screen_base.gd"

const STEPS := [
	"Prepare the town in 2026.",
	"Make decisions using limited resources.",
	"Investigate the consequences in 2046.",
	"Send clues back using Time Echo.",
	"Revise decisions and prevent the flood."
]


func _ready() -> void:
	accent_color = CYAN
	super._ready()

	var page := create_page("A SHARED FATE, ACROSS TIME", "How to Play", "Two players. Two timelines. One chance to change what happens.")
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(list)

	for index in range(STEPS.size()):
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 50
		row.add_theme_constant_override("separation", 18)
		list.add_child(row)
		row.add_child(make_label("%02d" % (index + 1), 18, CYAN))
		var step := make_body_label(STEPS[index], 16)
		step.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(step)

	var back := make_back_button("res://scenes/ui/main_menu.tscn")
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page.add_child(back)
