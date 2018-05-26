-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aLiteralReplacements = {};

function onButtonPress()
	local node = window.getDatabaseNode();
	
	aLiteralReplacements = {}
	
	sName = performTableLookups(DB.getValue(node, "name", ""));
	sText = performTableLookups(DB.getValue(node, "text", ""));
	
	sName = performLiteralReplacements(sName);
	sText = performLiteralReplacements(sText);
		
	sText = performLinkReplacements(sText);

	nodeTarget = DB.createChild("encounter");
	DB.setValue(nodeTarget, "name", "string", sName);
	DB.setValue(nodeTarget, "text", "formattedtext", sText);

	Interface.openWindow("encounter", nodeTarget);
end

-- Look for table roll expressions
function performTableLookups(sOriginal)
	-- store the original value in a variable. We will replace matches as we go and search for the next matching
	-- expression.
	local sOutput = sOriginal;
	
	-- Resolve math expressions
	local sResult = sOutput;
	local aMathResults = {};
	for nStartTag, sTag, nEndTag in sOutput:gmatch("()%[([^%]]+)%]()") do
		local sDiceExpr;
		if sTag:match("x$") then
			sDiceExpr = sTag:sub(1, -2);
		else
			sDiceExpr = sTag;
		end
		if StringManager.isDiceMathString(sDiceExpr) then
			local nMathResult = StringManager.evalDiceMathExpression(sDiceExpr);
			if sTag:match("x$") then
				table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = "[" .. nMathResult .. "x]" });
			else
				table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = nMathResult });
			end
		end
	end
	for i = #aMathResults,1,-1 do
		sOutput = sOutput:sub(1, aMathResults[i].nStart - 1) .. aMathResults[i].vResult .. sOutput:sub(aMathResults[i].nEnd);
	end
	
	-- Resolve table expressions
	local nMult = 1;
	local aLookupResults = {};
	for nStartTag, sTag, nEndTag in sOutput:gmatch("()%[([^%]]+)%]()") do
		local sMult = sTag:match("^(%d+)x$");
		if sMult then
			nMult = math.max(tonumber(sMult), 1);
			table.insert(aLookupResults, { nStart = nStartTag, nEnd = nEndTag, vResult = "" });
		else
			local sTable = sTag;
			local nCol = 0;
			
			local sColumn = sTable:match("|(%d+)$");
			if sColumn then
				sTable = sTable:sub(1, -(#sColumn + 2));
				nCol = tonumber(sColumn) or 0;
			end
			local nodeTable = TableManager.findTable(sTable);

			local aMultLookupResults = {};
			local aMultLookupLinks = {};
			for nCount = 1,nMult do
				local sLocalReplace = "";
				local aLocalLinks = {};
				if nodeTable then
					bContinue = true;
					
					local aDice, nMod = TableManager.getTableDice(nodeTable);
					local nRollResults = StringManager.evalDice(aDice, nMod);
					local aTableResults = TableManager.getResults(nodeTable, nRollResults, nCol);
					
					local aOutputResults = {};
					for _,v in ipairs(aTableResults) do
						if (v.sClass or "") ~= "" then
							if v.sClass == "table" then
								local sTableName = DB.getValue(DB.getPath(v.sRecord, "name"), "");
								if sTableName ~= "" then
									sTableName = "[" .. sTableName .. "]";
									local sMultTag, nEndMultTag = v.sText:match("%[(%d+x)%]()");
									if nEndMultTag then
										v.sText = v.sText:sub(1, nEndMultTag - 1) .. sTableName .. " " .. v.sText:sub(nEndMultTag);
									else
										v.sText = sTableName .. " " .. v.sText;
									end
								end
								table.insert(aOutputResults, v.sText);
							else
								table.insert(aLocalLinks, { sClass = v.sClass, sRecord = v.sRecord, sText = v.sText });
							end
						else
							table.insert(aOutputResults, v.sText);
						end
					end
					
					sLocalReplace = table.concat(aOutputResults, "; ");
				else
					sLocalReplace = sTag;
				end
				
				-- Recurse to address any new math/table lookups
				sLocalReplace = performTableLookups(sLocalReplace);
				
				table.insert(aMultLookupResults, sLocalReplace);
				for _,vLink in ipairs(aLocalLinks) do
					table.insert(aMultLookupLinks, vLink);
				end
			end

			local sReplace = table.concat(aMultLookupResults, " ");
			if aLiteralReplacements[sTable] then
				table.insert(aLiteralReplacements[sTable], sReplace);
			else
				aLiteralReplacements[sTable] = { sReplace };
			end

			for _,vLink in ipairs(aMultLookupLinks) do
				sReplace = sReplace .. "||" .. vLink.sClass .. "|" .. vLink.sRecord .. "|" .. vLink.sText .. "||";
			end
			
			table.insert(aLookupResults, { nStart = nStartTag, nEnd = nEndTag, vResult = sReplace });
			nMult = 1;
		end
		
	end
	for i = #aLookupResults,1,-1 do
		sOutput = sOutput:sub(1, aLookupResults[i].nStart - 1) .. aLookupResults[i].vResult .. sOutput:sub(aLookupResults[i].nEnd);
	end
	
	return sOutput;
end
	
function performLiteralReplacements(sOriginal)
	local sOutput = sOriginal;
	for k,v in pairs(aLiteralReplacements) do			
		-- Now replace any variable replacement values from the table. Replace < with
		-- xml encoded values. You can't use the encodeXML function because it escapes &amp;
		local sLiteral = "&#60;" .. k:gsub("([%-%+%.%?%*%(%)%[%]%^%$%%])", "%%%1") .."&#62;";
		sOutput = sOutput:gsub(sLiteral, table.concat(v, " "));	
	end
	return sOutput;
end

function performLinkReplacements(sOriginal)
	local sOutput = sOriginal;

	local aLinkResults = {};
	for nLinkStart, sLinkClass, sLinkRecord, sLinkText, nLinkEnd in sOutput:gmatch("()||([^|]*)|([^|]*)|([^|]*)||()") do
		local nSectionTagStart, sSectionTag, nSectionTagEnd;
		for nTempTagStart, sTempTag, nTempTagEnd in sOutput:gmatch("()<([^>]+)>()") do
			if nTempTagEnd > nLinkStart then
				break;
			end
			if (sTempTag == "p") or (sTempTag == "h") or (sTempTag == "table") or (sTempTag == "frame") or (sTempTag == "frameid") or (sTempTag == "li") or (sTempTag == "linklist") then
				nSectionTagStart = nTempTagStart;
				sSectionTag = sTempTag;
				nSectionTagEnd = nTempTagEnd;
			end
		end
		
		local sLinkReplace = "<linklist><link class=\"" .. UtilityManager.encodeXML(sLinkClass) .. "\" recordname=\"" .. UtilityManager.encodeXML(sLinkRecord) .. "\">" .. sLinkText .. "</link></linklist>";
		
		if sSectionTag == "table" then
			sLinkReplace = "!TABLE LINK NOT ALLOWED!";
		elseif sSectionTag == "frameid" then
			sLinkReplace = "!SPEAKER LINK NOT ALLOWED!";
		elseif sSectionTag == "li" then
			sLinkReplace = "</li></list>" .. sLinkReplace .. "<list><li>";
		elseif sSectionTag == "linklist" then
			sLinkReplace = "</link>" .. sLinkReplace .. "<link>";
		elseif sSectionTag == "frame" then
			sLinkReplace = "</frame>" .. sLinkReplace .. "<frame>";
		elseif sSectionTag == "h" then
			sLinkReplace = "</h>" .. sLinkReplace .. "<h>";
		elseif sSectionTag == "p" then
			sLinkReplace = "</p>" .. sLinkReplace .. "<p>";
		else
			sLinkReplace = "!MISSING SECTION!";
		end
		
		table.insert(aLinkResults, { nStart = nLinkStart, nEnd = nLinkEnd, vResult = sLinkReplace });
	end
	for i = #aLinkResults,1,-1 do
		sOutput = sOutput:sub(1, aLinkResults[i].nStart - 1) .. aLinkResults[i].vResult .. sOutput:sub(aLinkResults[i].nEnd);
	end
	
	sOutput = sOutput:gsub("<p></p>", "");
	sOutput = sOutput:gsub("<h></h>", "");
	sOutput = sOutput:gsub("<list>%s*<li></li>%s*</list>", "");
	sOutput = sOutput:gsub("<link></link>", "");
	sOutput = sOutput:gsub("<frame></frame>", "");
	
	sOutput = sOutput:gsub("</linklist>%s*<linklist>", "");
	
	return sOutput;
end
