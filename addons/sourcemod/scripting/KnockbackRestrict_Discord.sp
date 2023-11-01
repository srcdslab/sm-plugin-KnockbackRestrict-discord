#pragma semicolon 1
#pragma newdecls required

#include <KnockbackRestrict>
#include <discordWebhookAPI>

#undef REQUIRE_PLUGIN
#tryinclude <ExtendedDiscord>
#define REQUIRE_PLUGIN

#define PLUGIN_NAME "KnockbackRestrict_Discord"
#define WEBHOOK_URL_MAX_SIZE			1000
#define WEBHOOK_THREAD_NAME_MAX_SIZE	100

#define KBAN 	1
#define KUNBAN 	2

ConVar g_cvEnable, g_cvWebhook, g_cvWebhookRetry, g_cvAvatar, g_cvUsername;
ConVar g_cvRedirectURL = null, g_cvWebSite = null;
ConVar g_cvChannelType, g_cvThreadName, g_cvThreadID;

bool g_Plugin_ExtDiscord = false;

public Plugin myinfo =
{
	name 		= PLUGIN_NAME,
	author 		= ".Rushaway, Dolly, koen",
	version 	= "1.2",
	description = "Send KbRestrict Ban/Unban notifications to discord",
	url 		= "https://github.com/srcdslab/sm-plugin-KnockbackRestrict-discord"
};

public void OnPluginStart()
{
	/* General config */
	g_cvEnable 	= CreateConVar("kban_discord_enable", "1", "Toggle Kban notification system", _, true, 0.0, true, 1.0);
	g_cvWebhook = CreateConVar("kban_discord_webhook", "", "The webhook URL of your Discord channel.", FCVAR_PROTECTED);
	g_cvWebhookRetry = CreateConVar("kban_discord_webhook_retry", "3", "Number of retries if webhook fails.", FCVAR_PROTECTED);
	g_cvUsername = CreateConVar("kban_discord_discord_username", "Knockback Restrict Discord", "Discord username.");
	g_cvWebSite	= CreateConVar("kban_website", "", "The Kbans Website for your server (that sends the user to bans list page)", FCVAR_PROTECTED);

	g_cvRedirectURL = CreateConVar("kban_discord_redirect", "https://nide.gg/connect/", "URL to your redirect.php file.");
	g_cvChannelType = CreateConVar("kban_discord_channel_type", "0", "Type of your channel: (1 = Thread, 0 = Classic Text channel");

	/* Thread config */
	g_cvThreadName = CreateConVar("kban_discord_threadname", "KnockBackRestrict - Logs", "The Thread Name of your Discord forums. (If not empty, will create a new thread)", FCVAR_PROTECTED);
	g_cvThreadID = CreateConVar("kban_discord_threadid", "0", "If thread_id is provided, the message will send in that thread.", FCVAR_PROTECTED);
	
	AutoExecConfig(true);
}

public void OnAllPluginsLoaded()
{
	g_Plugin_ExtDiscord = LibraryExists("ExtendedDiscord");
}

public void OnLibraryAdded(const char[] sName)
{
	if (strcmp(sName, "ExtendedDiscord", false) == 0)
		g_Plugin_ExtDiscord = true;
}

public void OnLibraryRemoved(const char[] sName)
{
	if (strcmp(sName, "ExtendedDiscord", false) == 0)
		g_Plugin_ExtDiscord = false;
}

public void KR_OnClientKbanned(int target, int admin, int length, const char[] reason, int kbansNumber)
{
	if(!g_cvEnable.BoolValue)
		return;
	
	if(admin < 1)
		return;

	SendKbDiscordMessage(KBAN, admin, target, length, reason, kbansNumber, _);
}

public void KR_OnClientKunbanned(int target, int admin, const char[] reason, int kbansNumber)
{
    if(!g_cvEnable.BoolValue)
    	return;
    
    if(admin < 1)
		return;

    SendKbDiscordMessage(KUNBAN, admin, target, -1, reason, kbansNumber, _);
}

stock void SendKbDiscordMessage(int type, int admin, int target, int length, const char[] reason, int bansNumber, const char[] targetName = "")
{
	bool IsThread = g_cvChannelType.BoolValue;
	char steamID[MAX_AUTHID_LENGTH], steamID64[MAX_AUTHID_LENGTH], sThreadID[32], avatar[PLATFORM_MAX_PATH]; 
	char sThreadName[WEBHOOK_THREAD_NAME_MAX_SIZE], sWebhookURL[WEBHOOK_URL_MAX_SIZE], webredirectURL[PLATFORM_MAX_PATH];

	g_cvThreadID.GetString(sThreadID, sizeof sThreadID);
	g_cvThreadName.GetString(sThreadName, sizeof sThreadName);

	g_cvWebhook.GetString(sWebhookURL, sizeof(sWebhookURL));
	if (sWebhookURL[0] == '\0') {
        LogError("[%s] Invalid or no webhook specified.", PLUGIN_NAME);
        return;
    }

	g_cvRedirectURL.GetString(webredirectURL, sizeof(webredirectURL));
	if(!webredirectURL[0]) {
	    LogError("[%s] Invalid or no redirect URL specified in plugin config.", PLUGIN_NAME);
	    return;
	}
	
	// Admin Information
	if(!GetClientAuthId(admin, AuthId_Steam2, steamID, sizeof(steamID)))
		return;
	
	if(!GetClientAuthId(admin, AuthId_SteamID64, steamID64, sizeof(steamID64)))
		return;
	
	bool invalidTarget = false;
	if(target > MaxClients || target < 1 || !IsClientInGame(target))
		invalidTarget = true;

	char targetName2[32];
	if(!invalidTarget && !GetClientName(target, targetName2, sizeof(targetName2)))
		return;

	ExtendedDiscord_GetAvatarLink(target, avatar, sizeof(avatar));

	/* Webhook UserName */
	char sName[128];
	g_cvUsername.GetString(sName, sizeof(sName));

	/* Webhook Avatar */
	char sAvatar[256];
	g_cvAvatar.GetString(sAvatar, sizeof(sAvatar));
	
	char title[32];
	GetTypeTitle(type, title, sizeof(title));
	
	char embedHeader[68 + MAX_AUTHID_LENGTH];
	FormatEx(embedHeader, sizeof(embedHeader), "%s for `%s`", title, (invalidTarget) ? targetName : targetName2);
	
	int color;
	if (type == KBAN) color = 0xffff00;
	if (type == KUNBAN) color = 0x0000ff;
	
	Embed Embed1 = new Embed(embedHeader);
	Embed1.SetColor(color);
	Embed1.SetTitle(embedHeader);
	Embed1.SetTimeStampNow();
	
	EmbedThumbnail Thumbnail = new EmbedThumbnail();
	Thumbnail.SetURL(avatar);
	Embed1.SetThumbnail(Thumbnail);
	delete Thumbnail;
	
	char adminInfo[PLATFORM_MAX_PATH * 2];
	Format(adminInfo, sizeof(adminInfo), "`%N` ([%s](https://steamcommunity.com/profiles/%s))", admin, steamID, steamID64);
	EmbedField field1 = new EmbedField("Admin:", adminInfo, false);
	Embed1.AddField(field1);
	
	// Player Information
	if(!GetClientAuthId(target, AuthId_Steam2, steamID, sizeof(steamID), false)) {
		strcopy(steamID, sizeof(steamID), "No SteamID");
	}
	
	if(!GetClientAuthId(target, AuthId_SteamID64, steamID64, sizeof(steamID64))) {
		strcopy(steamID64, sizeof(steamID64), "No SteamID");
	}
	
	char playerInfo[PLATFORM_MAX_PATH * 2];
	if(StrContains(steamID, "STEAM_") != -1) {
		Format(playerInfo, sizeof(playerInfo), "`%N` ([%s](https://steamcommunity.com/profiles/%s))", target, steamID, steamID64);
	} else {
		Format(playerInfo, sizeof(playerInfo), "`%N` (No SteamID)", target);
	}
	
	EmbedField field2 = new EmbedField("Player:", playerInfo, false);
	Embed1.AddField(field2);
	
	// Reason
	EmbedField field3 = new EmbedField("Reason:", reason, false);
	Embed1.AddField(field3);
	
	/* Duration */
	char timeBuffer[128];
	switch (length) {
		case -1: {
			FormatEx(timeBuffer, sizeof(timeBuffer), "Temporary");
		}
		case 0: {
			FormatEx(timeBuffer, sizeof(timeBuffer), "Permanent");
		}
		default: {
			int ctime = GetTime();
			int finaltime = ctime + (length * 60);
			FormatEx(timeBuffer, sizeof(timeBuffer), "%d Minute%s \n(to <t:%d:f>)", length, length > 1 ? "s" : "", finaltime);
		}
	}
	
	EmbedField fieldDuration = new EmbedField("Duration:", timeBuffer, true);
	Embed1.AddField(fieldDuration);
	
	/* History Field */
	if(StrContains(steamID, "STEAM_") != -1) {
		char history[PLATFORM_MAX_PATH * 4];
		FormatTypeHistory(steamID, bansNumber, history, sizeof(history));
		
		EmbedField field5 = new EmbedField("History:", history, false);
		Embed1.AddField(field5);
	}
	
	Webhook webhook = new Webhook("");

	if (strlen(sName) > 0)
		webhook.SetUsername(sName);
	if (strlen(sAvatar) > 0)
		webhook.SetAvatarURL(sAvatar);
	
	webhook.AddEmbed(Embed1);

	DataPack pack = new DataPack();

	if (IsThread && strlen(sThreadName) <= 0 && strlen(sThreadID) > 0)
		pack.WriteCell(1);
	else
		pack.WriteCell(0);

	pack.WriteCell(type);
	pack.WriteCell(admin);
	pack.WriteCell(target);
	pack.WriteCell(length);
	pack.WriteString(reason);
	pack.WriteCell(bansNumber);
	pack.WriteString(targetName);
	pack.WriteString(avatar);
	pack.WriteString(sWebhookURL);

	webhook.Execute(sWebhookURL, OnWebHookExecuted, pack, sThreadID);
	delete webhook;
}


public void OnWebHookExecuted(HTTPResponse response, DataPack pack)
{
	char reason[256], targetName[MAX_NAME_LENGTH], avatar[PLATFORM_MAX_PATH], sWebhookURL[WEBHOOK_URL_MAX_SIZE];
	static int retries = 0;
	pack.Reset();

	bool IsThreadReply = pack.ReadCell();
	int type = pack.ReadCell();
	int adminID = pack.ReadCell();
	int admin = GetClientOfUserId(adminID);
	int targetID = pack.ReadCell();
	int target = GetClientOfUserId(targetID);
	int lenght = pack.ReadCell();
	pack.ReadString(reason, sizeof(reason));
	int bansNumber = pack.ReadCell();
	pack.ReadString(targetName, sizeof(targetName));
	pack.ReadString(avatar, sizeof(avatar));
	pack.ReadString(sWebhookURL, sizeof(sWebhookURL));

	delete pack;
	
	if ((!IsThreadReply && response.Status != HTTPStatus_OK) || (IsThreadReply && response.Status != HTTPStatus_NoContent))
	{
		if (retries < g_cvWebhookRetry.IntValue) {
			PrintToServer("[%s] Failed to send the webhook. Resending it .. (%d/%d)", PLUGIN_NAME, retries, g_cvWebhookRetry.IntValue);
			SendKbDiscordMessage(type, admin, target, lenght, reason, bansNumber, targetName);
			retries++;
			return;
		} else {
			if (!g_Plugin_ExtDiscord)
				LogError("[%s] Failed to send the webhook after %d retries, aborting.", PLUGIN_NAME, retries);
		#if defined _extendeddiscord_included
			else
				ExtendedDiscord_LogError("[%s] Failed to send the webhook after %d retries, aborting.", PLUGIN_NAME, retries);
		#endif
		}
	}

	retries = 0;
}

stock void GetTypeTitle(int type, char[] title, int maxlen) {
	switch(type) {
		case KBAN: {
			strcopy(title, maxlen, "Kban");
		}
		case KUNBAN: {
			strcopy(title, maxlen, "Kunban");
		}
		default: {
			strcopy(title, maxlen, "N/A (Error)");
		}
	}
	
	FormatEx(title, maxlen, "%s Notification", title);
}

stock void FormatTypeHistory(const char[] steamID, int bansNumber, char[] history, int maxlen) {
	char webURL[WEBHOOK_URL_MAX_SIZE];
	g_cvWebSite.GetString(webURL, sizeof(webURL));
	
	// View History link
	FormatEx(webURL, sizeof(webURL), "%s?all=true&s=%s&m=1", webURL, steamID);
	FormatEx(history, maxlen, "%d Kbans ([View History](%s))", bansNumber, webURL);
}
