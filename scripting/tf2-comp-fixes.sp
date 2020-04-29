#pragma semicolon 1
#pragma newdecls required

#include <dhooks>
#include <sdktools>
#include <tf2_stocks>

#define WEAPONSLOT_SECONDARY 1

// Globals

public Plugin myinfo = {
    name = "TF2 Competitive Fixes",
    author = "ldesgoui",
    description = "Various technical or gameplay altering changes "
        ... "catered towards competitive play",
    version = "1.2.0",
    url = "https://github.com/ldesgoui/tf2-comp-fixes"
};

Address g_vtable_healingbolt;
ConVar g_cvar_fix_sticky_delay;
Handle g_call_secondary_attack;
Handle g_detour_apply_on_damage_alive_modify_rules;
Handle g_detour_can_collide_with_teammates;
Handle g_detour_drop_halloween_soul_pack;
Handle g_detour_teamfortress_calculate_max_speed;
int g_offset_damaged_other_players;

// Forwards

public void OnPluginStart() {
    Handle game_config = LoadGameConfigFile("tf2-comp-fixes.games");

    if (game_config == INVALID_HANDLE) {
        SetFailState("Failed to load "
                ... "addons/sourcemod/gamedata/tf2-comp-fixes.games.txt");
    }



    g_detour_teamfortress_calculate_max_speed = CheckedDHookCreateFromConf(
            game_config, "CTFPlayer::TeamFortress_CalculateMaxSpeed");
    g_detour_apply_on_damage_alive_modify_rules = CheckedDHookCreateFromConf(
            game_config, "CTFGameRules::ApplyOnDamageAliveModifyRules");
    g_detour_can_collide_with_teammates = CheckedDHookCreateFromConf(
            game_config, "CBaseProjectile::CanCollideWithTeammates");
    g_detour_drop_halloween_soul_pack = CheckedDHookCreateFromConf(
            game_config, "CTFGameRules::DropHalloweenSoulPack");


    CreateBoolConVar("sm_fix_ghost_crossbow_bolts")
        .AddChangeHook(OnChangeCanCollideWithTeammates);
    CreateBoolConVar("sm_projectiles_ignore_teammates")
        .AddChangeHook(OnChangeCanCollideWithTeammates);

    CreateBoolConVar("sm_gunboats_always_apply")
        .AddChangeHook(OnChangeGunboatsAlwaysApply);
    CreateBoolConVar("sm_remove_halloween_souls")
        .AddChangeHook(OnChangeRemoveHalloweenSouls);
    CreateBoolConVar("sm_remove_medic_attach_speed")
        .AddChangeHook(OnChangeRemoveMedicAttachSpeed);

    g_cvar_fix_sticky_delay = CreateBoolConVar("sm_fix_sticky_delay");


    g_offset_damaged_other_players = CheckedGameConfGetKeyValueInt(
            game_config, "CTakeDamageInfo::m_iDamagedOtherPlayers");


    g_vtable_healingbolt = CheckedGameConfGetAddress(
            game_config, "CTFProjectile_HealingBolt::vtable");


    StartPrepSDKCall(SDKCall_Entity);

    if (!PrepSDKCall_SetFromConf(game_config, SDKConf_Virtual,
                "CTFWeaponBase::SecondaryAttack")) {
        SetFailState("Failed to load CTFWeaponBase::SecondaryAttack offset "
                ... "from gamedata");
    }

    if ((g_call_secondary_attack = EndPrepSDKCall()) == INVALID_HANDLE) {
        SetFailState("Failed to finalize SDK call to CTFWeaponBase::SecondaryAttack");
    }


    RemoveBonusRoundTimeUpperBound();
}


public void OnMapStart() {
    RemoveBonusRoundTimeUpperBound();
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse,
        float vel[3], float angles[3], int &currWeapon, int &subtype,
        int &cmdnum, int &tickcount, int &seed, int mouse[2]) {
    FixStickyDelay(client, buttons);

    return Plugin_Continue;
}

// ConVar Change Hooks

void OnChangeCanCollideWithTeammates(
        ConVar cvar, const char[] before, const char[] after) {
    bool previous = TruthyConVar(before);

    if (previous == cvar.BoolValue) {
        return;
    }

    bool fix_bolts = FindConVar("sm_fix_ghost_crossbow_bolts").BoolValue;
    bool fix_projectiles = FindConVar("sm_projectiles_ignore_teammates").BoolValue;
    DHookCallback enable;
    DHookCallback disable;

    if (fix_bolts && fix_projectiles) {
        enable = DetourCanCollideWithTeammates;
    } else if (fix_bolts) {
        enable = DetourFixGhostCrossbowBolts;
    } else if (fix_projectiles) {
        enable = DetourProjectilesIgnoreTeammates;
    }

    // bolts before | projs before | previous | cvar name | bolts after | projs after
    //    true      |    false     |   false  |   bolts   |    false    |    false
    //    false     |    true      |   false  |   projs   |    false    |    false
    //    true      |    false     |   true   |   projs   |    true     |    true
    //    false     |    true      |   true   |   bolts   |    true     |    true
    if (fix_bolts == fix_projectiles) {
        char name[64];
        cvar.GetName(name, sizeof(name));

        disable = previous == StrEqual(name, "sm_fix_ghost_crossbow_bolts")
            ? DetourFixGhostCrossbowBolts
            : DetourProjectilesIgnoreTeammates;
    } else if (previous) {
        disable = DetourCanCollideWithTeammates;
    }

    if (disable && !DHookDisableDetour(
                g_detour_can_collide_with_teammates, false, disable)) {
        SetFailState("Failed to disable detour on "
                ... "CBaseProjectile::CanCollideWithTeammates.");
    }

    if (enable && !DHookEnableDetour(
                g_detour_can_collide_with_teammates, false, enable)) {
        SetFailState("Failed to enable detour on "
                ... "CBaseProjectile::CanCollideWithTeammates.");
    }
}

void OnChangeGunboatsAlwaysApply(
        ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (!DHookToggleDetour(g_detour_apply_on_damage_alive_modify_rules, false,
                DetourApplyOnDamageAliveModifyRules, cvar.BoolValue)) {
        SetFailState("Failed to toggle detour "
                ... "CTFGameRules::ApplyOnDamageAliveModifyRules");
    }
}

void OnChangeRemoveHalloweenSouls(
        ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (!DHookToggleDetour(g_detour_drop_halloween_soul_pack, false,
                DetourDropHalloweenSoulPack, cvar.BoolValue)) {
        SetFailState("Failed to toggle detour "
                ... "CTFGameRules::DropHalloweenSoulPack.");
    }
}


void OnChangeRemoveMedicAttachSpeed(
        ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (!DHookToggleDetour(g_detour_teamfortress_calculate_max_speed, false,
                DetourCalculateMaxSpeed, cvar.BoolValue)) {
        SetFailState("Failed to toggle detour "
                ... "CTFPlayer::TeamFortress_CalculateMaxSpeed.");
    }
}

// Detours

MRESReturn DetourCanCollideWithTeammates(Address self, Handle ret, Handle params) {
    if (DetourFixGhostCrossbowBolts(self, ret, params) == MRES_Supercede) {
        return MRES_Supercede;
    }

    return DetourProjectilesIgnoreTeammates(self, ret, params);
}

MRESReturn DetourFixGhostCrossbowBolts(Address self, Handle ret, Handle params) {
    int vtable = LoadFromAddress(self, NumberType_Int32);

    if ((vtable - 8) == view_as<int>(g_vtable_healingbolt)) {
        DHookSetReturn(ret, 1);
        return MRES_Supercede;
    }

    return MRES_Ignored;
}

MRESReturn DetourProjectilesIgnoreTeammates(Address self, Handle ret, Handle params) {
    DHookSetReturn(ret, 0);
    return MRES_Supercede;
}

MRESReturn DetourApplyOnDamageAliveModifyRules(Address self, Handle ret, Handle params) {
    DHookSetParamObjectPtrVar(params, 1,
            g_offset_damaged_other_players, ObjectValueType_Int, 0);
    return MRES_Handled;
}

MRESReturn DetourCalculateMaxSpeed(Address self, Handle ret, Handle params) {
    if (DHookGetParam(params, 1)) {
        DHookSetReturn(ret, 0.0);
        return MRES_Supercede;
    }

    return MRES_Ignored;
}

MRESReturn DetourDropHalloweenSoulPack(Address self, Handle ret, Handle params) {
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
    int res;
    char buf[32];

    if (!GameConfGetKeyValue(game_config, name, buf, sizeof(buf))) {
        SetFailState("Failed to load %s key from gamedata", name);
    }

    if (StringToIntEx(buf, res) != strlen(buf)) {
        SetFailState("%s key is not a valid integer");
    }

    return res;
}

stock ConVar CreateBoolConVar(const char[] name, const char[] description = "") {
    return CreateConVar(
            name,
            "0",
            description,
            FCVAR_NOTIFY,
            true, 0.0,
            true, 1.0);
}

stock bool DHookToggleDetour(Handle setup, bool post, DHookCallback callback,
        bool enabled) {
    if (enabled) {
        return DHookEnableDetour(setup, post, callback);
    } else {
        return DHookDisableDetour(setup, post, callback);
    }
}

stock bool TruthyConVar(const char[] val) {
    return StringToFloat(val) == 1.0;
}

stock void FixStickyDelay(int client, int &buttons) {
    int weapon, item_id;

    if (g_cvar_fix_sticky_delay.BoolValue
            && buttons & IN_ATTACK2
            && IsPlayerAlive(client)
            && TF2_GetPlayerClass(client) == TFClass_DemoMan
            && (weapon = GetPlayerWeaponSlot(client, WEAPONSLOT_SECONDARY))
            && weapon != -1
            && (item_id = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
            && item_id != -1
            && item_id != 131   // The Chargin' Targe
            && item_id != 406   // The Splendid Screen
            && item_id != 1099  // The Tide Turner
            && item_id != 1144  // Festive Targe
       ) {
        SDKCall(g_call_secondary_attack, weapon);
    }
}

stock void RemoveBonusRoundTimeUpperBound() {
    SetConVarBounds(FindConVar("mp_bonusroundtime"), ConVarBound_Upper, false);
}
