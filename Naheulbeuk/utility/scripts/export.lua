-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Export structures
local aProperties = {};
local aNodes = {};
local aTokens = {};

function addExportNode(nodeSource, sExportType, sExportLabel, sTargetPath)
	-- Create reference node
	if aProperties.readonly then
		if not aNodes["reference"] then
			aNodes["reference"] = { static = true };
		end
	end
	
	-- Create node entry
	local rNodeExport = {};
	
	rNodeExport.import = nodeSource.getNodeName();
	rNodeExport.category = nodeSource.getCategory();
	
	aNodes[sTargetPath] = rNodeExport;
	
	if (sExportType or "") == "" then
		return;
	end
	
	-- Create library index
	local sLibraryNode = "library." .. aProperties.namecompact;
	if not aNodes[sLibraryNode] then
		local aLibraryIndex = {};
		aLibraryIndex.createstring = { name = aProperties.namecompact, categoryname = aProperties.category };
		aLibraryIndex.static = true;
		
		aNodes[sLibraryNode] = aLibraryIndex;
	end

	-- Create library entry
	local sLibraryEntry = sLibraryNode .. ".entries." .. sExportType;
	if not aNodes[sLibraryEntry] then
		local aLibraryEntry = {};
		aLibraryEntry.createstring = { name = sExportLabel, recordtype = sExportType };
		aLibraryEntry.createlink = { librarylink = { class = "reference_list", recordname = ".." } };
		
		aNodes[sLibraryEntry] = aLibraryEntry;
	end
end

function performClear()
	file.setValue("");
	thumbnail.setValue("");
	name.setValue("");
	category.setValue("");
	author.setValue("");
	for _,cw in ipairs(list.getWindows()) do
		cw.all.setValue(0);
		cw.entries.closeAll();
	end
	tokens.closeAll();
end

function performExport()
	-- Reset data
	aProperties = {};
	aNodes = {};
	aTokens = {};

	-- Global properties
	aProperties.name = name.getValue();
	aProperties.namecompact = string.lower(string.gsub(aProperties.name, "%W", ""));
	aProperties.category = category.getValue();
	aProperties.file = file.getValue();
	aProperties.author = author.getValue();
	aProperties.thumbnail = thumbnail.getValue();
	if readonly.getValue() == 1 then
		aProperties.readonly = true;
	end
	aProperties.playervisible = (playervisible.getValue() == 1);

	-- Pre checks
	if aProperties.name == "" then
		ChatManager.SystemMessage(Interface.getString("export_error_name"));
		name.setFocus(true);
		return;
	end
	if aProperties.file == "" then
		ChatManager.SystemMessage(Interface.getString("export_error_file"));
		file.setFocus(true);
		return;
	end
	
	-- Loop through categories
	for _, cw in ipairs(list.getWindows()) do
		local aExportSources = cw.getSources();
		local aExportTargets;
		if aProperties.readonly then
			aExportTargets = cw.getRefTargets();
		else
			aExportTargets = cw.getTargets();
		end
		if #aExportSources > 0 and #aExportSources == #aExportTargets then
			-- Construct export lists
			if cw.all.getValue() == 1 then
				-- Add all child nodes
				for kSource,vSource in ipairs(aExportSources) do
					local nodeSource = DB.findNode(vSource);
					if nodeSource then
						for _,nodeChild in pairs(nodeSource.getChildren()) do
							if nodeChild.getType() == "node" then
								local sTargetPath = nodeChild.getNodeName():gsub("^" .. vSource, aExportTargets[kSource]);
								addExportNode(nodeChild, cw.getExportType(), cw.label.getValue(), sTargetPath);
							end
						end
					end
				end
			else
				-- Loop through entries in category
				for _, ew in ipairs(cw.entries.getWindows()) do
					local node = ew.getDatabaseNode();
					local sTargetPath = node.getNodeName();
					for kSource,vSource in ipairs(aExportSources) do
						if sTargetPath:match("^" .. vSource) then
							sTargetPath = sTargetPath:gsub("^" .. vSource, aExportTargets[kSource]);
							break;
						end
					end
					addExportNode(node, cw.getExportType(), cw.label.getValue(), sTargetPath);
				end
			end
		end
	end
	
	-- Tokens
	for _, tw in ipairs(tokens.getWindows()) do
		table.insert(aTokens, tw.token.getPrototype());
	end
	
	-- Export
	local bRet = Module.export(aProperties.name, aProperties.category, aProperties.author, aProperties.file, aProperties.thumbnail,	aNodes, aTokens, aProperties.playervisible);
	
	if bRet then
		ChatManager.SystemMessage(Interface.getString("export_message_success"));
	else
		ChatManager.SystemMessage(Interface.getString("export_message_failure"));
	end
end
