extends Node3D

const CHUNK_SIZE = 10
const BALL_RADIUS = 1.
const BALL_HEIGHT = 2 * BALL_RADIUS
var noise = FastNoiseLite.new()

@export var threshold = 0.5

var time = 0.

func tick():
	time = Time.get_ticks_usec()

func tock():
	var newtime = Time.get_ticks_usec()
	print("ticktock time: ", (newtime - time) / 1000000.0)


func get_at(x, y, z, chunk):
	return chunk[x].get_pixel(y, z).r

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	noise.frequency = 0.1
	
	tick()
	var chunk = noise.get_image_3d(CHUNK_SIZE, CHUNK_SIZE, CHUNK_SIZE)
	tock()
	
	
	# slower because loops in godot slow af
	#tick()
	#var chunk_loop = []
	#chunk_loop.resize(CHUNK_SIZE)
	#
	#for x in range(CHUNK_SIZE):
		#chunk_loop[x] = []
		#chunk_loop[x].resize(CHUNK_SIZE)
		#for y in range(CHUNK_SIZE):
			#chunk_loop[x][y] = []
			#chunk_loop[x][y].resize(CHUNK_SIZE)
			#for z in range(CHUNK_SIZE):
				#chunk_loop[x][y][z] = noise.get_noise_3d(x, y, z)
	#tock()
	#
	#tick()
	#for x in range(CHUNK_SIZE):
		#for y in range(CHUNK_SIZE):
			#for z in range(CHUNK_SIZE):
				#print(chunk_loop[x][y][z])
	#tock()
	
	tick()
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			for z in range(CHUNK_SIZE):
				if (get_at(x, y, z, chunk) > threshold):
					var sphere = MeshInstance3D.new()
					var mesh = SphereMesh.new()
					sphere.mesh = mesh
					sphere.position = Vector3(x, y ,z) * BALL_RADIUS
					add_child(sphere)
	tock()

	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
