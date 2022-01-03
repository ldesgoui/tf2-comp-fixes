static Handle g_detour_PointInRespawnRoom;

void PreventRespawning_Setup(Handle game_config) {
    g_detour_PointInRespawnRoom =
        CheckedDHookCreateFromConf(game_config, "PointInRespawnRoom");

    CreateBoolConVar("sm_prevent_respawning", WhenConVarChange);
}

static void WhenConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (!DHookToggleDetour(g_detour_PointInRespawnRoom, HOOK_PRE, Detour_Pre,
                           cvar.BoolValue)) {
        SetFailState("Failed to toggle detour on PointInRespawnRoom");
    }
}

static MRESReturn Detour_Pre(Handle return, Handle params) {
    if (DHookGetParam(params, 1) != null) {
        DHookSetReturn(return, false);
        return MRES_Supercede;
    }

    return MRES_Ignored;
}
