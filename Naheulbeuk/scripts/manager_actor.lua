-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--
--  DATA STRUCTURES
--
-- rActor
--		sType
--		sName
--		sCreatureNode
-- 		sCTNode
--

function isPC(v)
	local sType = type(v);
	if sType == "string" then
		return StringManager.startsWith(v, "charsheet.");
	elseif sType == "databasenode" then
		return StringManager.startsWith(v.getPath(), "charsheet.");
	elseif sType == "table" then
		return (v.sType and v.sType == "pc");
	end
	return false;
end

function resolveActor(varActor)
	local sType = type(varActor);
	if sType == "table" then
		return varActor;
	elseif type(varActor) == "string" then
		if StringManager.startsWith(varActor, CombatManager.CT_MAIN_PATH .. ".") then
			return getActor("ct", varActor);
		elseif StringManager.startsWith(varActor, "charsheet.") then
			return getActor("pc", varActor);
		end
		return getActor("npc", varActor);
	elseif type(varActor) == "databasenode" then
		local sPath = varActor.getPath();
		if StringManager.startsWith(sPath, CombatManager.CT_MAIN_PATH .. ".") then
			return getActor("ct", varActor);
		elseif StringManager.startsWith(sPath, "charsheet.") then
			return getActor("pc", varActor);
		end
		return getActor("npc", varActor);
	end
	return nil;
end

function getActor(sActorType, varActor)
	-- GET ACTOR NODE
	local nodeActor = nil;
	if type(varActor) == "string" then
		if varActor ~= "" then
			nodeActor = DB.findNode(varActor);

			-- Note: Handle cases where PC targets another PC they do not own, 
			--     	which means they do not have access to PC record but they
			--		do have access to CT record.
			if not nodeActor and sActorType == "pc" then
				sActorType = "ct";
				nodeActor = CombatManager.getCTFromNode(varActor);
			end
		end
	elseif type(varActor) == "databasenode" then
		nodeActor = varActor;
	end
	if not nodeActor then
		return nil;
	end
	local sActorNode = nodeActor.getNodeName();

	-- Determine type unless specified
	if sActorType ~= "pc" and sActorType ~= "ct" and sActorType ~= "npc" then
		if isPC(nodeActor) then
			sActorType = "pc";
		else
			sActorType = "npc";
		end
	end
	
	-- BASED ON ORIGINAL ACTOR NODE, FILL IN THE OTHER INFORMATION
	local rActor = nil;
	if sActorType == "ct" then
		rActor = {};
		local sClass, sRecord = DB.getValue(nodeActor, "link", "", "");
		if sClass == "charsheet" then
			rActor.sType = "pc";
			rActor.sCreatureNode = sRecord;
		else
			rActor.sType = "npc";
			rActor.sCreatureNode = sActorNode;
		end
		rActor.sCTNode = sActorNode;
		rActor.sName = DB.getValue(nodeActor, "name", "");
		
	elseif sActorType == "pc" then
		rActor = {};
		rActor.sType = "pc";
		rActor.sCreatureNode = sActorNode;
		local nodeCT, sCTNode = CombatManager.getCTFromNode(nodeActor);
		rActor.sCTNode = sCTNode;
		if nodeCT then
			rActor.sName = DB.getValue(nodeCT, "name", "");
		else
			rActor.sName = DB.getValue(nodeActor, "name", "");
		end

	elseif sActorType == "npc" then
		rActor = {};
		rActor.sType = "npc";
		rActor.sCreatureNode = sActorNode;
		_, rActor.sCTNode = CombatManager.getCTFromNode(nodeActor);
		rActor.sName = DB.getValue(nodeActor, "name", "");
	end
	
	-- RETURN ACTOR INFORMATION
	return rActor;
end

function getActorFromCT(nodeCT)
	return getActor("ct", nodeCT);
end

function getActorFromToken(token)
	return getActor("ct", CombatManager.getCTFromToken(token));
end

function getType(varActor)
	local rActor = resolveActor(varActor);
	if rActor then return rActor.sType; end
	return nil;
end

function hasCT(varActor)
	return (getCTNodeName(varActor) ~= "");
end

function getCTNodeName(varActor)
	local rActor = resolveActor(varActor);
	if rActor then return rActor.sCTNode; end
	return "";
end

function getCTNode(varActor)
	local rActor = resolveActor(varActor);
	if rActor and ((rActor.sCTNode or "") ~= "") then
		return DB.findNode(rActor.sCTNode);
	end
	return nil;
end

function getCreatureNodeName(varActor)
	local rActor = resolveActor(varActor);
	if rActor then return rActor.sCreatureNode; end
	return "";
end

function getCreatureNode(varActor)
	local rActor = resolveActor(varActor);
	if rActor and ((rActor.sCreatureNode or "") ~= "") then
		return DB.findNode(rActor.sCreatureNode);
	end
	return nil;
end

function getTypeAndNodeName(varActor)
	local sType, nodeCreature = getTypeAndNode(varActor);
	if nodeCreature then
		return sType, nodeCreature.getPath();
	end
	return sType, nil;
end

function getTypeAndNode(varActor)
	local rActor = resolveActor(varActor);
	if not rActor then return nil, nil; end
	
	if rActor.sType == "pc" then
		local nodeCreature = getCreatureNode(rActor);
		if nodeCreature then
			if nodeCreature.isOwner() then return "pc", nodeCreature; end
		end
	end
	
	local nodeCT = getCTNode(rActor);
	if nodeCT then return "ct", nodeCT; end
	
	if rActor.sType ~= "pc" then
		local nodeNPC = getCreatureNode(rActor);
		if nodeNPC then return "npc", nodeNPC; end
	end
	
	return nil, nil;
end

function getFaction(varActor)
	local rActor = resolveActor(varActor);
	if rActor.sType == "pc" then
		return DB.getValue(getCTNode(rActor), "friendfoe", "friend");
	end
	return DB.getValue(getCTNode(rActor), "friendfoe", "foe");
end

local fCustomDisplayNameHandler = nil;
function setCustomDisplayNameHandler(f)
	fCustomDisplayNameHandler = f;
end

function getDisplayName(varActor)
	local rActor = resolveActor(varActor);
	if not rActor then return ""; end
	
	if fCustomDisplayNameHandler then return f(varActor); end

	local nodeCT = getCTNode(rActor);
	if nodeCT then return DB.getValue(nodeCT, "name", ""); end
	
	local nodeCreature = getCreatureNode(rActor);
	if nodeCreature then return DB.getValue(nodeCreature, "name", ""); end
	
	return "";
end
