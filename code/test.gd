extends Node

func _ready():
	await get_tree().create_timer(0.2)
	get_tree().quit()