extends Area3D

var speed : float = 30.0
var damage : int = 1

func _process(delta: float) -> void:
	position += global_transform.basis.z * speed * delta
	


func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		destroy()
		
	pass # Replace with function body.
func destroy():
	queue_free()

func _on_destroy_timer_timeout() -> void:
	destroy()
	pass # Replace with function body.
