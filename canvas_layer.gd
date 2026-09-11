extends CharacterBody3D # O "extends Node" según el tipo de tu nodo

@export var SaludMax: float = 100.0
var SaludAhora: float = 100.0

@onready var barra_vida: ProgressBar = $CanvasLayer/ProgressBar

func _ready() -> void:
	SaludAhora = SaludMax
	if barra_vida:
		barra_vida.min_value = 0
		barra_vida.max_value = SaludMax
		barra_vida.value = SaludAhora

func take_damage(_damage: float) -> void:
	if barra_vida:
		barra_vida.value = SaludAhora
