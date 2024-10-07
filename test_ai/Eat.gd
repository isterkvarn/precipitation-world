
class_name Eat extends ActionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	
	if actor.target_food == null:
		return FAILURE
	
	actor.eat_target()
	
	return SUCCESS
