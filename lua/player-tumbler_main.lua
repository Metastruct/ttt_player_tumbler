local ragmod = PlayerTumbler_Info.ragmod

local bbinfo
if istable(BreakingBones) then
	bbinfo = BreakingBones.plyinfo
else
	bbinfo = {}
end
local BONE_BUSTER_VALID = next(bbinfo) ~= nil

local info = {}
local convars = PlayerTumbler_Info.convars

local RAGMOD_REWORKED = PlayerTumbler_Info.RAGMOD_REWORKED
local RAGMOD_V3 = PlayerTumbler_Info.RAGMOD_V3

local ragmod_convar = GetConVar("rm_enabled")
local RAGMOD_ENABLED = ragmod_convar:GetBool()
local MOD_ENABLED = convars.EnableMod:GetBool()
local CONFIGURED_RAGMOD

if RAGMOD_REWORKED then
	CONFIGURED_RAGMOD = convars.AutoConfigured:GetBool()
elseif RAGMOD_V3 then
	CONFIGURED_RAGMOD = convars.AutoConfiguredRagmodV3:GetBool()
end

local EXIT_VEHICLE = convars.ExitVehicleRagdoll:GetBool()
local MOMENTUM_SYSTEM = convars.WallCollision:GetBool()
local WALL_CHECK = convars.WallCheck:GetBool()
local FALL_DAMAGE = convars.FallDamage:GetBool()
local WATER_ENABLED = convars.WaterCanRagdoll:GetBool()
local PROP_HIT = convars.PropHitPlayer:GetBool()
local HIT_PROP = convars.PlayerHitProp:GetBool()
local TRIP_CHECK = convars.TripCheck:GetBool()
local ALLOW_TRIPPING = convars.AllowTripping:GetBool()
local PREVENT_GETUP = convars.PreventMovingGetup:GetBool()

local exit_vehicle_threshold = convars.ExitVehicleThreshold:GetInt()
local maxspeed = convars.GroundMaxVelocity:GetInt()
local air_threshold = convars.AirThreshold:GetInt()
local ground_threshold = convars.GroundThreshold:GetInt()
local water_threshold = convars.WaterThreshold:GetInt()
local getup_threshold = convars.MovingGetupThreshold:GetInt()

local ground_up_threshold = convars.GroundUpThreshold:GetInt()
local ground_down_threshold = convars.GroundDownThreshold:GetInt()
local air_up_threshold = convars.AirUpThreshold:GetInt()
local air_down_threshold = convars.AirDownThreshold:GetInt()
local water_up_threshold = convars.WaterUpThreshold:GetInt()
local water_down_threshold = convars.WaterDownThreshold:GetInt()

--local callbacks = {}
local callback = {}

local util = util
local math = math

cvars.AddChangeCallback("ptumbler_wall", function(_, old, new)
	MOMENTUM_SYSTEM = tobool(new)
end)
cvars.AddChangeCallback("ptumbler_wall_check", function(_, old, new)
	WALL_CHECK = tobool(new)
end)
cvars.AddChangeCallback("ptumbler_trip_check", function(_, old, new)
	TRIP_CHECK = tobool(new)
end)
cvars.AddChangeCallback("ptumbler_trip_enable", function(_, old, new)
	ALLOW_TRIPPING = tobool(new)
end)
cvars.AddChangeCallback("ptumbler_fall_damage", function(_, old, new)
	FALL_DAMAGE = tobool(new)
end)
cvars.AddChangeCallback("ptumbler_water", function(_, old, new)
	WATER_ENABLED = tobool(new)
end)
cvars.AddChangeCallback("ptumbler_prophit", function(_, old, new)
	PROP_HIT = tobool(new)
end)
cvars.AddChangeCallback("ptumbler_playerhit", function(_, old, new)
	HIT_PROP = tobool(new)
end)
cvars.AddChangeCallback("ptumbler_prevent_moving_getup", function(_, old, new)
	PREVENT_GETUP = tobool(new)
end)

cvars.AddChangeCallback("ptumbler_vehicle_exit_threshold", function(_, old, new)
	exit_vehicle_threshold = tonumber(new)
end)
cvars.AddChangeCallback("ptumbler_groundthresh", function(_, old, new)
	ground_threshold = tonumber(new)
end)
cvars.AddChangeCallback("ptumbler_airthresh", function(_, old, new)
	air_threshold = tonumber(new)
end)
cvars.AddChangeCallback("ptumbler_waterthresh", function(_, old, new)
	water_threshold = tonumber(new)
end)
cvars.AddChangeCallback("ptumbler_groundlimit", function(_, old, new)
	maxspeed = tonumber(new)
end)
cvars.AddChangeCallback("ptumbler_getup_threshold", function(_, old, new)
	getup_threshold = tonumber(new)
end)

cvars.AddChangeCallback("ptumbler_ground_up_thresh", function(_, old, new)
	ground_up_threshold = tonumber(new)
end)
cvars.AddChangeCallback("ptumbler_ground_down_thresh", function(_, old, new)
	ground_down_threshold = tonumber(new)
end)
cvars.AddChangeCallback("ptumbler_air_up_thresh", function(_, old, new)
	air_up_threshold = tonumber(new)
end)
cvars.AddChangeCallback("ptumbler_air_down_thresh", function(_, old, new)
	air_down_threshold = tonumber(new)
end)
cvars.AddChangeCallback("ptumbler_water_up_thresh", function(_, old, new)
	water_up_threshold = tonumber(new)
end)
cvars.AddChangeCallback("ptumbler_water_down_thresh", function(_, old, new)
	water_down_threshold = tonumber(new)
end)

local function SetRagVel(ply, vel)
	local rag = ragmod:GetRagmodRagdoll(ply)
	if not IsValid(rag) then return end

	for i = 0, rag:GetPhysicsObjectCount() - 1 do
		local phys = rag:GetPhysicsObjectNum(i)

		phys:SetVelocityInstantaneous(vel)
		phys:SetVelocity(vel)
	end
end

local function RagdollPlayerPhysCollide(ply, vel)
	--callbacks[ply] = callbacks[ply] or {}

	--[[for id, func in pairs(ply:GetCallbacks("PhysicsCollide")) do
		callbacks[ply][id] = func
		ply:RemoveCallback("PhysicsCollide", id)
	end]]

	timer.Simple(0, function()
		info[ply]["DelVel"] = vel
		ragmod:TryToRagdoll(ply)
		SetRagVel(ply, vel)
	end)
end

local traceDown = Vector(0,0,2)
local trace_ground_func = {}
local trace_ground_func_output = {}
local trace_class_blacklist = {
	["prop_combine_ball"] = true
}

local function TraceGround(ply)
	local pos = ply:GetPos()
	local mins, maxs = ply:GetCollisionBounds()
	mins = mins - traceDown

	trace_ground_func.start = pos
	trace_ground_func.endpos = pos
	trace_ground_func.mins = mins
	trace_ground_func.maxs = maxs
	trace_ground_func.filter = function(hitEnt) return hitEnt ~= ply and not trace_class_blacklist[hitEnt:GetClass()] end
	trace_ground_func.output = trace_ground_func_output
	util.TraceHull(trace_ground_func)

	return trace_ground_func_output
end

--[[local function AbsVector(vec)
	vec[1], vec[2], vec[3] = math.abs(vec[1]), math.abs(vec[2]), math.abs(vec[3])
	return vec
end]]

local function GetAbsVector(vec)
	local vec_abs = Vector(math.abs(vec[1]), math.abs(vec[2]), math.abs(vec[3]))
	return vec_abs
end

local function CheckVectorGreater(vec1, vec2)
	local state
	local tab = {}
	local vec1_abs, vec2_abs = GetAbsVector(vec1), GetAbsVector(vec2)

	for i = 1, 3 do
		if ((vec1[i] > -25 and vec2[i] > 0) or (vec1[i] < 25 and vec2[i] < 0)) and vec1_abs[i] > 0 and vec2_abs[i] > 0 then
			state = vec2_abs[i] > vec1_abs[i]
			tab[i] = state
		end
	end

	return state, tab
end

local function Cooldown(info)
	return CurTime() - info["GetUpTime"] < 0.5
end

local function PhysicsCollide(ply, tab)
	local info = info[ply]
	if (not PROP_HIT and not HIT_PROP) or info["GoingToBeRagdoll"] or info["MoveType"][ply:GetMoveType()] or Cooldown(info) then return end
	--local hit_info = info["HitEntInfo"]

	local ent_old_vel = tab.TheirOldVelocity
	local ent_old_ang_vel = tab.TheirOldAngularVelocity
	local phys = tab.HitObject
	local ply_old_vel = tab.OurOldVelocity
	local hit_ent = tab.HitEntity
	local delvel = info["DelVel"]
	local not_ground_ent = TraceGround(ply).Entity ~= hit_ent or ply:GetGroundEntity() ~= hit_ent
	local mass = phys:GetMass()

	local state, remove_vectors = CheckVectorGreater(ent_old_vel, ply_old_vel)

	local velocity_diff = ent_old_vel - ply_old_vel
	if not state and PROP_HIT then
		local momentum = mass * (velocity_diff * 0.01905)

		for i, remove in pairs(remove_vectors) do
			if not remove then continue end
			momentum[i] = 0
		end

		momentum = momentum:Length()

		--local momentum_diag = math.Remap(momentum[1] + momentum[2], 0, 915, 0, 647)
		--local max_momentum = math.max(momentum[1], momentum[2], momentum[3], momentum_diag)
		--local max_velocity = math.max(math.abs(ent_old_vel[1]), math.abs(ent_old_vel[2]), math.abs(ent_old_vel[3]))
		local velocity = ent_old_vel:Length()
		local momentum_threshold = 300

		if ragmod:IsRagmodRagdoll(hit_ent) then momentum_threshold = 150 end

		if not_ground_ent and momentum >= momentum_threshold and velocity >= 100 then
			--print("\n PROP HIT PLAYER", momentum, "\n ENT", ent_old_vel, "\n PLAYER", ply_old_vel, "\n DIFF", velocity_diff, "\n")--, momentum_ply)

			info["GoingToBeRagdoll"] = true
			RagdollPlayerPhysCollide(ply, delvel)

			phys:SetVelocityInstantaneous(ent_old_vel)
			phys:SetAngleVelocityInstantaneous(ent_old_ang_vel)
			phys:SetVelocity(ent_old_vel)
			phys:SetAngleVelocity(ent_old_ang_vel)
		return end
	end

	if not HIT_PROP then return end

	--local momentum_change_ply = AbsVector(ply:GetPhysicsObject():GetMass() * ((tab.OurNewVelocity - delvel) * 0.01905))
	--local max_momentum_ply = math.max(momentum_change_ply[1], momentum_change_ply[2], momentum_change_ply[3])

	local ent_change_vel = tab.TheirNewVelocity - ent_old_vel
	--local ent_change_vel_abs = GetAbsVector(ent_change_vel)
	--local max_velocity_ent = math.max(ent_change_vel_abs[1], ent_change_vel_abs[2], ent_change_vel_abs[3])
	local velocity = ent_change_vel:Length()

	--local momentum_ent = AbsVector(mass * (ent_change_vel * 0.01905))
	local momentum = (mass * (ent_change_vel * 0.01905)):Length()
	--local max_momentum_ent = math.max(momentum_ent[1], momentum_ent[2], momentum_ent[3]) + max_momentum_ply
	--velocity_diff = AbsVector(velocity_diff)
	--local max_velocity = math.max(velocity_diff[1], velocity_diff[2], velocity_diff[3])
	local velocity_old = velocity_diff:Length()

	if not_ground_ent and momentum >= 300 and velocity >= 50 and velocity_old >= 100 then
		--print("\nPLAYER HIT PROP", "\n MAX MOMENTUM", max_momentum_ent, "\n MAX VELOCITY", max_velocity, "\n MAX VELOCITY ENT", max_velocity_ent)

		info["GoingToBeRagdoll"] = true
		RagdollPlayerPhysCollide(ply, delvel)

		phys:SetVelocityInstantaneous(ent_old_vel)
		phys:SetAngleVelocityInstantaneous(ent_old_ang_vel)
		phys:SetVelocity(ent_old_vel)
		phys:SetAngleVelocity(ent_old_ang_vel)
	end
end

local function InitPlayer(ply, addcallback)
	info[ply] = {
		["GoingToBeRagdoll"] = false,
		["IsRagdoll"] = false,
		["Vel"] = Vector(0,0,0),
		["DelVel"] = Vector(0,0,0),
		["Time"] = 0,
		["PreTime"] = 0,
		["MoveType"] = {
			[8] = true,
			[9] = true
		},
		["WaterLevel"] = {
			[0] = false,
			[1] = true,
			[2] = true,
			[3] = true
		},
		["GetUpTime"] = 0,
		["HasExitedVehicle"] = false,
		["WaitingForVehicleExit"] = false,
		["VehicleInfo"] = {
			["Vel"] = Vector(0,0,0),
			["InitialExit"] = false
		}
	}

	if addcallback then
		if not callback[ply] then
			callback[ply] = ply:AddCallback("PhysicsCollide", PhysicsCollide)
		else
			ply:RemoveCallback("PhysicsCollide", callback[ply])
			callback[ply] = ply:AddCallback("PhysicsCollide", PhysicsCollide)
		end
	end
end

local function InitPlayers()
	for _, v in ipairs(player.GetHumans()) do
		InitPlayer(v, true)
	end
end
--InitPlayers() -- disable me when you are donenot not not not

local function CalculateMomentum(ply, vel, delvel)
	local momentum = (((vel - delvel) * 0.01905) * ply:GetPhysicsObject():GetMass())
	return Vector(momentum[1], momentum[2], 0):Length(), momentum[3]
end

local function TestZDirection(on_ground, in_water, val)
	local up, down
	if on_ground then
		up = -ground_up_threshold
		down = ground_down_threshold
	elseif not in_water then
		up = -air_up_threshold
		down = air_down_threshold
	else
		up = -water_up_threshold
		down = water_down_threshold
	end

	if val >= 0 then
		return val >= down
	else
		return val <= up
	end
end

local traceDownCP = Vector(0,0,32)
local trace_checkplayer_func = {}
local trace_checkplayer_func_output = {}

local function WallHitCheck(ply, pos, vel, mins)
	trace_checkplayer_func.endpos = pos + (vel:GetNormalized() * 2)
	trace_checkplayer_func.mins = mins
	util.TraceHull(trace_checkplayer_func)

	return trace_checkplayer_func_output
end

local function CheckTripping(ply, pos, vel, mins, maxs, wall_check)
	if not ALLOW_TRIPPING or not TRIP_CHECK then return true end

	local maxs_f = Vector(0, 0, maxs[3])

	if not wall_check then
		trace_checkplayer_func.endpos = pos + (vel:GetNormalized() * 2)
		trace_checkplayer_func.mins = mins
		util.TraceHull(trace_checkplayer_func)
	end

	local ent = trace_checkplayer_func_output.Entity
	local hit_player
	if IsValid(ent) then hit_player = ent:IsPlayer() end

	trace_checkplayer_func.mins = mins
	trace_checkplayer_func.maxs = maxs - (maxs_f * 0.5)
	util.TraceHull(trace_checkplayer_func)

	local leg_hit = trace_checkplayer_func_output.Hit

	trace_checkplayer_func.mins = mins + (maxs_f * 0.7)
	trace_checkplayer_func.maxs = maxs
	util.TraceHull(trace_checkplayer_func)

	local head_hit = trace_checkplayer_func_output.Hit

	if leg_hit and not head_hit then return true, hit_player end

	trace_checkplayer_func.mins = mins
	trace_checkplayer_func.maxs = maxs - (maxs_f * 0.6)
	util.TraceHull(trace_checkplayer_func)

	leg_hit = trace_checkplayer_func_output.Hit

	trace_checkplayer_func.mins = mins + (maxs_f * 0.5)
	trace_checkplayer_func.maxs = maxs
	util.TraceHull(trace_checkplayer_func)

	head_hit = trace_checkplayer_func_output.Hit

	return head_hit and not leg_hit, hit_player
end

local function CheckPlayer(info, ply, vel, delvel, time)
	local change_momentum_hori, change_momentum_vert = CalculateMomentum(ply, vel, delvel)
	local hori_vel = Vector(vel[1], vel[2], 0):Length()
	local on_ground = TraceGround(ply).Hit or ply:OnGround()
	local in_water = info["WaterLevel"][ply:WaterLevel()]

	local ground_threshold, air_threshold = ground_threshold, air_threshold -- lower threshold when far off the ground
	local pos = ply:GetPos()
	local mins, maxs = ply:GetCollisionBounds()
	trace_checkplayer_func.start = pos
	trace_checkplayer_func.endpos = pos
	trace_checkplayer_func.mins = mins - traceDownCP
	trace_checkplayer_func.maxs = maxs
	trace_checkplayer_func.filter = function(hitEnt) return hitEnt ~= ply and not trace_class_blacklist[hitEnt:GetClass()] end
	trace_checkplayer_func.output = trace_checkplayer_func_output
	util.TraceHull(trace_checkplayer_func)

	if not trace_checkplayer_func_output.Hit then ground_threshold, air_threshold = ground_threshold * 0.5, air_threshold * 0.5 end

	local hit_wall = not WALL_CHECK or WallHitCheck(ply, pos, delvel, mins).Hit
	local has_tripped, hit_player = CheckTripping(ply, pos, delvel, mins, maxs, WALL_CHECK)

	if on_ground and ((hit_wall and ((ALLOW_TRIPPING and (has_tripped or hit_player) and change_momentum_hori >= ground_threshold) or TestZDirection(true, false, change_momentum_vert))) or hori_vel >= maxspeed) then
		info["GoingToBeRagdoll"] = true
		ragmod:TryToRagdoll(ply)
		SetRagVel(ply, delvel)

	elseif not on_ground and hit_wall and not in_water and (change_momentum_hori >= air_threshold or TestZDirection(false, false, change_momentum_vert)) then
		info["GoingToBeRagdoll"] = true
		ragmod:TryToRagdoll(ply)
		SetRagVel(ply, delvel)

	elseif WATER_ENABLED and not on_ground and in_water and (change_momentum_hori >= water_threshold or TestZDirection(false, true, change_momentum_vert)) then
		info["GoingToBeRagdoll"] = true
		ragmod:TryToRagdoll(ply)
		SetRagVel(ply, delvel)
	end
end

local function IsOutOfBounds(ply)
	local pos = ply:GetPos()
	local trace = {
		start = pos,
		endpos = pos,
		filter = ply
	}
	return util.TraceEntityHull(trace, ply).Hit
end

local function CheckIfVectorEquals(vec1, vec2)
	for i = 1, 3 do
		if vec1[i] ~= vec2[i] then return false end
	end
	return true
end

local function UpdateInfo(ply)
	local info = info[ply]
	if info["GoingToBeRagdoll"] or info["IsRagdoll"] then return end
	local vel = ply:GetAbsVelocity()

	info["PreTime"] = info["Time"]
	info["Time"] = CurTime()

	info["DelVel"] = info["Vel"]
	info["Vel"] = vel

	if not MOMENTUM_SYSTEM or CheckIfVectorEquals(info["Vel"], info["DelVel"]) or info["MoveType"][ply:GetMoveType()] or Cooldown(info) or IsOutOfBounds(ply) then return end
	CheckPlayer(info, ply, info["Vel"], info["DelVel"], info["Time"] - info["PreTime"])
end

local function Update()
	for _, v in ipairs(player.GetHumans()) do
		UpdateInfo(v)
	end
end

local action_blacklist = {
	["unpossess"] = true
}
local function PreventGettingUp(ply, action)
	if not action_blacklist[action] or not info[ply]["IsRagdoll"] then return end
	local rag = ragmod:GetRagmodRagdoll(ply)

	local vel = rag:GetPhysicsObject():GetVelocity():Length()

	if vel > getup_threshold then return false end
end

local function GetVelocity(ply)
	local info = info[ply]
	if info["GoingToBeRagdoll"] then return info["DelVel"] end
end

local function RagdollReady(rag, _, possessor)
	info[possessor]["IsRagdoll"] = true
end

local function PlayerSpawn(ply)
	if not info[ply]["IsRagdoll"] then return end
	InitPlayer(ply)
	info[ply]["GetUpTime"] = CurTime()

	--[[for _, func in pairs(callbacks[ply] or empty_tab) do
		ply:AddCallback("PhysicsCollide", func)
	end
	table.Empty(callbacks[ply] or empty_tab)]]
end

local function InitialSpawn(ply)
	InitPlayer(ply, true)

	if not CONFIGURED_RAGMOD then
		GetConVar("rm_enabled"):SetInt(1)

		if RAGMOD_REWORKED then
			GetConVar("rm_trigger_fall"):SetInt(0)
			GetConVar("rm_trigger_speed"):SetInt(0)
			GetConVar("rm_normal_death_ragdolls"):SetInt(0)
			GetConVar("rm_drop_weapons"):SetInt(0)

			convars.AutoConfigured:SetInt(1)
		elseif RAGMOD_V3 then
			GetConVar("rm_rag_onfall"):SetInt(0)
			GetConVar("rm_rag_onspeed"):SetInt(0)

			convars.AutoConfiguredRagmodV3:SetInt(1)
		end

		CONFIGURED_RAGMOD = true

		if not ply:IsAdmin() then return end

		timer.Simple(3, function()
			ply:ChatPrint("\nPlayer Tumbler has auto configured RagModnot \nSee console for details.")

			if RAGMOD_REWORKED then
				print("\nPLAYER TUMBLER AUTO CONFIGURATION DETAILS\n rm_enabled set to 1\n rm_trigger_fall set to 0\n rm_trigger_speed set to 0\n rm_normal_death_ragdolls set to 0\n rm_drop_weapons set to 0\n")
			elseif RAGMOD_V3 then
				print("\nPLAYER TUMBLER AUTO CONFIGURATION DETAILS\n rm_enabled set to 1\n rm_rag_onfall set to 0\n rm_rag_onspeed set to 0\n")
			end
		end)
	end
end

hook.Add("PlayerInitialSpawn", "PT_InitPlayer", InitialSpawn)

local function PreventPhysicsDamage(ent, dmginfo)
	if not PROP_HIT then return end
	local attacker = dmginfo:GetInflictor()
	if not dmginfo:IsDamageType(1) or not IsValid(ent) or not ent:IsPlayer() or not IsValid(attacker) or attacker:IsNPC() or attacker:IsNextBot() or not IsValid(attacker:GetPhysicsObject()) then return end

	dmginfo:SetDamage(0)
end

local function PreventFallDamage(ply)
	if FALL_DAMAGE or not MOMENTUM_SYSTEM or Cooldown(info[ply]) then return end
	return 0
end

local function OwnerInitialized(_, ply)
	bbinfo[ply]["Velocity"] = info[ply]["DelVel"] * 0.01905
	ply.BB_InitTime = CurTime()

	ply.BB_InitPossess = true
end

local function FinalExit(ply)
	local info = info[ply]
	if not info["WaitingForVehicleExit"] then return end
	info["WaitingForVehicleExit"] = false

	if info["VehicleInfo"]["InitialExit"] then ply:ExitVehicle() end
	local vel = info["VehicleInfo"]["Vel"]

	info["GoingToBeRagdoll"] = true
	info["DelVel"] = vel
	ragmod:TryToRagdoll(ply)
	SetRagVel(ply, vel)

	table.Empty(info["VehicleInfo"])
end

local function RagdollPlayerVehicle(ply, veh, init_exit)
	if not IsValid(veh) then return end

	local parent = veh:GetParent()
	if IsValid(parent) then veh = parent end

	local phys = veh:GetPhysicsObject()
	if not IsValid(phys) then return end

	local vel = phys:GetVelocity()
	local abs_vel = GetAbsVector(vel) * 0.01905
	local max = math.max(abs_vel[1], abs_vel[2], abs_vel[3])
	local info = info[ply]

	if max > exit_vehicle_threshold then
		info["WaitingForVehicleExit"] = true
		info["VehicleInfo"]["InitialExit"] = init_exit
		info["VehicleInfo"]["Vel"] = vel

		timer.Simple(0.2, function()
			FinalExit(ply)
		end)
	else
		info["WaitingForVehicleExit"] = false
		table.Empty(info["VehicleInfo"])
	end

	if not init_exit then info["HasExitedVehicle"] = false end
end

local function PlayerEnterVehicle(ply)
	local info = info[ply]
	info["WaitingForVehicleExit"] = false
	table.Empty(info["VehicleInfo"])
end

local function LeaveVehicle(ply, veh)
	local info = info[ply]
	if info["HasExitedVehicle"] then info["HasExitedVehicle"] = false return end

	info["HasExitedVehicle"] = true
	RagdollPlayerVehicle(ply, veh, false)
end

local function ExitVehicle(veh, ply)
	local info = info[ply]
	if info["HasExitedVehicle"] then info["HasExitedVehicle"] = false return end

	info["HasExitedVehicle"] = true
	RagdollPlayerVehicle(ply, veh, true)
end

local function AddHooks()
	hook.Add("Tick", "PT_GetVel", Update)
	hook.Add("PlayerTumbler_GetVelocity", "PT_SetObjectVel", GetVelocity)
	hook.Add("RM_RagdollReady", "PT_RagReady", RagdollReady)
	hook.Add("PlayerSpawn", "PT_PlayerSpawned", PlayerSpawn)
	hook.Add("EntityTakeDamage", "PT_PreventPhysicsDamage", PreventPhysicsDamage)
	hook.Add("GetFallDamage", "PT_PreventFallDamage", PreventFallDamage)
	if EXIT_VEHICLE then
		hook.Add("PlayerLeaveVehicle", "PT_PlayerLeftVehicle", LeaveVehicle)
		hook.Add("CanExitVehicle", "PT_PlayerCanExitVehicle", ExitVehicle)
		hook.Add("FindUseEntity", "PT_PlayerFinalExitVehicle", FinalExit)
		hook.Add("CanPlayerEnterVehicle", "PT_PlayerEnterVehicle", PlayerEnterVehicle)
	end
	if PREVENT_GETUP then
		hook.Add("RM_CanAction", "PT_PreventGettingUp", PreventGettingUp)
	end

	if BONE_BUSTER_VALID then
		hook.Add("RM_OwnerInitialized", "BB_GetPlayersVel", OwnerInitialized)
	end

	InitPlayers()
end

local function RemoveHooks()
	hook.Remove("Tick", "PT_GetVel")
	hook.Remove("PlayerTumbler_GetVelocity", "PT_SetObjectVel")
	hook.Remove("RM_RagdollReady", "PT_RagReady")
	hook.Remove("PlayerSpawn", "PT_PlayerSpawned")
	hook.Remove("EntityTakeDamage", "PT_PreventPhysicsDamage")
	hook.Remove("GetFallDamage", "PT_PreventFallDamage")
	hook.Remove("PostGamemodeLoaded", "PT_OverrideBBOwnerInitializedHook")
	hook.Remove("PlayerLeaveVehicle", "PT_PlayerLeftVehicle")
	hook.Remove("CanExitVehicle", "PT_PlayerCanExitVehicle")
	hook.Remove("FindUseEntity", "PT_PlayerFinalExitVehicle")
	hook.Remove("CanPlayerEnterVehicle", "PT_PlayerEnterVehicle")
	hook.Remove("RM_CanAction", "PT_PreventGettingUp")

	for _, v in ipairs(player.GetHumans()) do
		v:RemoveCallback("PhysicsCollide", callback[v])
	end
	table.Empty(callback)

	if BONE_BUSTER_VALID then
		hook.Add("RM_OwnerInitialized", "BB_GetPlayersVel", function(rag, ply) -- bone buster
			bbinfo[ply]["Velocity"] = ply:GetAbsVelocity() * 0.01905
			ply.BB_InitTime = CurTime()

			ply.BB_InitPossess = true
		end)
	end
end

cvars.AddChangeCallback("ptumbler_enable", function(_, old, new)
	MOD_ENABLED = tobool(new)
	if not RAGMOD_ENABLED then return end

	if new == 1 and old ~= 1 then
		AddHooks()
	elseif new == 0 and old ~= 0 then
		RemoveHooks()
	end
end)

cvars.AddChangeCallback("rm_enabled", function(_, old, new)
	RAGMOD_ENABLED = tobool(new)
	if not MOD_ENABLED then return end

	new = tonumber(new)
	old = tonumber(old)

	if new == 1 and old ~= 1 then
		AddHooks()
	elseif new == 0 and old ~= 0 then
		RemoveHooks()
	end
end)

cvars.AddChangeCallback("ptumbler_vehicle_exit_ragdoll", function(_, old, new)
	EXIT_VEHICLE = tobool(new)
	if not RAGMOD_ENABLED or not MOD_ENABLED then return end

	if new == 1 and old ~= 1 then
		hook.Add("PlayerLeaveVehicle", "PT_PlayerLeftVehicle", LeaveVehicle)
		hook.Add("CanExitVehicle", "PT_PlayerCanExitVehicle", ExitVehicle)
		hook.Add("FindUseEntity", "PT_PlayerFinalExitVehicle", FinalExit)
		hook.Add("CanPlayerEnterVehicle", "PT_PlayerEnterVehicle", PlayerEnterVehicle)
	elseif new == 0 and old ~= 0 then
		hook.Remove("PlayerLeaveVehicle", "PT_PlayerLeftVehicle")
		hook.Remove("CanExitVehicle", "PT_PlayerCanExitVehicle")
		hook.Remove("FindUseEntity", "PT_PlayerFinalExitVehicle")
		hook.Remove("CanPlayerEnterVehicle", "PT_PlayerEnterVehicle")
	end
end)

cvars.AddChangeCallback("ptumbler_prevent_moving_getup", function(_, old, new)
	PREVENT_GETUP = tobool(new)
	if not RAGMOD_ENABLED or not MOD_ENABLED then return end

	if new == 1 and old ~= 1 then
		hook.Add("RM_CanAction", "PT_PreventGettingUp", PreventGettingUp)
	elseif new == 0 and old ~= 0 then
		hook.Remove("RM_CanAction", "PT_PreventGettingUp")
	end
end)

if RAGMOD_ENABLED and MOD_ENABLED then
	AddHooks()

	if BONE_BUSTER_VALID then
		hook.Add("PostGamemodeLoaded", "PT_OverrideBBOwnerInitializedHook", function()
			hook.Add("RM_OwnerInitialized", "BB_GetPlayersVel", OwnerInitialized)
		end)
	end
end