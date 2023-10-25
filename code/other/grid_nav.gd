class_name GridNav
extends GDScript

class DirectionCheck:
	var can_move: bool = false
	var grid_point: Vector2
	var grid_position: Vector2

	func _init(_can_move: bool, _grid_point: Vector2, _grid_position: Vector2):
		can_move = _can_move
		grid_point = _grid_point
		grid_position = _grid_position

var grid_size: Vector2 = Vector2(24,24)
var grid_offset: Vector2 =	grid_size/2
var grid_size_real: Vector2 = grid_size + grid_offset

# var current_grid_point: Vector2
var target_grid_point: Vector2


func is_position_a_grid_point(position: Vector2) -> bool:
	return fmod(position.x, grid_size_real.x) == 0 and \
	fmod(position.y, grid_size_real.y) == 0

