
class_name FindFood extends ActionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	
	if actor.ses_food():
		return SUCCESS
	else: 
		actor.state = actor.FIND_FOOD
		return RUNNING
	
