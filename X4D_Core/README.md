# X4D **Core**

X4D Core is a LibStub-compatible Framework of shared code used throughout <a href="http://www.esoui.com/portal.php?id=50&a=list">X4D Addons</a>. Rather than duplicate this code it has been consolidated into a separate library add-on.

All X4D Add-Ons depend on this Framework.


## Features

* String Helpers
    * string:Split, string:StartsWith, string:EndsWith, etc.
    * base58() and sha1() helpers
* Conversion API
    * Various conversion/mapping helpers necessary in X4D Addons.
* Color API
    * Color constants used throughout X4D Addons as well as color helpers to create, parse, lerp, etc.
* Icons API
    * Helpers for working with Icons
* Debug API
    * Log Levels such as Verbose, Information, Warning, and Error
    * Clean, for example: X4D.Debug:Verbose('Hello, World!')
* Async API
    * Async helpers, currently exposes a Timer via X4D.Async.CreateTimer() call
* Settings API
    * Tidy wrapper for 'Saved Variables', providing more consistent and predictable behavior.
* Database API
    * Provides a LINQ-like wrapper around Lua tables *(Fx: myDb:Where(predicate) myDb:Select(builder) myDb:ForEach(visitor) myDb:FirstOrDefault() etc)
    * Query results also provide LINQ-like wrapper API
    * Provides 'persistent' databases, as well. These databases can be accessed between multiple Addons to share data.
* Items API
    * Lookup tables for:
        * Item Qualities
        * Item Types
        * Item Groups
    * Item DB (work in progress)
* Players API
    * Player DB (work in progress)
* Guilds API
    * Guild DB (work in progress)

## Installation

Open the Archive and copy the **X4D_Core** folder into **%USERPROFILE%\Documents\Elder Scrolls Online\live\Addons\** folder.


If ESO is already running, execute **/reloadui** command.

## Integration

In your code:
<pre>
local X4D = LibStub('X4D')
if (X4D) then
	X4D.Debug.Verbose('Hello, World!')
	X4D.Debug.Error({ ['HELLO'] = 'WORLD' })
end
</pre>

In your manifest, if you are NOT including the library with your Add-On:
<pre>
## DependsOn: X4D_Core
lib/LibStub/LibStub.lua
</pre>

Including X4D_Core along with your add-on is **NOT** recommended, but it is possible to do so. Contact me if you require assistance to avoid breaking other people's Add-Ons due to an incorrect set-up.
<pre>
## DependsOn: LibAddonMenu-2.0
## OptionalDependsOn: X4D_Core
lib/LibStub/LibStub.lua
lib/kikito/sha1.lua
lib/badgerman/BigNum.lua
lib/X4D_Core.lua
lib/X4D_Strings.lua
lib/X4D_Convert.lua
lib/X4D_Colors.lua
lib/X4D_Icons.lua
lib/X4D_Debug.lua
lib/X4D_Async.lua
lib/X4D_Settings.lua
lib/X4D_DB.lua
lib/X4D_Items.lua
lib/X4D_Players.lua
lib/X4D_Guilds.lua
</pre>

## Versions
v1.5

- Fixed a bug which only affects X4D_Bank by preventing you from changing "Settings Are.." from "Account-Wide" to "Per-Character"

v1.4

- Fixed several bugs in Async, DB, and Settings modules.
- Implemented persistence and scavenging for Players module, moved data out of AntiSpam.
- Added 'LibAddonMenu-2.0' to /lib/ folder, marked it as an optional dependency.
- Added new 'X4D_ETA' module

v1.3

- Fixed bug in settings save/restore for per-character
- Added 'Low Addon Memory' event handler that reports amount of memory in-use at the time

v1.2

- Added sha1, base58 and bignum functions/libraries

v1.1

- ESO Update 6
- Removed LibAddonMenu-1.0 from /lib/ folder
- DependsOn: LibAddonMenu-2.0


v1.0

- Initial release.
- multiple fixes

