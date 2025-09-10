# Copilot Instructions for KnockbackRestrict Discord Plugin

## Project Overview
This repository contains a SourceMod plugin that serves as a bridge between the KnockbackRestrict plugin and Discord notifications. The plugin sends formatted Discord webhook messages when players are banned or unbanned using the knockback restriction system in Source engine games.

**Key Characteristics:**
- **Type**: SourceMod extension/bridge plugin (not standalone)
- **Purpose**: Discord notifications for KnockbackRestrict ban/unban events
- **Language**: SourcePawn
- **Dependencies**: Multiple external plugins and APIs
- **Architecture**: Event-driven with webhook callbacks

## Dependencies & Build System

### Primary Dependencies
- **KnockbackRestrict**: Core plugin that this extends (provides events)
- **DiscordWebhookAPI**: Required for Discord webhook functionality
- **ExtendedDiscord**: Optional plugin for enhanced Discord features
- **SourceMod**: Version 1.11.0-git6934 or newer

### Build System: SourceKnight
This project uses **SourceKnight v0.2** for dependency management and building, NOT the standard SourceMod compiler directly.

**Build Configuration:** `sourceknight.yaml`
- Automatically downloads and manages dependencies
- Handles include path resolution
- Compiles to `/addons/sourcemod/plugins`
- Target: `KnockbackRestrict_Discord`

**Build Commands:**
```bash
# Standard build (requires SourceKnight)
sourceknight build

# Local development setup
sourceknight deps  # Download dependencies first
```

### CI/CD Pipeline
- **GitHub Actions**: Automated building, testing, and releases
- **Artifacts**: Built plugins packaged as tar.gz
- **Releases**: Automatic tagging and release creation
- **Runner**: Ubuntu 24.04 with SourceKnight action

## Code Architecture & Patterns

### File Structure
```
addons/sourcemod/scripting/
└── KnockbackRestrict_Discord.sp    # Main plugin file
```

### Key Components

#### 1. Plugin Entry Points
- `OnPluginStart()`: ConVar initialization and configuration
- `OnAllPluginsLoaded()`: Dependency detection
- `OnLibraryAdded/Removed()`: Dynamic dependency management

#### 2. Event Handlers
- `KR_OnClientKbanned()`: Handles ban events from KnockbackRestrict
- `KR_OnClientKunbanned()`: Handles unban events from KnockbackRestrict

#### 3. Discord Integration
- `SendKbDiscordMessage()`: Core message formatting and sending
- `OnWebHookExecuted()`: Webhook response handling with retry logic
- Thread and channel support for Discord

#### 4. Configuration (ConVars)
- `kban_discord_enable`: Toggle system on/off
- `kban_discord_webhook`: Discord webhook URL (protected)
- `kban_discord_webhook_retry`: Retry attempts for failed webhooks
- `kban_discord_channel_type`: Thread vs text channel support
- `kban_discord_threadname/threadid`: Thread configuration
- `kban_website`: Website URL for ban history links

### Code Conventions Used
- **Pragma directives**: `#pragma semicolon 1` and `#pragma newdecls required`
- **Variable naming**: 
  - Global variables prefixed with `g_`
  - ConVars use `g_cv` prefix
  - CamelCase for functions, camelCase for locals
- **Constants**: ALL_CAPS with underscores
- **Memory management**: Proper `delete` usage without null checks
- **Error handling**: Comprehensive logging and retry mechanisms

## Discord Integration Specifics

### Webhook Features
- **Embed formatting**: Rich Discord embeds with colors, thumbnails, fields
- **Player information**: Steam profile links, avatar integration
- **Admin tracking**: Full admin information in notifications
- **History links**: Integration with web-based ban history
- **Thread support**: Can send to Discord forum threads or text channels
- **Retry mechanism**: Configurable retry logic for failed webhooks

### Message Structure
- **Colors**: Yellow for bans, blue for unbans
- **Fields**: Admin, Player, Reason, Duration, History
- **Thumbnails**: Player avatars via ExtendedDiscord integration
- **Timestamps**: Discord timestamp formatting
- **Links**: Clickable Steam profile and ban history links

## Development Guidelines

### When Making Changes

#### 1. Dependency-Related Changes
- Understand that this plugin REQUIRES other plugins to function
- KnockbackRestrict events are the primary trigger
- ExtendedDiscord integration is optional but provides enhancements
- Any changes to includes require dependency updates in `sourceknight.yaml`

#### 2. Discord Formatting Changes
- Test webhook formatting thoroughly
- Consider both thread and text channel modes
- Validate embed field limits and character constraints
- Test retry logic for failed webhook calls

#### 3. Configuration Changes
- New ConVars should follow existing naming conventions
- Use `FCVAR_PROTECTED` for sensitive information (URLs, tokens)
- Add proper validation and default values
- Update `AutoExecConfig(true)` call if needed

#### 4. Event Handling Changes
- Ensure proper client validation before processing
- Handle edge cases (disconnected players, invalid targets)
- Maintain backward compatibility with KnockbackRestrict API
- Test with both temporary and permanent bans

### Testing Approach

#### 1. Build Testing
```bash
# Verify dependencies resolve
sourceknight deps

# Test compilation
sourceknight build

# Check for warnings/errors
```

#### 2. Runtime Testing Requirements
- **Test Server**: Source engine game server with SourceMod
- **Required Plugins**: KnockbackRestrict must be installed and functional
- **Discord Setup**: Valid Discord webhook URL for testing
- **Test Scenarios**:
  - Temporary bans with various durations
  - Permanent bans
  - Unbans by different admins
  - Invalid/disconnected target players
  - Webhook failures and retry logic

#### 3. Integration Testing
- Verify Discord message formatting
- Test Steam profile link generation
- Validate ban history links (if website configured)
- Check thread vs channel posting
- Test ExtendedDiscord avatar integration (if available)

### Common Modification Patterns

#### Adding New Discord Fields
```sourcepawn
EmbedField newField = new EmbedField("Field Name:", "Field Value", false);
Embed1.AddField(newField);
```

#### Adding New ConVars
```sourcepawn
g_cvNewSetting = CreateConVar("kban_discord_newsetting", "default", "Description", FCVAR_PROTECTED);
```

#### Handling New KnockbackRestrict Events
```sourcepawn
public void KR_OnNewEvent(int client, /* other params */)
{
    if(!g_cvEnable.BoolValue)
        return;
    
    // Process event
}
```

### Performance Considerations
- **Webhook calls**: All Discord API calls are asynchronous
- **Memory management**: Proper cleanup of Embed, Webhook, and DataPack objects
- **String operations**: Minimize expensive string formatting in frequently called functions
- **Client validation**: Always validate client indices and connection status
- **Timer usage**: Avoid unnecessary timers; use event-driven approach

### Security Considerations
- **Webhook URLs**: Always use `FCVAR_PROTECTED` for sensitive configuration
- **SQL injection**: Not applicable (no direct database interaction)
- **Input validation**: Validate client data before Discord formatting
- **Rate limiting**: Discord webhooks have rate limits; retry mechanism handles this

## Troubleshooting Common Issues

### Build Issues
- **Missing includes**: Check `sourceknight.yaml` dependencies
- **SourceKnight not found**: Ensure build environment has SourceKnight installed
- **Version conflicts**: Verify SourceMod version compatibility

### Runtime Issues
- **No Discord messages**: Check webhook URL and permissions
- **Missing player info**: Verify client validity and connection status
- **Thread posting fails**: Validate thread ID and permissions
- **Avatar not showing**: Check ExtendedDiscord plugin availability

### Integration Issues
- **KnockbackRestrict events not firing**: Ensure plugin load order
- **Steam profile links broken**: Validate SteamID format conversion
- **Ban history links incorrect**: Check website URL configuration

## Key Files to Understand
- `KnockbackRestrict_Discord.sp`: Main plugin logic
- `sourceknight.yaml`: Build configuration and dependencies
- `.github/workflows/ci.yml`: CI/CD pipeline
- `.gitignore`: Build artifact exclusions

This plugin is specifically designed as an integration component, not a standalone feature. Always consider the broader ecosystem when making changes.