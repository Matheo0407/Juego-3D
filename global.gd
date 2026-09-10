extends Node

# Variable global para guardar si la pistola está desbloqueada
var get_pistol: bool = false

func reproducir(ruta_sonido: String):
	if ResourceLoader.exists(ruta_sonido):
		var sonido = load(ruta_sonido)
		var fx_player = AudioStreamPlayer.new()
		add_child(fx_player)
		fx_player.stream = sonido
		fx_player.play()
		fx_player.finished.connect(fx_player.queue_free)
	else:
		push_error("No se encontró el archivo de audio en la ruta: " + ruta_sonido)
