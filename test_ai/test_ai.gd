extends CharacterBody3D

const ROAMING = 0
const FLEEING = 1
const FIND_FOOD = 2

const SPEED = [5.0, 10.0, 5.0]

const MAX_HUNGER = 100

@onready var navigation = $NavigationAgent3D
@onready var perception = $Perception


var state = 0
var hunger = MAX_HUNGER

const SCARED_TIME = 10.0
var scared_timer = 0.0

var collision_rays = []
@onready var mid_ray = $RayMid

var danger_pos = Vector3.ZERO

var time = 0
var mesh
var mesh2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	velocity = Vector3(1, 0, 0)
	
	var ray_length = 4
	
	for i in range(1,12):
		var ray_r = RayCast3D.new()
		var ray_l = RayCast3D.new()
		add_child(ray_r)
		add_child(ray_l)
		collision_rays.append(ray_r)
		collision_rays.append(ray_l)
		ray_r.set_target_position(Vector3(ray_length*cos(-PI/2 - i*PI/12), 0, ray_length*sin(-PI/2 - i*PI/12)))
		ray_l.set_target_position(Vector3(ray_length*cos(-PI/2 + i*PI/12), 0, ray_length*sin(-PI/2 + i*PI/12)))
		
		"""mesh = $MeshInstance3D.duplicate()
		mesh.position = Vector3(ray_length*cos(-PI/2 - i*PI/12), 0, ray_length*sin(-PI/2 - i*PI/12))
		add_child(mesh)
		
		mesh2 = $MeshInstance3D.duplicate()
		mesh2.position = Vector3(ray_length*cos(-PI/2 + i*PI/12), 0, ray_length*sin(-PI/2 + i*PI/12))
		add_child(mesh2)"""
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	time += delta
	do_scared_timer(delta)
	calculate_hunger(delta)

	match state:
		ROAMING:
			do_roaming(delta)
		FLEEING:
			do_roaming(delta)
		FIND_FOOD:
			do_find(delta)
	
	if (not velocity.is_zero_approx() and 
		not (global_position + 5*velocity).cross(Vector3.UP).is_zero_approx()):
		
		look_at(global_position + 5*velocity, Vector3.UP)
		
	velocity = velocity.normalized() * get_speed()
	
	if not is_on_floor():
		velocity += get_gravity() * delta;
	
	move_and_slide()

func calculate_hunger(delta):
	hunger -= delta

func is_hungry():
	return hunger < MAX_HUNGER * 0.7

func get_speed() -> float:
	
		if state == ROAMING:
			return clampf(velocity.length(), 0.0, SPEED[state])
			
		return SPEED[state]

func new_random_roam_target() -> void:
	var random_position
	var radius = 5
	
	# Instead of while loop so we dont get stuck
	for i in range(1000):
		random_position = position + Vector3(randf_range(-radius, radius), 
											0, 
											randf_range(-radius, radius))
							
		navigation.set_target_position(random_position)
		if navigation.is_target_reachable():
			break
	
	
func has_arrived_navigation() -> bool:
	return navigation.is_target_reached()
	
	
func do_roaming(delta) -> void:
	
	var acceleration = Vector3.ZERO
	
	if is_heading_for_collsion():
		acceleration += calc_collision_force()
	
	var herd_members = get_percived_herd_members()
	
	if not herd_members.is_empty():
		acceleration += calc_boid_forces(herd_members, [5, 5, 5])
	
	acceleration.y = 0
	
	if acceleration.length() < 5:
		#velocity = velocity.move_toward(Vector3.ZERO, 5)'
		pass
	else:
		velocity += acceleration * delta
	
	
func is_heading_for_collsion():
	if mid_ray.is_colliding() and not mid_ray.get_collider().is_in_group("herd_agent"):
		$Debugball.global_position = mid_ray.get_collision_point()
		return true
	
	for i in range(4):
		if collision_rays[i].is_colliding() and not collision_rays[i].get_collider().is_in_group("herd_agent"):
			$Debugball.global_position = collision_rays[i].get_collision_point()
			return true
			
	return false
	
func do_fleeing(delta) -> void:
	
	var acceleration = Vector3.ZERO
	
	if is_heading_for_collsion():
		acceleration += calc_collision_force()
	
	var herd_members = get_percived_herd_members()
	
	if not herd_members.is_empty():
		acceleration += calc_boid_forces(herd_members, [55, 70, 50])
	
	acceleration += calc_avoid_force()
	
	acceleration.y = 0
	
	velocity += acceleration * delta
	
func calc_collision_force() -> Vector3:
	var collision_vector
	
	var best_ray = collision_rays[-1]
	var count = 0
		
	for ray in collision_rays:
		if not ray.is_colliding():
			best_ray = ray
			break
				
	collision_vector = best_ray.get_target_position().normalized().rotated(Vector3.UP, rotation.y)
	
	var collision_force = (collision_vector - velocity)
	collision_force = clampf(collision_force.length(), 0.0, 0.9) * collision_force.normalized()
	var collision_weigth = max(800 - 200*(mid_ray.get_collision_point() - global_position).length(), 0.0)
	return collision_weigth * collision_force
	
func calc_boid_forces(members, weights) -> Vector3:
	
	var sum_forces = Vector3.ZERO
	var alignment_force = Vector3.ZERO
	var cohesion_force = Vector3.ZERO
	var seperation_force = Vector3.ZERO
	
	for member in members:
		var weigth = max(1.2 - 0.2 * (global_position - member.global_position).length(), 0.0)
		
		seperation_force += weigth * (global_position - member.global_position).normalized()
		alignment_force += weigth * member.velocity.normalized()
		cohesion_force += member.position
		
	cohesion_force /= members.size()
	cohesion_force = (cohesion_force - global_position)
		
	sum_forces += weights[0] * clampf(alignment_force.length(), 0.0, 0.6) * alignment_force.normalized()
	sum_forces += weights[1] * clampf(cohesion_force.length(), 0.0, 0.6) * cohesion_force.normalized()
	sum_forces += weights[2] * clampf(seperation_force.length(), 0.0, 0.6) * seperation_force.normalized()
	
	return sum_forces
	

func calc_avoid_force() -> Vector3:
	
	var avoid_vector = (position - danger_pos).normalized()
	var avoid_force = (avoid_vector - velocity.normalized())
	avoid_force = clampf(avoid_force.length(), 0.0, 0.8) * avoid_force.normalized()
	var avoid_weight = clampf(400 - 80*(position - danger_pos).length(), 0, 400)
	avoid_weight *= perception_weight(position - danger_pos)
	return avoid_weight * avoid_force
	
func perception_weight(pos) -> float:
	var weight = abs(velocity.normalized().dot(pos))
	return weight
	
func do_find(delta) -> void:
	velocity = velocity.rotated(Vector3.UP, delta * PI/12)

func get_percived_herd_members():
	
	var members = []
	
	for body in perception.get_overlapping_bodies():
		if body.is_in_group("herd_agent"):
			members.append(body)
			
	return members

func check_danger() -> void:
	for body in perception.get_overlapping_bodies():
		if body.is_in_group("player"):
			# Set to run away from players current position
			give_scared(body.global_position)
			

func is_scared() -> bool:
	return scared_timer > 0

func give_scared(scared_pos) -> void:
	
	# If already scared dont update, so only player can update danger postion
	danger_pos = scared_pos
	
	# Set timer
	scared_timer = SCARED_TIME
	
	# Give other in herd this postion to run from
	for member in get_percived_herd_members():
		if not member.is_scared():
			member.give_scared(global_position)

func do_scared_timer(delta) -> void:
	
	#if not is_scared():
		#return
			
	scared_timer -= delta
