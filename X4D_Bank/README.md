# X4D **Bank**

X4D Bank is LibStub-compatible Add-On that performs regular Bank deposits.


## Features

* Auto-Deposit Gold, either fixed amount or percentage of carried.
* Specify a Gold Reserve Amount to ensure a minimum amount is kept on-hand.
* Specify Deposit Debounce Time, such as depositing only once an hour.
* Auto-Deposit Items (fill incomplete stacks, start new stacks)
* Deposit and Withdraw Items based on Item Type
* Pattern-based Item Ignore List - by default, ignore STOLEN items.


## Planned Features

* Display own output, currently relies on X4D Loot for displaying Balance Changes.


## Known Issues

* If an item is "Character Bound" and your configuration settings would normally deposit it to the bank, instead an error occurs. As a temporary workaround `IsBound==true` items will NOT be auto-deposited regardless of what user settings are.

## Installation

Open the Archive and copy the **X4D_Bank** folder into **%USERPROFILE%\Documents\Elder Scrolls Online\live\Addons\** folder.

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

### 1.28

- API Version 100028
- Rework of Settings Panel based on user feedback.
- Added support for ESP Plus 'Subscriber Bank' slots.
- Changed default Gold Deposit/Withdraw settings to be less agg.

### 1.27

- API Version 100017
- Refactored primary banking logic to operate asynchronously.
- Added MRL (message rate limiting) logic, the rate limit is arbitrary at this time and based on own testing and user experience. This was only done to Play Nice(tm) with the server, network and CPU, it was not actually a problem.
- Refactored to use 'scrubbed item links' as "X4D_Item IDs, aka. X4DB entity keys" instead of "item names" where applicable due to ESO changes which affected the "X4D_Item Module".

### 1.26
#### ESO 2.1

- API Version 100012

### 1.25

- Removed anonymous function (minor optimization)

### 1.24

- Integrated Stopwatch module for profiling misc code.

### 1.23

- When closing bank, refresh bag state, allowing status bar updates to use cached data rather than constantly refresh bag state itself.

### 1.22

- Add item deposit/withdraw patterns, similar to "for keeps" and "for sales" patterns in the Vendors addon, but applied to banks
- update descriptions on settings ui

### 1.21

- Fixed bug combining partial stacks that would cause UI Error.

### 1.20

- Fixed off-by-one bug in slot iterators.
- Added new 'Bank Status Panel' (depends on optional X4D UI Addon)
- Additional money update reason override when Vendors addon is present.

### 1.19

- Relocated loot-specific behaviour out of Bank addon and into Loot addon.
- Misc updates for Core ### 1.10

### 1.18

- Fixed bug where partial stacks were sometimes not being filled if target bag was full and prior stack failed to fill.

### 1.17

- Reports withdrawal/deposit summaries at end of auto-deposit/auto-withdraw actions, and also shows free backpack/bank slot counts (no need to click tabs.)
- Improved display of item links by adopting zo_strformat where appropriate, removed old method of reformatting of link text, 
- Misc clean-up and bugfixes from core/items refactor for icons, items, bags, etc.

### 1.16

- Added 'Reset' section where users can quickly reset all item type options at once, handy for reconfigurations and first time setups.

### 1.15

- Optimized how Item Type Deposit Settings are stored/used.

### 1.14

- Added 'Ignored Items List'
- Expanded Item Type Deposit Settings

### 1.13

- ESO Update 6
- Removed LibAddonMenu-1.0 from /lib/ folder
- Depends On: X4D_Core, LibAddonMenu-2.0

### 1.12

- fixed bug where deposits/withdrawals would not be displayed
- added support for Gold deposit/withdrawal information (normally provided by X4D_Loot add-on instead.)

### 1.11

- ESO version update, no functional change

### 1.10

- More intelligent item deposit/withdraw logic.
- Fixed "double-deposit to restack" bug.
- Auto-Split when a single slot doesn't fit into target partial stack, additional partial slots and/or free slot is used.
- Stack counts reported now report actual number of items counted (not the final stack size.)

### 1.9

- Fix to prevent attempting to stack items of different levels/qualities.

### 1.8

- Fixed Descriptions
- Fix bad reference to LibAddonMenu

### 1.7

- Fix error when restacking.
- Removed call deferral for 'new stacks' functionality.
- Split "Armor Items" and "Weapon Items" into two additional groups "Armor Traits" and "Weapon Traits".
- Added Additional Groups for previously missing item items.

### 1.6

- Add ability to Deposit and Withdraw Items based on Item Type.
- Add ability to combine partial stacks in inventory and bank.
- Removed option to create new stacks, this behavior is now implied.

### 1.5

- Modified how auto-deposit amounts are determined, so that 'all non-reserve gold' can be deposited on every visit.

### 1.4

- Fix bug with boolean options not being read correctly.

### 1.3

- Settings are now Per-Character, or Account-Wide, you decide.
- Now performs bank deposits, thanks to users pointing out several add-ons which already make protected API calls.

### 1.2

- Fix 'reset to defaults' bug in Options UI.

### 1.1

- Option to Auto-Withdraw funds from bank to meet your reserve amount.

### 1.0

- Initial release.

