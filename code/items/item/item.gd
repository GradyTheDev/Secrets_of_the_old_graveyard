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
	
	Shared.time_of_day_changed.connect(_time_of_day_changed)


func _enter_tree():
	Shared.active_items.append(self)


func _exit_tree():
	Shared.active_items.erase(self)


func _time_of_day_changed(daytime: bool):
	if not daytime:
		queue_free()


func _to_string():
	return "Item: %s %s" % [self.item_type, self.name]