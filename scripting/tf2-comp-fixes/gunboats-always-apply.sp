#pragma semicolon 1
#pragma newdecls required

#include <dhooks>
#include <sdktools>
#include "utils.sp"

ConVar g_gunboats_always_apply;
int g_damaged_other_players_offset;

void SetupGunboatsAlwaysApply(Handle game_config) {
    g_gunboats_always_apply = CreateBoolConVar("sm_gunboats_always_apply");

    char buf[32];

    if (!GameConfGetKeyValue(game_config, "CTakeDamageInfo::m_iDamagedOtherPlayers",
                buf, sizeof(buf))) {
        SetFailState("Failed to load CTFGameRules::m_iDamagedOtherPlayers key "
                ... "from gamedata");
    }

    if (StringToIntEx(buf, g_damaged_other_players_offset) != strlen(buf)) {
        SetFailState("CTFGameRules::m_iDamagedOtherPlayers key "
                ... "could not be entirely parsed as integer");
    }

    Handle detour = DHookCreateFromConf(game_config,
            "CTFGameRules::ApplyOnDamageAliveModifyRules");

    if (detour == INVALID_HANDLE) {
        SetFailState("Failed to create detour for "
                ... "CTFGameRules::ApplyOnDamageAliveModifyRules");
    }

    if (!DHookEnableDetour(detour, false, DetourApplyOnDamageAliveModifyRules)) {
        SetFailState("Failed to enable "
                ... "detour CTFGameRules::ApplyOnDamageAliveModifyRules");
    }
}

MRESReturn DetourApplyOnDamageAliveModifyRules(Address self, Handle ret, Handle params) {
    if (g_gunboats_always_apply.BoolValue) {
        DHookSetParamObjectPtrVar(params, 1,
                g_damaged_other_players_offset, ObjectValueType_Int, 0);

        return MRES_Handled;
    }

    return MRES_Ignored;
}
