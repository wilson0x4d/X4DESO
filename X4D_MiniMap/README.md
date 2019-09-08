# X4D **MiniMap**

X4D MiniMap is a UI Mod which adds a simple MiniMap to the game.

## Features

- MiniMap Anchored to bottom-right of display.
- Map/Zone and Location Name
- Player Position

## Known Issues

-- Occasionally a map will appear with incorrect scaling/size, while POIs/etc appear with their correct scaling/size and location. You may be able to work around this issue by performing a `/reloadui`, if that fails then a hard reset of the maps DB can be performed followed by `/reloadui` but this is extreme. In most cases waiting 5 minutes for a map refresh is sufficient/preferred.

## Planned

- Additional POIs
- Zoom In/Out
- Moving
- Resizing
- MiniCompass (Outer Border with Pips)
- Other (Nodes, Mob Levels, etc)
- Rotation
- Fencing / Boundaries

## Installation

Open the Archive and copy the **X4D_MiniMap** folder into **%USERPROFILE%\Documents\Elder Scrolls Online\live\Addons\** folder.

If ESO is already running, execute **/reloadui** command.


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

### 1.7

- API Version 100028
- Major refactor to not be dependent on ZO World Map, removing much of the scatter/gather/guard logic seen in previous versions.
- Reizing and Relocation of MiniMap window to Play Nice(tm) with ZO's Bounty widget.
- Minor re-integration with Status Bar to allow MiniMap to overlay Status Bar without occluding Status Bar Panels.
- This module is transitioning from "alpha" to "beta" as new POI types are evaluated/integrated. Current implementation provides consistent experience.

### 1.6

- API Version 100017

### 1.5

- API Version 100012

### 1.4

- Fix error incorreect name when performing tile measurements.
- Modified zoom/pan state to update 15 times a second instead of 10 (providing a smoother user experience)

### 1.3

- Integrated Stopwatch module for profiling misc code.

### 1.2

- Code is stabilizing, but still considered Alpha stages of development.
- Use new 'GetTileDimensions' from Cartography module, retiring use of globals for tracking/determining tile dimensions.
- Fixed bug where minimap zoom level would become stuck on zone change, MiniMap now uses a fixed zoom level, and performs scaling instead of resizing.
- Allow pip position to wander, rather than clamp to interior of tile container, this provides a better experience when nearing the edge of a map.

### 1.1

- Fix bug where Location Name not updating.
- Misc optimizations to minimap/ui code.
- Updates for X4D_Core ### 1.14

### 1.0

- Initial release.

