class_name Item
extends Area2D


@export var texture: Texture
@export var item_type: String


func _ready():
	var s = get_node("Sprite") as Sprite2D
	if texture != null:
		s.texture = texture
	elif s.texture != null:
		texture = s.texture


func _to_string():
	return "Item: %s %s" % [self.item_type, self.name]