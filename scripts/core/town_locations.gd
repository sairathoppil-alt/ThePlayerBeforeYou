extends RefCounted

const WORLD_SIZE := 100.0
const TOWN_SQUARE_ID := "town.square"

# Shared X/Z coordinates identify corresponding places in either timeline.
const LOCATIONS: Dictionary = {
	"town.square": Vector3(0.0, 0.0, 32.0),
	"town.fountain": Vector3(0.0, 0.0, 32.0),
	"town.clock_tower": Vector3(-6.0, 0.0, 32.0),
	"town.general_store": Vector3(3.0, 0.0, -34.0),
	"house.northwest": Vector3(-36.0, 0.0, -33.0),
	"house.northwest_2": Vector3(-16.0, 0.0, -34.0),
	"house.north_east": Vector3(37.0, 0.0, -33.0),
	"house.southwest": Vector3(-36.0, 0.0, 34.0),
	"house.southwest_2": Vector3(-15.0, 0.0, 34.0),
	"house.southeast": Vector3(34.0, 0.0, 39.0),
	"river.main": Vector3(0.0, 0.0, 0.0),
	"river.dam": Vector3(-22.0, 0.0, 0.0),
	"river.bridge": Vector3(14.0, 0.0, 0.0),
	"river.drainage_outlet": Vector3(0.0, 0.0, -13.6),
	"town.shelter_site": Vector3(26.0, 0.0, -34.0),
	"town.warning_tower": Vector3(-28.0, 0.0, -31.0),
	"town.archives": Vector3(-26.0, 0.0, -42.0),
	"town.workshop": Vector3(34.0, 0.0, -42.0),
	"town.construction_site": Vector3(26.0, 0.0, -34.0),
	"town.electrical_station": Vector3(-43.0, 0.0, 43.0),
	"town.maintenance_facility": Vector3(43.0, 0.0, 43.0),
	"drainage.tunnel_entrance": Vector3(4.0, 0.0, 14.0),
}

const STRUCTURE_LOCATION_IDS: Dictionary = {
	"dam": "river.dam",
	"bridge": "river.bridge",
	"drainage": "river.drainage_outlet",
	"shelter": "town.shelter_site",
	"warning_tower": "town.warning_tower",
}
