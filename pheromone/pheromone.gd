extends Area3D

var producer_id : int
var type : int
var strength : float
var direction : Vector3

const RADIUS = 6


func init(producer_id, type, strength, direction):
	self.producer_id = producer_id
	self.type = type
	self.strength = strength
	self.direction = direction

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	strength -= delta
	
	if strength <= 0:
		queue_free()
