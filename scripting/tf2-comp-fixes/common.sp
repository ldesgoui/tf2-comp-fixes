#if defined _TF2_COMP_FIXES_COMMON
#endinput
#endif
#define _TF2_COMP_FIXES_COMMON

#include <dhooks>
#include <sdktools>

#define HOOK_PRE  (false)
#define HOOK_POST (true)

#define INVALID_HOOK_ID (-1)

#define MAXENTITIES (2048)

enum OperatingSystem {
    Linux,
    Mac,
    Windows,
    Unknown,
};

stock OperatingSystem GetOs(Handle game_config) {
    char buf[32];

    if (!GameConfGetKeyValue(game_config, "OS", buf, sizeof(buf))) {
        return Unknown;
    }

    if (StrEqual(buf, "linux")) {
        return Linux;
    } else if (StrEqual(buf, "mac")) {
        return Mac;
    } else if (StrEqual(buf, "windows")) {
        return Windows;
    } else {
        return Unknown;
    }
}

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

stock int GetEntityFromAddress(Address entity_ptr) {
    int offset        = FindDataMapInfo(0, "m_angRotation") + 12;
    int entity_handle = LoadFromAddress(entity_ptr + view_as<Address>(offset), NumberType_Int32);

    return entity_handle & 0xFFF;
}

stock void ScaleVectorTo(const float vec[3], float scale, float result[3]) {
    result[0] = vec[0] * scale;
    result[1] = vec[1] * scale;
    result[2] = vec[2] * scale;
}

// https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/game/shared/gamemovement.cpp#L3145-L3180
stock void ClipVelocity(const float velocity[3], const float normal[3], float result[3]) {
    float backoff = GetVectorDotProduct(velocity, normal);
    float tmp[3];

    ScaleVectorTo(normal, backoff, tmp);
    SubtractVectors(velocity, tmp, result);

    backoff = GetVectorDotProduct(result, normal);
    if (backoff < 0.0) {
        ScaleVectorTo(normal, backoff, tmp);
        SubtractVectors(velocity, tmp, result);
    }
}
