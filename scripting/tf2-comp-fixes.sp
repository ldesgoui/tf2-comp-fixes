#pragma semicolon 1
#pragma newdecls required

#include <dhooks>
#include <sdktools>
#include <tf2_stocks>

#define WEAPONSLOT_SECONDARY 1
#define HOOK_PRE             false
#define HOOK_POST            true

// Globals

// clang-format off
public
Plugin myinfo = {
    name = "TF2 Competitive Fixes",
    author = "ldesgoui",
    description = "Various technical or gameplay changes \
                   catered towards competitive play",
    version = "1.2.0",
    url = "https://github.com/ldesgoui/tf2-comp-fixes"
};
// clang-format on

ConVar g_cvar_fix_sticky_delay;
Handle g_call_secondary_attack;
Handle g_detour_apply_on_damage_alive_modify_rules;
Handle g_detour_can_collide_with_teammates;
Handle g_detour_drop_halloween_soul_pack;
Handle g_detour_teamfortress_calculate_max_speed;
int    g_offset_damaged_other_players;

// Forwards

public
void OnPluginStart() {
    Handle game_config = LoadGameConfigFile("tf2-comp-fixes.games");

    if (game_config == INVALID_HANDLE) {
        SetFailState(
            "Failed to load addons/sourcemod/gamedata/tf2-comp-fixes.games.txt");
    }

    RegAdminCmd("sm_cf", CfCommand, ADMFLAG_CONVARS,
                "Batch update of TF2 Competitive Fixes cvars");

    g_detour_apply_on_damage_alive_modify_rules = CheckedDHookCreateFromConf(
        game_config, "CTFGameRules::ApplyOnDamageAliveModifyRules");
    g_detour_can_collide_with_teammates = CheckedDHookCreateFromConf(
        game_config, "CBaseProjectile::CanCollideWithTeammates");
    g_detour_drop_halloween_soul_pack = CheckedDHookCreateFromConf(
        game_config, "CTFGameRules::DropHalloweenSoulPack");
    g_detour_teamfortress_calculate_max_speed = CheckedDHookCreateFromConf(
        game_config, "CTFPlayer::TeamFortress_CalculateMaxSpeed");

    CreateBoolConVar("sm_fix_ghost_crossbow_bolts")
        .AddChangeHook(OnChangeFixGhostCrossbowBolts);
    CreateBoolConVar("sm_gunboats_always_apply")
        .AddChangeHook(OnChangeGunboatsAlwaysApply);
    CreateBoolConVar("sm_projectiles_ignore_teammates")
        .AddChangeHook(OnChangeProjectilesIgnoreTeammates);
    CreateBoolConVar("sm_remove_halloween_souls")
        .AddChangeHook(OnChangeRemoveHalloweenSouls);
    CreateBoolConVar("sm_remove_medic_attach_speed")
        .AddChangeHook(OnChangeRemoveMedicAttachSpeed);

    g_cvar_fix_sticky_delay = CreateBoolConVar("sm_fix_sticky_delay");

    g_offset_damaged_other_players = CheckedGameConfGetKeyValueInt(
        game_config, "CTakeDamageInfo::m_iDamagedOtherPlayers");

    StartPrepSDKCall(SDKCall_Entity);

    if (!PrepSDKCall_SetFromConf(game_config, SDKConf_Virtual,
                                 "CTFWeaponBase::SecondaryAttack")) {
        SetFailState(
            "Failed to load CTFWeaponBase::SecondaryAttack offset from gamedata");
    }

    if ((g_call_secondary_attack = EndPrepSDKCall()) == INVALID_HANDLE) {
        SetFailState(
            "Failed to finalize SDK call to CTFWeaponBase::SecondaryAttack");
    }

    RemoveBonusRoundTimeUpperBound();
}

public
void OnMapStart() { RemoveBonusRoundTimeUpperBound(); }

public
Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3],
                      float angles[3], int &currWeapon, int &subtype,
                      int &cmdnum, int &tickcount, int &seed, int mouse[2]) {
    FixStickyDelay(client, buttons);

    return Plugin_Continue;
}

// Commands

Action CfCommand(int client, int args) {
    char full[256];
    bool everything = false;
    bool fixes      = false;

    GetCmdArgString(full, sizeof(full));

    if (StrEqual(full, "all")) {
        everything = true;
    } else if (StrEqual(full, "fixes")) {
        fixes = true;
    } else if (StrEqual(full, "none")) {
    } else {
        ReplyToCommand(client, "usage: sm_cf (all | fixes | none)");
        return Plugin_Handled;
    }

    FindConVar("sm_fix_ghost_crossbow_bolts").SetBool(everything || fixes);
    FindConVar("sm_fix_sticky_delay").SetBool(everything || fixes);
    FindConVar("sm_projectiles_ignore_teammates").SetBool(everything || fixes);
    FindConVar("sm_remove_halloween_souls").SetBool(everything || fixes);

    FindConVar("sm_gunboats_always_apply").SetBool(everything);
    FindConVar("sm_remove_medic_attach_speed").SetBool(everything);

    return Plugin_Handled;
}

// ConVar Change Hooks

void OnChangeFixGhostCrossbowBolts(ConVar cvar, const char[] before,
                                   const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    DHookToggleEntityListener(ListenType_Created, ListenerFixGhostCrossbowBolts,
                              cvar.BoolValue);
}

void OnChangeGunboatsAlwaysApply(ConVar cvar, const char[] before,
                                 const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (!DHookToggleDetour(g_detour_apply_on_damage_alive_modify_rules,
                           HOOK_PRE, DetourApplyOnDamageAliveModifyRules,
                           cvar.BoolValue)) {
        SetFailState(
            "Failed to toggle detour CTFGameRules::ApplyOnDamageAliveModifyRules");
    }
}

void OnChangeProjectilesIgnoreTeammates(ConVar cvar, const char[] before,
                                        const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    DHookToggleEntityListener(
        ListenType_Created, ListenerProjectilesIgnoreTeammates, cvar.BoolValue);
}

void OnChangeRemoveHalloweenSouls(ConVar cvar, const char[] before,
                                  const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (!DHookToggleDetour(g_detour_drop_halloween_soul_pack, HOOK_PRE,
                           DetourDropHalloweenSoulPack, cvar.BoolValue)) {
        SetFailState(
            "Failed to toggle detour CTFGameRules::DropHalloweenSoulPack");
    }
}

void OnChangeRemoveMedicAttachSpeed(ConVar cvar, const char[] before,
                                    const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (!DHookToggleDetour(g_detour_teamfortress_calculate_max_speed, HOOK_PRE,
                           DetourCalculateMaxSpeed, cvar.BoolValue)) {
        SetFailState(
            "Failed to toggle detour CTFPlayer::TeamFortress_CalculateMaxSpeed");
    }
}

// Entity Listeners

void ListenerFixGhostCrossbowBolts(int entity, const char[] classname) {
    if (StrEqual(classname, "tf_projectile_healing_bolt")) {
        DHookEntity(g_detour_can_collide_with_teammates, HOOK_PRE, entity, _,
                    DetourFixGhostCrossbowBolts);
    }
}

void ListenerProjectilesIgnoreTeammates(int entity, const char[] classname) {
    if (StrContains(classname, "tf_projectile_") != -1 &&
        !StrEqual(classname, "tf_projectile_healing_bolt")) {
        DHookEntity(g_detour_can_collide_with_teammates, HOOK_PRE, entity, _,
                    DetourProjectilesIgnoreTeammates);
    }
}

// Detours

MRESReturn DetourFixGhostCrossbowBolts(Address self, Handle ret,
                                       Handle params) {
    DHookSetReturn(ret, 1);
    return MRES_Supercede;
}

MRESReturn DetourProjectilesIgnoreTeammates(Address self, Handle ret,
                                            Handle params) {
    DHookSetReturn(ret, 0);
    return MRES_Supercede;
}

MRESReturn DetourApplyOnDamageAliveModifyRules(Address self, Handle ret,
                                               Handle params) {
    DHookSetParamObjectPtrVar(params, 1, g_offset_damaged_other_players,
                              ObjectValueType_Int, 0);
    return MRES_Handled;
}

MRESReturn DetourCalculateMaxSpeed(Address self, Handle ret, Handle params) {
    if (DHookGetParam(params, 1)) {
        DHookSetReturn(ret, 0.0);
        return MRES_Supercede;
    }

    return MRES_Ignored;
}

MRESReturn DetourDropHalloweenSoulPack(Address self, Handle ret,
                                       Handle params) {
    return MRES_Supercede;
}

// Stocks

stock Handle CheckedDHookCreateFromConf(Handle game_config, const char[] name) {
    Handle res = DHookCreateFromConf(game_config, name);

    if (res == INVALID_HANDLE) {
        SetFailState("Failed to create detour for %s", name);
    }

    return res;
}

stock Address CheckedGameConfGetAddress(Handle game_config, const char[] name) {
    Address res = GameConfGetAddress(game_config, name);

    if (res == Address_Null) {
        SetFailState("Failed to load %s signature from gamedata", name);
    }

    return res;
}

stock int CheckedGameConfGetKeyValueInt(Handle game_config, const char[] name) {
    int  res;
    char buf[32];

    if (!GameConfGetKeyValue(game_config, name, buf, sizeof(buf))) {
        SetFailState("Failed to load %s key from gamedata", name);
    }

    if (StringToIntEx(buf, res) != strlen(buf)) {
        SetFailState("%s key is not a valid integer");
    }

    return res;
}

stock ConVar CreateBoolConVar(const char[] name,
                              const char[] description = "") {
    return CreateConVar(name, "0", description, FCVAR_NOTIFY, true, 0.0, true,
                        1.0);
}

stock bool DHookToggleDetour(Handle setup, bool post, DHookCallback callback,
                             bool enabled) {
    if (enabled) {
        return DHookEnableDetour(setup, post, callback);
    } else {
        return DHookDisableDetour(setup, post, callback);
    }
}

stock void DHookToggleEntityListener(ListenType listen_type, ListenCB callback,
                                     bool enabled) {
    if (enabled) {
        DHookAddEntityListener(listen_type, callback);
    } else {
        DHookRemoveEntityListener(listen_type, callback);
    }
}

stock bool TruthyConVar(const char[] val) { return StringToFloat(val) == 1.0; }

stock void FixStickyDelay(int client, int &buttons) {
    int weapon, item_id;

    if (g_cvar_fix_sticky_delay.BoolValue && buttons & IN_ATTACK2 &&
        IsPlayerAlive(client) &&
        TF2_GetPlayerClass(client) == TFClass_DemoMan &&
        (weapon = GetPlayerWeaponSlot(client, WEAPONSLOT_SECONDARY)) &&
        weapon != -1 &&
        (item_id = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")) &&
        item_id != -1 && item_id != 131 /* The Chargin' Targe */
        && item_id != 406               /* The Splendid Screen */
        && item_id != 1099              /* The Tide Turner */
        && item_id != 1144              /* Festive Targe */
    ) {
        SDKCall(g_call_secondary_attack, weapon);
    }
}

stock void RemoveBonusRoundTimeUpperBound() {
    SetConVarBounds(FindConVar("mp_bonusroundtime"), ConVarBound_Upper, false);
}
