-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bInitialized = false;
local rStartSize = { w = 450, h = 450 };
local MAX_START_HEIGHT = 650;
local DEFAULT_COL_WIDTH = 50;
local COL_OFFSET = 5;
local LINK_OFFSET = 25;

function onInit()
	if User.getRulesetName() == "SavageWorlds" then
		DEFAULT_COL_WIDTH = 250;
	end
	
	local rList = nil;
	
	local nodeMain = getDatabaseNode();
	local sSource = DB.getValue(nodeMain, "source");
	local sRecordType = DB.getValue(nodeMain, "recordtype");
	if nodeMain and (sSource or sRecordType) then
		rList = {};
		
		rList.sSource = sSource;
		rList.sRecordType = sRecordType;
		rList.sDisplayClass = DB.getValue(nodeMain, "displayclass");
		if not rList.sDisplayClass and (User.getRulesetName() == "SavageWorlds") then
			rList.sDisplayClass = DB.getValue(nodeMain, "itemclass");
		end
		rList.sListView = DB.getValue(nodeMain, "listview");
		
		rList.sTitle = DB.getValue(nodeMain, "name", "");
		if (rList.sTitle == "") and (rList.sRecordType or "") ~= "" then
			rList.sTitle = LibraryData.getDisplayText(rList.sRecordType);
		end
		rList.nWidth = tonumber(DB.getValue(nodeMain, "width")) or nil;
		rList.nHeight = tonumber(DB.getValue(nodeMain, "height")) or nil;
		if DB.getChild(nodeMain, "notes") then
			rList.sDBNotesField = "notes";
		end
		
		rList.aColumns = {};
		for _,nodeColumn in ipairs(UtilityManager.getSortedTable(DB.getChildren(nodeMain, "columns"))) do
			local rColumn = {};
			rColumn.sName = DB.getValue(nodeColumn, "name");
			rColumn.sTooltip = DB.getValue(nodeColumn, "tooltip");
			rColumn.sTooltipRes = DB.getValue(nodeColumn, "tooltipres");
			rColumn.sHeading = DB.getValue(nodeColumn, "heading");
			rColumn.sHeadingRes = DB.getValue(nodeColumn, "headingres");
			rColumn.nWidth = tonumber(DB.getValue(nodeColumn, "width")) or nil;
			if nodeColumn.getChild("center") then
				rColumn.bCentered = true;
			end
			if nodeColumn.getChild("wrap") then
				rColumn.bWrapped = true;
			end
			rColumn.nSortOrder = DB.getValue(nodeColumn, "sortorder");
			if nodeColumn.getChild("sortdesc") then
				rColumn.bSortDesc = true;
			end
			
			local sTempType = DB.getValue(nodeColumn, "type");
			if sTempType then
				if sTempType:match("formattedtext") then
					rColumn.sType = "formattedtext";
				elseif sTempType:match("number") then
					rColumn.sType = "number";
					if nodeColumn.getChild("displaysign") then
						rColumn.bDisplaySign = true;
					end
				end
			end
			if not rColumn.sType then
				rColumn.sType = "string";
			end

			table.insert(rList.aColumns, rColumn);
		end
		
		rList.aFilters = {};
		for _,nodeFilter in pairs(DB.getChildren(nodeMain, "filters")) do
			local rFilter = {};
			rFilter.sDBField = DB.getValue(nodeFilter, "field");
			rFilter.vFilterValue = DB.getValue(nodeFilter, "value");
			if rFilter.sDBField and rFilter.vFilterValue then
				rFilter.vDefaultVal = DB.getValue(nodeFilter, "defaultvalue");
				table.insert(rList.aFilters, rFilter);
			end
		end
		if #(rList.aFilters) == 0 and (User.getRulesetName() == "SavageWorlds") then
			local sOldFilter = DB.getValue(nodeMain, "catname");
			if sOldFilter then
				table.insert(rList.aFilters, { sDBField = "catname", vFilterValue = sOldFilter });
			end
		end
		
		rList.aGroups = {};
		for _,nodeGroup in ipairs(UtilityManager.getSortedTable(DB.getChildren(nodeMain, "groups"))) do
			local rGroup = {};
			rGroup.sDBField = DB.getValue(nodeGroup, "field");
			rGroup.sType = DB.getValue(nodeGroup, "type");
			rGroup.nLength = DB.getValue(nodeGroup, "length");
			rGroup.sPrefix = DB.getValue(nodeGroup, "prefix");
			if rGroup.sDBField then
				table.insert(rList.aGroups, rGroup);
			end
		end
		if #(rList.aGroups) == 0 and (User.getRulesetName() == "SavageWorlds") then
			table.insert(rList.aGroups, { sDBField = "group" });
		end
		rList.aGroupValueOrder = StringManager.split(DB.getValue(nodeMain, "grouporder", ""), "|", true);
		if #(rList.aGroupValueOrder) == 0 and (User.getRulesetName() == "SavageWorlds") then
			rList.aGroupValueOrder = StringManager.split(DB.getValue(nodeMain, "order", ""), ",", true);
		else
		end
	end
	
	if rList then
		init(rList);
	end
end

function init(rListParam)
	if bInitialized then
		return;
	end
	bInitialized = true;
	
	local rList;
	if (rListParam.sListView or "") ~= "" then
		rList = UtilityManager.copyDeep(LibraryData.getListView(rListParam.sRecordType, rListParam.sListView));
		rList.sSource = rListParam.sSource;
		rList.sRecordType = rListParam.sRecordType;
	else
		rList = UtilityManager.copyDeep(rListParam);
	end
	
	local sTitle = rList.sTitle;
	if (sTitle or "") == "" then
		sTitle = Interface.getString(rList.sTitleRes);
	end
	reftitle.setValue(sTitle);
	
	createControl("filter_refgroupedlist", "filter");
	createControl("button_refgroupedlist_expand", "expand");
	createControl("button_refgroupedlist_collapse", "collapse");
	
	if rList.sDBNotesField then
		local cNotes = createControl("ft_refgroupedlist_notes", rList.sDBNotesField);
		local cScrollbar = createControl("scrollbar_refgroupedlist_notes", "");
		cScrollbar.setAnchor("left", rList.sDBNotesField, "right", "absolute", -5);
		cScrollbar.setAnchor("top", rList.sDBNotesField, "top", "absolute", 5);
		cScrollbar.setAnchor("bottom", rList.sDBNotesField, "bottom", "absolute", -5);
		cScrollbar.setTarget(rList.sDBNotesField);
	end
	
	local nTotalColumnWidth = LINK_OFFSET;
	for _,rColumn in ipairs(rList.aColumns) do
		local cColumn = nil;
		if rColumn.bCentered then
			cColumn = createControl("label_refgroupedlist_center", rColumn.sName);
		else
			cColumn = createControl("label_refgroupedlist", rColumn.sName);
		end
		local sHeading = rColumn.sHeading;
		if (sHeading or "") == "" then
			sHeading = Interface.getString(rColumn.sHeadingRes);
		end
		local sTooltip = rColumn.sTooltip;
		if (sTooltip or "") == "" then
			sTooltip = Interface.getString(rColumn.sTooltipRes);
		end
		cColumn.setValue(sHeading);
		cColumn.setTooltipText(sTooltip);
		cColumn.setAnchoredWidth(rColumn.nWidth or DEFAULT_COL_WIDTH);
		
		nTotalColumnWidth = nTotalColumnWidth + (rColumn.nWidth or DEFAULT_COL_WIDTH) + COL_OFFSET;
	end
	
	local cList = createControl("list_refgroupedlist", "grouplist");
	createControl("scrollbar_refgroupedlist", "");
	
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
	local lw, lh = grouplist.getSize();
	local nTotalWidth = nTotalColumnWidth + (ww - lw);
	local nTotalHeight = math.min((nRows * 24) + (wh-lh), MAX_START_HEIGHT);
	
	rStartSize.w = rList.nWidth or math.max(rStartSize.w, nTotalWidth);
	rStartSize.h = rList.nHeight or math.max(rStartSize.h, nTotalHeight);
	setSize(rStartSize.w, rStartSize.h);
	
	setOrder(rList.aGroupValueOrder);
	
	if rList.aGroupings then
		for _,v in pairs(rList.aGroupings) do
			v.initialize();
		end
	end
end

function addListRecord(node, rList)
	local nRows = 0;
	local bAdd = true;
	for _,rFilter in ipairs(rList.aFilters) do
		local v;
		if rFilter.sCustom then
			if not LibraryData.getCustomFilterValue(rFilter.sCustom, node) then
				bAdd = false;
				break;
			end
		else
			if rFilter.fGetValue then
				v = rFilter.fGetValue(node);
			else
				v = DB.getValue(node, rFilter.sDBField, rFilter.vDefaultVal);
			end
			if v ~= rFilter.vFilterValue then
				bAdd = false;
				break;
			end
		end
	end
	if bAdd then
		local aGroups = {};
		for _,rGroup in ipairs(rList.aGroups) do
			local sSubGroup = DB.getValue(node, rGroup.sDBField);
			if rGroup.sCustom then
				sSubGroup = LibraryData.getCustomGroupOutput(rGroup.sCustom, sSubGroup);
			elseif rGroup.nLength then
				sSubGroup = sSubGroup:sub(1, rGroup.nLength);
			end
			if rGroup.sPrefix then
				if (sSubGroup or "") ~= "" then
					sSubGroup = " " .. sSubGroup;
				end
				sSubGroup = rGroup.sPrefix .. (sSubGroup or "");
			end
			table.insert(aGroups, (sSubGroup or ""));
		end
		local sGroup = StringManager.capitalizeAll(table.concat(aGroups, " - "));
		
		if not rList.aGroupings then
			rList.aGroupings = {};
		end
		if not rList.aGroupings[sGroup] then
			rList.aGroupings[sGroup] = grouplist.createWindow();
			rList.aGroupings[sGroup].group.setValue(sGroup);
			rList.aGroupings[sGroup].setColumnInfo(rList.aColumns);
			nRows = nRows + 1;
		end
		
		local wItem = rList.aGroupings[sGroup].list.createWindow(node);
		if rList.sDisplayClass then
			wItem.setItemClass(rList.sDisplayClass);
		else
			wItem.setItemRecordType(rList.sRecordType);
		end
		wItem.setColumnInfo(rList.aColumns, DEFAULT_COL_WIDTH);
		nRows = nRows + 1;
	end
	return nRows;
end

local aValueOrder = {};
function setOrder(aNewOrder)
	aValueOrder = aNewOrder;
	grouplist.applySort();
end

function onSortCompare(w1, w2)
	local sName1 = w1.group.getValue()
	local sName2 = w2.group.getValue()
	
	local nOrder1 = 10000;
	local nOrder2 = 10000;
	for k,s in ipairs(aValueOrder) do
		if s == sName1 then
			nOrder1 = k;
		end
		if s == sName2 then
			nOrder2 = k;
		end
	end
	
	if nOrder1 ~= nOrder2 then
		return nOrder1 > nOrder2;
	end
	
	return sName1 > sName2
end