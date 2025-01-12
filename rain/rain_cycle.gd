extends GPUParticles3D

@export var transition_duration: float = 10.0
var timer: float = 0.0
var state: int = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	timer += delta
	
	if timer >= transition_duration:
		timer = 0.0
		
		state += 1
		if state == 4:
			state = 0
			
	if state == 0:
		amount_ratio = 0
	elif state == 1:
		amount_ratio = timer/transition_duration
	elif state == 2: 
		amount_ratio = 1
	elif state == 3:
		amount_ratio = 1-timer/transition_duration
