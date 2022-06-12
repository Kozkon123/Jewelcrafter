local TOCNAME,JC=...

--Options
-------------------------------------------------------------------------------------
function JC.UpdateTags()
	-- Undecided if I should keep this in or not
	--[[ 
		for k, v in pairs(JC.DB.Custom) do 
		if v == nil or v == "" then
			local txt = JC.Tool.Combine(JC.RecipeTags["jeGB"][k],",")
			JC.DB.Custom[k] = txt
		end
	end
--]]
	for k, _ in pairs(JC.DBChar.RecipeList) do
		if JC.DB.Custom[k] ~= nil and JC.DB.Custom[k] ~= "" then
			JC.DBChar.RecipeList[k] = JC.Tool.Split(JC.DB.Custom[k]:lower(),",")
		end
	end
end

function JC.DefaultCustomTags()

	JC.RecipeTags = JC.DefaultRecipeTags
	for k,v in pairs(JC.RecipeTags["jeGB"]) do
		local txt = JC.Tool.Combine(JC.RecipeTags["jeGB"][k],",")
		JC.DB.Custom[k] = txt
	end

end

function JC.Default()
	JC.JewelcrafterTags = JC.DefaultJewelcrafterTags
	JC.PrefixTags = JC.DefaultPrefixTags
	JC.RecipeTags = JC.DefaultRecipeTags
	JC.DefaultCustomTags()
end

function JC.OptionsUpdate() 

	JC.UpdateTags()
	JC.BlackList = JC.Tool.Split(JC.DB.Custom.BlackList:lower(), ",")
	JC.PrefixTags = JC.Tool.Split(JC.DB.Custom.SearchPrefix:lower(), ",")
	JC.JewelcrafterTags = JC.Tool.Split(JC.DB.Custom.GenericPrefix:lower(), ",")
end

function JC.OptionsInit ()
	JC.Options.Init(
		function() -- ok button			
			JC.Options.DoOk() 
			JC.OptionsUpdate()	
		end,
		function() -- Chancel/init button
			JC.Options.DoCancel() 
		end, 
		function() -- default button
			JC.Options.DoDefault()
			JC.OptionsUpdate()	
		end
		)
	
	JC.Options.SetScale(0.85)

	-- Tags Tab
	JC.Options.AddPanel("Jewelcrafter",false,true)
	
	JC.Options.AddCategory("General Options")
	JC.Options.Indent(10)
	JC.Options.InLine()
	JC.Options.AddCheckBox(JC.DB, "AutoInvite", true, "Auto Invite")
	--JC.Options.AddCheckBox(JC.DB, "NetherRecipes", false, "Disable Nether Recipes")
	JC.Options.AddCheckBox(JC.DB, "WhisperLfRequests", false, "Reply to LF Jewelcrafter requests")
	JC.Options.EndInLine()
	JC.Options.Indent(-10)
	JC.Options.AddSpace()

	-- Delay timers for auto behavior
	JC.Options.AddEditBox(JC.DB, "WhisperTimeDelay", 0, "WhisperTimeDelay", 50, nil, true)
	JC.Options.AddEditBox(JC.DB, "InviteTimeDelay", 0, "InviteTimeDelay", 50, nil, true)

	JC.Options.AddCategory("Search Patterns")
	JC.Options.Indent(10)
	JC.Options.AddText('Enter your own unique search patterns here. You must use "," (comma) as the seperator with no space after it', 450+200)
	JC.Options.AddSpace()

	-- Message String
	JC.Options.AddEditBox(JC.DB, "MsgPrefix", "I can cut ", "Message Prefix", 445, 200, false)

	-- LF Jewelcrafter Msg String
	JC.Options.AddEditBox(JC.DB, "LfWhisperMsg", "What you looking for?", "Generic request wisper message", 445, 200, false)
	JC.Options.AddSpace()

	local prefixTags = JC.Tool.Combine(JC.PrefixTags, ",")
	JC.Options.AddEditBox(JC.DB.Custom, "SearchPrefix", prefixTags, "Prefix to search for", 445, 200, false)

	local genericSearchWords = JC.Tool.Combine(JC.JewelcrafterTags, ",")
	JC.Options.AddEditBox(JC.DB.Custom, "GenericPrefix", genericSearchWords, "Generic request match phrases", 445, 200, false)

	-- Blacklist
	JC.Options.AddEditBox(JC.DB.Custom, "BlackList", "", "BlackList", 445, 200, false)	
	JC.Options.AddSpace()

	-- Recipe Tags
	for k,v in pairs(JC.RecipeTags["jeGB"]) do
		local txt = JC.Tool.Combine(JC.RecipeTags["jeGB"][k],",")
		JC.Options.AddEditBox(JC.DB.Custom, k, txt, k, 445, 200, false)
	end

	JC.OptionsUpdate() 
end
