extends Node

func _ready():
	var token: Node2D = $Player as Node2D

	var t: TileMap = $TileMap as TileMap
	Graveyard.tilemap = t

	# for x in 5:
	# 	for y in 5:
	# 		var a = Vector2(x,y) 
	# 		var b = Graveyard.is_tile_passable(a)
	# 		print(a, ' ', b)

	var a = Vector2(1, 1.041667)
	var b = Vector2(1.041667, 1.041667)	
	a = Graveyard.grid_to_world(a)
	b = Graveyard.grid_to_world(b)
	print(Graveyard.is_on_grid(a))
	print(Graveyard.is_on_grid(b))

	await get_tree().create_timer(0.2).timeout
	# get_tree().quit()