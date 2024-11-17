if SERVER then
	local disabled_convars = { "rm_show_tips", "rm_enable_manual", "rm_doorbreaching" }
	local enabled_convars = { "rm_normal_death_ragdolls" }

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
end

if CLIENT then
	hook.Add("TTTRenderEntityInfo", "TTT2RagdollTargetID", function(tData)
		local ent = tData:GetEntity()

		-- Check if entity is a ragdoll
		if not IsValid(ent) or not ent:IsRagdoll() then return end
		if not ragmod then return end
		if not ragmod:IsRagmodRagdoll(ent) then return end

		-- Get the ragdoll owner
		local owner = ent.GetOwningPlayer and ent:GetOwningPlayer() or nil
		if not IsValid(owner) then return end

		-- Add the player info to the target ID
		local roleData = roles.GetByIndex(owner:GetRole())
		if not roleData then return end

		tData:AddIcon(
			roleData.icon,
			roleData.color
		)

		tData:SetKey("name", owner:Nick())

		local subRoleData = roles.GetByIndex(owner:GetSubRole())
		if not subRoleData then return end

		tData:SetSubtitle(subRoleData.name)
		tData:AddIcon(
			subRoleData.icon,
			subRoleData.color
		)

		-- You can add more info here as needed
	end)
end
