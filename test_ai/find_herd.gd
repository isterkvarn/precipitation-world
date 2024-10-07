
class_name FindHerd extends ActionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	
	actor.state = actor.FIND_HERD
	
	return SUCCESS
	
