extends "res://scripts/ui/screen_base.gd"

const STEPS := [
	"WASD or arrows move, mouse looks, Space jumps and Shift sprints.",
	"Press E near items and machinery; Tab opens your six-slot inventory.",
	"M opens the shared-coordinate map, J the journal and C Echo Link.",
	"Press T for a real partner projection, or V to observe the other 3D timeline.",
	"In Local Demonstration, F4 switches roles. F reveals historical details in 2046."
]


func _ready() -> void:
	accent_color = CYAN
	super._ready()

	var page := create_page("A SHARED FATE, ACROSS TIME", "How to Play", "Explore together online, or inspect both timelines locally.")
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
