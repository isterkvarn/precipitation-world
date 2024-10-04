
class_name NewWanderTarget extends ActionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	actor.new_random_roam_target()
	
	return SUCCESS
