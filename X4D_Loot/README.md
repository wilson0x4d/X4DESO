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
