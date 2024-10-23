
class_name NewRoamDirection extends ActionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	
	actor.new_roam_direction()

	return SUCCESS
