extends GPUParticles3D

@export var transition_duration: float = 10.0
var timer: float = 0.0
var state: int = 0
var noisemax: float = 0.01
var noisemin: float = 0.003
var environment 
var sky_material 
var cloud_texture
var cloud_texture2 
var noise 
var frequency 


func _ready():
	
	var environment = get_node("../../WorldEnvironment").environment
	if environment and environment.sky:
		var sky_material = environment.sky.sky_material
		if sky_material and sky_material is ShaderMaterial:
			var cloud_texture = sky_material.get_shader_parameter("cloud_texture")
			if cloud_texture and cloud_texture is NoiseTexture2D:
				var noise = cloud_texture.noise
				if not noise:
					print("Noise = NULL")
			else:
				print("Texture = NULL")
		else:
			print("Shader = NULL")
				#var noise2 = cloud_texture2.noise
		
	#var frequency2 = noise2.frequency
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	timer += delta
	var sky_material = get_node("../../WorldEnvironment").environment.sky.sky_material
	var cloud_texture_test = sky_material.get_shader_parameter("cloud_texture")
	var light_mult = sky_material.get_shader_parameter("light_multiplier")
	var noise = cloud_texture_test.noise
	var temp_light
	if timer >= transition_duration:
		timer = 0.0
		
		state += 1
		if state == 4:
			state = 0
		
		
	if state == 0:
		if temp_light != 1:
			sky_material.set_shader_parameter("light_multiplier", 1)
			temp_light = 1
		noise.frequency = noisemax
		amount_ratio = 0
		
	elif state == 1:
		if (timer >= 3.2 and timer <= 3.3) or (timer >= 6.5 and timer <= 6.6):
			sky_material.set_shader_parameter("light_multiplier", min(1.0, 1.2-timer/transition_duration))
			temp_light = min(1.0, 1.2-timer/transition_duration)
		noise.frequency = (noisemax+noisemin)/2
		amount_ratio = timer/transition_duration
		
	elif state == 2: 
		if temp_light != 0.2:
			sky_material.set_shader_parameter("light_multiplier", 0.2)
			temp_light = 0.2
		noise.frequency = noisemin
		amount_ratio = 1
	elif state == 3:
		if (timer >= 3.2 and timer <= 3.3) or (timer >= 6.5 and timer <= 6.6):
			sky_material.set_shader_parameter("light_multiplier", min(1.0, 0.2+timer/transition_duration))
			temp_light = min(1.0, 0.2+timer/transition_duration)
		amount_ratio = 1-timer/transition_duration
		
	print(get_node("../../WorldEnvironment").environment.sky.sky_material.get_shader_parameter("cloud_texture").noise.frequency)
