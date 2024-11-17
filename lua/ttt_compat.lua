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
		ply.next_reset_is_override = nil
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

	hook.Add("RM_RagdollPossessed", "TTT2RagmodRestoreCredits", function(rag, ply)
		if not IsValid(ply) then return end
		if ply.IsTerror and not ply:IsTerror() then return end
		if GetRoundState and GetRoundState() ~= ROUND_ACTIVE then return end

		ply.next_reset_is_override = true
	end)

	hook.Add("TTTEndRound", "TTT2RagmodOverrides", function()
		for _, ply in ipairs(player.GetAll()) do
			ply.next_reset_is_override = nil
		end
	end)

	-- This is gross but it works
	hook.Add("Initialize", "TTT2RagmodOverrides", function()
		local PLY = FindMetaTable("Player")
		PLY.old_ResetRoundFlags = PLY.old_ResetRoundFlags or PLY.ResetRoundFlags
		PLY.ResetRoundFlags = function(ply) -- This is called on PlayerSpawn, which is called when a player gets up from a ragdoll
			if ply.next_reset_is_override then
				ply.next_reset_is_override = nil

				if ply:IsTerror() then return end -- only override for players that are still in the round
			end

			ply:old_ResetRoundFlags()
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