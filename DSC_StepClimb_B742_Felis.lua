-- Auto Step Climb for Felis B742
-- Initial uploader: Dragoljub Blagojevic, DS_Creations
-- License: GNU 3.0
-- Download link: https://github.com/DraggeBagge/Felis-B742-StepClimb-Flywithlua-script

-- Version:
--	1.0	2025-12-17	Initial uppload	//DRAGGEBAGGE
--	1.1	2025-01-04	ISSUE #1 Account for airspeed loss during climb	//DRAGGEBAGGE
-------------------------------------------------------------------------------------------------

if not SUPPORTS_FLOATING_WINDOWS then
    logMsg("DSC_StepClimb_B742_Felis: ImGui not supported by your FlyWithLua version")
    return
end
local delay_start = os.clock()
local delay_duration = 5  -- seconds.
local delay_done = false

-- Global variables - Sim
selected_mode = "085"
starting_mach = nil
starting_mach_counter = 0

-- Global variables - Menu
script_enabled = false
mode_options = { "085", "LRC" }

-- Global variables returned values if stepclimb initiated
pending_alt = nil
pending_alt_sel = nil
pending_at_mode = nil


-- Flight engineers table in hash for Automatic calculation
weight_to_altitude_hash = {
	["085"] = {
		[175500] = 45000, [185100] = 44000, [194100] = 43000, [203700] = 42000, [214100] = 41000,
		[224500] = 40000, [235900] = 39000, [246300] = 38000, [258100] = 37000, [269400] = 36000,
		[281200] = 35000, [296200] = 34000, [310700] = 33000, [322100] = 32000, [335700] = 31000,
		[353800] = 30000, [371900] = 29000
	},
	["LRC"] = {
		[170100] = 45000, [178300] = 44000, [188200] = 43000, [198200] = 42000, [208700] = 41000,
		[217700] = 40000, [224100] = 39000, [240000] = 38000, [250400] = 37000, [263100] = 36000,
		[278100] = 35000, [292600] = 34000, [308400] = 33000, [317500] = 32000, [331100] = 31000,
		[344700] = 30000, [360600] = 29000, [371900] = 28000
	}
}
logMsg("DSC StepClimb: Mode table initialized with keys: " .. table.concat(mode_options, ", "))

-- Only applicable for FL340 and above checks
weight_to_altitude_hash_ISA = {
	["ISA+10"] = {
		[176000] = 45000, [186900] = 44000, [199600] = 43000, [214100] = 42000, [227700] = 41000,
		[242200] = 40000, [255800] = 39000, [269400] = 38000, [282600] = 37000, [296300] = 36000,
		[308400] = 35000, [321600] = 34000
	},
	["ISA+15"] = {
		[168900] = 45000, [181900] = 44000, [196000] = 43000, [209600] = 42000, [223200] = 41000,
		[236100] = 40000, [249500] = 39000, [263000] = 38000, [275800] = 37000, [288500] = 36000,
		[300700] = 35000, [313000] = 34000
	},
	["ISA+20"] = {
		[163300] = 45000, [176900] = 44000, [189600] = 43000, [202300] = 42000, [215000] = 41000,
		[229100] = 40000, [242200] = 39000, [254800] = 38000, [267600] = 37000, [280300] = 36000,
		[291700] = 35000, [299400] = 34000
	}
}

-- Menu layout
function build_stepclimb_menu(wnd, x, y)
    imgui.TextUnformatted("Step Climb Configuration")
    imgui.TextUnformatted("")
	imgui.TextUnformatted("NOTE! Enable only in stable cruise")
	imgui.TextUnformatted("")
	imgui.TextUnformatted("The stepclimb script is automatically checking if ISA is limiting factor")
	
    local script_enabled_changed_check, new_value = imgui.Checkbox("Enable Step Climb Script", script_enabled)
    if script_enabled_changed_check then
        script_enabled = new_value
	end
	
    imgui.TextUnformatted("")
    imgui.TextUnformatted("Select Step Climb Mode:")
	
    for i, label in ipairs(mode_options) do
        local selected = (selected_mode == label)
        local mode_changed_check = imgui.RadioButton(label, selected)
        if mode_changed_check then
            selected_mode = label
		end
        if i % 3 ~= 0 then imgui.SameLine() end
	end
end

function toggle_stepclimb_menu()
    if stepclimb_menu_wnd then
        float_wnd_destroy(stepclimb_menu_wnd)
        stepclimb_menu_wnd = nil
		else
        stepclimb_menu_wnd = float_wnd_create(400, 200, 1, true)
        float_wnd_set_title(stepclimb_menu_wnd, "DSC Stepclimb B742 Felis v1.0")
        float_wnd_set_imgui_builder(stepclimb_menu_wnd, "build_stepclimb_menu")
	end
end

-- lookup function for biggest key
function find_ceiling_key(tbl, value)
	local ceiling_key = nil
	local max_key = nil
	
	for k,_ in pairs(tbl) do
		local nk = tonumber(k)
		if not max_key or nk > max_key then
			max_key = nk
		end
		if nk >= value then
			if not ceiling_key or nk < ceiling_key then
				ceiling_key = nk
			end
		end
	end
	return ceiling_key or max_key -- if no ceiling found, use max key
end

-- ISA temperature at altitude (ft)
function isa_temp(alt_ft)
    if alt_ft <= 36000 then
        return 15 - 0.0019812 * alt_ft
		else
        return -56.5 -- temperature after entering tropopause
	end
end

-- ISA deviation
function isa_deviation(oat_c, alt_ft)
    return oat_c - isa_temp(alt_ft)
end

function step_climb(script_enabled_prm,on_ground_prm,oat_prm,selected_mode_prm,current_weight_prm,indicated_altitude_prm,magnetic_track_prm,at_mode_mach_btn_prm,ap_alt_prm,alt_sel_prm)
	
    if script_enabled_prm == false or on_ground_prm == 1 then 
		starting_mach = nil
		starting_mach_counter = 0
		return
	end
	at_on_sw = 1 -- make sure AT is always on if script enabled because it disengages shortly during script use
	
	if starting_mach_counter == 0 then
		starting_mach = current_mach
		starting_mach_counter = 1
	end
	
	local mode_key = selected_mode_prm
    if not mode_key or not weight_to_altitude_hash[mode_key] then
        logMsg(string.format("DSC StepClimb: Invalid or nil mode '%s', falling back to '085'", tostring(mode_key)))
        mode_key = "085"
	end
	
    local mode_tbl = weight_to_altitude_hash[mode_key]
    if not mode_tbl then
        logMsg("DSC StepClimb: No valid mode table found, aborting.")
        return
	end
	
	
	local weight = find_ceiling_key(mode_tbl, current_weight_prm)
    local base_altitude = mode_tbl[weight]
	
	-- Check if ISA is even limiting us... (only FL340 and above)
    local dev = isa_deviation(oat_prm, indicated_altitude_prm)
	
    local limiting_altitude = base_altitude
    if indicated_altitude_prm + 100 >= 34000 then -- 100 ft margin for not exact indicated altitudes
        local isa_tbl = nil
        if dev >= 20 then
            isa_tbl = weight_to_altitude_hash_ISA["ISA+20"]
			elseif dev >= 15 then
            isa_tbl = weight_to_altitude_hash_ISA["ISA+15"]
			elseif dev >= 10 then
            isa_tbl = weight_to_altitude_hash_ISA["ISA+10"]
		end
		
        if isa_tbl then
            local isa_key = find_ceiling_key(isa_tbl, current_weight_prm)
            local isa_alt = isa_tbl[isa_key]
            if isa_alt and isa_alt < limiting_altitude then
                limiting_altitude = isa_alt
			end
		end
	end
	
	if (limiting_altitude - 850) <= indicated_altitude_prm then
		if current_mach < starting_mach then -- will continue to speed up with EPR engaged.
		else at_mode_mach_btn = 1 end -- makes sure mach epr btn is set when not in climb in addition to not uneccesserly stepclimbing.
		return
	end
	
    -- Directional flight level parity check (east/westbound)
    local is_eastbound = magnetic_track_prm >= 0 and magnetic_track_prm < 180
    local is_odd = (limiting_altitude / 1000) % 2 == 1
	
    if (is_eastbound and is_odd) or (not is_eastbound and not is_odd) then
		air_cond_rotary = limiting_altitude / 1000 - 20 -- the relationship between rotary knob and the selected cabin alt is 20
		
		ap_alt = limiting_altitude
        alt_sel = -1
		at_mode_epr_btn = 1 
		ap_pitch_mode_sel = 3 -- automatically switched to 0(off) byu aircraft when correct FL reached
		at_on_sw = 1
        logMsg(string.format("DSC: Step climb triggered: Weight=%d, ISA Dev=%.1f, New FL=%d", current_weight_prm, dev, limiting_altitude/100))
		
	end
end




-- Main
function wait_for_datarefs()
	if not delay_done and os.clock() - delay_start >= delay_duration then
		delay_done = true
		if (PLANE_ICAO == "B742") then
			
			-- REQUIRED DATAREFS
			dataref("on_ground", "sim/flightmodel/failures/onground_any", "readonly")							-- On ground check
			dataref("oat", "sim/weather/aircraft/temperature_ambient_deg_c", "readonly")						-- Outside air temperature
			dataref("indicated_altitude", "sim/cockpit2/gauges/indicators/altitude_ft_pilot", "readonly")		-- Current indicated altitude
			dataref("magnetic_track", "sim/flightmodel/position/mag_psi", "readonly")							-- Current magnetic track (for semicircle rule!)
			dataref("current_weight", "sim/flightmodel/weight/m_total", "readonly")								-- Current gross weight
			dataref("ap_alt",	"B742/AP_panel/altitude_set", "writable")										-- Current autopilot altitude
			dataref("ap_pitch_mode_sel",	"B742/AP_panel/AP_pitch_mode_sel",	"writable")						-- AP Pitch mode selector setting -1 to 3, 3 is MACH
			dataref("at_on_sw",	"B742/AP_panel/AT_on_sw", "writable")											-- A/T off(0)/on(-1)
			dataref("current_mach",	"sim/cockpit2/gauges/indicators/mach_pilot", "readonly")					-- MACH Indicated CPT side
			dataref("at_mode_mach_btn",	"B742/EPRL/mode_mach_button", "writable")								-- A/T mode MACH
			dataref("at_mode_epr_btn",	"B742/EPRL/mode_epr_button", "writable")								-- A/T mode EPR
			dataref("at_eprl_sel",	"B742/EPRL/eprl_mode_sel", "writable")										-- EPRL setting 1 to 5, 4 is CRZ
			dataref("alt_sel",	"B742/AP_panel/altitude_mode_sw", "writable")									-- ALT SEL off(0)/on(-1) ALT hold (1)
			dataref("air_cond_rotary",	"B742/AIR_COND/altitude_rotary", "writable")							-- Air condition altitude rotary which sets air cond gaguge (AIR_COND/altitude_gauge)
			dataref("at_rst_cpt",	"B742/AP_mode_panel/AT_RST_button", "writable")								-- Resets the A/T warning
			
			add_macro("DSC StepClimb B742 Felis", "toggle_stepclimb_menu()")
			
			do_sometimes([[
				step_climb(
				script_enabled,
				on_ground,
				oat,
				selected_mode,
				current_weight,
				indicated_altitude,
				magnetic_track,
				at_mode_mach_btn,
				ap_alt,
				alt_sel
				)
			]])
			
		end
		logMsg("Delay complete. Proceeding with script execution.")
	end
end

do_every_frame("wait_for_datarefs()")
-- Main end