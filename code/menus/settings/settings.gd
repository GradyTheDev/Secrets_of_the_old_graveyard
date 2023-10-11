extends PanelContainer

func _ready():
	var template = get_node("TextureRect/MarginContainer/VBoxContainer/Template")
	var vbox = template.get_parent()
	for bus in Shared.AUDIO_BUS_INDEX:
		var i = template.duplicate()
		i.bus = Shared.AUDIO_BUS_INDEX[bus]
		vbox.add_child(i)
	template.queue_free()


func _on_back_button_up():
	queue_free()

