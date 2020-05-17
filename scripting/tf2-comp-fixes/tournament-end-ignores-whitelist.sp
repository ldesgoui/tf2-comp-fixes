#if defined _TF2_COMP_FIXES_TOURNAMENT_END_IGNORES_WHITELIST
#endinput
#endif
#define _TF2_COMP_FIXES_TOURNAMENT_END_IGNORES_WHITELIST

#include "common.sp"
#include <dhooks>
#include <sdktools>

static int    g_hook_id_pre  = -1;
static int    g_hook_id_post = -1;
static Handle g_detour_CEconItemSystem_ReloadWhitelist;
static Handle g_detour_CTeamplayRoundBasedRules_RestartTournament;

void TournamentEndIgnoresWhitelist_Setup(Handle game_config) {
    g_detour_CTeamplayRoundBasedRules_RestartTournament =
        CheckedDHookCreateFromConf(game_config, "CTeamplayRoundBasedRules::RestartTournament");

    g_detour_CEconItemSystem_ReloadWhitelist =
        CheckedDHookCreateFromConf(game_config, "CEconItemSystem::ReloadWhitelist");

    ConVar cvar = CreateConVar("sm_tournament_end_ignores_whitelist", "1", _, FCVAR_NOTIFY, true,
                               0.0, true, 1.0);

    CallConVarUpdateHook(cvar, OnConVarChange);

    RegServerCmd("mp_tournament_restart", Command_TournamentRestart);
}

static Action Command_TournamentRestart(int args) {
    DisableHook();
    CreateTimer(0.01, Timer_TournamentRestart_Post);

    return Plugin_Continue;
}

static Action Timer_TournamentRestart_Post(Handle timer) {
    EnableHook();
    return Plugin_Continue;
}

static void OnConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (cvar.BoolValue) {
        EnableHook();
    } else {
        DisableHook();
    }
}

static void EnableHook() {
    g_hook_id_pre =
        DHookGamerules(g_detour_CTeamplayRoundBasedRules_RestartTournament, HOOK_PRE, _, Hook_Pre);

    if (g_hook_id_pre == -1) {
        SetFailState("Failed to hook CTeamplayRoundBasedRules::RestartTournament");
    }

    g_hook_id_post = DHookGamerules(g_detour_CTeamplayRoundBasedRules_RestartTournament, HOOK_POST,
                                    _, Hook_Post);

    if (g_hook_id_post == -1) {
        DisableHook();
        SetFailState("Failed to hook CTeamplayRoundBasedRules::RestartTournament");
    }
}

static void DisableHook() {
    if (g_hook_id_pre != -1) {
        DHookRemoveHookID(g_hook_id_pre);
        g_hook_id_pre = -1;
    }

    if (g_hook_id_post != -1) {
        DHookRemoveHookID(g_hook_id_post);
        g_hook_id_post = -1;
    }
}

static MRESReturn Hook_Pre(Address self) {
    DHookEnableDetour(g_detour_CEconItemSystem_ReloadWhitelist, HOOK_PRE, Detour_Pre);

    return MRES_Handled;
}

static MRESReturn Hook_Post(Address self) {
    DHookDisableDetour(g_detour_CEconItemSystem_ReloadWhitelist, HOOK_PRE, Detour_Pre);

    return MRES_Handled;
}

static MRESReturn Detour_Pre(Address self) {
    PrintToChatAll("[TF2 Comp Fixes] Preventing Whitelist Reload");
    return MRES_Supercede;
}
