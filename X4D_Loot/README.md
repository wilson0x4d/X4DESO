# X4D **Loot**

## Features

- Outputs 'Loot Items' to Chat Window, with correct Item Quality and Count.
- Outputs 'Quest Items' to Chat Window, with Count.
- Optional 'Party Loot' to Chat Window.
- Optional 'Money Updates' to Chat Window (gold spends/gains, with remaining balance)
- When Bag is Full or Almost Full (less than 10 slots free), you are notified.
- Can be integrated with via LibStub, and a callback can be set via **X4D_Loot:RegisterCallback(color, text)**
- Integrated into **X4D Chat** Add-On which provides timestamp support for **X4D Loot** output.

## Planned

- Option to display loot from deconstructed items.
- Option to show/hide AP (Alliance Point) gains

## Installation

Open the Archive and copy the **X4D_Loot** folder into **%USERPROFILE%\Documents\Elder Scrolls Online\live\Addons\** folder.

If ESO is already running, execute **/reloadui** command.

## Versions

v1.14

- New option to display Level of looted items.
- Fixed invalid use of GetMaxBags()
- Additional money update reason override when Vendors addon is present.

v1.13

- Change to use "on-hand" rather than occasionally misinterpreted term "total"
- Relocated loot-specific behaviour out of Bank addon and into Loot addon.
- Fix bug where withdrawals from bank were double-reported by loot addon.
- Added additional event hooks where Loot snapshots "may" require an update, such as when using a crafting table.
- Misc updates for Core v1.10

v1.12

- Fixed bug where empty slots would process as modified slots and error.
- Fixed bug where quest tool display would not report correct count.
- Fixed bug displaying incorrect values for stackable loot (cumulative vs. deltas)

v1.11

- Misc clean-up and fixed Group/Party Member Loot display.
- Properly built item links now show when an Item was stolen or not.
- First version to embrace the new modules added to core (Icons, Items, Bags.)
- Completely refactored how updates were determined, retiring some really old (and complex) code.

v1.10

- Allowing X4D_Vendors to take over responsibility of reporting vendor income/expenses.
- Added option to report loot worth, enabled by default.

v1.9

- Added 'beta' option to display party loot, needs more work.
- Many bug fixes related to API changes.

v1.8

- ESO Update 6
- Removed LibAddonMenu from /lib/ folder
- Depends On: X4D_Core, LibAddonMenu-2.0

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
