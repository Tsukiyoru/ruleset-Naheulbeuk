-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addLinkToBattle(nodeBattle, sLinkClass, sLinkRecord, nCount)
	local sTargetNPCList = LibraryData.getCustomData("battle", "npclist") or "npclist";

	if sLinkClass == "battle" then
		for _,nodeSrcNPC in pairs(DB.getChildren(DB.getPath(sLinkRecord, sTargetNPCList))) do
			local nodeTargetNPC = DB.createChild(DB.getChild(nodeBattle, sTargetNPCList));
			DB.copyNode(nodeSrcNPC, nodeTargetNPC);
			if nCount then
				DB.setValue(nodeTargetNPC, "count", "number", DB.getValue(nodeTargetNPC, "count", 1) * nCount);
			end
		end
	else
		local bHandle = false;
		if LibraryData.isRecordDisplayClass("npc", sLinkClass) then
			bHandle = true;
		else
			local aCombatClasses = LibraryData.getCustomData("battle", "acceptdrop") or { "npc" };
			if StringManager.contains(aCombatClasses, sLinkClass) then
				bHandle = true;
			end
		end

		if bHandle then
			local sName = DB.getValue(DB.getPath(sLinkRecord, "name"), "");

			local nodeTargetNPC = DB.createChild(DB.getChild(nodeBattle, sTargetNPCList));
			DB.setValue(nodeTargetNPC, "count", "number", nCount or 1);
			DB.setValue(nodeTargetNPC, "name", "string", sName);
			DB.setValue(nodeTargetNPC, "link", "windowreference", sLinkClass, sLinkRecord);
			
			local sToken = DB.getValue(DB.getPath(sLinkRecord, "token"), "");
			if sToken == "" or not Interface.isToken(sToken) then
				local sLetter = StringManager.trim(sName):match("^([a-zA-Z])");
				if sLetter then
					sToken = "tokens/Medium/" .. sLetter:lower() .. ".png@Letter Tokens";
				else
					sToken = "tokens/Medium/z.png@Letter Tokens";
				end
			end
			DB.setValue(nodeTargetNPC, "token", "token", sToken);
		else
			return false;
		end
	end
	
	return true;
end
