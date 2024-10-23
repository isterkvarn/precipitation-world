
extends CharacterBody3D

# State enums
enum{ROAMING, HUNTING, FIGHTING, ATTACKING, FLEEING}

# Phermone enums
enum{TERRITORY, SEARCHED}
@onready var phermone = load("res://pheromone/pheromone.tscn")

var territory = []

const SPEED = [8.0, 15.0, 10.0, 0.0, 12.0]

const MAX_HEALTH = 100
const HURT_THRESHOLD = MAX_HEALTH * 0.4

const MAX_HUNGER = 200
const EAT_THRESHOLD = MAX_HUNGER * 0.85
const DEFENSIVE_THRESHOLD = MAX_HUNGER * 0.95
const INTRUSION_THRESHOLD = MAX_HUNGER * 0.5
const AGGRESSION_THRESHOLD = MAX_HUNGER * 0.3
const EAT_DISTANCE = 4.0

@onready var perception = $Perception
@onready var smell = $Smell

var state = ROAMING
var hunger = MAX_HUNGER
var target

var health = MAX_HEALTH


const SCARED_TIME = 5.0
var scared_timer = 0.0

var territroy_timer = 0.0
var roam_direction = Vector3.ZERO
var territory_center = Vector3.ZERO

var collision_rays = []
@onready var mid_ray = $RayMid

var danger_pos = Vector3.ZERO

var time = 0
var mesh
var mesh2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	velocity = Vector3(1, 0, 0)
	
	var ray_length = 6
	var ray_sep_ang = PI/12
	
	for i in range(1,12):
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
	
	if Input.is_action_just_pressed("new_random"):
		give_scared()
	
	time += delta
	do_scared_timer(delta)
	calculate_hunger(delta)

	match state:
		ROAMING:
			$SpotLight3D.light_color = Color.BLUE
			do_roaming(delta)
		FIGHTING:
			$SpotLight3D.light_color = Color.RED
			do_fight(delta)
		HUNTING:
			$SpotLight3D.light_color = Color.PINK
			do_hunt(delta)
		ATTACKING:
			$SpotLight3D.light_color = Color.RED
			do_attacking(delta)
		FLEEING:
			$SpotLight3D.light_color = Color.GREEN
			do_fleeing(delta)
	
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
	
	if not is_hungry():
		health += 2 * delta
		
	health = min(health, MAX_HEALTH)

func is_hungry():
	return hunger < EAT_THRESHOLD
	
func is_defensive():
	return hunger < DEFENSIVE_THRESHOLD
	
func is_intrusive():
	return hunger < INTRUSION_THRESHOLD
	
func is_aggresive():
	return hunger < AGGRESSION_THRESHOLD
	
func is_in_own_territory():
	
	var own_smell = 0
	var other_smell = 0
	
	for area in smell.get_overlapping_areas():
		if area.is_in_group("pheromone"):
			if (area.producer_id == get_instance_id()):
				own_smell += 1
			else:
				other_smell += 1

	return own_smell > other_smell

func get_speed() -> float:
	return SPEED[state]

	
func do_roaming(delta) -> void:
	
	release_pheromone(TERRITORY)
	
	var acceleration = Vector3.ZERO
	
	if is_heading_for_collsion():
		acceleration += calc_collision_force(750)
	
	acceleration += 40 * roam_direction
	
	acceleration.y = 0
		
	velocity += acceleration * delta
	
	
func is_heading_for_collsion():
	if mid_ray.is_colliding():
		#$Debugball.global_position = mid_ray.get_collision_point()
		return true
	
	for i in range(4):
		if collision_rays[i].get_collider() != null:
			if collision_rays[i].is_colliding():
				#$Debugball.global_position = collision_rays[i].get_collision_point()
				return true
			
	return false

func do_fight(delta) -> void:
	
	var acceleration = Vector3.ZERO
	
	#if is_heading_for_collsion():
		#acceleration += calc_collision_force(1000)
		
	if is_instance_valid(target) or target != null:
		acceleration += 200 * (target.global_position - global_position).normalized()
	
	acceleration.y = 0
	
	velocity += acceleration * delta
	
func do_fleeing(delta) -> void:
	
	var acceleration = Vector3.ZERO
	
	if is_heading_for_collsion():
		acceleration += calc_collision_force(2000)
	
	acceleration += calc_avoid_force()
	acceleration += calc_home_force()
	
	acceleration.y = 0
	
	velocity += acceleration * delta
	
func do_hunt(delta) -> void:
	
	var acceleration = Vector3.ZERO
	
	if is_heading_for_collsion():
		acceleration += calc_collision_force(800)
	
	if target != null:
		acceleration += 300 * (target.global_position - global_position).normalized()
		
	acceleration.y = 0
	
	velocity += acceleration * delta
	
func do_attacking(delta):
	pass

func ses_food() -> bool:
	var food_candidates = []
	
	for body in perception.get_overlapping_bodies():
		if body.is_in_group("herd_agent"):
			food_candidates.append(body)
			
	if food_candidates.is_empty():
		return false
		
	var best_target = food_candidates[0]
	var best_distance = INF
	for food in food_candidates:
		var distance = (global_position - food.global_position).length()
		if distance < best_distance:
			best_target = food
			best_distance = distance
			
	target = best_target
		
	return true
	
func can_eat_target() -> bool:
	return EAT_DISTANCE >= (global_position - target.global_position).length()
	
func eat_target() -> void:
	if is_instance_valid(target):
		target.get_eaten()
		target = null
		hunger += MAX_HUNGER * randf_range(0.1, 0.2)
		hunger = min(MAX_HUNGER, hunger)
	
	if not is_hungry():
		territroy_timer = 30
	
func calc_collision_force(max_force) -> Vector3:
	var collision_vector
	
	var best_ray = collision_rays[-1]
	var count = 0
		
	for ray in collision_rays:
		if not ray.is_colliding():
			best_ray = ray
			break
		count += 1
			
				
	collision_vector = best_ray.get_target_position().normalized().rotated(Vector3.UP, rotation.y)
	
	var collision_force = (collision_vector - velocity)
	collision_force = clampf(collision_force.length(), 0.0, 0.5) * collision_force.normalized()
	#$Debugball2.position = collision_vector * 4
	var collision_weigth = max(max_force - (max_force/10)*(mid_ray.get_collision_point() - global_position).length(), 0.0)
	return collision_weigth * collision_force

func calc_pheromone_force(avoid_pher, follow_pher) -> Vector3:
	
	var max_force = 800
	var pheromone_force = Vector3.ZERO
	
	for phero in perception.get_overlapping_areas():
		if phero.is_in_group("pheromone") and phero.producer_id != get_instance_id():
			
			if phero.type in avoid_pher:
				var direction = (global_position - phero.global_position).normalized()
				direction = clampf(direction.length(), 0.0, 0.5) * direction.normalized()
				var distance = (global_position - phero.global_position).length()
				var weigth  = max(max_force - (max_force/phero.RADIUS) * distance, 0.0) 
				pheromone_force += weigth * direction
				
			if phero.type in avoid_pher:
				var direction = clampf(phero.direction.length(), 0.0, 0.5) * phero.direction.normalized()
				var distance = (global_position - phero.global_position).length()
				var weigth  = max(max_force - (max_force/phero.RADIUS) * distance, 0.0) 
				pheromone_force += weigth * direction
				
	
	return pheromone_force

func in_other_territory() -> bool:
	
	for phero in smell.get_overlapping_areas():
		if phero.is_in_group("pheromone") and phero.producer_id != get_instance_id():
			return true
			
	return false

func calc_avoid_force() -> Vector3:
	
	var avoid_vector = (position - danger_pos).normalized()
	var avoid_force = (avoid_vector - velocity.normalized())
	avoid_force = clampf(avoid_force.length(), 0.0, 0.5) * avoid_force.normalized()
	var avoid_weight = clampf(378 - 27*(position - danger_pos).length(), 0, 378)
	return avoid_weight * avoid_force

func calc_home_force() -> Vector3:
	var home_vector = (territory_center - global_position).normalized()
	var home_force = min((territory_center - global_position).length(), 300)
	return home_vector * home_force

func ses_danger() -> bool:
	for body in perception.get_overlapping_bodies():
		if ((body.is_in_group("hunter") and body.get_instance_id() != get_instance_id()) 
										or body.is_in_group("player")):
			
			danger_pos = body.global_position
			target = body
			return true
			
	return false

func is_scared() -> bool:
	return scared_timer > 0

func give_scared() -> void:
	# Set timer
	scared_timer = SCARED_TIME * randf_range(0.8, 1.2)

func do_scared_timer(delta) -> void:
			
	scared_timer -= delta
	
func get_attacked(dmg) -> void:
	print("took ", dmg)
	health -= dmg
	print("health ", health)
	if health <= 0:
		queue_free()
		
func attack_target() -> void:
	var dmg = randf_range(10, 30)
	print("deal ", dmg)
	target.get_attacked(dmg)
	
func is_hurt() -> bool:
	return health <= HURT_THRESHOLD

func release_pheromone(pher_type) -> void:
	
	# If some of same type found, update them
	for area in smell.get_overlapping_areas():
		if (area.is_in_group("pheromone") and area.type == pher_type):
			if (area.producer_id == get_instance_id()):
				
				area.strength = 60
				area.direction = -velocity.normalized()
				return
			else:
				# dont place scent if already there
				return

	var new_pher = phermone.instantiate()
	new_pher.init(get_instance_id(), pher_type, 60, -velocity.normalized())
	get_parent().add_child(new_pher)
	new_pher.global_position = global_position
	
	if pher_type == TERRITORY:
		territory.append(new_pher)

	if true:
		match name:
			"Hunter":
				new_pher.get_node("DebugMesh1").visible = true
				pass
			"Hunter2":
				new_pher.get_node("DebugMesh2").visible = true
				pass
			"Hunter3":
				new_pher.get_node("DebugMesh3").visible = true
				pass
			"Hunter4":
				new_pher.get_node("DebugMesh4").visible = true
				pass
		

func get_territory_center() -> Vector3:
	
	var center = Vector3.ZERO
	
	for pher in territory:
		
		if not is_instance_valid(pher):
			territory.erase(pher)
			continue
			
		center += pher.global_position
		
	center /= territory.size()
	
	return center

func new_roam_direction() -> void:
	if territory.size() <= 1:
		roam_direction = Vector3.FORWARD.rotated(Vector3.UP, randf() * 2 * PI )
		territory_center = global_position
		return
		
	territory_center = get_territory_center()
	# Make direction a bit random, more random if hungry to spread territory
	var angle_variance = randf_range(-1.0, 1.0) * (PI/12 + (MAX_HUNGER - hunger)/MAX_HUNGER * PI/2)
	var new_roam_direction = (territory_center - global_position).rotated(Vector3.UP, angle_variance)
	roam_direction = new_roam_direction.normalized()

func is_far_from_territory() -> bool:
	return (global_position - territory_center).length() > 25 + (MAX_HUNGER - hunger)/MAX_HUNGER * 160
