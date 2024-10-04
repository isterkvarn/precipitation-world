class_name IsScaredLeaf extends ConditionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	
	actor.check_danger()
	if actor.is_scared():
		return SUCCESS
	else:
		return FAILURE
