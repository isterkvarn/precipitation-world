
class_name Chase extends ActionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	
	actor.state = actor.HUNTING
	
	if actor.target == null:
		return FAILURE
	
	if actor.can_eat_target():
		actor.eat_target()
		return SUCCESS
		
	return RUNNING
