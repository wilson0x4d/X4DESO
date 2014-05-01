# X4D **Core**

A LibStub-compatible Framework for Developing Add-Ons for ESO.

All X4D Add-Ons rely on this Framework.

## Features

* Debug API
* Color API
* SavedVars API
* Async API
* Items API
* Players API
* Guilds API
* LibAddonMenu Extensions
* Misc. Conversion Functions

## Integration

In your code:
```
local X4D = LibStub('X4D')
if (X4D) then
	X4D.Verbose('Hello, World!')
	X4D.Error({ ['HELLO'] = 'WORLD' })
end
```

In your manifest, if you are NOT including the library with your Add-On:
```
## DependsOn: X4D_Core
## OptionalDependsOn: LibAddonMenu-1.0
lib/LibStub/LibStub.lua
lin/LibAddonMenu-1.0/LibAddonMenu-1.0.lua
```

Including X4D_Core along with your add-on is **NOT** recommended, but it is possible to do so. Contact me if you require assistance to avoid breaking other people's Add-Ons due to an incorrect set-up.
```
## OptionalDependsOn: LibAddonMenu-1.0, X4D_Core
lib/LibStub/LibStub.lua
lib/LibAddonMenu-1.0/LibAddonMenu-1.0.lua
lib/X4D_Core/X4D_Colors.lua
lib/X4D_Core/X4D_Debug.lua
lib/X4D_Core/X4D_Convert.lua
lib/X4D_Core/X4D_SavedVars.lua
lib/X4D_Core/X4D_Async.lua
lib/X4D_Core/X4D_Items.lua
lib/X4D_Core/X4D_Guilds.lua
lib/X4D_Core/X4D_Players.lua
lib/X4D_Core/X4D_Options.lua
lib/X4D_Core/X4D_Conversions.lua
lib/X4D_Core/X4D_Core.lua
```

*NOTE: LibAddonMenu-1.0 is Optional, X4D_Core does not require it, but will extend it if present.*

## Installation

Open the Archive and copy the **X4D_Core** folder into **%USERPROFILE%\Documents\Elder Scrolls Online\live\Addons\** folder.


If ESO is already running, execute **/reloadui** command.

## Versions
v1.0
- Initial release.

