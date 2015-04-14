# X4D ESO Add-Ons

A collection of LibStub-compatible Add-Ons that provide minor enhancements.

### Dependencies

- LibStub *(Optional)*
- LibAddonMenu-2.0 **(Required)**

### Modules

One of the earliest goals of X4DESO was to provide modular add-ons, so users could install only what they wanted.

To that end, the following independent modules exist. When it makes sense they will auto-detect one another and interact accordingly.

- **X4D_Core** - A LibStub-compatible Framework for Developing Add-Ons for ESO, All X4D Add-Ons depend on this Framework.
- **X4D_Bank** - Performs regular bank deposits of items and gold based on user-configured options.
- **X4D_Chat** - Modifies Chat to show Character Names in Guild Chat, and adds timestamps to all chat messages, supports color stripping, text clean-up. All features optional.
- **X4D_LibAntiSpam** - An Anti-Spam Library that can be used to perform basic pattern/flood spam filtering.
- **X4D_Loot** - Displays looted Items in Chat Window, including Quest Items, Stack Counts, Item Icons and Monetary transactions.
- **X4D_Mail** - Provides minor Mail enhancements, namely integrating 'LibAntiSpam', performing auto-accepting mail attachments and auto-deleting system-generated mail.
- **X4D_XP** - Shows XP Gains in the Chat Window.

All of them are optional, except for X4D_Core, which all other X4D Add-ons depend on and it is thus required.

