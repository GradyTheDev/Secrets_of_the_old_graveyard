class_name Player
extends CharacterBody2D

signal scrolls_changed(current_count)
signal held_item_changed(current_item)

@onready var node_held_item: TextureRect = get_node("HUD/HeldItem")
@onready var node_scroll_counter: Label = get_node("HUD/ScrollsContainer/ScrollCounter")

## pixels / second
@export var speed: int

## TODO: add Item here (needs to have a "texture": Texture variable)
var held_item = null : set = _set_held_item
var scrolls := 0 : set = _set_scrolls

func _process(delta: float):
	# input x/y
	var ix := Input.get_axis("move_left", "move_right")
	var iy := Input.get_axis("move_up", "move_down")

	var motion := Vector2(ix * speed * delta, iy * speed * delta)
	if ix != 0:
		# prevent diagonal movement
		motion.y = 0
	
	var col := move_and_collide(motion)
	if col != null:
		print('player collided with ', col)


func _set_scrolls(v):
	scrolls = v
	node_scroll_counter.text = "%s" % scrolls
	scrolls_changed.emit(scrolls)


func _set_held_item(v):
	held_item = v
	if v == null:
		node_held_item.texture = null
	else:
		node_held_item.texture = held_item.texture
	held_item_changed.emit(held_item)