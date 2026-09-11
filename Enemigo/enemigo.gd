extends CharacterBody3D
var salud = 0
var velMov = 1

var damage = 10
var attackRate = 1
var attackDist = 2

var puntosQueDa = 10

#componentes

@onready var player : Node = get_node("/root/World/CharacterBody3D")
@onready var timer : Timer = get_node("Timer")

func _ready() -> void:
	timer.set_wait_time(attackRate)
	timer.start()
func _physics_process(_delta: float) -> void:
	var dir = (player.position - position).normalized()
	dir.y = 0
	
	velocity.x = dir.x * velMov
	velocity.z = dir.z * velMov
	
	move_and_slide()
func take_damage(amount: float) -> void:
	salud -= amount
	if salud <= 0:
		morirse() # o tu lógica de muerte
	
	if salud == 0:
		morirse()
func morirse():
	player.add_score(puntosQueDa)
	queue_free()
func atacar():
	player.take_damage(damage)
func _on_timer_timeout() -> void:
	if position.distance_to(player.position) <= attackDist:
		atacar()
