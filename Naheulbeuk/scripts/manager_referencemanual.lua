-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aManualPages = {};
local aManualIndex = {};

-- NOTE: Assume that only one manual exists per module
-- NOTE: Assume that the reference manual exists in a specific location in each module
function init(sModule, sPath)
	sModule = sModule or "";
	if aManualPages[sModule] then
		return;
	end
	
	local sManualPath;
	local _,nChapterEnd = sPath:find("%.chapters%.");
	if nChapterEnd then
		sManualPath = sPath:sub(1, nChapterEnd - 1);
	else
		sManualPath = "reference.refmanualindex.chapters";
	end
	
	aManualPages[sModule] = {};
	aManualIndex[sModule] = nil;

	for _,vChapter in pairs(UtilityManager.getSortedTable(DB.getChildren(sManualPath .. "@" .. sModule))) do
		for _,vSubChapter in pairs(UtilityManager.getSortedTable(DB.getChildren(vChapter, "subchapters"))) do
			for _,vPage in pairs(UtilityManager.getSortedTable(DB.getChildren(vSubChapter, "refpages"))) do
				local sClass, sRecord = DB.getValue(vPage, "listlink", "", "");
				if sRecord ~= "" then
					table.insert(aManualPages[sModule], sRecord);
					local sNameLower = DB.getValue(vPage, "name", ""):lower();
					if sNameLower:match("%(contents%)") or sNameLower:match("%(index%)") then
						aManualIndex[sModule] = sRecord;
					end
				end
			end
		end
	end
end

function getIndexRecord(sModule)
	sModule = sModule or "";
	return aManualIndex[sModule];
end

function getPrevRecord(sModule, sCurrent)
	sModule = sModule or "";
	for kRecord,sRecord in ipairs(aManualPages[sModule]) do
		if sRecord == sCurrent then
			return aManualPages[sModule][kRecord - 1];
		end
	end
	return nil;
end

function getNextRecord(sModule, sCurrent)
	sModule = sModule or "";
	for kRecord,sRecord in ipairs(aManualPages[sModule]) do
		if sRecord == sCurrent then
			return aManualPages[sModule][kRecord + 1];
		end
	end
	return nil;
end
