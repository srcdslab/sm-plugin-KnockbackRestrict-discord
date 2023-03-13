#pragma semicolon 1

#include <KnockbackRestrict>

#define PLUGIN_NAME "KnockbackRestrict_Discord"
#define STEAM_API_CVAR "kban_steam_api"

#include <RelayHelper>

#tryinclude <sourcebanschecker>
#tryinclude <sourcecomms>

#pragma newdecls required

Global_Stuffs g_Kban;

public Plugin myinfo =
{
	name 		= PLUGIN_NAME,
	author 		= ".Rushaway, Dolly, koen",
	version 	= "1.0",
	description = "Send KbRestrict Ban/Unban notifications to discord",
	url 		= "https://nide.gg"
};

public void OnPluginStart() {
	g_Kban.enable 	= CreateConVar("kban_discord_enable", "1", "Toggle kban notification system", _, true, 0.0, true, 1.0);
	g_Kban.webhook 	= CreateConVar("kban_discord", "", "The webhook URL of your Discord channel. (Kban)", FCVAR_PROTECTED);
	g_Kban.website	= CreateConVar("kban_website", "", "The Kbans Website for your server (that sends the user to bans list page)", FCVAR_PROTECTED);
	
	RelayHelper_PluginStart();
	
	AutoExecConfig(true, PLUGIN_NAME);
	
	/* Incase of a late load */
	for(int i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || IsFakeClient(i) || IsClientSourceTV(i) || g_sClientAvatar[i][0]) {
			return;
		}
		
		OnClientPostAdminCheck(i);
	}
}

public void OnClientPostAdminCheck(int client) {
	if(IsFakeClient(client) || IsClientSourceTV(client)) {
		return;
	}
	
	GetClientSteamAvatar(client);
}

public void OnClientDisconnect(int client) {
	g_sClientAvatar[client][0] = '\0';
}

public void KR_OnClientKbanned(int target, int admin, int length, const char[] reason, int kbansNumber)
{
	if(!g_Kban.enable.BoolValue) {
		return;
	}
	
	if(admin < 1) {
		return;
	}
	
	SendDiscordMessage(g_Kban, Message_Type_Kban, admin, target, length, reason, kbansNumber, 0, _, g_sClientAvatar[target]);
}

public void KR_OnClientKunbanned(int target, int admin, const char[] reason, int kbansNumber)
{
    if(!g_Kban.enable.BoolValue) {
    	return;
    }
    
    if(admin < 1) {
		return;
	}
	
    SendDiscordMessage(g_Kban, Message_Type_Kunban, admin, target, -1, reason, kbansNumber, 0, _, g_sClientAvatar[target]);  
}