#pragma semicolon 1
#pragma newdecls required

#include <dhooks>
#include <sdktools>
#include "utils.sp"

ConVar g_remove_halloween_souls;

void SetupRemoveHalloweenSouls(Handle game_config) {
    g_remove_halloween_souls = CreateBoolConVar("sm_remove_halloween_souls");

    Handle detour = DHookCreateFromConf(game_config,
            "CTFGameRules::DropHalloweenSoulPack");

    if (detour == INVALID_HANDLE) {
        SetFailState("Failed to create detour for CTFGameRules::DropHalloweenSoulPack");
    }

    if (!DHookEnableDetour(detour, false, DetourDropHalloweenSoulPack)) {
        SetFailState("Failed to enable detour CTFGameRules::DropHalloweenSoulPack.");
    }
}

MRESReturn DetourDropHalloweenSoulPack(Address self, Handle ret, Handle params) {
    if (g_remove_halloween_souls.BoolValue) {
        return MRES_Supercede;
    }

    return MRES_Ignored;
}
