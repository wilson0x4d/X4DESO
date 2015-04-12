# X4D **Chat**

## Features

* Optionally Modifies Guild Chat so that Character Names are displayed instead of Account Names.
* Optional Chat Timestamps
* Optional Color Stripping
* Optional Guild Abbreviations
* Optional Guild Numbers
* Optional Excess Text Stripping
* Option to Disable Chat Window Fading
* Resize Chat Window Larger than Standard Default
* Configurable Guild Abbreviations (overrides Inferred abbreviations.)

## Installation

*If you are upgrading from v1.2 or earlier you must first delete any prior version of the Add-On.*

Open the Archive and copy the **X4D_Chat** folder into **%USERPROFILE%\Documents\Elder Scrolls Online\live\Addons\** folder.

If ESO is already running, execute **/reloadui** command.

## Versions
v1.24

- ESO Update 6
- Removed LibAddonMenu-1.0 from /lib/ folder
- Fixed parsing bug when deriving colors from 'nil'
- Depends On: X4D_Core, LibAddonMenu-2.0
 
v1.23

- ESO version update, no functional change

v1.22

- Fix bad reference to LibAddonMenu.

v1.21

- Fix bug in "Remove Seconds Component" option.

v1.20

- Fix 12 hour timestamps showing as negative values.
- Add option to remove the "seconds" component from timestamps.

v1.19

- Add Support for [URL="http://www.esoui.com/downloads/info347-X4DBank.html"][B]X4D [COLOR="DarkOrange"]Bank[/COLOR][/B][/URL]

v1.18

- Add Option to choose between 24-Hour and 12-Hour Timestamp Formats.

v1.17

- Option to disable Friend Online/Offline messages.

v1.16

- Friend Online/Offline Messages now display Character Name.
- Add Timestamps to LibAntiSpam output.
- Add Timestamps and Character Name is Friend Online/Offline Messages.
- Add Timestamps to System Shutdown, Ignores, and Group Changes output.

v1.15

- Fixed bug where Player/Character Name options were mutually exclusive and displaying an incorrect state.

v1.14

- Add support for [URL="http://www.esoui.com/downloads/info324-X4DXP.html"][B]X4D [COLOR="DarkOrange"]XP[/COLOR][/B][/URL]

v1.13

- Fixed Highlight Colors for all Chat Output.

v1.12

- Fixed a LibStub error for users that do not also use LibAntiSpam.
- Added Option to Display Player Name in Guild Chat (in addition to Character Name, thus "character@player")
- 'Automatic Guild Abbreviations' should now pick up on lower case characters and respect punctuation.
- Users can now optionally specify an explicit Guild Abbreviation for each of their Guilds.
- Added Option to Disable Chat Window Fading

v1.11

- Chat Window can now be resized larger than the default limit allowed.

v1.10

- Adds support for **X4D Loot** Add-On.

v1.9

- Optimized resolving character names, reduces CPU utilization.

v1.8

- Fixed bug with certain player names not properly converting to character names in guild chat.

v1.7

- Support for displaying 'Guild Number' in lieu of or in addition to 'Guild Abbreviation'.
- Fixed bug with 'Reset to Defaults' which affected both UI and SavedVars.

v1.6

- Add support for Guild Name abbreviations, these can be specified in Guild Descriptions by Guild Leaders/Officers. For example "Our Guild Tag [FOO] is the best!" will cause "FOO" to be used as an abbreviation.- If an abbreviation is not set in Guild Description, one is inferred from the Guild Name.
- This feature, like all others, can be disabled in settings.   

v1.5

- Fixed bug with SavedVars not saving (oops!)
- Added support for [URL="http://www.esoui.com/downloads/info211-X4DLibAntiSpam.html"][B]X4D [COLOR="DarkOrange"]LibAntiSpam[/COLOR][/B][/URL]

v1.4

- Fixes a bug with player names which contain special characters.

v1.3

- Adds Settings UI, Enables Color Stripping, Adds Excess Text Stripping.

v1.2

- Added Timestamps, colorized for visibility. Added support to strip colors from text, but feature is not enabled.

v1.1

- Remove debug output from console (oops!)

v1.0

- Initial release.

