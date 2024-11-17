PlayerTumbler_Info.convars = {}
local convars = PlayerTumbler_Info.convars
local cvarFlagsNumeric = FCVAR_ARCHIVE + FCVAR_SERVER_CAN_EXECUTE + FCVAR_NEVER_AS_STRING

convars.EnableMod = CreateConVar("ptumbler_enable", 1, cvarFlagsNumeric, "Enable Player Tumbler", 0, 1)
convars.WeaponDropping = CreateConVar("ptumbler_weapondropping", 1, cvarFlagsNumeric, "Enable weapon dropping", 0, 1)
convars.ExitVehicleRagdoll = CreateConVar("ptumbler_vehicle_exit_ragdoll", 0, cvarFlagsNumeric, "Enable ragdolling when leaving a vehicle", 0, 1)
convars.WallCollision = CreateConVar("ptumbler_wall", 1, cvarFlagsNumeric, "Enable falling when hitting walls", 0, 1)
convars.WallCheck = CreateConVar("ptumbler_wall_check", 1, cvarFlagsNumeric, "Check if there is an object to hit before falling over", 0, 1)
convars.TripCheck = CreateConVar("ptumbler_trip_check", 1, cvarFlagsNumeric, "Check if there is an object to trip over on ground", 0, 1)
convars.AllowTripping = CreateConVar("ptumbler_trip_enable", 1, cvarFlagsNumeric, "Enable tripping on ground", 0, 1)
convars.FallDamage = CreateConVar("ptumbler_fall_damage", 0, cvarFlagsNumeric, "Enable fall damage", 0, 1)
convars.WaterCanRagdoll = CreateConVar("ptumbler_water", 0, cvarFlagsNumeric, "Enable falling in water", 0, 1)
convars.PropHitPlayer = CreateConVar("ptumbler_prophit", 1, cvarFlagsNumeric, "Enable props knocking down players", 0, 1)
convars.PlayerHitProp = CreateConVar("ptumbler_playerhit", 0, cvarFlagsNumeric, "Enable players falling over into props", 0, 1)
convars.PreventMovingGetup = CreateConVar("ptumbler_prevent_moving_getup", 0, cvarFlagsNumeric, "Prevents players from getting up from ragdoll while moving", 0, 1)

convars.ExitVehicleThreshold = CreateConVar("ptumbler_vehicle_exit_threshold", 8, cvarFlagsNumeric, "Sets vehicle exit threshold", 0)
convars.GroundThreshold = CreateConVar("ptumbler_groundthresh", 500, cvarFlagsNumeric, "Sets ground knockover threshold", 0)
convars.AirThreshold = CreateConVar("ptumbler_airthresh", 500, cvarFlagsNumeric, "Sets air knockover threshold", 0)
convars.WaterThreshold = CreateConVar("ptumbler_waterthresh", 250, cvarFlagsNumeric, "Sets water knockover threshold", 0)
convars.GroundMaxVelocity = CreateConVar("ptumbler_groundlimit", 650, cvarFlagsNumeric, "Sets ground velocity limit", 0)
convars.MovingGetupThreshold = CreateConVar("ptumbler_getup_threshold", 200, cvarFlagsNumeric, "Sets velocity players have to be moving under to get up", 0)

convars.GroundUpThreshold = CreateConVar("ptumbler_ground_up_thresh", 350, cvarFlagsNumeric, "Sets ground knockover up threshold", 0)
convars.GroundDownThreshold = CreateConVar("ptumbler_ground_down_thresh", 865, cvarFlagsNumeric, "Sets ground knockover down threshold", 0)
convars.AirUpThreshold = CreateConVar("ptumbler_air_up_thresh", 350, cvarFlagsNumeric, "Sets air knockover up threshold", 0)
convars.AirDownThreshold = CreateConVar("ptumbler_air_down_thresh", 350, cvarFlagsNumeric, "Sets air knockover down threshold", 0)
convars.WaterUpThreshold = CreateConVar("ptumbler_water_up_thresh", 415, cvarFlagsNumeric, "Sets water knockover up threshold", 0)
convars.WaterDownThreshold = CreateConVar("ptumbler_water_down_thresh", 415, cvarFlagsNumeric, "Sets water knockover down threshold", 0)

convars.AutoConfigured = CreateConVar("ptumbler_autoconfigured", 0, cvarFlagsNumeric, "If set to 0, will force RagMod to reconfigure at startup", 0, 1)
convars.AutoConfiguredRagmodV3 = CreateConVar("ptumbler_autoconfigured_legacy", 0, cvarFlagsNumeric, "If set to 0, will force RagMod V3 to reconfigure at startup", 0, 1)