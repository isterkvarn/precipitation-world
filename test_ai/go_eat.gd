
class_name GoEat extends ActionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	
	if actor.target_food == null:
		return FAILURE
	
	actor.state = actor.EATING
	
	if actor.can_eat_target():
		
		actor.state = actor.STOP
		
		return SUCCESS
		
	return RUNNING
	
