local TOCNAME,JC=...
Jewelcrafter_Addon=JC


JC.Initalized = false
JC.PlayerList = {}
JC.LfRecipeList = {}
JC.JewelcrafterTags = JC.DefaultJewelcrafterTags
JC.PrefixTags = JC.DefaultPrefixTags
JC.RecipeTags = JC.DefaultRecipeTags
--JC.RecipesWithNether = {"Enchant Boots - Surefooted"}

-- Scans the users known recipes and stores them
-- Additionally it also stores the recipes clickable link, that will be used when messaging the user (for those people asks what are the mats?)
function JC.GetItems()
	JC.DBChar.RecipeList = {}
	JC.DBChar.RecipeLinks = {}

	CastSpellByName("Jewelcrafting")
	for i = 1, GetNumTradeSkills(), 1 do
		local skillName, skillType, numAvailable = GetTradeSkillInfo(i);
		if (skillType ~= "header") then
			if JC.RecipeTags["jeGB"][skillName] ~= nil then 
				JC.DBChar.RecipeLinks[skillName] = GetTradeSkillRecipeLink(i)
				JC.DBChar.RecipeList[skillName] = JC.RecipeTags["jeGB"][skillName]
			end
		end
	end
end

function JC.Init()

	-- Initalize options
	if not JewelcrafterDB then JewelcrafterDB = {} end -- fresh DB
	if not JewelcrafterDBChar then JewelcrafterDBChar = {} end -- fresh DB
	
	JC.DB=JewelcrafterDB
	JC.DBChar=JewelcrafterDBChar

	-- Initialize DB Variables if not set
	if not JC.DBChar.RecipeList then JC.DBChar.RecipeList = {} end
	if not JC.DBChar.RecipeLinks then JC.DBChar.RecipeLinks = {} end
	if not JC.DB.Custom then JC.DB.Custom={} end
	if not JC.DBChar.Stop then JC.DBChar.Stop = false end
	if not JC.DBChar.Debug then JC.DBChar.Debug = false end

	JC.Tool.SlashCommand({"/jc", "/jewelcrafter", "/j"},{
		{"scan","MUST BE RAN PRIOR TO /jc start. Scans and stores your Jewelcrafting recipes to be used when filter for requests. NOTE: You need to rerun this when you learn new recipes",function()
			JC.GetItems()
			print("Scan Completed")
			end},
		{{"stop", "pause"},"Pauses addon",function()
			JC.DBChar.Stop = true
			print("Paused")
		end},
		{"start","Starts the addon. It will begin parsing chat looking for requests",function()
			JC.DBChar.Stop = false
			print("Started...")
		end},
		{{"default", "reset"},"Resets everything to default values",function()
			JC.Default()
			JC.UpdateTags()
			print("Reset complete")
		end},
		{{"config","setup","options"},"Settings",JC.Options.Open,1},
		{"debug","Enables/Disabled debug messages",function()
			if JC.DBChar.Debug== true then
				JC.DBChar.Debug = false
				print("Debug mode is now off")
			else 
				JC.DBChar.Debug = true
				print("Debug mode is now on")
			end
		end},
		{{"about", "usage"},"You need to first run /j scan this will store your known recipes and will be parsing chat for them (only need to do it 1 time or if you learned new recipes) after run /e start to start looking for requests"},
	})

	JC.OptionsInit()
    JC.Initalized = true

	print("|cFFFF1C1C Loaded: "..GetAddOnMetadata(TOCNAME, "Title") .." ".. GetAddOnMetadata(TOCNAME, "Version") .." by "..GetAddOnMetadata(TOCNAME, "Author"))
end

-- Sends a msg with the Jewelcrafting links that Jewelcrafter is capable of doing
function JC.SendMsg(name)
		if JC.LfRecipeList[name] ~= nil then
			-- Iterates over the matches requested Jewelcrafts (that is capable of doing) adds them to the message
			local msg = JC.DB.MsgPrefix
			for k, _ in pairs(JC.LfRecipeList[name]) do 
				msg = msg .. JC.DBChar.RecipeLinks[k]
			end
			SendChatMessage(msg, "WHISPER", nil, name)
			JC.LfRecipeList[name] = nil -- Clearing it so it doesn't growing larger unnecessarily 
		end
end

-- For a message it will attempt to filter the request based on any of the words in JC.PrefixTags
-- If the message contains any of those words it will then attempt to check if any of the users recipes(tags) are contained in the message
-- If their is, it will then invite and message the user with a link to all desired recipes that the Jewelcrafter is capable of doing
function JC.ParseMessage(msg, name)
	if JC.Initalized==false or name==nil or name=="" or msg==nil or msg=="" or string.len(msg)<4 or JC.DBChar.Stop == true then
		return
	end

	local isRequestValid = false
	for _, v in pairs(JC.PrefixTags) do 
		if string.find(msg:lower(), "%f[%w_]" .. v .. "%f[^%w_]") then -- Important so it doesn't match things like LFW
			isRequestValid = true
		end
	end

	for _, v in pairs (JC.BlackList) do 
		if string.find(msg:lower(), "%f[%w_]" .. v .. "%f[^%w_]") then
			if JC.DBChar.Debug == true then
				print("Request: " .. msg .. " is being blacklisted due to tag: " .. v)
			end
			isRequestValid = false
		end
	end

	if isRequestValid == false then return end
	local shouldInvite = false

	-- The storing of the recipe links is really un-needed (leftover from another iteration) but I'm too lazy to change the code
	for k, v in pairs(JC.DBChar.RecipeList) do
		for _, v2 in pairs(v) do
		if string.find(msg:lower(), v2, 1, true) then
			if not JC.LfRecipeList[name] then JC.LfRecipeList[name] = {} end
			if JC.DBChar.Debug == true then
				print("User should be invited for msg: " .. msg)
				print("Due to tag: " .. v2)
			end
			shouldInvite = true
			JC.LfRecipeList[name][k] = v2
			end 
		end
	end
	
	if shouldInvite == true then
		-- This check is in case there is a bug and it wrongly matches we don't continue spamming invite to the same user every time they post
		if JC.PlayerList[name] == nil then 
			if JC.DBChar.Debug == true then
				print("Inviting Player: " .. name .. " for request: " .. msg)
			end

			JC.PlayerList[name] = 1

			if JC.DB.AutoInvite then
				C_Timer.After(JC.DB.InviteTimeDelay, function() InviteUnit(name) end)

			end
			-- Reason for whispering them before the join the group is in case they are already in a group
			C_Timer.After(JC.DB.WhisperTimeDelay, function() JC.SendMsg(name) end)
		else
			-- Due to the laziness of keeping the whole recipe storage thing, this is an optimization to clear it for users that have already been invited
			JC.LfRecipeList[name] = nil
		end
	elseif JC.DB.WhisperLfRequests and isRequestValid and JC.PlayerList[name] == nil then
	
		local isGenericJewelcraftRequest = false
		local stripedMsg = string.gsub(msg:lower(), "%s+", "")
		for _, v in pairs(JC.JewelcrafterTags) do
			local stripedTag = string.gsub(v:lower(), "%s+", "")
			if stripedTag == stripedMsg then
				isGenericJewelcraftRequest = true
			end
		end

		if isGenericJewelcraftRequest then 
			JC.PlayerList[name] = 1
			C_Timer.After(JC.DB.WhisperTimeDelay, function() SendChatMessage(JC.DB.LfWhisperMsg, "WHISPER", nil, name) end)
		end
	end
end


local function Event_CHAT_MSG_CHANNEL(msg,name,_3,_4,_5,_6,_7,channelID,channel,_10,_11,guid)
	if not JC.Initalized then return end
	--[[ To be used later when I add an option to select which channels to parse from
	if channelID ~= 4 then
		JC.ParseMessage(msg, name)
	end
	--]]
	JC.ParseMessage(msg, name)
end

local function Event_ADDON_LOADED(arg1)
	if arg1 == TOCNAME then
		JC.Init()
	end
end

function JC.OnLoad()
    JC.Tool.RegisterEvent("ADDON_LOADED",Event_ADDON_LOADED)
	JC.Tool.RegisterEvent("CHAT_MSG_CHANNEL",Event_CHAT_MSG_CHANNEL)
	JC.Tool.RegisterEvent("CHAT_MSG_SAY",Event_CHAT_MSG_CHANNEL)
	JC.Tool.RegisterEvent("CHAT_MSG_YELL",Event_CHAT_MSG_CHANNEL)
	JC.Tool.RegisterEvent("CHAT_MSG_GUILD",Event_CHAT_MSG_CHANNEL)
	JC.Tool.RegisterEvent("CHAT_MSG_OFFICER",Event_CHAT_MSG_CHANNEL)
end

