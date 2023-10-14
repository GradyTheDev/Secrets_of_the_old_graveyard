extends Control

@onready var node_credits = get_node("ClipCredits/Credits") as RichTextLabel

func _ready():
	node_credits.position = Vector2(0, node_credits.size.y)
	var t = node_credits.create_tween()
	t.tween_interval(5) # wait for cutscene to end
	
	# roll credits
	var pos = Vector2(0, -node_credits.size.y)
	var time = node_credits.get_line_count() * 2
	t.tween_property(node_credits, 'position', pos, time)
	t.play()


func _on_main_menu_pressed():
	if get_parent() == get_tree().root:
		queue_free()
	SceneHandler.change_main_scene(Shared.SCENES[Shared.SCENES_ENUM.main_menu])
	

