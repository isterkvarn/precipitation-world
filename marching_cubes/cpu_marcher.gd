class_name CpuMarcher extends Marcher



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

func generate_balls(coord) -> void:
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
					scene.add_child(sphere)


# very unsure about what I am doing here
func interp_weight(a, b):
	return (threshold - b) / (a - b)
	#return (e2 + (t - b) * (e1 - e2)  / (a - b));	

func map(v: float, min: float, max: float, nmin: float, nmax: float):
	return (v - min) * (nmax - nmin) / (max - min) + nmin


# slow but cool
func march_animation(coord: Vector3i) -> void:
	loaded_mutex.lock()
	loaded_chunks[coord] = 1.
	loaded_mutex.unlock()
	
	var box := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box.mesh = box_mesh
	scene.add_child(box)
	for x in range(CHUNK_SIZE):
		await scene.get_tree().create_timer(0.1).timeout # nice animation
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
				scene.add_child(marched)
	scene.remove_child(box)


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
	scene.add_child.call_deferred(marched)
	
	var newtime2 := Time.get_ticks_usec()
	print("time to generate terrain: ", (newtime3 - time) / 1000000.0)
	print("time to generate vertex: ", (newtime1 - newtime3) / 1000000.0)
	print("time to generate collision: ", (newtime2 - newtime1) / 1000000.0)

# nothing to initialize here. Is for gpu
func init() -> void:
	pass
