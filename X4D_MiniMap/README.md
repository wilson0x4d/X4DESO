# X4D **MiniMap**

X4D MiniMap is a UI Mod which adds a simple MiniMap to the game.

## Features

- MiniMap Anchored to bottom-right of display.
- Map/Zone and Location Name
- Player Position

## Known Issues

- When using the world map, sometimes exiting the world map causes the minimap to desync. Closing and re-opening the world map will fix the issue.

## Planned

- Locations
- POIs
- Zoom In/Out
- Moving
- Resizing
- MiniCompass (Outer Border with Pips)
- Other (Nodes, Mob Levels, etc)
- Rotation

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

v1.2

- Code is stabilizing, but still considered Alpha stages of development.
- Use new 'GetTileDimensions' from Cartography module, retiring use of globals for tracking/determining tile dimensions.
- Fixed bug where minimap zoom level would become stuck on zone change, MiniMap now uses a fixed zoom level, and performs scaling instead of resizing.
- Allow pip position to wander, rather than clamp to interior of tile container, this provides a better experience when nearing the edge of a map.

v1.1

- Fix bug where Location Name not updating.
- Misc optimizations to minimap/ui code.
- Updates for X4D_Core v1.14

v1.0

- Initial release.

