#pragma semicolon 1
#pragma newdecls required

#include <dhooks>
#include <sdktools>

ConVar g_remove_halloween_souls;

void SetupRemoveHalloweenSouls(Handle game_config) {
    g_remove_halloween_souls = CreateConVar(
            "sm_remove_halloween_souls", "0", "", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    Handle detour = DHookCreateDetour(
        Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_Address);

    if (detour == INVALID_HANDLE) {
        SetFailState("Failed to create detour for CTFGameRules::DropHalloweenSoulPack");
    }

    if (!DHookSetFromConf(detour, game_config, SDKConf_Signature, "CTFGameRules::DropHalloweenSoulPack")) {
        SetFailState("Failed to load CTFGameRules::DropHalloweenSoulPack signature from gamedata");
    }

    DHookAddParam(detour, HookParamType_Bool);

    if (!DHookEnableDetour(detour, false, DetourDropHalloweenSoulPack)) {
        SetFailState("Failed to detour CTFGameRules::DropHalloweenSoulPack.");
    }
}

MRESReturn DetourDropHalloweenSoulPack(Address self, Handle ret, Handle params) {
    if (g_remove_halloween_souls.BoolValue) {
        return MRES_Supercede;
    }

    return MRES_Ignored;
}
