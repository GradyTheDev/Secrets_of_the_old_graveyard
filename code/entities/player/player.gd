class_name Player
extends CharacterBody2D

const DIRECTION_NONE = Vector2.ZERO
const DIRECTION_DOWN = Vector2(0,1)
const DIRECTION_UP = Vector2(0,-1)
const DIRECTION_RIGHT = Vector2(1,0)
const DIRECTION_LEFT = Vector2(-1,0)

signal scrolls_changed(current_count)
signal held_item_changed(current_item)

@onready var node_held_item: TextureRect = get_node("HUD/HeldItem")
@onready var node_scroll_counter: Label = get_node("HUD/ScrollCounter")
@onready var node_interact_area: Area2D = get_node("InteractArea")
@onready var node_held_item_label: Label = get_node("HUD/HeldItemLabel")
@onready var node_wall_detector: RayCast2D = get_node("WallDetector")

## pixels / second
@export var speed: int

var held_item: Item = null : set = _set_held_item
var scrolls := 0 : set = _set_scrolls

var _last_item: Item = null

var _tile_size := Vector2(24,24)
var _offset := (_tile_size / 2).round()

var _input_buffer: Array[Vector2] = []
var _next_point: Vector2

var _item_containment_node: Node

class DirectionCheck:
	var can_move: bool = false
	var grid_point: Vector2
	var grid_position: Vector2

	func _init(_can_move: bool, _grid_point: Vector2, _grid_position: Vector2):
		can_move = _can_move
		grid_point = _grid_point
		grid_position = _grid_position


## Only call this from the physics thread, due to the raycast
func can_move_to_node_in_direction(direction: Vector2) -> DirectionCheck:
	direction = direction

	# Grid check
	var current_grid_point := (position - _offset) / _tile_size

	var target_grid_point = current_grid_point.round() + direction
	var target_grid_position = target_grid_point * _tile_size + _offset

	var dir = current_grid_point.direction_to(target_grid_point)
	var is_movement_on_grid_line = not (dir.x != 0 and dir.y != 0)

	if not is_movement_on_grid_line:
		return DirectionCheck.new(false, target_grid_point, target_grid_position)
	
	# Physics check
	node_wall_detector.target_position = target_grid_position - position
	node_wall_detector.force_raycast_update()
	if node_wall_detector.is_colliding():
		return DirectionCheck.new(false, target_grid_point, target_grid_position)
	else:
		return DirectionCheck.new(true, target_grid_point, target_grid_position)


func _ready():
	# snap node to grid
	position = snap_point_to_grid(position)
	_next_point = position


func snap_point_to_grid(point: Vector2) -> Vector2:
	return (point / _tile_size).floor() * _tile_size + _offset


func _physics_process(delta: float):
	# Start: Calculate movement
	var direction = DIRECTION_NONE

	# Only check last input in input buffer
	# if _input_buffer.size() == 0:
	# 	_next_point = position
	# else:
	# 	direction = _input_buffer[-1]
	# 	var check = can_move_to_node_in_direction(direction)
	# 	if check.can_move:
	# 		_next_point = check.grid_position

	# Check all inputs in input buffer, in reverse order (latest input to oldest input)
	for i in range(_input_buffer.size() - 1, -1, -1):
		if _input_buffer.size() == 0:
			_next_point = position
		else:
			direction = _input_buffer[i]
			var check = can_move_to_node_in_direction(direction)
			if check.can_move:
				_next_point = check.grid_position
				break
	# End: Calculate movement

	# Start: Move
	if position.distance_to(_next_point) == 0:
		return
	
	var motion = position.move_toward(_next_point, speed * delta) - position

	var col := move_and_collide(motion)
	if col != null:
		print('player collided with ', col)

	if position.distance_to(_next_point) < 1.0:
		position = _next_point
	# End: Move

func _input(event: InputEvent):
	if event.is_action("drop_item") and Input.is_action_just_released("drop_item"):
		held_item = null
	elif event.is_action("ui_cancel") and Input.is_action_just_released("ui_cancel"):
		SceneHandler.add_popup(Shared.POPUPS[Shared.POPUPS_ENUM.pause])
	
	elif event.is_action("move_up"):
		if event.is_released():
			_input_buffer.erase(DIRECTION_UP)
		elif not DIRECTION_UP in _input_buffer:
			_input_buffer.append(DIRECTION_UP)
	
	elif event.is_action("move_down"):
		if event.is_released():
			_input_buffer.erase(DIRECTION_DOWN)
		elif not DIRECTION_DOWN in _input_buffer:
			_input_buffer.append(DIRECTION_DOWN)
	
	elif event.is_action("move_left"):
		if event.is_released():
			_input_buffer.erase(DIRECTION_LEFT)
		elif not DIRECTION_LEFT in _input_buffer:
			_input_buffer.append(DIRECTION_LEFT)
	
	elif event.is_action("move_right"):
		if event.is_released():
			_input_buffer.erase(DIRECTION_RIGHT)
		elif not DIRECTION_RIGHT in _input_buffer:
			_input_buffer.append(DIRECTION_RIGHT)


func _set_scrolls(v):
	scrolls = v
	node_scroll_counter.text = "%s" % scrolls
	scrolls_changed.emit(scrolls)
	if scrolls >= 15:
		SceneHandler.change_main_scene.call_deferred(Shared.SCENES[Shared.SCENES_ENUM.victory])


func _set_held_item(v):
	_last_item = held_item

	if held_item != null:
		print("Player dropped ", held_item)
		if not held_item.is_inside_tree():
			held_item.position = global_position
			_item_containment_node.add_child(held_item)
		
		held_item = null

	held_item = v
	if held_item == null:
		node_held_item.texture = null
	else:
		node_held_item.texture = held_item.texture
		if held_item.is_inside_tree():
			if _item_containment_node == null:
				_item_containment_node = held_item.get_parent()
			held_item.get_parent().remove_child(held_item)
		print("Player picked up ", held_item)
	
	held_item_changed.emit(held_item)

	node_held_item_label.visible = held_item != null


func _on_interact_area_entered(area):
	if _last_item != null and area == _last_item:
		_last_item = null
		return
	
	if held_item == null and area is Item:
		held_item = area
