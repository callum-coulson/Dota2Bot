StateMachine = {};
StateMachine["State"] = STATE_IDLE;
STATE = STATE_IDLE;

function think()

	local npcBot = GetBot();
	StateMachine[StateMachine.State](StateMachine);
	
	
end