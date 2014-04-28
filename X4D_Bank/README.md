# X4D **Bank**

X4D Bank is LibStub-compatible Add-On that performs regular Bank deposits.

## Features

* Auto-Deposit Gold, either fixed amount or percentage of carried.
* Specify a Reserve Amount.
* Specify Deposit Down-Time, such as depositing only once an hour.
* Auto-Deposit Items (fill incomplete stacks, start new stacks)
* Deposit and Withdraw Items based on Item Type

## Planned Features

* Display own output, currently relies on X4D Loot for displaying Balance Changes.

## Installation

Open the Archive and copy the **X4D_Bank** folder into **%USERPROFILE%\Documents\Elder Scrolls Online\live\Addons\** folder.

If ESO is already running, execute **/reloadui** command.

## Versions
v1.7
- Fix bug when restacking.
- Removed call deferral for 'new stacks' functionality.
- Split "Armor Items" and "Weapon Items" into two additional groups "Armor Traits" and "Weapon Traits".

v1.6
- Add ability to Deposit and Withdraw Items based on Item Type.
- Add ability to combine partial stacks in inventory and bank.
- Removed option to create new stacks, this behavior is now implied.

v1.5
- Modified how auto-deposit amounts are determined, so that 'all non-reserve gold' can be deposited on every visit.

v1.4
- Fix bug with boolean options not being read correctly.

v1.3
- Settings are now Per-Character, or Account-Wide, you decide.
- Now performs bank deposits, thanks to users pointing out several add-ons which already make protected API calls.

v1.2
- Fix 'reset to defaults' bug in Options UI.

v1.1
- Option to Auto-Withdraw funds from bank to meet your reserve amount.

v1.0
- Initial release.

