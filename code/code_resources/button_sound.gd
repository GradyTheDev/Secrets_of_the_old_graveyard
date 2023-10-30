class_name ButtonSound
extends Button

@export_group("Sounds")
@export var on_click_sound: AudioStream
@export var on_hover_sound: AudioStream
@export var bus: String
@export var volume_db: float

func play_sound(sound: AudioStream):
	var audio_player = OneShotAudio.new(sound)
	audio_player.bus = bus
	audio_player.volume_db = volume_db
	GlobalSounds.add_child(audio_player)


func _on_pressed():
	if on_click_sound != null:
		play_sound(on_click_sound)

func _on_mouse_entered():
	if on_hover_sound != null:
		play_sound(on_hover_sound)
