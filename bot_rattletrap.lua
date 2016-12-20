--[[
    StateMachine is a table
    the key "STATE" stores the STATE of Lina
    other key value pairs: key is the string of state value is the function of the State.
    each frame DOTA2 will call Think()
    Then Think() will call the function of current state.
]]

ValveAbilityUse = require(GetScriptDirectory().."/rattletrap/ability_item_usage_rattletrap");
state_desires = require(GetScriptDirectory().."/state_desires");


AbilityPriority = {
	"rattletrap_hookshot",
	"rattletrap_battery_assault",
	"rattletrap_power_cogs",
	"rattletrap_rocket_flare"
};

function ThinkLvlupAbility()
    -- Is there a bug? http://dev.dota2.com/showthread.php?t=274436
    local npcBot = GetBot();
    --[[
        npcBot:Action_LevelAbility("lina_laguna_blade");
    npcBot:Action_LevelAbility("lina_dragon_slave");
    npcBot:Action_LevelAbility("lina_light_strike_array");
    npcBot:Action_LevelAbility("lina_fiery_soul");
    ]]

    for _,AbilityName in pairs(AbilityPriority)
    do
        -- USELESS BREAK : because valve does not check ability points
        if TryToUpgradeAbility(AbilityName) then
            break;
        end
    end
end

PrevState = "none";
local done = 0;

StateMachine = {};
StateMachine["State"] = STATE_IDLE;
StateMachine[STATE_IDLE] = state_desires.StateIdle;
StateMachine[STATE_ATTACKING_CREEP] = state_desires.StateAttackingCreep;
StateMachine[STATE_RETREAT] = state_desires.StateRetreat;
StateMachine[STATE_GOTO_COMFORT_POINT] = state_desires.StateGotoComfortPoint;
StateMachine[STATE_FIGHTING] = state_desires.StateFighting;

function Think()
    local npcBot = GetBot();
    local ItemPurchase = require(GetScriptDirectory().."/rattletrap/item_purchase_rattletrap");

	   MyTeam = GetTeam();
    --print(GetLocationAlongLane(2,0.9));
    ThinkLvlupAbility();

    StateMachine[StateMachine.State](StateMachine);
    if(PrevState ~= StateMachine.State) then
        print("STATE: "..StateMachine.State);
        PrevState = StateMachine.State;
    end
	CheckEnemyHeroes();
  ItemPurchase.ItemPurchaseThink(true);
end

totalLevelOfAbilities = 0;
function TryToUpgradeAbility(AbilityName)
    local npcBot = GetBot();
    local ability = npcBot:GetAbilityByName(AbilityName);
    if ability:CanAbilityBeUpgraded() then
		if totalLevelOfAbilities < npcBot:GetHeroLevel() then
        ability:UpgradeAbility();
		totalLevelOfAbilities = totalLevelOfAbilities + 1;
		print(npcBot:GetHeroLevel());
        return true;
		end
    end
    return false;
end

function CDOTA_Bot_Script:GetHeroLevel()
  local respawnTable = {8, 10, 12, 14, 16, 26, 28, 30, 32, 34, 36, 46, 48, 50, 52, 54, 56, 66, 70, 74, 78,  82, 86, 90, 100};
  local nRespawnTime = self:GetRespawnTime() +1 -- It gives 1 second lower values.
  for k,v in pairs (respawnTable) do
        if v == nRespawnTime then
        return k
        end
    end
end

-- How to get iTree handles?
function IsItemAvailable(item_name)
    local npcBot = GetBot();
    -- query item code by Hewdraw
    for i = 0, 5, 1 do
        local item = hero:GetItemInSlot(i);
        if(item and item:IsFullyCastable() and item:GetName() == item_name) then
            return item;
        end
    end
    return nil;
end


function CheckEnemyHeroes()
    local npcBot = GetBot();
	local their_team = nil;
	local abilityRF = npcBot:GetAbilityByName( "rattletrap_rocket_flare" );
	local EnemyHP = nil;
	local CanSee = nil;
	local Predicted_Damage = nil;
	Hero = nil;

	if MyTeam == 2 then
		their_team = 3;
	elseif MyTeam == 3 then
		their_team = 2;
	end
	for i = 1, 5 do
		Hero = GetTeamMember( their_team, i )
		CanSee = Hero:CanBeSeen();
		--print(CanSee);

		EnemyHP = Hero:GetHealth();
		--print(EnemyHP);

		TimeForRocket =(GetUnitToLocationDistance(npcBot, (((Hero:GetExtrapolatedLocation(1)) + Hero:GetLocation()))))/1750;

		--print (TimeForRocket);

		Predicted_Damage = Hero:GetActualDamage(abilityRF:GetAbilityDamage(),abilityRF:GetDamageType())
		--print("Damage: ",Predicted_Damage)

		if EnemyHP < Predicted_Damage and abilityRF:IsFullyCastable() and EnemyHP > 0 then
			npcBot:Action_UseAbilityOnLocation( abilityRF, ((Hero:GetExtrapolatedLocation(1))*TimeForRocket + Hero:GetLocation()));
		end



		if CanSee == true then
			DebugDrawCircle(((Hero:GetExtrapolatedLocation(1))*TimeForRocket + Hero:GetLocation()), 50, 255, 255, 255 );
		end
	end

	return;
end
