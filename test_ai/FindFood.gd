
class_name FindFood extends ActionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	actor.state = actor.FIND_FOOD
	
	return SUCCESS
