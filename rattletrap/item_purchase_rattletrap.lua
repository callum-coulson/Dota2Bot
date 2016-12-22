if tableItemsToBuy == nil then

tableItemsToBuy = {
				"item_ring_of_protection",
				"item_stout_shield",
				"item_magic_stick",
				"item_circlet",
				"item_branches",
				"item_branches",
				"item_boots",
				"item_energy_booster",
				"item_staff_of_wizardry",
				"item_ring_of_regen",
				"item_sobi_mask",
				"item_recipe_force_staff",
				"item_point_booster",
				"item_staff_of_wizardry",
				"item_ogre_axe",
				"item_blade_of_alacrity",
				"item_mystic_staff",
				"item_ultimate_orb",
				"item_void_stone",
				"item_staff_of_wizardry",
				"item_wind_lace",
				"item_void_stone",
				"item_recipe_cyclone",
				"item_cyclone",
};
end
local r = {}
function r.ItemPurchaseThink()

	local npcBot = GetBot();

	if ( #tableItemsToBuy == 0 )
	then
		npcBot:SetNextItemPurchaseValue( 0 );
		return;
	end

	local sNextItem = tableItemsToBuy[1];

	npcBot:SetNextItemPurchaseValue( GetItemCost( sNextItem ) );

	if ( npcBot:GetGold() >= GetItemCost( sNextItem ) )
	then
		npcBot:Action_PurchaseItem( sNextItem );
		table.remove( tableItemsToBuy, 1 );
		npcBot:Action_CourierDeliver()
		return
	end
end
return r;
----------------------------------------------------------------------------------------------------
