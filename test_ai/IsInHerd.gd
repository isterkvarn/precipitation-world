class_name IsInHerd extends ConditionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	
	if not actor.is_in_herd():
		return SUCCESS
	else:
		return FAILURE
