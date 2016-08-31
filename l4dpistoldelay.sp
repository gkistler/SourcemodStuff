/**
 * =============================================================================
 * L4D Pistol Delayer
 * Enforces a configurable NextAttack delay for pistols, for use on >30tick servers
 *
 * - Griffin
 * =============================================================================
 */

#include <sourcemod>
#include <sdktools>
#include include/sdkhooks.inc

public Plugin:myinfo =
{
	name = "L4D Pistol Delayer",
	author = "Griffin",
	description = "Slow down, pistols!",
	version = "0.2"
};

new Float:g_fNextAttack[MAXPLAYERS + 1];
// Defaults approximated from 30tick testing
new Float:g_fPistolDelayDualies = 0.1;
new Float:g_fPistolDelaySingle = 0.2;
new Float:g_fPistolDelayIncapped = 0.3;
new Handle:g_hPistolDelayDualies = INVALID_HANDLE;
new Handle:g_hPistolDelaySingle = INVALID_HANDLE;
new Handle:g_hPistolDelayIncapped = INVALID_HANDLE;

public OnPluginStart()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client)) continue;
		SDKHook(client, SDKHook_PostThinkPost, Hook_OnPostThinkPost);
	}
	g_hPistolDelayDualies = CreateConVar("l4d_pistol_delay_dualies", "0.1", "Minimum time (in seconds) between dual pistol shots",
		FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY, true, 0.0, true, 5.0);
	g_hPistolDelaySingle = CreateConVar("l4d_pistol_delay_single", "0.2", "Minimum time (in seconds) between single pistol shots",
		FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY, true, 0.0, true, 5.0);
	g_hPistolDelayIncapped = CreateConVar("l4d_pistol_delay_incapped", "0.3", "Minimum time (in seconds) between pistol shots while incapped",
		FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY, true, 0.0, true, 5.0);

	UpdatePistolDelays();

	HookConVarChange(g_hPistolDelayDualies, Cvar_PistolDelay);
	HookConVarChange(g_hPistolDelaySingle, Cvar_PistolDelay);
	HookConVarChange(g_hPistolDelayIncapped, Cvar_PistolDelay);
	HookEvent("weapon_fire", Event_WeaponFire);
}

public OnMapStart()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		g_fNextAttack[client] = 0.0;
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PreThink, Hook_OnPostThinkPost);
	g_fNextAttack[client] = 0.0;
}

public Cvar_PistolDelay(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UpdatePistolDelays()
}

UpdatePistolDelays()
{
	g_fPistolDelayDualies = GetConVarFloat(g_hPistolDelayDualies);
	if (g_fPistolDelayDualies < 0.0) g_fPistolDelayDualies = 0.0;
	else if (g_fPistolDelayDualies > 5.0) g_fPistolDelayDualies = 5.0;

	g_fPistolDelaySingle = GetConVarFloat(g_hPistolDelaySingle);
	if (g_fPistolDelaySingle < 0.0) g_fPistolDelaySingle = 0.0;
	else if (g_fPistolDelaySingle > 5.0) g_fPistolDelaySingle = 5.0;

	g_fPistolDelayIncapped = GetConVarFloat(g_hPistolDelayIncapped);
	if (g_fPistolDelayIncapped < 0.0) g_fPistolDelayIncapped = 0.0;
	else if (g_fPistolDelayIncapped > 5.0) g_fPistolDelayIncapped = 5.0;
}

public Hook_OnPostThinkPost(client)
{
	// Human survivors only
	if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != 2) return;
	new activeweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEdict(activeweapon)) return;
	decl String:weaponname[64];
	GetEdictClassname(activeweapon, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "weapon_pistol") != 0) return;
	
	new Float:old_value = GetEntPropFloat(activeweapon, Prop_Send, "m_flNextPrimaryAttack");
	new Float:new_value = g_fNextAttack[client];

	// Never accidentally speed up fire rate
	if (new_value > old_value)
	{
		SetEntPropFloat(activeweapon, Prop_Send, "m_flNextPrimaryAttack", new_value);
	}
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != 2) return;
	new activeweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEdict(activeweapon)) return;
	decl String:weaponname[64];
	GetEdictClassname(activeweapon, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "weapon_pistol") != 0) return;
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated"))
	{
		g_fNextAttack[client] = GetGameTime() + g_fPistolDelayIncapped;
	}
	// m_isDualWielding vs m_hasDualWeapons?
	else if (GetEntProp(activeweapon, Prop_Send, "m_isDualWielding"))
	{
		g_fNextAttack[client] = GetGameTime() + g_fPistolDelayDualies;
	}
	else
	{
		g_fNextAttack[client] = GetGameTime() + g_fPistolDelaySingle;
	}
}
