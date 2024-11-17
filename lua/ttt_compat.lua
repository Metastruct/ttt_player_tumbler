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
	end)

	hook.Add("RM_RagdollReady", "TTT2RagmodOutfitterRagdoll", function(rag, ply)
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

	hook.Add("TTTPrepareRound", "TTT2RagmodOverrides", function()
		if not ragmod then return end

		for _, ply in ipairs(player.GetAll()) do
			local ragdoll = ragmod:GetRagmodRagdoll(ply)
			SafeRemoveEntity(ragdoll)
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

	hook.Add("TTT2PreventAccessShop", "TTT2RagmodPreventAccessShop", function(ply)
		if ragmod and ragmod:IsRagmodRagdoll(ply) then
			return true
		end
	end)

	hook.Add("Initialize", "TTT2RemoveRagmodOptions", function()
		concommand.Remove("rm_menu")

		local PLY = FindMetaTable("Player")
		PLY.RM_OpenMenu = function() end
		PLY.RM_CloseMenu = function() end
	end)
end