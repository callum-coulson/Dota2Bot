local r = {};

npcBot = GetBot();
AssLane = npcBot:GetAssignedLane()
abilityBA = npcBot:GetAbilityByName( "rattletrap_battery_assault" );
abilityCog = npcBot:GetAbilityByName( "rattletrap_power_cogs" );
abilityRF = npcBot:GetAbilityByName( "rattletrap_rocket_flare" );
abilityHook = npcBot:GetAbilityByName( "rattletrap_hookshot" );
Arrived = false;
OnTheMove = false;
CHealth = npcBot:GetHealth()
Ouch = 0;
submode_lane = 0;
local DistanceToLaneMarker = 0;
local LaneAdvance = 0.15;
local target = GetLocationAlongLane(AssLane,LaneAdvance);
local Time = DotaTime()

STATE_IDLE = "STATE_IDLE";
STATE_LANE = "STATE_LANE";
STATE_ATTACKING_CREEP = "STATE_ATTACKING_CREEP";
STATE_KILL = "STATE_KILL";
STATE_RETREAT = "STATE_RETREAT";
STATE_FARMING = "STATE_FARMING";
STATE_ROAMING = "STATE_ROAMING";
STATE_FIGHTING = "STATE_FIGHTING";
STATE_RUN_AWAY_FROM_TOWER = "STATE_RUN_AWAY_FROM_TOWER";
RetreatHPThreshold = 0.3;
RetreatMPThreshold = 0.2;
STATE = STATE_IDLE;

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
		end
		for k,v in ipairs(FHeroes) do
			table.insert(FCreeps, v)
		end
		return FCreeps
	end
	FCreeps = JoinBlockTargets(FCreeps,ECreeps,FHeroes);
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

local function ShouldRetreat()
    return npcBot:GetHealth()/npcBot:GetMaxHealth()
    < RetreatHPThreshold or npcBot:GetMana()/npcBot:GetMaxMana()
    < RetreatMPThreshold;
end

local function ConsiderRFCreeps(creeps)
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

function r.StateIdle(StateMachine)
    if(npcBot:IsAlive() == false) then
				Arrived = false;
        return;
    end
    if Time < 600 or npcBot:GetHeroLevel() < 8 then
      StateMachine.State = STATE_LANE;
      return;
    end
end
------lANING FUNCTIONS------
function r.StateLane(StateMachine)

	local creeps = npcBot:GetNearbyCreeps(500,true);
	local friend_creeps = npcBot:GetNearbyCreeps(500,false);
	local NearbyEnemyHeroes = npcBot:GetNearbyHeroes( 1500, true, BOT_MODE_NONE );
	CHealth = npcBot:GetHealth();
  if(npcBot:IsAlive() == false) then
      StateMachine.State = STATE_IDLE;
      return;
  end
	if npcBot:GetHealth() < (npcBot:GetMaxHealth()*RetreatHPThreshold) or npcBot:GetMana() < (npcBot:GetMaxMana()*RetreatMPThreshold) then
		StateMachine.State = STATE_RETREAT;
	end
	if npcBot:TimeSinceDamagedByAnyHero() < 1 then
		Ouch = Ouch + (CHealth - npcBot:GetHealth())/100;
		TakenHeroDamage()
	elseif CHealth > npcBot:GetHealth() then
		Ouch = Ouch + (CHealth - npcBot:GetHealth())/100
		for k,v in pairs(friend_creeps) do
				AggroDrop = v
		end
		npcBot:Action_AttackUnit(AggroDrop,true);
		npcBot:Action_ClearActions(true);
		TakenCreepDamage()
	end
  if(NearbyEnemyHeroes ~= nil) then
		Fighting(NearbyEnemyHeroes)
  end
	if Ouch < 0 then
		---Creep laning
		if Time < 0 then

			if submode_lane ~= 1 then
				print("Going To lane")
			end
			submode_lane = 1;
			GetToLane()
		elseif #friend_creeps < 2 and #creeps > 0 then
			if submode_lane ~= 2 then
				print("RetreatFromCreeps")
			end
			submode_lane = 2;
			RetreatFromCreeps();
		elseif #friend_creeps > 0 and #creeps > 0 then
			if submode_lane ~= 3 then
				print("ConsiderAttackCreeps")
			end
			submode_lane = 3;
			ConsiderAttackCreeps(creeps,friend_creeps);
	  elseif #friend_creeps > 0 and #creeps == 0 then
			if submode_lane ~= 4 then
				print("FollowCreepsIn")
			end
			submode_lane = 4;
	    FollowCreepsIn(friend_creeps)
		elseif Time > 0 and  #friend_creeps == 0 and #creeps == 0 then
			if submode_lane ~= 5 then
				print("MoveUpLane")
			end
			submode_lane = 5;
			MoveUpLane();
		else
			if submode_lane ~= 6 then
				print("I'M CONFUSED WHAT TO DO");
			end
			submode_lane = 6;
	  end
	else
		---ow that hurt
		print("Ouch! - ",Ouch)
		Ouch = Ouch - 0.05;
	end

end
------lANING SUBFUNCTIONS------
function GetToLane()

	target = GetLocationAlongLane(AssLane,0.1)
  npcBot:Action_MoveToLocation(target);
  return true;
end

function FollowCreepsIn(friend_creeps)
  for k,fcreep in pairs(friend_creeps) do
    if fcreeppos == nil then
        fcreeppos = fcreep:GetLocation();
    else
      fcreeppos = fcreeppos + fcreep:GetLocation();
    end
  end
  AveragePos = (fcreeppos / #friend_creeps);
  fcreeppos = nil;
  npcBot:Action_MoveToLocation(AveragePos);
  return true;
end

function RetreatFromCreeps()
	local RetreatBackPos = GetLocationAlongLane(AssLane,0)
	print(OnTheMove)
	print(GetUnitToLocationDistance(npcBot,RetreatBackPos))

	if OnTheMove == false then
		LaneAdvance = LaneAdvance - 0.01;
		OnTheMove = true;
	end
	npcBot:Action_MoveToLocation(RetreatBackPos);

	if GetUnitToLocationDistance(npcBot,RetreatBackPos) < 200 then
		OnTheMove = false;
	end
end

function MoveUpLane()
	local NearbyTowers = npcBot:GetNearbyTowers(1100,true);
	--local TowerName = nil;
	local AdvanceForwardPos = GetLocationAlongLane(AssLane,LaneAdvance)
	if Time == 0 then
		LaneAdvance = 0.35
	end
	if #NearbyTowers > 0 then
		for k,v in pairs(NearbyTowers) do
			TowerName = v:GetUnitName()
			LaneAdvance = LaneAdvance - 0.01;
		end
	end


	if --[[TowerName ~= nil and]] OnTheMove == false then
		LaneAdvance = LaneAdvance + 0.01;

		OnTheMove = true;
	end
	if GetUnitToLocationDistance(npcBot,AdvanceForwardPos) < 200 then
		OnTheMove = false;
	end
	npcBot:Action_MoveToLocation(AdvanceForwardPos);
end

function TakenCreepDamage()
	local RetreatPos = GetLocationAlongLane(AssLane,0)
	npcBot:Action_MoveToLocation(RetreatPos);

end

function TakenHeroDamage()
	local RetreatPos = GetLocationAlongLane(AssLane,0)
	npcBot:Action_MoveToLocation(RetreatPos);

end

function Fighting(NearbyEnemyHeroes)
	for _,npcEnemy in pairs( NearbyEnemyHeroes ) do
		local CanIBurst = npcBot:GetEstimatedDamageToTarget(true,npcEnemy,5, DAMAGE_TYPE_MAGICAL )
		local CanIBurst = CanIBurst + npcBot:GetEstimatedDamageToTarget(true,npcEnemy,5, DAMAGE_TYPE_PHYSICAL )
		local EnemyNearTower = #npcEnemy:GetNearbyTowers(1200,true)
		--print("CanIBurst? - ",CanIBurst)
		if EnemyNearTower == 0 and CanIBurst > npcEnemy:GetHealth() and npcEnemy:CanBeSeen() == true then
			if(GetUnitToUnitDistance(npcBot,npcEnemy) < 600) then
				EnemyToKill = npcEnemy;
				ShouldFight = true;
				StateMachine.State = STATE_FIGHTING;
				break;
			elseif GetUnitToUnitDistance(npcBot,npcEnemy) > 300 and abilityHook:IsFullyCastable() then
				EnemyToKill = npcEnemy;
				ShouldFight = true;
				StateMachine.State = STATE_FIGHTING;
				break;
			end
		end
	end
end

function ConsiderAttackCreeps(creeps,fcreeps)
    local lowest_hp = 1000;
    local weakest_creep = nil;
    for creep_k,creep in pairs(creeps) do
        if(creep:IsAlive()) then
             local creep_hp = creep:GetHealth();
             if(lowest_hp > creep_hp) then
                 lowest_hp = creep_hp;
                 weakest_creep = creep;
             end
         end
    end
    if(weakest_creep ~= nil) then
			local rightClick = npcBot:GetEstimatedDamageToTarget( true, weakest_creep, 1.4, DAMAGE_TYPE_PHYSICAL );
			if lowest_hp > (rightClick*2.5) then
				for k,fcreep in pairs(fcreeps) do
			    if fcreeppos == nil then
			        fcreeppos = fcreep:GetLocation();
			    else
			      fcreeppos = fcreeppos + fcreep:GetLocation();
			    end
			  end
			  AveragePos = (fcreeppos / #fcreeps);
				fcreeppos = nil;
				npcBot:Action_MoveToLocation(AveragePos);
			elseif lowest_hp < (rightClick*2.5) then
					local weakest_creep_pos = weakest_creep:GetLocation();
					npcBot:Action_MoveToLocation(weakest_creep_pos)
				end
        if lowest_hp < (rightClick) then
            npcBot:Action_AttackUnit(weakest_creep,true);
            return;
        end
        weakest_creep = nil;
    end
end

----------------------------


function r.StateRetreat(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

		if MyTeam == 2  then
    	home_pos = Vector(-7000,-7000);
		elseif MyTeam == 3 then
			home_pos = Vector(7000,7000);
		end
    npcBot:Action_MoveToLocation(home_pos);
    if(npcBot:GetHealth() == npcBot:GetMaxHealth() and npcBot:GetMana() == npcBot:GetMaxMana()) then
        StateMachine.State = STATE_IDLE;
        return;
    end
end

function r.StateFighting(StateMachine)
	local HookLevel = abilityHook:GetLevel();
	local HookSpeed = 4000;
	local castBADesire, castBATarget = 0,EnemyToKill;
	local castCogDesire, castCogTarget = 0,EnemyToKill;
	local castRFDesire, castRFLocation = 0,EnemyToKill:GetLocation();
	local castHookDesire, castHookLocation = 0,EnemyToKill:GetLocation();
	if HookLevel == 2 then
	HookSpeed = 5000;
	elseif HookLevel == 3 then
	HookSpeed = 6000;
	end
	local TimeForHook =(GetUnitToLocationDistance(npcBot, (((EnemyToKill:GetExtrapolatedLocation(1)) + EnemyToKill:GetLocation()))))/HookSpeed;

  if(npcBot:IsAlive() == false) then
      StateMachine.State = STATE_IDLE;
      return;
  end
  if(not EnemyToKill:CanBeSeen() or not EnemyToKill:IsAlive()) then
      print("lost enemy");
			npcBot:Action_MoveToLocation(EnemyToKill:GetLastSeenLocation());
			if GetUnitToLocationDistance(npcBot,EnemyToKill:GetLastSeenLocation()) <80 then
      	StateMachine.State = STATE_IDLE;
			end
      return;
  else
    if ( npcBot:IsUsingAbility() ) then return end;
		if GetUnitToUnitDistance(npcBot,EnemyToKill) > 300  and abilityHook:IsFullyCastable() then
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
		elseif abilityBA:IsFullyCastable() == true and abilityCog:IsFullyCastable() == false then
			LastEnemyToBeAttacked = nil;
			npcBot:Action_UseAbility( abilityBA );
		end
    if ( castRFDesire > 0 )
        then
            LastEnemyToBeAttacked = nil;
            npcBot:Action_UseAbilityOnLocation( abilityRF, castRFLocation );
			castRFDesire = 0;
            return;
        end
        if(npcBot:GetAttackTarget() ~= EnemyToKill) then
            npcBot:Action_AttackUnit(EnemyToKill,false);
        end

    end
end

function r.StateRoaming(StateMachine)



end

-- useless now ignore it
function r.StateFarming(StateMachine)
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end
end
return r;
