# X4D **Vendors**

A LibStub-compatible Add-on that interacts with Vendors and Fences, performing Laundering and Sales on your behalf.


## Features

- Options to Auto-Sell/Launder Items by Pattern Matching (pattern matching is identical to 'Bank Ignore List')
- Tracks Money In, Money Out, and reports results of Auto-Sell/Launder (if any)


## Planned

- 'Vendor Action' Options by Item Type, configured similar to Bank Addon (i.e. via drop-downs.) 
- Option to Auto-Repair Equipped/All/None


## Installation

Open the Archive and copy the **X4D_Vendors** folder into **%USERPROFILE%\Documents\Elder Scrolls Online\live\Addons\** folder.

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

v1.5

- stolen items are no longer auto-laundered on fresh addon installs. however, lockpicks, motifs, legendarys, artifacts and arcane items still are.
- fixed bug where no items would be laundered once salesmax was reached.
- added option to launder items which would normally be sold when there would be no profit
- Misc updates for Core v1.13

v1.4

- Fixed bug where items would not actually sell to fences when they were supposed to.

v1.3

- Added option to switch settings between "Account-Wide" and "Per-Character", defaulting to "Per-Character"
- Fix bug between fence transaction submission and fence transaction counts not being synchronizedS
- Misc updates for Core v1.10

v1.2

- Will no longer attempt to launder items where there are insufficient funds available, condquently does not show incorrect earnings report for failed launder attempts.

v1.1

- Now you can conduct transactions based on item type settings similar to [bank] addon (keep/sell patterns still take precedence)
- Now tracking map/zone in Vendor DB
- Adopted use of zo_strformat where appropriate.
- Integration with recent X4D Core library changes (icons, items, bags, etc)

v1.0

- Initial release.
- Options to Auto-Sell/Launder Items by Pattern Matching (pattern matching is identical to 'Bank Ignore List')
- Tracks Money In, Money Out, and reports results of Auto-Sell/Launder (if any)
- Added Persistent Vendors DB
