-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	DB.onImport = onImport;
end

--
-- Drop handling
--

function handleFileDrop(sTarget, draginfo)
	if not User.isHost() then
		return;
	end
	
	if sTarget == "image" then
		Interface.addImageFile(draginfo.getStringData());
		return true;
	end
end

function handleDrop(sTarget, draginfo)
	if CampaignDataManager2 and CampaignDataManager2.handleDrop then
		if CampaignDataManager2.handleDrop(sTarget, draginfo) then
			return true;
		end
	end
	
	if not User.isHost() then
		return;
	end
	
	if sTarget == "image" then
		ChatManager.SystemMessage(Interface.getString("image_message_nocopy"));
		return true;
	elseif sTarget == "item" then
		ItemManager.handleAnyDrop(DB.createNode("item"), draginfo);
		return true;
	elseif sTarget == "combattracker" then
		local sClass, sRecord = draginfo.getShortcutData();
		if sClass == "charsheet" then
			CombatManager.addPC(draginfo.getDatabaseNode());
			return true;
		elseif sClass == "npc" then
			CombatManager.addNPC(sClass, draginfo.getDatabaseNode());
			return true;
		elseif sClass == "battle" then
			CombatManager.addBattle(draginfo.getDatabaseNode());
			return true;
		end
	elseif sTarget == "charsheet" then
		local sClass, sRecord = draginfo.getShortcutData();
		if sClass == "pregencharsheet" then
			addPregenChar(DB.findNode(sRecord));
			return true;
		end
	else
		local sClass, sRecord = draginfo.getShortcutData();

		local bAllowEdit = LibraryData.allowEdit(sTarget);
		if bAllowEdit then
			local sDisplayClass = LibraryData.getRecordDisplayClass(sTarget);
			local sRootMapping = LibraryData.getRootMapping(sTarget);

			local bCopy = false;
			if ((sRootMapping or "") ~= "") then
				if ((sDisplayClass or "") == sClass) then
					bCopy = true;
				elseif ((sTarget == "story") and (sClass == "note")) then
					bCopy = true;
				elseif ((sTarget == "note") and (sClass == "encounter")) then
					bCopy = true;
				end
			end
			if bCopy then
				local nodeSource = DB.findNode(sRecord);
				local nodeTarget = DB.createChild(sRootMapping);
				DB.copyNode(nodeSource, nodeTarget);
				DB.setValue(nodeTarget, "locked", "number", 1);
				return true;
			end
		end
	end
end

--
-- Character manaagement
--

function importChar()
	local sFile = Interface.dialogFileOpen();
	if sFile then
		DB.import(sFile, "charsheet", "character");
		ChatManager.SystemMessage(Interface.getString("message_slashimportsuccess") .. ": " .. sFile);
	end
end

function importNPC()
	local sFile = Interface.dialogFileOpen();
	if sFile then
		DB.import(sFile, "npc", "npc");
		ChatManager.SystemMessage(Interface.getString("message_slashimportnpcsuccess") .. ": " .. sFile);
	end
end

function onImport(node)
	local aPath = StringManager.split(node.getNodeName(), ".");
	if #aPath == 2 and aPath[1] == "charsheet" then
		if DB.getValue(node, "token", ""):sub(1,9) == "portrait_" then
			DB.setValue(node, "token", "token", "portrait_" .. node.getName() .. "_token");
		end
	end
end

function exportChar(nodeChar)
	local sFile = Interface.dialogFileSave();
	if sFile then
		if nodeChar then
			DB.export(sFile, nodeChar, "character");
			ChatManager.SystemMessage(Interface.getString("message_slashexportsuccess") .. ": " .. DB.getValue(nodeChar, "name", ""));
		else
			DB.export(sFile, "charsheet", "character", true);
			ChatManager.SystemMessage(Interface.getString("message_slashexportsuccess"));
		end
	end
end

function setCharPortrait(nodeChar, sPortraitFile)
	if not nodeChar or not sPortraitFile then
		return;
	end
	
	User.setPortrait(nodeChar, sPortraitFile);
	
	local sToken = DB.getValue(nodeChar, "token", "");
	if nodeChar and ((sToken == "") or (sToken:sub(1,9) == "portrait_")) then
		DB.setValue(nodeChar, "token", "token", "portrait_" .. nodeChar.getName() .. "_token");
	end
	
	local wnd = Interface.findWindow("charsheet", nodeChar)
	if wnd then
		if User.isLocal() then
			if wnd.localportrait then
				wnd.localportrait.setFile(sPortraitFile);
			end
		else
			if wnd.portrait then
				wnd.portrait.setIcon("portrait_" .. nodeChar.getName() .. "_charlist", true);
			end
		end
	end
	
	wnd = Interface.findWindow("charselect_client", "");
	if wnd then
		for _, v in pairs(wnd.list.getWindows()) do
			if v.localdatabasenode then
				if v.localdatabasenode == nodeChar then
					if v.localportrait then
						v.localportrait.setFile(sPortraitFile);
					end
				end
			end
		end
	end
end

function addPregenChar(nodeSource)
	if CampaignDataManager2 and CampaignDataManager2.addPregenChar then
		CampaignDataManager2.addPregenChar(nodeSource);
		return;
	end
	
	local nodeTarget = DB.createChild("charsheet");
	DB.copyNode(nodeSource, nodeTarget);

	ChatManager.SystemMessage(Interface.getString("pregenchar_message_add"));
end

--
-- Encounter management
--

function generateEncounterFromRandom(nodeSource)
	if not nodeSource then
		return;
	end
	
	local sDisplayClass = LibraryData.getRecordDisplayClass("battle");
	local sRootMapping = LibraryData.getRootMapping("battle");
	if ((sRootMapping or "") == "") then
		return;
	end
	
	local nodeTarget = DB.createChild(sRootMapping);
	DB.copyNode(nodeSource, nodeTarget);
	
	local aDelete = {};
	local sTargetNPCList = LibraryData.getCustomData("battle", "npclist") or "npclist";
	for _,nodeNPC in pairs(DB.getChildren(nodeTarget, sTargetNPCList)) do
		local sExpr = DB.getValue(nodeNPC, "expr", "");
		DB.deleteChild(nodeNPC, "expr");
		
		sExpr = sExpr:gsub("$PC", tostring(PartyManager.getPartyCount()));
		
		local nCount = StringManager.evalDiceMathExpression(sExpr);
		DB.setValue(nodeNPC, "count", "number", nCount);
		if nCount <= 0 then
			table.insert(aDelete, nodeNPC);
		end
	end
	for _,nodeDelete in ipairs(aDelete) do
		nodeDelete.delete();
	end
	DB.setValue(nodeTarget, "locked", "number", 1);

	if CampaignDataManager2 and CampaignDataManager2.onEncounterGenerated then
		CampaignDataManager2.onEncounterGenerated(nodeTarget);
	end
	
	Interface.openWindow(sDisplayClass, nodeTarget);
end
