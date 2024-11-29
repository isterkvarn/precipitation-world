class_name GpuMarcher extends Marcher

var rd : RenderingDevice
var rd_mutex := Mutex.new()
var shader : RID
var edited_buffer : RID
var vertex_buffer : RID
var buffer_set : RID
var size_buffer : RID
var is_empty_buffer : RID
var pos_buffer : RID
var lod_buffer : RID
var threshold_buffer : RID
var pipeline : RID

var dead_beef_arr = PackedFloat32Array()

func init() -> void:
	# Create a local rendering device for compute shaders
	rd_mutex.lock()
	rd = RenderingServer.create_local_rendering_device()
	
	# Load GLSL shader
	var shader_file := load("res://shaders/cube_march.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	
	# Create buffer for edited
	edited_buffer = rd.storage_buffer_create(32*(CHUNK_SIZE+1)**3)
	var e_uniform := RDUniform.new()
	e_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	e_uniform.binding = 1 # this needs to match the "binding" in our shader file
	e_uniform.add_id(edited_buffer)
	
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
	
	# create buffer for chunk position
	var chunk_pos = [0.0, 0.0, 0.0]
	var pos_bytes = PackedInt32Array(chunk_pos).to_byte_array()
	pos_buffer = rd.storage_buffer_create(pos_bytes.size(), pos_bytes)
	var pos_uniform = RDUniform.new()
	pos_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	pos_uniform.binding = 5
	pos_uniform.add_id(pos_buffer)
	
	# create buffer for lod
	var lod = [1]
	var lod_bytes = PackedInt32Array(lod).to_byte_array()
	lod_buffer = rd.storage_buffer_create(lod_bytes.size(), lod_bytes)
	var lod_uniform = RDUniform.new()
	lod_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	lod_uniform.binding = 0
	lod_uniform.add_id(lod_buffer)
	
	# create buffer for threshold
	var threshold_array = [threshold]
	var threshold_bytes = PackedFloat32Array(threshold_array).to_byte_array()
	threshold_buffer = rd.storage_buffer_create(size_bytes.size(), size_bytes)
	var threshold_uniform = RDUniform.new()
	threshold_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	threshold_uniform.binding = 4
	threshold_uniform.add_id(threshold_buffer)
	
	# create buffer for is_empty
	var empty_array = [0]
	var is_empty_bytes = PackedFloat32Array(empty_array).to_byte_array()
	is_empty_buffer = rd.storage_buffer_create(is_empty_bytes.size(), is_empty_bytes)
	var is_empty_uniform = RDUniform.new()
	is_empty_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	is_empty_uniform.binding = 6
	is_empty_uniform.add_id(is_empty_buffer)
	
	var buffers = [is_empty_uniform, pos_uniform, e_uniform, v_uniform, size_uniform, lod_uniform, threshold_uniform]
	buffer_set = rd.uniform_set_create(buffers, shader, 0)
	pipeline = rd.compute_pipeline_create(shader)
	rd_mutex.unlock()
	print(buffer_set)
	print("done init for shader")
	
	#print(rd.buffer_get_data(noise_buffer).to_float32_array())
func generate_mesh(vertex_output, coord, lod: int):
	var marched := march_meshInstance()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#for i in range(8):
		#print(vertex_output[i])
	#print(count_output)
	# ADD ALL VERTECIES TO st
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
		
		#if vertex1.distance_to(vertex2) > 2.0 or vertex1.distance_to(vertex3) > 2.0 or vertex2.distance_to(vertex3) > 2.0:
			#print("polygon :", vertex1, ", ", vertex2, ", ", vertex3)
		st.add_vertex(vertex1)
		st.add_vertex(vertex2)
		st.add_vertex(vertex3)
	
	# Commit to a mesh.
	st.generate_normals()
	# hits generation performance and i couldn't measure any performance difference
	#st.index()
	#st.optimize_indices_for_cache()
	var mesh := st.commit()
	
	marched.position = coord * CHUNK_SIZE
	marched.mesh = mesh
	
	# generate collison for mesh
	if lod == 1 && mesh.get_surface_count() > 0:
		marched.create_trimesh_collision()
	# make sure collsision is detected on backside since collision orientation is wrong
	# kinda ugly way to access collision shape but is works
	if marched.get_child_count() > 0:
		marched.get_node("_col").get_node("CollisionShape3D").shape.set_backface_collision_enabled(true)
	
	#add_child(marched) deffered because of threading
	marched.name = str(coord)
	scene.update_chunk.call_deferred(str(coord), marched)

	var newtime4 := Time.get_ticks_usec()
	#print("time to generate noise cpu: ", (newtime1 - time) / 1000000.0)
	#print("time to generate polygons gpu: ", (newtime2 - newtime1) / 1000000.0)
	#print("time to generate mesh cpu: ", (newtime3 - newtime2) / 1000000.0)
	#print("Total time ", (newtime4 - time) / 1000000.0)

func march_chunk(coord: Vector3i, lod: int, TRI, edited) -> void:
	var time = Time.get_ticks_usec()
	
	loaded_mutex.lock()
	loaded_chunks[coord] = lod
	loaded_mutex.unlock()
	
	# Update with chunk noise
	if edited.is_empty():
		edited.resize((CHUNK_SIZE+1)**3)
		edited.fill(0.0)
		
	var edited_bytes = PackedFloat32Array(edited).to_byte_array()
	
	var test_time = Time.get_ticks_usec()
	
	var pos_bytes = PackedFloat32Array([coord.x, coord.y, coord.z]).to_byte_array()
	var lod_bytes = PackedInt32Array([lod]).to_byte_array()
	var is_empty = PackedInt32Array([0]).to_byte_array()
	
	rd_mutex.lock()
	
	rd.buffer_update(edited_buffer, 0, edited_bytes.size(), edited_bytes)
	
	rd.buffer_update(pos_buffer, 0, pos_bytes.size(), pos_bytes)
	
	# update lod
	rd.buffer_update(lod_buffer, 0, lod_bytes.size(), lod_bytes)
	
	# Clear output buffer
	rd.buffer_update(vertex_buffer, 0, dead_beef_arr.size(), dead_beef_arr)
	
	# Clear is empty buffer
	rd.buffer_update(is_empty_buffer, 0, is_empty.size(), is_empty)
	
	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, buffer_set, 0)
	rd.compute_list_dispatch(compute_list, 8/lod, 8/lod, 8/lod)
	rd.compute_list_end()
	
	var newtime1 = Time.get_ticks_usec()
	
	# GENERATE VERTEIES ON GPU
	rd.submit()
	rd.sync()
	
	var newtime2 := Time.get_ticks_usec()
	
	
	var ver_bytes = rd.buffer_get_data(vertex_buffer)
	var is_empty_bytes = rd.buffer_get_data(is_empty_buffer)
	rd_mutex.unlock()
	
	var vertex_output = ver_bytes.to_float32_array()
	var is_empty_output = is_empty_bytes.to_int32_array()
	
	#print(rd.buffer_get_data(noise_buffer).to_float32_array())
	
	# don't generate mesh if it's empty
	
	# Check if there is something in buffer, dont want to waste time on air
	var not_empty = is_empty_output[0] != 0
	if not_empty:
		generate_mesh(vertex_output, coord, lod)
		
	var newtime3 := Time.get_ticks_usec()
	
	var end := Time.get_ticks_usec()
	#print("time to test: ", (test_time - time) / 1000000.0)
	print("time to set-up: ", (newtime1 - time) / 1000000.0)
	print("time to generate polygons gpu: ", (newtime2 - newtime1) / 1000000.0)
	print("time to generate mesh cpu: ", (newtime3 - newtime2) / 1000000.0, ", empty: ", not not_empty)
	print("Total time ", (end - time) / 1000000.0)
