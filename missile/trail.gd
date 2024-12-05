extends Node3D


func start_death_timer():
	$Timer.wait_time = $Trail.lifetime
	$Timer.start()
	$Trail.emitting = false

func _on_timer_timeout() -> void:
	queue_free()
