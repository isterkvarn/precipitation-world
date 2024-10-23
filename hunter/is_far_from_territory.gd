class_name IsFarFromTerritory extends ConditionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	
	if actor.is_far_from_territory() or (actor.in_other_territory() and not actor.is_intrusive()):
		return SUCCESS
	
	return RUNNING
