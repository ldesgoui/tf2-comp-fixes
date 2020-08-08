static ConVar g_cvar;

void Debug_Setup() {
    g_cvar = CreateConVar("sm_cf_debug", "0", "Print debug statements in chat", FCVAR_REPLICATED,
                          true, 0.0, true, 1.0);
}

void LogDebug(const char[] format, any...) {
    char message[256];

    VFormat(message, sizeof(message), format, 2);

    if (g_cvar.BoolValue) {
        PrintToChatAll("[TF2 Competitive Fixes] Debug: %s", message);
    }

    LogMessage(message);
}
