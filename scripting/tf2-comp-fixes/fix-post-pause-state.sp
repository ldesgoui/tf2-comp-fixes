static ConVar g_convar_pausable;
static bool   g_paused = false;
static float  g_ubercharge[MAXPLAYERS + 1];

void FixPostPauseState_Setup() {
    g_convar_pausable = FindConVar("sv_pausable");

    if (g_convar_pausable == INVALID_HANDLE) {
        SetFailState("Failed to find sv_pausable");
    }

    CreateBoolConVar("sm_fix_post_pause_state", WhenConVarChange);
}

void FixPostPauseState_OnMapStart() {
    g_paused = false;
}

static void WhenConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (cvar.BoolValue) {
        AddCommandListener(WhenPause, "pause");
    } else {
        RemoveCommandListener(WhenPause, "pause");
    }
}

static Action WhenPause(int client, const char[] command, int argc) {
    if (!g_convar_pausable.BoolValue) {
        return Plugin_Continue;
    }

    for (int client = 1; client <= MaxClients; client++) {
        if (!IsClientInGame(client)) {
            continue;
        }

        if (TF2_GetPlayerClass(client) != TFClass_Medic) {
            continue;
        }

        int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);

        if (medigun == -1) {
            // Weird
            continue;
        }

        if (g_paused) {
            SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", g_ubercharge[client]);
            LogDebug("Restoring %N's ubercharge to %.0f%", client, g_ubercharge[client] * 100);
        } else {
            g_ubercharge[client] = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
            LogDebug("Saving %N's ubercharge as %.0f%", client, g_ubercharge[client] * 100);
        }
    }

    g_paused = !g_paused;

    return Plugin_Continue;
}
