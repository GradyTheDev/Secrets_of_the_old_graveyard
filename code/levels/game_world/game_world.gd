extends Node2D

@onready var node_graveyard_tilemap: TileMap = get_node("Graveyard")

var _grave_normal = Vector2i(2, 0)
var _grave_haunted = Vector2i(3, 0)

func _ready():
	generate_haunted_graves(5)

func clear_haunted_graves():
	var cells = node_graveyard_tilemap.get_used_cells(0)
	for point in cells:
		var a = node_graveyard_tilemap.get_cell_atlas_coords(0, point)
		if a == _grave_haunted:
			node_graveyard_tilemap.set_cell(0, point, 0, _grave_normal)

func _get_available_graves():
	var normal_graves: Array[Vector2i] = []
	var haunted_graves: Array[Vector2i] = []
	var available_graves: Array[Vector2i] = []

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
			if Vector2(haunted).distance_to(Vector2(normal)) <= 2:
				far = false
				break
		if far:
			available_graves.append(normal)
	
	return available_graves

func generate_haunted_graves(amount: int):
	for i in range(amount):
		var graves = _get_available_graves()
		if len(graves) == 0:
			print("Failed to haunt ", amount, " graves, stopped at ", i)
			return
		
		var point = graves[randi_range(0, len(graves)-1)]
		node_graveyard_tilemap.set_cell(0, point, 0, _grave_haunted)