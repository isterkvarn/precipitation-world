extends Area3D

const GROWTH_CHANCE = 0.25
const STD_GROWTH_TIME = 1.0
const GROWTH_RND = 0.5
const RND_GROWTH_ANGLE = PI/12
const STD_GROWTH_DISTANCE = 1.5
const RND_GROWTH_DISTANCE = 0.5

var growth_timer = STD_GROWTH_TIME

@onready var growth_area = $GrowthArea

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if get_growth_chance() == 0:
		return
		
	if growth_timer <= 0:
		growth_timer = STD_GROWTH_TIME + randf_range(-GROWTH_RND, GROWTH_RND)
	
		if roll_if_growth(delta):
			do_growth()
			
	growth_timer -= delta

func roll_if_growth(delta) -> bool:
	var rand_float = randf_range(0.0, 1.0)
	return (rand_float < GROWTH_CHANCE)

func get_growth_chance() -> float:
	var num_food = 0
	
	for body in get_overlapping_areas():
		if body.is_in_group("food"):
			num_food += 1
			
	return max(0.0, 1.0 - num_food * GROWTH_CHANCE)
		

func do_growth():
	
	#var acum_direction = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
	var acum_direction = Vector3(1.0, 0.0, 0.0)
	
	for body in get_overlapping_areas():
		if body.is_in_group("food"):
			acum_direction = global_position - body.global_position
			
	acum_direction.normalized()
	
	var rnd_angle_offset = randf_range(-RND_GROWTH_ANGLE, RND_GROWTH_ANGLE)
	
	var growth_direction = acum_direction.rotated(Vector3.UP, rnd_angle_offset)
	var growth_distance = (STD_GROWTH_DISTANCE + 
							randf_range(-RND_GROWTH_DISTANCE, RND_GROWTH_DISTANCE))
	var growth_position = global_position + growth_distance * growth_direction
	
	var new_food = duplicate()
	get_parent().add_child(new_food)
	new_food.global_position = growth_position
	
