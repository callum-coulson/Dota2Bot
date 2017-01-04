local npcBot = GetBot();
Target=nil;

function AbilityUsageThink()



	-- Check if we're already using an ability
	if ( npcBot:IsUsingAbility() ) then return end;



	wisp_overcharge = npcBot:GetAbilityByName( "wisp_overcharge" );
	wisp_relocate = npcBot:GetAbilityByName( "wisp_relocate" );
	wisp_spirits = npcBot:GetAbilityByName( "wisp_spirits" );
	wisp_spirits_in = npcBot:GetAbilityByName( "wisp_spirits_in" );
	wisp_spirits_out = npcBot:GetAbilityByName( "wisp_spirits_out" );
	wisp_tether = npcBot:GetAbilityByName( "wisp_tether" );
	wisp_tether_break = npcBot:GetAbilityByName( "wisp_tether_break" );
	special_bonus_unique_wisp = npcBot:GetAbilityByName("special_bonus_unique_wisp");
	--print("Special:",special_bonus_unique_wisp:GetSpecialValueInt("value"))

	if wisp_spirits:CanAbilityBeUpgraded() == true then
		--print(wisp_spirits:GetHeroLevelRequiredToUpgrade())
		npcBot:Action_LevelAbility("wisp_spirits");
	end

	-- Consider using each ability
	wisp_spirits_desire,Target = ConsiderSpirits();

	SpiritsIn,SpritsOut = ConsiderSpiritRange(Target);
	wisp_tether_desire, TetherTarget = ConsiderTether();
	wisp_overdrive_desire = ConsiderOvercharge();

	if ( wisp_spirits_desire > 0)
	then
		npcBot:Action_UseAbility( wisp_spirits );
		return;
	end
	if ( SpiritsIn == true)
	then
		npcBot:Action_UseAbility( wisp_spirits_in );
		return;
	end
	if ( SpritsOut == true)
	then
		npcBot:Action_UseAbility( wisp_spirits_out );
		return;
	end
end


function ConsiderSpirits()
	local Heroes = npcBot:GetNearbyHeroes(875,true,0);
	local DamageTypical = wisp_spirits:GetSpecialValueInt('hero_damage')*5*0.75
	for k,v in pairs(Heroes) do
		if v:GetHealth() < DamageTypical then
			if Target == nil then
			 Target = v;
			end
			print(target)
			return BOT_ACTION_DESIRE_HIGH,Target;
		end

	end

	return  BOT_ACTION_DESIRE_NONE;
end


function ConsiderSpiritRange(TargetToKill)
	local Current = special_bonus_unique_wisp:GetSpecialValueInt("value")
	local Heroes = npcBot:GetNearbyHeroes(1200,true,0);
	local Distance = npcBot:GetUnitToUnitDistance(TargetToKill)
	DistanceScaling = (Distance - 100)/775;
	if DistanceScaling > Current then
		return false,true
	elseif DistanceScaling < Current then
		return true,false
	end

end

function ConsiderTether()
end

function ConsiderOvercharge()
end
