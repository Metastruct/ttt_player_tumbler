if SERVER then
	local disabled_convars = {"rm_show_tips", "rm_enable_manual", "rm_doorbreaching"}
	local enabled_convars = {"rm_normal_death_ragdolls"}

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

	hook.Add("TTT2PostPlayerDeath", "TTT2RagmodRemoveRagdoll", function(ply)
		if not ragmod then return end
		local ragdoll = ragmod:GetRagmodRagdoll(ply)

		SafeRemoveEntity(ragdoll)
		ply.ragdoll_pre_data = nil
	end)

	hook.Add("RM_RagdollReady", "TTT2RagmodOutfitterRagdoll", function(rag, ply)
		net.Start("TTTOutfitterRagdoll")
		net.WritePlayer(ply)
		net.WriteUInt(rag:EntIndex(), 13)
		net.Broadcast()

		local weapon_data = {}
		for _, wep in ipairs(ply:GetWeapons()) do
			table.insert(weapon_data, {
				class = wep:GetClass(),
				ammo = wep:Clip1(),
				clip = wep:Clip2(),
			})
		end

		ply.ragdoll_pre_data = {
			credits = ply:GetCredits(),
			equipment = ply:GetEquipmentItems(),
			weapons = weapon_data,
		}
	end)

	hook.Add("PlayerSpawn", "TTT2RagmodRestoreData", function(ply)
		if not ply.ragdoll_pre_data then return end

		ply:SetCredits(ply.ragdoll_pre_data.credits)

		for _, equipment_class in pairs(ply.ragdoll_pre_data.equipment) do
			ply:AddEquipmentItem(equipment_class)
		end

		for _, data in ipairs(ply.ragdoll_pre_data.weapons) do
			local wep = ply:Give(data.class)
			wep:SetClip1(data.ammo)
			wep:SetClip2(data.clip)
		end

		ply.ragdoll_pre_data = nil

		return true
	end)

	hook.Add("TTTCanOrderEquipment", "TTT2RagmodOrderEquipment", function(ply)
		if ragmod and ragmod:IsRagmodRagdoll(ply) then
			return false
		end
	end)

	hook.Add("TTTPrepareRound", "TTT2RagmodOverrides", function()
		for _, ply in ipairs(player.GetAll()) do
			local ragdoll = ragmod and ragmod:GetRagmodRagdoll(ply)
			SafeRemoveEntity(ragdoll)

			ply.ragdoll_pre_data = nil
		end
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

		return owner
	end)

	hook.Add("Initialize", "TTT2RemoveRagmodOptions", function()
		concommand.Remove("rm_menu")

		local PLY = FindMetaTable("Player")
		PLY.RM_OpenMenu = function() end
		PLY.RM_CloseMenu = function() end
	end)
end