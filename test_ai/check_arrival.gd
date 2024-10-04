
class_name Roam extends ActionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	
	actor.state = actor.ROAMING
	
	if actor.has_arrived_navigation():
		return SUCCESS
	
	return RUNNING
