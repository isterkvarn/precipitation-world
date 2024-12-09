class_name Marcher extends Node
### this is an abstract class and shouldn't be instantiated 

const BLOCK_SIZE := 1.
const BALL_RADIUS := BLOCK_SIZE / 8.
const BALL_HEIGHT := 2 * BALL_RADIUS

var CHUNK_SIZE: int
var threshold: int

var terrain_generator := TerrainGenerator.new()

var loaded_mutex = Mutex.new()
var loaded_chunks := {} # contains the currently shown chunks

var scene: Node3D
var mat: StandardMaterial3D
# constructor
func _init(s, chunk_size, thrshold):
	scene = s
	CHUNK_SIZE = chunk_size
	threshold = thrshold
	mat = load("res://marching_cubes/terrain_material.tres")

func terrain_get_at(terrain, coord: Vector3i, size) -> float:
	return terrain[coord.z + coord.y * size + coord.x * (size ** 2)]

func get_at(coord: Vector3i) -> float:
	return terrain_generator.get_at(coord)

func march_meshInstance() -> MeshInstance3D:
	var marched := MeshInstance3D.new()
	marched.material_override = mat
	marched.material_override.set_cull_mode(0)
	marched.material_override.albedo_color = Color(1, 0.2, 0.2)
	marched.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	#marched.material_override.albedo_color = Color(0.6, 0.4, 0.4)
	return marched

func init() -> void:
	print("init should never be called but be implemented by the extending class")

# returns compute time and lod
func march_chunk(coord: Vector3i, lod: int, TRI, edited) -> Array:
	print("march_chunk should never be called but be implemented by the extending class")
	return []
