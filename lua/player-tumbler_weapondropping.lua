local ragmod = PlayerTumbler_Info.ragmod

local convars = PlayerTumbler_Info.convars
local ragmod_convar = GetConVar("rm_enabled")
local RAGMOD_ENABLED = ragmod_convar:GetBool()
local MOD_ENABLED = convars.EnableMod:GetBool()
local WEAPON_DROPPING = convars.WeaponDropping:GetBool()
local weaponPositions = {
	["models/weapons/w_crowbar.mdl"] = {
		[0] = { -- Angle
			[0] = -85,
			[1] = -5,
			[2] = -15
		},
		[1] = { -- Position
			[0] = 0,
			[1] = 0,
			[2] = -6
		}
	},
	["models/weapons/w_smg1.mdl"] = {
		[0] = {
			[0] = 10,
			[1] = 0,
			[2] = 0
		},
		[1] = {
			[0] = 0,
			[1] = 3,
			[2] = 7
		}
	},
	["models/weapons/w_pistol.mdl"] = {
		[0] = {
			[0] = 0,
			[1] = 180,
			[2] = 0
		},
		[1] = {
			[0] = 0,
			[1] = 3,
			[2] = -3.75
		}
	},
	["models/weapons/w_357.mdl"] = {
		[0] = {
			[0] = 0,
			[1] = 0,
			[2] = 0
		},
		[1] = {
			[0] = 0,
			[1] = 2.15,
			[2] = -1.5
		}
	},
	["models/weapons/w_toolgun.mdl"] = {
		[0] = {
			[0] = 0,
			[1] = 0,
			[2] = 0
		},
		[1] = {
			[0] = 0,
			[1] = 2.15,
			[2] = -1.5
		}
	},
	["models/weapons/w_Physics.mdl"] = {
		[0] = {
			[0] = 0,
			[1] = -6,
			[2] = 13
		},
		[1] = {
			[0] = 0,
			[1] = 3,
			[2] = 0
		}
	},
	["models/weapons/w_shotgun.mdl"] = {
		[0] = {
			[0] = 10,
			[1] = 180,
			[2] = 0
		},
		[1] = {
			[0] = 0,
			[1] = 0,
			[2] = -15
		}
	},
	["models/weapons/w_grenade.mdl"] = {
		[0] = {
			[0] = 0,
			[1] = 180,
			[2] = 0
		},
		[1] = {
			[0] = 0,
			[1] = -3.5,
			[2] = 0
		}
	},
	["models/weapons/w_irifle.mdl"] = {
		[0] = {
			[0] = 14,
			[1] = 180,
			[2] = 0
		},
		[1] = {
			[0] = 0,
			[1] = 0,
			[2] = -14
		}
	},
	["models/weapons/w_rocket_launcher.mdl"] = {
		[0] = {
			[0] = 12,
			[1] = 180,
			[2] = 0
		},
		[1] = {
			[0] = -1.5,
			[1] = 0,
			[2] = -14
		}
	},
	["models/MaxOfS2D/camera.mdl"] = {
		[0] = {
			[0] = 0,
			[1] = 0,
			[2] = 0
		},
		[1] = {
			[0] = -3,
			[1] = 0,
			[2] = 3
		}
	},
}
local custom_collisions = {}

local function BoundingBox(phys, mins, maxs)
	local pos = phys:GetPos()

	local mins_1 = WorldToLocal(phys:LocalToWorld(Vector(maxs[1], mins[2], mins[3])), angle_zero, pos, angle_zero)
	local mins_2 = WorldToLocal(phys:LocalToWorld(Vector(mins[1], maxs[2], mins[3])), angle_zero, pos, angle_zero)
	local mins_3 = WorldToLocal(phys:LocalToWorld(Vector(mins[1], mins[2], maxs[3])), angle_zero, pos, angle_zero)

	local maxs_1 = WorldToLocal(phys:LocalToWorld(Vector(mins[1], maxs[2], maxs[3])), angle_zero, pos, angle_zero)
	local maxs_2 = WorldToLocal(phys:LocalToWorld(Vector(maxs[1], mins[2], maxs[3])), angle_zero, pos, angle_zero)
	local maxs_3 = WorldToLocal(phys:LocalToWorld(Vector(maxs[1], maxs[2], mins[3])), angle_zero, pos, angle_zero)

	mins = WorldToLocal(phys:LocalToWorld(mins), angle_zero, pos, angle_zero)
	maxs = WorldToLocal(phys:LocalToWorld(maxs), angle_zero, pos, angle_zero)

	local bbox_maxs = Vector(0,0,0)
	local bbox_mins = Vector(0,0,0)
	for i = 1, 3 do
		bbox_maxs[i] = math.max(mins[i], mins_1[i], mins_2[i], mins_3[i], maxs[i], maxs_1[i], maxs_2[i], maxs_3[i])
		bbox_mins[i] = math.min(mins[i], mins_1[i], mins_2[i], mins_3[i], maxs[i], maxs_1[i], maxs_2[i], maxs_3[i])
	end

	local abs = Vector(0,0,0)
	for i = 1, 3 do
		abs[i] = math.max(math.abs(bbox_maxs[i]), math.abs(bbox_mins[i]))
	end

	local max = math.max(abs[1], abs[2], abs[3])

	return bbox_mins, bbox_maxs, max
end

local phys_trace = Vector(100, 100, 100)

local function GetValidPosition(ply, weapon, phys, position, col_mins, col_maxs)
	local ply_pos = ply:GetPos()
	ply_pos[3] = position[3]

	local mins, maxs, max = BoundingBox(phys, col_mins, col_maxs)
	local max_full = (max * 2) + ply_pos:Distance(position)

	local diff = position - ply_pos
	local ang = diff:Angle()
	local _, l_ang = WorldToLocal(vector_origin, ang, vector_origin, ply:GetAngles())
	l_ang[2] = math.abs(l_ang[2])
	local dir = diff:GetNormalized()
	dir:Rotate(l_ang)

	local trace = {
		start = position - (dir * max_full),
		endpos = position + (dir * max_full),
		mins = mins,
		maxs = maxs,
		filter = {ply, weapon}
	}
	local tr_hull = util.TraceHull(trace)
	local tr_hull_hitpos = tr_hull.HitPos
	local tr_hull_normal = tr_hull.HitNormal
	local dirs = {
		[1] = dir:Angle():Right(),
		[2] = -dir
	}

	trace.start = position + (tr_hull_normal * max_full)
	trace.endpos = position - (tr_hull_normal * max_full)
	local tr = util.TraceLine(trace)
	local tr_hitpos

	if tr.Hit then
		tr_hitpos = tr.HitPos
	else
		tr_hitpos = util.IntersectRayWithOBB(tr_hull_hitpos - (tr_hull_normal * max_full), tr_hull_normal * max_full, tr_hull_hitpos, angle_zero, mins, maxs)
	end

	trace.start = tr_hitpos
	trace.endpos = ply_pos
	local tr_valid = util.TraceLine(trace)

	if tr_valid.Hit or tr_valid.StartSolid or tr_hull_normal:IsZero() or tr_hull.HitPos == trace.endpos or tr_hull.AllSolid then
		for _, single_dir in ipairs(dirs) do
			trace.start = position - (single_dir * max_full)
			trace.endpos = position + (single_dir * max_full)
			trace.output = tr_hull
			util.TraceHull(trace)
			tr_hull_hitpos = tr_hull.HitPos
			tr_hull_normal = tr_hull.HitNormal

			if not tr_hull_normal:IsZero() and tr_hull.HitPos ~= trace.endpos and not tr_hull.AllSolid then
				trace.start = position + (tr_hull_normal * max_full)
				trace.endpos = position - (tr_hull_normal * max_full)
				trace.output = tr
				util.TraceLine(trace)

				if tr.Hit then
					tr_hitpos = tr.HitPos
				else
					tr_hitpos = util.IntersectRayWithOBB(tr_hull_hitpos - (tr_hull_normal * max_full), tr_hull_normal * max_full, tr_hull_hitpos, angle_zero, mins, maxs)
				end

				trace.start = tr_hitpos
				trace.endpos = ply_pos
				trace.output = tr_valid
				util.TraceLine(trace)

				if not tr_valid.Hit then break end
			end
		end
		--print("\nNOT VALID")
	end
	--rmdebug.Point("hitpos", tr_hitpos)
	--debugoverlay.Box(tr_hull_hitpos, mins, maxs, 5, Color(255,0,0,50))
	if tr_hull.Hit and not tr_hull_normal:IsZero() then
		local phys_collide = CreatePhysCollideBox(-phys_trace, phys_trace)

		local l_hitpos = phys:WorldToLocal(tr_hitpos)
		local l_normal = phys:WorldToLocalVector(tr_hull_normal)
		local l_angles = l_normal:Angle()

		local not_hit = not phys_collide:TraceBox(l_hitpos - (l_normal * 100), l_angles, vector_origin, vector_origin, col_mins, col_maxs)

		if not not_hit then
			local phys_collide_pos = phys_collide:TraceBox(vector_origin, l_angles, vector_origin + (l_normal * 500), vector_origin, col_mins, col_maxs)
			local dist = vector_origin:Distance(phys_collide_pos) - 100
			local new_pos = tr_hitpos + (tr_hull_normal * dist)
			--debugoverlay.BoxAngles(new_pos, col_mins, col_maxs, ply.PT_ActiveWeaponInfo.Ang, 15, Color(255,0,255,50))
			phys_collide:Destroy()
			return new_pos
		end
		phys_collide:Destroy()
	end
end

local function SpawnHeldWeapon(ply, velocity)
	if not ply.PT_ActiveWeaponInfo or not IsValid(ply.PT_ActiveWeapon) or IsValid(ply.PT_SpawnedWeapon) or table.IsEmpty(ply.PT_ActiveWeaponInfo) then return end

	local position = ply.PT_ActiveWeaponInfo.Pos
	local angle = ply.PT_ActiveWeaponInfo.Ang
	local name = tostring(ply.PT_ActiveWeaponModel)

	-- If you have the time, (and care enough to do it) some of these weapon angles and positions can be tweaked to be more accurate. Use host_timescale 0.1

	if weaponPositions[name] ~= nil then
		for i = 0, #weaponPositions[name] do
			local tab = weaponPositions[name][i]
			--local right, up, forward = angle:Right(), angle:Up(), angle:Forward() -- I want this to work at some point

			if i == 0 then
				angle:RotateAroundAxis(angle:Right(), tab[0])
				angle:RotateAroundAxis(angle:Up(), tab[1])
				angle:RotateAroundAxis(angle:Forward(), tab[2])
			else
				position:Add(angle:Right() * tab[0])
				position:Add(angle:Up() * tab[1])
				position:Add(angle:Forward() * tab[2])
			end
		end
	end

	local weapon = ents.Create(ply.PT_ActiveWeapon:GetClass())
	weapon:SetModel(tostring(ply.PT_ActiveWeaponModel))

	weapon:SetPos(position)
	weapon:SetAngles(angle)
	weapon:Spawn()
	weapon:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	weapon:SetClip1(0)
	weapon:SetClip2(0)
	ply.PT_SpawnedWeapon = weapon

	custom_collisions[weapon] = true
	weapon:SetCustomCollisionCheck(true)

	local phys = weapon:GetPhysicsObject()
	if not IsValid(phys) then return end

	local mins, maxs = phys:GetAABB()
	local pos = GetValidPosition(ply, weapon, phys, position, mins, maxs) or position
	weapon:SetPos(pos)
	phys:SetVelocity(velocity)

	-- debugoverlay.BoxAngles(position, mins, maxs, angle, 15, Color(255,255,0,50))
end

local function RemoveWeapon(ply)
	if not IsValid(ply.PT_SpawnedWeapon) then return end
	ply.PT_SpawnedWeapon:Remove()
	ply.PT_SpawnedWeapon = nil
end

local function RemoveWeapons()
	for _, ply in ipairs(player.GetHumans()) do
		RemoveWeapon(ply)
	end
end

-- Dev stuff
--[[hook.Remove("RM_OwnerInitialized", "PT_SetActiveWeapon")
hook.Remove("PlayerSpawn", "PT_PlayerSpawn")
hook.Remove("PlayerCanPickupWeapon", "PT_WeaponPickup")
hook.Remove("AllowPlayerPickup", "PT_PlayerPickup")
hook.Remove("DoPlayerDeath", "PT_GetWeaponBeforeDeath")
hook.Remove("PlayerDisconnected", "PT_RemoveWepOnDisconnect")]]
-- Dev stuff

local function RagdollReady(rag, ply)
	local wep = ply.PT_SpawnedWeapon

	timer.Simple(1, function()
		custom_collisions[rag] = nil
		if IsValid(wep) then
			custom_collisions[wep] = nil
			wep:SetCustomCollisionCheck(false)
		end
	end)
end

local function ShouldCollideHook(ent1, ent2)
	return not custom_collisions[ent1] or not custom_collisions[ent2]
end

local function SpawnWeaponOnRagdoll(rag, ply)
	custom_collisions[rag] = true

	if not ply:Alive() then return end
	local attachment = ply:LookupAttachment("anim_attachment_RH")
	if not attachment then return end

	ply.PT_ActiveWeaponInfo = ply:GetAttachment(attachment) -- This right hand attachment doesn't seem to exist on some player models, will error if that is the casenot
	ply.PT_ActiveWeapon = ply:GetActiveWeapon()
	if not IsValid(ply.PT_ActiveWeapon) then return end
	ply.PT_ActiveWeaponModel = ply.PT_ActiveWeapon:GetModel()

	local vel = hook.Run("PlayerTumbler_GetVelocity", ply) or ply:GetAbsVelocity()

	SpawnHeldWeapon(ply, vel)
end

local function SpawnWeaponOnDeath(ply)
	if ragmod:IsRagdoll(ply) then return end
	ply.PT_ActiveWeaponInfo = ply:GetAttachment(ply:LookupAttachment("anim_attachment_RH"))
	ply.PT_ActiveWeapon = ply:GetActiveWeapon()
	if not IsValid(ply.PT_ActiveWeapon) then return end
	ply.PT_ActiveWeaponModel = ply.PT_ActiveWeapon:GetModel()

	SpawnHeldWeapon(ply, ply:GetAbsVelocity())
end

local function AllowPickup(ply, ent) -- Prevents players from picking up dropped weapons
	if not IsValid(ent) or not ent:IsWeapon() then return end

	if ent == ply.PT_SpawnedWeapon then
		return false

	else
		for _, v in ipairs(player.GetHumans()) do
			if ent == v.PT_SpawnedWeapon then
				return false
			end
		end
	end
end

local function AddHooks()
	hook.Add("RM_RagdollReady", "PT_WeaponNoCollide", RagdollReady)
	hook.Add("ShouldCollide", "PT_DisableWeaponRagdollCollisions", ShouldCollideHook)
	hook.Add("RM_OwnerInitialized", "PT_SetActiveWeapon", SpawnWeaponOnRagdoll)
	hook.Add("DoPlayerDeath", "PT_GetWeaponBeforeDeath", SpawnWeaponOnDeath)
	hook.Add("PlayerSpawn", "PT_PlayerSpawn", RemoveWeapon)
	hook.Add("PlayerDisconnected", "PT_RemoveWepOnDisconnect", RemoveWeapon)
	hook.Add("PlayerCanPickupWeapon", "PT_WeaponPickup", AllowPickup)
	hook.Add("AllowPlayerPickup", "PT_PlayerPickup", AllowPickup)
end

local function RemoveHooks()
	hook.Remove("RM_RagdollReady", "PT_WeaponNoCollide")
	hook.Remove("ShouldCollide", "PT_DisableWeaponRagdollCollisions")
	hook.Remove("RM_OwnerInitialized", "PT_SetActiveWeapon")
	hook.Remove("DoPlayerDeath", "PT_GetWeaponBeforeDeath")
	hook.Remove("PlayerSpawn", "PT_PlayerSpawn")
	hook.Remove("PlayerDisconnected", "PT_RemoveWepOnDisconnect")
	hook.Remove("PlayerCanPickupWeapon", "PT_WeaponPickup")
	hook.Remove("AllowPlayerPickup", "PT_PlayerPickup")
end

cvars.AddChangeCallback("ptumbler_enable", function(_, old, new)
	MOD_ENABLED = tobool(new)
	if not WEAPON_DROPPING or not RAGMOD_ENABLED then return end

	if new == 1 and old ~= 1 then
		AddHooks()
	elseif new == 0 and old ~= 0 then
		RemoveHooks()
		RemoveWeapons()
	end
end)

cvars.AddChangeCallback("rm_enabled", function(_, old, new)
	RAGMOD_ENABLED = tobool(new)
	if not WEAPON_DROPPING or not MOD_ENABLED then return end

	new = tonumber(new)
	old = tonumber(old)

	if new == 1 and old ~= 1 then
		AddHooks()
	elseif new == 0 and old ~= 0 then
		RemoveHooks()
		RemoveWeapons()
	end
end)

cvars.AddChangeCallback("ptumbler_weapondropping", function(_, old, new)
	WEAPON_DROPPING = tobool(new)
	if not RAGMOD_ENABLED or not MOD_ENABLED then return end

	if new == 1 and old ~= 1 then
		AddHooks()
	elseif new == 0 and old ~= 0 then
		RemoveHooks()
		RemoveWeapons()
	end
end)

if WEAPON_DROPPING and RAGMOD_ENABLED and MOD_ENABLED then
	AddHooks()
end