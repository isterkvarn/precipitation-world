class_name TerrainGenerator

var noise_ground := FastNoiseLite.new()
var noise_spike := FastNoiseLite.new()
var noise_caves := FastNoiseLite.new()
var noise_boulder := FastNoiseLite.new()

func _init() -> void:
	noise_ground.frequency = 0.008
	noise_ground.set_noise_type(FastNoiseLite.TYPE_PERLIN)
	
	noise_spike.frequency = 0.010
	noise_spike.set_noise_type(FastNoiseLite.TYPE_PERLIN)
	
	noise_caves.frequency = 0.02
	noise_caves.set_noise_type(FastNoiseLite.TYPE_PERLIN)
	
	noise_boulder.frequency = 0.04
	noise_boulder.set_noise_type(FastNoiseLite.TYPE_PERLIN)

func get_at(coord) -> float:
	
	var noise = 0.0
	
	noise += 6 * max(noise_caves.get_noise_3dv(coord), 0.0)
	
	var ground = clampf(coord.y + 63 * noise_ground.get_noise_2dv(Vector2i(coord.x, coord.z)), -1.0, 1.0)
	noise += ground
	
	var spike = noise_spike.get_noise_2dv(Vector2i(coord.x, coord.z))
	if spike < -0.37:
		noise += clampf(coord.y + 800*(spike+0.37), -8.0, 0.0)
	
	if ground > 0.1: # hard coding threshold from terrian_cpu here
		noise += clampf(4 - 0.5 * coord.y, -1.0, 5.0) * noise_boulder.get_noise_3dv(coord)
		
	noise = clampf(noise, -1.0, 1.0)
	return noise

func get_terrain_3d(width: int, height: int, depth: int, position: Vector3i):
	var noise_3d := []
	for x in range(width):
		for y in range(height):
			for z in range(depth):
				noise_3d.append(get_at(position + Vector3i(x, y, z)))
	return noise_3d
	
