
-- plugin.lua

-- Implements the main entrypoint for the plugin, as well as all the handling needed

-- Deathdrop plugin allows for a players inventory to be copied to a chest before death to remove some of the pain of long mining trips.

  -- TO DO
    -- If there is a chest next to the player death create a Trap Chest
	-- Create a config file to tweak some things
	-- Create a time limit to delete the chest, with time in config file
	-- Create a limit in the number of GraveChest a player can have, limit in config file
	-- Create a DB in SQLite
	-- Only the owner of the chest can open it, conf file
	-- Add in the config file one World where the plugin don't act


function Initialize(Plugin)
	Plugin:SetName("GraveChest")
	Plugin:SetVersion(.1)

	--Hook into the HOOK_KILLING to see when something is going to die
    cPluginManager:AddHook(cPluginManager.HOOK_KILLING, OnKilling)
    cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_BREAKING_BLOCK, OnPlayerBreakingBlock)
    -- Let the user know our plugin is running
	LOG("Initialized " .. Plugin:GetName() .. " v." .. Plugin:GetVersion())
    -- Let upstream know we started ok....not that we have a fail mode yet...
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
	local VictimPos     = Victim:GetPosition()
	-- Give a lighting bolt above to let the player know their stuff is saved
	Victim:GetWorld():CastThunderbolt(Victim:GetPosition().x, Victim:GetPosition().y, Victim:GetPosition().z);
	-- Check the sum of the grids
	if (InventoryGrid + HotbarGrid + ArmorGrid ~= -3) then
		-- Build the chest and check if the block is not air
		Victim:GetWorld():SetBlock(VictimPos.x, VictimPos.y +2, VictimPos.z, E_BLOCK_CHEST, E_META_CHEST_FACING_ZM)
		if (Victim:GetWorld():GetBlock(VictimPos.x +1,VictimPos.y +2, VictimPos.z) == E_BLOCK_AIR) then
			Victim:GetWorld():SetBlock(VictimPos.x +1,VictimPos.y +2, VictimPos.z, E_BLOCK_CHEST, E_META_CHEST_FACING_ZM)
		else
			Victim:GetWorld():SetBlock(VictimPos.x, VictimPos.y +1, VictimPos.z, E_BLOCK_CHEST, E_META_CHEST_FACING_ZM)
		end
		-- Copy the items in the chest
		Victim:GetWorld():DoWithChestAt(
			VictimPos.x, VictimPos.y +2, VictimPos.z,
			function(a_Chest)
				a_Chest:GetContents():AddItems(Items)
			end
		)
		if (Victim:GetWorld():GetBlock(VictimPos.x +1, VictimPos.y +2, VictimPos.z) == E_BLOCK_AIR) then
			Victim:GetWorld():DoWithChestAt(
				VictimPos.x +1, VictimPos.y +2, VictimPos.z,
				function(a_Chest)
					a_Chest:GetContents():AddItems(Items)
				end
			)
		else
			Victim:GetWorld():DoWithChestAt(
				VictimPos.x, VictimPos.y +1, VictimPos.z,
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

function OnPlayerBreakingBlock(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace, a_BlockType, a_BlockMeta)
	-- Check if the player is facing a chest
	if (a_BlockFace == BLOCK_FACE_NONE) then
		return false
	end
	-- Check if the player is breaking a chest
	local World = a_Player:GetWorld()
	local a_BlockMeta = World:GetBlockMeta(a_BlockX, a_BlockY, a_BlockZ)
	local a_BlockType = World:GetBlock(a_BlockX, a_BlockY, a_BlockZ)
	if (a_BlockType ~= E_BLOCK_CHEST) then
		return false
	end
	-- Change the block to Air to avoid the item drop of the chest
	World:SetBlock(a_BlockX, a_BlockY, a_BlockZ, E_BLOCK_AIR, 0)
end