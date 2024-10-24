extends Node3D


var tri_mutex = Mutex.new()
# tables from https://github.com/jbernardic/Godot-Smooth-Voxels/blob/main/Scripts/Terrain.gd
const TRIANGULATIONS = [
[],
[0, 8, 3],
[0, 1, 9],
[1, 8, 3, 9, 8, 1],
[1, 2, 10],
[0, 8, 3, 1, 2, 10],
[9, 2, 10, 0, 2, 9],
[2, 8, 3, 2, 10, 8, 10, 9, 8],
[3, 11, 2],
[0, 11, 2, 8, 11, 0],
[1, 9, 0, 2, 3, 11],
[1, 11, 2, 1, 9, 11, 9, 8, 11],
[3, 10, 1, 11, 10, 3],
[0, 10, 1, 0, 8, 10, 8, 11, 10],
[3, 9, 0, 3, 11, 9, 11, 10, 9],
[9, 8, 10, 10, 8, 11],
[4, 7, 8],
[4, 3, 0, 7, 3, 4],
[0, 1, 9, 8, 4, 7],
[4, 1, 9, 4, 7, 1, 7, 3, 1],
[1, 2, 10, 8, 4, 7],
[3, 4, 7, 3, 0, 4, 1, 2, 10],
[9, 2, 10, 9, 0, 2, 8, 4, 7],
[2, 10, 9, 2, 9, 7, 2, 7, 3, 7, 9, 4],
[8, 4, 7, 3, 11, 2],
[11, 4, 7, 11, 2, 4, 2, 0, 4],
[9, 0, 1, 8, 4, 7, 2, 3, 11],
[4, 7, 11, 9, 4, 11, 9, 11, 2, 9, 2, 1],
[3, 10, 1, 3, 11, 10, 7, 8, 4],
[1, 11, 10, 1, 4, 11, 1, 0, 4, 7, 11, 4],
[4, 7, 8, 9, 0, 11, 9, 11, 10, 11, 0, 3],
[4, 7, 11, 4, 11, 9, 9, 11, 10],
[9, 5, 4],
[9, 5, 4, 0, 8, 3],
[0, 5, 4, 1, 5, 0],
[8, 5, 4, 8, 3, 5, 3, 1, 5],
[1, 2, 10, 9, 5, 4],
[3, 0, 8, 1, 2, 10, 4, 9, 5],
[5, 2, 10, 5, 4, 2, 4, 0, 2],
[2, 10, 5, 3, 2, 5, 3, 5, 4, 3, 4, 8],
[9, 5, 4, 2, 3, 11],
[0, 11, 2, 0, 8, 11, 4, 9, 5],
[0, 5, 4, 0, 1, 5, 2, 3, 11],
[2, 1, 5, 2, 5, 8, 2, 8, 11, 4, 8, 5],
[10, 3, 11, 10, 1, 3, 9, 5, 4],
[4, 9, 5, 0, 8, 1, 8, 10, 1, 8, 11, 10],
[5, 4, 0, 5, 0, 11, 5, 11, 10, 11, 0, 3],
[5, 4, 8, 5, 8, 10, 10, 8, 11],
[9, 7, 8, 5, 7, 9],
[9, 3, 0, 9, 5, 3, 5, 7, 3],
[0, 7, 8, 0, 1, 7, 1, 5, 7],
[1, 5, 3, 3, 5, 7],
[9, 7, 8, 9, 5, 7, 10, 1, 2],
[10, 1, 2, 9, 5, 0, 5, 3, 0, 5, 7, 3],
[8, 0, 2, 8, 2, 5, 8, 5, 7, 10, 5, 2],
[2, 10, 5, 2, 5, 3, 3, 5, 7],
[7, 9, 5, 7, 8, 9, 3, 11, 2],
[9, 5, 7, 9, 7, 2, 9, 2, 0, 2, 7, 11],
[2, 3, 11, 0, 1, 8, 1, 7, 8, 1, 5, 7],
[11, 2, 1, 11, 1, 7, 7, 1, 5],
[9, 5, 8, 8, 5, 7, 10, 1, 3, 10, 3, 11],
[5, 7, 0, 5, 0, 9, 7, 11, 0, 1, 0, 10, 11, 10, 0],
[11, 10, 0, 11, 0, 3, 10, 5, 0, 8, 0, 7, 5, 7, 0],
[11, 10, 5, 7, 11, 5],
[10, 6, 5],
[0, 8, 3, 5, 10, 6],
[9, 0, 1, 5, 10, 6],
[1, 8, 3, 1, 9, 8, 5, 10, 6],
[1, 6, 5, 2, 6, 1],
[1, 6, 5, 1, 2, 6, 3, 0, 8],
[9, 6, 5, 9, 0, 6, 0, 2, 6],
[5, 9, 8, 5, 8, 2, 5, 2, 6, 3, 2, 8],
[2, 3, 11, 10, 6, 5],
[11, 0, 8, 11, 2, 0, 10, 6, 5],
[0, 1, 9, 2, 3, 11, 5, 10, 6],
[5, 10, 6, 1, 9, 2, 9, 11, 2, 9, 8, 11],
[6, 3, 11, 6, 5, 3, 5, 1, 3],
[0, 8, 11, 0, 11, 5, 0, 5, 1, 5, 11, 6],
[3, 11, 6, 0, 3, 6, 0, 6, 5, 0, 5, 9],
[6, 5, 9, 6, 9, 11, 11, 9, 8],
[5, 10, 6, 4, 7, 8],
[4, 3, 0, 4, 7, 3, 6, 5, 10],
[1, 9, 0, 5, 10, 6, 8, 4, 7],
[10, 6, 5, 1, 9, 7, 1, 7, 3, 7, 9, 4],
[6, 1, 2, 6, 5, 1, 4, 7, 8],
[1, 2, 5, 5, 2, 6, 3, 0, 4, 3, 4, 7],
[8, 4, 7, 9, 0, 5, 0, 6, 5, 0, 2, 6],
[7, 3, 9, 7, 9, 4, 3, 2, 9, 5, 9, 6, 2, 6, 9],
[3, 11, 2, 7, 8, 4, 10, 6, 5],
[5, 10, 6, 4, 7, 2, 4, 2, 0, 2, 7, 11],
[0, 1, 9, 4, 7, 8, 2, 3, 11, 5, 10, 6],
[9, 2, 1, 9, 11, 2, 9, 4, 11, 7, 11, 4, 5, 10, 6],
[8, 4, 7, 3, 11, 5, 3, 5, 1, 5, 11, 6],
[5, 1, 11, 5, 11, 6, 1, 0, 11, 7, 11, 4, 0, 4, 11],
[0, 5, 9, 0, 6, 5, 0, 3, 6, 11, 6, 3, 8, 4, 7],
[6, 5, 9, 6, 9, 11, 4, 7, 9, 7, 11, 9],
[10, 4, 9, 6, 4, 10],
[4, 10, 6, 4, 9, 10, 0, 8, 3],
[10, 0, 1, 10, 6, 0, 6, 4, 0],
[8, 3, 1, 8, 1, 6, 8, 6, 4, 6, 1, 10],
[1, 4, 9, 1, 2, 4, 2, 6, 4],
[3, 0, 8, 1, 2, 9, 2, 4, 9, 2, 6, 4],
[0, 2, 4, 4, 2, 6],
[8, 3, 2, 8, 2, 4, 4, 2, 6],
[10, 4, 9, 10, 6, 4, 11, 2, 3],
[0, 8, 2, 2, 8, 11, 4, 9, 10, 4, 10, 6],
[3, 11, 2, 0, 1, 6, 0, 6, 4, 6, 1, 10],
[6, 4, 1, 6, 1, 10, 4, 8, 1, 2, 1, 11, 8, 11, 1],
[9, 6, 4, 9, 3, 6, 9, 1, 3, 11, 6, 3],
[8, 11, 1, 8, 1, 0, 11, 6, 1, 9, 1, 4, 6, 4, 1],
[3, 11, 6, 3, 6, 0, 0, 6, 4],
[6, 4, 8, 11, 6, 8],
[7, 10, 6, 7, 8, 10, 8, 9, 10],
[0, 7, 3, 0, 10, 7, 0, 9, 10, 6, 7, 10],
[10, 6, 7, 1, 10, 7, 1, 7, 8, 1, 8, 0],
[10, 6, 7, 10, 7, 1, 1, 7, 3],
[1, 2, 6, 1, 6, 8, 1, 8, 9, 8, 6, 7],
[2, 6, 9, 2, 9, 1, 6, 7, 9, 0, 9, 3, 7, 3, 9],
[7, 8, 0, 7, 0, 6, 6, 0, 2],
[7, 3, 2, 6, 7, 2],
[2, 3, 11, 10, 6, 8, 10, 8, 9, 8, 6, 7],
[2, 0, 7, 2, 7, 11, 0, 9, 7, 6, 7, 10, 9, 10, 7],
[1, 8, 0, 1, 7, 8, 1, 10, 7, 6, 7, 10, 2, 3, 11],
[11, 2, 1, 11, 1, 7, 10, 6, 1, 6, 7, 1],
[8, 9, 6, 8, 6, 7, 9, 1, 6, 11, 6, 3, 1, 3, 6],
[0, 9, 1, 11, 6, 7],
[7, 8, 0, 7, 0, 6, 3, 11, 0, 11, 6, 0],
[7, 11, 6],
[7, 6, 11],
[3, 0, 8, 11, 7, 6],
[0, 1, 9, 11, 7, 6],
[8, 1, 9, 8, 3, 1, 11, 7, 6],
[10, 1, 2, 6, 11, 7],
[1, 2, 10, 3, 0, 8, 6, 11, 7],
[2, 9, 0, 2, 10, 9, 6, 11, 7],
[6, 11, 7, 2, 10, 3, 10, 8, 3, 10, 9, 8],
[7, 2, 3, 6, 2, 7],
[7, 0, 8, 7, 6, 0, 6, 2, 0],
[2, 7, 6, 2, 3, 7, 0, 1, 9],
[1, 6, 2, 1, 8, 6, 1, 9, 8, 8, 7, 6],
[10, 7, 6, 10, 1, 7, 1, 3, 7],
[10, 7, 6, 1, 7, 10, 1, 8, 7, 1, 0, 8],
[0, 3, 7, 0, 7, 10, 0, 10, 9, 6, 10, 7],
[7, 6, 10, 7, 10, 8, 8, 10, 9],
[6, 8, 4, 11, 8, 6],
[3, 6, 11, 3, 0, 6, 0, 4, 6],
[8, 6, 11, 8, 4, 6, 9, 0, 1],
[9, 4, 6, 9, 6, 3, 9, 3, 1, 11, 3, 6],
[6, 8, 4, 6, 11, 8, 2, 10, 1],
[1, 2, 10, 3, 0, 11, 0, 6, 11, 0, 4, 6],
[4, 11, 8, 4, 6, 11, 0, 2, 9, 2, 10, 9],
[10, 9, 3, 10, 3, 2, 9, 4, 3, 11, 3, 6, 4, 6, 3],
[8, 2, 3, 8, 4, 2, 4, 6, 2],
[0, 4, 2, 4, 6, 2],
[1, 9, 0, 2, 3, 4, 2, 4, 6, 4, 3, 8],
[1, 9, 4, 1, 4, 2, 2, 4, 6],
[8, 1, 3, 8, 6, 1, 8, 4, 6, 6, 10, 1],
[10, 1, 0, 10, 0, 6, 6, 0, 4],
[4, 6, 3, 4, 3, 8, 6, 10, 3, 0, 3, 9, 10, 9, 3],
[10, 9, 4, 6, 10, 4],
[4, 9, 5, 7, 6, 11],
[0, 8, 3, 4, 9, 5, 11, 7, 6],
[5, 0, 1, 5, 4, 0, 7, 6, 11],
[11, 7, 6, 8, 3, 4, 3, 5, 4, 3, 1, 5],
[9, 5, 4, 10, 1, 2, 7, 6, 11],
[6, 11, 7, 1, 2, 10, 0, 8, 3, 4, 9, 5],
[7, 6, 11, 5, 4, 10, 4, 2, 10, 4, 0, 2],
[3, 4, 8, 3, 5, 4, 3, 2, 5, 10, 5, 2, 11, 7, 6],
[7, 2, 3, 7, 6, 2, 5, 4, 9],
[9, 5, 4, 0, 8, 6, 0, 6, 2, 6, 8, 7],
[3, 6, 2, 3, 7, 6, 1, 5, 0, 5, 4, 0],
[6, 2, 8, 6, 8, 7, 2, 1, 8, 4, 8, 5, 1, 5, 8],
[9, 5, 4, 10, 1, 6, 1, 7, 6, 1, 3, 7],
[1, 6, 10, 1, 7, 6, 1, 0, 7, 8, 7, 0, 9, 5, 4],
[4, 0, 10, 4, 10, 5, 0, 3, 10, 6, 10, 7, 3, 7, 10],
[7, 6, 10, 7, 10, 8, 5, 4, 10, 4, 8, 10],
[6, 9, 5, 6, 11, 9, 11, 8, 9],
[3, 6, 11, 0, 6, 3, 0, 5, 6, 0, 9, 5],
[0, 11, 8, 0, 5, 11, 0, 1, 5, 5, 6, 11],
[6, 11, 3, 6, 3, 5, 5, 3, 1],
[1, 2, 10, 9, 5, 11, 9, 11, 8, 11, 5, 6],
[0, 11, 3, 0, 6, 11, 0, 9, 6, 5, 6, 9, 1, 2, 10],
[11, 8, 5, 11, 5, 6, 8, 0, 5, 10, 5, 2, 0, 2, 5],
[6, 11, 3, 6, 3, 5, 2, 10, 3, 10, 5, 3],
[5, 8, 9, 5, 2, 8, 5, 6, 2, 3, 8, 2],
[9, 5, 6, 9, 6, 0, 0, 6, 2],
[1, 5, 8, 1, 8, 0, 5, 6, 8, 3, 8, 2, 6, 2, 8],
[1, 5, 6, 2, 1, 6],
[1, 3, 6, 1, 6, 10, 3, 8, 6, 5, 6, 9, 8, 9, 6],
[10, 1, 0, 10, 0, 6, 9, 5, 0, 5, 6, 0],
[0, 3, 8, 5, 6, 10],
[10, 5, 6],
[11, 5, 10, 7, 5, 11],
[11, 5, 10, 11, 7, 5, 8, 3, 0],
[5, 11, 7, 5, 10, 11, 1, 9, 0],
[10, 7, 5, 10, 11, 7, 9, 8, 1, 8, 3, 1],
[11, 1, 2, 11, 7, 1, 7, 5, 1],
[0, 8, 3, 1, 2, 7, 1, 7, 5, 7, 2, 11],
[9, 7, 5, 9, 2, 7, 9, 0, 2, 2, 11, 7],
[7, 5, 2, 7, 2, 11, 5, 9, 2, 3, 2, 8, 9, 8, 2],
[2, 5, 10, 2, 3, 5, 3, 7, 5],
[8, 2, 0, 8, 5, 2, 8, 7, 5, 10, 2, 5],
[9, 0, 1, 5, 10, 3, 5, 3, 7, 3, 10, 2],
[9, 8, 2, 9, 2, 1, 8, 7, 2, 10, 2, 5, 7, 5, 2],
[1, 3, 5, 3, 7, 5],
[0, 8, 7, 0, 7, 1, 1, 7, 5],
[9, 0, 3, 9, 3, 5, 5, 3, 7],
[9, 8, 7, 5, 9, 7],
[5, 8, 4, 5, 10, 8, 10, 11, 8],
[5, 0, 4, 5, 11, 0, 5, 10, 11, 11, 3, 0],
[0, 1, 9, 8, 4, 10, 8, 10, 11, 10, 4, 5],
[10, 11, 4, 10, 4, 5, 11, 3, 4, 9, 4, 1, 3, 1, 4],
[2, 5, 1, 2, 8, 5, 2, 11, 8, 4, 5, 8],
[0, 4, 11, 0, 11, 3, 4, 5, 11, 2, 11, 1, 5, 1, 11],
[0, 2, 5, 0, 5, 9, 2, 11, 5, 4, 5, 8, 11, 8, 5],
[9, 4, 5, 2, 11, 3],
[2, 5, 10, 3, 5, 2, 3, 4, 5, 3, 8, 4],
[5, 10, 2, 5, 2, 4, 4, 2, 0],
[3, 10, 2, 3, 5, 10, 3, 8, 5, 4, 5, 8, 0, 1, 9],
[5, 10, 2, 5, 2, 4, 1, 9, 2, 9, 4, 2],
[8, 4, 5, 8, 5, 3, 3, 5, 1],
[0, 4, 5, 1, 0, 5],
[8, 4, 5, 8, 5, 3, 9, 0, 5, 0, 3, 5],
[9, 4, 5],
[4, 11, 7, 4, 9, 11, 9, 10, 11],
[0, 8, 3, 4, 9, 7, 9, 11, 7, 9, 10, 11],
[1, 10, 11, 1, 11, 4, 1, 4, 0, 7, 4, 11],
[3, 1, 4, 3, 4, 8, 1, 10, 4, 7, 4, 11, 10, 11, 4],
[4, 11, 7, 9, 11, 4, 9, 2, 11, 9, 1, 2],
[9, 7, 4, 9, 11, 7, 9, 1, 11, 2, 11, 1, 0, 8, 3],
[11, 7, 4, 11, 4, 2, 2, 4, 0],
[11, 7, 4, 11, 4, 2, 8, 3, 4, 3, 2, 4],
[2, 9, 10, 2, 7, 9, 2, 3, 7, 7, 4, 9],
[9, 10, 7, 9, 7, 4, 10, 2, 7, 8, 7, 0, 2, 0, 7],
[3, 7, 10, 3, 10, 2, 7, 4, 10, 1, 10, 0, 4, 0, 10],
[1, 10, 2, 8, 7, 4],
[4, 9, 1, 4, 1, 7, 7, 1, 3],
[4, 9, 1, 4, 1, 7, 0, 8, 1, 8, 7, 1],
[4, 0, 3, 7, 4, 3],
[4, 8, 7],
[9, 10, 8, 10, 11, 8],
[3, 0, 9, 3, 9, 11, 11, 9, 10],
[0, 1, 10, 0, 10, 8, 8, 10, 11],
[3, 1, 10, 11, 3, 10],
[1, 2, 11, 1, 11, 9, 9, 11, 8],
[3, 0, 9, 3, 9, 11, 1, 2, 9, 2, 11, 9],
[0, 2, 11, 8, 0, 11],
[3, 2, 11],
[2, 3, 8, 2, 8, 10, 10, 8, 9],
[9, 10, 2, 0, 9, 2],
[2, 3, 8, 2, 8, 10, 0, 1, 8, 1, 10, 8],
[1, 10, 2],
[1, 3, 8, 9, 1, 8],
[0, 9, 1],
[0, 3, 8],
[]
]

const POINTS := [
	Vector3i(0, 0, 0),
	Vector3i(0, 0, 1),
	Vector3i(1, 0, 1),
	Vector3i(1, 0, 0),
	Vector3i(0, 1, 0),
	Vector3i(0, 1, 1),
	Vector3i(1, 1, 1),
	Vector3i(1, 1, 0),
]

const EDGES := [
	Vector2i(0, 1),
	Vector2i(1, 2),
	Vector2i(2, 3),
	Vector2i(3, 0),
	Vector2i(4, 5),
	Vector2i(5, 6),
	Vector2i(6, 7),
	Vector2i(7, 4),
	Vector2i(0, 4),
	Vector2i(1, 5),
	Vector2i(2, 6),
	Vector2i(3, 7),
]

@export var CHUNK_SIZE := 30
@export var RENDER_DISTANCE := 3 # in chunks
const BLOCK_SIZE := 1.
const BALL_RADIUS := BLOCK_SIZE / 8.
const BALL_HEIGHT := 2 * BALL_RADIUS
var terrain_generator := TerrainGenerator.new()

var loaded_mutex = Mutex.new()
var loaded_chunks := {} # contains the currently shown chunks

var generated_mutex = Mutex.new()
var generated_chunks := {} # contains meshes for already computed chunks

@export var threshold := 0.1

var time := 0.

func tick():
	time = Time.get_ticks_usec()

func tock(message: String = "ticktock time"):
	var newtime := Time.get_ticks_usec()
	print(message + ": ", (newtime - time) / 1000000.0)

func march_meshInstance() -> MeshInstance3D:
	var marched := MeshInstance3D.new()
	marched.material_override = StandardMaterial3D.new()
	marched.material_override.set_cull_mode(1)
	marched.material_override.albedo_color = Color(1, 0.2, 0.2)
	return marched

func get_at(coord: Vector3i) -> float:
	return terrain_generator.get_at(coord)
	
func generate_balls(coord) -> void:
	tick()
	var base_sphere := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = BALL_RADIUS
	sphere_mesh.height = BALL_HEIGHT
	base_sphere.mesh = sphere_mesh
	for x in range(CHUNK_SIZE + 1):
		for y in range(CHUNK_SIZE + 1):
			for z in range(CHUNK_SIZE + 1):
				var val := get_at(Vector3i(x, y, z))
				if (val > threshold):
					var sphere := base_sphere.duplicate()
					sphere.material_override = StandardMaterial3D.new() # probably a pointer so can't be duplicated properly
					sphere.material_override.albedo_color = Color(val, val, val)
					
					sphere.position = Vector3(x, y ,z) * BLOCK_SIZE
					add_child(sphere)
	tock("time to generate balls")

# slow but cool
func march_animation(coord: Vector3i) -> void:
	loaded_mutex.lock()
	loaded_chunks[coord] = 1.
	loaded_mutex.unlock()
	
	tick()
	var box := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box.mesh = box_mesh
	add_child(box)
	for x in range(CHUNK_SIZE):
		await get_tree().create_timer(0.1).timeout # nice animation
		for y in range(CHUNK_SIZE):
			for z in range(CHUNK_SIZE):
				var pos := Vector3i(x, y, z) + coord * CHUNK_SIZE
				box.position = (Vector3(pos) + Vector3(0.5, 0.5, 0.5)) * BLOCK_SIZE
				
				var marched := MeshInstance3D.new()
				marched.material_override = StandardMaterial3D.new()
				marched.material_override.set_cull_mode(2) # CULL_DISABLED
				marched.material_override.albedo_color = Color(1, 0.2, 0.2)
				var st := SurfaceTool.new()
				
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				
				
				var pos1 := pos + Vector3i(0, 0, 1)
				var pos2 := pos + Vector3i(1, 0, 1)
				var pos3 := pos + Vector3i(1, 0, 0)
				var pos4 := pos + Vector3i(0, 1, 0)
				var pos5 := pos + Vector3i(0, 1, 1)
				var pos6 := pos + Vector3i(1, 1, 1)
				var pos7 := pos + Vector3i(1, 1, 0)
				
				# get triangulation index. Inspired from https://github.com/jbernardic/Godot-Smooth-Voxels/blob/main/Scripts/Terrain.gd
				var idx = 0b00000000
				idx |= int(get_at(pos) < threshold) << 0
				idx |= int(get_at(pos1) < threshold) << 1
				idx |= int(get_at(pos2) < threshold) << 2
				idx |= int(get_at(pos3) < threshold) << 3
				idx |= int(get_at(pos4) < threshold) << 4
				idx |= int(get_at(pos5) < threshold) << 5
				idx |= int(get_at(pos6) < threshold) << 6
				idx |= int(get_at(pos7) < threshold) << 7
				
				for edge in TRIANGULATIONS[idx]:
					var p0 = POINTS[EDGES[edge].x] + pos
					var p1 = POINTS[EDGES[edge].y] + pos
					st.set_smooth_group(-1) # flat shading
					st.add_vertex((p0 + p1) / 2.)

				# Commit to a mesh.
				st.generate_normals()
				var mesh := st.commit()
				
				marched.mesh = mesh
				add_child(marched)
	remove_child(box)
	
	tock("time to animate chunk")

func map(v: float, min: float, max: float, nmin: float, nmax: float):
	return (v - min) * (nmax - nmin) / (max - min) + nmin

# very unsure about what I am doing here
func interp_weight(a, b):
	return (threshold - b) / (a - b)
	#return (e2 + (t - b) * (e1 - e2)  / (a - b));

func march_chunk(coord: Vector3i, TRI) -> void:
	loaded_mutex.lock()
	loaded_chunks[coord] = 1.
	loaded_mutex.unlock()
	
	#var time = Time.get_ticks_usec()
	
	var marched = march_meshInstance()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			for z in range(CHUNK_SIZE):
				var pos := Vector3i(x, y, z) + coord * CHUNK_SIZE
				var pos1 := pos + Vector3i(0, 0, 1)
				var pos2 := pos + Vector3i(1, 0, 1)
				var pos3 := pos + Vector3i(1, 0, 0)
				var pos4 := pos + Vector3i(0, 1, 0)
				var pos5 := pos + Vector3i(0, 1, 1)
				var pos6 := pos + Vector3i(1, 1, 1)
				var pos7 := pos + Vector3i(1, 1, 0)
				
				# get triangulation index from https://github.com/jbernardic/Godot-Smooth-Voxels/blob/main/Scripts/Terrain.gd
				var idx = 0b00000000
				idx |= int(get_at(pos) < threshold) << 0
				idx |= int(get_at(pos1) < threshold) << 1
				idx |= int(get_at(pos2) < threshold) << 2
				idx |= int(get_at(pos3) < threshold) << 3
				idx |= int(get_at(pos4) < threshold) << 4
				idx |= int(get_at(pos5) < threshold) << 5
				idx |= int(get_at(pos6) < threshold) << 6
				idx |= int(get_at(pos7) < threshold) << 7
				
				for edge in TRI[idx]:
					var p0 = POINTS[EDGES[edge].x] + Vector3i(x, y, z)
					var p1 = POINTS[EDGES[edge].y] + Vector3i(x, y, z)
					
					var v0 = map(get_at(p0) - threshold, -1, threshold, 0, 1)
					var v1 = map(get_at(p1) - threshold, -1, threshold, 0, 1)
					
					var sum = v0 + v1
					var w0 = .5
					var w1 = .5
					if sum != 0:
						w0 = v0 / sum
						w1 = v1 / sum
					
					st.set_smooth_group(-1) # flat shading
					#st.add_vertex((p0 + p1) / 2.) # could do some linear interpolation here
					# interpolation breaks between the chunks :/
					st.add_vertex((p0 * w0 + p1 * w1))

	# Commit to a mesh.
	st.generate_normals()
	# hits generation performance and i couldn't measure any performance difference
	#st.index()
	#st.optimize_indices_for_cache()
	var mesh := st.commit()
	
	generated_mutex.lock()
	generated_chunks[coord] = mesh
	generated_mutex.unlock()
	
	marched.position = coord * CHUNK_SIZE
	marched.mesh = mesh
	
	# generate collison for mesh
	marched.create_trimesh_collision()
	# make sure collsision is detected on backside since collision orientation is wrong
	# kinda ugly way to access collision shape but is works
	if marched.get_child_count() > 0:
		marched.get_child(0).get_child(0).shape.set_backface_collision_enabled(true)
	
	#add_child(marched) deffered because of threading
	add_child.call_deferred(marched)
	
	#var newtime := Time.get_ticks_usec()
	#print("time to generate chunk: ", (newtime - time) / 1000000.0)

var chunk_thread: Thread

var worker_threads: Array

func noop():
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	chunk_thread = Thread.new()
	
	var num_threads = RENDER_DISTANCE ** 3
	# for some reason if this is 3, then 500% (5 cores) of the cpu is used
	var num_cores = OS.get_processor_count() / 2 - 3
	if (num_threads > num_cores):
		num_threads = num_cores
	
	print("using ", num_threads, " threads ")
	for x in range(num_threads):
		worker_threads.append(Thread.new())
		worker_threads[x].start(noop) # so that they all are "started"
	chunk_thread.start(noop) # same here
	
	
	#generate_balls(Vector3i(1,2,3))
	
	#march_chunk(Vector3i(1,2,3))
	#march_animation(Vector3i(0,1,0))

# assumes the coord are in generated_chunks!! (untested)
func load_chunk(coord: Vector3i) -> void:
	var marched := march_meshInstance()
	marched.position = Vector3(coord * CHUNK_SIZE)
	generated_mutex.lock()
	marched.mesh = generated_chunks[coord]
	generated_mutex.unlock()

func duplicate_2d(arr: Array):
	#tick()
	var ret: Array
	ret.resize(len(arr))
	for i in range(len(arr)):
		ret[i] = arr[i].duplicate()
		ret[i].reverse()
	#tock("time to duplicate") # very small
	return ret

func get_worker_thread() -> Thread:
	while true:
		for worker: Thread in worker_threads:
			if !worker.is_alive() && worker.is_started():
				worker.wait_to_finish()
				return worker
	return # just so that the compiler is happy about all paths returning

func show_chunk(coord: Vector3i) -> void:
	loaded_mutex.lock()
	var has_loaded = loaded_chunks.has(coord)
	loaded_mutex.unlock()
	if (!has_loaded):
		generated_mutex.lock()
		var has_generated = generated_chunks.has(coord)
		generated_mutex.unlock()
		if (has_generated):
			load_chunk(coord) # never used lol
		else:
			var thread := get_worker_thread()
			thread.start(march_chunk.bind(coord, duplicate_2d(TRIANGULATIONS)))

func show_chunks_around_player(player_chunk: Vector3i) -> void:
	for x in range(RENDER_DISTANCE):
		for y in range(RENDER_DISTANCE):
			for z in range(RENDER_DISTANCE):
					var chunk_coord := player_chunk + Vector3i(x, y, z) - Vector3i(RENDER_DISTANCE / 2, RENDER_DISTANCE / 2, RENDER_DISTANCE / 2)
					show_chunk(chunk_coord)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if (chunk_thread.is_started() && !chunk_thread.is_alive()):
		chunk_thread.wait_to_finish()
		# big oopsie if there is more than 1 player
		for player: Node3D in get_tree().get_nodes_in_group("player"):
			var player_chunk := Vector3i(floor(player.position.x / CHUNK_SIZE), floor(player.position.y / CHUNK_SIZE), floor(player.position.z / CHUNK_SIZE))
			chunk_thread.start(show_chunks_around_player.bind(player_chunk))
