static ConVar g_cvar;

static StringMap g_projectiles_positions;
static int g_laser;

static Handle g_detour_CTFWeaponBaseGun_FireProjectile;

void Debug_Setup(Handle game_config) {
    g_laser = PrecacheModel("sprites/laser.vmt");
    g_projectiles_positions = new StringMap();

    g_detour_CTFWeaponBaseGun_FireProjectile =
        CheckedDHookCreateFromConf(game_config, "CTFWeaponBaseGun::FireProjectile");

    g_cvar = CreateConVar("sm_cf_debug", "0", "Print debug statements in chat", FCVAR_NOTIFY, true,
                          0.0, true, 2.0);
    CreateBoolConVar("sm_cf_show_projectiles_traces", OnConVarChange);
}

void LogDebug(const char[] format, any...) {
    if (!g_cvar.BoolValue) {
        return;
    }

    char message[256];

    VFormat(message, sizeof(message), format, 2);

    if (g_cvar.IntValue >= 1) {
        LogMessage(message);
    }

    if (g_cvar.IntValue >= 2) {
        PrintToChatAll("[TF2 Competitive Fixes] Debug: %s", message);
    }
}

static void OnConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (!DHookToggleDetour(g_detour_CTFWeaponBaseGun_FireProjectile, HOOK_POST,
                           Detour_CTFWeaponBaseGun_FireProjectile, true)) {
        SetFailState("Failed to toggle detour on CCTFWeaponBaseGun::FireProjectile");
    }
}

static MRESReturn Detour_CTFWeaponBaseGun_FireProjectile(Handle hReturn, Handle hParams) {
    if (g_cvar.IntValue < 2) {
        return MRES_Ignored;
    }

    int entity = DHookGetReturn(hReturn);

    if (entity == -1) {
        return MRES_Ignored;
    }

    float position[3];
    char entity_id[5];

    GetEntityPosition(entity, position);
    IntToString(entity, entity_id, sizeof(entity_id));

    g_projectiles_positions.SetArray(entity_id, position, 3);
    SDKHook(entity, SDKHook_SetTransmit, DrawProjectilePath);

    return MRES_Handled;
}

static void DrawProjectilePath(int entity) {
    float position[3], last_position[3];
    char entity_id[5];

    GetEntityPosition(entity, position);
    IntToString(entity, entity_id, sizeof(entity_id));

    g_projectiles_positions.GetArray(entity_id, last_position, 3);

    TE_SetupBeamPoints(last_position, position, g_laser, 0, 0, 66, 20.0, 1.0, 1.0, 1, 0.1, {255, 0, 0, 255}, 0);
    TE_SendToAll();

    g_projectiles_positions.SetArray(entity_id, position, 3);
}
