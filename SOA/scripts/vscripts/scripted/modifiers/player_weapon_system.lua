--Player weapon system

local weaponslist = {
			["item_weapon_ak"] = {attackspeed = 300, attackdamage = 120, maxrange = 400},
			["item_weapon_m4"] = {attackspeed = 300, attackdamage = 100, maxrange = 400},
			["item_weapon_awp"] = {attackspeed = -400, attackdamage = 300, maxrange = 700}
		}

modifier_player_weapon_system = class({})

-------------------------------------------

function modifier_player_weapon_system:IsHidden()
    return false
end

function modifier_player_weapon_system:IsDebuff()
	return false
end

function modifier_player_weapon_system:IsPurgable()
	return false
end

function modifier_player_weapon_system:IsPermanent()
	return true
end

function modifier_player_weapon_system:RemoveOnDeath()
	return false
end

-------------------------------------------

function modifier_player_weapon_system:OnCreated()
	if IsServer() then
		self:StartIntervalThink( 0.1 )
	end
end

function modifier_player_weapon_system:OnIntervalThink()
	local parent = self:GetParent()
	if parent:GetItemInSlot(0) ~= nil then
		local playerslot0item = parent:GetItemInSlot(0)
		if weaponslist[playerslot0item:GetName()] ~= nil then
			self.weapon = playerslot0item
		else
			self.weapon = nil
		end
	else
		self.weapon = nil
	end
	if self.weapon ~= nil and self.weapon:GetCurrentCharges() > 0 then
		self.disarmed = false
	else
		self.disarmed = true
	end
end

function modifier_player_weapon_system:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	}
 
	return funcs
end

function modifier_player_weapon_system:OnAttack( event )
	local parent = self:GetParent()
	
	if event.attacker == parent then
		if self.weapon ~= nil then
			if self.weapon:GetCurrentCharges() - 1 > 0 then
				self.weapon:SetCurrentCharges( self.weapon:GetCurrentCharges() - 1 )
			else
				self.weapon:SetCurrentCharges( 0 )
				self.disarmed = true
			end
		end
	end
end

function modifier_player_weapon_system:GetModifierBaseAttack_BonusDamage()
	if IsServer() and self.weapon ~= nil then
		return weaponslist[self.weapon:GetName()].attackdamage
	end
end

function modifier_player_weapon_system:GetModifierAttackRangeBonus()
	if IsServer() and self.weapon ~= nil then
		return weaponslist[self.weapon:GetName()].maxrange
	end
end

function modifier_player_weapon_system:GetModifierAttackSpeedBonus_Constant()
	if IsServer() and self.weapon ~= nil then
		return weaponslist[self.weapon:GetName()].attackspeed
	end
end

function modifier_player_weapon_system:CheckState()
	local state = {
	[MODIFIER_STATE_DISARMED] = self.disarmed,
	}
 
	return state
end