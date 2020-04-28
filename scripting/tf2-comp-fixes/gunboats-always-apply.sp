#pragma semicolon 1
#pragma newdecls required

#include <dhooks>
#include <sdktools>

#define BUFSIZE 32

ConVar g_gunboats_always_apply;
int g_damaged_other_players_offset;

void SetupGunboatsAlwaysApply(Handle game_config) {
    g_gunboats_always_apply = CreateConVar(
            "sm_gunboats_always_apply", "0", "", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    char buf[BUFSIZE];

    if (!GameConfGetKeyValue(game_config, "CTakeDamageInfo::m_iDamagedOtherPlayers", buf, BUFSIZE)) {
        SetFailState("Failed to load CTFGameRules::m_iDamagedOtherPlayers key from gamedata");
    }

    if (StringToIntEx(buf, g_damaged_other_players_offset) != strlen(buf)) {
        SetFailState("CTFGameRules::m_iDamagedOtherPlayers key could not be entirely parsed as integer");
    }

    Handle detour = DHookCreateDetour(
        Address_Null, CallConv_THISCALL, ReturnType_Float, ThisPointer_Address);

    if (detour == INVALID_HANDLE) {
        SetFailState("Failed to create detour for CTFGameRules::ApplyOnDamageAliveModifyRules");
    }

    if (!DHookSetFromConf(detour, game_config, SDKConf_Signature,
                "CTFGameRules::ApplyOnDamageAliveModifyRules")) {
        SetFailState("Failed to load CTFGameRules::ApplyOnDamageAliveModifyRules signature from gamedata");
    }

    DHookAddParam(detour, HookParamType_ObjectPtr);     // CTakeDamageInfo *
    DHookAddParam(detour, HookParamType_CBaseEntity);   // CBaseEntity *
    DHookAddParam(detour, HookParamType_ObjectPtr);     // DamageModifyExtras_t *

    if (!DHookEnableDetour(detour, false, DetourApplyOnDamageAliveModifyRules)) {
        SetFailState("Failed to detour CTFGameRules::ApplyOnDamageAliveModifyRules");
    }
}

MRESReturn DetourApplyOnDamageAliveModifyRules(Address self, Handle ret, Handle params) {
    if (g_gunboats_always_apply.BoolValue) {
        DHookSetParamObjectPtrVar(params, 1, g_damaged_other_players_offset, ObjectValueType_Int, 0);
        return MRES_Handled;
    }

    return MRES_Ignored;
}
