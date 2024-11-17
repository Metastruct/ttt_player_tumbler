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
end

if CLIENT then
	hook.Add("TTTModifyTargetedEntity", "TTT2RagdollTargetID", function(ent, distance)
		if not ent:IsRagdoll() then return end
		if not ragmod:IsRagmodRagdoll(ent) then return end

		-- Get the ragdoll owner
		local owner = ent.GetOwningPlayer and ent:GetOwningPlayer() or nil
		if not IsValid(owner) then return end
		if not owner:IsTerror() then return end

		return owner
	end)
end