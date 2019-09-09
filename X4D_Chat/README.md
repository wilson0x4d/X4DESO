# X4D **Chat**

## Features

* Modifies Guild Chat so that Character Names are displayed instead of Account Names.
* Optional Chat Timestamps, 12-Hour and 24-Hour formats, and both HH:MM and HH:MM:SS formats.
* Optional Color Stripping, no more rainbow text.
* Optional Auto-Generated Guild Abbreviations, as well as User Overrides
* Optional Guild Numbers
* Optional Efficient Text Format, e.g. remove "says", "yells", etc
* Option to Disable Chat Text Fade-Out
* Allows Resize of Chat Window to fill window
* Option to disable online/offline status updates.

## Planned

* Options to specify/override the Chat Tab for each message type
* Localization support for 'Efficient Text Format'

## Installation

Open the Archive and copy the **X4D_Chat** folder into **%USERPROFILE%\Documents\Elder Scrolls Online\live\Addons\** folder.

If ESO is already running, execute **/reloadui** command.


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


## Versions

### 1.35

- API Version 100028

### 1.35

- API Version 100017

### 1.33

- API Version 100012

### 1.32

- Integrated Stopwatch module for profiling misc code.

### 1.31

- fix bug where player names are not displayed when both playername and character name options were enabled.
- Updates for 

### 1.30

- fix bug with online/offline status.
- Misc updates for Core ### 1.13

### 1.29

- Fix bug invalid check for non-existent guild.

### 1.28

- Misc updates for Core ### 1.10

### 1.27

- Fix bug in Chat settings where custom guild abbreviations would be reset at the end of the session.
- Misc clean-up and bugfixes from core/items refactor for icons, items, bags, etc.

### 1.26

- add support for **X4D Vendors** Addon

### 1.25

- Misc updates due to Core changes.

### 1.24

- ESO Update 6
- Removed LibAddonMenu-1.0 from /lib/ folder
- Fixed parsing bug when deriving colors from 'nil'
- Depends On: X4D_Core, LibAddonMenu-2.0
 
### 1.23

- ESO version update, no functional change

### 1.22

- Fix bad reference to LibAddonMenu.

### 1.21

- Fix bug in "Remove Seconds Component" option.

### 1.20

- Fix 12 hour timestamps showing as negative values.
- Add option to remove the "seconds" component from timestamps.

### 1.19

- Add Support for X4D Bank

### 1.18

- Add Option to choose between 24-Hour and 12-Hour Timestamp Formats.

### 1.17

- Option to disable Friend Online/Offline messages.

### 1.16

- Friend Online/Offline Messages now display Character Name.
- Add Timestamps to LibAntiSpam output.
- Add Timestamps and Character Name is Friend Online/Offline Messages.
- Add Timestamps to System Shutdown, Ignores, and Group Changes output.

### 1.15

- Fixed bug where Player/Character Name options were mutually exclusive and displaying an incorrect state.

### 1.14

- Add support for `X4D_XP`.

### 1.13

- Fixed Highlight Colors for all Chat Output.

### 1.12

- Fixed a LibStub error for users that do not also use LibAntiSpam.
- Added Option to Display Player Name in Guild Chat (in addition to Character Name, thus "character@player")
- 'Automatic Guild Abbreviations' should now pick up on lower case characters and respect punctuation.
- Users can now optionally specify an explicit Guild Abbreviation for each of their Guilds.
- Added Option to Disable Chat Window Fading

### 1.11

- Chat Window can now be resized larger than the default limit allowed.

### 1.10

- Adds support for **X4D Loot** Add-On.

### 1.9

- Optimized resolving character names, reduces CPU utilization.

### 1.8

- Fixed bug with certain player names not properly converting to character names in guild chat.

### 1.7

- Support for displaying 'Guild Number' in lieu of or in addition to 'Guild Abbreviation'.
- Fixed bug with 'Reset to Defaults' which affected both UI and SavedVars.

### 1.6

- Add support for Guild Name abbreviations, these can be specified in Guild Descriptions by Guild Leaders/Officers. For example "Our Guild Tag [FOO] is the best!" will cause "FOO" to be used as an abbreviation.- If an abbreviation is not set in Guild Description, one is inferred from the Guild Name.
- This feature, like all others, can be disabled in settings.   

### 1.5

- Fixed bug with SavedVars not saving (oops!)
- Added support for `X4D_LibAntiSpam`.

### 1.4

- Fixes a bug with player names which contain special characters.

### 1.3

- Adds Settings UI, Enables Color Stripping, Adds Excess Text Stripping.

### 1.2

- Added Timestamps, colorized for visibility. Added support to strip colors from text, but feature is not enabled.

### 1.1

- Remove debug output from console (oops!)

### 1.0

- Initial release.

