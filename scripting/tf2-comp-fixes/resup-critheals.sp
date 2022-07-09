static ConVar g_convar;

int lastDamageTimeOffs;
void ResupCritheals_Setup(Handle game_config) {
    g_convar = CreateBoolConVar("sm_resup_gives_critheals", WhenConVarChange);

    lastDamageTimeOffs = GameConfGetOffset(game_config, "CTFPlayer::m_flLastDamageTime");
}

static void WhenConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    int entity = -1;
    while ((entity = FindEntityByClassname(entity, "func_regenerate")) != -1) {
        if (cvar.BoolValue) {
            ResupCritheals_ReqFrame(entity);
        } else {
            SDKUnHook(entity, SDKHook_Touch, Hook_Resup_Touch);
        }
    }
}


public
void ResupCritheals_OnEntityCreated(int entity, const char[] classname)
{
    if (!g_convar.BoolValue) {
        return;
    }
    if (!StrEqual(classname, "func_regenerate")) {
        return;
    }

    // A lot of entities are invalid until the frame after they spawn
    RequestFrame(ResupCritheals_ReqFrame, entity);
}

void ResupCritheals_ReqFrame(int entity)
{
    if (entity < 1 || !IsValidEntity(entity)) {
        return;
    }
    SDKHook(entity, SDKHook_Touch, Hook_Resup_Touch);
}

Action Hook_Resup_Touch(int entity, int other)
{
    // not a valid client index
    if (other < 1 || other > MaxClients) {
        return Plugin_Continue;
    }

    SetEntDataFloat(other, lastDamageTimeOffs, 0.0);

    return Plugin_Continue;
}
