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
- BUG: when you swap rings, then go loot something, the swap registers as a loss of an item. probably need to test item swap scenarios but this may be specific to swapping rings (a game-dev optimization.)
- BUG: because of inventory changes (crafting bag) when looting mats we no longer get notifications. we may also see breaks in other modules (vendor sales, laundering, etc?)

## Installation

Open the Archive and copy the **X4D_Loot** folder into **%USERPROFILE%\Documents\Elder Scrolls Online\live\Addons\** folder.

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

### 1.19
#### ESO 2.6
- API Version 100017
- Fixes a bug where confiscated items would cause new items to not be detected correctly.
- Adds support for detecting when stolen items are confiscated/removed from your inventory.

### 1.18
#### ESO 2.1
- API Version 100012

### 1.17

- Integrated Stopwatch module for profiling misc code.

### 1.16

- Fix several nil reference bugs when populating bag slots which may have been emptied/moved by a coroutine.

### 1.15

- Fix bug where 'receiving player' was not being displayed when grouped and group loot option is enabled.

### 1.14

- New option to display Level of looted items.
- Fixed invalid use of GetMaxBags()
- Additional money update reason override when Vendors addon is present.

### 1.13

- Change to use "on-hand" rather than occasionally misinterpreted term "total"
- Relocated loot-specific behaviour out of Bank addon and into Loot addon.
- Fix bug where withdrawals from bank were double-reported by loot addon.
- Added additional event hooks where Loot snapshots "may" require an update, such as when using a crafting table.
- Misc updates for Core ### 1.10

### 1.12

- Fixed bug where empty slots would process as modified slots and error.
- Fixed bug where quest tool display would not report correct count.
- Fixed bug displaying incorrect values for stackable loot (cumulative vs. deltas)

### 1.11

- Misc clean-up and fixed Group/Party Member Loot display.
- Properly built item links now show when an Item was stolen or not.
- First version to embrace the new modules added to core (Icons, Items, Bags.)
- Completely refactored how updates were determined, retiring some really old (and complex) code.

### 1.10

- Allowing X4D_Vendors to take over responsibility of reporting vendor income/expenses.
- Added option to report loot worth, enabled by default.

### 1.9

- Added 'beta' option to display party loot, needs more work.
- Many bug fixes related to API changes.

### 1.8

- ESO Update 6
- Removed LibAddonMenu from /lib/ folder
- Depends On: X4D_Core, LibAddonMenu-2.0

### 1.7

- ESO version update, no functional change

### 1.6

- Fix bad reference to LibAddonMenu.

### 1.5

- Fix crafting tables not updating bag states.

### 1.4

- Fix items in slot 0 would not display updates.
- Fix certain bag updates were not being tracked, and would result in 'spam'.
- Fix typo that was causing an error dialog to appear in rare cases.

### 1.3

- Icons for all loot and monetary displays.
- Fixed bug where some quest tools did not display correctly.
- Bag Space Low/Full Notifications now seen less often.
- Gold amounts display with thousands separators.

### 1.2

- Removed prefixes on some output.
- Added color for subtext.

### 1.1

- Fixed a bug where, sometimes, loot would not be displayed.
- Fixed a bug where, sometimes, non-loot would be displayed.
- Added support for displaying 'quest items'.

### 1.0

- Initial release.
