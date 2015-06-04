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

v1.64

- Integrated Stopwatch module for profiling misc code.

v1.63

- Removed unnecessary debug output.
- Misc updates for Core v1.10

v1.62

- Relocation of player data out of AntiSpam and into Core.

v1.61

- Memory optimizations.

v1.60

- Moved 'Aggressive' patterns into separate setting.
- Reworked defaults.

v1.59

- ESO Update 6
- Removed LibAddonMenu from /lib/ folder
- Depends On: X4D_Core, LibAddonMenu-2.0

v1.58

- Modified Patterns.
- ESO version update

v1.57

- Fix bug where normalized output would be displayed for a player already marked as a spammer.
- Workaround for "patterns bug" some users experience after upgrading.
- Modified Scrub.
- New Patterns.

v1.56

- Modified Scrub.

v1.55

- Modified Scrub.

v1.54

- Adding more [DEV] output to assist with pattern creation.
- Modified CharMap
- New Patterns.

v1.53

- Optimized Scrubs, and fixed a bug with item stripping.
- Optimized CharMap Lookup.

v1.52

- Flood Time increment changed from 30 seconds to 5 seconds so users can choose a lower setting.
- Modified Scrub.
- Modified CharMap.
- Modified Patterns.

v1.51

- Modified Scrub.

v1.50

- Fix bad reference to LibAddonMenu.

v1.49

- Modified Scrub.

v1.48

- Modified Scrub.

v1.47

- Modified Scrub.

v1.46

- Modified CharMap.
- Modified Patterns.

v1.45

- Default Patterns now termed "Internal Patterns".
- New option to disable use of "Internal Patterns".
- Previous "Spam Patterns" option is now termed "User Patterns".
- User Patterns and Internal Patterns were separated to solve the problem of some users running out of space for custom patterns.

v1.44

- Modified CharMap.

v1.43

- Fix Chat Flood notifications are no longer displayed when you disable notifications.
- New Pattern.

v1.42

- Fix so Spammers also caught flooding is not double-notified to the user.
- Modified Patterns.
- Updated Scrubs.

v1.41

- Fixed a bug in flood check code.
- Increased max 'Flood Time' value to 900 seconds (equivalent to 15 minutes)

v1.40

- Increased pattern limit.
- Updated Scrubs.

v1.39

- Modified Patterns and Scrubs.

v1.38

- Modified Patterns.

v1.37

- Modified Patterns and CharMap.

v1.36

- Modified Patterns.
- Changed color on spam notifications.

v1.35

- Modified Patterns and CharMap.

v1.34

- Flood messages are no longer repeated for every message, and do not require [DEV] option to be enabled.
- Fixed a bug where players were permanently marked as flooders, which was never intended.
- Changed 'Flood Time' Slider Min Value to 0, when '0' Flooder checks are disabled.
- The pattern which matched a spammer is now reported alongside the spammer name.
- The text which matched a pattern is now highlighted in normalized text output for debugging purposes.
- Modified Scrub.
- Modified Patterns.

v1.33

- Integrated into latest version of X4D_Chat to provide timestamp support.
- Added Chat Emit Callback support, other add-ons can now capture the messages LibAntiSpam emits and write them to custom chat frames, etc.

v1.32

- Modified Patterns.

v1.31

- New Pattern.

v1.30

- Modified Patterns.

v1.29

- New Pattern.

v1.28

- Modified Patterns.

v1.27

- Modified flood check to not match a zero-length string.
- Modified Patterns.
- [DEV] option now outputs Add-On Version along with all normalized text.

v1.26

- Modified Patterns.

v1.25

- Modified Patterns.

v1.24

- Modified Scrubbers.

v1.23

- Updated CharMap.
- Updated Patterns.
- Added message for when player is blocked for flooding (as opposed to spamming)

v1.22

- Fix Spam Check. 

v1.21

- Fix Flooder Check.

v1.20

- Auto-Whitelist for Self, Friends, Group Members and Guild Members.
- Modified Patterns, removed a pattern that would catch too many non-spammers.
- Modified Scrubbers, added a large utf8 scrub list based on a modification of Kyle Smith's "utf8.lua"

v1.19

- Modified Patterns.

v1.18

- New Spam Patterns.
- Sliding Expiry for 'Flooding' is only extended when user continues flooding same text, different text does not extend expiry.
- Simplified Scrubbers and Aggregation.
- Normalization output now shows Player/Character Name of sender.
- Fix a bug with monster names not writing out to chat.

v1.17

- Removed debug lines accidentally left in the code (oops!)

v1.16

- Modified Patterns to be more restrictive.
- Added new spam Patterns.
- Modified Scrubbers to deal with link-based spam.

v1.15

- Modified Patterns.

v1.14

- Modifications to text scrubbers.
- Spammer notification now only occurs once per spammer, rather than for every message detected.
- Spammer notifications are again enabled by default to promote reporting by users.
- Fixed a bug with SavedVars being reset for every release, what a horrible API.

v1.13

- New Algo for Line-Break Spammers.
- New Algo for Multi-Line Spammers.
- Boot in the Mouth for all Spammers.

v1.12

- New Spam Pattern.
- Fixed bug with Pattern Merge.

v1.11

- Automatic Pattern Merges on Add-On Load/Init - Users do not need to explicitly 'reset to defaults' to pick up new patterns.

v1.10

- Fix bug with Pattern Merge.
- Fix bug with GuildInvite 'nil' Error for uninitialized variable name.

v1.9

- Refactor of Patterns into a single list, implemented pattern merge (no longer lose your customized patterns when resetting to defaults, but still get NEW patterns added to Add-On.)
- Reworked Flood/Spam notifications so that the spammer names are links, you can now right-click to report spammers (if you wish.)
- Reworked Flood/Spam notifications so they are shown regardless of which Chat Add-On you are using, this option is still disabled by default.
- Refactored "Spammer Guild Invite" - previous version was notifying, but not actually declining the invites. Was not yet able to test.
- Updated spam definitions, and added a few additional mappings to charmap. Fixed a bug with charmap code not mapping certain characters correctly.
- Misc output window clean-up/colorization, only really matters for people who enable the output options.

v1.8

- Modified Spam Patterns based on feedback.

v1.7

- New Spam Pattern

v1.6

- Fix bug where Spam Notifications are always being sent. Quite annoying.

v1.5

- New Spam Definition
- Fixed bug with 'Reset to Defaults' which affected both UI and SavedVars.

v1.4

- additional definition for new spammer.
- fix a bug where spam dictionaries were being truncated when loaded into the settings UI.
- modified how spam and flood checks are performed, to better deal with spammers that pose as 'normal' chatters, and to filter out their 'non-spam' text as well.

v1.3

- Fix bug with Guild Invite Spam displaying debug text.
- Added option to display 'normalized' text for all checks, to assist with creating new patterns.
- Increased maximum possible flood time to 5 minutes, default is changed to 30 seconds.

v1.2

- Renamed LibStub registration as "LibAntiSpam" to facilitate polyfill creation.
- Deprecated 'IsSpam' method, add-on authors should use the new 'Check' method instead.
- Added support to Auto-Decline invites from 'Spammer Guilds'.

v1.1

- Adds additional mapping to catch a new spammer.

v1.0

- Initial release.
