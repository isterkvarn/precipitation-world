
class_name HunterFlee extends ActionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	
	actor.state = actor.FLEEING
	
	return SUCCESS
