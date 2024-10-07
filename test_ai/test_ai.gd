extends CharacterBody3D

const ROAMING = 0
const FLEEING = 1
const FIND_FOOD = 2
const EATING = 3
const FIND_HERD = 4
const STOP = 5

const SPEED = [2.0, 10.0, 4.0, 4.0, 4.0, 0.0]

const MAX_HUNGER = 100
const EAT_DISTANCE = 1.8

const PUSH_TIME = 2.0

const HERD_COUNT_REQ = 5

@onready var navigation = $NavigationAgent3D
@onready var perception = $Perception


var state = ROAMING
var hunger = MAX_HUNGER
var target_food


const SCARED_TIME = 10.0
var scared_timer = 0.0

var collision_rays = []
@onready var mid_ray = $RayMid

var danger_pos = Vector3.ZERO

var push_timer = 0

var time = 0
var mesh
var mesh2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	velocity = Vector3(1, 0, 0)
	
	var ray_length = 4
	var ray_sep_ang = PI/8
	
	for i in range(1,8):
		var ray_r = RayCast3D.new()
		var ray_l = RayCast3D.new()
		add_child(ray_r)
		add_child(ray_l)
		collision_rays.append(ray_r)
		collision_rays.append(ray_l)
		ray_r.set_target_position(Vector3(ray_length*cos(-PI/2 - i*ray_sep_ang), 0, ray_length*sin(-PI/2 - i*ray_sep_ang)))
		ray_l.set_target_position(Vector3(ray_length*cos(-PI/2 + i*ray_sep_ang), 0, ray_length*sin(-PI/2 + i*ray_sep_ang)))
		
		"""mesh = $MeshInstance3D.duplicate()
		mesh.position = Vector3(ray_length*cos(-PI/2 - i*ray_sep_ang), 0, ray_length*sin(-PI/2 - i*ray_sep_ang))
		add_child(mesh)
		
		mesh2 = $MeshInstance3D.duplicate()
		mesh2.position = Vector3(ray_length*cos(-PI/2 + i*ray_sep_ang), 0, ray_length*sin(-PI/2 + i*ray_sep_ang))
		add_child(mesh2)"""
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	time += delta
	do_scared_timer(delta)
	calculate_hunger(delta)

	match state:
		ROAMING:
			$SpotLight3D.light_color = Color.BLUE
			do_roaming(delta)
		FLEEING:
			$SpotLight3D.light_color = Color.RED
			do_fleeing(delta)
		FIND_FOOD:
			$SpotLight3D.light_color = Color.YELLOW
			find_food(delta)
		EATING:
			$SpotLight3D.light_color = Color.GREEN
			do_eating(delta)
		FIND_HERD:
			$SpotLight3D.light_color = Color.PURPLE
			find_herd(delta)
	
	if (not global_position.is_equal_approx(global_position + 5*velocity)):
		look_at(global_position + 5*velocity, Vector3.UP)
		
	velocity = velocity.normalized() * get_speed()
	
	if not is_on_floor():
		velocity += get_gravity() * delta;
	
	move_and_slide()

func calculate_hunger(delta):
	hunger -= delta
	if hunger <= 0:
		queue_free()

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
	
	if is_heading_for_collsion(true):
		acceleration += calc_collision_force(true, 20)
	
	var herd_members = get_percived_herd_members()
	
	if not herd_members.is_empty():
		acceleration += calc_boid_forces(herd_members, [3, 15, 13], 0.5)
	
	acceleration.y = 0
	
	if push_timer <= 0:
		if randf() < 0.14:
			acceleration += Vector3(8.0, 0.0, 0.0).rotated(Vector3.UP, randf_range(0.0, PI*2))
		push_timer = PUSH_TIME + randf() * PUSH_TIME
	else:
		push_timer -= delta
		
	if acceleration.length() < 6:
		acceleration = velocity.move_toward(Vector3.ZERO, 5) - velocity
		
	velocity += acceleration * delta
	
	
func is_heading_for_collsion(ignore_herd):
	if mid_ray.is_colliding() and (not ignore_herd or mid_ray.get_collider().is_in_group("herd_agent")):
		$Debugball.global_position = mid_ray.get_collision_point()
		return true
	
	for i in range(4):
		if collision_rays[i].get_collider() != null:
			if collision_rays[i].is_colliding() and (not ignore_herd or not collision_rays[i].get_collider().is_in_group("herd_agent")):
				$Debugball.global_position = collision_rays[i].get_collision_point()
				return true
			
	return false
	
func do_fleeing(delta) -> void:
	
	var acceleration = Vector3.ZERO
	
	if is_heading_for_collsion(true):
		acceleration += calc_collision_force(true, 700)
	
	var herd_members = get_percived_herd_members()
	
	if not herd_members.is_empty():
		acceleration += calc_boid_forces(herd_members, [55, 70, 50], 0.6)
	
	acceleration += calc_avoid_force()
	
	acceleration.y = 0
	
	velocity += acceleration * delta

func find_herd(delta) -> void:
	var acceleration = Vector3.ZERO
	
	if is_heading_for_collsion(false):
		acceleration += calc_collision_force(false, 100)
	
	var herd_members = get_percived_herd_members()
	
	if not herd_members.is_empty():
		acceleration += calc_boid_forces(herd_members, [7, 12, 8], 0.5)
	
	acceleration.y = 0
	
	velocity += acceleration * delta
	
func is_in_herd() -> bool:
	
	var herd = get_percived_herd_members()
	
	# In herd if we can see enough members
	if herd.size() >= HERD_COUNT_REQ:
		return true
		
	# Or if we see a member that is calm
	for member in herd:
		if member.state == ROAMING:
			return true
			
	return false

func find_food(delta) -> void:
	var acceleration = Vector3.ZERO
	
	if is_heading_for_collsion(false):
		acceleration += calc_collision_force(false, 100)
	
	var herd_members = get_percived_herd_members()
	
	if not herd_members.is_empty():
		acceleration += calc_boid_forces(herd_members, [5, 8, 8], 0.5)
	
	acceleration.y = 0
	
	velocity += acceleration * delta
	
func do_eating(delta) -> void:
	
	var acceleration = Vector3.ZERO
	
	if is_heading_for_collsion(false):
		acceleration += calc_collision_force(false, 150)
	
	var herd_members = get_percived_herd_members()
	
	if not herd_members.is_empty():
		acceleration += calc_boid_forces(herd_members, [2, 3, 5], 0.5)
	
	if target_food != null:
		acceleration += 25 * (target_food.global_position - global_position).normalized() 
	
	acceleration.y = 0
	
	velocity += acceleration * delta
	

func ses_food() -> bool:
	
	var food_candidates = []
	
	for area in perception.get_overlapping_areas():
		if area.is_in_group("food"):
			food_candidates.append(area)
			
	if food_candidates.is_empty():
		return false
		
	var best_target = food_candidates[0]
	var best_distance = INF
	for food in food_candidates:
		var distance = (global_position - food.global_position).length()
		if distance < best_distance:
			best_target = food
			best_distance = distance
			
	target_food = best_target
		
	return true
	
func can_eat_target() -> bool:
	return EAT_DISTANCE >= (global_position - target_food.global_position).length()
	
func eat_target() -> void:
	target_food.get_eaten()
	target_food = null
	hunger += MAX_HUNGER * randf_range(0.1, 0.3)
	
func calc_collision_force(ignore_herd, max_force) -> Vector3:
	var collision_vector
	
	var best_ray = collision_rays[-1]
	var count = 0
		
	for ray in collision_rays:
		if not ray.is_colliding() or (ignore_herd and ray.get_collider().is_in_group("herd_agent")):
			best_ray = ray
			break
		count += 1
			
				
	collision_vector = best_ray.get_target_position().normalized().rotated(Vector3.UP, rotation.y)
	
	var collision_force = (collision_vector - velocity)
	collision_force = clampf(collision_force.length(), 0.0, 0.5) * collision_force.normalized()
	$Debugball2.position = collision_vector * 4
	var collision_weigth = max(max_force - (max_force/10)*(mid_ray.get_collision_point() - global_position).length(), 0.0)
	return collision_weigth * collision_force
	
func calc_boid_forces(members, weights, turning_speed) -> Vector3:
	
	var sum_forces = Vector3.ZERO
	var alignment_force = Vector3.ZERO
	var cohesion_force = Vector3.ZERO
	var seperation_force = Vector3.ZERO
	
	for member in members:
		var weigth = max(1.2 - 0.2 * (global_position - member.global_position).length(), 0.0)
		
		#print("weight: ", weigth, ", distance: ", (global_position - member.global_position).length())
		
		seperation_force += weigth * (global_position - member.global_position).normalized()
		alignment_force += weigth * member.velocity.normalized()
		cohesion_force += member.position
		
	cohesion_force /= members.size()
	cohesion_force = (cohesion_force - global_position)
		
	sum_forces += weights[0] * clampf(alignment_force.length(), 0.0, turning_speed) * alignment_force.normalized()
	sum_forces += weights[1] * clampf(cohesion_force.length(), 0.0, turning_speed) * cohesion_force.normalized()
	sum_forces += weights[2] * clampf(seperation_force.length(), 0.0, turning_speed) * seperation_force.normalized()
	
	return sum_forces
	

func calc_avoid_force() -> Vector3:
	
	var avoid_vector = (position - danger_pos).normalized()
	var avoid_force = (avoid_vector - velocity.normalized())
	avoid_force = clampf(avoid_force.length(), 0.0, 0.5) * avoid_force.normalized()
	var avoid_weight = clampf(378 - 27*(position - danger_pos).length(), 0, 378)
	#avoid_weight *= perception_weight(position - danger_pos)
	#print(avoid_weight)
	return avoid_weight * avoid_force
	
func perception_weight(pos) -> float:
	var weight = abs(velocity.normalized().dot(pos))
	return weight

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
	scared_timer = SCARED_TIME * randf_range(0.8, 1.2)
	
	# Give other in herd this postion to run from
	for member in get_percived_herd_members():
		if not member.is_scared():
			member.give_scared(scared_pos)

func do_scared_timer(delta) -> void:
	
	#if not is_scared():
		#return
			
	scared_timer -= delta
