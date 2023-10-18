extends Control

@export var player: Player

@onready var node_scroll: TextureRect = get_node("Scroll")
@onready var node_scroll_counter: Label = get_node("ScrollCounter")
@onready var node_held_item: TextureRect = get_node("HeldItem")
@onready var node_held_item_label: Label = get_node("HeldItemLabel")

func _ready():
	node_held_item.visible = false
	node_held_item_label.visible = false

	# todo: combine drop & interact into a single dynamic action drop/give
	# that drops the item if there isn't anything to interact with
	# but if there is (a ghost requesting the item in hand) give 
	# also changes the label based on if the player is next to a interactable (ghost) or not
	# todo: dynamically update this label if the input actions change
	node_held_item_label.text = "%s: Drop\n%s: Interact" % [
		InputMap.action_get_events("drop_item")[0].as_text(),
		InputMap.action_get_events("interact")[0].as_text(),
	]

	player.scrolls_changed.connect(_scrolls_changed)
	player.held_item_changed.connect(_held_item_changed)

	get_viewport().size_changed.connect(_root_viewport_size_changed)


func _scrolls_changed(count: int):
	node_scroll_counter.text = "%s" % count

func _held_item_changed(item: Item):
	if item == null:
		node_held_item.texture = null
	else:
		node_held_item.texture = item.texture
	
	node_held_item.visible = item != null
	node_held_item_label.visible = node_held_item.visible



@onready var node_icon = get_node("Icon") as Sprite2D
var w = Vector2.ZERO

func _root_viewport_size_changed():
	var a = get_viewport_rect()
	var b = node_icon.get_rect()
	var c = Vector2(0, a.size.y - b.size.y)
	node_icon.global_position = Vector2.ZERO

	print(a.size, ' ', b.size)


func _draw():
	node_icon.global_position = w



	
		
