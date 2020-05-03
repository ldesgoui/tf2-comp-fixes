#if defined _TF2_COMP_FIXES_COMMON
#endinput
#endif
#define _TF2_COMP_FIXES_COMMON

#include <dhooks>
#include <sdktools>

#define HOOK_PRE  (false)
#define HOOK_POST (true)

#define INVALID_HOOK_ID (-1)

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

    CallConVarUpdateHook(cvar, callback);

    return cvar;
}

stock void CallConVarUpdateHook(ConVar cvar, ConVarChanged callback) {
    char current[128], def[128];
    cvar.GetString(current, sizeof(current));
    cvar.GetDefault(def, sizeof(def));

    Call_StartFunction(INVALID_HANDLE, callback);
    Call_PushCell(cvar);
    Call_PushString(def);
    Call_PushString(current);
    Call_Finish();
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

stock bool TruthyConVar(const char[] val) { return StringToFloat(val) >= 1.0; }
