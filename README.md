[![Build status](https://ci.appveyor.com/api/projects/status/lron8ntepgememdi?svg=true)](https://ci.appveyor.com/project/wilson0x4d/x4deso)

# X4D ESO Add-Ons

A collection of LibStub-compatible Add-Ons that provide minor enhancements to the game "Elder Scrolls Online".

## Compatibility with Others, and Infrequent Updates

I started development of these AddOns years ago when the game first released. I still enjoy using these AddOns when I play and don't really "shop" much for other AddOns, so, I've no idea if they are at all compatible with other AddOns.

I only update these AddOns when I am actively playing the game, which has been infrequent over the years. Bills need paying, life remains busy. I'd be happy to work with other developers to maintain these AddOns (will grant rights as necessary to commit and release new builds.) Would be nice to see enough contributors to keep these alive and listed on ESOUI, Curse, etc.

As it is I no longer publish to these sites because I'm not publishing regularly enough for it to matter. The overhead for these sites is too high.

I am working on a set of scripts to assist others with getting setup locally for development/debugging, and also for package & deployment of these AddOns.
 
## Dependencies

- LibStub *(Optional)*
- LibAddonMenu-2.0 *(Optional)*

## Modularity

One of the earliest goals of X4DESO was to provide modular add-ons, so users could install only what they wanted.

To that end, the following independent modules exist. When it makes sense they will auto-detect one another and interact accordingly.

- **X4D_Core** - A LibStub-compatible Framework for Developing Add-Ons for ESO, All X4D Add-Ons depend on this Framework.
- **X4D_Bank** - Performs regular bank deposits of items and gold based on user-configured options.
- **X4D_Chat** - Modifies Chat to show Character Names in Guild Chat, and adds timestamps to all chat messages, supports color stripping, text clean-up. All features optional.
- **X4D_LibAntiSpam** - An Anti-Spam Library that can be used to perform basic pattern/flood spam filtering.
- **X4D_Loot** - Displays looted Items in Chat Window, including Quest Items, Stack Counts, Item Icons and Monetary transactions.
- **X4D_Mail** - Provides minor Mail enhancements, namely integrating 'LibAntiSpam', performing auto-accepting mail attachments and auto-deleting system-generated mail.
- **X4D_Vendors** - Launder and Sell items at Merchants and Fences.
- **X4D_XP** - Shows XP Gains in the Chat Window.
- **X4D_UI** - Provides additional UI elements to the game, such as a Status Bar Window
- **X4D_MiniMap** - (BETA) Adds a 'minimap' to the game with Tracked Quest, POI and NPC pins.
- **X4D_Quest** - Integrates with in-game Quest Tracker and Quest APIs.

All of them are optional, except for X4D_Core, which all other X4D Add-ons depend on and it is thus required.

## Development

So you want to work on these AddOns, or, you want to run these AddOns directly from the github repository? This section is for you.

### `Create-AddOnSymLinks.ps1`

Creates symlinks for all X4D AddOns from the current repository to the default %USERPROFILE% location.

This is useful for developers that like to keep their projects in a standard location (most of us?)

Q: Pulled from github but not loading when restart ESO?
A: Run `Create-AddOnSymLinks.ps1` as Administrator.

### `Create-LibrarySymLinks.ps1`

Creates symlinks for all libraries used by AddOns.

Rather than have libraries/dependencies copied multiple times throughout the repository, a single copy of each dependency is maintained in /lib/ and this script is used to create symlinks from /lib/ into each AddOn folder.

Q: I ran `Create-AddOnSumLinks.ps1` but still no workie.
A: Also run `Create-LibrarySumLinks.ps1` as Administrator.

### Slash Commands

There are slash commands you will find useful when debugging AddOns or Testing changes to X4D AddOns.

| Command | |
|-|-|
| `/x4d` | Without arguments this slash-command will print a 'Version' and 'Load Time' summary for all X4D AddOns. |
| `/x4d dev` | Puts the AddOns into 'Developer Mode'; Sets the log level to VERBOSE (shows 'useful' logging/activity, but not 'all'), and then performs a broad test of X4D_Core module. If you're doing any development that uses X4D_Core you will usually use this command after performing a `/reloadui`. |
| `/x4d debug` | Puts the AddOns into 'Debugger Mode'; Sets the log level to DEBUG (shows all logging/activity), and adds a performance summary in the Chat window. You will not use this command often/ever. |
| `/x4d pos`,`/x4d loc` | Print player location including 'normalized/virtual' and 'minimap/actual' coordinates. |

Additionally, the `X4D_DB` module exposes its own commands:

| Command | |
|-|-|
| `/x4db count [DBNAME]` | Writes the count for the specified database. If no database is specified then "all" DBs are enumerated. Please be aware that 'transient' databases may be enumerated by this command. |
| `/x4db reset <DBNAME>` | Resets the target database such that it contains no items, no keys. Nothing. WARNING! Performing this against a "Core" DB may have unintended side-effects that will require you to manually delete savedvars. You should only use this to reset your OWN databases. |


## Support, Assistance, and Bug Reports

You can file a bug at <a href="https://github.com/wilson0x4d/X4DESO/issues">GITHUB.COM</a>.

You can send me **in-game mail** (not a /tell) if you prefer. I can be found on NA 
servers as `@wilson0x4d`. Feel free to say hello if you see me wandering 
about. :)


## Donations

I hope you enjoy using my add-ons as much as I enjoy creating them. If you want to show 
your support and donate :D I can always use in-game gold and items, and they're easy 
things to come by.

I am also a firm believer in Bitcoin, so if you really want to put a smile on my face 
send a Bitcoin donation (of ANY amount!) to <b><a href="bitcoin:1PeRYfrygTEo3VuJCQaZL5A43hrssRTNVH">1PeRYfrygTEo3VuJCQaZL5A43hrssRTNVH</a></b>,
you can use a service like <a href="https://www.coinbase.com">Coinbase</a> to purchase 
and send bitcoin if you don't already have a bitcoin wallet.
