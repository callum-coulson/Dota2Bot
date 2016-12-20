--[[
    StateMachine is a table
    the key "STATE" stores the STATE of Lina
    other key value pairs: key is the string of state value is the function of the State.
    each frame DOTA2 will call Think()
    Then Think() will call the function of current state.
]]

ValveAbilityUse = require(GetScriptDirectory().."/rattletrap/ability_item_usage_rattletrap");

STATE_IDLE = "STATE_IDLE";
STATE_ATTACKING_CREEP = "STATE_ATTACKING_CREEP";
STATE_KILL = "STATE_KILL";
STATE_RETREAT = "STATE_RETREAT";
STATE_FARMING = "STATE_FARMING";
STATE_GOTO_COMFORT_POINT = "STATE_GOTO_COMFORT_POINT";
STATE_FIGHTING = "STATE_FIGHTING";
STATE_RUN_AWAY_FROM_TOWER = "STATE_RUN_AWAY_FROM_TOWER";

RetreatHPThreshold = 0.3;
RetreatMPThreshold = 0.2;

STATE = STATE_IDLE;






function StateIdle(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        return;
    end
	local abilityHook = npcBot:GetAbilityByName( "rattletrap_hookshot" )

    local creeps = npcBot:GetNearbyCreeps(800,true);
    local pt = GetComfortPoint(creeps);

    local ShouldFight = false;

    local NearbyEnemyHeroes = npcBot:GetNearbyHeroes( 1500, true, BOT_MODE_NONE );
    if(NearbyEnemyHeroes ~= nil) then
        for _,npcEnemy in pairs( NearbyEnemyHeroes )
        do
            if(npcBot:WasRecentlyDamagedByHero(npcEnemy,1)) then
                -- got the enemy who attacks me, kill him!--
                EnemyToKill = npcEnemy;
                ShouldFight = true;
                break;
            elseif(GetUnitToUnitDistance(npcBot,npcEnemy) < 400) then
                EnemyToKill = npcEnemy;
                ShouldFight = true;
				break;
			elseif(GetUnitToUnitDistance(npcBot,npcEnemy) > 400 and abilityHook:GetCooldownTimeRemaining() == 0 ) then
                EnemyToKill = npcEnemy;
                ShouldFight = true;
                break;
            end
        end
    end

    if(ShouldRetreat()) then
        StateMachine.State = STATE_RETREAT;
        return;
    elseif(npcBot:GetAttackTarget() ~= nil) then
        if(npcBot:GetAttackTarget():IsHero()) then
            EnemyToKill = npcBot:GetAttackTarget();
            print("auto attacking: "..npcBot:GetAttackTarget():GetUnitName());
            StateMachine.State = STATE_FIGHTING;
            return;
        end
    elseif(ShouldFight) then
        StateMachine.State = STATE_FIGHTING;
        return;
    elseif(#creeps > 0 and pt ~= nil) then
        local mypos = npcBot:GetLocation();

        local d = GetUnitToLocationDistance(npcBot,pt);
        if(d > 200) then
            StateMachine.State = STATE_GOTO_COMFORT_POINT;
        else
            StateMachine.State = STATE_ATTACKING_CREEP;
        end
        return;
    end

    local NearbyTowers = npcBot:GetNearbyTowers(1000,true);
    if(#NearbyTowers > 0) then
        target = GetLocationAlongLane(2,0);
        npcBot:Action_MoveToLocation(target);
    else
        target = GetLocationAlongLane(2,0.95);
        npcBot:Action_AttackMove(target);
    end


end

function StateAttackingCreep(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    local creeps = npcBot:GetNearbyCreeps(800,true);
	local friend_creeps = npcBot:GetNearbyCreeps(300,false);
	local fcreeps = #friend_creeps;
	local ecreeps = #creeps;
    local pt = GetComfortPoint(creeps);
	local abilityHook = npcBot:GetAbilityByName( "rattletrap_hookshot" )
    local ShouldFight = false;

    local NearbyEnemyHeroes = npcBot:GetNearbyHeroes( 1500, true, BOT_MODE_NONE );
    if(NearbyEnemyHeroes ~= nil) then
        for _,npcEnemy in pairs( NearbyEnemyHeroes )
        do
            if(npcBot:WasRecentlyDamagedByHero(npcEnemy,1)) then
                -- got the enemy who attacks me, kill him!--
                EnemyToKill = npcEnemy;
                ShouldFight = true;
                break;
            elseif(GetUnitToUnitDistance(npcBot,npcEnemy) < 400) then
                EnemyToKill = npcEnemy;
                ShouldFight = true;
                break;
			elseif(GetUnitToUnitDistance(npcBot,npcEnemy) > 400 and abilityHook:GetCooldownTimeRemaining() == 0 ) then
                EnemyToKill = npcEnemy;
                ShouldFight = true;
                break;
            end
        end
    end


    if(ShouldRetreat()) then
        StateMachine.State = STATE_RETREAT;
        return;
    elseif(ShouldFight) then
        StateMachine.State = STATE_FIGHTING;
        return;
    elseif(#creeps > 0 and pt ~= nil) then
        local mypos = npcBot:GetLocation();
        local d = GetUnitToLocationDistance(npcBot,pt);
        if(d > 200 and ecreeps > 1 and fcreeps <2) then
            StateMachine.State = STATE_GOTO_COMFORT_POINT;
        else

            ConsiderAttackCreeps(creeps);
        end
        return;
    else
        StateMachine.State = STATE_IDLE;
        return;
    end
end

function StateRetreat(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    --[[
            I don't know how to Create a object of Location so I borrow one from GetLocation()
            Got Vector from marko.polo at http://dev.dota2.com/showthread.php?t=274301
    ]]
    home_pos = Vector(-7000,-7000);
    npcBot:Action_MoveToLocation(home_pos);

    if(npcBot:GetHealth() == npcBot:GetMaxHealth() and npcBot:GetMana() == npcBot:GetMaxMana()) then
        StateMachine.State = STATE_IDLE;
        return;
    end
end


function StateGotoComfortPoint(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    local creeps = npcBot:GetNearbyCreeps(800,true);
	local friend_creeps = npcBot:GetNearbyCreeps(300,false);
	local fcreeps = #friend_creeps;
	local ecreeps = #creeps;
    local pt = GetComfortPoint(creeps);

    if(ShouldRetreat()) then
        StateMachine.State = STATE_RETREAT;
        return;
    elseif(#creeps > 0 and pt ~= nil) then
        local mypos = npcBot:GetLocation();

        local d = GetUnitToLocationDistance(npcBot,pt);
        if(d > 200 and ecreeps > 1 and fcreeps <2) then
            --print("mypos "..mypos[1]..mypos[2]);
            --print("comfort_pt "..pt[1]..pt[2]);
            npcBot:Action_MoveToLocation(pt);
        else
            StateMachine.State = STATE_ATTACKING_CREEP;
        end
        return;
    else
        StateMachine.State = STATE_IDLE;
        return;
    end

end

function StateFighting(StateMachine)
    local npcBot = GetBot();

    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    if(not EnemyToKill:CanBeSeen() or not EnemyToKill:IsAlive()) then
        -- lost enemy
        print("lost enemy");
        StateMachine.State = STATE_IDLE;
        return;
    else
        if ( npcBot:IsUsingAbility() ) then return end;

        local abilityBA = npcBot:GetAbilityByName( "rattletrap_battery_assault" );
        local abilityCog = npcBot:GetAbilityByName( "rattletrap_power_cogs" );
        local abilityRF = npcBot:GetAbilityByName( "rattletrap_rocket_flare" );
        local abilityHook = npcBot:GetAbilityByName( "rattletrap_hookshot" );
		local HookLevel = abilityHook:GetLevel();
		local HookSpeed = 4000;

		if HookLevel == 2 then
		HookSpeed = 5000;
		elseif HookLevel == 3 then
		HookSpeed = 6000;
		end

		local TimeForHook =(GetUnitToLocationDistance(npcBot, (((EnemyToKill:GetExtrapolatedLocation(1)) + EnemyToKill:GetLocation()))))/HookSpeed;
        local castBADesire, castBATarget = 0,EnemyToKill;
        local castCogDesire, castCogTarget = 0,EnemyToKill;
        local castRFDesire, castRFLocation = 0,EnemyToKill:GetLocation();
        local castHookDesire, castHookLocation = 0,EnemyToKill:GetLocation();


		if GetUnitToUnitDistance(npcBot,EnemyToKill) > 500  and abilityHook:IsFullyCastable()
        then

			if(CheckHookClearance(EnemyToKill) == 0) then
				LastEnemyToBeAttacked = nil;
				npcBot:Action_UseAbilityOnLocation( abilityHook, EnemyToKill:GetLocation()+(EnemyToKill:GetExtrapolatedLocation(1)*TimeForHook));
				return;
			end
        end

		if GetUnitToUnitDistance(npcBot,EnemyToKill) < 200 and abilityCog:IsFullyCastable()
        then
            LastEnemyToBeAttacked = nil;
			npcBot:Action_MoveToLocation(EnemyToKill:GetLocation());
				npcBot:Action_UseAbility( abilityCog );

            return;
        end

		if  GetUnitToUnitDistance(npcBot,EnemyToKill) < 200 and abilityCog:GetCooldownTimeRemaining() > 0 and abilityBA:IsFullyCastable() then
		    LastEnemyToBeAttacked = nil;
			npcBot:Action_UseAbility( abilityBA );
			return
		end

        if ( castRFDesire > 0 )
        then
            LastEnemyToBeAttacked = nil;
            npcBot:Action_UseAbilityOnLocation( abilityRF, castRFLocation );
			castRFDesire = 0;
            return;
        end



        --print("desires: " .. castLBDesire .. " " .. castLSADesire .. " " .. castDSDesire);

        if(npcBot:GetAttackTarget() ~= EnemyToKill) then
            npcBot:Action_AttackUnit(EnemyToKill,false);
        end

    end
end

-- useless now ignore it
function StateFarming(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end
end

StateMachine = {};
StateMachine["State"] = STATE_IDLE;
StateMachine[STATE_IDLE] = StateIdle;
StateMachine[STATE_ATTACKING_CREEP] = StateAttackingCreep;
StateMachine[STATE_RETREAT] = StateRetreat;
StateMachine[STATE_GOTO_COMFORT_POINT] = StateGotoComfortPoint;
StateMachine[STATE_FIGHTING] = StateFighting;

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

function ConsiderRFCreeps(creeps)
    local npcBot = GetBot();

    -- Check if we're already using an ability
	if ( npcBot:IsUsingAbility() ) then return end;

        local abilityRF = npcBot:GetAbilityByName("rattletrap_rocket_flare");
		local mylocal = npcBot:GetLocation();
        local castRFDesire, castRFLocation = 0,creep_pos;

		local lowCreeps = 0;
		local done_creep = 0
		local RFdamage = abilityRF:GetAbilityDamage();
		for creep_k,creep in pairs(creeps)
		do
			local creep_name = creep:GetUnitName();
			if(creep:IsAlive()) then
				 local creep_hp = creep:GetHealth();
				 if(RFdamage > creep_hp) then
					castRFLocation = creep:GetLocation();
					checkOtherCreeps = creep:GetNearbyCreeps(500,true);
					lowCreeps = lowCreeps + 1;

				 end
			 end
		end
		if lowCreeps > 1 then
			castRFDesire = 1;
		end

        if ( castRFDesire > 0 )
        then
            LastEnemyToBeAttacked = nil;
            npcBot:Action_UseAbilityOnLocation( abilityRF, castRFLocation );
            return;
        end
end


function ConsiderAttackCreeps(creeps)
    -- there are creeps try to attack them --
    --print("ConsiderAttackCreeps");
    local npcBot = GetBot();

			local far_creeps = npcBot:GetNearbyCreeps(1500,true)
			ConsiderRFCreeps(far_creeps);

    -- Check if we're already using an ability

    --If we dont cast ability, just try to last hit.

    local lowest_hp = 100000;
    local weakest_creep = nil;
	rightClick = 1;
    for creep_k,creep in pairs(creeps)
    do


		local creep_name = creep:GetUnitName();
        -- "bad" means "dire" and "good" means "radian"
        local badpos = string.find( creep_name,"bad");
        if(creep:IsAlive() == false) then
            print("dead creep");
        end
        if(badpos ~= nil and creep:IsAlive()) then

             local creep_hp = creep:GetHealth();
             if(lowest_hp > creep_hp) then

                 lowest_hp = creep_hp;
                 weakest_creep = creep;
             end
         end
    end

    if(weakest_creep ~= nil) then

		local rightClick = npcBot:GetEstimatedDamageToTarget( true, weakest_creep, 1.0, DAMAGE_TYPE_PHYSICAL );


        -- if creep's hp is lower than 70(because I don't Know how much is my damadge!!), try to last hit it.
		creep_pos = weakest_creep:GetLocation();
		if(Attacking_creep ~= weakest_creep and lowest_hp < (rightClick*2)) then
		npcBot:Action_MoveToLocation(creep_pos)
		end
        if(Attacking_creep ~= weakest_creep and lowest_hp < (rightClick)) then
            Attacking_creep = weakest_creep;
            npcBot:Action_AttackUnit(Attacking_creep,true);
            StateMachine.State = STATE_ATTACKING_CREEP;
            return;
        end
        weakest_creep = nil;

    end

    -- nothing to do , try to attack heros

    local NearbyEnemyHeroes = npcBot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
    if(NearbyEnemyHeroes ~= nil) then
        for _,npcEnemy in pairs( NearbyEnemyHeroes )
        do
            if(npcBot:GetAttackTarget() ~= npcEnemy) then
                npcBot:Action_AttackUnit(npcEnemy,false);
                return;
            end
        end
    end

end

function GetComfortPoint(creeps)
    local npcBot = GetBot();
    local mypos = npcBot:GetLocation();
    local x_pos_sum = 0;
    local y_pos_sum = 0;
    local count = 0;
    for creep_k,creep in pairs(creeps)
    do
        local creep_name = creep:GetUnitName();
        local meleepos = string.find( creep_name,"melee");
        --if(meleepos ~= nil) then
        if(true) then
            creep_pos = creep:GetLocation();
            x_pos_sum = x_pos_sum + creep_pos[1];
            y_pos_sum = y_pos_sum + creep_pos[2];
            count = count + 1;
        end
    end

    local avg_pos_x = x_pos_sum / count;
    local avg_pos_y = y_pos_sum / count;

    if(count > 0) then
        -- I assume ComfortPoint is 600 from the avg point
        --print("avg_pos : " .. avg_pos_x .. " , " .. avg_pos_y);
        return Vector(avg_pos_x - 500 / 1.414,avg_pos_y - 500 / 1.414);
    else
        return nil;
    end;
end

function CheckHookClearance(EnemyToKill)
	local npcBot = GetBot();
	local AB = 0;
	local AC = 0;
	local BC = 0;
	local ABC = 0;
	local Heron_upper = nil;
	local Herons = nil;
	local EnemyPos = EnemyToKill:GetLocation();
	local Creep_Pos = nil;
	local FCreeps = npcBot:GetNearbyCreeps(800,false);
	local ECreeps = npcBot:GetNearbyCreeps(800,true);
	local FHeroes = npcBot:GetNearbyHeroes(800,false,0);
	local Clear = 0

	function JoinBlockTargets(FCreeps, ECreeps,FHeroes)
		for k,v in ipairs(ECreeps) do
		table.insert(FCreeps, v)
		print("Creep: ",v:GetUnitName())
		end
		return FCreeps
	end
	JoinBlockTargets(FCreeps,ECreeps,FHeroes);
	for creep_k,creep in pairs(FCreeps)
		do

			Creep_Pos = creep:GetLocation()
			--Get Distance from Bot-Foe
			AB = GetUnitToLocationDistance(npcBot,EnemyPos);

			--Get Distance from Bot-Creep
			AC = GetUnitToLocationDistance(npcBot,Creep_Pos);

			--Get Distance from Foe-Creep
			BC = GetUnitToLocationDistance(EnemyToKill,Creep_Pos);

			--get d [https://en.wikipedia.org/wiki/Heron's_formula]
			ABC = (AB + AC + BC)/2;

			--Do Upper portion of Herron's equation
			Heron_upper = 4*ABC*((ABC-AB)*(ABC-AC)*(ABC-BC));

			--Do rest of Herons
			Herons = Heron_upper/((AB)*(AB));
			HeronsSRT = math.sqrt(Herons);

			print("Herons: ",HeronsSRT);

			--check it its out of the way and if it's behind cancel that
			if HeronsSRT < 200  then
				Clear = Clear+1
				if BC > AB and AC < BC then
					Clear = Clear-1
				end

			end

	end
	print ("Clear: ",Clear);
	return Clear;
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

function ShouldRetreat()
    local npcBot = GetBot();
    return npcBot:GetHealth()/npcBot:GetMaxHealth()
    < RetreatHPThreshold or npcBot:GetMana()/npcBot:GetMaxMana()
    < RetreatMPThreshold;
end
