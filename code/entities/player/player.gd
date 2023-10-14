class_name Player
extends CharacterBody2D

signal scrolls_changed(current_count)
signal held_item_changed(current_item)

@onready var node_held_item: TextureRect = get_node("HUD/HeldItem")
@onready var node_scroll_counter: Label = get_node("HUD/ScrollCounter")
@onready var node_interact_area: Area2D = get_node("InteractArea")
@onready var node_held_item_label: Label = get_node("HUD/HeldItemLabel")

## pixels / second
@export var speed: int

var held_item: Item = null : set = _set_held_item
var scrolls := 0 : set = _set_scrolls

var _last_item: Item = null

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

func _input(event):
	if event.is_action("drop_item") and Input.is_action_just_released("drop_item"):
		held_item = null
	elif event.is_action("ui_cancel") and Input.is_action_just_released("ui_cancel"):
		SceneHandler.add_popup(Shared.POPUPS[Shared.POPUPS_ENUM.pause])

func _set_scrolls(v):
	scrolls = v
	node_scroll_counter.text = "%s" % scrolls
	scrolls_changed.emit(scrolls)


func _set_held_item(v):
	_last_item = held_item

	if held_item != null:
		print("Player dropped ", held_item)
		if not held_item.is_inside_tree():
			held_item.position = global_position
			get_parent().add_child(held_item)
		
		held_item = null

	held_item = v
	if held_item == null:
		node_held_item.texture = null
	else:
		node_held_item.texture = held_item.texture
		if held_item.is_inside_tree():
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
