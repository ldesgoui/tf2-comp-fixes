static ConVar g_convar;

void ResupCritheals_Setup() {
    g_convar = CreateBoolConVar("sm_resup_gives_critheals", WhenConVarChange);
}

static void WhenConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }   

    int entity = -1;
    while ((entity = FindEntityByClassname(entity, "func_regenerate")) != -1) {      
        if (cvar.BoolValue) {
            SDKHook(entity, SDKHook_EndTouchPost, Hook_Resup_EndTouchPost);
        } else {
            SDKUnhook(entity, SDKHook_EndTouchPost, Hook_Resup_EndTouchPost);
        }   
    }
}


public
void ResupCritheals_OnEntityCreated(int entity, const char[] classname)
{
    if (!g_convar.BoolValue)
    {
        return;
    }
    if (!StrEqual(classname, "func_regenerate"))
    {
        return;
    }
    if (entity < 1 || !IsValidEntity(entity))
    {
        return;
    }
    SDKHook(entity, SDKHook_EndTouchPost, Hook_Resup_EndTouchPost);
}

void Hook_Resup_EndTouchPost(int entity, int other)
{
    if (other < 1 || other > MaxClients)
    {
        return;
    }
    PrintToServer("%i touched resup %i", other, entity);
    SetEntPropFloat(other, Prop_Send, "m_flLastDamageTime", 0.0);
}
