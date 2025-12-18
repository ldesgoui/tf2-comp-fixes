
#define ORDER_LEN 6
static const TFClassType ORDER[ORDER_LEN] = {
    TFClass_DemoMan,
    TFClass_Medic,
    TFClass_Soldier,
    TFClass_Soldier,
    TFClass_Scout,
    TFClass_Scout,
};

void ClassOrderedSpawnpoints_Setup() {
    CreateBoolConVar("sm_class_ordered_spawnpoints", WhenConVarChange);
}

static void WhenConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (cvar.BoolValue) {
        PresetBase();
    } else {
        UnsetAll();
    }
}

static void UnsetAll() {
    int entity;

    while ((entity = FindEntityByClassname(entity, "info_player_teamspawn")) != -1) {
        SetEntProp(entity, Prop_Data, "m_spawnflags", 0x1ff); // 9 bits all high
    }
}

static void PresetBase() {
    char red_last[64] = "";
    char blu_last[64] = "";

    int entity;
    int red = 0;
    int blu = 0;

    while ((entity = FindEntityByClassname(entity, "info_player_teamspawn")) != -1) {
        int team = GetEntProp(entity, Prop_Send, "m_iTeamNum");

        if (team != 2 && team != 3) continue;

        LogDebug("Found a RED/BLU spawn point: %d", entity);

        char control_point_name[64];
        int wrote = GetEntPropString(entity, Prop_Send, "m_iszControlPointName", control_point_name, sizeof(control_point_name));

        if (wrote == 0) {
            LogDebug("- It's not attached to a control point");
            // This is most likely KOTH, in which we process all team spawnpoints
        } else if (team == 2 && StrEqual(control_point_name, red_last)) {
            LogDebug("- It's attached to known RED last");
        } else if (team == 3 && StrEqual(control_point_name, blu_last)) {
            LogDebug("- It's attached to known BLU last");
        } else {
            int control_point = FindControlPointByName(control_point_name);
            if (control_point == -1) {
                LogDebug("- Couldn't find which control point it's attached to!!!");
                continue;
            }

            int index = GetEntProp(control_point, Prop_Send, "m_iPointIndex");

            if (index == 4) {
                red_last = control_point_name;
                LogDebug("- It's attached to the RED last, by the way iTeamNum is %d", team);
            } else if (index == 0) {
                blu_last = control_point_name;
                LogDebug("- It's attached to the BLU last, by the way iTeamNum is %d", team);
            } else {
                LogDebug("- It's attached to a control point we don't care about: %d", index);
                continue;
            }
        }

        TFClassType cls;
        if (team == 2) {
            cls = red < ORDER_LEN ? ORDER[red] : TFClass_Unknown;
            red += 1;
        } else if (team == 3) {
            cls = blu < ORDER_LEN ? ORDER[blu] : TFClass_Unknown;
            blu += 1;
        }

        LogDebug("- Limiting it to this class type only: %d", cls);
        SetSpawnClass(entity, cls);
    }
}

static int FindControlPointByName(const char[] target) {
    int entity;
    char name[64];

    while ((entity = FindEntityByClassname(entity, "team_control_point")) != -1) {
        if (!GetEntPropString(entity, Prop_Send, "m_iName", name, sizeof(name))) {
            continue;
        }

        if (StrEqual(name, target)) {
            return entity;
        }
    }

    return -1;
}

static void SetSpawnClass(int entity, TFClassType cls) {
    int flags;

    if (cls == TFClass_Unknown) {
        flags = 0; // allow nothing
    } else {
        flags = 1 << view_as<int>(cls) - 1;
    }

    SetEntProp(entity, Prop_Data, "m_spawnflags", flags);
}
