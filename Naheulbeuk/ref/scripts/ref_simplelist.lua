-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local rStartSize = { w = 350, h = 450 };
local MAX_START_HEIGHT = 650;
local DEFAULT_COL_WIDTH = 50;
local COL_OFFSET = 5;
local LINK_OFFSET = 25;

function onInit()
	local rList = nil;
	
	local nodeMain = getDatabaseNode();
	local sSource = DB.getValue(nodeMain, "source");
	local sRecordType = DB.getValue(nodeMain, "recordtype");
	if nodeMain and (sSource or sRecordType) then
		rList = {};
		
		rList.sSource = sSource;
		rList.sRecordType = sRecordType;
		rList.sDisplayClass = DB.getValue(nodeMain, "displayclass");
		
		rList.sTitle = DB.getValue(nodeMain, "name", "");
		if (rList.sTitle == "") and (rList.sRecordType or "") ~= "" then
			rList.sTitle = LibraryData.getDisplayText(rList.sRecordType);
		end
		rList.nWidth = tonumber(DB.getValue(nodeMain, "width")) or nil;
		rList.nHeight = tonumber(DB.getValue(nodeMain, "height")) or nil;
		
		rList.aFilters = {};
		for _,nodeFilter in pairs(DB.getChildren(nodeMain, "filters")) do
			local rFilter = {};
			rFilter.sDBField = DB.getValue(nodeFilter, "field");
			rFilter.vFilterValue = DB.getValue(nodeFilter, "value");
			if rFilter.sDBField and rFilter.vFilterValue then
				table.insert(rList.aFilters, rFilter);
			end
		end
	end
	
	if rList then
		init(rList);
	end
end

function init(rList)
	reftitle.setValue(rList.sTitle);
	
	local nRows = 0
	if rList.sSource then
		local sModule = DB.getModule(getDatabaseNode());
		if sModule and not rList.sSource:match("@") then
			rList.sSource = rList.sSource .. "@" .. sModule;
		end
		for _,vNode in pairs(DB.getChildren(rList.sSource)) do
			nRows = nRows + addListRecord(vNode, rList);
		end
	elseif rList.sRecordType then
		local sModule = DB.getModule(getDatabaseNode());
		local aMappings = LibraryData.getMappings(rList.sRecordType);
		for _,vMapping in ipairs(aMappings) do
			if (sModule or "") ~= "" then
				local nodeSource = DB.findNode(vMapping .. "@" .. sModule);
				if nodeSource then
					for _,vNode in pairs(nodeSource.getChildren()) do
						nRows = nRows + addListRecord(vNode, rList);
					end
				end
			else
				for _,vNode in pairs(DB.getChildrenGlobal(vMapping)) do
					nRows = nRows + addListRecord(vNode, rList);
				end
			end
		end
	end
	
	local ww, wh = getSize();
	local lw, lh = list.getSize();
	local nTotalWidth = LINK_OFFSET + 200 + (ww - lw);
	local nTotalHeight = math.min((nRows * 24) + (wh-lh), MAX_START_HEIGHT);
	
	rStartSize.w = rList.nWidth or math.max(rStartSize.w, nTotalWidth);
	rStartSize.h = rList.nHeight or math.max(rStartSize.h, nTotalHeight);
	setSize(rStartSize.w, rStartSize.h);
end

function addListRecord(node, rList)
	local nRows = 0;
	local bAdd = true;
	for _,rFilter in ipairs(rList.aFilters) do
		if DB.getValue(node, rFilter.sDBField, rFilter.vDefaultVal) ~= rFilter.vFilterValue then
			bAdd = false;
		end
	end
	if bAdd then
		local wItem = list.createWindow(node);
		if rList.sDisplayClass then
			wItem.setItemClass(rList.sDisplayClass);
		else
			wItem.setItemRecordType(rList.sRecordType);
		end
		wItem.name.setValue(DB.getValue(node, "name", ""));
		nRows = nRows + 1;
	end
	return nRows;
end
