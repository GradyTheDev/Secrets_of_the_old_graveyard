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
@onready var node_grave_detector: Area2D = get_node("GraveDetector")
@onready var node_sprite: AnimatedSprite2D = get_node("Sprite")
@onready var node_item: Sprite2D = get_node("HeldItem")

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

func _ready():
	# snap node to grid
	position = snap_point_to_grid(position)
	_next_point = position

	node_scroll_counter.text = "%s left" % Shared.scroll_win_count

	Shared.time_of_day_changed.connect(_time_of_day_changed)

func _time_of_day_changed(daytime: bool):
	if not daytime:
		held_item = null

func _enter_tree():
	Shared.player = self

func _exit_tree():
	Shared.player = null


func snap_point_to_grid(point: Vector2) -> Vector2:
	return (point / _tile_size).floor() * _tile_size + _offset


func _physics_process(delta: float):
	# Start: Calculate movement
	var direction = DIRECTION_NONE
	
	if _input_buffer.size() == 0:
		_next_point = position
	
	# Check all inputs in input buffer, in reverse order (latest input to oldest input)
	for i in range(_input_buffer.size() - 1, -1, -1):
		direction = _input_buffer[i]

		var to = Graveyard.stop_at_first_intersection(global_position, global_position + direction * speed)
		node_wall_detector.target_position = to - position
		if _next_point != to and \
			Graveyard.is_on_grid(to) == Graveyard.ON_GRID.INTERSECTION and \
			Graveyard.is_tile_passable(Graveyard.world_to_grid(to)):
				_next_point = to
				break
	# End: Calculate movement

	var s = position
	# Start: Move
	if position.distance_to(_next_point) == 0:
		return
	
	var motion = position.move_toward(_next_point, speed * delta) - position

	var dir = position.direction_to(_next_point).x
	if dir != 0:
		node_sprite.flip_h = dir < 0
		node_item.position.x = -dir * 8

	var col := move_and_collide(motion)
	position = position.round() # fixes grid based movement problems, by rounding sub-pixel movement 
	if col != null:
		print('player collided with ', col)
	# End: Move


func _input(event: InputEvent):
	if event.is_action("drop_item") and Input.is_action_just_released("drop_item"):
		held_item = null
	elif event.is_action("interact") and Input.is_action_just_released("interact"):
		var v = node_grave_detector.get_overlapping_areas()
		if len(v) > 0 and held_item != null:
			v = v[0] as Grave
			if held_item.item_type == v.requested_item:
				held_item.queue_free()
				held_item = null
				v.cure()
				scrolls += 1
			else:
				v.interact()
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
	node_scroll_counter.text = "%s/%s" % [scrolls, Shared.scroll_win_count]
	scrolls_changed.emit(scrolls)
	if scrolls >= Shared.scroll_win_count:
		SceneHandler.change_main_scene.call_deferred(Shared.SCENES[Shared.SCENES_ENUM.victory])


func _set_held_item(v):
	_last_item = held_item

	if held_item != null:
		# print("Player dropped ", held_item)
		if not held_item.is_inside_tree():
			held_item.position = global_position
			_item_containment_node.add_child(held_item)
		
		held_item = null

	held_item = v
	if held_item == null:
		# node_held_item.texture = null
		node_item.texture = null
	else:
		# node_held_item.texture = held_item.texture
		node_item.texture = held_item.texture
		if held_item.is_inside_tree():
			if _item_containment_node == null:
				_item_containment_node = held_item.get_parent()
			held_item.get_parent().remove_child(held_item)
		# print("Player picked up ", held_item)
	
	held_item_changed.emit(held_item)

	node_held_item_label.visible = held_item != null


func _on_interact_area_entered(area):
	if _last_item != null and area == _last_item:
		_last_item = null
		return
	
	if held_item == null and area is Item:
		held_item = area


func die():
	await get_tree().process_frame
	$Death.process_mode = Node.PROCESS_MODE_ALWAYS
	$Death.play()
	SceneHandler.main_scene_container.process_mode = PROCESS_MODE_DISABLED


func _on_death_finished():
	SceneHandler.change_main_scene(Shared.SCENES[Shared.SCENES_ENUM.main_menu])