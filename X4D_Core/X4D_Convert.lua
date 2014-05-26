local X4D_Convert = LibStub:NewLibrary('X4D_Convert', 1000)
if (not X4D_Convert) then
	return
end

local _chatChannelCategories = {
	[CHAT_CHANNEL_EMOTE] = CHAT_CATEGORY_EMOTE,
	[CHAT_CHANNEL_GUILD_1] = CHAT_CATEGORY_GUILD_1,
	[CHAT_CHANNEL_GUILD_2] = CHAT_CATEGORY_GUILD_2,
	[CHAT_CHANNEL_GUILD_3] = CHAT_CATEGORY_GUILD_3,
	[CHAT_CHANNEL_GUILD_4] = CHAT_CATEGORY_GUILD_4,
	[CHAT_CHANNEL_GUILD_5] = CHAT_CATEGORY_GUILD_5,
	[CHAT_CHANNEL_MONSTER_EMOTE] = CHAT_CATEGORY_MONSTER_EMOTE,
	[CHAT_CHANNEL_MONSTER_SAY] = CHAT_CATEGORY_MONSTER_SAY,
	[CHAT_CHANNEL_MONSTER_WHISPER] = CHAT_CATEGORY_MONSTER_WHISPER,
	[CHAT_CHANNEL_MONSTER_YELL] = CHAT_CATEGORY_MONSTER_YELL,
	[CHAT_CHANNEL_OFFICER_1] = CHAT_CATEGORY_OFFICER_1,
	[CHAT_CHANNEL_OFFICER_2] = CHAT_CATEGORY_OFFICER_2,
	[CHAT_CHANNEL_OFFICER_3] = CHAT_CATEGORY_OFFICER_3,
	[CHAT_CHANNEL_OFFICER_4] = CHAT_CATEGORY_OFFICER_4,
	[CHAT_CHANNEL_OFFICER_5] = CHAT_CATEGORY_OFFICER_5,
	[CHAT_CHANNEL_PARTY] = CHAT_CATEGORY_PARTY,
	[CHAT_CHANNEL_SAY] = CHAT_CATEGORY_SAY,
	[CHAT_CHANNEL_SYSTEM] = CHAT_CATEGORY_SYSTEM,
	[CHAT_CHANNEL_USER_CHANNEL_1] = CHAT_CATEGORY_PARTY,
	[CHAT_CHANNEL_USER_CHANNEL_2] = CHAT_CATEGORY_PARTY,
	[CHAT_CHANNEL_USER_CHANNEL_3] = CHAT_CATEGORY_PARTY,
	[CHAT_CHANNEL_USER_CHANNEL_4] = CHAT_CATEGORY_PARTY,
	[CHAT_CHANNEL_USER_CHANNEL_5] = CHAT_CATEGORY_PARTY,
	[CHAT_CHANNEL_USER_CHANNEL_6] = CHAT_CATEGORY_PARTY,
	[CHAT_CHANNEL_USER_CHANNEL_7] = CHAT_CATEGORY_PARTY,
	[CHAT_CHANNEL_USER_CHANNEL_8] = CHAT_CATEGORY_PARTY,
	[CHAT_CHANNEL_USER_CHANNEL_9] = CHAT_CATEGORY_PARTY,
	[CHAT_CHANNEL_WHISPER] = CHAT_CATEGORY_WHISPER_INCOMING,
	[CHAT_CHANNEL_WHISPER_NOT_FOUND] = CHAT_CATEGORY_OUTGOING,
	[CHAT_CHANNEL_WHISPER_SENT] = CHAT_CATEGORY_WHISPER_OUTGOING,
	[CHAT_CHANNEL_YELL] = CHAT_CATEGORY_YELL,
	[CHAT_CHANNEL_ZONE] = CHAT_CATEGORY_ZONE,
	[CHAT_CHANNEL_ZONE_LANGUAGE_1] = CHAT_CATEGORY_ZONE_ENGLISH,
	[CHAT_CHANNEL_ZONE_LANGUAGE_2] = CHAT_CATEGORY_ZONE_FRENCH,
	[CHAT_CHANNEL_ZONE_LANGUAGE_3] = CHAT_CATEGORY_ZONE_GERMAN,
}

local _chatCategoryChannels = {}

for ch,ca in pairs(_chatChannelCategories) do
	_chatCategoryChannels[ca] = ch
end

function X4D_Convert.ChannelToCategory(self, channel)
	return _chatChannelCategories[channel] or CHAT_CATEGORY_SYSTEM
end

function X4D_Convert.CategoryToChannel(self, category)
	return _chatCategoryChannels[category] or CHAT_CHANNEL_SYSTEM
end
