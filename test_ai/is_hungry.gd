class_name IshUNGRY extends ConditionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	
	if actor.is_hungry():
		return SUCCESS
	else:
		return FAILURE
