#pragma semicolon 1

#include <sourcemod>

#define L4D_TEAM_SPECTATE 1
#define SERVER_INDEX 0

static bool: g_SpecsGagged = false;
static bool: g_GaggingInProgress = false;
static bool: g_UngaggingInProgress = false;

public Plugin:myinfo =
{
	name = "L4D Spectator Gag",
	author = "Griffin",
	description = "Force spectators to MM2.",
	version = "0.1"
};

public OnPluginStart()
{
	AddCommandListener(Command_Say, "say");

	RegAdminCmd("sm_gagspecs", CommandGagSpecs, ADMFLAG_GENERIC, "sm_gagspecs - force spectators to mm2");
	RegAdminCmd("sm_ungagspecs", CommandUngagSpecs, ADMFLAG_GENERIC, "sm_ungagspecs - ungag spectators");
}

public Action:Command_Say(client, const String:command[], args)
{
	if (args < 1) return Plugin_Continue;

	new flags = GetUserFlagBits(client);
	if (flags & ADMFLAG_GENERIC) return Plugin_Continue;

	if (g_SpecsGagged && GetClientTeam(client) == L4D_TEAM_SPECTATE)
	{
		decl String:msg[256];
		GetCmdArgString(msg, sizeof(msg));
		FakeClientCommandEx(client, "say_team %s", msg);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:CommandGagSpecs(client, args)
{
	if (!g_GaggingInProgress)
	{
		g_GaggingInProgress = true;
		CreateTimer(0.1, Timer_Gag, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

public Action:CommandUngagSpecs(client, args)
{
	if (!g_UngaggingInProgress)
	{
		g_UngaggingInProgress = true;
		CreateTimer(0.1, Timer_Ungag, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

public Action:Timer_Gag(Handle:Timer, any:client)
{
	if (!g_SpecsGagged)
	{
		g_SpecsGagged = true;
		PrintToChatAll("[SM] Spectators have been gagged.");
	}
	else
	{
		PrintToChat(client, "[SM] Spectators are already gagged. Use !ungagspecs to ungag spectators.");
	}
	g_GaggingInProgress = false;
}

public Action:Timer_Ungag(Handle:Timer, any:client)
{
	if (g_SpecsGagged)
	{
		g_SpecsGagged = false;
		PrintToChatAll("[SM] Spectators have been ungagged.");
	}
	else
	{
		PrintToChat(client, "[SM] Spectators are already ungagged. Use !gagspecs to gag spectators.");
	}
	g_UngaggingInProgress = false;
}
