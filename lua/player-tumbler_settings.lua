require("ragmod_utils")

local function CreateCheckBox(panel, cvar, name, tooltip)
	local option = vgui.Create("DCheckBoxLabel", panel)
	local setting = cvars.Bool(cvar, false)

	Derma_Install_Convar_Functions(option)

	option:SetConVar(cvar)
	option:SetText(name)
	option:SetChecked(setting)
	option:SetTextColor(Color(0,0,0,255))

	if isstring(tooltip) then
		option:SetTooltip(tooltip)
	end

	function option:OnChange(val)
		if val then
			option:ConVarChanged("1")
		else
			option:ConVarChanged("0")
		end
	end

	panel:AddItem(option)
end

local function CreateNumberWang(panel, cvar, name, tooltip)
	local label = vgui.Create("DLabel", panel)

	label:SetText(name)
	label:SetTextColor(Color(0,0,0,255))

	panel:AddItem(label)

	local option = vgui.Create("DNumberWang", label)
	local reset = vgui.Create("DImageButton", label)
	local setting = cvars.Number(cvar, 0)
	local default = GetConVar(cvar):GetDefault()

	Derma_Install_Convar_Functions(option)

	option:SetConVar(cvar)
	option:SetMinMax(0, math.huge)
	option:SetValue(setting)
	option:SetX(125)
	option:SetWidth(50)

	if isstring(tooltip) then
		option:SetTooltip(tooltip)
	end

	function option:OnValueChanged(val)
		option:ConVarChanged(tostring(val))
	end

	reset:SetImage("icon16/delete.png")
	reset:SetSize(17, 17)
	reset:SetKeepAspect(true)
	reset:SetX(178)
	reset:SetY(1.75)

	function reset:DoClick()
		option:SetValue(default)
	end
end

local function CreateSpacer(panel, amount)
	local space = vgui.Create("DLabel", panel)

	space:SetTextColor(Color(0,0,0,0))
	space:SetHeight(amount)
	panel:AddItem(space)
end

hook.Add("AddToolMenuTabs", "PT_SettingsCat", function()
	spawnmenu.AddToolCategory(rmutil:GetPhrase("label.tab.ragmod"), "PlayerTumbler", "#Player Tumbler")
end)

hook.Add("PopulateToolMenu", "PT_SettingsOptions", function()
	spawnmenu.AddToolMenuOption(rmutil:GetPhrase("label.tab.ragmod"), "PlayerTumbler", "PlayerTumbler_Server_Settings", "#Server Settings", "", "", function(dform)
		dform:Clear()
		CreateCheckBox(dform, "ptumbler_enable", "Enable mod", "Enables or disables Player Tumbler")
		CreateCheckBox(dform, "ptumbler_weapondropping", "Weapon dropping", "Sets whether or not player's should drop their held weapon on ragdoll")
		CreateCheckBox(dform, "ptumbler_vehicle_exit_ragdoll", "Exiting moving vehicle ragdolls", "Sets if player's should fall over when exiting vehicles at speed")
		CreateCheckBox(dform, "ptumbler_prevent_moving_getup", "Prevent getting up while moving", "Prevents player's from getting up from ragdoll if they are moving too fast")
		CreateCheckBox(dform, "ptumbler_wall", "Momentum system", "This system figures out if player's should fall when hitting walls and such")
		CreateCheckBox(dform, "ptumbler_wall_check", "Collision check", "This ensures player's have to actually hit objects in order to fall over")
		CreateCheckBox(dform, "ptumbler_trip_enable", "Enable tripping", "Should player's fall over when running into walls on the ground")
		CreateCheckBox(dform, "ptumbler_trip_check", "Trip check", "This checks the lower half and upper half of player's to determine if a trip is valid")
		CreateCheckBox(dform, "ptumbler_fall_damage", "Fall damage", "Should fall damage be enabled?")
		CreateCheckBox(dform, "ptumbler_water", "Water momentum system", "Sets if player's can be ragdolled in water")
		CreateCheckBox(dform, "ptumbler_prophit", "Props knockdown players", "Sets if player's can be knocked over by props hitting them with enough momentum")
		CreateCheckBox(dform, "ptumbler_playerhit", "Players fall into props", "Extra check to ensure player's fall over when running into props")

		CreateSpacer(dform, 10)

		CreateNumberWang(dform, "ptumbler_vehicle_exit_threshold", "Vehicle exit threshold")
		CreateNumberWang(dform, "ptumbler_getup_threshold", "Get up threshold")
		CreateNumberWang(dform, "ptumbler_groundthresh", "Ground threshold")
		CreateNumberWang(dform, "ptumbler_airthresh", "Air threshold")
		CreateNumberWang(dform, "ptumbler_waterthresh", "Water threshold")
		CreateNumberWang(dform, "ptumbler_groundlimit", "Ground max speed")

		CreateSpacer(dform, 10)

		CreateNumberWang(dform, "ptumbler_ground_up_thresh", "Ground up threshold")
		CreateNumberWang(dform, "ptumbler_ground_down_thresh", "Ground down threshold")
		CreateNumberWang(dform, "ptumbler_air_up_thresh", "Air up threshold")
		CreateNumberWang(dform, "ptumbler_air_down_thresh", "Air down threshold")
		CreateNumberWang(dform, "ptumbler_water_up_thresh", "Water up threshold")
		CreateNumberWang(dform, "ptumbler_water_down_thresh", "Water down threshold")
	end)
end)