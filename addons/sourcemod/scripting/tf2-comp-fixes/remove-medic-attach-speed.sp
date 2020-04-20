#pragma semicolon 1
#pragma newdecls required

#include <dhooks>
#include <sdktools>

ConVar g_remove_medic_attach_speed;

void SetupRemoveMedicAttachSpeed(Handle game_config) {
    g_remove_medic_attach_speed = CreateConVar(
            "sm_remove_medic_attach_speed", "0", "", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    Handle detour = DHookCreateDetour(
        Address_Null, CallConv_THISCALL, ReturnType_Float, ThisPointer_Address);

    if (detour == INVALID_HANDLE) {
        SetFailState("Failed to create detour for CTFPlayer::TeamFortress_CalculateMaxSpeed");
    }

    if (!DHookSetFromConf(detour, game_config, SDKConf_Signature,
                "CTFPlayer::TeamFortress_CalculateMaxSpeed")) {
        SetFailState("Failed to load CTFPlayer::TeamFortress_CalculateMaxSpeed signature from gamedata");
    }

    DHookAddParam(detour, HookParamType_Bool);

    if (!DHookEnableDetour(detour, false, DetourCalculateMaxSpeed)) {
        SetFailState("Failed to detour CTFPlayer::TeamFortress_CalculateMaxSpeed.");
    }
}

MRESReturn DetourCalculateMaxSpeed(Address self, Handle ret, Handle params) {
    if (g_remove_medic_attach_speed.BoolValue
            && DHookGetParam(params, 1)) {
        DHookSetReturn(ret, 0.0);
        return MRES_Supercede;
    }

    return MRES_Ignored;
}
