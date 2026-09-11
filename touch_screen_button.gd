extends TouchScreenButton

func _ready() -> void:
	# Muestra la capa SOLO si el dispositivo es Android o iOS
	if OS.has_feature("android") or OS.has_feature("ios"):
		show()
	else:
		hide()
