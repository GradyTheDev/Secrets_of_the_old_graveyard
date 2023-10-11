@tool
extends Control

var AUDIO_BUS_NAMES := {
	0: 'Master',
	1: 'Music',
	2: 'SFX',
	3: 'UI',
	4: 'Voice',
}

@export var bus: Shared.AUDIO_BUS_INDEX:
	set(new):
		bus = new
		$Name.text = AUDIO_BUS_NAMES[bus]
@onready var mute_value = $HSlider.min_value

func _ready():
	$Name.text = AUDIO_BUS_NAMES[bus]
	$HSlider.value = AudioServer.get_bus_volume_db(bus)


func _on_h_slider_value_changed(value):
	AudioServer.set_bus_volume_db(bus, value)
	if value == mute_value:
		AudioServer.set_bus_mute(bus, true)
		$Name.modulate = Color.RED
	else:
		AudioServer.set_bus_mute(bus, false)
		$Name.modulate = Color.WHITE
