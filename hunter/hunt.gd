
class_name Hunt extends ActionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	
	if actor.ses_food():

		return SUCCESS
	else: 
		actor.state = actor.HUNTING
		return RUNNING
	
