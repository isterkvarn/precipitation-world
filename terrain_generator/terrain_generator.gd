class_name TerrainGenerator

var noise_ground := FastNoiseLite.new()
var noise_caves := FastNoiseLite.new()
var noise_boulder := FastNoiseLite.new()

func _init() -> void:
	noise_ground.frequency = 0.003
	noise_ground.set_noise_type(FastNoiseLite.TYPE_PERLIN)
	
	noise_caves.frequency = 0.01
	noise_caves.set_noise_type(FastNoiseLite.TYPE_PERLIN)
	
	noise_boulder.frequency = 0.02
	noise_boulder.set_noise_type(FastNoiseLite.TYPE_PERLIN)

func get_at(coord) -> float:
	
	var noise = 0.0
	
	noise += 5 * max(noise_caves.get_noise_3dv(coord), 0.0)
	
	var ground = clampf(coord.y + 140 * noise_ground.get_noise_2dv(Vector2i(coord.x, coord.z)), -1.0, 1.0)
	noise += ground
	
	if ground > 0.1: # hard coding threshold from terrian_cpu here
		noise += clampf(5 - 0.5 * coord.y, -1.0, 5.0) * noise_boulder.get_noise_3dv(coord)
		
	noise = clampf(noise, -1.0, 1.0)
	return noise
