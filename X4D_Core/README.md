# X4D **Core**

X4D Core is a LibStub-compatible Framework of shared code used throughout <a href="http://www.esoui.com/portal.php?id=50&a=list">X4D Addons</a>. Rather than duplicate this code it has been consolidated into a separate library add-on.

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
lib/LibStub/LibStub.lua
</pre>

Including X4D_Core along with your add-on is **NOT** recommended, but it is possible to do so. Contact me if you require assistance to avoid breaking other people's Add-Ons due to an incorrect set-up.
<pre>
## DependsOn: LibAddonMenu-2.0
## OptionalDependsOn: X4D_Core
lib/LibStub/LibStub.lua
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


## Versions

### 1.19
#### ESO 2.6 (API Version 100017)

- API Version 100017
- somewhere between ESO 2.2 and ESO 2.6 the game client stopped including names in item links when converting them to strings, therefore, all calls which previously returned a parsed item name now instead return the original link object (which the game engine will be entirely responsible for rendering correctly) -- if these are used as strings, they should convert into an engine-compatible equivalent and render correctly

?? - similarly item ids now include options so that X4D_Item objects can continue to be used to track extended item details as if they represented unique items -- for this reason we generate a new item link to serve as the aforementioned `name` result -- however, X4D will never use the resulting item names/links where uniqueness (instance-id) is required

#### ESO 2.4 (API Version 100015)

- Fixed bug with `ITEMTYPE_ALCHEMY_BASE` having been split into two groups, potions and poisons.

### 1.18
#### ESO 2.1 (API Version 100012)
- Updated 'currency type' enums which ESO devs renamed and also removed.

### 1.17

- Several global functions in 3rd party libs are now local to prevent collision with other poorly written addons.
- Added debug output to report module loads, only visible to developers who modify add-on source code to default to 'DEBUG' trace level.
- Added framerate and latency data to core debug output.
- Modified oom handler to report after 3rd out-of-memory event instead of 5th.
- Relocate Cartography coroutine creation to explicit initializer, requiring dependent modules to call initializer (minor optimization)
- Fixed bug where Log module output verbose log lines not meant for release to users.
- Avoid full-copy of player DB during scavenge, instead preferring iterator with predicate relocated into iter function (major optimization)
- Modified base58 wrapper to use single-alloc for bignum0/bignum1 (minor optimization)

### 1.16

- Moved Cartography module init into LOAD instead of ACTIVATE event handler (e.g. is now initializing earlier than player init.)
- Fixed bug with DB module :Count() method returning incorrect counts.
- Fixed bug with DB module :Where() method iterating over non-entities.
- Add new 'X4D_Stopwatch' module for profiling/timing arbitrary blocks of code.
- Integrated Stopwatch module for profiling misc code.
- Refactored Log module to capture all output even when ESO's CHAT_SYSTEM is not ready yet, thus allowing devs to see logs from when their Addon code first began execution.
- Added new 'Raw' log level, which bypasses all of X4D_Log's "prettifying" behavior (e.g. functionally equivalent to in-build d(...) function, no timestamps and no color modifications.)
- Added new 'System' log level, which will always appear if used, and will use the in-built 'System' text color (yellow.)

### 1.15

- Refactors to Cartography module for more efficient amp data acquisition, as well as numerous work-arounds to the quirky nature of ZO_WorldMap & Friends.
- Cartography module now updates at a rate of ~20fps, this affects animations of consumer code (like MiniMap.) The old update rate was ~13fps (bare minimum.)
- Fixed bug where Cartograpy module would create new coroutine on every map change.
- Fixed bug where Bags module would error when bag state was modified by multiple coroutines.
- The Garbage Collector is now auto-tuned over time based on memory growth and OOM events, instead of the OOM-prone default configuration.
- The "/x4d -debug" command will now load Zgoo to the X4D root, and print colorized memory deltas and timer/coroutine counts every 5 seconds.
- The DB module now allows authors to version each database independent of any SVs which may be used as a backing store. This way a DB can be reset (by version) without necessarily having to reset all SVs.
- Many general optimizations to cull back memory and CPU use.

### 1.14

- Removed unnecessary log lines.
- Fixed bug where IsSubZone was not being set properly.
- Optimizations and bug fixes for new (alpha) Cartography code.
- Created new 'Crafting' item types group to clarify settings in misc addons which depend on it.
- Salting vendor keys to avoid name collisions for generic-named NPCs.

### 1.13

- Added new 'X4D_Cartography' module.
- Several bug fixes for Observables, including a plurality change on all uses, and the introduction of 'Rate Limit' concept.
- Modified "/x4d" slash-command to accept a -test option, this puts the framework into development mode.
- Added :Count() method to X4D_DB LINQ-like interface.
- Callers can now include their identity when creating an async timer, this is a debugging aid.
- Added new "Debug" trace level (this is lower level than "Verbose")

### 1.12

- Added new 'X4D_Observable' module, check source file for notes/usage.
- Using localized "Item Type" Names where possible.
- Updated Test() method with X4D.Observable showcase.

### 1.11

- fix 'fish bug', add missing ITEMTYPE_FISH, it has been placed in the "Provisioning" group
- X4D.Log:Error only displays type info when Verbose trace level has been set (e.g. no longer the default)
- fixed off-by-one bug in bags module which would make it appear as though and item couldn't be deposited into the bank
- added new 'X4D_Currency' module
- added quality colors to item qualities table
- added some basic colors (RGB,CYM,BWG) to Colors module

### 1.10

- Fix bug where items stored without an item type would cause normalization to error.
- Fix bug where item names would be overwritten with non-normalized versions
- Adapted MD5 algo from https://github.com/kikito/md5.lua/blob/master/md5.lua
- X4D.Debug is now X4D.Log

### 1.9

- Fixed bug where FreeCount would desync when slots were repopulated.
- Modified item normalization text so that "level" portion uses minimum of 2 digits for level (to assist with low level item pattern matches e.g. "L[012][0-9].*ITEMTYPE_POTION")

### 1.8

- Reset of Core DBs (nobody will notice)
- Improved Icons, Items, Bags, Players and Settings modules.
- Bug fixes for DB, Players and Settings moduls.

### 1.7-hotfix

- fix null reference error in X4D_DB module

### 1.6

- Added new X4D_Bags module, which will help consolidate code/requirements that exist for Vendor, Bank and Loot Addons.
- X4D_DB now returns keys in addition to values from :Find() and most callbacks (predicates, builders, visitors) are now sent the key as a second parameter. This allows more efficient code to be written (knowing which key allows for direct lookups.)
- Default 'trace level' is now "INFORMATION" (instead of WARNING), developers should use X4D.Log:Verbose(...) for debug output, and X4D.Log:Information(...) for user-friendly information messages. Eventually the end-user will be able to change trace level, developers need to ensure "Information" level is not used for dev-only feedback.
- X4D_Players base58 encodes keys, it does not duplicate the key as a conventional property (shaving memory for something we don't actually need to look-up.), and optimized player lookups.

### 1.5

- Fixed a bug which only affects X4D_Bank by preventing you from changing "Settings Are.." from "Account-Wide" to "Per-Character"

### 1.4

- Fixed several bugs in Async, DB, and Settings modules.
- Implemented persistence and scavenging for Players module, moved data out of AntiSpam.
- Added 'LibAddonMenu-2.0' to /lib/ folder, marked it as an optional dependency.
- Added new 'X4D_ETA' module

### 1.3

- Fixed bug in settings save/restore for per-character
- Added 'Low Addon Memory' event handler that reports amount of memory in-use at the time

### 1.2

- Added sha1, base58 and bignum functions/libraries

### 1.1

#### ESO 1.4-1.6(-ish)
- Removed LibAddonMenu-1.0 from /lib/ folder
- DependsOn: LibAddonMenu-2.0


### 1.0

#### ESO 1.0-1.2(-ish)
- Initial release.
- multiple fixes

