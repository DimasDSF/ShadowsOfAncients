if SOA == nil then
	SOA = class({})
end

require('libraries/timers')

function Precache( ctx )
	--Precaching Custom Ability sounds (and all used heros' sounds :fp:)
	
	--PrecacheUnitByNameSync("npc_dota_hero_wisp", ctx)
	
	--Warning! Hero Names should be in internal format ex. OD is obsidian_destroyer
	local herosoundprecachelist = {
		"sniper"
	}
	
	for i=1,#herosoundprecachelist do
		PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_"..herosoundprecachelist[i]..".vsndevts", ctx)
	end
	
end

function Activate()
	GameRules.SOA = SOA()
	GameRules.SOA:Init()
end

function SOA:Init()
	
	--LinkLuaModifier("modifier_vgmar_util_dominator_ability_purger", "abilities/util/modifiers/modifier_vgmar_util_dominator_ability_purger.lua", LUA_MODIFIER_MOTION_NONE)
	
	self.mode = GameRules:GetGameModeEntity()
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, RADIANT_TEAM_MAX_PLAYERS)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, DIRE_TEAM_MAX_PLAYERS)
	GameRules:SetStrategyTime( 0.0 )
	GameRules:SetShowcaseTime( 0.0 )
	GameRules:SetCustomGameSetupAutoLaunchDelay( 5 )
	--GameRules:SetRuneSpawnTime(RUNE_SPAWN_TIME)
	--GameRules:SetRuneMinimapIconScale( 1 )
	self.mode:SetRecommendedItemsDisabled(true)
	GameRules:GetGameModeEntity():SetBotThinkingEnabled(false)
	self.mode:SetRuneEnabled( DOTA_RUNE_DOUBLEDAMAGE, false )
	self.mode:SetRuneEnabled( DOTA_RUNE_HASTE, false )
	self.mode:SetRuneEnabled( DOTA_RUNE_ILLUSION, false )
	self.mode:SetRuneEnabled( DOTA_RUNE_INVISIBILITY, false )
	self.mode:SetRuneEnabled( DOTA_RUNE_REGENERATION, false )
	self.mode:SetRuneEnabled( DOTA_RUNE_ARCANE, false )
	self.mode:SetRuneEnabled( DOTA_RUNE_BOUNTY, false )
	self.mode:SetRuneSpawnFilter( Dynamic_Wrap( SOA, "FilterRuneSpawn" ), self )
	self.mode:SetExecuteOrderFilter( Dynamic_Wrap( SOA, "ExecuteOrderFilter" ), self )
	self.mode:SetDamageFilter( Dynamic_Wrap( SOA, "FilterDamage" ), self )
	--self.mode:SetModifierGainedFilter( Dynamic_Wrap( VGMAR, "FilterModifierGained" ), self)
	self.mode:SetModifyExperienceFilter( Dynamic_Wrap( SOA, "FilterExperienceGained" ), self)

	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( SOA, "OnNPCSpawned" ), self )
	ListenToGameEvent( "dota_player_learned_ability", Dynamic_Wrap( SOA, "OnPlayerLearnedAbility" ), self)
	ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( SOA, 'OnGameStateChanged' ), self )
	--ListenToGameEvent( "dota_item_picked_up", Dynamic_Wrap( VGMAR, 'OnItemPickedUp' ), self )
	--ListenToGameEvent( "dota_tower_kill", Dynamic_Wrap( SOA, 'OnTowerKilled' ), self )
	--ListenToGameEvent( "dota_player_used_ability", Dynamic_Wrap( VGMAR, 'OnPlayerUsedAbility' ), self )
	Convars:RegisterConvar('soa_devmode', "0", "Set to 1 to show debug info.  Set to 0 to disable.", 0)
	--[[Convars:RegisterConvar('vgmar_blockbotcontrol', "1", "Set to 0 to enable controlling bots", 0)
	Convars:RegisterConvar('vgmar_enablecompanion_fullcontrol', "0", "Set to 1 to enable controlling a companion", 0)--]]
	--Convars:RegisterCommand('soa_reload_test_modifier', Dynamic_Wrap( SOA, "ReloadTestModifier" ), "Reload script modifier", 0)
	
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, 0.25 )
end

function dprint(...)
	if Convars:GetInt("soa_devmode") == 1 then
		print(...)
	end
end

function SOA:DisplayClientError(pid, message)
    local player = PlayerResource:GetPlayer(pid)
    if player then
        CustomGameEventManager:Send_ServerToPlayer(player, "SOADisplayError", {message=message})
    end
end

function SOA:FilterRuneSpawn( filterTable )
	filterTable.rune_type = DOTA_RUNE_INVALID
	return true
end

function SOA:FilterExperienceGained( filterTable )
	--DeepPrintTable( filterTable )
	--if self.playercompanionsnum[filterTable["player_id_const"]] ~= nil then
	--	filterTable["experience"] = filterTable["experience"] + filterTable["experience"] * (self.playercompanionsnum[filterTable["player_id_const"]] * 0.5)
	--end
	return true
end

--[[function VGMAR:FilterModifierGained( filterTable )
	local modifiername = filterTable["name_const"]
	local ability = nil
	if filterTable["entindex_ability_const"] then
		ability = EntIndexToHScript(filterTable.entindex_ability_const)
	end
	
	return true
end--]]

--##MOVETOINVLIB
--[[function VGMAR:HeroHasUsableItemInInventory( hero, item, mutedallowed, backpackallowed, stashallowed )
	if stashallowed ~= true and not hero:HasItemInInventory(item) then
		return false
	end
	local endslot = 8
	if stashallowed == true then
		endslot = 14
	end
	for i = 0, endslot do
		local slotitem = hero:GetItemInSlot(i);
		if slotitem then
			if slotitem:GetName() == item then
				if slotitem:IsMuted() and mutedallowed == true then
					if i <= 5 then
						return true
					elseif i >= 6 and i <= 8 and backpackallowed == true then
						return true
					elseif i >= 9 and stashallowed == true then
						return true
					else 
						return false
					end
				elseif not slotitem:IsMuted() then
					if i <= 5 then
						return true
					elseif i >= 6 and i <= 8 and backpackallowed == true then
						return true
					elseif i >= 9 and stashallowed == true then
						return true
					else 
						return false
					end
				else
					return false
				end
			end
		end
	end
end

function VGMAR:GetItemFromInventoryByName( hero, item, mutedallowed, backpackallowed, stashallowed )
	if stashallowed ~= true and not hero:HasItemInInventory(item) then
		return nil
	end
	local endslot = 8
	if stashallowed == true then
		endslot = 14
	end
	for i = 0, endslot do
		local slotitem = hero:GetItemInSlot(i);
		if slotitem then
			if slotitem:GetName() == item then
				if slotitem:IsMuted() and mutedallowed == true then
					if i <= 5 then
						return slotitem
					elseif i >= 6 and i <= 8 and backpackallowed == true then
						return slotitem
					elseif i >= 9 and stashallowed == true then
						return slotitem
					else 
						return nil
					end
				elseif not slotitem:IsMuted() then
					if i <= 5 then
						return slotitem
					elseif i >= 6 and i <= 8 and backpackallowed == true then
						return slotitem
					elseif i >= 9 and stashallowed == true then
						return slotitem
					else 
						return nil
					end
				else
					return nil
				end
			end
		end
	end
end

function VGMAR:GetItemSlotFromInventoryByItemName( hero, item, mutedallowed, backpackallowed, stashallowed )
	if stashallowed ~= true and not hero:HasItemInInventory(item) then
		return -1
	end
	local endslot = 8
	if stashallowed == true then
		endslot = 14
	end
	for i = 0, endslot do
		local slotitem = hero:GetItemInSlot(i);
		if slotitem then
			if slotitem:GetName() == item then
				if slotitem:IsMuted() and mutedallowed == true then
					if i <= 5 then
						return i
					elseif i >= 6 and i <= 8 and backpackallowed == true then
						return i
					elseif i >= 9 and stashallowed == true then
						return i
					else 
						return -1
					end
				elseif not slotitem:IsMuted() then
					if i <= 5 then
						return i
					elseif i >= 6 and i <= 8 and backpackallowed == true then
						return i
					elseif i >= 9 and stashallowed == true then
						return i
					else 
						return -1
					end
				else
					return -1
				end
			end
		end
	end
end

function VGMAR:CountUsableItemsInHeroInventory( hero, item, mutedallowed, backpackallowed, stashallowed )
	if stashallowed ~= true and not hero:HasItemInInventory(item) then
		return 0
	end
	local itemcount = 0
	local endslot = 8
	if stashallowed == true then
		endslot = 14
	end
	for i = 0, endslot do
		local slotitem = hero:GetItemInSlot(i);
		if slotitem then
			if slotitem:GetName() == item then
				if slotitem:IsMuted() and mutedallowed == true then
					if i <= 5 then
						itemcount = itemcount + 1
					elseif i >= 6 and i <= 8 and backpackallowed == true then
						itemcount = itemcount + 1
					elseif i >= 9 and stashallowed == true then
						itemcount = itemcount + 1
					end
				elseif not slotitem:IsMuted() then
					if i <= 5 then
						itemcount = itemcount + 1
					elseif i >= 6 and i <= 8 and backpackallowed == true then
						itemcount = itemcount + 1
					elseif i >= 9 and stashallowed == true then
						itemcount = itemcount + 1
					end
				end
			end
		end
	end
	return itemcount
end

function VGMAR:RemoveNItemsInInventory( hero, item, num )
	local removeditemsnum = 0
	for i = 0, 14 do
		local slotitem = hero:GetItemInSlot(i);
		if slotitem then
			if slotitem:GetName() == item and removeditemsnum < num then
				hero:RemoveItem(slotitem)
				removeditemsnum = removeditemsnum + 1
			elseif removeditemsnum >= num then
				break
			end
		end
	end
	return
end--]]

function SOA:TimeIsLaterThan( minute, second )
	local num = minute * 60 + second
	if GameRules:GetDOTATime(false, false) > num then
		return true
	else
		return false
	end
end

--##MOVETOINVLIB
--[[function VGMAR:HeroHasAllItemsFromListWMultiple( hero, itemlist, backpack )
	for i=1,#itemlist.itemnames do
		if self:CountUsableItemsInHeroInventory( hero, itemlist.itemnames[i], false, backpack, false) < itemlist.itemnum[i] then
			return false
		end
	end
	return true
end

function VGMAR:GetHeroFreeInventorySlots( hero, backpackallowed, stashallowed )
	local slotcount = 0
	local endslot = 8
	if stashallowed == true then
		endslot = 14
	end
	for i = 0, endslot, 1 do
		if hero:GetItemInSlot(i) == nil then
			if i <= 5 then
				slotcount = slotcount + 1
			elseif i >= 6 and i <= 8 and backpackallowed == true then
				slotcount = slotcount + 1
			elseif i >= 9 and stashallowed == true then
				slotcount = slotcount + 1
			end
		end
	end
	return slotcount
end--]]

--[[
function VGMAR:OnItemPickedUp(keys)
	local heroEntity = EntIndexToHScript(keys.HeroEntityIndex or keys.UnitEntityIndex)
	local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local itemname = keys.itemname
	
	if heroEntity:IsRealHero() and not heroEntity:IsCourier() then
	end
end
--]]

--[[function VGMAR:IsHeroBotControlled(hero)
	if hero ~= nil then
		local heroplayerID = hero:GetPlayerID()
		if PlayerResource:IsValidPlayer(heroplayerID) and PlayerResource:GetConnectionState(heroplayerID) == 1 then
			return true
		end
	end
	return false
end--]]

function SOA:OnThink()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, PlayerResource:GetPlayerCount())
		for playerID=0,PlayerResource:GetPlayerCount() do
			if PlayerResource:IsValidPlayer(playerID) and PlayerResource:GetConnectionState(playerID) == 2 then
				dprint("Valid Player found on slot:", playerID)
				dprint("Player Team is:", PlayerResource:GetTeam(playerID))
				if PlayerResource:GetTeam(playerID) ~= 2 then
					PlayerResource:SetCustomTeamAssignment(playerID, DOTA_TEAM_GOODGUYS)
				end
			end
		end
		GameRules:LockCustomGameSetupTeamAssignment(true)
	end
	--[[if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
	end
	if GameRules:State_Get() >= DOTA_GAMERULES_STATE_PRE_GAME then
		
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then		-- Safe guard catching any state that may exist beyond DOTA_GAMERULES_STATE_POST_GAME
		return nil
	end--]]
	return 1
end

function SOA:OnNPCSpawned( event )
	local spawnedUnit = EntIndexToHScript( event.entindex )
	if not spawnedUnit or spawnedUnit:GetClassname() == "npc_dota_thinker" or spawnedUnit:IsPhantom() then
		return
	end
end

--[[function VGMAR:OnPlayerUsedAbility( keys )
	local PlayerID = keys.PlayerID
	local ability = keys.abilityname
end--]]

function SOA:OnPlayerLearnedAbility( keys )
	local player = EntIndexToHScript(keys.player)
	local abilityname = keys.abilityname
	
	local playerhero = player:GetAssignedHero()
end

function SOA:FilterDamage( filterTable )
	--local victim_index = filterTable["entindex_victim_const"]
    --local attacker_index = filterTable["entindex_attacker_const"]
	if not filterTable["entindex_victim_const"] or not filterTable["entindex_attacker_const"] then
        return true
    end
	local victim = EntIndexToHScript(filterTable.entindex_victim_const)
	local attacker = EntIndexToHScript(filterTable.entindex_attacker_const)
	local damage = filterTable["damage"]

	return true
end

function SOA:ExecuteOrderFilter( filterTable )
	local order_type = filterTable.order_type
    local units = filterTable["units"]
    local issuer = filterTable["issuer_player_id_const"]
	local unit = nil
	if units["0"] ~= nil then
		unit = EntIndexToHScript(units["0"])
	end
    local ability = EntIndexToHScript(filterTable.entindex_ability)
    local target = EntIndexToHScript(filterTable.entindex_target)		
	
	--///////////////////////
	--SecondCourierPrevention
	--///////////////////////
	--[[if unit then
		if unit:IsRealHero() then
			
		end
	end--]]

	return true
end

function SOA:OnGameStateChanged( keys )
	local state = GameRules:State_Get()
	
	--if state == DOTA_GAMERULES_STATE_HERO_SELECTION then
	--[[elseif state == DOTA_GAMERULES_STATE_STRATEGY_TIME then
		local used_hero_name = "npc_dota_hero_dragon_knight"
		dprint("Checking players...")
		
		for playerID=0, DOTA_MAX_TEAM_PLAYERS do
			if PlayerResource:IsValidPlayer(playerID) then
				dprint("PlayedID:", playerID)
				
				if PlayerResource:GetTeam(playerID) == DOTA_TEAM_GOODGUYS then
					self.n_players_radiant = self.n_players_radiant + 1
				elseif PlayerResource:GetTeam(playerID) == DOTA_TEAM_BADGUYS then
					self.n_players_dire = self.n_players_dire + 1
				end

				-- Random heroes for people who have not picked
				if PlayerResource:HasSelectedHero(playerID) == false then
					dprint("Randoming hero for:", playerID)
					PlayerResource:GetPlayer(playerID):MakeRandomHeroSelection()
					dprint("Randomed:", PlayerResource:GetSelectedHeroName(playerID))
				end
				
				used_hero_name = PlayerResource:GetSelectedHeroName(playerID)
			end
		end
	--]]
	--[[elseif state == DOTA_GAMERULES_STATE_PRE_GAME then
	elseif state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
	end--]]
end
