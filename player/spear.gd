extends Area3D

const SPEED = 10

var velocity = Vector3.FORWARD
var hit = false
var pos_offset = Vector3.ZERO
var rot_offset = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if not hit:
		
		if (not global_position.is_equal_approx(global_position + 5*velocity)):
			look_at(global_position + 5*velocity, Vector3.UP)
		
		velocity += delta * 3 * get_gravity() * Vector3.DOWN
		position += velocity * delta

func _on_body_entered(body: Node3D) -> void:
	if not hit:
		
		print(body.name)
		self.reparent(body)
		hit = true
