class_name GetInRange extends ActionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	actor.state = actor.FIGHTING
	
	if not is_instance_valid(actor.target) or actor.target == null or actor.is_scared():
		return SUCCESS
	
	if actor.can_eat_target():
		return SUCCESS
		
	return RUNNING
