
class_name HunterRoam extends ActionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	
	actor.state = actor.ROAMING

	return SUCCESS
