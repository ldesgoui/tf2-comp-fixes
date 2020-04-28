#pragma semicolon 1
#pragma newdecls required

#if !defined TF2_COMP_FIXES__UTILS
#define TF2_COMP_FIXES__UTILS

#if defined DEBUG
#define DEFAULT_BOOL_CONVAR_VALUE "1"
#else
#define DEFAULT_BOOL_CONVAR_VALUE "0"
#endif

ConVar CreateBoolConVar(const char[] name, const char[] description = "") {
    return CreateConVar(
            name,
            DEFAULT_BOOL_CONVAR_VALUE,
            description,
            FCVAR_NOTIFY,
            true, 0.0,
            true, 1.0);
}

#endif
