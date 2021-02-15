static TFClassType CLASS_LOOKUP[9] = {TFClass_Scout,   TFClass_Soldier, TFClass_Pyro,
                                      TFClass_DemoMan, TFClass_Heavy,   TFClass_Engineer,
                                      TFClass_Medic,   TFClass_Sniper,  TFClass_Spy};

static int         g_class_limits[9]               = {-1, ...};
static TFClassType g_current_class[MAXPLAYERS + 1] = {TFClass_Unknown, ...};
static TFClassType g_wanted_class[MAXPLAYERS + 1]  = {TFClass_Unknown, ...};

void BetterClassLimits_Setup() {
    ConVar cvar = CreateConVar(
        "sm_better_class_limits", "-1,-1,-1,-1,-1,-1,-1,-1,-1",
        "Format: whole numbers separated by commas for each class, empty/unspecified defaults to -1, which is unlimited. \
            e.g.: '2,2,1,1,1,1,1,1,2' for 6v6, '1,1,1,1,1,1,1,1,1' for Highlander",
        FCVAR_NOTIFY);

    cvar.AddChangeHook(OnConVarChange);
    CallConVarUpdateHook(cvar, OnConVarChange);
}

static void OnConVarChange(ConVar cvar, const char[] before, const char[] after) {
    int new_limits[9] = {-1, ...};

    if (!ParseClassLimits(after, new_limits)) {
        LogMessage("Invalid 'sm_better_class_limits' format");
        cvar.Flags &= ~FCVAR_NOTIFY;
        cvar.SetString("-1,-1,-1,-1,-1,-1,-1,-1,-1");
        cvar.Flags |= FCVAR_NOTIFY;
        return;
    }

    char reformatted[64];
    // clang-format off
    Format(reformatted, sizeof(reformatted), "%d,%d,%d,%d,%d,%d,%d,%d,%d",
           new_limits[0], new_limits[1], new_limits[2],
           new_limits[3], new_limits[4], new_limits[5],
           new_limits[6], new_limits[7], new_limits[8]);
    // clang-format on

    if (!StrEqual(after, reformatted)) {
        cvar.Flags &= ~FCVAR_NOTIFY;
        cvar.SetString(reformatted);
        cvar.Flags |= FCVAR_NOTIFY;
        return;
    }

    bool was_enabled = false;
    bool is_enabled  = false;
    for (int i = 0; i < 9; i++) {
        was_enabled       = was_enabled || g_class_limits[i] != -1;
        is_enabled        = is_enabled || new_limits[i] != -1;
        g_class_limits[i] = new_limits[i];
    }

    if (was_enabled == is_enabled) {
        return;
    }

    int entity = -1;
    while ((entity = FindEntityByClassname(entity, "func_respawnroom")) != -1) {
        ToggleSDKHook(entity, SDKHook_StartTouch, Respawn_StartTouch, is_enabled);
        ToggleSDKHook(entity, SDKHook_EndTouch, Respawn_EndTouch, is_enabled);
    }

    ToggleHookEvent("player_changeclass", Event_PlayerChangeClass, is_enabled);
    ToggleHookEvent("player_spawn", Event_PlayerSpawn, is_enabled);
    DHookToggleEntityListener(ListenType_Created, OnEntityCreated, is_enabled);

    if (!is_enabled) {
        return;
    }

    for (entity = 1; entity <= MaxClients; entity++) {
        g_current_class[entity] =
            IsClientInGame(entity) ? TF2_GetPlayerClass(entity) : TFClass_Unknown;

        if (g_current_class[entity] != TFClass_Unknown) {
            PrintToChatAll("%N: %d", entity, g_current_class[entity]);
        }
    }
}

static void Event_PlayerChangeClass(Event event, const char[] name, bool dont_broadcast) {
    int         player = GetClientOfUserId(event.GetInt("userid"));
    TFClassType klass  = view_as<TFClassType>(event.GetInt("class"));

    g_wanted_class = klass;

    PrintToChatAll("%N: wants %d", player, klass);
}

static void Event_PlayerSpawn(Event event, const char[] name, bool dont_broadcast) {
    int         player = GetClientOfUserId(event.GetInt("userid"));
    TFClassType klass  = view_as<TFClassType>(event.GetInt("class"));

    g_current_class[player] = klass;

    PrintToChatAll("%N: %d", player, klass);
}

static void OnEntityCreated(int entity, const char[] classname) {
    if (StrEqual(classname, "func_respawnroom")) {
        SDKHook(entity, SDKHook_StartTouch, Respawn_StartTouch);
        SDKHook(entity, SDKHook_EndTouch, Respawn_EndTouch);
    }
}

static void Respawn_StartTouch(int entity, int other) {
    PrintToChatAll("Respawn_StartTouch: %N", other);
}

static void Respawn_EndTouch(int entity, int other) {
    PrintToChatAll("Respawn_EndTouch: %N", other);
}

static bool ParseClassLimits(const char[] value, int result[9]) {
    char fields[10][16];
    int  num_fields = ExplodeString(value, ",", fields, sizeof(fields), sizeof(fields[]));
    int  i          = 0;
    bool failed     = num_fields > 9;

    while (!failed && i < num_fields) {
        int limit    = -1;
        int consumed = StringToIntEx(fields[i], limit);

        if (consumed != strlen(fields[i])) {
            i      = 0;
            failed = true;
            break;
        }

        if (consumed == 0 || limit < -1) {
            limit = -1;
        } else if (limit > MAXPLAYERS) {
            limit = MAXPLAYERS;
        }

        result[i] = limit;
        i += 1;
    }

    while (i < 9) {
        result[i] = -1;
        i += 1;
    }

    return !failed;
}
