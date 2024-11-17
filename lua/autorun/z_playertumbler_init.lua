if SERVER then
	PlayerTumbler_Info = {
		RAGMOD_REWORKED = true,
		ragmod = require("ragmod")
	}

	include("Player-Tumbler_Convars.lua")
	include("Player-Tumbler_Main.lua")
	include("Player-Tumbler_WeaponDropping.lua")
	--AddCSLuaFile("Player-Tumbler_Settings.lua")
--else
	--include("Player-Tumbler_Settings.lua")
end