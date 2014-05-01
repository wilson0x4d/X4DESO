# X4D LibAntiSpam

A LibStub-compatible Anti-Spam Library that can be used from Chat Mods, Mail Mods, etc.

Can also be used as a Stand-Alone Chat Mod to filter 'spammers' and 'flooders'.

## Features

* Does not clog up your in-game ignore list.
* Detects Flooders
* Detects Spammer Domains
* Detects Spammer Words/Phrases
* Spam Dictionary is User Editable
* Can be used from other Add-Ons, such as **X4D Chat**, hopefully others (requires author support.)
* Can be used as a stand-alone Add-On to auto-filter Spammers and Flooders from Chat.

## Planned Features

* Spam Dictionary Sync (share your spam dictionary your Guild, your Friends, etc)

## Installation

Open the Archive and copy the **X4D_LibAntiSpam** folder into **%USERPROFILE%\Documents\Elder Scrolls Online\live\Addons\** folder.

If ESO is already running, execute **/reloadui** command.

## Versions
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
