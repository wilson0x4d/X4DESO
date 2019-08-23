# X4D ESO Add-Ons

A collection of LibStub-compatible Add-Ons that provide minor enhancements to the game "Elder Scrolls Online".

## Compatibility with Others, and Infrequent Updates

I started development of these AddOns years ago when the game first released. I still enjoy using these AddOns when I play and don't really "shop" much for other AddOns, so, I've no idea if they are at all compatible with other AddOns.

I only update these AddOns when I am actively playing the game, which has been infrequent over the years. Bills need paying, life remains busy. I'd be happy to work with other developers to maintain these AddOns (will grant rights as necessary to commit and release new builds.) Would be nice to see enough contributors to keep these alive and listed on ESOUI, Curse, etc, perhaps entirely automate the release process.

As it is I no longer publish to these sites because I'm not publishing regularly enough for it to matter.

I will be adding scripts to assist other developers with getting setup locally for development/debugging, and also for package & deployment of these AddOns. 
 
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
- **X4D_MiniMap** - (ALPHA PREVIEW) Adds a 'minimap' to the game (disabled by default until 'stable' quality.)

All of them are optional, except for X4D_Core, which all other X4D Add-ons depend on and it is thus required.

## Development

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

| Command | Args | Example | |
|-|-|-|-|
| `-debug` | N/A | `/x4d -debug` | Sets the log level to DEBUG (shows all logging/activity), and adds a performance summary in the Chat window.|
| `-test` | N/A | `/x4d -test` | Sets the log level to VERBOSE (shows most logging/activity, but not all), and then performs a board test of X4D AddOns, each test printing output to the Chat window. Useful for checking to see if anything fundamental has broken that would not throw an API error if misbehaving. |



## Support, Assistance, and Bug Reports

You can file a bug by commenting on the add-ons at <a href="http://www.esoui.com/downloads/author-4678.html">ESOUI.COM</a>.

You can send me **in-game mail** (not a /tell) if you prefer. I can be found on NA 
servers as Maekir@wilson0x4d, and feel free to say hello if you see me wandering 
about. :)


## Donations

I hope you enjoy using my add-ons as much as I enjoy creating them. If you want to show 
your support and donate :D I can always use in-game gold and items, and they're easy 
things to come by.

I am also a firm believer in Bitcoin, so if you really want to put a smile on my face 
send a Bitcoin donation (of ANY amount!) to <b><a href="bitcoin:1PeRYfrygTEo3VuJCQaZL5A43hrssRTNVH">1PeRYfrygTEo3VuJCQaZL5A43hrssRTNVH</a></b>,
you can use a service like <a href="https://www.coinbase.com">Coinbase</a> to purchase 
and send bitcoin if you don't already have a bitcoin wallet.



