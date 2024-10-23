class_name IsThreatened extends ConditionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	
	if actor.is_scared() or (actor.ses_danger() and (not actor.target.is_scared() or not actor.target.is_in_own_territory())):
		return SUCCESS
		
	return FAILURE
