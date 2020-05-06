#if defined _TF2_COMP_FIXES_REMOVE_HALLOWEEN_SOULS
#endinput
#endif
#define _TF2_COMP_FIXES_REMOVE_HALLOWEEN_SOULS

#include "common.sp"
#include <dhooks>
#include <sdktools>

static Handle g_detour_CTFGameRules_DropHalloweenSoulPack;

void RemoveHalloweenSouls_Setup(Handle game_config) {
    g_detour_CTFGameRules_DropHalloweenSoulPack =
        CheckedDHookCreateFromConf(game_config, "CTFGameRules::DropHalloweenSoulPack");

    CreateBoolConVar("sm_remove_halloween_souls", OnConVarChange);
}

static void OnConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (!DHookToggleDetour(g_detour_CTFGameRules_DropHalloweenSoulPack, HOOK_PRE,
                           Detour_CTFGameRules_DropHalloweenSoulPack, cvar.BoolValue)) {
        SetFailState("Failed to toggle detour on CTFGameRules::DropHalloweenSoulPack");
    }
}

static MRESReturn Detour_CTFGameRules_DropHalloweenSoulPack(Address self, Handle ret,
                                                            Handle params) {
    return MRES_Supercede;
}
