
-- plugin.lua

-- Implements the main entrypoint for the plugin, as well as all the handling needed

-- Deathdrop plugin allows for a players inventory to be copied to a chest before death to remove some of the pain of long mining trips.

  -- To do: add functionality to make sure that the chest is not placed in lava/bedrock basically anywhere that would reneder the use of the plugin u and to check if
    -- the chest has enough slots to hold complete inventory.


function Initialize(Plugin)
	Plugin:SetName("GraveChest")
	Plugin:SetVersion(.1)

	--Hook into the HOOK_KILLING to see when something is going to die
    cPluginManager:AddHook(cPluginManager.HOOK_KILLING, OnKilling)
    -- let the user know our plugin is running
	LOG("Initialized " .. Plugin:GetName() .. " v." .. Plugin:GetVersion())
    -- let upstream know we started ok....not that we have a fail mode yet...
	return true
end

function OnKilling(Victim, Killer, TDI)
  -- In this function something is about to die and we need to figure out if its a player.
  if (Victim:IsPlayer()) then
    -- Ok so it is a player
    -- get the players items and copy them to a chest
    local Items    = cItems()
    local TESTVAR  = Victim:GetInventory()
	TESTVAR:CopyToItems(Items)
	-- get the diferent grids from the inventory to check if they are empty (if -1 they are empty)
	local InventoryGrid = Victim:GetInventory():GetInventoryGrid():GetLastUsedSlot()
	local HotbarGrid    = Victim:GetInventory():GetHotbarGrid():GetLastUsedSlot()
	local ArmorGrid     = Victim:GetInventory():GetArmorGrid():GetLastUsedSlot()
	-- Give a lighting bolt above to let the player know their stuff is saved
	Victim:GetWorld():CastThunderbolt(Victim:GetPosition().x, Victim:GetPosition().y, Victim:GetPosition().z);
	-- Check the sum of the grids
	if (InventoryGrid + HotbarGrid + ArmorGrid ~= -3) then
		-- Build the chest and check if the block is not air
		Victim:GetWorld():SetBlock(Victim:GetPosition().x, Victim:GetPosition().y +1, Victim:GetPosition().z, E_BLOCK_CHEST, E_META_CHEST_FACING_ZM)
		if (Victim:GetWorld():GetBlock(Victim:GetPosition().x +1,Victim:GetPosition().y +1, Victim:GetPosition().z) == E_BLOCK_AIR) then
			Victim:GetWorld():SetBlock(Victim:GetPosition().x +1,Victim:GetPosition().y +1, Victim:GetPosition().z, E_BLOCK_CHEST, E_META_CHEST_FACING_ZM)
		else
			Victim:GetWorld():SetBlock(Victim:GetPosition().x,Victim:GetPosition().y , Victim:GetPosition().z, E_BLOCK_CHEST, E_META_CHEST_FACING_ZM)
		end
		-- copy the items in the chest
		Victim:GetWorld():DoWithChestAt(
			Victim:GetPosition().x, (Victim:GetPosition().y +1), Victim:GetPosition().z,
			function(a_Chest)
				a_Chest:GetContents():AddItems(Items)
			end
		)
		if (Victim:GetWorld():GetBlock(Victim:GetPosition().x +1, Victim:GetPosition().y +1, Victim:GetPosition().z) == E_BLOCK_AIR) then
			Victim:GetWorld():DoWithChestAt(
				Victim:GetPosition().x +1, Victim:GetPosition().y +1, Victim:GetPosition().z,
				function(a_Chest)
					a_Chest:GetContents():AddItems(Items)
				end
			)
		else
			Victim:GetWorld():DoWithChestAt(
				Victim:GetPosition().x, Victim:GetPosition().y, Victim:GetPosition().z,
				function(a_Chest)
					a_Chest:GetContents():AddItems(Items)
				end
			)
		end
		-- Remove the items from the inventory so that when the player dies the system doesnt drop
		Victim:GetInventory():Clear()
		Victim:SendMessage(cChatColor.Yellow .. "[INFO] " .. cChatColor.White .. " Your items are stored in a chest")
	else
		Victim:SendMessage(cChatColor.Yellow .. "[INFO] " .. cChatColor.White .. " You don't have items in the inventory")
	end
  else
      -- This is a Mob which this plugin does not care about.
  end
  -- return false to let everyone know we good...I think...readup on this
  return false
  -- close up the program.
end
