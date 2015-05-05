# X4D **XP**

X4D XP is LibStub-compatible Add-On that reports XP gains.

## Features

- Outputs Experience Gains
- Shows XP/min
- Optionally shows Time-To-Level (ttl) 
- Optionally shows XP til-next-level (tnl)
- Can be integrated with via LibStub, and a callback can be set via **X4D_XP:RegisterCallback(color, text)**
- Supported by **X4D Chat** Add-On

## Planned

- If user is idle for 5 minutes or more, reset session start time and session count to avoid skew.

## Installation

Open the Archive and copy the **X4D_XP** folder into **%USERPROFILE%\Documents\Elder Scrolls Online\live\Addons\** folder.

If ESO is already running, execute **/reloadui** command.

## Versions

v1.9

- Added new 'XP Status Panel' (depends on optional X4D UI Addon)

v1.8

- Fix bug where quest XP was being reported twice.
- Misc updates for Core v1.10

v1.7

- Modified gains displayed for veteran ranked players.
- Added Settings UI, with two new feature options "Show TNL" and "Show TTL"
- Added new TTL/TNL outputs to chat with standard XP gains (not reported for Quest, Objective nor POI since it is less relevant.)

v1.6

- Fixed bug where sometimes XP would be reported incorrectly.

v1.5

- ESO Update 6
- Removed LibAddonMenu from /lib/ folder
- Depends On: X4D_Core, LibAddonMenu-2.0

v1.4

- ESO version update, no functional change

v1.3

- Additional support for Veteran Points

v1.2

- Added support for Veteran Points

v1.1

- Quest, Objective and Discovery XP now identifies the source (e.g. Quest names, POI names, etc)
- XP output format changed for readability.
- Colors adjusted for readability.

v1.0

- Initial release.

