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

* Restacking issue between BAG_BANK and BAG_SUBSCRIBER_BANK, not implemented. As a workaround users can leverage the in-game restack hotkey.

## Installation

Open the Archive and copy the **X4D_Bank** folder into **%USERPROFILE%\Documents\Elder Scrolls Online\live\Addons\** folder.

If ESO is already running, execute **/reloadui** command.


## Support, Assistance, and Bug Reports

You can file a bug at <a href="https://github.com/wilson0x4d/X4DESO/issues">GITHUB.COM</a>.

You can send me **in-game mail** (not a /tell) if you prefer. I can be found on NA 
servers as `@wilson0x4d`. Feel free to say hello if you see me wandering 
about. :)


## Donations

I hope you enjoy using my add-ons as much as I enjoy creating them. If you want to show 
your support and donate :D I can always use in-game gold and items, and they're easy 
things to come by.

I am also a firm believer in Bitcoin, so if you really want to put a smile on my face 
send a Bitcoin donation (of ANY amount!) to <b><a href="bitcoin:1PeRYfrygTEo3VuJCQaZL5A43hrssRTNVH">1PeRYfrygTEo3VuJCQaZL5A43hrssRTNVH</a></b>,
you can use a service like <a href="https://www.coinbase.com">Coinbase</a> to purchase 
and send bitcoin if you don't already have a bitcoin wallet.
