extends RichTextLabel


func _ready():
	text = text.replace('Great game title', ProjectSettings.get_setting("application/config/name"))