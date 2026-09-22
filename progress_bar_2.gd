extends ProgressBar

func _ready() -> void:
	# Godot 4 requiere que las "features" del OS estén en minúsculas
	if OS.has_feature("windows") or OS.has_feature("macos") or OS.has_feature("linux"):
		show()
	else:
		hide()
