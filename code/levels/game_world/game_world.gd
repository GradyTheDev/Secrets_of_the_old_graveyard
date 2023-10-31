extends Node2D

@onready var node_graveyard_tilemap: TileMap = get_node("Graveyard")
@onready var node_light: Light2D = get_node("Light")
@onready var node_graves = get_node("Graves")
@onready var node_items = get_node("Items")
@onready var node_ghosts = get_node("Ghosts")
@onready var node_music_day: AudioStreamPlayer = get_node("AmbientDay")
@onready var node_music_night: AudioStreamPlayer = get_node("AmbientNight")
@onready var node_night_music: AudioStreamPlayer = get_node("NightMusic")
@onready var node_nav_line: Line2D = get_node("NavLine")
@onready var node_night: Node2D = get_node("night")
@onready var node_day: Node2D = get_node("day")
@onready var node_deco: Node2D = get_node("Deco")
@onready var moving_scroll: Node2D = get_node("Scroll")

# @onready var node_background_b: Sprite2D = get_node("filler_day")

@export var image_night: Texture
@export var image_day: Texture

var color_white := Color.WHITE
var color_transparent := Color(1,1,1,0)


var _grave_normal = 2
var _grave_haunted = 3

var _graves: Array[Grave] = []

func _ready():
	Graveyard.map = node_graveyard_tilemap
	node_light.visible = true
	Shared.game_time = -0.1
	Shared.time_of_day_changed.connect(_time_of_day_changed)
	Shared.game_time = 0.1

	var passable_cells := Graveyard.map.get_used_cells_by_id(Graveyard.LAYER_PASSABLE)
	var lpc = passable_cells.size() -1

	_randomize_graves()
	Graveyard.spawn_pumpkins(5, node_deco)

	if get_parent() == get_tree().root:
		SceneHandler.change_main_scene.call_deferred(self)


var _vis_time := 2
func _time_of_day_changed(daytime: bool):
	if daytime:
		var t = node_night.create_tween()
		t.tween_property(node_night, 'modulate', color_transparent, 2)
		t = node_day.create_tween()
		t.tween_property(node_day, 'modulate', color_white, 2)

		generate_haunted_graves(5)
		node_music_day.play()
		node_music_night.stop()
		node_night_music.stop()
	else:
		var t = node_day.create_tween()
		t.tween_property(node_day, 'modulate', color_transparent, 2)
		t = node_night.create_tween()
		t.tween_property(node_night, 'modulate', color_white, 2)

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

	Graveyard.reset_haunted_graves()

func _get_available_graves() -> Array[Vector2i]:
	var normal_graves: Array[Vector2i] = []
	var haunted_graves: Array[Vector2i] = []
	var available_graves: Array[Vector2i] = []

	var player_pos := Vector2(node_graveyard_tilemap.local_to_map(Shared.player.position))

	var cells = node_graveyard_tilemap.get_used_cells(Graveyard.LAYER_GRAVE)
	for point in cells:
		var a = node_graveyard_tilemap.get_cell_source_id(Graveyard.LAYER_GRAVE, point)
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
	for point in node_graveyard_tilemap.get_used_cells(Graveyard.LAYER_PASSABLE):
		if player_on_grid.distance_to(point) > 1:
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
		Graveyard.place_random_grave(point, Graveyard.SOURCE_HAUNTED_GRAVES)
		
		# Create and place grave
		var grave = Shared.grave.instantiate()
		grave.cured.connect(_cured)
		node_graves.add_child(grave)
		grave.set_request(item)
		grave.global_position = node_graveyard_tilemap.map_to_local(point)
		grave.tree_exiting.connect(_grave_cleanup.bind(grave))


func _cured(g: Grave):
	var point = node_graveyard_tilemap.local_to_map(g.global_position)
	node_graveyard_tilemap.set_cell(Graveyard.LAYER_GRAVE, point, _grave_normal, Vector2.ZERO)
	moving_scroll.position = g.position
	var t = moving_scroll.create_tween()
	t.tween_property(moving_scroll, 'scale', Vector2.ONE, 0.3)
	# t.tween_property(moving_scroll, 'position', Shared.player.position, 1.5)
	t.tween_method(_fe, 0, 1, 1.5)
	t.tween_property(moving_scroll, 'scale', Vector2(0.1,0.1), 0.3)
	t.tween_property(moving_scroll, 'position', Vector2(-30,-30), 0)

func _fe(v):
	Shared.player.position
	moving_scroll.position = moving_scroll.position.move_toward(Shared.player.position, 1)



func _grave_cleanup(grave: Grave):
	_graves.erase(grave)


func spawn_ghosts():
	var tiles := get_dirt_tiles()

	for i in range(Shared.ghosts.size()):
		var r = randi_range(0, tiles.size()-1)
		var tile: Vector2 = tiles.pop_at(r)
		var ghost: Ghost = Shared.ghosts[i].instantiate()
		var pos = node_graveyard_tilemap.map_to_local(tile)
		node_ghosts.add_child(ghost)
		ghost.position = pos

		for x in tiles:
			if tile.distance_to(x) <= 1:
				tiles.erase(x)


func _randomize_graves():
	for cell in Graveyard.get_normal_grave_tiles():
		Graveyard.remove_grave(cell)
		Graveyard.place_random_grave(cell)