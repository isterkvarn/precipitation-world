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

@export var CHUNK_SIZE := 32
@export var RENDER_DISTANCE :=  5# in chunks

const BLOCK_SIZE := 1.
const BALL_RADIUS := BLOCK_SIZE / 8.
const BALL_HEIGHT := 2 * BALL_RADIUS

var terrain_generator := TerrainGenerator.new()

var loaded_mutex = Mutex.new()
var loaded_chunks := {} # contains the currently shown chunks

var generated_mutex = Mutex.new()
var generated_chunks := {} # contains meshes for already computed chunks

var rd : RenderingDevice
var shader : RID
var noise_buffer : RID
var vertex_buffer : RID
var counter_buffer : RID
var buffer_set : RID
var size_buffer : RID
var threshold_buffer : RID
var pipeline : RID
var dead_beef_arr = PackedFloat32Array()

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
	marched.material_override.set_cull_mode(0)
	marched.material_override.albedo_color = Color(1, 0.2, 0.2)
	return marched

func get_at(coord: Vector3i) -> float:
	return terrain_generator.get_at(coord)
	
func terrain_get_at(terrain, coord: Vector3i, size) -> float:
	return terrain[coord.z + coord.y * size + coord.x * (size ** 2)]
	
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
	var time = Time.get_ticks_usec()
	
	var terrain_noise = terrain_generator.get_terrain_3d(CHUNK_SIZE+1, CHUNK_SIZE+1, CHUNK_SIZE+1, coord*CHUNK_SIZE)
	var newtime3 := Time.get_ticks_usec()
	
	var marched = march_meshInstance()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			for z in range(CHUNK_SIZE):
				var pos := Vector3i(x, y, z) #+ coord * CHUNK_SIZE
				var pos1 := pos + Vector3i(0, 0, 1)
				var pos2 := pos + Vector3i(1, 0, 1)
				var pos3 := pos + Vector3i(1, 0, 0)
				var pos4 := pos + Vector3i(0, 1, 0)
				var pos5 := pos + Vector3i(0, 1, 1)
				var pos6 := pos + Vector3i(1, 1, 1)
				var pos7 := pos + Vector3i(1, 1, 0)
				
				# get triangulation index from https://github.com/jbernardic/Godot-Smooth-Voxels/blob/main/Scripts/Terrain.gd
				var idx = 0b00000000
				idx |= int(terrain_get_at(terrain_noise, pos, CHUNK_SIZE+1) < threshold) << 0
				idx |= int(terrain_get_at(terrain_noise, pos1, CHUNK_SIZE+1) < threshold) << 1
				idx |= int(terrain_get_at(terrain_noise, pos2, CHUNK_SIZE+1) < threshold) << 2
				idx |= int(terrain_get_at(terrain_noise, pos3, CHUNK_SIZE+1) < threshold) << 3
				idx |= int(terrain_get_at(terrain_noise, pos4, CHUNK_SIZE+1) < threshold) << 4
				idx |= int(terrain_get_at(terrain_noise, pos5, CHUNK_SIZE+1) < threshold) << 5
				idx |= int(terrain_get_at(terrain_noise, pos6, CHUNK_SIZE+1) < threshold) << 6
				idx |= int(terrain_get_at(terrain_noise, pos7, CHUNK_SIZE+1) < threshold) << 7
				
				for edge in TRI[idx]:
					var p0 = POINTS[EDGES[edge].x] + Vector3i(x, y, z)
					var p1 = POINTS[EDGES[edge].y] + Vector3i(x, y, z)
					
					var v0 = map(terrain_get_at(terrain_noise, p0, CHUNK_SIZE+1) - threshold, -1, threshold, 0, 1)
					var v1 = map(terrain_get_at(terrain_noise, p1, CHUNK_SIZE+1) - threshold, -1, threshold, 0, 1)
					
					var sum = v0 + v1
					var w0 = .5
					var w1 = .5
					if sum != 0:
						w0 = v0 / sum
						w1 = v1 / sum
					
					st.set_smooth_group(0) # smooth shading
					#st.add_vertex((p0 + p1) / 2.) # could do some linear interpolation here
					# interpolation breaks between the chunks :/
					st.add_vertex((p0 * w0 + p1 * w1))

	var newtime1 := Time.get_ticks_usec()
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
	if mesh.get_surface_count() > 0:
		marched.create_trimesh_collision()
	# make sure collsision is detected on backside since collision orientation is wrong
	# kinda ugly way to access collision shape but is works
	if marched.get_child_count() > 0:
		marched.get_node("_col").get_node("CollisionShape3D").shape.set_backface_collision_enabled(true)
	
	#add_child(marched) deffered because of threading
	add_child.call_deferred(marched)
	
	var newtime2 := Time.get_ticks_usec()
	print("time to generate terrain: ", (newtime3 - time) / 1000000.0)
	print("time to generate vertex: ", (newtime1 - newtime3) / 1000000.0)
	print("time to generate collision: ", (newtime2 - newtime1) / 1000000.0)
	
	
func march_gpu_init() -> void:
	# Create a local rendering device for compute shaders
	rd = RenderingServer.create_local_rendering_device()
	
	# Load GLSL shader
	var shader_file := load("res://shaders/cube_march.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	
	# Create buffer for noise
	noise_buffer = rd.storage_buffer_create(32*(CHUNK_SIZE+1)**3)
	var n_uniform := RDUniform.new()
	n_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	n_uniform.binding = 0 # this needs to match the "binding" in our shader file
	n_uniform.add_id(noise_buffer)
	
	# Create buffer for counter
	var counter = [0]
	var counter_bytes = PackedInt32Array(counter).to_byte_array()
	counter_buffer = rd.storage_buffer_create(counter_bytes.size(), counter_bytes)
	var c_uniform = RDUniform.new()
	c_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	c_uniform.binding = 1
	c_uniform.add_id(counter_buffer)
	
	# Create buffer from output vertices
	# 32 size of float, 3 floats per vertex, max 15 vertex per cube, chunk size pow 3 cubes
	for i in range(3*15*(CHUNK_SIZE**3)):
		dead_beef_arr.append(-1.0)
		
	dead_beef_arr = dead_beef_arr.to_byte_array()
	vertex_buffer = rd.storage_buffer_create(dead_beef_arr.size(), dead_beef_arr)
	var v_uniform := RDUniform.new()
	v_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	v_uniform.binding = 2 # this needs to match the "binding" in our shader file
	v_uniform.add_id(vertex_buffer)
	
	# create buffer for chunk size
	var chunk_size = [CHUNK_SIZE]
	var size_bytes = PackedInt32Array(chunk_size).to_byte_array()
	size_buffer = rd.storage_buffer_create(size_bytes.size(), size_bytes)
	var size_uniform = RDUniform.new()
	size_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	size_uniform.binding = 3
	size_uniform.add_id(size_buffer)
	
	# create buffer for threshold
	var threshold_array = [threshold]
	var threshold_bytes = PackedFloat32Array(threshold_array).to_byte_array()
	threshold_buffer = rd.storage_buffer_create(size_bytes.size(), size_bytes)
	var threshold_uniform = RDUniform.new()
	threshold_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	threshold_uniform.binding = 4
	threshold_uniform.add_id(threshold_buffer)
	
	var buffers = [n_uniform, c_uniform, v_uniform, size_uniform, threshold_uniform]
	buffer_set = rd.uniform_set_create(buffers, shader, 0)
	pipeline = rd.compute_pipeline_create(shader)
	print(buffer_set)
	print("done init for shader")


func march_chunk_gpu(coord: Vector3i, TRI) -> void:
	loaded_mutex.lock()
	loaded_chunks[coord] = 1.
	loaded_mutex.unlock()
	
	var time = Time.get_ticks_usec()
	
	# Update with chunk noise
	var terrain_noise = terrain_generator.get_terrain_3d(CHUNK_SIZE+1, CHUNK_SIZE+1, CHUNK_SIZE+1, coord*CHUNK_SIZE)
	var terrain_bytes = PackedFloat32Array(terrain_noise).to_byte_array()
	rd.buffer_update(noise_buffer, 0, terrain_bytes.size(), terrain_bytes)
	
	# Reset counter
	var counter = [0]
	var counter_bytes = PackedFloat32Array(counter).to_byte_array()
	rd.buffer_update(counter_buffer, 0 ,counter_bytes.size(), counter_bytes)
	
	# Clear output buffer
	rd.buffer_update(vertex_buffer, 0, dead_beef_arr.size(), dead_beef_arr)
	
	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, buffer_set, 0)
	rd.compute_list_dispatch(compute_list, 4, 4, 4)
	rd.compute_list_end()
	
	# GENERATE VERTEIES ON GPU
	rd.submit()
	rd.sync()
	
	var newtime1 := Time.get_ticks_usec()
	
	var ver_bytes = rd.buffer_get_data(vertex_buffer)
	var vertex_output = ver_bytes.to_float32_array()
	
	counter_bytes = rd.buffer_get_data(counter_buffer)
	var count_output = counter_bytes.to_int32_array()

	#print(rd.buffer_get_data(noise_buffer).to_float32_array())
	
	var marched = march_meshInstance()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for ver_index in range(0, vertex_output.size(), 9):
		
		if vertex_output[ver_index] == -1.0:
			continue
			
		var vertex1 = Vector3(vertex_output[ver_index], 
							vertex_output[ver_index+1],
							vertex_output[ver_index+2])

		var vertex2 = Vector3(vertex_output[ver_index+3], 
							  vertex_output[ver_index+4],
							  vertex_output[ver_index+5])
		var vertex3 = Vector3(vertex_output[ver_index+6], 
							  vertex_output[ver_index+7],
							  vertex_output[ver_index+8])
								
			##if vertex1.distance_to(vertex2) > 2.0 or vertex1.distance_to(vertex3) > 2.0 or vertex2.distance_to(vertex3) > 2.0:
			##
			##
			##print("cube_index :", cube_index, " polygon :", vertex1, ", ", vertex2, ", ", vertex3)
			##
		st.add_vertex(vertex1)
		st.add_vertex(vertex2)
		st.add_vertex(vertex3)
		
	
	var newtime2 := Time.get_ticks_usec()
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
	if mesh.get_surface_count() > 0:
		marched.create_trimesh_collision()
	# make sure collsision is detected on backside since collision orientation is wrong
	# kinda ugly way to access collision shape but is works
	if marched.get_child_count() > 0:
		marched.get_node("_col").get_node("CollisionShape3D").shape.set_backface_collision_enabled(true)
	
	#add_child(marched) deffered because of threading
	add_child.call_deferred(marched)
	
	var newtime3 := Time.get_ticks_usec()
	print("time to generate vertex gpu: ", (newtime1 - time) / 1000000.0)
	print("time to build polygons  cpu: ", (newtime2 - newtime1) / 1000000.0)
	print("Total time ", (newtime3 - time) / 1000000.0)

var chunk_thread: Thread

var worker_threads: Array

func noop():
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	chunk_thread = Thread.new()
	march_gpu_init()
	
	var num_threads = 1 #RENDER_DISTANCE ** 4
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
			thread.start(march_chunk_gpu.bind(coord, duplicate_2d(TRIANGULATIONS)))

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
