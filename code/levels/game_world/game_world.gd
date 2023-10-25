extends Node2D

@onready var node_graveyard_tilemap: TileMap = get_node("Graveyard")
@onready var node_light: Light2D = get_node("Light")
@onready var node_graves = get_node("Graves")
@onready var node_items = get_node("Items")
@onready var node_ghosts = get_node("Ghosts")
@onready var node_music_day: AudioStreamPlayer = get_node("AmbientDay")
@onready var node_music_night: AudioStreamPlayer = get_node("AmbientNight")
@onready var node_night_music: AudioStreamPlayer = get_node("NightMusic")

var _grave_normal = Vector2i(2, 0)
var _grave_haunted = Vector2i(3, 0)
var _walking_path = Vector2i(0, 0)

var _graves: Array[Grave] = []

func _ready():
	node_light.visible = true
	Shared.game_time = -0.1
	Shared.time_of_day_changed.connect(_time_of_day_changed)
	Shared.game_time = 0.1


func _time_of_day_changed(daytime: bool):
	if daytime:
		await get_tree().create_timer(2).timeout
		generate_haunted_graves(5)
		node_music_day.play()
		node_music_night.stop()
		node_night_music.stop()
	else:
		clear_haunted_graves()
		node_music_day.stop()
		node_music_night.play()
		node_night_music.play()
		spawn_ghosts()

func _process(delta: float):
	Shared.game_time += delta
	node_light.energy = remap(Shared.get_game_cycle(), -1, 1, -0.8, -0.5)

func clear_haunted_graves():
	for grave in _graves:
		grave.queue_free()
	
	var cells = node_graveyard_tilemap.get_used_cells(0)
	for point in cells:
		var a = node_graveyard_tilemap.get_cell_atlas_coords(0, point)
		if a == _grave_haunted:
			node_graveyard_tilemap.set_cell(0, point, 0, _grave_normal)

func _get_available_graves():
	var normal_graves: Array[Vector2i] = []
	var haunted_graves: Array[Vector2i] = []
	var available_graves: Array[Vector2i] = []

	var player_pos := Vector2(node_graveyard_tilemap.local_to_map(Shared.player.position))

	var cells = node_graveyard_tilemap.get_used_cells(0)
	for point in cells:
		var a = node_graveyard_tilemap.get_cell_atlas_coords(0, point)
		if a == _grave_normal:
			normal_graves.append(point)
		elif a == _grave_haunted:
			haunted_graves.append(point)
	
	for normal in normal_graves:
		var far = true
		for haunted in haunted_graves:
			if Vector2(haunted).distance_to(Vector2(normal)) <= 3:
				far = false
				break
			elif player_pos.distance_to(Vector2(normal)) < 3:
				far = false
				break
		if far:
			available_graves.append(normal)
	
	return available_graves


## For item placement
## in tilemap coordinates
func get_dirt_tiles() -> Array[Vector2]:
	var tiles: Array[Vector2] = []
	var player_on_grid = Vector2(node_graveyard_tilemap.local_to_map(Shared.player.position))
	for point in node_graveyard_tilemap.get_used_cells(0):
		if node_graveyard_tilemap.get_cell_atlas_coords(0, point) == _walking_path and \
			player_on_grid.distance_to(point) > 1:
			tiles.append(Vector2(point))
	return tiles


func generate_haunted_graves(amount: int):
	var empty_tiles = get_dirt_tiles()

	for i in range(amount):
		var graves = _get_available_graves()
		if len(graves) == 0:
			print("Failed to haunt ", amount, " graves, stopped at ", i)
			return

		# Create and place item
		var item = Shared.items[randi_range(0,len(Shared.items)-1)].instantiate()
		var n = randi_range(0, len(empty_tiles)-1)
		n = empty_tiles.pop_at(n)
		n = node_graveyard_tilemap.map_to_local(n)
		item.position = n
		node_items.add_child(item)


		# Set tile to haunted grave
		var point = graves[randi_range(0, len(graves)-1)]
		node_graveyard_tilemap.set_cell(0, point, 0, _grave_haunted)	
		
		# Create and place grave
		var grave = Shared.grave.instantiate()
		grave.cured.connect(_cured)
		node_graves.add_child(grave)
		grave.set_request(item)
		grave.global_position = node_graveyard_tilemap.map_to_local(point)
		grave.tree_exiting.connect(_grave_cleanup.bind(grave))


func _cured(g: Grave):
	var point = node_graveyard_tilemap.local_to_map(g.global_position)
	node_graveyard_tilemap.set_cell(0, point, 0, _grave_normal)


func _grave_cleanup(grave: Grave):
	_graves.erase(grave)


func spawn_ghosts():
	var tiles := get_dirt_tiles()

	for i in 3:
		var r = randi_range(0, tiles.size()-1)
		var tile: Vector2 = tiles.pop_at(r)
		var ghost: Ghost = Shared.ghost.instantiate()
		var pos = node_graveyard_tilemap.map_to_local(tile)
		node_ghosts.add_child(ghost)
		ghost.position = pos

		for x in tiles:
			if tile.distance_to(x) <= 1:
				tiles.erase(x)





