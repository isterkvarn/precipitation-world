extends Area3D

var direction = Vector3.FORWARD
var velocity = Vector3.ZERO
@onready var trail = $Trail
const SPEED = 50
const GRAVITY = Vector3.DOWN * 9.8

@onready var exp_scene = preload("res://missile/explosion_particles.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotation = direction
	velocity = direction * SPEED

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	set_orientation()
	velocity += GRAVITY * delta
	position += velocity * delta

func set_orientation():
	look_at(position + velocity.normalized())

func explode():
	var exp = exp_scene.instantiate()
	get_parent().add_child(exp)
	get_parent().edit_terrain(position, 6, 100)
	exp.position = position
	exp.get_node("Base").emitting = true
	exp.get_node("Wide").emitting = true
	trail.reparent(get_parent())
	trail.start_death_timer()
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		explode()


func _on_timer_timeout() -> void:
	explode()
