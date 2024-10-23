class_name ShouldFight extends ConditionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	
	if actor.is_scared():
		return FAILURE
	
	# Make decision to either fight or flee
	var is_in_territory = actor.is_in_own_territory() 
	
	if ((is_in_territory and actor.is_defensive()) or 
		(not is_in_territory and actor.is_intrusive())) and not actor.is_hurt():
		
		return SUCCESS
	
	actor.give_scared()
	return FAILURE
