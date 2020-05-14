#if defined _TF2_COMP_FIXES_REMOVE_MEDIC_ATTACH_SPEED
#endinput
#endif
#define _TF2_COMP_FIXES_REMOVE_MEDIC_ATTACH_SPEED

#include "common.sp"
#include <dhooks>
#include <sdktools>

static Handle g_detour_CTFPlayer_TeamFortress_CalculateMaxSpeed;

void RemoveMedicAttachSpeed_Setup(Handle game_config) {
    if (GetOs(game_config) == Windows) {
        LogMessage("'Remove Medic Attach Speed' is currently broken on Windows (sorry!)");
    }

    g_detour_CTFPlayer_TeamFortress_CalculateMaxSpeed =
        CheckedDHookCreateFromConf(game_config, "CTFPlayer::TeamFortress_CalculateMaxSpeed");

    CreateBoolConVar("sm_remove_medic_attach_speed", OnConVarChange);
}

static void OnConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (!DHookToggleDetour(g_detour_CTFPlayer_TeamFortress_CalculateMaxSpeed, HOOK_PRE, Detour_Pre,
                           cvar.BoolValue)) {
        SetFailState("Failed to toggle detour on CTFPlayer::TeamFortress_CalculateMaxSpeed");
    }
}

static MRESReturn Detour_Pre(int self, Handle ret, Handle params) {
    if (DHookGetParam(params, 1)) {
        DHookSetReturn(ret, 0.0);
        return MRES_Override;
    }

    return MRES_Ignored;
}
