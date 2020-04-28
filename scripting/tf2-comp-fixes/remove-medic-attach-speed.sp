#pragma semicolon 1
#pragma newdecls required

#include <dhooks>
#include <sdktools>
#include "utils.sp"

ConVar g_remove_medic_attach_speed;

void SetupRemoveMedicAttachSpeed(Handle game_config) {
    g_remove_medic_attach_speed = CreateBoolConVar("sm_remove_medic_attach_speed");

    Handle detour = DHookCreateFromConf(game_config,
            "CTFPlayer::TeamFortress_CalculateMaxSpeed");

    if (detour == INVALID_HANDLE) {
        SetFailState("Failed to create detour for "
                ... "CTFPlayer::TeamFortress_CalculateMaxSpeed");
    }

    if (!DHookEnableDetour(detour, false, DetourCalculateMaxSpeed)) {
        SetFailState("Failed to enable detour CTFPlayer::TeamFortress_CalculateMaxSpeed.");
    }
}

MRESReturn DetourCalculateMaxSpeed(Address self, Handle ret, Handle params) {
    if (g_remove_medic_attach_speed.BoolValue && DHookGetParam(params, 1)) {
        DHookSetReturn(ret, 0.0);

        return MRES_Supercede;
    }

    return MRES_Ignored;
}
