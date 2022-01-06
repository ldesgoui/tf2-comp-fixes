static ConVar g_cvar;

static Handle g_detour_CTFFlameThrower_DeflectEntity;

void FixAirblastSelfDamage_Setup(Handle game_config)
{
	g_detour_CTFFlameThrower_DeflectEntity = CheckedDHookCreateFromConf(game_config, "CTFFlameThrower::DeflectEntity");
	
	g_cvar = CreateConVar("sm_fix_airblast_explosive_selfdamage", "0", _, FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	g_cvar.AddChangeHook(OnConVarChange);
}

static void OnConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }
    
    if (!DHookToggleDetour(g_detour_CTFFlameThrower_DeflectEntity, HOOK_POST,
                           Detour_CTFFlameThrower_DeflectEntity, cvar.BoolValue)) {
        SetFailState("Failed to toggle detour on CTFFlameThrower::DeflectEntity");
    }
}

static MRESReturn Detour_CTFFlameThrower_DeflectEntity(Handle hReturn, Handle hParams)
{
	int projectile = DHookGetParam(hParams, 1);
	if (!IsValidEntity(projectile)) {
		return MRES_Ignored;
	}
	
	char class[32];
	GetEdictClassname(projectile, class, sizeof(class));
	
	if(StrEqual(class, "tf_projectile_pipe", false)) {
		SetEntPropEnt(projectile, Prop_Send, "m_hLauncher", GetEntPropEnt(projectile, Prop_Send, "m_hOriginalLauncher"));
		return MRES_Handled;
	}
	
	if(StrEqual(class, "tf_projectile_sentryrocket", false)) {
		SetEntPropEnt(projectile, Prop_Send, "m_hOriginalLauncher", -1);
		return MRES_Handled;
	}
	return MRES_Ignored;
}