extends ProgressBar

func _ready() -> void:
	# En Godot 4, "android" e "ios" se escriben estrictamente en minúsculas
	if OS.has_feature("android") or OS.has_feature("ios"):
		show()
	else:
		hide()
