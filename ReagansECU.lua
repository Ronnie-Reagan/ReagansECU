-- Reagan's ECU

--#region Variables

-- file save names
local settingsFilename = "Reagans_ECU_settings.json"
local vehicleDataFilename = "Reagans_ECU_User_Vehicles.json"

-- avoid adding things to this table, the merge function only adds things to the saved settings
local settings = {
    version = 1.62,
    odometer = {
        autorun = false,
        delay = 0.25
    },
    debugMode = false,
    debugLogging = false,
    userPrints = true,
    tuner = {
        autoTune = true,
        autorun = true
    },
    timesLoaded = 0
}

local settingsDefaults = settings

local userOwnedVehicles = {} -- Changed from keyed table to array

local speedmode = {
    kph = 3.6,
    mph = 2.23694
}

local utilities = {
    prompting = false,
    promptComplete = false,
    promptResult = false,
    keycodes = {
        y = 89,
        n = 78
    }
}

local updatesSkipped = 1
local saveTimer = 101

local tempMemory = {
    currentVehicle = nil,
    savingData = false,
    odometer = {
        started = false,
        running = false,
    },
    acceleration = {
        tracking = false,
        startTime = 0,
        reached60 = false,
        lastSpeed = 0,
        startPoint = { x = nil, y = nil, z = nil },
        finishPoint = { x = nil, y = nil, z = nil }
    }
}

local credits = {
    developer =
        "\n\nHey, It's Don Reagan!\n" ..
        "Thank you for using my script, it means alot to me that people get to enjoy what I create.\n" ..
        "While I may not play gta anymore, I put a lot of work into my scripts for people like you to enjoy playing it a little bit more.\n" ..
        "Please feel free to message me on Discord if you have any questions or ideas to make the script better for everyone.\n" ..
        "\n" ..
        "-Don Reagan\n" ..
        "Discord: keef_it_up\n",
    QA =
    "\nQuality Assurance Specialist: NO TESTER\n",
    expert =
        "\n\nExpert: Gaymer\n" ..
        "Without your help I would still be sitting around wondering what it would be like to develop my own scripts.\n" ..
        "Thank you for your patience and for sharing your knowledge with me, knowing i knew noting about making lua scripts.\n" ..
        "Ever since the first speedometer I made, You have been my main source of knowledge in the world of GTA modding and coding in general\n"
}

--#endregion

--#region Tuning Pointers
local tuning_pointers = {
    performance = {
        { name = "Initial Drive Force",             type = "float", key = "initial_drive_force",             set = "set_initial_drive_force",             get = "get_initial_drive_force",             min = 0.0,      max = 5.0,   step = 0.01, default = 1.0 },
        { name = "Initial Drive Gears",             type = "int",   key = "initial_drive_gears",             set = "set_initial_drive_gears",             get = "get_initial_drive_gears",             min = 1,        max = 10,    step = 1,    default = 5 },
        { name = "Initial Drive Max Flat Velocity", type = "float", key = "initial_drive_max_flat_velocity", set = "set_initial_drive_max_flat_velocity", get = "get_initial_drive_max_flat_velocity", min = 0.0,      max = 400.0, step = 1.0,  default = 200.0 },
        { name = "Down Shift",                      type = "float", key = "down_shift",                      set = "set_down_shift",                      get = "get_down_shift",                      min = 0.0,      max = 100.0, step = 0.1,  default = 1.0 },
        { name = "Up Shift",                        type = "float", key = "up_shift",                        set = "set_up_shift",                        get = "get_up_shift",                        min = 0.0,      max = 100.0, step = 0.1,  default = 1.0 },
        { name = "Max Speed",                       type = "float", key = "max_speed",                       set = "set_max_speed",                       get = "get_max_speed",                       min = 0.0,      max = 400.0, step = 1.0,  default = 200.0 },
        { name = "Acceleration",                    type = "float", key = "acceleration",                    set = "set_acceleration",                    get = "get_acceleration",                    min = 0.0,      max = 10.0,  step = 0.1,  default = 1.0 },
        { name = "Boost",                           type = "float", key = "boost",                           set = "set_boost",                           get = "get_boost",                           min = 0.0,      max = 50.0,  step = 0.1,  default = 0.0 },
        { name = "Boost Active",                    type = "bool",  key = "boost_active",                    set = "set_boost_active",                    get = "get_boost_active",                    default = false },
        { name = "Boost Enabled",                   type = "bool",  key = "boost_enabled",                   set = "set_boost_enabled",                   get = "get_boost_enabled",                   default = false },
    },
    handling = {
        { name = "Anti Roll Bar Bias Front",           type = "float",   key = "anti_roll_bar_bias_front",           set = "set_anti_roll_bar_bias_front",           get = "get_anti_roll_bar_bias_front",           min = 0.0,                        max = 1.0,     step = 0.01, default = 0.5 },
        { name = "Anti Roll Bar Force",                type = "float",   key = "anti_roll_bar_force",                set = "set_anti_roll_bar_force",                get = "get_anti_roll_bar_force",                min = 0.0,                        max = 10.0,    step = 0.1,  default = 1.0 },
        { name = "Brake Bias Front",                   type = "float",   key = "brake_bias_front",                   set = "set_brake_bias_front",                   get = "get_brake_bias_front",                   min = 0.0,                        max = 1.0,     step = 0.01, default = 0.5 },
        { name = "Brake Force",                        type = "float",   key = "brake_force",                        set = "set_brake_force",                        get = "get_brake_force",                        min = 0.0,                        max = 5.0,     step = 0.1,  default = 1.0 },
        { name = "Centre of Mass Offset",              type = "vector3", key = "centre_of_mass_offset",              set = "set_centre_of_mass_offset",              get = "get_centre_of_mass_offset",              default = { x = 0, y = 0, z = 0 } },
        { name = "Handbrake Force",                    type = "float",   key = "handbrake_force",                    set = "set_handbrake_force",                    get = "get_handbrake_force",                    min = 0.0,                        max = 10.0,    step = 0.1,  default = 1.0 },
        { name = "Inertia Multiplier",                 type = "vector3", key = "inertia_multiplier",                 set = "set_inertia_multiplier",                 get = "get_inertia_multiplier",                 default = { x = 1, y = 1, z = 1 } },
        { name = "Initial Drag Coeff",                 type = "float",   key = "initial_drag_coeff",                 set = "set_initial_drag_coeff",                 get = "get_initial_drag_coeff",                 min = 0.0,                        max = 10.0,    step = 0.01, default = 1.0 },
        { name = "Low Speed Traction Loss Multiplier", type = "float",   key = "low_speed_traction_loss_multiplier", set = "set_low_speed_traction_loss_multiplier", get = "get_low_speed_traction_loss_multiplier", min = 0.0,                        max = 5.0,     step = 0.1,  default = 1.0 },
        { name = "Mass",                               type = "float",   key = "mass",                               set = "set_mass",                               get = "get_mass",                               min = 0.0,                        max = 10000.0, step = 1.0,  default = 1500.0 },
        { name = "Drift Tyres Enabled",                type = "bool",    key = "drift_tyres_enabled",                set = "set_drift_tyres_enabled",                get = "get_drift_tyres_enabled",                default = false },
        { name = "Drift Vehicle Reduced Suspension",   type = "bool",    key = "drift_vehicle_reduced_suspension",   set = "set_drift_vehicle_reduced_suspension",   get = "get_drift_vehicle_reduced_suspension",   default = false },
        { name = "Drive Bias Front",                   type = "float",   key = "drive_bias_front",                   set = "set_drive_bias_front",                   get = "get_drive_bias_front",                   min = 0.0,                        max = 1.0,     step = 0.01, default = 0.5 },
        { name = "Drive Inertia",                      type = "vector3", key = "drive_inertia",                      set = "set_drive_inertia",                      get = "get_drive_inertia",                      default = { x = 1, y = 1, z = 1 } },
        { name = "Steering Lock",                      type = "float",   key = "steering_lock",                      set = "set_steering_lock",                      get = "get_steering_lock",                      min = 0.0,                        max = 90.0,    step = 1.0,  default = 35.0 },
        { name = "Suspension Bias Front",              type = "float",   key = "suspension_bias_front",              set = "set_suspension_bias_front",              get = "get_suspension_bias_front",              min = 0.0,                        max = 1.0,     step = 0.01, default = 0.5 },
        { name = "Suspension Comp Damp",               type = "float",   key = "suspension_comp_damp",               set = "set_suspension_comp_damp",               get = "get_suspension_comp_damp",               min = 0.0,                        max = 10.0,    step = 0.1,  default = 1.0 },
        { name = "Suspension Force",                   type = "float",   key = "suspension_force",                   set = "set_suspension_force",                   get = "get_suspension_force",                   min = 0.0,                        max = 10.0,    step = 0.1,  default = 1.0 },
        { name = "Suspension Height",                  type = "float",   key = "suspension_height",                  set = "set_suspension_height",                  get = "get_suspension_height",                  min = 0.0,                        max = 10.0,    step = 0.1,  default = 1.0 },
        { name = "Suspension Lower Limit",             type = "float",   key = "suspension_lower_limit",             set = "set_suspension_lower_limit",             get = "get_suspension_lower_limit",             min = 0.0,                        max = 10.0,    step = 0.1,  default = 1.0 },
        { name = "Suspension Raise",                   type = "float",   key = "suspension_raise",                   set = "set_suspension_raise",                   get = "get_suspension_raise",                   min = 0.0,                        max = 10.0,    step = 0.1,  default = 1.0 },
        { name = "Suspension Rebound Damp",            type = "float",   key = "suspension_rebound_damp",            set = "set_suspension_rebound_damp",            get = "get_suspension_rebound_damp",            min = 0.0,                        max = 10.0,    step = 0.1,  default = 1.0 },
        { name = "Suspension Upper Limit",             type = "float",   key = "suspension_upper_limit",             set = "set_suspension_upper_limit",             get = "get_suspension_upper_limit",             min = 0.0,                        max = 10.0,    step = 0.1,  default = 1.0 },
        { name = "Camber Stiffness",                   type = "float",   key = "camber_stiffness",                   set = "set_camber_stiffness",                   get = "get_camber_stiffness",                   min = 0.0,                        max = 10.0,    step = 0.1,  default = 1.0 },
        { name = "Traction Bias Front",                type = "float",   key = "traction_bias_front",                set = "set_traction_bias_front",                get = "get_traction_bias_front",                min = 0.0,                        max = 1.0,     step = 0.01, default = 0.5 },
        { name = "Traction Curve Lateral",             type = "float",   key = "traction_curve_lateral",             set = "set_traction_curve_lateral",             get = "get_traction_curve_lateral",             min = 0.0,                        max = 10.0,    step = 0.1,  default = 1.0 },
        { name = "Traction Curve Max",                 type = "float",   key = "traction_curve_max",                 set = "set_traction_curve_max",                 get = "get_traction_curve_max",                 min = 0.0,                        max = 100.0,   step = 0.1,  default = 1.0 },
        { name = "Traction Curve Min",                 type = "float",   key = "traction_curve_min",                 set = "set_traction_curve_min",                 get = "get_traction_curve_min",                 min = 0.0,                        max = 100.0,   step = 0.1,  default = 1.0 },
        { name = "Traction Loss Multiplier",           type = "float",   key = "traction_loss_multiplier",           set = "set_traction_loss_multiplier",           get = "get_traction_loss_multiplier",           min = 0.0,                        max = 50.0,    step = 0.1,  default = 1.0 },
        { name = "Traction Spring Delta Max",          type = "float",   key = "traction_spring_delta_max",          set = "set_traction_spring_delta_max",          get = "get_traction_spring_delta_max",          min = 0.0,                        max = 10.0,    step = 0.1,  default = 1.0 },
        { name = "Gravity",                            type = "float",   key = "gravity",                            set = "set_gravity",                            get = "get_gravity",                            min = -20.0,                      max = 200.0,   step = 1.0,  default = 9.81 },
        { name = "Roll Centre Height Front",           type = "float",   key = "roll_centre_height_front",           set = "set_roll_centre_height_front",           get = "get_roll_centre_height_front",           min = 0.0,                        max = 10.0,    step = 0.1,  default = 1.0 },
        { name = "Roll Centre Height Rear",            type = "float",   key = "roll_centre_height_rear",            set = "set_roll_centre_height_rear",            get = "get_roll_centre_height_rear",            min = 0.0,                        max = 10.0,    step = 0.1,  default = 1.0 },
    },
    aesthetics = {
        { name = "Dirt Level",              type = "float",  key = "dirt_level",              set = "set_dirt_level",              get = "get_dirt_level",              min = 0.0,                  max = 10.0, step = 0.1, default = 0.0 },
        { name = "Number Plate Index",      type = "int",    key = "number_plate_index",      set = "set_number_plate_index",      get = "get_number_plate_index",      min = 0,                    max = 10,   step = 1,   default = 0 },
        { name = "Number Plate Text",       type = "string", key = "number_plate_text",       set = "set_number_plate_text",       get = "get_number_plate_text",       default = "DEFAULT" },
        { name = "Window Tint",             type = "int",    key = "window_tint",             set = "set_window_tint",             get = "get_window_tint",             min = 0,                    max = 10,   step = 1,   default = 0 },
        { name = "Custom Primary Colour",   type = "rgb",    key = "custom_primary_colour",   set = "set_custom_primary_colour",   get = "get_custom_primary_colour",   default = { 0, 0, 0 } },       -- Default black
        { name = "Custom Secondary Colour", type = "rgb",    key = "custom_secondary_colour", set = "set_custom_secondary_colour", get = "get_custom_secondary_colour", default = { 255, 255, 255 } }, -- Default white
    },
    reliability = {
        { name = "Godmode",                       type = "bool",  key = "godmode",                       set = "set_godmode",                       get = "get_godmode",                       default = false },
        { name = "Health",                        type = "float", key = "health",                        set = "set_health",                        get = "get_health",                        min = 0.0,      max = 1000.0, step = 10.0, default = 1000.0 },
        { name = "Bouyance",                      type = "float", key = "bouyance",                      set = "set_bouyance",                      get = "get_bouyance",                      min = 0.0,      max = 10.0,   step = 0.1,  default = 1.0 },
        { name = "Bulletproof Tires",             type = "bool",  key = "bulletproof_tires",             set = "set_bulletproof_tires",             get = "get_bulletproof_tires",             default = false },
        { name = "Can Be Targeted",               type = "bool",  key = "can_be_targeted",               set = "set_can_be_targeted",               get = "get_can_be_targeted",               default = true },
        { name = "Can Be Visibly Damaged",        type = "bool",  key = "can_be_visibly_damaged",        set = "set_can_be_visibly_damaged",        get = "get_can_be_visibly_damaged",        default = true },
        { name = "Collision Damage Multiplier",   type = "float", key = "collision_damage_multiplier",   set = "set_collision_damage_multiplier",   get = "get_collision_damage_multiplier",   min = 0.0,      max = 10.0,   step = 0.1,  default = 1.0 },
        { name = "Deformation Damage Multiplier", type = "float", key = "deformation_damage_multiplier", set = "set_deformation_damage_multiplier", get = "get_deformation_damage_multiplier", min = 0.0,      max = 10.0,   step = 0.1,  default = 1.0 },
        { name = "Window Collisions Disabled",    type = "bool",  key = "window_collisions_disabled",    set = "set_window_collisions_disabled",    get = "get_window_collisions_disabled",    default = false },
        { name = "Engine Damage Multiplier",      type = "float", key = "engine_damage_multiplier",      set = "set_engine_damage_multiplier",      get = "get_engine_damage_multiplier",      min = 0.0,      max = 10.0,   step = 0.1,  default = 1.0 },
    },
    misc = {
        { name = "Bomb Count",                  type = "int",     key = "bomb_count",                  set = "set_bomb_count",                  get = "get_bomb_count",                  min = 0,                          max = 10,    step = 1,   default = 0 },
        { name = "Countermeasure Count",        type = "int",     key = "countermeasure_count",        set = "set_countermeasure_count",        get = "get_countermeasure_count",        min = 0,                          max = 10,    step = 1,   default = 0 },
        { name = "Create Money Pickups",        type = "bool",    key = "create_money_pickups",        set = "set_create_money_pickups",        get = "get_create_money_pickups",        default = false },
        { name = "Model Hash",                  type = "int",     key = "model_hash",                  set = "set_model_hash",                  get = "get_model_hash",                  default = 0 },
        { name = "Parachute Hash",              type = "int",     key = "parachute_hash",              set = "set_parachute_hash",              get = "get_parachute_hash",              default = 0 },
        { name = "Parachute Texture Variation", type = "int",     key = "parachute_texture_variation", set = "set_parachute_texture_variation", get = "get_parachute_texture_variation", min = 0,                          max = 10,    step = 1,   default = 0 },
        { name = "Percent Submerged",           type = "float",   key = "percent_submerged",           set = "set_percent_submerged",           get = "get_percent_submerged",           min = 0.0,                        max = 100.0, step = 0.1, default = 0.0 },
        { name = "Position",                    type = "vector3", key = "position",                    set = "set_position",                    get = "get_position",                    default = { x = 0, y = 0, z = 0 } },
        { name = "Rotation",                    type = "vector3", key = "rotation",                    set = "set_rotation",                    get = "get_rotation",                    default = { x = 0, y = 0, z = 0 } },
        { name = "Weapon Damage Multiplier",    type = "float",   key = "weapon_damage_multiplier",    set = "set_weapon_damage_multiplier",    get = "get_weapon_damage_multiplier",    min = 0.0,                        max = 10.0,  step = 0.1, default = 1.0 },
        { name = "Door Lock State",             type = "int",     key = "door_lock_state",             set = "set_door_lock_state",             get = "get_door_lock_state",             min = 0,                          max = 10,    step = 1,   default = 0 },
    },
    getterOnly = {
        { name = "Velocity",           type = "vector3", key = "velocity",           get = "get_velocity" },
        { name = "Mission Flags",      type = "int",     key = "mission_flags",      get = "get_mission_flags" },
        { name = "Handling Name Hash", type = "int",     key = "handling_name_hash", get = "get_handling_name_hash" },
        { name = "Heading",            type = "vector3", key = "heading",            get = "get_heading" },
    }
}
--#endregion

--#region Vehicle Hashes
local vehicleHashes = {
    [-1132721664] = "Imorgon",
    [1456336509] = "Vstr",
    [1284356689] = "Zhaba",
    [740289177] = "Vargant",
    [872704284] = "Sultan Classic",
    [987469656] = "Sugoi",
    [301304410] = "Stryder",
    [2031587082] = "Retinue2",
    [408825843] = "Outlaw",
    [394110044] = "Jb7002",
    [960812448] = "Furia",
    [-1960756985] = "Formula2",
    [340154634] = "Formula",
    [-1756021720] = "Everon",
    [-2098954619] = "Club",
    [-1728685474] = "Coquette4",
    [2134119907] = "Beater Dukes",
    [-2122646867] = "Gauntlet5",
    [-913589546] = "Glendale Custom",
    [-838099166] = "Landstalker2",
    [1717532765] = "Manana2",
    [1492612435] = "Openwheel1",
    [1181339704] = "Openwheel2",
    [-631322662] = "Penumbra2",
    [1107404867] = "Peyote Custom",
    [-1810806490] = "Seminole Frontier",
    [-1358197432] = "Tigon",
    [1802742206] = "Youga3",
    [-777275802] = "Freighttrailer",
    [-1744505657] = "Impaler4",
    [600450546] = "Hustler",
    [628003514] = "Issi4",
    [-1293924613] = "Dominator6",
    [1239571361] = "Issi6",
    [679453769] = "Cerberus2",
    [1279262537] = "Deviant",
    [-579747861] = "Scarab3",
    [1502869817] = "Trailerlarge",
    [-1259134696] = "Flashgt",
    [-1374500452] = "Deathbike3",
    [1938952078] = "Firetruk",
    [1721676810] = "Monster3",
    [-1146969353] = "Scarab",
    [-42959138] = "Hunter",
    [1637620610] = "Imperator2",
    [840387324] = "Monster4",
    [-376434238] = "Tyrant",
    [1254014755] = "Caracara",
    [-1134706562] = "Taipan",
    [788045382] = "Sanchez",
    [-214906006] = "Jester Classic",
    [1542143200] = "Scarab2",
    [931280609] = "Issi3",
    [1046206681] = "Michelli",
    [-1694081890] = "Bruiser2",
    [1537277726] = "Issi5",
    [-1924800695] = "Impaler3",
    [1742022738] = "Slamvan6",
    [1617472902] = "Fagaloa",
    [-1100548694] = "Trailers4",
    [-2042350822] = "Bruiser3",
    [-1566607184] = "Clique",
    [1118611807] = "Asbo",
    [409049982] = "Kanjo",
    [-1254331310] = "Minitank",
    [1693751655] = "Yosemite2",
    [83136452] = "Rebla",
    [-834353991] = "Komoda",
    [159274291] = "Ardent",
    [1011753235] = "Coquette2",
    [1051415893] = "Jb700",
    [418536135] = "Infernus",
    [-1558399629] = "Tornado6",
    [-1566741232] = "Feltzer3",
    [-982130927] = "Turismo2",
    [1762279763] = "Tornado3",
    [1504306544] = "Torero",
    [500482303] = "Swinger",
    [1483171323] = "Deluxo",
    [1841130506] = "Retinue",
    [886810209] = "Stromberg",
    [-882629065] = "Nebula",
    [668439077] = "Bruiser",
    [2139203625] = "Brutus",
    [444994115] = "Imperator",
    [2038858402] = "Brutus3",
    [1009171724] = "Impaler2",
    [868868440] = "Metrotrain",
    [-1476447243] = "Armytrailer",
    [-2061049099] = "Slamvan4",
    [219613597] = "Speedo4",
    [-1812949672] = "Deathbike2",
    [1126868326] = "Bfinjection",
    [-801550069] = "Cerberus",
    [373261600] = "Slamvan5",
    [1909189272] = "Gb200",
    [-1267543371] = "Ellie",
    [838982985] = "Z190",
    [661493923] = "Comet5",
    [-755532233] = "Imperator3",
    [-1375060657] = "Future Shock Dominator",
    [-688189648] = "Apocalypse Dominator",
    [-27326686] = "Deathbike",
    [408970549] = "Avenger2",
    [-1890996696] = "Brutus2",
    [-2120700196] = "Entity2",
    [-715746948] = "Monster5",
    [-121446169] = "Kamacho",
    [1909700336] = "Cerberus3",
    [-1842748181] = "Faggio",
    [2069146067] = "Oppressor2",
    [-891462355] = "Bati2",
    [-757735410] = "Fcr2",
    [-609625092] = "Vortex",
    [-1352468814] = "Trflat",
    [1019737494] = "Graintrailer",
    [-1770643266] = "Tvtrailer",
    [1854776567] = "Issi7",
    [1922255844] = "Schafter6",
    [-1372848492] = "Kuruma",
    [-1106353882] = "Jester2",
    [736902334] = "Buffalo2",
    [353883353] = "Polmav",
    [-1973172295] = "Unmarked Cruiser",
    [-1779120616] = "Police RoadCruiser",
    [-2007026063] = "Prison Bus",
    [2046537925] = "Police Cruiser ()",
    [-1536924937] = "Police Rancher",
    [1912215274] = "Police Cruiser ()",
    [1127131465] = "Fbi",
    [-1205689942] = "Riot",
    [-1627000575] = "Police Cruiser ()",
    [469291905] = "Lguard",
    [719660200] = "Ruston",
    [108773431] = "Coquette",
    [-1106120762] = "Zr3802",
    [1104234922] = "Sentinel3",
    [-1089039904] = "Furore GT",
    [-1757836725] = "Seven70",
    [310284501] = "Dynasty",
    [-777172681] = "Omnis",
    [-566387422] = "Elegy2",
    [-1041692462] = "Banshee",
    [237764926] = "Buffalo3",
    [-2022483795] = "Comet3",
    [-1848994066] = "Neon",
    [410882957] = "Kuruma2",
    [-208911803] = "Jugular",
    [-331467772] = "Italigto",
    [767087018] = "Alpha",
    [499169875] = "Fusilade",
    [1102544804] = "Verlierer2",
    [-1620126302] = "Neo",
    [867799010] = "Pariah",
    [-1529242755] = "Raiden",
    [1074745671] = "Specter2",
    [1489967196] = "Schafter4",
    [-1485523546] = "Schafter3",
    [196747873] = "Elegy",
    [686471183] = "Drafter",
    [-591651781] = "Blista3",
    [-377465520] = "Penumbra",
    [-447711397] = "Paragon",
    [1886268224] = "Specter",
    [-941272559] = "Locust",
    [1039032026] = "Blista2",
    [540101442] = "Zr380",
    [-304802106] = "Buffalo",
    [-1045541610] = "Comet2",
    [-1995326987] = "Feltzer2",
    [544021352] = "Khamelion",
    [-888242983] = "Schafter5",
    [1032823388] = "Obey 9F",
    [-1461482751] = "Ninef2",
    [-362150785] = "Hellion",
    [-286046740] = "Rcbandito",
    [-54332285] = "Freecrawler",
    [101905590] = "Trophytruck",
    [1233534620] = "Marshall",
    [-1435919434] = "Bodhi2",
    [-1590337689] = "Blazer5",
    [-1237253773] = "Dubsta3",
    [-1479664699] = "Brawler",
    [1645267888] = "Rancherxl",
    [-2045594037] = "Rebel2",
    [-845961253] = "Monster",
    [-663299102] = "Trophytruck2",
    [92612664] = "Kalahari",
    [-312295511] = "Ramp Buggy 2",
    [-827162039] = "Ramp Buggy",
    [-2103821244] = "Rallytruck",
    [-1912017790] = "Wastelander",
    [1917016601] = "Trash",
    [-305727417] = "Brickade",
    [1283517198] = "Airbus",
    [1941029835] = "Tourbus",
    [-2072933068] = "Coach",
    [-713569950] = "Bus",
    [-956048545] = "Taxi",
    [345756458] = "Pbus2",
    [-1098802077] = "Rentalbus",
    [-1255698084] = "Trash2",
    [-311022263] = "Seashark3",
    [1448677353] = "Tropic2",
    [1033245328] = "Dinghy",
    [-1066334226] = "Submersible2",
    [861409633] = "Jetmax",
    [1070967343] = "Toro",
    [-616331036] = "Seashark2",
    [290013743] = "Tropic",
    [-2100640717] = "Tug",
    [400514754] = "Squalo",
    [771711535] = "Submersible",
    [1739845664] = "Bison3",
    [-1743316013] = "Burrito3",
    [-1126264336] = "Minivan2",
    [-16948145] = "Bison",
    [728614474] = "Speedo2",
    [1026149675] = "Youga2",
    [-810318068] = "Speedo",
    [-1987130134] = "Boxville",
    [943752001] = "Pony2",
    [-310465116] = "Minivan",
    [1132262048] = "Burrito5",
    [296357396] = "Gburrito2",
    [1951180813] = "Taco",
    [-1311240698] = "Surfer2",
    [-907477130] = "Burrito2",
    [534258863] = "sPACE dOCKER",
    [-1269889662] = "Blazer3",
    [-1207771834] = "Rebel",
    [1770332643] = "Dloader",
    [2071877360] = "Insurgent2",
    [-1532697517] = "Riata",
    [1180875963] = "Technical2",
    [1897744184] = "Dune FAV",
    [989381445] = "Sandking2",
    [1356124575] = "Technical3",
    [433954513] = "Nightshark",
    [-1924433270] = "Insurgent3",
    [-1349095620] = "Caracara2",
    [-1860900134] = "Insurgent",
    [-2096818938] = "Technical",
    [-2064372143] = "Mesa3",
    [2044532910] = "Menacer",
    [1933662059] = "Rancherxl2",
    [-48031959] = "Blazer2",
    [-440768424] = "Blazer4",
    [-349601129] = "Bifta",
    [-2128233223] = "Blazer",
    [-1189015600] = "Sandking",
    [-1661854193] = "Dune",
    [1824333165] = "Besra",
    [1058115860] = "Jet",
    [621481054] = "Luxor",
    [-1214293858] = "Luxor2",
    [1341619767] = "Vestra",
    [-975345305] = "Rogue",
    [-2122757008] = "Stunt",
    [-1746576111] = "Mammatus",
    [1349725314] = "Sentinel",
    [330661258] = "Cogcabrio",
    [-1193103848] = "Zion2",
    [1581459400] = "Windsor",
    [-89291282] = "Felon2",
    [-624529134] = "Jackal",
    [-511601230] = "Oracle2",
    [-1930048799] = "Windsor2",
    [-5153954] = "Exemplar",
    [-391594584] = "Felon",
    [-1122289213] = "Zion",
    [-591610296] = "F620",
    [873639469] = "Sentinel2",
    [1348744438] = "Oracle",
    [-1776615689] = "Rumpo2",
    [893081117] = "Burrito4",
    [1069929536] = "Bobcatxl",
    [-119658072] = "Pony",
    [121658888] = "Boxville3",
    [1488164764] = "Paradise",
    [1876516712] = "Camper",
    [-1346687836] = "Burrito",
    [-1745203402] = "Gburrito",
    [699456151] = "Surfer",
    [1475773103] = "Rumpo3 or boxvile3",
    [1162065741] = "Rumpo",
    [-233098306] = "Boxville2",
    [444171386] = "Boxville4",
    [-120287622] = "Journey",
    [65402552] = "Youga",
    [2072156101] = "Bison2",
    [782665360] = "Rhino",
    [-1435527158] = "Khanjali",
    [-212993243] = "Barrage",
    [1074326203] = "Barracks2",
    [630371791] = "Barracks3",
    [-1881846085] = "Trailersmall2",
    [-692292317] = "Chernobog",
    [562680400] = "Apc",
    [321739290] = "Crusader",
    [-823509173] = "Barracks",
    [-32236122] = "Halftrack",
    [-1214505995] = "Shamal",
    [-1295027632] = "Nimbus",
    [-1006919392] = "Cutter",
    [444583674] = "Handler",
    [1886712733] = "Bulldozer",
    [-2130482718] = "Dump",
    [-1705304628] = "Rubble",
    [-784816453] = "Mixer",
    [475220373] = "Mixer2",
    [-2107990196] = "Guardian",
    [1353720154] = "Flatbed",
    [1269098716] = "Landstalker",
    [-808457413] = "Patriot",
    [1337041428] = "Serrano",
    [1221512915] = "Seminole",
    [-1543762099] = "Gresley",
    [142944341] = "Baller2",
    [1203490606] = "Xls",
    [-1829436850] = "Novak",
    [914654722] = "Mesa",
    [-808831384] = "Baller",
    [-789894171] = "Cavalcade2",
    [-394074634] = "Dubsta2",
    [666166960] = "Baller6",
    [-420911112] = "Patriot2",
    [850565707] = "Bjxl",
    [3862958888] = "Xls2",
    [634118882] = "Baller4",
    [1878062887] = "Baller3",
    [486987393] = "Huntley",
    [-1137532101] = "Fq2",
    [470404958] = "Baller5",
    [-1775728740] = "Granger",
    [683047626] = "Contender",
    [-748008636] = "Mesa2",
    [2006918058] = "Cavalcade",
    [884422927] = "Habanero",
    [-1168952148] = "Toros",
    [1177543287] = "Dubsta",
    [2136773105] = "Rocoto",
    [-1651067813] = "Radi",
    [1489874736] = "Thruster",
    [-295689028] = "Sultanrs",
    [-1403128555] = "Zentorno",
    [2123327359] = "Prototipo",
    [-1242608589] = "Vigilante",
    [1031562256] = "Tezeract",
    [819197656] = "Sheava",
    [989294410] = "Voltic2",
    [-682108547] = "Zorrusso",
    [917809321] = "Xa21",
    [338562499] = "Vacca",
    [1392481335] = "Cyclone",
    [-324618589] = "S80",
    [1093792632] = "Nero2",
    [-638562243] = "Scramjet",
    [1352136073] = "Sc1",
    [1987142870] = "Osiris",
    [-1696146015] = "Bullet",
    [-313185164] = "Autarch",
    [-998177792] = "Visione",
    [1034187331] = "Nero",
    [-1622444098] = "Voltic",
    [1426219628] = "Fmj",
    [1663218586] = "T20",
    [1234311532] = "Gp1",
    [-664141241] = "Krieger",
    [1323778901] = "Emerus",
    [633712403] = "Banshee2",
    [1939284556] = "Vagner",
    [-1291952903] = "Entityxf",
    [2067820283] = "Tyrus",
    [272929391] = "Tempesta",
    [234062309] = "Reaper",
    [-482719877] = "Italigtb2",
    [-1216765807] = "Adder",
    [-1232836011] = "Le7b",
    [408192225] = "Turismor",
    [1044193113] = "Thrax",
    [-947761570] = "Tiptruck2",
    [48339065] = "Tiptruck",
    [841808271] = "Rhapsody",
    [-1177863319] = "Issi2",
    [1682114128] = "Dilettante2",
    [-1130810103] = "Dilettante",
    [1723137093] = "Stratum",
    [906642318] = "Cog55",
    [-14495224] = "Regina",
    [-1008861746] = "Tailgater",
    [886934177] = "Intruder",
    [-2040426790] = "Primo2",
    [-1883869285] = "Premier",
    [-1807623979] = "Asea2",
    [1777363799] = "Washington",
    [-1477580979] = "Stanier",
    [321186144] = "Stafford",
    [-1894894188] = "Surge",
    [-1903012613] = "Asterope",
    [1909141499] = "Fugitive",
    [-1883002148] = "Emperor2",
    [-1809822327] = "Asea",
    [1123216662] = "Superd",
    [-114627507] = "Limo2",
    [704435172] = "Cog552",
    [-685276541] = "Emperor",
    [-1255452397] = "Schafter2",
    [-604842630] = "Cognoscenti2",
    [-1289722222] = "Ingot",
    [-2030171296] = "Cognoscenti",
    [1373123368] = "Warrener",
    [-1150599089] = "Primo",
    [75131841] = "Glendale",
    [-1961627517] = "Stretch",
    [627094268] = "Romero",
    [-1241712818] = "Emperor3",
    [-1829802492] = "Pfister811",
    [-2048333973] = "Italigtb",
    [-1758137366] = "Penetrator",
    [-1311154784] = "Cheetah",
    [-1361687965] = "Chino2",
    [1896491931] = "Moonbeam2",
    [-1790546981] = "Faction2",
    [972671128] = "Tampa",
    [2006667053] = "Voodoo",
    [784565758] = "Coquette3",
    [-589178377] = "Ratloader2",
    [723973206] = "Dukes",
    [-682211828] = "Buccaneer",
    [349605904] = "Chino",
    [525509695] = "Moonbeam",
    [-1943285540] = "Nightshade",
    [729783779] = "Slamvan",
    [-1210451983] = "Tampa3",
    [16646064] = "Virgo3",
    [833469436] = "Slamvan2",
    [-227741703] = "Ruiner",
    [523724515] = "Voodoo2",
    [-1800170043] = "Gauntlet",
    [80636076] = "Dominator",
    [1934384720] = "Gauntlet4",
    [-1013450936] = "Buccaneer2",
    [-667151410] = "Ratloader",
    [37348240] = "Hotknife",
    [15219735] = "Hermes",
    [1119641113] = "Slamvan3",
    [722226637] = "Gauntlet3",
    [941494461] = "Ruiner2",
    [-498054846] = "Virgo",
    [-2039755226] = "Faction3",
    [642617954] = "Freightgrain",
    [1030400667] = "Freight",
    [184361638] = "Freightcar",
    [920453016] = "Freightcont1",
    [240201337] = "Freightcont2",
    [586013744] = "Tankercar",
    [1549126457] = "Brioso",
    [-431692672] = "Panto",
    [-344943009] = "Blista",
    [-1450650718] = "Prairie",
    [1491375716] = "Forklift",
    [-442313018] = "Towtruck2",
    [2132890591] = "Utillitruck3",
    [734217681] = "Sadler2",
    [1560980623] = "Airtug",
    [1641462412] = "Tractor",
    [-884690486] = "Docktug",
    [-537896628] = "Caddy2",
    [1147287684] = "Caddy",
    [516990260] = "Utillitruck",
    [-2076478498] = "Tractor2",
    [887537515] = "Utillitruck2",
    [3525819835] = "Caddy3",
    [-845979911] = "Ripley",
    [-599568815] = "Sadler",
    [-1323100960] = "Towtruck",
    [1783355638] = "Mower",
    [1445631933] = "Tractor3",
    [-1700801569] = "Scrap",
    [1871995513] = "Yosemite",
    [-326143852] = "Dukes2",
    [-49115651] = "Vamos",
    [-915704871] = "Dominator2",
    [-1804415708] = "Peyote2",
    [-825837129] = "Vigero",
    [223258115] = "Sabregt2",
    [777714999] = "Ruiner3",
    [-899509638] = "Virgo2",
    [1456744817] = "Tulip",
    [-2119578145] = "Faction",
    [-2096690334] = "Impaler",
    [-986944621] = "Dominator3",
    [-1685021548] = "Sabregt",
    [349315417] = "Gauntlet2",
    [-401643538] = "Stalion2",
    [-2095439403] = "Phoenix",
    [1923400478] = "Stalion",
    [-1205801634] = "Blade",
    [2068293287] = "Lurcher",
    [1507916787] = "Picador",
    [-893984159] = "Obey 10F",
    [-1029730482] = "Cavlacade XL",
    [-1372798934] = "Karin Vivanite",
    [-1233767450] = "Gauntlet Interceptor",
    [-1674384553] = "Stanier LE Cruiser",
    [-129283887] = "Phantom",
    [167522317] = "Terminus",
    [-671564942] = "Tow Truck",
    [-122993285] = "Turismo Omaggio",
    [372621319] = "Vigero ZX Convertible",
    [-38879449] = "Aleutian",
    [-741120335] = "Asterope GZ",
    [-863358884] = "Baller ST-D",
    [-441209695] = "Dominator GT",
    [-768044142] = "Dorado",
    [821121576] = "Drift Euros",
    [-1479935577] = "Drift FR36",
    [-181562642] = "Drift Futo",
    [-1763273939] = "Drift Jester RR",
    [-1624083468] = "Drift Remus",
    [-1696319096] = "Drift Tampa",
    [-1681653521] = "Drift Yosemite",
    [1923534526] = "Drift ZR350",
    [-465825307] = "FR36",
    [-478639183] = "Impaler SZ",
    [-178442374] = "Impaler LX",
    [-902029319] = "Tow Truck"
}
--#endregion

--#region System Functions

--#region DebugLogging Functions

local debugLogFileName = "Reagans_ECU_Debug_Log.json"
local secondaryDebugLogFileName = "Reagans_ECU_Debug_Log_2.json"

local DebugLog = { pageNumber = 1 }
local Debug = {}

function Debug:log(...)
    local currentLogCount = #DebugLog - 1             -- subtract one for the page number variable
    local logNumber = tostring((currentLogCount + 1)) -- add it back for new log insertion
    local args = { ... }
    local printable = "[(LOG: " .. logNumber .. "): "
    for i, v in ipairs(args) do
        printable = printable .. tostring(v)
        if i < #args then
            printable = printable .. " ]"
        end
    end
    local enclosedLog = { printable }
    table.insert(DebugLog, enclosedLog)
end

function Debug:loadDebugLogs()
    local successLoadingSecondaryDebugFile, secondaryDebugFileContents = pcall(function()
        return json.loadfile(
            secondaryDebugLogFileName)
    end)
    local successLoadingDebugFile, debugFileContents = pcall(function() return json.loadfile(debugLogFileName) end)

    if successLoadingDebugFile then
        local debugOneFull = #debugFileContents > 2000
        local debugTwoFull = false
        if successLoadingSecondaryDebugFile then
            debugTwoFull = #secondaryDebugFileContents > 2000
        end
        if #debugFileContents > 2000 and not successLoadingSecondaryDebugFile then
            print("Debug File Full! Creating a new file labeled: " .. secondaryDebugLogFileName)
            DebugLog = { pageNumber = 2 }
            json.savefile(secondaryDebugLogFileName, DebugLog)
        elseif debugOneFull and successLoadingSecondaryDebugFile and not debugTwoFull then
            print("Found Secondary Debug File! Loading it now")
            DebugLog = secondaryDebugFileContents
        elseif debugOneFull and successLoadingSecondaryDebugFile and debugTwoFull then
            print("Both Files Are Full!!, removing the oldest entries now.")
            local oneIsOlder = debugFileContents.pageNumber < secondaryDebugFileContents.pageNumber
            if oneIsOlder then
                local newPageNumber = debugFileContents.pageNumber + 2
                DebugLog = { pageNumber = newPageNumber }
                json.savefile(debugLogFileName, DebugLog)
            else
                local newPageNumber = secondaryDebugFileContents.pageNumber + 2
                DebugLog = { pageNumber = newPageNumber }
                json.savefile(secondaryDebugLogFileName, DebugLog)
            end
        end
    else
        print("No Debug Log found! Creating a new one now.")
        local success, results = pcall(function() json.savefile(debugLogFileName, DebugLog) end)
        if success then
            print("Debug Log Initialized and saved.")
        else
            print("Error initializing debug log file: " .. tostring(results))
        end
    end
end

function Debug:saveDebugLogs()
    local successLoadingOne, contentsOfOne = pcall(function() return json.loadfile(debugLogFileName) end)
    local successLoadingTwo, contentsOfTwo = pcall(function() return json.loadfile(secondaryDebugLogFileName) end)
    local fileOnePageNumber = 1
    local fileTwoPageNumber = 2
    if successLoadingOne then
        fileOnePageNumber = contentsOfOne.pageNumber
    end
    if successLoadingTwo then
        fileTwoPageNumber = contentsOfTwo.pageNumber
    end
    if fileOnePageNumber > fileTwoPageNumber then
        -- next page is an odd number in file one
        local newPageNumber = fileOnePageNumber + 2
        DebugLog = { pageNumber = newPageNumber }
        json.savefile(debugLogFileName, DebugLog)
    else
        -- next page is an even number in file two
        local newPageNumber = fileTwoPageNumber + 2
        DebugLog = { pageNumber = newPageNumber }
        json.savefile(secondaryDebugLogFileName, DebugLog)
    end
end

--#endregion

-- Prints notifications
local function notify(...)
    if settings.userPrints then
        local args = { ... }
        local printable = "[NOTIFY] "
        for i, v in ipairs(args) do
            printable = printable .. tostring(v)
            if i < #args then
                printable = printable .. " "
            end
        end
        print(printable)
    end
end

-- Prints debug messages
local function debugPrint(...)
    if settings.debugLogging then
        Debug:log(...)
    end
    if settings.debugMode then
        local args = { ... }
        local printable = "[DEBUG] "
        for i, v in ipairs(args) do
            printable = printable .. tostring(v)
            if i < #args then
                printable = printable .. " "
            end
        end
        print(printable)
    end
end

-- rip you a new one
local function rip()
    print("sup")
end

--#endregion

--#region Reagan's ECU Functions
local reagansECU = {}

-- Function to find or add a vehicle based on model hash
function reagansECU:findOrAddVehicle(modelHash)
    if not modelHash then
        debugPrint("Error: Model hash is nil.")
        return nil
    end

    -- Search for the vehicle in the array
    for _, vehicle in ipairs(userOwnedVehicles) do
        if vehicle.modelHash == modelHash then
            return vehicle
        end
    end

    local licensePlate = "UNKNOWN"

    if localplayer and localplayer:is_in_vehicle() then
        local veh = localplayer:get_current_vehicle()
        local hash = veh:get_model_hash()
        if modelHash == hash then
            licensePlate = veh:get_number_plate_text()
        end
    end

    -- Initialize new vehicle data with default values
    local vehicle = {
        name = vehicleHashes[modelHash] or "Unknown Vehicle",
        modelHash = modelHash,
        odometer = 0,
        highestSpeed = 0,
        licensePlate = licensePlate,
        bestZeroToSixty = 0,
        lastTimeUsed = reagansECU:getVehicleTime(),
        customECU = {},
        trips = {
            a = 0,
            b = 0
        }
    }

    table.insert(userOwnedVehicles, vehicle) -- Save the new vehicle in the array
    debugPrint("Initialized and saved new vehicle: " .. vehicle.name)

    local success, err = pcall(function() saveUserVehiclesData() end
    )
    if not success then
        debugPrint("Error saving vehicle data: " .. tostring(err))
    end

    return vehicle
end

function reagansECU:getSpeed(vehiclePointer)
    if vehiclePointer == nil then
        if localplayer and localplayer:is_in_vehicle() then
            vehiclePointer = localplayer:get_current_vehicle()
        else
            return nil, nil
        end
    end
    local velocity = vehiclePointer:get_velocity()
    local speedMS = math.sqrt(velocity.x ^ 2 + velocity.y ^ 2 + velocity.z ^ 2)
    local MPH = math.floor(speedMS * speedmode.mph)
    local KPH = math.floor(speedMS * speedmode.kph)
    return MPH, KPH
end

-- Function to get the current in-game time spent in vehicle
function reagansECU:getVehicleTime()
    local success, time = pcall(function()
        return stats.get_int("MP" .. stats.get_int("MPPLY_LAST_MP_CHAR") .. "_TIME_IN_CAR")
    end
    )
    if not success then
        debugPrint("Error retrieving vehicle time.")
        return 0
    end
    return time
end

-- Function to update odometer for the current vehicle and track 0-60 time
function reagansECU:updateOdometer()
    if not tempMemory.odometer.started then
        tempMemory.odometer.running = false
        debugPrint("Odometer is not started.")
        return
    end

    if localplayer and localplayer:is_in_vehicle() then
        local vehiclePointer = localplayer:get_current_vehicle()
        if vehiclePointer then
            local modelHash = vehiclePointer:get_model_hash()
            local vehicleTable = reagansECU:findOrAddVehicle(modelHash)

            local posOne = vehiclePointer:get_position()
            sleep(0.1) -- Reduced sleep time for more frequent updates
            local posTwo = vehiclePointer:get_position()
            local distance = utilities:calculateDistance(posOne, posTwo)
            local MPH, KPH = reagansECU:getSpeed(vehiclePointer)

            if vehicleTable then
                -- Track highest speed
                if MPH ~= nil and vehicleTable.highestSpeed < MPH then
                    vehicleTable.highestSpeed = MPH
                    notify("New Speed Record!", MPH, "MPH")
                end

                -- Update odometer and trips
                local mileageToAdd = distance / 1609.34 -- Convert meters to miles
                vehicleTable.trips.a = (vehicleTable.trips.a or 0) + (mileageToAdd)
                vehicleTable.trips.b = (vehicleTable.trips.b or 0) + (mileageToAdd)
                vehicleTable.odometer = (vehicleTable.odometer or 0) + (mileageToAdd)

                -- 0-60 MPH Tracking
                if distance < 1 and MPH == 0 and not tempMemory.acceleration.tracking then
                    -- Start tracking when the vehicle begins from a stop
                    tempMemory.acceleration.tracking = true
                    tempMemory.acceleration.startTime = utilities:getLastEightDigits(reagansECU:getVehicleTime())
                    tempMemory.acceleration.reached60 = false
                    tempMemory.acceleration.startPoint = posOne
                elseif MPH > 0 and tempMemory.acceleration.tracking and not tempMemory.acceleration.reached60 then
                    tempMemory.acceleration.lastSpeed = MPH
                    if MPH >= 60 then
                        local finishTime = utilities:getLastEightDigits(reagansECU:getVehicleTime())
                        local elapsedTime = (finishTime - tempMemory.acceleration.startTime) / 1000
                        tempMemory.acceleration.reached60 = true
                        tempMemory.acceleration.finishPoint = vehiclePointer:get_position()
                        notify("0-60 MPH Time:", (elapsedTime), "seconds", "Current Fastest:",
                            vehicleTable.bestZeroToSixty)
                        if vehicleTable.bestZeroToSixty > elapsedTime and elapsedTime > 0 or vehicleTable.bestZeroToSixty == 0 then
                            notify("You Set A New Record! Fastest 0-60 in this vehicle:\nNew Time:", elapsedTime,
                                "\nPrevious Fastest:", vehicleTable.bestZeroToSixty, "\nSaving Now!")
                            vehicleTable.bestZeroToSixty = elapsedTime
                            for _, vehicle in ipairs(userOwnedVehicles) do
                                if vehicle.modelHash == modelHash then
                                    userOwnedVehicles.vehicle = vehicleTable
                                end
                            end
                            local success, err = pcall(function() saveUserVehiclesData() end)
                            if not success then
                                debugPrint("Error saving vehicle data:", err, "Trying Again Soon.")
                                updatesSkipped = saveTimer / 2
                            else
                                debugPrint("Vehicle data updated and saved.")
                                updatesSkipped = 0
                            end
                        end
                        tempMemory.acceleration.tracking = false
                    end
                elseif MPH == 0 and tempMemory.acceleration.tracking and not tempMemory.acceleration.reached60 then
                    tempMemory.acceleration.reached60 = true
                    tempMemory.acceleration.tracking = false
                end

                if updatesSkipped >= saveTimer then
                    for _, vehicle in ipairs(userOwnedVehicles) do
                        if vehicle.modelHash == modelHash then
                            userOwnedVehicles.vehicle = vehicleTable
                        end
                    end
                    local success, err = pcall(function() saveUserVehiclesData() end)
                    if not success then
                        debugPrint("Error saving vehicle data:", err, "Trying Again Soon.")
                        updatesSkipped = saveTimer / 2
                    else
                        Debug:saveDebugLogs()
                        debugPrint("Vehicle data updated and saved.")
                        updatesSkipped = 0
                    end
                else
                    updatesSkipped = updatesSkipped + 1
                end
            else
                debugPrint("Error in reagansECU:updateOdometer(): VehicleTable is nil.")
            end
        else
            debugPrint("Error: Vehicle pointer is nil.")
        end
    else
        sleep(settings.odometer.delay)
    end
    tempMemory.odometer.running = false
end

-- Function to start odometer and 0-60 tracking manually
function reagansECU:startOdometer()
    if not tempMemory.odometer.started then
        tempMemory.odometer.started = true
        tempMemory.odometer.running = false
        debugPrint("Odometer started.")
        while tempMemory.odometer.started do
            if not tempMemory.odometer.running and not tempMemory.savingData then
                tempMemory.odometer.running = true
                reagansECU:updateOdometer()
            end
        end
    else
        debugPrint("Odometer is already running.")
    end
end

-- Function to stop odometer tracking
function reagansECU:stopOdometer()
    if tempMemory.odometer.started then
        tempMemory.odometer.running = false
        tempMemory.odometer.started = false
        tempMemory.acceleration.tracking = false -- Stop 0-60 tracking
        notify("Odometer and acceleration tracking stopped.")
    else
        notify("Odometer is not running.")
    end
end

-- Function to apply the custom tuning to the current vehicle based on the saved customECU values
function reagansECU:tuneCurrentVehicle()
    if localplayer and localplayer:is_in_vehicle() then
        local currentVehicle = localplayer:get_current_vehicle()
        local CurrentVehiclesModelHash = currentVehicle:get_model_hash()

        for _, vehicle in ipairs(userOwnedVehicles) do
            if vehicle.modelHash == CurrentVehiclesModelHash then
                -- Apply each custom ECU tuning variable to the current vehicle
                for key, value in pairs(vehicle.customECU) do
                    if type(value) == "table" and value.x and value.y and value.z then
                        -- For Vector3 values (position, rotation, etc.)
                        currentVehicle["set_" .. key](currentVehicle, value.x, value.y, value.z)
                    elseif type(value) == "table" and #value == 3 then
                        -- For RGB values (custom primary and secondary colors)
                        currentVehicle["set_" .. key](currentVehicle, value[1], value[2], value[3])
                    elseif currentVehicle["set_" .. key] then
                        -- For float, int, and bool values
                        currentVehicle["set_" .. key](currentVehicle, value)
                    else
                        debugPrint("Unsupported type or key: " .. tostring(key))
                    end
                end
                debugPrint("Vehicle tuning applied for: " .. vehicle.name)
                break
            end
        end
    else
        debugPrint("Player is not in a vehicle or vehicle could not be found.")
    end
end

-- Function to start the tuner
function reagansECU:startTuner()
    if not tempMemory.tuner.started then
        notify("Tuner is starting!")
        tempMemory.tuner.started = true
        tempMemory.tuner.running = false
        repeat
            if not tempMemory.tuner.running then
                tempMemory.tuner.running = true
                reagansECU:tuneCurrentVehicle()
                tempMemory.tuner.running = false
                sleep(1)
            end
        until not tempMemory.tuner.started
        notify("Tuner is already started!")
    end
end

-- Function to stop the tuner
function reagansECU:stopTuner()
    if tempMemory.tuner.started then
        tempMemory.tuner.started = false
        tempMemory.tuner.running = false
        notify("Tuner stopped.")
    else
        notify("Tuner is not running.")
    end
end

--#endregion

--#region Utilities Functions

-- Prompt Yes or No with hotkeys
function utilities:promptYesOrNo()
    if not utilities.prompting then
        print("\n\nPlease Confirm With Y\nOR\nCancel With N\n\nPlease Enter Your Choice Now...\n")
        utilities.prompting = true
        utilities.promptComplete = false
        utilities.promptResult = false
        menu.register_hotkey(utilities.keycodes.y,
            function()
                if utilities.prompting then
                    utilities.promptResult = true
                    utilities.promptComplete = true
                end
            end
        )
        menu.register_hotkey(utilities.keycodes.n,
            function()
                if utilities.prompting then
                    utilities.promptResult = false
                    utilities.promptComplete = true
                end
            end
        )
        repeat
            sleep(1)
        until utilities.promptComplete
        local result = utilities.promptResult
        utilities.promptResult = false
        utilities.prompting = false
        notify("Prompting Complete! You Have Chosen: " .. tostring(result))
        return result
    end
end

function utilities:getLastEightDigits(number)
    local mod = 10 ^ 8
    return number % mod
end

-- returns the saved table but they should match.
function utilities:mergeTables(defaults, saved)
    if defaults.version and saved.version and defaults.version > saved.version then
        saved.version = defaults.version
    end
    for variableName, variable in pairs(defaults) do
        if type(variable) == "table" then
            saved[variableName] = utilities:mergeTables(variable, saved[variableName] or {})
        elseif saved[variableName] == nil then
            saved[variableName] = variable
        end
    end
    return saved
end

-- Save vehicle data to JSON file
function saveUserVehiclesData()
    tempMemory.savingData = true
    debugPrint("Saving User Vehicles Data")

    -- Convert the array of userOwnedVehicles to a keyed table format
    local keyedVehicles = {}
    for index, vehicle in ipairs(userOwnedVehicles) do
        -- Ensure all necessary fields are present to prevent nil values
        keyedVehicles[tostring(index)] = {
            name = vehicle.name or "Unknown Vehicle",
            modelHash = vehicle.modelHash or 0,
            odometer = vehicle.odometer or 0,
            highestSpeed = vehicle.highestSpeed or 0,
            licensePlate = vehicle.licensePlate or "UNKNOWN",
            bestZeroToSixty = vehicle.bestZeroToSixty or 0,
            lastTimeUsed = vehicle.lastTimeUsed or 0,
            customECU = vehicle.customECU or {},
            trips = vehicle.trips or { a = 0, b = 0 }
        }
    end

    -- Attempt to save the data and handle any errors
    local success, err = pcall(function() json.savefile(vehicleDataFilename, keyedVehicles) end)
    if not success then
        debugPrint("Error saving vehicle data: " .. tostring(err))
    else
        debugPrint("User Vehicles Data saved successfully.")
    end

    tempMemory.savingData = false
end

-- Load vehicle data from JSON file
function loadUserVehiclesData()
    local success, data = pcall(function() return json.loadfile(vehicleDataFilename) end)

    if success and type(data) == "table" then
        -- Convert keyed table back to array format
        userOwnedVehicles = {}
        for key, vehicle in pairs(data) do
            -- Ensure vehicle has required structure, fixing or setting defaults if needed
            table.insert(userOwnedVehicles, {
                name = vehicle.name or "Unknown Vehicle",
                modelHash = vehicle.modelHash or 0,
                odometer = vehicle.odometer or 0,
                highestSpeed = vehicle.highestSpeed or 0,
                licensePlate = vehicle.licensePlate or "UNKNOWN",
                bestZeroToSixty = vehicle.bestZeroToSixty or 0,
                lastTimeUsed = vehicle.lastTimeUsed or 0,
                customECU = vehicle.customECU or {},
                trips = vehicle.trips or { a = 0, b = 0 }
            })
        end
        debugPrint("Vehicle data loaded successfully.")
    else
        debugPrint("Failed to load vehicle data: No File Found or Corrupted Data. Saving A Blank File.")
        -- Save a blank file to ensure that a valid JSON structure exists for future operations
        saveUserVehiclesData()
    end
end

-- Save settings table to JSON file
function utilities:saveUserSettings()
    debugPrint("Saving user settings")
    tempMemory.savingData = true
    local success, err = pcall(function() json.savefile(settingsFilename, settings) end
    ) -- Save the current settings
    if not success then
        debugPrint("Error saving settings: " .. tostring(err))
    else
        debugPrint("Settings saved.")
    end
    tempMemory.savingData = false
end

-- Load settings table from JSON file
function utilities:loadUserSettings()
    debugPrint("Loading user settings from file...")
    local success, loadedSettings = pcall(function() return json.loadfile(settingsFilename) end
    )
    if success and type(loadedSettings) == "table" then
        if loadedSettings.version < settings.version then
            debugPrint("Merged new sttings into saved settings.")
            settings = utilities:mergeTables(settings, loadedSettings)
            utilities:saveUserSettings()
        elseif loadedSettings.version == settings.version then
            settings = loadedSettings
            debugPrint("Loaded settings with matching version.")
        else
            debugPrint("SCRIPT IS OLDER THAN THE LAST TIME USED")
        end
    else
        debugPrint("Failed to load settings, initializing defaults.")
        utilities:saveUserSettings()
    end
end

-- Calculate the Euclidean distance between two positions
function utilities:calculateDistance(posOne, posTwo)
    local dx = posTwo.x - posOne.x
    local dy = posTwo.y - posOne.y
    local dz = posTwo.z - posOne.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function blankSpace(amount)
    local numberSpaces = amount
    return string.rep(' ', numberSpaces)
end

local function showWelcomeMessage()
    settings.timesLoaded = settings.timesLoaded + 1
    if settings.timesLoaded < 3 then
        local b = blankSpace
        error(
            b(28) .. "Welcome To Reagans ECU\n" ..
            "\n" ..
            "\n" ..
            b(6) .. "Considering This Is Your First Time Using My Script\n" ..
            "I Strongly Suggest You Use It With The Lua Debug Console\n" ..
            "\n" ..
            "   You Can Find The Option To Open It In Modest Menu's\n" ..
            b(36) .. "Settings Section.\n" ..
            "\n" ..
            "If You Ever Have Questions Or Suggestions Please Contact Me\n" ..
            b(30) .. "Discord:" .. b(11) .. "keef_it_up", 0
        )
    elseif settings.timesLoaded == 100 then
        error(
            "You Have Used My Script A Total of 100 times!\nPlease message me on discord to give me your thoughts!\nI would love to hear from you.")
    end
end

--#endregion

--#region Callbacks

-- Initialize settings on script load
menu.register_callback("OnScriptsLoaded",
    function()
        Debug:loadDebugLogs()
        utilities:loadUserSettings()
        loadUserVehiclesData()
        populateUserVehicleSubmenu()
        if settings.odometer.autorun == true then
            reagansECU:startOdometer()
        end
        if settings.tuner.autoStart == true then
            reagansECU:startTuner()
        end
        showWelcomeMessage()
    end
)

--#endregion

--#region Menu Creation
-- Reagan's ECU
local mainmenu = menu.add_submenu("Reagan's ECU")

-- Tunes Submenu
local tunesMenu = mainmenu:add_submenu("Tunes")

-- Current Vehicle Submenu
local currentVehicleMenu = tunesMenu:add_submenu("Current Vehicle")

-- Save Tune Action
currentVehicleMenu:add_action("Save Tune",
    function()
        local vehicle = localplayer:get_current_vehicle()
        if vehicle then
            local found_vehicle = reagansECU:findOrAddVehicle(vehicle:get_model_hash())
            if found_vehicle then
                local success, err = pcall(function() saveUserVehiclesData() end
                )
                if success then
                    notify("Tune saved for " .. found_vehicle.name)
                else
                    debugPrint("Error saving tune: " .. tostring(err))
                end
            else
                notify("No vehicle data found to save.")
            end
        else
            notify("No current vehicle detected.")
        end
    end
)

-- Tune Current Vehicle
currentVehicleMenu:add_action("Tune Current Vehicle",
    function()
        reagansECU:tuneCurrentVehicle()
    end
)

-- Revert Tune Submenu
local revertTuneMenu = currentVehicleMenu:add_submenu("Revert Tune")
revertTuneMenu:add_action("Warning Warning Warning",
    function() rip() end
)
revertTuneMenu:add_action("Reversion Is Permanent!",
    function() rip() end
)
revertTuneMenu:add_action("This WILL Reset The ECU",
    function() rip() end
)
revertTuneMenu:add_action("",
    function() rip() end
) -- Empty line for spacing
revertTuneMenu:add_action("DELETE",
    function()
        local vehicle = localplayer:get_current_vehicle()
        if vehicle then
            local found_vehicle = reagansECU:findOrAddVehicle(vehicle:get_model_hash())
            if found_vehicle then
                found_vehicle.customECU = {}
                local success, err = pcall(function() saveUserVehiclesData() end
                )
                if success then
                    notify("ECU reset and tune reverted for " .. found_vehicle.name)
                else
                    debugPrint("Error resetting ECU: " .. tostring(err))
                end
            else
                notify("No vehicle data found to reset.")
            end
        else
            notify("No current vehicle detected.")
        end
    end
)

-- Handling Submenu
local handlingMenu = currentVehicleMenu:add_submenu("Handling")

-- Performance Submenu
local performanceMenu = currentVehicleMenu:add_submenu("Performance")

-- Aesthetics Submenu
local aestheticsMenu = currentVehicleMenu:add_submenu("Aesthetics")

-- Reliability Submenu
local reliabilityMenu = currentVehicleMenu:add_submenu("Reliability")

-- Function to add menu items
local function add_menu_items(menu, variables)
    for _, var in ipairs(variables) do
        local get_func = function()
            local vehicle = localplayer:get_current_vehicle()
            if vehicle then
                local found_vehicle = reagansECU:findOrAddVehicle(vehicle:get_model_hash())
                return found_vehicle and found_vehicle.customECU[var.key] or var.default
            end
            return var.default
        end

        local set_func = function(value)
            local vehicle = localplayer:get_current_vehicle()
            if vehicle then
                local found_vehicle = reagansECU:findOrAddVehicle(vehicle:get_model_hash())
                if found_vehicle then
                    found_vehicle.customECU[var.key] = value
                    print(var.name .. " set to " .. tostring(value))
                    local success, err = pcall(function() saveUserVehiclesData() end
                    )
                    if not success then
                        debugPrint("Error saving custom ECU value: " .. tostring(err))
                    end
                end
            end
        end

        if var.type == "float" then
            menu:add_float_range("Set " .. var.name, var.step, var.min, var.max, get_func, set_func)
        elseif var.type == "int" then
            menu:add_int_range("Set " .. var.name, var.step, var.min, var.max, get_func, set_func)
        elseif var.type == "bool" then
            menu:add_toggle("Set " .. var.name, get_func, set_func)
        elseif var.type == "vector3" then
            local vector3Menu = menu:add_submenu("Set " .. var.name)
            vector3Menu:add_float_range("X", 1, -1000.0, 1000.0,
                function() return get_func().x end,
                function(value)
                    local vec = get_func()
                    vec.x = value
                    set_func(vec)
                end
            )
            vector3Menu:add_float_range("Y", 1, -1000.0, 1000.0,
                function() return get_func().y end,
                function(value)
                    local vec = get_func()
                    vec.y = value
                    set_func(vec)
                end
            )
            vector3Menu:add_float_range("Z", 1, -1000.0, 1000.0,
                function() return get_func().z end,
                function(value)
                    local vec = get_func()
                    vec.z = value
                    set_func(vec)
                end
            )
        elseif var.type == "rgb" then
            local rgbMenu = menu:add_submenu("Set " .. var.name)
            rgbMenu:add_int_range("R", 1, 0, 255,
                function() return get_func()[1] end,
                function(value)
                    local color = get_func()
                    color[1] = value
                    set_func(color)
                end
            )
            rgbMenu:add_int_range("G", 1, 0, 255,
                function() return get_func()[2] end,
                function(value)
                    local color = get_func()
                    color[2] = value
                    set_func(color)
                end
            )
            rgbMenu:add_int_range("B", 1, 0, 255,
                function() return get_func()[3] end,
                function(value)
                    local color = get_func()
                    color[3] = value
                    set_func(color)
                end
            )
        elseif var.type == "string" then
            menu:add_action("string functions coming soon",
                function() rip() end
            )
        end
    end
end

-- Add items to submenus
add_menu_items(performanceMenu, tuning_pointers.performance)
add_menu_items(handlingMenu, tuning_pointers.handling)
add_menu_items(aestheticsMenu, tuning_pointers.aesthetics)
add_menu_items(reliabilityMenu, tuning_pointers.reliability)

-- Saved Vehicles Submenu
local savedVehiclesMenu = tunesMenu:add_submenu("Saved Vehicles")

-- Dynamically create submenus for each saved vehicle
function populateUserVehicleSubmenu()
    for _, vehicle in ipairs(userOwnedVehicles) do
        local vehicleSubMenu = savedVehiclesMenu:add_submenu(vehicle.name)

        vehicleSubMenu:add_action("Save Tune",
            function()
                local success, err = pcall(function() saveUserVehiclesData() end
                )
                if success then
                    notify("Tune saved for " .. vehicle.name)
                else
                    debugPrint("Error saving tune: " .. tostring(err))
                end
            end
        )

        local revertSavedTuneMenu = vehicleSubMenu:add_submenu("Revert Tune")
        revertSavedTuneMenu:add_action("Warning Warning Warning",
            function() rip() end
        )
        revertSavedTuneMenu:add_action("Reversion Is Permanent!",
            function() rip() end
        )
        revertSavedTuneMenu:add_action("This WILL Reset The ECU",
            function() rip() end
        )
        revertSavedTuneMenu:add_action("",
            function() rip() end
        )
        revertSavedTuneMenu:add_action("DELETE",
            function()
                vehicle.customECU = {}
                local success, err = pcall(function() saveUserVehiclesData() end
                )
                if success then
                    notify("ECU reset and tune reverted for " .. vehicle.name)
                else
                    debugPrint("Error resetting ECU: " .. tostring(err))
                end
            end
        )
        revertSavedTuneMenu:add_action("CANCEL",
            function()
                notify("Tune reversion canceled for " .. vehicle.name)
            end
        )

        -- Replicate handling, performance, aesthetics, and reliability submenus
        local handlingSubMenu = vehicleSubMenu:add_submenu("Handling")
        local performanceSubMenu = vehicleSubMenu:add_submenu("Performance")
        local aestheticsSubMenu = vehicleSubMenu:add_submenu("Aesthetics")
        local reliabilitySubMenu = vehicleSubMenu:add_submenu("Reliability")

        add_menu_items(performanceSubMenu, tuning_pointers.performance)
        add_menu_items(handlingSubMenu, tuning_pointers.handling)
        add_menu_items(aestheticsSubMenu, tuning_pointers.aesthetics)
        add_menu_items(reliabilitySubMenu, tuning_pointers.reliability)
    end
end

-- Odometer Menu
local odometerMenu = mainmenu:add_submenu("Odometer")

odometerMenu:add_action("Start Odometer",
    function()
        reagansECU:startOdometer()
    end
)

odometerMenu:add_action("Start Trip A",
    function()
        if localplayer and localplayer:is_in_vehicle() then
            local currentVehicle = localplayer:get_current_vehicle()
            local success, foundTable = pcall(function()
                return reagansECU:findOrAddVehicle(currentVehicle
                    :get_model_hash())
            end)
            if success and foundTable ~= nil and foundTable == type("table") then
                local currentTripCount = foundTable.trips.a
                for i, value in ipairs(userOwnedVehicles) do
                    if value and value.trips.a == currentTripCount then
                        value.trips.a = 0
                        saveUserVehiclesData()
                    end
                end
            else
                debugPrint("Error:", table)
            end
        end
    end
)

odometerMenu:add_action("Start Trip B",
    function()
        if localplayer and localplayer:is_in_vehicle() then
            local currentVehicle = localplayer:get_current_vehicle()
            local success, foundTable = pcall(function()
                return reagansECU:findOrAddVehicle(currentVehicle
                    :get_model_hash())
            end)
            if success and foundTable ~= nil and foundTable == type("table") then
                local currentTripCount = foundTable.trips.b
                for i, value in ipairs(userOwnedVehicles) do
                    if value and value.trips.b == currentTripCount then
                        value.trips.b = 0
                        saveUserVehiclesData()
                    end
                end
            end
        end
    end
)

odometerMenu:add_action("Current Reading",
    function()
        if localplayer and localplayer:is_in_vehicle() then
            local currentModelHash = localplayer:get_current_vehicle():get_model_hash()
            local vehicleFound, vehicleTable = reagansECU:findOrAddVehicle(currentModelHash)
            if vehicleFound and vehicleTable ~= nil and vehicleTable == type("table") then
                notify("Current odometer reading:", vehicleTable.odometer, "miles.")
            else
                notify("No current vehicle data available.")
            end
        else
            notify("You Must Be In A Vehicle To Use This Function!")
        end
    end
)

odometerMenu:add_action("Top 10 Highest Speeds",
    function()
        local userVehicles = userOwnedVehicles
        table.sort(userVehicles,
            function(a, b)
                return a.highestSpeed > b.highestSpeed
            end
        )
        local topTen = {}
        for i = 1, math.min(10, #userVehicles) do
            table.insert(topTen, userVehicles[i].name .. ": " .. userVehicles[i].highestSpeed .. " MPH")
        end
        notify("Top Ten Fastest Accelerations:\n" .. table.concat(topTen, "\n"))
    end
)

odometerMenu:add_action("Top 10 Accelerations",
    function()
        local userVehicles = userOwnedVehicles
        table.sort(userVehicles,
            function(a, b)
                return a.bestZeroToSixty > b.bestZeroToSixty
            end
        )
        local topTen = {}
        for i = 1, math.min(10, #userVehicles) do
            table.insert(topTen, userVehicles[i].name .. ": " .. userVehicles[i].bestZeroToSixty .. " seconds")
        end
        notify("Top Ten Fastest Accelerations:\n" .. table.concat(topTen, "\n"))
    end
)

odometerMenu:add_action("Top 10 Odometer Readings",
    function()
        local userVehicles = userOwnedVehicles
        table.sort(userVehicles,
            function(a, b)
                return a.odometer > b.odometer
            end
        )
        local topTen = {}
        for i = 1, math.min(10, #userVehicles) do
            table.insert(topTen, userVehicles[i].name .. ": " .. userVehicles[i].odometer .. " miles")
        end
        notify("Top 10 vehicles by odometer:\n" .. table.concat(topTen, "\n"))
    end
)

odometerMenu:add_action("Print All Vehicle Data",
    function()
        local vehicleData = {}
        for vehicleNumber, vehicle in ipairs(userOwnedVehicles) do
            table.insert(vehicleData, "Vehicle " .. vehicleNumber)
            for name, variable in pairs(vehicle) do
                if type(variable) == "table" then
                    variable = table.concat(variable, ", ")
                end
                local infoString = tostring(name .. ": " .. tostring(variable))
                table.insert(vehicleData, "  " .. infoString)
            end
            table.insert(vehicleData, "")
        end
        notify("All vehicles:\n" .. table.concat(vehicleData, "\n"))
    end
)


-- Settings Submenu
local settingsMenu = mainmenu:add_submenu("Settings")

-- Debugging Submenu

local debugMenu = settingsMenu:add_submenu("Debugging")

-- controld debug prints to the console
debugMenu:add_toggle("Debug Prints",
    function()
        return settings.debugMode
    end,
    function(bool)
        settings.debugMode = bool
        utilities:saveUserSettings()
    end
)

-- controls logging of debug prints, regardless of print settings
debugMenu:add_toggle("Debug Logging",
    function()
        return settings.debugLogging
    end,
    function(bool)
        settings.debugLogging = bool
        utilities:saveUserSettings()
    end
)

settingsMenu:add_toggle("User Notifications",
    function()
        return settings.userPrints
    end,
    function(bool)
        settings.userPrints = bool
        utilities:saveUserSettings()
    end
)

-- Tunes Submenu

local tunesSettings = settingsMenu:add_submenu("Tuner Settings")

-- controls automatically tuning a vehicle
tunesSettings:add_toggle("Auto Tune Vehicles",
    function()
        return settings.tuner.autoTune
    end,
    function(bool)
        settings.tuner.autoTune = bool
        reagansECU:startTuner()
        utilities:saveUserSettings()
    end
)

-- controls auto run on script startup
tunesSettings:add_toggle("Run On Startup",
    function()
        return settings.tuner.autoStart
    end,
    function(bool)
        settings.tuner.autoStart = bool
        utilities:saveUserSettings()
    end
)

-- Odometer Submenu
local odometerSettings = settingsMenu:add_submenu("Odometer Settings")

odometerSettings:add_float_range("Update Delay", 1, 0.01, 1,
    function()
        return settings.odometer.delay
    end,
    function(number)
        settings.odometer.delay = number
        utilities:saveUserSettings()
    end
)

odometerSettings:add_toggle("Automatic Mode",
    function()
        return settings.odometer.autorun
    end,
    function(value)
        settings.odometer.autorun = value
        utilities:saveUserSettings()
        notify("Odometer autorun set to " .. tostring(value))
    end
)

-- Memory Submenu
local memorySettings = settingsMenu:add_submenu("Memory/Saved Data")

memorySettings:add_action("Delete All Saved Vehicles",
    function()
        userOwnedVehicles = {}
        local success, err = pcall(function() saveUserVehiclesData() end
        )
        if success then
            notify("All saved vehicles deleted.")
        else
            debugPrint("Error deleting saved vehicles: " .. tostring(err))
        end
    end
)
memorySettings:add_action("Reset Saved Settings",
    function()
        settings = settingsDefaults
        utilities:saveUserSettings()
        notify("Saved settings reset to default.")
    end
)
memorySettings:add_action("Reset EVERYTHING",
    function()
        userOwnedVehicles = {}
        settings = settingsDefaults
        utilities:saveUserSettings()
        local success, err = pcall(function() saveUserVehiclesData() end
        )
        if success then
            notify("All data reset.")
        else
            debugPrint("Error resetting all data: " .. tostring(err))
        end
    end
)

-- Credits Submenu
local creditsMenu = settingsMenu:add_submenu("Credits")

creditsMenu:add_action("Click a Person's Title To",
    function() rip() end
)
creditsMenu:add_action("Display Their Credits!",
    function() rip() end
)
creditsMenu:add_action("",
    function() rip() end
)
creditsMenu:add_action("Developer",
    function()
        print(credits.developer)
    end
)
creditsMenu:add_action("QA Analyst",
    function()
        print(credits.QA)
    end
)
creditsMenu:add_action("Expert Help",
    function()
        print(credits.expert)
    end
)



--#endregion
