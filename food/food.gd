extends Area3D

const GROWTH_CHANCE_DENSITY_MOD = 0.1
const STD_GROWTH_TIME = 0.8
const GROWTH_RND = 0.2
const RND_GROWTH_ANGLE = PI
const STD_GROWTH_DISTANCE = 0.5
const RND_GROWTH_DISTANCE = 0.3

var growth_timer = STD_GROWTH_TIME

@onready var growth_area = $GrowthArea

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
		
	if growth_timer <= 0:
		growth_timer = STD_GROWTH_TIME + randf_range(-GROWTH_RND, GROWTH_RND)
	
		if get_growth_chance() <= 0:
			return
		
		if roll_if_growth(delta):
			do_growth()
			
	growth_timer -= delta

func roll_if_growth(delta) -> bool:
	var rand_float = randf_range(0.0, 1.0)
	return (rand_float < get_growth_chance())

func get_growth_chance() -> float:
	var num_food = 0
	
	for body in growth_area.get_overlapping_areas():
		if body.is_in_group("food"):
			num_food += 1

	return max(0.0, 1.0 - num_food * GROWTH_CHANCE_DENSITY_MOD)
		

func do_growth():
	
	# Count other foods to get growth direction
	var acum_direction = Vector3(1.0, 0.0, 0.0).rotated(Vector3.UP, randf_range(0.0, PI*2))
	
	for body in growth_area.get_overlapping_areas():
		if body.is_in_group("food"):
			acum_direction += (global_position - body.global_position).normalized()
			
	acum_direction.normalized()
	
	# Add some randomness
	var rnd_angle_offset = randf_range(-RND_GROWTH_ANGLE, RND_GROWTH_ANGLE)
	
	var growth_direction = acum_direction.rotated(Vector3.UP, rnd_angle_offset)
	
	# Get random growth distnace to get position
	var growth_distance = (STD_GROWTH_DISTANCE + 
							randf_range(-RND_GROWTH_DISTANCE, RND_GROWTH_DISTANCE))
	var growth_position = global_position + growth_distance * growth_direction
	
	# Check if growth position is reachable
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position + Vector3(0.0, 0.25, 0.0), growth_position)
	var result = space_state.intersect_ray(query)
	
	if result.position != growth_position:
		return
	
	# Make food at position
	var new_food = duplicate()
	get_parent().add_child(new_food)
	new_food.global_position = growth_position
	
func get_eaten() -> void:
	queue_free()
	
