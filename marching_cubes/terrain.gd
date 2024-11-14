extends Node3D

@export var CHUNK_SIZE := 32 # number of cubes in a chunk 
@export var RENDER_DISTANCE := 4 # in chunks

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


func map(v: float, min: float, max: float, nmin: float, nmax: float):
	return (v - min) * (nmax - nmin) / (max - min) + nmin

# very unsure about what I am doing here
func interp_weight(a, b):
	return (threshold - b) / (a - b)
	#return (e2 + (t - b) * (e1 - e2)  / (a - b));	
	
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
	vertex_buffer = rd.storage_buffer_create(16*32*(CHUNK_SIZE**3))
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
	rd.buffer_clear(vertex_buffer, 16*32*(CHUNK_SIZE**3), 0)
	
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
	
	#for i in range(8):
		#print(vertex_output[i])
	#print(count_output)

	# ADD ALL VERTECIES TO st
	for ver_index in range(0, count_output[0], 9):
		var vertex1 = Vector3(vertex_output[ver_index], 
							  vertex_output[ver_index+1],
							  vertex_output[ver_index+2])
		var vertex2 = Vector3(vertex_output[ver_index+3], 
							  vertex_output[ver_index+4],
							  vertex_output[ver_index+5])
		var vertex3 = Vector3(vertex_output[ver_index+6], 
							  vertex_output[ver_index+7],
							  vertex_output[ver_index+8])
		
		if vertex1.distance_to(vertex2) > 2.0 or vertex1.distance_to(vertex3) > 2.0 or vertex2.distance_to(vertex3) > 2.0:
			print("polygon :", vertex1, ", ", vertex2, ", ", vertex3)
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
	print("time to generate mesh cpu: ", (newtime2 - newtime1) / 1000000.0)
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
