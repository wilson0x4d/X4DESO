# X4D **Core**

X4D Core is a LibStub-compatible Framework of shared code used throughout all X4D Addons.

All X4D Add-Ons depend on this Framework.

## Features

* String Module
    * string:Split, string:StartsWith, string:EndsWith, etc.
    * base58(), sha1() and md5() helpers
* Conversion Module
    * Various conversion/mapping helpers necessary in X4D Addons.
* Color Module
    * Color constants used throughout X4D Addons as well as color helpers to create, parse, lerp, etc.
* Icons Module
    * Helpers for working with Icons.
    * Icons table to reference icons using less memory.
* Logging Module
    * Log Levels such as Verbose, Information, Warning, and Error
    * Clean, for example: X4D.Log:Verbose('Hello, World!')
* Async Module
    * Async helpers, currently exposes a Timer via X4D.Async:CreateTimer() call
* Observable Module
    * Observable closure providing basic observer/observable behavior
* Settings Module
    * Tidy wrapper for 'Saved Variables', providing more consistent and predictable behavior.
* Database Module
    * Provides a LINQ-like wrapper around Lua tables *(Fx: myDb:Where(predicate) myDb:Select(builder) myDb:ForEach(visitor) myDb:FirstOrDefault() etc)
    * Query results also provide LINQ-like wrapper API
    * Provides 'persistent, named' databases, as well. These databases can be accessed between multiple Addons to share data.
* Cartography module
    * Provides Current Map Information (Index, Zone, Name, Location, etc)
    * Exposes Observables for Map and Player Information
* Items Module
    * Lookup tables for:
        * Item Qualities
        * Item Types
        * Item Groups
    * Item DB (work in progress)
* Players Module
    * Tracks recently seen players (last 15 minutes.)
    * Remembers spammers, and whitelisted players (friends, guild members, etc.)
* Guilds Module
    * Guild DB (work in progress)


## Installation

Open the Archive and copy the **X4D_Core** folder into **%USERPROFILE%\Documents\Elder Scrolls Online\live\Addons\** folder.

If ESO is already running, execute **/reloadui** command.


## Integration

In your code:
<pre>
local X4D = LibStub('X4D')
if (X4D) then
	X4D.Log:Verbose('Hello, World!')
	X4D.Log:Error({ ['HELLO'] = 'WORLD' })
end
</pre>

In your manifest, if you are NOT including the library with your Add-On:
<pre>
## DependsOn: X4D_Core
lib/X4D_LibStub/X4D_LibStub.lua
</pre>

Including X4D_Core along with your add-on is **NOT** recommended, but it is possible to do so. Contact me if you require assistance to avoid breaking other people's Add-Ons due to an incorrect set-up.
<pre>
## DependsOn: LibAddonMenu-2.0
## OptionalDependsOn: X4D_Core
lib/X4D_LibStub/X4D_LibStub.lua
lib/kikito/sha1.lua
lib/kikito/md5.lua
lib/badgerman/BigNum.lua
lib/X4D_Core/X4D_Core.lua
lib/X4D_Core/X4D_Observable.lua
lib/X4D_Core/X4D_Strings.lua
lib/X4D_Core/X4D_Convert.lua
lib/X4D_Core/X4D_Colors.lua
lib/X4D_Core/X4D_Icons.lua
lib/X4D_Core/X4D_Currency.lua
lib/X4D_Core/X4D_Log.lua
lib/X4D_Core/X4D_ETA.lua
lib/X4D_Core/X4D_Settings.lua
lib/X4D_Core/X4D_DB.lua
lib/X4D_Core/X4D_Async.lua
lib/X4D_Core/X4D_Cartography.lua
lib/X4D_Core/X4D_Items.lua
lib/X4D_Core/X4D_Players.lua
lib/X4D_Core/X4D_Guilds.lua
lib/X4D_Core/X4D_Bags.lua
</pre>

At the in-game Chat prompt, you can execute a "/x4d" command with no arguments to run a test and enable 'developer mode'.
When developer mode is enabled you will see detailed log output. Errors will include type information, and 'Verbose' log output will be displayed.


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
