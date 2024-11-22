hook.Add("RM_CanAction", "TTT2RagmodCanAction", function(ply, action)
	if not ply:IsTerror() or (GetRoundState and GetRoundState() ~= ROUND_ACTIVE) then return false end
end)

if SERVER then
	local disabled_convars = {"rm_show_tips", "rm_doorbreaching", "rm_movement_fly"}
	local enabled_convars = {"rm_normal_death_ragdolls", "rm_enable_manual"}
	local changed_convars = {
		rm_damage_phys_multiplier = 2,    -- Double physics damage
		rm_damage_phys_min = 2000,         -- Lower minimum threshold
		rm_damage_force_multiplier = 2,   -- Double force from impacts
	}

	for _, cvar in pairs(disabled_convars) do
		local convar = GetConVar(cvar)
		if convar then
			convar:SetBool(false)
		end
	end

	for _, cvar in pairs(enabled_convars) do
		local convar = GetConVar(cvar)
		if convar then
			convar:SetBool(true)
		end
	end

	for cvar, value in pairs(changed_convars) do
		local convar = GetConVar(cvar)
		if convar then
			convar:SetInt(value)
		end
	end

	hook.Add("TTT2PostPlayerDeath", "TTT2RagmodRemoveRagdoll", function(ply)
		if not ragmod then return end
		local ragdoll = ragmod:GetRagmodRagdoll(ply)

		SafeRemoveEntity(ragdoll)
	end)

	hook.Add("RM_RagdollReady", "TTT2RagmodOutfitterRagdoll", function(rag, ply)
		if not ply:IsTerror() then
			SafeRemoveEntity(rag)
			return
		end

		net.Start("TTTOutfitterRagdoll")
		net.WritePlayer(ply)
		net.WriteUInt(rag:EntIndex(), 13)
		net.Broadcast()
	end)

	hook.Add("TTTCanOrderEquipment", "TTT2RagmodOrderEquipment", function(ply)
		if ragmod and ragmod:IsRagmodRagdoll(ply) then
			return false
		end
	end)

	hook.Add("TTTEndRound", "TTT2RagmodRemoveRagdoll", function()
		if not ragmod then return end

		for _, ply in ipairs(player.GetAll()) do
			local ragdoll = ragmod:GetRagmodRagdoll(ply)
			SafeRemoveEntity(ragdoll)
		end
	end)

	hook.Add("Initialize", "TTT2RagmodOverrides", function()
		if not ragmod then return end

		local old_rm_RestorePlayerInventory = ragmod.RestorePlayerInventory
		ragmod.RestorePlayerInventory = function(self, ply)
			if ply.Ragmod_SavedInventory then
				ply:SetCredits(ply.Ragmod_SavedInventory.credits)
				for _, equipment_class in pairs(ply.Ragmod_SavedInventory.equipment) do
					ply:AddEquipmentItem(equipment_class)
				end
			end

			old_rm_RestorePlayerInventory(self,ply)
		end

		local old_rm_SavePlayerInventory = ragmod.SavePlayerInventory
		ragmod.SavePlayerInventory = function(self, ply)
			old_rm_SavePlayerInventory(self, ply)

			if ply.Ragmod_SavedInventory then
				ply.Ragmod_SavedInventory.credits = ply:GetCredits()
				ply.Ragmod_SavedInventory.equipment = ply:GetEquipmentItems()
			end
		end

		local old_rm_IsRagmodRagdoll = ragmod.IsRagmodRagdoll
		ragmod.IsRagmodRagdoll = function(self, ent) -- fix oversight in ragmod
			if not IsValid(ent) then return false end
			return old_rm_IsRagmodRagdoll(self, ent)
		end

		local ragmod_Tick = hook.GetTable().Tick.ragmod_Tick
		hook.Add("Tick", "TTT2RagmodTick", function()
			for i, ragdoll in ipairs(ragmod.Ragdolls) do
				-- This shouldn't happen unless someone broke something
				if not IsValid(ragdoll) then
					table.remove(ragmod.Ragdolls, i)
				elseif not ragdoll.Tick then
					ragdoll.Tick = function() end
				end
			end

			ragmod_Tick()
		end)
	end)
end

if CLIENT then
	hook.Add("TTTModifyTargetedEntity", "TTT2RagmodRagdollTargetID", function(ent, distance)
		if not ent:IsRagdoll() then return end
		if not ragmod:IsRagmodRagdoll(ent) then return end

		-- Get the ragdoll owner
		local owner = ent.GetOwningPlayer and ent:GetOwningPlayer() or nil
		if not IsValid(owner) then return end
		if not owner:IsTerror() then return end
		if owner == LocalPlayer() then return end

		return owner
	end)

	hook.Add("TTT2PreventAccessShop", "TTT2RagmodPreventAccessShop", function(ply)
		if ragmod and ragmod:IsRagdoll(ply) then
			return true
		end
	end)

	hook.Add("RM_CanChangeCamera", "TTT2RagmodCanChangeCamera", function(ply)
		return false
	end)

	hook.Add("Initialize", "TTT2RemoveRagmodOptions", function()
		concommand.Add("rm_menu", function() end) -- disable ragmod menu

		local PLY = FindMetaTable("Player")
		PLY.RM_OpenMenu = function() end
		PLY.RM_CloseMenu = function() end

		local bad_cvars = { rm_key_fly = true, rm_key_open_menu = true }
		if RagmodInputTable then
			for i, inpt in pairs(RagmodInputTable) do
				if bad_cvars[inpt.ConVarName] then
					table.remove(RagmodInputTable, i)
				end
			end
		end
	end)
end