extends Node3D

@export var CHUNK_SIZE := 32 # number of cubes in a chunk 
@export var RENDER_DISTANCE := 8 # in chunks
@export var VERTICAL_RENDER_DISTANCE := 4
@export var threshold := 0.1

var marcher: Marcher = GpuMarcher.new(self, CHUNK_SIZE, threshold)

var chunk_thread: Thread

var worker_threads: Array

func noop():
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	chunk_thread = Thread.new()
	marcher.init()
	
	var num_threads = 1 #RENDER_DISTANCE ** 4
	# for some reason if this is 3, then 500% (5 cores) of the cpu is used
	var num_cores = OS.get_processor_count() / 2 - 3
	if (num_cores > num_threads):
		num_threads = num_cores
	
	print("using ", num_threads, " threads ")
	for x in range(num_threads):
		worker_threads.append(Thread.new())
		worker_threads[x].start(noop) # so that they all are "started"
	chunk_thread.start(noop) # same here


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
	return null# just so that the compiler is happy about all paths returning

@onready var chunk_time_label := $chunk_time

func show_chunk(coord: Vector3i) -> void:
	var thread := get_worker_thread()
	if thread == null:
		return
	var start := Time.get_ticks_usec()
	thread.start(marcher.march_chunk.bind(coord, duplicate_2d(TRIANGULATIONS)))
	var end := Time.get_ticks_usec()
	chunk_time_label.set_text.call_deferred("chunk generation time: " + str((end - start) / 1000000.0))

# returns the indicies of a cube around the player
func get_cube_index(radius: int, vertical_radius: int):
	if radius == 0:
		return [Vector3i(0,0,0)]
	var indexes := []
	# side 1
	for height in range(-vertical_radius, vertical_radius + 1):
		for x in range(-radius, radius):
			indexes.append(Vector3i(x, height, radius))
	# side 2
	for height in range(-vertical_radius, vertical_radius + 1):
		for x in range(-radius + 1, radius + 1):
			indexes.append(Vector3i(x, height, -radius))
	# side 3
	for height in range(-vertical_radius, vertical_radius + 1):
		for z in range(-radius + 1, radius + 1):
			indexes.append(Vector3i(radius, height, z))
	# side 4
	for height in range(-vertical_radius, vertical_radius + 1):
		for z in range(-radius, radius):
			indexes.append(Vector3i(-radius, height, z))
	# top
	for x in range(-radius + 1, radius):
		for z in range(-radius + 1, radius):
			indexes.append(Vector3i(x, vertical_radius, z))
	# bottom
	for x in range(-radius + 1, radius):
		for z in range(-radius + 1, radius):
			indexes.append(Vector3i(x, -vertical_radius, z))
	
	return indexes

var global_player_chunk := Vector3i(0,0,0)
var global_player_chunk_mutex := Mutex.new()

func show_chunks_around_player() -> void:
	global_player_chunk_mutex.lock()
	var player_chunk := global_player_chunk
	global_player_chunk_mutex.unlock()
	for offset in range(RENDER_DISTANCE):
		global_player_chunk_mutex.lock()
		var global_chunk = Vector3i(global_player_chunk)
		global_player_chunk_mutex.unlock()
		# player has moved, restart
		if(player_chunk != global_chunk):
			print("player moved chunk")
			return
		
		var positions = get_cube_index(offset, min(offset, VERTICAL_RENDER_DISTANCE))
		for pos: Vector3i in positions:
			var chunk_coord := player_chunk + pos
			marcher.loaded_mutex.lock()
			var has_loaded = marcher.loaded_chunks.has(chunk_coord)
			marcher.loaded_mutex.unlock()
			if has_loaded:
				continue
			#print("Player chunk: " , player_chunk , " Current chunk: " , chunk_coord , " x,y,z: " ,dx ,",", dy ,",", dz)
			show_chunk(chunk_coord)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	for player: Node3D in get_tree().get_nodes_in_group("player"):
		global_player_chunk_mutex.lock()
		global_player_chunk = Vector3i(floor(player.position.x / CHUNK_SIZE), floor(player.position.y / CHUNK_SIZE), floor(player.position.z / CHUNK_SIZE))
		global_player_chunk_mutex.unlock()
	if (chunk_thread.is_started() && !chunk_thread.is_alive()):
		chunk_thread.wait_to_finish()
		# big oopsie if there is more than 1 player
		chunk_thread.start(show_chunks_around_player)

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
