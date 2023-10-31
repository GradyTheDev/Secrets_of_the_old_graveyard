class_name Graveyard
extends GDScript

enum ON_GRID{
	NOT,
	LINE,
	INTERSECTION
}

const LAYER_IMPASSABLE := 0
const LAYER_PASSABLE := 1
const LAYER_GRAVE := 2
const LAYER_DECORATIONS := 3

const SOURCE_DIRT := 1
const SOURCE_NORMAL_GRAVES := 2
const SOURCE_HAUNTED_GRAVES := 3

static var grid_size: Vector2 = Vector2(24, 24)
static var grid_offset: Vector2 = grid_size/2
static var map: TileMap : set = _set_map
static var nav := AStar2D.new()


static func world_to_grid(world_position: Vector2) -> Vector2:
	return (world_position - grid_offset) / grid_size


static func grid_to_world(grid_position: Vector2) -> Vector2:
	return grid_position * grid_size + grid_offset


static func is_on_grid(world_position: Vector2) -> ON_GRID:
	var a = world_to_grid(world_position)
	var x := fmod(a.x, 1)
	var y := fmod(a.y, 1)
	
	if x == 0 and y == 0:
		return ON_GRID.INTERSECTION
	elif x != 0 and y != 0:
		return ON_GRID.NOT
	else:
		return ON_GRID.LINE


## Return value is in world space
static func get_nearest_grid_intersection(world_position: Vector2) -> Vector2:
	return grid_to_world(world_to_grid(world_position).round())


## inputs and output are in world space
## max_grid_intersection_hops limits how far you can go by intersection
## if you're at 1 and give 3 for distance, but 1 for max, then you'll only get a max of 1, not 3 or 2.5 
static func stop_at_first_intersection(from: Vector2, to: Vector2) -> Vector2:
	var from_grid := world_to_grid(from)
	var fm := Vector2(fmod(from_grid.x, 1), fmod(from_grid.y, 1))

	var to_grid := world_to_grid(to)

	var x_min: float
	var x_max: float

	var y_min: float
	var y_max: float

	if fm.x == 0:
		x_min = from_grid.x - 1
		x_max = from_grid.x + 1
	else:
		x_min = floor(from_grid.x)
		x_max = ceil(from_grid.x)
	
	if fm.y == 0:
		y_min = from_grid.y - 1
		y_max = from_grid.y + 1
	else:
		y_min = floor(from_grid.y)
		y_max = ceil(from_grid.y)

	return grid_to_world(Vector2(
		clamp(to_grid.x, x_min, x_max),
		clamp(to_grid.y, y_min, y_max)))

static func convert_arr_of_vec2i_to_vec2(arr: Array[Vector2i]) -> Array[Vector2]:
	var a: Array[Vector2] = []

	for b in arr:
		a.append(Vector2(b))

	return a

## returns values in grid space
static func get_walkable_tiles() -> Array[Vector2i]:
	return map.get_used_cells_by_id(LAYER_PASSABLE)

## returns values in grid space
static func get_normal_grave_tiles() -> Array[Vector2i]:
	return map.get_used_cells_by_id(LAYER_GRAVE, SOURCE_NORMAL_GRAVES)

## returns values in grid space
static func get_haunted_grave_tiles() -> Array[Vector2i]:
	return map.get_used_cells_by_id(LAYER_GRAVE, SOURCE_HAUNTED_GRAVES)

## returns values in grid space
static func get_tiles_with_items() -> Array[Vector2i]:
	var a: Array[Vector2i] = []

	for b in Shared.active_items:
		a.append(map.local_to_map(b.global_position))
	
	return a

## returns values in grid space
static func get_tiles_with_ghosts() -> Array[Vector2i]:
	var a: Array[Vector2i] = []

	for b in Shared.active_ghosts:
		a.append(map.local_to_map(b.global_position))
	
	return a

## Returns INF if no items exist
## Return values are in world space
static func distance_to_nearest_item(world_position: Vector2) -> float:
	var dis: float = INF

	for tile in get_tiles_with_items():
		var x = world_position.distance_to(grid_to_world(tile))
		if x < dis:
			dis = x

	return dis

## Returns INF if no items exist
## Return values are in world space
static func distance_to_nearest_ghost(world_position: Vector2) -> float:
	var dis: float = INF

	for tile in get_tiles_with_items():
		var x = world_position.distance_to(grid_to_world(tile))
		if x < dis:
			dis = x

	return dis

## Return values are in world space
static func distance_to_nearest_player(world_position: Vector2) -> float:
	return world_position.distance_to(Shared.player.global_position)

## Get tiles that don't have things around it (items, players, haunted graves.  Chasing ghosts not accounted for)
## Return values are in grid space
## Tiles are in grid space
static func get_empty_tiles(tiles: Array[Vector2i], distance_in_grid_space: float = 3) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []

	var c := distance_in_grid_space * grid_size.x

	for cell in tiles:
		if distance_to_nearest_item(cell) >= c and \
			distance_to_nearest_ghost(cell) >= c and \
			distance_to_nearest_player(cell) >= c:
			empty.append(cell)

	return empty


## Doesn't account for items, ghosts or other dynamic elements, or physics just tile layer
static func is_tile_passable(grid_position: Vector2) -> bool:
	return map.get_cell_atlas_coords(LAYER_PASSABLE, grid_position) != -Vector2i.ONE


static func is_tile_grave(grid_position: Vector2) -> bool:
	return map.get_cell_atlas_coords(LAYER_GRAVE, grid_position)  != -Vector2i.ONE

static func is_direction_diagonal(a: Vector2, b: Vector2):
	return a.x != b.x and a.y != b.y

static func _set_map(v):
	map = v

	if map == null:
		nav.clear()
	else:
		setup_nav()


static func setup_nav():
	var cells := map.get_used_cells_by_id(LAYER_PASSABLE)

	var cid = 0
	for cell in cells:
		nav.add_point(cid, grid_to_world(cell))
		cid += 1

	for cell in cells:
		var n := map.get_surrounding_cells(cell)
		for c in n:
			if is_tile_passable(c):
				var a := nav.get_closest_point(grid_to_world(cell))
				var b := nav.get_closest_point(grid_to_world(c))
				nav.connect_points(a, b)


static func nav_to(world_from: Vector2, world_to: Vector2) -> PackedVector2Array:
	var a := nav.get_closest_point(world_from)
	var b := nav.get_closest_point(world_to)
	var c := nav.get_id_path(a, b)
	var d: PackedVector2Array = []
	for x in c:
		d.append(nav.get_point_position(x))
	return d


static func place_random_grave(grid_position: Vector2i, source: int = SOURCE_NORMAL_GRAVES):
	var p = Vector2i(randi_range(0, 5), randi_range(0, 3))

	var s = map.get_cell_source_id(LAYER_GRAVE, grid_position)
	if s != -1:
		p.x = map.get_cell_atlas_coords(LAYER_GRAVE, grid_position).x
		map.set_cell(LAYER_GRAVE, grid_position, source, p)
	else:
		map.set_cell(LAYER_GRAVE, grid_position, source, p)

	Graveyard.map.set_cell(LAYER_GRAVE, grid_position, source, p)



static func remove_grave(grid_position: Vector2i):
	map.erase_cell(LAYER_GRAVE, grid_position)


static func remove_all_graves():
	map.clear_layer(LAYER_GRAVE)


static func reset_haunted_graves():
	for x in map.get_used_cells_by_id(LAYER_GRAVE, SOURCE_HAUNTED_GRAVES):
		place_random_grave(x)

static func set_nav_weight(world_position: Vector2, weight: float = 1):
	nav.set_point_weight_scale(nav.get_closest_point(world_position), weight)

static func get_nav_weight(world_position: Vector2) -> float:
	return nav.get_point_weight_scale(nav.get_closest_point(world_position))

static func spawn_pumpkins(n: int, to: Node2D):
	for i in range(n):
		var cells = Graveyard.get_walkable_tiles()
		var cell = cells[ randi_range(0, len(cells)-1) ]
		var pos = Graveyard.grid_to_world(cell)
		var p: Node2D = load("res://code/other/pumpkin/pumpkin.tscn").instantiate()
		to.add_child(p)
		p.position = pos