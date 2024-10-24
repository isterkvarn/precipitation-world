extends CharacterBody3D


const SPEED = 40.0
const MAX_SPEED = 20
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003

@onready var rotation_helper = $RotationHelper

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var up_down = Input.get_axis("down", "up")
	var direction := (transform.basis * Vector3(input_dir.x, up_down, input_dir.y)).normalized()
	if direction:
		var fast = Input.is_action_pressed("speedup")
		velocity += direction * (int(fast) * 4 + 1) * SPEED * delta

	else:
		velocity.x = move_toward(velocity.x, 0, SPEED*delta)
		#velocity.y = move_toward(velocity.y, 0, SPEED*delta)
		velocity.z = move_toward(velocity.z, 0, SPEED*delta)

	velocity = velocity.limit_length(MAX_SPEED)
	move_and_slide()
	
func _input(event):
	# Used for mouse movment
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		rotation_helper.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		rotation_helper.rotation.x = clampf(rotation_helper.rotation.x, -PI/2, PI/2)
