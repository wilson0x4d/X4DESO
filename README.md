# X4D ESO Add-Ons

A collection of LibStub-compatible Add-Ons that provide minor enhancements to the game "Elder Scrolls Online".

### Until next update, YMMV. Enjoy!

As of 2016-10-22 This code is in a **raw development stage**, a work in progress as **it is being updated for various changes to the Game APIs since last update.** Hooray! 

You can expect another 30 days before all X4D modules have been updated and tested, this code is merely committed "as-is" so there is more than one copy, and so that anyone that wants access to an "experimental dev build" now has it. 

Not all modules have been upgraded (namely: `Mail` and `LibAntiSpam`, all others work for me, however, X4D_XP module has not been tested with a Champion character, but it "should" work.)

Lastly, LibAddonMenu has not been upgraded, but works fine for me as I do not have any other Addons which use a newer version.) The ownership of LAM has been solid in the past, and so I expect LAM to remain backward compatible, but have not verified. Again, YMMV.

The versions, notes, etc in various READMEs, including this one, have not been updated. I only do this as part of public release to http://ESOUI.com -- which will not happen for another 30 days.
 
### Dependencies

- LibStub *(Optional)*
- LibAddonMenu-2.0 *(Optional)*

### Modules

One of the earliest goals of X4DESO was to provide modular add-ons, so users could install only what they wanted.

To that end, the following independent modules exist. When it makes sense they will auto-detect one another and interact accordingly.

- **X4D_Core** - A LibStub-compatible Framework for Developing Add-Ons for ESO, All X4D Add-Ons depend on this Framework.
- **X4D_Bank** - Performs regular bank deposits of items and gold based on user-configured options.
- **X4D_Chat** - Modifies Chat to show Character Names in Guild Chat, and adds timestamps to all chat messages, supports color stripping, text clean-up. All features optional.
- **X4D_LibAntiSpam** - An Anti-Spam Library that can be used to perform basic pattern/flood spam filtering.
- **X4D_Loot** - Displays looted Items in Chat Window, including Quest Items, Stack Counts, Item Icons and Monetary transactions.
- **X4D_Mail** - Provides minor Mail enhancements, namely integrating 'LibAntiSpam', performing auto-accepting mail attachments and auto-deleting system-generated mail.
- **X4D_Vendors** - Launder and Sell items at Merchants and Fences.
- **X4D_XP** - Shows XP Gains in the Chat Window.
- **X4D_UI** - Provides additional UI elements to the game, such as a Status Bar Window
- **X4D_MiniMap** - (ALPHA PREVIEW) Adds a 'minimap' to the game (disabled by default until 'stable' quality.)

All of them are optional, except for X4D_Core, which all other X4D Add-ons depend on and it is thus required.


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



