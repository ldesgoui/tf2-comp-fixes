#pragma semicolon 1
#pragma newdecls required

#include <dhooks>
#include <functions>
#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>

#define HOOK_PRE  (false)
#define HOOK_POST (true)

#define INVALID_HOOK_ID (-1)

Handle g_call_CTFWeaponBase_PrimaryAttack;
Handle g_call_CTFWeaponBase_SecondaryAttack;
Handle g_detour_CTFGameRules_ApplyOnDamageAliveModifyRules;
Handle g_detour_CTFGameRules_DropHalloweenSoulPack;
Handle g_detour_CTFWeaponBase_ItemBusyFrame;
Handle g_detour_CTFPlayer_TeamFortress_CalculateMaxSpeed;
Handle g_hook_CBaseProjectile_CanCollideWithTeammates;
Handle g_hook_CTFWeaponBase_SecondaryAttack;
int    g_offset_CTakeDamageInfo_m_iDamagedOtherPlayers;

// clang-format off
public
Plugin myinfo = {
    name = "TF2 Competitive Fixes",
    author = "ldesgoui",
    description = "Various technical or gameplay changes \
                   catered towards competitive play",
    version = "1.3.0",
    url = "https://github.com/ldesgoui/tf2-comp-fixes"
};
// clang-format on

public
void OnPluginStart() {
    Handle game_config = LoadGameConfigFile("tf2-comp-fixes.games");

    if (game_config == INVALID_HANDLE) {
        SetFailState("Failed to load addons/sourcemod/gamedata/tf2-comp-fixes.games.txt");
    }

    RegAdminCmd("sm_cf", CfCommand, ADMFLAG_CONVARS, "Batch update of TF2 Competitive Fixes cvars");

    CreateBoolConVar("sm_fix_ghost_crossbow_bolts", FixGhostCrossbowBolts_OnConVarChange);
    CreateBoolConVar("sm_fix_sticky_delay", FixStickyDelay_OnConVarChange);
    CreateBoolConVar("sm_gunboats_always_apply", GunboatsAlwaysApply_OnConVarChange);
    CreateBoolConVar("sm_projectiles_ignore_teammates", ProjectilesIgnoreTeammates_OnConVarChange);
    CreateBoolConVar("sm_remove_halloween_souls", RemoveHalloweenSouls_OnConVarChange);
    CreateBoolConVar("sm_remove_medic_attach_speed", RemoveMedicAttachSpeed_OnConVarChange);

    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(game_config, SDKConf_Virtual, "CTFWeaponBase::PrimaryAttack");
    if ((g_call_CTFWeaponBase_PrimaryAttack = EndPrepSDKCall()) == INVALID_HANDLE) {
        SetFailState("Failed to finalize SDK call to CTFWeaponBase::PrimaryAttack");
    }

    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(game_config, SDKConf_Virtual, "CTFWeaponBase::SecondaryAttack");
    if ((g_call_CTFWeaponBase_SecondaryAttack = EndPrepSDKCall()) == INVALID_HANDLE) {
        SetFailState("Failed to finalize SDK call to CTFWeaponBase::SecondaryAttack");
    }

    g_detour_CTFGameRules_ApplyOnDamageAliveModifyRules =
        CheckedDHookCreateFromConf(game_config, "CTFGameRules::ApplyOnDamageAliveModifyRules");
    g_detour_CTFGameRules_DropHalloweenSoulPack =
        CheckedDHookCreateFromConf(game_config, "CTFGameRules::DropHalloweenSoulPack");
    g_detour_CTFPlayer_TeamFortress_CalculateMaxSpeed =
        CheckedDHookCreateFromConf(game_config, "CTFPlayer::TeamFortress_CalculateMaxSpeed");
    g_detour_CTFWeaponBase_ItemBusyFrame =
        CheckedDHookCreateFromConf(game_config, "CTFWeaponBase::ItemBusyFrame");

    g_hook_CBaseProjectile_CanCollideWithTeammates =
        CheckedDHookCreateFromConf(game_config, "CBaseProjectile::CanCollideWithTeammates");
    g_hook_CTFWeaponBase_SecondaryAttack =
        CheckedDHookCreateFromConf(game_config, "CTFWeaponBase::SecondaryAttack");

    g_offset_CTakeDamageInfo_m_iDamagedOtherPlayers =
        CheckedGameConfGetKeyValueInt(game_config, "CTakeDamageInfo::m_iDamagedOtherPlayers");

    RemoveBonusRoundTimeUpperBound();

    int i = -1;
    while ((i = FindEntityByClassname(i, "tf_weapon_syringegun_medic")) != -1) {
        DHookEntity(g_hook_CTFWeaponBase_SecondaryAttack, HOOK_PRE, i, _, hook);
    }
}

public
void OnMapStart() { RemoveBonusRoundTimeUpperBound(); }

public
void OnClientPutInServer(int client) { SDKHook(client, SDKHook_WeaponCanUse, fuk); }

void fuk(int client, int weapon) {
    char classname[64];
    if (!GetEntityClassname(weapon, classname, sizeof(classname))) {
        return;
    }

    if (!StrEqual(classname, "tf_weapon_syringegun_medic")) {
        return;
    }

    DHookEntity(g_hook_CTFWeaponBase_SecondaryAttack, HOOK_PRE, weapon, _, hook);
}

MRESReturn hook(int self) {
    PrintToChatAll("FUCK YOU");

    if (GetEntPropFloat(self, Prop_Send, "m_flNextSecondaryAttack") > GetGameTime()) {
        return MRES_Supercede;
    }

    int client = GetEntPropEnt(self, Prop_Send, "m_hOwner");

    if (client == 0 || client > MaxClients) {
        return MRES_Supercede;
    }

    int ammo_type = GetEntProp(self, Prop_Send, "m_iPrimaryAmmoType");

    // this dont work
    if (GetEntProp(client, Prop_Send, "m_iAmmo", 4, ammo_type) < 10) {
        return MRES_Supercede;
    }

    for (int i = 0; i < 10; i++) {
        SetEntPropFloat(self, Prop_Send, "m_flNextPrimaryAttack", 0.0);
        SDKCall(g_call_CTFWeaponBase_PrimaryAttack, self);
    }

    SetEntPropFloat(self, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1.5);
    SetEntPropFloat(self, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 1.5);
    return MRES_Supercede;
}

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

// === FIX GHOST CROSSBOW BOLTS ===

void FixGhostCrossbowBolts_OnConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    DHookToggleEntityListener(ListenType_Created, FixGhostCrossbowBolts_OnEntityCreated,
                              cvar.BoolValue);
}

void FixGhostCrossbowBolts_OnEntityCreated(int entity, const char[] classname) {
    if (StrEqual(classname, "tf_projectile_healing_bolt")) {
        if (INVALID_HOOK_ID ==
            DHookEntity(g_hook_CBaseProjectile_CanCollideWithTeammates, HOOK_PRE, entity, _,
                        FixGhostCrossbowBolts_Hook_CBaseProjectile_CanCollideWithTeammates)) {
            SetFailState("Failed to hook CBaseProjectile::CanCollideWithTeammates");
        }
    }
}

MRESReturn FixGhostCrossbowBolts_Hook_CBaseProjectile_CanCollideWithTeammates(int    self,
                                                                              Handle ret) {
    DHookSetReturn(ret, true);
    return MRES_Supercede;
}

// === FIX STICKY DELAY BUG ===

void FixStickyDelay_OnConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (!DHookToggleDetour(g_detour_CTFWeaponBase_ItemBusyFrame, HOOK_PRE,
                           FixStickyDelay_Detour_ItemBusyFrame, cvar.BoolValue)) {
        SetFailState("Failed to toggle detour on CTFWeaponBase::ItemBusyFrame");
    }
}

stock MRESReturn FixStickyDelay_Detour_ItemBusyFrame(int self, Handle ret) {
    int owner = GetEntPropEnt(self, Prop_Data, "m_hOwnerEntity");

    if (GetClientButtons(owner) & IN_ATTACK2 != IN_ATTACK2) {
        return MRES_Ignored;
    }

    int secondary = GetPlayerWeaponSlot(owner, TFWeaponSlot_Secondary);
    if (secondary == -1) {
        return MRES_Ignored;
    }

    // XXX: perf?
    char classname[64];
    if (!GetEntityClassname(secondary, classname, sizeof(classname))) {
        return MRES_Ignored;
    }

    if (!StrEqual(classname, "tf_weapon_pipebomblauncher")) {
        return MRES_Ignored;
    }

    SDKCall(g_call_CTFWeaponBase_SecondaryAttack, self);

    return MRES_Handled;
}

// === GUNBOATS ALWAYS APPLY ===

void GunboatsAlwaysApply_OnConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (!DHookToggleDetour(g_detour_CTFGameRules_ApplyOnDamageAliveModifyRules, HOOK_PRE,
                           GunboatsAlwaysApply_Detour_ApplyOnDamageAliveModifyRules,
                           cvar.BoolValue)) {
        SetFailState("Failed to toggle detour on CTFGameRules::ApplyOnDamageAliveModifyRules");
    }
}

MRESReturn GunboatsAlwaysApply_Detour_ApplyOnDamageAliveModifyRules(Address self, Handle ret,
                                                                    Handle params) {
    DHookSetParamObjectPtrVar(params, 1, g_offset_CTakeDamageInfo_m_iDamagedOtherPlayers,
                              ObjectValueType_Int, 0);
    return MRES_Handled;
}

// === PROJECTILES IGNORE TEAMMATES ===

void ProjectilesIgnoreTeammates_OnConVarChange(ConVar cvar, const char[] before,
                                               const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    DHookToggleEntityListener(ListenType_Created, ProjectilesIgnoreTeammates_OnEntityCreated,
                              cvar.BoolValue);
}

void ProjectilesIgnoreTeammates_OnEntityCreated(int entity, const char[] classname) {
    if (StrContains(classname, "tf_projectile_") != -1 &&
        !StrEqual(classname, "tf_projectile_healing_bolt")) {
        if (INVALID_HOOK_ID ==
            DHookEntity(g_hook_CBaseProjectile_CanCollideWithTeammates, HOOK_PRE, entity, _,
                        ProjectilesIgnoreTeammates_Hook_CBaseProjectile_CanCollideWithTeammates)) {
            SetFailState("Failed to hook CBaseProjectile::CanCollideWithTeammates");
        }
    }
}

MRESReturn ProjectilesIgnoreTeammates_Hook_CBaseProjectile_CanCollideWithTeammates(int    self,
                                                                                   Handle ret) {
    DHookSetReturn(ret, false);
    return MRES_Supercede;
}

// === REMOVE BONUS ROUND TIME UPPER BOUND ===

void RemoveBonusRoundTimeUpperBound() {
    SetConVarBounds(FindConVar("mp_bonusroundtime"), ConVarBound_Upper, false);
}

// === REMOVE HALLOWEEN SOULS ===

void RemoveHalloweenSouls_OnConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (!DHookToggleDetour(g_detour_CTFGameRules_DropHalloweenSoulPack, HOOK_PRE,
                           RemoveHalloweenSouls_Detour_CTFGameRules_DropHalloweenSoulPack,
                           cvar.BoolValue)) {
        SetFailState("Failed to toggle detour on CTFGameRules::DropHalloweenSoulPack");
    }
}

MRESReturn RemoveHalloweenSouls_Detour_CTFGameRules_DropHalloweenSoulPack(Address self, Handle ret,
                                                                          Handle params) {
    return MRES_Supercede;
}

// === REMOVE MEDIC ATTACH SPEED ===

void RemoveMedicAttachSpeed_OnConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (!DHookToggleDetour(g_detour_CTFPlayer_TeamFortress_CalculateMaxSpeed, HOOK_PRE,
                           RemoveMedicAttachSpeed_Detour_CTFPlayer_TeamFortress_CalculateMaxSpeed,
                           cvar.BoolValue)) {
        SetFailState("Failed to toggle detour on CTFPlayer::TeamFortress_CalculateMaxSpeed");
    }
}

MRESReturn RemoveMedicAttachSpeed_Detour_CTFPlayer_TeamFortress_CalculateMaxSpeed(int    self,
                                                                                  Handle ret,
                                                                                  Handle params) {
    if (DHookGetParam(params, 1)) {
        DHookSetReturn(ret, 0.0);
        return MRES_Supercede;
    }

    return MRES_Ignored;
}

//

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

stock ConVar CreateBoolConVar(const char[] name, ConVarChanged callback) {
    ConVar cvar = CreateConVar(name, "0", _, FCVAR_NOTIFY, true, 0.0, true, 1.0);

    cvar.AddChangeHook(callback);

    char current[128];
    cvar.GetString(current, sizeof(current));

    Call_StartFunction(INVALID_HANDLE, callback);
    Call_PushCell(cvar);
    Call_PushString("0");
    Call_PushString(current);
    Call_Finish();

    return cvar;
}

stock bool DHookToggleDetour(Handle setup, bool post, DHookCallback callback, bool enabled) {
    if (enabled) {
        return DHookEnableDetour(setup, post, callback);
    } else {
        return DHookDisableDetour(setup, post, callback);
    }
}

stock void DHookToggleEntityListener(ListenType listen_type, ListenCB callback, bool enabled) {
    if (enabled) {
        DHookAddEntityListener(listen_type, callback);
    } else {
        DHookRemoveEntityListener(listen_type, callback);
    }
}

stock bool TruthyConVar(const char[] val) { return StringToFloat(val) == 1.0; }
