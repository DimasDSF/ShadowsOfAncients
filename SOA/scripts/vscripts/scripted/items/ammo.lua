local ammoweaponcompat = {
		["item_weapon_ak"] = "item_ammo_762",
		["item_weapon_m4"] = "item_ammo_542",
		["item_weapon_awp"] = "item_ammo_awp"
	}

item_ammo = class({})

function item_ammo:OnSpellStart()
	local caster = self:GetCaster()
	local weaponsystem = caster:FindModifierByName("modifier_player_weapon_system")
	local weapon = weaponsystem.weapon
	if weapon == nil or ammoweaponcompat[weapon:GetName()] ~= self:GetName() or (ammoweaponcompat[weapon:GetName()] == self:GetName() and weapon:GetCurrentCharges() == weapon:GetInitialCharges() ) then
		caster:Interrupt()
	end
end

function item_ammo:OnChannelFinish(bInterrupted)
	local caster = self:GetCaster()
	local clip_ammo = self:GetSpecialValueFor("clip_ammo")
	local weaponsystem = caster:FindModifierByName("modifier_player_weapon_system")
	local weapon = weaponsystem.weapon

	if not bInterrupted then
		if weapon ~= nil then
			if ammoweaponcompat[weapon:GetName()] == self:GetName() then
				if weapon:GetCurrentCharges() ~= weapon:GetInitialCharges() then
					weapon:SetCurrentCharges( clip_ammo )
					if self:GetCurrentCharges() - 1 <= 0 then
						caster:RemoveItem(self)
					else
						self:SetCurrentCharges(self:GetCurrentCharges() - 1)
					end
				end
			end
		end
	end
end

item_ammo_762 = class(item_ammo)
item_ammo_542 = class(item_ammo)
item_ammo_awp = class(item_ammo)