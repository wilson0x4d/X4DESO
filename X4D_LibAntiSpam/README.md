# X4D LibAntiSpam

A LibStub-compatible Anti-Spam Library that can be used from Chat Mods, Mail Mods, etc.

Can also be used as a Stand-Alone Chat Mod to filter 'spammers' and 'flooders'.

## Features

- Can be used as a stand-alone Add-On to auto-filter Spammers from Chat.
- Does not clog up your in-game ignore list.
- Does not your block guild members, group members, nor friends.
- Optional. Detects Flooders (people who repeat the same thing, over and over, and do nothing but clutter chat.)
- Optional. Detects Spammer Domains, Words/Phrases and ASCII ART using and internal set of patterns.
- User can add/edit their own patterns.
- Addon authors can use via LibStub to implement spam/flood detection, without having to write the code to do it (such as other chat mods, like **X4D Chat**, or mail mods, like **X4D Mail**.

## Planned Features

* Ignore List Editor, and persistence via X4D_DB Module.
* "Guild Recruitment Spam" filtering, disabled by default.

## Installation

Open the Archive and copy the **X4D_LibAntiSpam** folder into **%USERPROFILE%\Documents\Elder Scrolls Online\live\Addons\** folder.

If ESO is already running, execute **/reloadui** command.

## User Patterns

Users can define their own anti-spam patterns in the Settings UI. Each pattern must appear on a separate line to work correctly. If you're not sure, enter extra blank lines, the Add-On will strip them out on the next reload.

### LUA Pattern Matching

LibAntiSpam Patterns are similar to LUA Patterns, thus you may find the following resources useful:

* http://www.lua.org/pil/20.2.html
* http://lua-users.org/wiki/PatternsTutorial

### Normalization and Original Text

Patterns are applied to Normalized Text as well as Original Text, and are used to filter Chat, Guild Invite, and Mail spam.

Normalization is the process of taking otherwise codified text and translating it into a human-readable equivalent, for example translating "\/\/*V\/*\/V*G*0*I*D*3*X*P*R*3*5*5*(*0*|V|" into "wwwgoldexpresscom". This makes pattern construction much easier, since most of the time users can enter a snippet from the normalized text and NOT have to worry about constructing a LUA Pattern (Fx. to block the above "spam" text, you would enter "goldexpress" on a new line in the Settings UI.)


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
