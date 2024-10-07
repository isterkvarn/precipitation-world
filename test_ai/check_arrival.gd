
class_name Roam extends ActionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	
	actor.state = actor.ROAMING

	return RUNNING
