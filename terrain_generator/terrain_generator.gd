class_name TerrainGenerator

var noise_ground := FastNoiseLite.new()
var noise_caves := FastNoiseLite.new()
var noise_boulder := FastNoiseLite.new()

@export var GROUND_COLOR := Vector3(0,1,0)
@export var CAVE_COLOR := Vector3(1,0,0)
@export var BOULDER_COLOR := Vector3(0,0,1)
@export var SNOW_COLOR := Vector3(1,1,1)
@export var HIGH := 40

var threshold

func _init(thrsold) -> void:
	threshold = thrsold
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
	
	if ground > threshold:
		noise += clampf(5 - 0.5 * coord.y, -1.0, 5.0) * noise_boulder.get_noise_3dv(coord)
		
	noise = clampf(noise, -1.0, 1.0)
	return noise

func color_at(coord) -> Color:
	var color := Vector3(0,0,0)
	
	color += 5 * max(noise_caves.get_noise_3dv(coord), 0.0) * CAVE_COLOR
	
	var ground = clampf(coord.y - 1 + 140 * noise_ground.get_noise_2dv(Vector2i(coord.x, coord.z)), -1.0, 1.0)
	var ground_over = clampf(coord.y + 1 + 140 * noise_ground.get_noise_2dv(Vector2i(coord.x, coord.z)), -1.0, 1.0)
	if ground < threshold and ground_over >= threshold:
		#color += GROUND_COLOR * ground
		color += GROUND_COLOR * ((HIGH - coord.y) / 40)
		if coord.y >= HIGH:
			color += SNOW_COLOR * ((coord.y - HIGH)  / 10)
	#color += max(-ground, -threshold) * GROUND_COLOR
	
	if ground > threshold:
		var boulder = clampf(5 - 0.5 * coord.y, -1.0, 5.0) * noise_boulder.get_noise_3dv(coord)
		color += max(-boulder, 0) * BOULDER_COLOR
	#color = color.normalized()
	
	#print(color)
	return Color(color.x, color.y, color.z)

func get_terrain_3d(width: int, height: int, depth: int, position: Vector3i):
	var noise_3d := []
	for x in range(width):
		for y in range(height):
			for z in range(depth):
				noise_3d.append(get_at(position + Vector3i(x, y, z)))
	return noise_3d
	
