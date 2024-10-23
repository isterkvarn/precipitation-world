
class_name Fight extends ActionLeaf

func tick(actor:Node, _blackboard:Blackboard) -> int:
	
	actor.state = actor.ATTACKING
	
	if not is_instance_valid(actor.target) or actor.target == null or actor.is_scared():
		return SUCCESS
		
	actor.attack_target()
		
	return SUCCESS
