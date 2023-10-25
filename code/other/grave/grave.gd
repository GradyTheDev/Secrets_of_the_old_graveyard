class_name Grave
extends Area2D

signal cured(_self: Grave)

## [item.item_type]
@export var requested_item: String

@onready var node_ghost: Sprite2D = get_node("Ghost")
@onready var node_request: Sprite2D = get_node("Request")
@onready var node_animator: AnimationPlayer = get_node("Animator")
@onready var node_request_timer: Timer = get_node("Request/Timer")

@onready var node_talking: AudioStreamPlayer2D = get_node("Talking")

var _activated: bool = false

func _ready():
	Shared.time_of_day_changed.connect(_time_of_day_changed)

func _on_area_entered(area: Area2D):
	node_animator.play("request")
	if not _activated:
		node_talking.play()
		_activated = true
		node_request_timer.start()

func set_request(item: Item):
	requested_item = item.item_type
	node_request.texture = item.texture

func _on_area_exited(area: Area2D):
	node_talking.stop()
	node_animator.play('RESET')


func _on_request_timer_timeout():
	node_request.visible = true


func cure():
	cured.emit(self)
	var a: AudioStreamPlayer2D = $Cured
	remove_child(a)
	get_parent().add_child(a)
	a.finished.connect(a.queue_free)
	a.play()
	queue_free()

func _process(delta):
	node_request.modulate.a = remap(sin(Shared.game_time), -1,1, 0.2,0.8)

func _time_of_day_changed(daytime: bool):
	if not daytime:
		queue_free()

func interact():
	$Interact.play()