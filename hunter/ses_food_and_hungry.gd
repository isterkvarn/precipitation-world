class_name SesFoodAndHungry extends ConditionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	
	if (actor.is_hungry() and actor.ses_food()):
		return SUCCESS
		
	return FAILURE
