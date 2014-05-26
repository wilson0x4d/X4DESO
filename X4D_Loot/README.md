# X4D **Loot**

## Features

* Outputs 'Loot Items' to Chat Window, with correct Tier Color and Count.
* Outputs 'Quest Items' to Chat Window, with Count.
* Outputs monetary changes (gold spends/gains) and remaining balance.
* When Bag is Full or Almost Full (less than 10 slots free), you are notified.
* Items can be clicked for Item Info.
* Can be integrated with via LibStub, and a callback can be set via **X4D_Loot:RegisterCallback(color, text)**
* Integrated into **X4D Chat** Add-On which provides timestamp support for **X4D Loot** output.

## Installation

Open the Archive and copy the **X4D_Loot** folder into **%USERPROFILE%\Documents\Elder Scrolls Online\live\Addons\** folder.

If ESO is already running, execute **/reloadui** command.

## Versions
v1.7
- ESO version update, no functional change

v1.6
- Fix bad reference to LibAddonMenu.

v1.5
- Fix crafting tables not updating bag states.

v1.4
- Fix items in slot 0 would not display updates.
- Fix certain bag updates were not being tracked, and would result in 'spam'.
- Fix typo that was causing an error dialog to appear in rare cases.

v1.3
- Icons for all loot and monetary displays.
- Fixed bug where some quest tools did not display correctly.
- Bag Space Low/Full Notifications now seen less often.
- Gold amounts display with thousands separators.

v1.2
- Removed prefixes on some output.
- Added color for subtext.

v1.1
- Fixed a bug where, sometimes, loot would not be displayed.
- Fixed a bug where, sometimes, non-loot would be displayed.
- Added support for displaying 'quest items'.

v1.0
- Initial release.

