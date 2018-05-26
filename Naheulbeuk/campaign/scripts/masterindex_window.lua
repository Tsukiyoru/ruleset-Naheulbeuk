-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aRecords = {};
local aFilteredRecords = {};
local nDisplayOffset = 0;
local MAX_DISPLAY_RECORDS = 100;
local bDelayedChildrenChanged = false;
local bDelayedRebuild = false;

local fName = "";
local fSharedOnly = false;
local fCategory = "";

local bAllowCategories = true;
local sCategoryAll = "*";
local sCategoryEmpty = "";

local sInternalRecordType = "";
local bProcessListChanged = false;

local cButtonAnchor = nil;
local aButtonControls = {};

local aEditControls = {};

local aCustomFilters = {};
local nCustomFilters = 0;
local aCustomFilterControls = {};
local aCustomFilterValueControls = {};
local aCustomFilterValues = {};

local bDelayedFocus = nil;

function onInit()
	local node = getDatabaseNode();
	if node then
		local sRecordType = LibraryData.getRecordTypeFromPath(node.getPath());
		if (sRecordType or "") ~= "" then
			setRecordType(sRecordType);
		end
	end

	Module.onModuleLoad = onModuleLoadAndUnload;
	Module.onModuleUnload = onModuleLoadAndUnload;
end

function onClose()
	local sInternalIDOption = LibraryData.getIDOption(sInternalRecordType);
	if sInternalIDOption ~= "" then
		OptionsManager.unregisterCallback(sInternalIDOption, onIDChanged);
	end

	removeHandlers();
end

function onModuleLoadAndUnload(sModule)
	local nodeRoot = DB.getRoot(sModule);
	if nodeRoot then
		local vNodes = LibraryData.getMappings(sInternalRecordType);
		for i = 1, #vNodes do
			if nodeRoot.getChild(vNodes[i]) then
				bDelayedRebuild = true;
				onListRecordsChanged(true);
				break;
			end
		end
	end
end

function addHandlers()
	function addHandlerHelper(vNode)
		local sPath = DB.getPath(vNode);
		local sChildPath = sPath .. ".*@*";
		DB.addHandler(sChildPath, "onAdd", onChildAdded);
		DB.addHandler(sChildPath, "onDelete", onChildDeleted);
		DB.addHandler(sChildPath, "onCategoryChange", onChildCategoryChange);
		DB.addHandler(sChildPath, "onObserverUpdate", onChildObserverUpdate);
		DB.addHandler(DB.getPath(sChildPath, "name"), "onUpdate", onChildNameChange);
		DB.addHandler(DB.getPath(sChildPath, "nonid_name"), "onUpdate", onChildUnidentifiedNameChange);
		DB.addHandler(DB.getPath(sChildPath, "isidentified"), "onUpdate", onChildIdentifiedChange);
		for kCustomFilter,vCustomFilter in pairs(aCustomFilters) do
			DB.addHandler(DB.getPath(sChildPath, vCustomFilter.sField), "onUpdate", onChildCustomFilterValueChange);
		end
		DB.addHandler(sPath, "onChildCategoriesChange", onChildCategoriesChanged);
	end
	
	local vNodes = LibraryData.getMappings(sInternalRecordType);
	for i = 1, #vNodes do
		addHandlerHelper(vNodes[i]);
	end
end

function removeHandlers()
	function removeHandlerHelper(vNode)
		local sPath = DB.getPath(vNode);
		local sChildPath = sPath .. ".*@*";
		DB.removeHandler(sChildPath, "onAdd", onChildAdded);
		DB.removeHandler(sChildPath, "onDelete", onChildDeleted);
		DB.removeHandler(sChildPath, "onCategoryChange", onChildCategoryChange);
		DB.removeHandler(sChildPath, "onObserverUpdate", onChildObserverUpdate);
		DB.removeHandler(DB.getPath(sChildPath, "name"), "onUpdate", onChildNameChange);
		DB.removeHandler(DB.getPath(sChildPath, "nonid_name"), "onUpdate", onChildUnidentifiedNameChange);
		DB.removeHandler(DB.getPath(sChildPath, "isidentified"), "onUpdate", onChildIdentifiedChange);
		for kCustomFilter,vCustomFilter in pairs(aCustomFilters) do
			DB.removeHandler(DB.getPath(sChildPath, vCustomFilter.sField), "onUpdate", onChildCustomFilterValueChange);
		end
		DB.removeHandler(sPath, "onChildCategoriesChange", onChildCategoriesChanged);
	end
	
	local vNodes = LibraryData.getMappings(sInternalRecordType);
	for i = 1, #vNodes do
		removeHandlerHelper(vNodes[i]);
	end
end

function getRecordType()
	return sInternalRecordType;
end
function setRecordType(sRecordType)
	if sRecordType == sInternalRecordType then
		return;
	end
	
	removeHandlers();
	clearButtons();
	clearCustomFilters();
	clearIDOption();

	sInternalRecordType = sRecordType;

	local sDisplayTitle = LibraryData.getDisplayText(sRecordType);
	reftitle.setValue(sDisplayTitle);
	
	setupEditTools();
	setupCategories();
	setupButtons();
	setupCustomFilters();
	setupIDOption();

	rebuildList();
	addHandlers();
end

function setupEditTools()
	list_iadd.setRecordType(LibraryData.getRecordDisplayClass(sInternalRecordType));
	local bAllowEdit = LibraryData.allowEdit(sInternalRecordType);
	list_iedit.setVisible(bAllowEdit);

	list.setReadOnly(not bAllowEdit);
	list.resetMenuItems();
	if not list.isReadOnly() and bAllowEdit then
		list.registerMenuItem(Interface.getString("list_menu_createitem"), "insert", 5);
	end
end

function setupCategories()
	bAllowCategories = LibraryData.allowCategories(sInternalRecordType);
	label_category.setVisible(bAllowCategories);
	filter_category_label.setVisible(bAllowCategories);
	button_category_detail.setVisible(bAllowCategories);
	handleCategorySelect("*");
end

function clearIDOption()
	local sInternalIDOption = LibraryData.getIDOption(sInternalRecordType);
	if sInternalIDOption ~= "" then
		OptionsManager.unregisterCallback(sInternalIDOption, onIDChanged);
	end
end

function setupIDOption()
	local sInternalIDOption = LibraryData.getIDOption(sInternalRecordType);
	if sInternalIDOption ~= "" then
		OptionsManager.registerCallback(sInternalIDOption, onIDChanged);
	end
end

function clearButtons()
	for _,v in ipairs(aButtonControls) do
		v.destroy();
	end
	if cButtonAnchor then
		cButtonAnchor.destroy();
		cButtonAnchor = nil;
	end
	aButtonControls = {};
	
	for _,v in ipairs(aEditControls) do
		v.destroy();
	end
	aEditControls = {};
end

function setupButtons()
	local aIndexButtons = LibraryData.getIndexButtons(sInternalRecordType);
	if #aIndexButtons > 0 then
		cButtonAnchor = createControl("masterindex_anchor_button", "buttonanchor");
		for k,v in ipairs(aIndexButtons) do
			local c = createControl(v, "button_custom" .. k);
			if c then
				table.insert(aButtonControls, c);
			end
		end
	end

	local aEditButtons = LibraryData.getEditButtons(sInternalRecordType);
	if #aEditButtons > 0 then
		for k,v in ipairs(aEditButtons) do
			local c = createControl(v, "button_edit" .. k);
			if c then
				table.insert(aEditControls, c);
			end
		end
	end
end

function clearCustomFilters()
	for _,c in pairs(aCustomFilterValueControls) do
		c.onDestroy();
		c.destroy();
	end
	aCustomFilterValueControls = {};
	for _,c in pairs(aCustomFilterControls) do
		c.destroy();
	end
	aCustomFilterControls = {};
	aCustomFilters = {};
	nCustomFilters = 0;
end

function setupCustomFilters()
	aCustomFilters = LibraryData.getCustomFilters(sInternalRecordType);
	
	local aSortedFilters = {};
	for kFilter,_ in pairs(aCustomFilters) do
		table.insert(aSortedFilters, kFilter);
	end
	table.sort(aSortedFilters);
	for _,vFilter in ipairs(aSortedFilters) do
		addCustomFilter(vFilter);
	end
	nCustomFilters = #aSortedFilters;
end

function addCustomFilter(sCustomType)
	local c = createControl("masterindex_filter_custom", "filter_custom_" .. sCustomType);
	c.setValue(sCustomType);
	aCustomFilterControls[sCustomType] = c;
	
	local c2 = createControl("masterindex_filter_custom_value",  "filter_custom_value_" .. sCustomType);
	c2.setFilterType(sCustomType);
	aCustomFilterValueControls[sCustomType] = c2;
	
	aCustomFilterValues[sCustomType] = "";
end

function clearFilterValues()
	if fSharedOnly then
		filter_sharedonly.setValue(0);
	end
	if fName ~= "" then
		filter_name.setValue();
	end
	for kCustomFilter,_ in pairs(aCustomFilters) do
		aCustomFilterValueControls[kCustomFilter].setValue("");
	end
end

function rebuildList()
	bProcessListChanged = false;
	
	local sListDisplayClass = LibraryData.getIndexDisplayClass(sInternalRecordType);
	if sListDisplayClass ~= "" then
		list.setChildClass(sListDisplayClass);
	end
	
	aRecords = {};
	local aMappings = LibraryData.getMappings(sInternalRecordType);
	for _,vMapping in ipairs(aMappings) do
		for _,vNode in pairs(DB.getChildrenGlobal(vMapping)) do
			addListRecord(vNode);
		end
	end

	nDisplayOffset = 0;
	onListRecordsChanged();
	
	bProcessListChanged = true;
end

function onChildAdded(vNode)
	addListRecord(vNode);
	clearFilterValues();
	onListRecordsChanged(true);
end

function onChildDeleted(vNode)
	if aRecords[vNode] then
		aRecords[vNode] = nil;
		onListRecordsChanged(true);
	end
end

function onChildCategoriesChanged()
	onListRecordsChanged(true);
end

function onListRecordsChanged(bAllowDelay)
	if bAllowDelay then
		bDelayedChildrenChanged = true;
		list.setDatabaseNode(nil);
	else
		bDelayedChildrenChanged = false;
		if bDelayedRebuild then
			bDelayedRebuild = false;
			rebuildList();
		end
		rebuildCategories();
		rebuildCustomFilterValues();
		applyListFilter();
	end
end

function addListRecord(vNode)
	local rRecord = {};
	rRecord.vNode = vNode;
	rRecord.sName = DB.getValue(vNode, "name", "");
	rRecord.sNameLower = rRecord.sName:lower();
	rRecord.sCategory = UtilityManager.getNodeCategory(vNode);
	rRecord.nAccess = UtilityManager.getNodeAccessLevel(vNode);
	
	rRecord.bIdentifiable = LibraryData.isIdentifiable(sInternalRecordType, vNode);
	if rRecord.bIdentifiable then
		rRecord.sUnidentifiedName = DB.getValue(vNode, "nonid_name", "");
		rRecord.sUnidentifiedNameLower = rRecord.sUnidentifiedName:lower();
	end
	
	rRecord.aCustomValues = {};
	for kCustomFilter,vCustomFilter in pairs(aCustomFilters) do
		rRecord.aCustomValues[kCustomFilter] = DB.getValue(vNode, vCustomFilter.sField, "");
	end
	
	aRecords[vNode] = rRecord;
end

function onListChanged()
	if bDelayedChildrenChanged then
		onListRecordsChanged(false);
	else
		list.update();
	end
end

function getFilteredResultsPages()
	local nPages = math.floor(#aFilteredRecords / MAX_DISPLAY_RECORDS);
	if (#aFilteredRecords % MAX_DISPLAY_RECORDS) > 0 then
		nPages = nPages + 1;
	end
	return nPages;
end

function applyListFilter()
	aFilteredRecords = {};
	for _,vRecord in pairs(aRecords) do
		if applyRecordFilter(vRecord) then
			table.insert(aFilteredRecords, vRecord);
		end
	end
	table.sort(aFilteredRecords, applyRecordSort);
	
	if (nDisplayOffset < 0) or (nDisplayOffset >= #aFilteredRecords) then
		nDisplayOffset = 0;
	end
	
	list.closeAll();
	local nDisplayOffsetMax = nDisplayOffset + MAX_DISPLAY_RECORDS;
	for kRecord,vRecord in ipairs(aFilteredRecords) do
		if kRecord > nDisplayOffset and kRecord <= nDisplayOffsetMax then
			local w = list.createWindow(vRecord.vNode);
			if w.category and (fCategory ~= "*") then
				w.category.setVisible(false);
			end
			w.setRecordType(sInternalRecordType);
		end
	end

	local nPages = getFilteredResultsPages();
	if nPages > 1 then
		local nCurrentPage = math.max(math.floor(nDisplayOffset / MAX_DISPLAY_RECORDS) + 1, 1);
		local sPageText = string.format(Interface.getString("masterindex_label_page_info"), nCurrentPage, nPages)
		page_info.setValue(sPageText);
		page_info.setVisible(true);
		if nCurrentPage == 1 then
			page_start.setVisible(false);
			page_prev.setVisible(false);
		else
			page_start.setVisible(true);
			page_prev.setVisible(true);
		end
		if nCurrentPage >= nPages then
			page_next.setVisible(false);
			page_end.setVisible(false);
		else
			page_next.setVisible(true);
			page_end.setVisible(true);
		end
	else
		page_start.setVisible(false);
		page_prev.setVisible(false);
		page_next.setVisible(false);
		page_end.setVisible(false);
		page_info.setVisible(false);
	end
	
	local nListOffset = 40;
	if nPages > 1 then
		nListOffset = nListOffset + 24;
	end
	if nCustomFilters > 0 then
		nListOffset = nListOffset + (25 * nCustomFilters);
	end
	list.setAnchor("bottom", "bottomanchor", "top", "relative", -nListOffset);
end

function applyRecordSort(vRecordA, vRecordB)
	local sNameA, sNameB;
	if getRecordIDState(vRecordA) then sNameA = vRecordA.sName; else sNameA = vRecordA.sUnidentifiedName; end
	if getRecordIDState(vRecordB) then sNameB = vRecordB.sName; else sNameB = vRecordB.sUnidentifiedName; end
	if sNameA ~= sNameB then
		return sNameA < sNameB;
	end
	return vRecordA.vNode.getPath() < vRecordB.vNode.getPath();
end

function getFilterValues(kCustomFilter, vNode)
	local vValues = {};
	
	local vCustomFilter = aCustomFilters[kCustomFilter];
	if vCustomFilter then
		if vCustomFilter.fGetValue then
			vValues = vCustomFilter.fGetValue(vNode);
			if type(vValues) ~= "table" then
				vValues = { vValues };
			end
		elseif vCustomFilter.sType == "boolean" then
			if DB.getValue(vNode, vCustomFilter.sField, 0) ~= 0 then
				vValues = { LibraryData.sFilterValueYes };
			else
				vValues = { LibraryData.sFilterValueNo };
			end
		else
			local vValue = DB.getValue(vNode, vCustomFilter.sField);
			if vCustomFilter.sType == "number" then
				vValues = { tostring(vValue or 0) };
			else
				local sValue;
				if vValue then
					sValue = tostring(vValue) or "";
				else
					sValue = "";
				end
				if sValue == "" then
					vValues = { LibraryData.sFilterValueEmpty };
				else
					vValues = { sValue };
				end
			end
		end
	end
	
	return vValues;
end

function applyRecordFilter(vRecord)
	if bAllowCategories and fCategory ~= "*" then
		if vRecord.sCategory ~= fCategory then
			return false;
		end
	end
	if fSharedOnly then
		if vRecord.nAccess == 0 then
			return false;
		end
	end
	for kCustomFilter,sCustomFilterValue in pairs(aCustomFilterValues) do
		if sCustomFilterValue ~= "" then
			local vValues = getFilterValues(kCustomFilter, vRecord.vNode);
			local bMatch = false;
			for _,v in ipairs(vValues) do
				if v:lower() == sCustomFilterValue then
					bMatch = true;
					break;
				end
			end
			if not bMatch then
				return false;
			end
		end
	end
	if fName ~= "" then
		if getRecordIDState(vRecord) then
			if not string.find(vRecord.sNameLower, fName, 0, true) then
				return false;
			end
		else
			if not string.find(vRecord.sUnidentifiedNameLower, fName, 0, true) then
				return false;
			end
		end
	end
	return true;
end

function getRecordIDState(vRecord)
	return LibraryData.getIDState(sInternalRecordType, vRecord.vNode);
end

function rebuildCustomFilterValues()
	local nCustomFilters = 0;
	local aRecordFilterValues = {};
	for kCustomFilter,_ in pairs(aCustomFilters) do
		if aCustomFilterValueControls[kCustomFilter] then
			aRecordFilterValues[kCustomFilter] = {};
			nCustomFilters = nCustomFilters + 1;
		end
	end
	if nCustomFilters == 0 then
		return;
	end
	
	for _,vRecord in pairs(aRecords) do
		for kCustomFilter,vCustomFilter in pairs(aCustomFilters) do
			if aCustomFilterValueControls[kCustomFilter] then
				local vValues = getFilterValues(kCustomFilter, vRecord.vNode);
				for _,v in ipairs(vValues) do
					if (v or "") ~= "" then
						aRecordFilterValues[kCustomFilter][v] = true;
					end
				end
			end
		end
	end
	for kCustomFilter,vRecordFilterValues in pairs(aRecordFilterValues) do
		aCustomFilterValueControls[kCustomFilter].clear();
		if not vRecordFilterValues[aCustomFilterValueControls[kCustomFilter].getValue()] then
			aCustomFilterValueControls[kCustomFilter].setValue("");
		end
		local aFilterValues = {};
		for k,_ in pairs(vRecordFilterValues) do
			table.insert(aFilterValues, k);
		end
		if aCustomFilters[kCustomFilter].fSort then
			aFilterValues = aCustomFilters[kCustomFilter].fSort(aFilterValues);
		elseif aCustomFilters[kCustomFilter].sType == "number" then
			table.sort(aFilterValues, function(a,b) return (tonumber(a) or 0) < (tonumber(b) or 0); end);
		else
			table.sort(aFilterValues);
		end
		table.insert(aFilterValues, 1, "");
		aCustomFilterValueControls[kCustomFilter].addItems(aFilterValues);
	end
end

function onCustomFilterValueChanged(sFilterType, cFilterValue)
	aCustomFilterValues[sFilterType] = cFilterValue.getValue():lower();
	applyListFilter();
end

function onChildCategoryChange(vNode)
	if aRecords[vNode] then
		aRecords[vNode].sCategory = UtilityManager.getNodeCategory(vNode);
		if fCategory ~= "*" then
			applyListFilter();
		end
	end
end

function onChildObserverUpdate(vNode)
	aRecords[vNode].nAccess = UtilityManager.getNodeAccessLevel(vNode);
	if fSharedOnly then
		applyListFilter();
	end
end

function onChildCustomFilterValueChange(vNode)
	local sNodeName = vNode.getName();
	for kCustomFilter,vCustomFilter in pairs(aCustomFilters) do
		if vCustomFilter.sField == sNodeName then
			if aCustomFilterValues[kCustomFilter] ~= "" then
				applyListFilter();
			end
			break;
		end
	end
end

function onChildNameChange(vNameNode)
	local vNode = vNameNode.getParent();
	aRecords[vNode].sName = DB.getValue(vNode, "name", "");
	aRecords[vNode].sNameLower = aRecords[vNode].sName:lower();
	if getRecordIDState(aRecords[vNode]) then
		applyListFilter();
	end
end

function onChildUnidentifiedNameChange(vNameNode)
	local vNode = vNameNode.getParent();
	aRecords[vNode].sUnidentifiedName = DB.getValue(vNode, "nonid_name", "");
	aRecords[vNode].sUnidentifiedNameLower = aRecords[vNode].sUnidentifiedName:lower();
	if not getRecordIDState(aRecords[vNode]) then
		applyListFilter();
	end
end

function onChildIdentifiedChange (vIDNode)
	local vNode = vIDNode.getParent();
	if aRecords[vNode].bIdentifiable and not User.isHost() then
		applyListFilter();
	end
end

function handlePageStart()
	nDisplayOffset = 0;
	applyListFilter();
end
function handlePagePrev()
	nDisplayOffset = nDisplayOffset - MAX_DISPLAY_RECORDS;
	applyListFilter();
end
function handlePageNext()
	nDisplayOffset = nDisplayOffset + MAX_DISPLAY_RECORDS;
	applyListFilter();
end
function handlePageEnd()
	local nPages = getFilteredResultsPages();
	if nPages > 1 then
		nDisplayOffset = (nPages - 1) * MAX_DISPLAY_RECORDS;
	else
		nDisplayOffset = 0;
	end
	applyListFilter();
end

function handleCategorySelect(sCategory)
	if not bAllowCategories then
		return;
	end
	
	filter_category.setValue(sCategory);
	fCategory = sCategory;

	if fCategory == "*" then
		filter_category_label.setValue(Interface.getString("masterindex_label_category_all"));
	elseif fCategory == "" then
		filter_category_label.setValue(Interface.getString("masterindex_label_category_empty"));
	else
		filter_category_label.setValue(fCategory);
	end
	
	for _,w in ipairs(list_category.getWindows()) do
		if w.category.getValue() == fCategory then
			w.setFrame("rowshade");
		else
			w.setFrame(nil);
		end
	end
	
	button_category_detail.setValue(0);
	
	local sDefaultCategory = sCategory;
	if sDefaultCategory == "*" then
		sDefaultCategory = "";
	end
	for _,vMapping in ipairs(LibraryData.getMappings(sInternalRecordType)) do
		DB.setDefaultChildCategory(vMapping, sDefaultCategory);
	end

	applyListFilter();
end

function handleCategoryNameChange(sOriginal, sNew)
	if sOriginal == sNew then
		return;
	end
	for _,vMapping in ipairs(LibraryData.getMappings(sInternalRecordType)) do
		DB.updateChildCategory(vMapping, sOriginal, sNew, true);
	end
end

function handleCategoryDelete(sName)
	for _,vMapping in ipairs(LibraryData.getMappings(sInternalRecordType)) do
		DB.removeChildCategory(vMapping, sName, true);
	end
end

function handleCategoryAdd()
	local aMappings = LibraryData.getMappings(sInternalRecordType);
	local sNew = DB.addChildCategory(aMappings[1]);
	list_category.applySort(true);
	for _,w in ipairs(list_category.getWindows()) do
		if w.category.getValue() == sNew then
			w.category_label.setFocus();
			break;
		end
	end
end

function rebuildCategories()
	if not bAllowCategories then
		return;
	end
	
	local aCategories = {};
	for _,vMapping in ipairs(LibraryData.getMappings(sInternalRecordType)) do
		for _,vCategory in ipairs(DB.getChildCategories(vMapping, true)) do
			if type(vCategory) == "string" then
				aCategories[vCategory] = vCategory;
			else
				aCategories[vCategory.name] = vCategory.name;
			end
		end
	end
	aCategories["*"] = Interface.getString("masterindex_label_category_all");
	aCategories[""] = Interface.getString("masterindex_label_category_empty");

	list_category.closeAll();
	for kCategory,vCategory in pairs(aCategories) do
		local w = list_category.createWindow();
		w.category.setValue(kCategory);
		w.category_label.initialize(vCategory);
		if kCategory ~= "*" then
			w.category_label.setStateFrame("drophover", "fieldfocusplus", 7, 3, 7, 3);
			w.category_label.setStateFrame("drophilight", "fieldfocus", 7, 3, 7, 3);
		end
		if fCategory == kCategory then
			w.setFrame("rowshade");
		end
	end
	list_category.applySort();
	
	if not aCategories[fCategory] then
		handleCategorySelect("*");
	end
	
	if button_category_iedit.getValue() == 1 then
		button_category_iedit.setValue(0);
		button_category_iedit.setValue(1);
	end
end

function onNameFilterChanged()
	fName = filter_name.getValue():lower();
	applyListFilter();
end

function onSharedOnlyFilterChanged()
	fSharedOnly = (filter_sharedonly.getValue() == 1);
	applyListFilter();
end

function onIDChanged()
	for _,w in ipairs(list.getWindows()) do
		w.onIDChanged();
	end
	applyListFilter();
end

function addEntry()
	list_iadd.onButtonPress();
end

function onEditModeChanged(bEditMode)
	for _,v in ipairs(aEditControls) do
		v.setVisible(bEditMode);
	end
end

function getIndexRecord(vNode)
	if bDelayedChildrenChanged then
		onListRecordsChanged(false);
	end

	local sCategory = UtilityManager.getNodeCategory(vNode);
	local sModule = UtilityManager.getNodeModule(vNode);
	
	for _,rRecord in pairs(aRecords) do
		if sModule == UtilityManager.getNodeModule(rRecord.vNode) and sCategory == rRecord.sCategory then
			if rRecord.sNameLower:match("%(contents%)") or rRecord.sNameLower:match("%(index%)") then
				if vNode == rRecord.vNode then
					return nil;
				end
				return rRecord.vNode;
			end
		end
	end
	
	return nil;
end

function getNextRecord(vNode)
	if bDelayedChildrenChanged then
		onListRecordsChanged(false);
	end

	local sCategory = UtilityManager.getNodeCategory(vNode);
	local sModule = UtilityManager.getNodeModule(vNode);

	aSortedRecords = {};
	for _,rRecord in pairs(aRecords) do
		if sModule == UtilityManager.getNodeModule(rRecord.vNode) and sCategory == rRecord.sCategory then
			table.insert(aSortedRecords, rRecord);
		end
	end
	table.sort(aSortedRecords, applyRecordSort);
	
	local bGetNext = false;
	for _,rRecord in ipairs(aSortedRecords) do
		if bGetNext then
			return rRecord.vNode;
		end
		if rRecord.vNode == vNode then
			bGetNext = true;
		end
	end
	
	return nil;
end

function getPrevRecord(vNode)	
	if bDelayedChildrenChanged then
		onListRecordsChanged(false);
	end

	local sCategory = UtilityManager.getNodeCategory(vNode);
	local sModule = UtilityManager.getNodeModule(vNode);

	aSortedRecords = {};
	for _,rRecord in pairs(aRecords) do
		if sModule == UtilityManager.getNodeModule(rRecord.vNode) and sCategory == rRecord.sCategory then
			table.insert(aSortedRecords, rRecord);
		end
	end
	table.sort(aSortedRecords, applyRecordSort);
	
	local nodePrev = nil;
	for _,rRecord in ipairs(aSortedRecords) do
		if rRecord.vNode == vNode then
			return nodePrev;
		end
		nodePrev = rRecord.vNode;
	end
	
	return nil;
end

