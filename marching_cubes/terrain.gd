extends Node3D

@export var CHUNK_SIZE := 32 # number of cubes in a chunk 
@export var RENDER_DISTANCE := 6 # in chunks
@export var VERTICAL_RENDER_DISTANCE := 6
@export var LOD2_DISTANCE := 10
@export var LOD4_DISTANCE := 18
@export var LOD8_DISTANCE := 32
@export var threshold := 0.1

var marcher: Marcher = GpuMarcher.new(self, CHUNK_SIZE, threshold)

var chunk_thread: Thread

var worker_threads: Array

var edited_chunks: Dictionary

var chunks: Dictionary

@onready var missile_scene = preload("res://missile/missile.tscn")

func noop():
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	chunk_thread = Thread.new()
	marcher.init()
	
	var num_threads = 1 #RENDER_DISTANCE ** 4
	# for some reason if this is 3, then 500% (5 cores) of the cpu is used
	var num_cores = OS.get_processor_count() / 2 - 2
	if (num_cores > num_threads):
		num_threads = num_cores
	
	print("using ", num_threads, " threads ")
	for x in range(num_threads):
		worker_threads.append(Thread.new())
		#worker_threads[x].start(noop) # so that they all are "started"
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

@onready var chunk_time_label := $chunk_time

func get_worker_thread() -> Thread:
	for worker: Thread in worker_threads:
		if (!worker.is_alive() && worker.is_started()):
			var data = worker.wait_to_finish()
			var time = data[0]
			var lod = data[1]
			chunk_time_label.set_text.call_deferred("chunk time: " + str(time) + "\nlod: " + str(lod))
			
			return worker
		elif !worker.is_started():
			return worker
	return null


func show_chunk(coord: Vector3i, lod: int, thread: Thread) -> bool:
	var edited = []
	if edited_chunks.has(coord):
		edited = edited_chunks[coord]
	thread.start(marcher.march_chunk.bind(coord, lod, duplicate_2d(TRIANGULATIONS), edited))
	return true

func replace_chunk(chunk_name: String, chunk: MeshInstance3D):
	#chunk.material_override.transparency = 0
	if chunk_name in chunks:
		chunks[chunk_name].queue_free()
	chunks[chunk_name] = chunk

func update_chunk(chunk_name: String, chunk: MeshInstance3D):
	# Remove chunk if it already exit
	add_child(chunk)
	replace_chunk(chunk_name, chunk)
	
	#var tween := create_tween()
	#chunk.material_override.transparency = 3
	#tween.tween_property(chunk.material_override, "albedo_color:a", 1., 3.3).from(0.)
	#tween.tween_property(chunk, "position", chunk.position, 1.).from(Vector3.ZERO)
	#tween.tween_callback(replace_chunk.bind(chunk_name, chunk))


func show_chunks_circle(offset: int, vertical_offset: int, player_chunk: Vector3i, lod: int, thread: Thread):
	for dx in range(-offset, offset+1):
		for dz in range(-offset, offset+1):
			for dy in range(-vertical_offset, vertical_offset+1):
				var chunk_coord := player_chunk + Vector3i(dx, dy, dz)
				marcher.loaded_mutex.lock()
				var has_loaded = marcher.loaded_chunks.get(chunk_coord)
				marcher.loaded_mutex.unlock()
				if has_loaded != null && has_loaded <= lod:
					continue

				#print("Player chunk: " , player_chunk , " Current chunk: " , chunk_coord , " x,y,z: " ,dx ,",", dy ,",", dz)
				#print("rendering with ", lod, " was ", has_loaded)
				show_chunk(chunk_coord, lod, thread)
				return true
	return false

func show_chunks_around_player(player_chunk: Vector3i) -> void:
	var render_offset = floor(RENDER_DISTANCE/2)
	var lod2_offset = floor(LOD2_DISTANCE/2)
	var lod4_offset = floor(LOD4_DISTANCE/2)
	var lod8_offset = floor(LOD8_DISTANCE/2)
	var max_offset = max(render_offset, lod2_offset, lod4_offset, lod8_offset)
	var vertical_offset = floor(VERTICAL_RENDER_DISTANCE/2)
	
	var thread := get_worker_thread()
	if thread == null:
		return
	
	for offset in range(0, max_offset + 1):
		if offset >= lod4_offset && offset <= lod8_offset:
			if show_chunks_circle(offset, vertical_offset, player_chunk, 8, thread):
				return
		if offset >= lod2_offset && offset <= lod4_offset:
			if show_chunks_circle(offset, vertical_offset, player_chunk, 4, thread):
				return
		if offset >= render_offset && offset <= lod2_offset:
			if show_chunks_circle(offset, vertical_offset, player_chunk, 2, thread):
				return
		if offset <= render_offset:
			if show_chunks_circle(offset, vertical_offset, player_chunk, 1, thread):
				return


func edit_terrain(coord: Vector3, radius: float, power: float) -> void:
	# Might not work for radius bigger then chunk_size
	var effected_chunks = []

	for x_i in range(-1, 2):
		for y_i in range(-1, 2):
			for z_i in range(-1, 2):
				var x = coord.x + radius * x_i
				var y = coord.y + radius * y_i
				var z = coord.z + radius * z_i
				var chunk = Vector3i(floor(x / CHUNK_SIZE), floor(y / CHUNK_SIZE), floor(z / CHUNK_SIZE))
				if not chunk in effected_chunks:
					effected_chunks.append(chunk)
					

	for chunk in effected_chunks:
		if not chunk in edited_chunks:
			var edited_data = []

			edited_data.resize((CHUNK_SIZE+1)**3)
			edited_data.fill(0.0)
				
			edited_chunks[chunk] = edited_data
		
		for x in range(CHUNK_SIZE+1):
			for y in range(CHUNK_SIZE+1):
				for z in range(CHUNK_SIZE+1):
					var noise_pos = CHUNK_SIZE * chunk + Vector3i(x, y, z)
					if noise_pos.distance_to(coord) <= radius:
						edited_chunks[chunk][x * (CHUNK_SIZE+1)**2 + y * (CHUNK_SIZE+1) + z] = power
	
		#var old_chunk_inst = get_node(str(chunk))
		
		#if old_chunk_inst != null:
			#old_chunk_inst.queue_free()
		
		marcher.loaded_mutex.lock()
		marcher.loaded_chunks.erase(chunk)
		marcher.loaded_mutex.unlock()

func check_player_inputs() -> void:
	var shoot_ray : RayCast3D = %Player.get_shootray()
	
	if Input.is_action_just_pressed("explosion"):
		var player = %Player
		var missile = missile_scene.instantiate()
		missile.direction = player.get_look_direction().rotated(Vector3.UP, randf_range(-PI/8, PI/8)).rotated(Vector3.LEFT, randf_range(-PI/8, PI/8))
		add_child(missile)
		missile.global_position = player.get_missile_spawn_point()
		missile.set_orientation()

		
	if Input.is_action_just_pressed("build") and shoot_ray.is_colliding():
		edit_terrain(shoot_ray.get_collision_point(), 8, -100)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	check_player_inputs()
	var player = %Player
	#$DebugBall.position = CHUNK_SIZE * Vector3(Vector3i(floor(player.position.x / CHUNK_SIZE), floor(player.position.y / CHUNK_SIZE), floor(player.position.z / CHUNK_SIZE)))
	#if (chunk_thread.is_started() && !chunk_thread.is_alive()):
		#chunk_thread.wait_to_finish()
		
	var player_chunk = Vector3i(floor(player.position.x / CHUNK_SIZE), floor(player.position.y / CHUNK_SIZE), floor(player.position.z / CHUNK_SIZE))
	show_chunks_around_player(player_chunk)

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
