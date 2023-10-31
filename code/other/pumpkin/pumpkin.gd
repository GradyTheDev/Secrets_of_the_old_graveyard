extends Sprite2D

func _ready():
	randomize_image()
	Shared.time_of_day_changed.connect(_time_of_day_changed)
	var t = $Timer as Timer
	t.wait_time = randf_range(10, 30)
	t.start()
	await get_tree().create_timer(0.1).timeout
	set_light(not Shared.daytime)

# x: 0 -> 1
# y: 0 -> 2
func set_image(x: int, y: int):
	var at := texture as AtlasTexture
	x = x * 24
	y = y * 24
	if y < 0:
		y = at.region.position.y

	var l = $Light as Light2D
	var t = create_tween()

	var e = 0.0
	if x > 0:
		e = 0.15

	t.tween_callback(_e.bind(x,y))
	t.tween_property(l, 'energy', e, 2)
	
func _e(x,y):
	var at := texture as AtlasTexture
	at.region.position.x = x
	at.region.position.y = y

func set_light(lit: bool):
	set_image(int(lit), -1)


func randomize_image():
	set_image(
		randi_range(0, 1),
		randi_range(0, 2)
	)

func _time_of_day_changed(daytime: bool):
	set_light(not daytime)

func _on_timer_timeout():
	var n = get_parent() as Node2D
	Graveyard.spawn_pumpkins(1, n)
	queue_free.call_deferred()
