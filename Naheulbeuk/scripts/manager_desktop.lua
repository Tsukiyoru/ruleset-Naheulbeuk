-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local m_wShortcuts = nil;

local m_rcStackOffset = { left = 6, top = 2, right = 4, bottom = 0 };
local m_szStackIcon = { w = 47, h = 27 };
local m_szStackSpacing = { w = 0, h = 0 };

local m_nMaxDockCols = 3;
local m_dDockScaleAddColThreshold = 0.75;

local m_rcDockOffset = { left = 2, top = 5, right = 2, bottom = 0 };
local m_szDockIcon = { w = 100, h = 95 };
local m_szDockSpacing = { w = 0, h = 2 };

local m_rcLowerDockOffset = { left = 2, top = 5, right = 2, bottom = 5 };

local m_aStackControls = {};
local m_aDockControls = {};
local m_aLowerDockControls = {};

local bDelayUpdate = false;
local m_aDelayedCreate = {};
local m_aDelayedLibraryCreate = {};

local bShowDockTitleText = false;
local sDockTitleFont = "mini_name_selected";
local sDockTitleFrame = "mini_name";
local rcDockTitleFrameOffset = { left = 5, top = 2, right = 5, bottom = 2 };
local positionDockTitle = { anchor = "top", x = 0, y = 10 };

local aSidebarOrder = {};
aDefaultSidebarState = {
	["gm"] = "charsheet,note,image,table,story,quest,npc,battle,item,treasureparcel,vehicle",
	["play"] = "charsheet,note,image,story,npc,item",
	["create"] = "charsheet",
};

--
--	Initialization and clean up
--

function onInit()
	Interface.onDesktopInit = onDesktopInit;
	Interface.onDesktopClose = onDesktopClose;
end

function onDesktopInit()
	if type(CampaignRegistry.sidebar) ~= "string" then
		CampaignRegistry.sidebar = nil;
	end
	LibraryData.initialize();
	initializeSidebar();
end

function onDesktopClose()
	CampaignRegistry.sidebar = table.concat(aSidebarOrder, ",");
end

--
--	Sidebar details management
--

function registerContainerWindow(w)
	bDelayUpdate = true;
	m_wShortcuts = w;

	for _,f in ipairs(m_aDelayedCreate) do
		f();
	end
	m_aDelayedCreate = {};
	for _,f in ipairs(m_aDelayedLibraryCreate) do
		f();
	end
	m_aDelayedLibraryCreate = {};
	
	m_wShortcuts.onSizeChanged = updateControls;
	bDelayUpdate = false;
	updateControls();
end

function setStackOffset(l, t, r, b)
	m_rcStackOffset.left = l;
	m_rcStackOffset.top = t;
	m_rcStackOffset.right = r;
	m_rcStackOffset.bottom = b;
end

function setUpperDockOffset(l, t, r, b)
	m_rcDockOffset.left = l;
	m_rcDockOffset.top = t;
	m_rcDockOffset.right = r;
	m_rcDockOffset.bottom = b;
end

function setLowerDockOffset(l, t, r, b)
	m_rcLowerDockOffset.left = l;
	m_rcLowerDockOffset.top = t;
	m_rcLowerDockOffset.right = r;
	m_rcLowerDockOffset.bottom = b;
end

function setStackIconSizeAndSpacing(iw, ih, sw, sh)
	m_szStackIcon.w = iw;
	m_szStackIcon.h = ih;
	m_szStackSpacing.w = sw;
	m_szStackSpacing.h = sh;
end

function setDockIconSizeAndSpacing(iw, ih, sw, sh)
	m_szDockIcon.w = iw;
	m_szDockIcon.h = ih;
	m_szDockSpacing.w = sw;
	m_szDockSpacing.h = sh;
end

function setMinDockScaling(dScale)
	if dScale >= .25 and dScale <= 1.0 then
		m_dDockScaleAddColThreshold = dScale;
	end
end

function setMaxDockColumns(nMaxDockCols)
    m_nMaxDockCols = nMaxDockCols;
end

function showDockTitleText(bState)
	bShowDockTitleText = bState;
end

function setDockTitleFont(sFont)
	sDockTitleFont = sFont;
end

function setDockTitleFrame(sFrame, nLeft, nTop, nRight, nBottom)
	sDockTitleFrame = sFrame;
	rcDockTitleFrameOffset.left = nLeft or 0;
	rcDockTitleFrameOffset.top = nTop or 0;
	rcDockTitleFrameOffset.right = nRight or 0;
	rcDockTitleFrameOffset.bottom = nBottom or 0;
end

function setDockTitlePosition(sAnchor, nX, nY)
	positionDockTitle.anchor = sAnchor;
	positionDockTitle.x = nX;
	positionDockTitle.y = nY;
end

function updateControls()
	if not m_wShortcuts or bDelayUpdate then
		return;
	end
	bDelayUpdate = true;
	local szWindow = {};
	szWindow.w, szWindow.h = m_wShortcuts.getSize();
	if szWindow.h == 0 then
		return;
	end
	
	local rAreas = calcAreas(szWindow);
	
	local szBar = { w = 0, h = 0 };
	szBar.w = math.max(rAreas.szStack.w, rAreas.szUpperDock.w, rAreas.szLowerDock.w);
	m_wShortcuts.shortcutbar.setAnchoredWidth(szBar.w);
	
	layoutArea(m_aStackControls, m_rcStackOffset, m_szStackIcon, m_szStackSpacing, rAreas.nStackCols, rAreas.szStack, 1, szBar);
	
	layoutArea(m_aDockControls, m_rcDockOffset, m_szDockIcon, m_szDockSpacing, rAreas.nDockCols, rAreas.szUpperDock, rAreas.dDockScale, szBar);
	
	szBar.h = szWindow.h - rAreas.szLowerDock.h - (m_rcLowerDockOffset.top + m_rcLowerDockOffset.bottom);
	layoutArea(m_aLowerDockControls, m_rcLowerDockOffset, m_szDockIcon, m_szDockSpacing, rAreas.nDockCols, rAreas.szLowerDock, rAreas.dDockScale, szBar);
	
	local wAnchor = Interface.findWindow("shortcutsanchor", "");
	wAnchor.setPosition(-szBar.w, 0, true);
	bDelayUpdate = false;
end

function calcAreas(szWindow)
	local rAreas = {};
	
	rAreas.nStackCols = 0;
	rAreas.szStack = { w = 0, h = 0 };
	rAreas.nDockCols = 0;
	rAreas.szUpperDock = { w = 0, h = 0 };
	rAreas.szLowerDock = { w = 0, h = 0 };
	
	repeat
		rAreas.nDockCols = rAreas.nDockCols + 1;
		rAreas.szUpperDock.w = (rAreas.nDockCols * m_szDockIcon.w) + ((rAreas.nDockCols - 1) * m_szDockSpacing.w) + (m_rcDockOffset.left + m_rcDockOffset.right);
		
		local nPotentialStackW = rAreas.szUpperDock.w - (m_rcDockOffset.left + m_rcDockOffset.right);
		rAreas.nStackCols = math.max(math.floor(nPotentialStackW / (m_szStackIcon.w + m_szStackSpacing.w)), 1);
		rAreas.szStack.w = (rAreas.nStackCols * m_szStackIcon.w) + ((rAreas.nStackCols - 1) * m_szStackSpacing.w) + (m_rcStackOffset.left + m_rcStackOffset.right);

		rAreas.szStack.h = calcSectionHeight(m_aStackControls, rAreas.nStackCols, m_szStackIcon, m_szStackSpacing);
		rAreas.szUpperDock.h = calcSectionHeight(m_aDockControls, rAreas.nDockCols, m_szDockIcon, m_szDockSpacing);
		rAreas.szLowerDock.h = calcSectionHeight(m_aLowerDockControls, rAreas.nDockCols, m_szDockIcon, m_szDockSpacing);
		
		local nTotalH = m_rcStackOffset.top + rAreas.szStack.h + m_rcDockOffset.top + (rAreas.szUpperDock.h * m_dDockScaleAddColThreshold) + m_rcLowerDockOffset.top + (rAreas.szLowerDock.h * m_dDockScaleAddColThreshold) + m_rcLowerDockOffset.bottom;
		if rAreas.nDockCols >= m_nMaxDockCols then
			break;
		end
	until szWindow.h > nTotalH;
	
	rAreas.szLowerDock.w = rAreas.szUpperDock.w;

	local nRemainderH = szWindow.h - rAreas.szStack.h - m_rcDockOffset.top - m_rcLowerDockOffset.top - m_rcLowerDockOffset.bottom;
	local nTotalDockH = rAreas.szUpperDock.h + rAreas.szLowerDock.h;
	rAreas.dDockScale = 1;
	if (nRemainderH > 0) and (nTotalDockH > nRemainderH) then
		rAreas.dDockScale = nRemainderH / nTotalDockH;
		rAreas.szUpperDock.h = rAreas.dDockScale * rAreas.szUpperDock.h;
		rAreas.szLowerDock.h = rAreas.dDockScale * rAreas.szLowerDock.h;
	end
	
	return rAreas;
end

function calcSectionHeight(aControls, nCols, szIcon, szSpacing)
	local nRows = math.ceil(#aControls / nCols);
	local nHeight = 0;
	if nRows > 0 then
		nHeight = (nRows * szIcon.h) + ((nRows - 1) * szSpacing.h);
	else
		nRows = 0;
	end
	return nHeight, nRows;
end

function layoutArea(aControls, rcOffset, szIcon, szSpacing, nCols, szArea, dScale, szBar)
	local nFullRows = math.floor(#aControls/nCols);
	local nLeftOver = #aControls % nCols;
	
	local szScaledIcon = {};
	szScaledIcon.w = szIcon.w;
	szScaledIcon.h = szIcon.h * dScale;
	local szScaledSpacing = {};
	szScaledSpacing.w = szSpacing.w;
	szScaledSpacing.h = szSpacing.h * dScale;
	
	local nSectionOffsetW = math.floor((szBar.w - szArea.w) / 2);
	
	local szPlacement = { x = nSectionOffsetW + rcOffset.left, y = szBar.h + rcOffset.top };
	for i = 1, nFullRows do
		for j = 1, nCols do
			local nIndex = ((i-1)*nCols) + j;
			aControls[nIndex].setStaticBounds(szPlacement.x, szPlacement.y, szScaledIcon.w, szScaledIcon.h);
			szPlacement.x = szPlacement.x + szScaledIcon.w + szScaledSpacing.w;
		end
		szPlacement.x = nSectionOffsetW + rcOffset.left;
		szPlacement.y = szPlacement.y + szScaledIcon.h + szScaledSpacing.h;
	end
	
	if nLeftOver > 0 then
		local nLeftOverW = (nLeftOver * szScaledIcon.w) + ((nLeftOver - 1) * szScaledSpacing.w) + (rcOffset.left + rcOffset.right);
		local nLeftOverOffsetW = math.floor((szBar.w - nLeftOverW) / 2);
		szPlacement.x = nLeftOverOffsetW + rcOffset.left;
		for j = 1, nLeftOver do
			local nIndex = (nFullRows*nCols) + j;
			aControls[nIndex].setStaticBounds(szPlacement.x, szPlacement.y, szScaledIcon.w, szScaledIcon.h);
			szPlacement.x = szPlacement.x + szScaledIcon.w + szScaledSpacing.w;
		end
		szPlacement.y = szPlacement.y + szScaledIcon.h + szScaledSpacing.h;
	end
	
	if #aControls > 0 then
		szBar.h = szPlacement.y - szScaledSpacing.h;
	end
end

function registerStackShortcuts(aShortcuts)
	bDelayUpdate = true;
	for _,v in ipairs(aShortcuts) do
		registerStackShortcut2(v.icon, v.icon_down, v.tooltipres, v.class, v.path);
	end
	bDelayUpdate = false;
	updateControls();
end

function registerStackShortcut(iconNormal, iconPressed, tooltipText, className, recordName)
	function fCreate()
		createStackShortcut(iconNormal, iconPressed, tooltipText, className, recordName);
	end

	if m_wShortcuts == nil then
		table.insert(m_aDelayedCreate, fCreate);
	else
		fCreate();
	end
end

function registerStackShortcut2(iconNormal, iconPressed, sTooltipRes, className, recordName, bFront)
	function fCreate()
		createStackShortcut(iconNormal, iconPressed, Interface.getString(sTooltipRes), className, recordName, bFront);
	end

	if m_wShortcuts == nil then
		table.insert(m_aDelayedCreate, fCreate);
	else
		fCreate();
	end
end

function createStackShortcut(iconNormal, iconPressed, tooltipText, className, recordName, bFront)
	local c = m_wShortcuts.shortcutbar.subwindow.createControl("desktop_stackitem", tooltipText);
	
	if bFront then
		table.insert(m_aStackControls, 1, c);
	else
		table.insert(m_aStackControls, c);
	end
	
	c.setIcons(iconNormal, iconPressed);
	c.setValue(className, recordName or "");
	c.setTooltipText(tooltipText);
	
	updateControls();
end

function removeStackShortcut(recordName)
	for iStack,cStack in ipairs(m_aStackControls) do
		if cStack.getValue() == recordName then
			table.remove(m_aStackControls, iStack)
			cStack.destroy()
			break;
		end
	end
end

function registerDockShortcuts(aShortcuts)
	bDelayUpdate = true;
	for _,v in ipairs(aShortcuts) do
		registerDockShortcut2(v.icon, v.icon_down, v.tooltipres, v.class, v.path, v.subdock);
	end
	bDelayUpdate = false;
	updateControls();
end

function registerDockShortcut(iconNormal, iconPressed, tooltipText, className, recordName, useSubdock)
	function fCreate()
		createDockShortcut(iconNormal, iconPressed, tooltipText, className, recordName, useSubdock);
	end

	if m_wShortcuts == nil then
		table.insert(m_aDelayedCreate, fCreate);
	else
		fCreate();
	end
end

function registerDockShortcut2(iconNormal, iconPressed, sTooltipRes, className, recordName, useSubdock, bFront)
	function fCreate()
		createDockShortcut(iconNormal, iconPressed, Interface.getString(sTooltipRes), className, recordName, useSubdock, bFront);
	end

	if m_wShortcuts == nil then
		table.insert(m_aDelayedCreate, fCreate);
	else
		fCreate();
	end
end

function createDockShortcut(iconNormal, iconPressed, tooltipText, className, recordName, useSubdock, bFront)
	local c = m_wShortcuts.shortcutbar.subwindow.createControl("desktop_dockitem", tooltipText);
	
	if useSubdock then
		if bFront then
			table.insert(m_aLowerDockControls, 1, c);
		else
			table.insert(m_aLowerDockControls, c);
		end
	else
		if bFront then
			table.insert(m_aDockControls, 1, c);
		else
			table.insert(m_aDockControls, c);
		end
	end
	
	c.setIcons(iconNormal, iconPressed);
	c.setValue(className, recordName or "");
	c.setTooltipText(tooltipText);
	
	if bShowDockTitleText then
		local widgetText = c.addTextWidget(sDockTitleFont, c.getTooltipText());
		widgetText.setPosition(positionDockTitle.anchor, positionDockTitle.x, positionDockTitle.y);
		widgetText.setFrame(sDockTitleFrame, rcDockTitleFrameOffset.left, rcDockTitleFrameOffset.top, rcDockTitleFrameOffset.right, rcDockTitleFrameOffset.bottom);
		widgetText.setName("title");
	end

	updateControls();
end

function removeDockShortcut(recordName, useSubdock)
	local aControls;
	if useSubdock then
		aControls = m_aLowerDockControls;
	else
		aControls = m_aDockControls;
	end
	
	for iDock,cDock in ipairs(aControls) do
		if cDock.getValue() == recordName then
			table.remove(aControls, iDock)
			cDock.destroy()
			break;
		end
	end
end

function addLibraryDockShortcut(sRecordType)
	function fCreate()
		createLibraryDockShortcut(sRecordType);
	end

	if m_wShortcuts == nil then
		table.insert(m_aDelayedLibraryCreate, fCreate);
	else
		fCreate();
	end
end

function createLibraryDockShortcut(sRecordType)
	for _,vCtrl in ipairs(m_aDockControls) do
		local sName = vCtrl.getName();
		if sName ~= "" then
			if sName == sRecordType then
				return false;
			end
		end
	end
	
	local c = m_wShortcuts.shortcutbar.subwindow.createControl("button_library_sidebar", sRecordType);
	c.setRecordType(sRecordType);
	
	if bShowDockTitleText then
		local widgetText = c.addTextWidget(sDockTitleFont, c.getTooltipText());
		widgetText.setPosition(positionDockTitle.anchor, positionDockTitle.x, positionDockTitle.y);
		widgetText.setFrame(sDockTitleFrame, rcDockTitleFrameOffset.left, rcDockTitleFrameOffset.top, rcDockTitleFrameOffset.right, rcDockTitleFrameOffset.bottom);
		widgetText.setName("title");
	end

	table.insert(m_aDockControls, c);

	updateControls();
end

function removeLibraryDockShortcut(sRecordType)
	if (sRecordType or "") == "" then
		return;
	end
	
	for kCtrl,vCtrl in ipairs(m_aDockControls) do
		if vCtrl.getName() == sRecordType then
			table.remove(m_aDockControls, kCtrl);
			vCtrl.destroy();
			updateControls();
			break;
		end
	end
end

--
--	Sidebar state management
--

function toggleIndex(sRecordType)
	local rRecordType = LibraryData.getRecordTypeInfo(sRecordType);
	if not rRecordType then
		return;
	end
	
	if rRecordType.fToggleIndex then
		rRecordType.fToggleIndex();
		return;
	end
	
	local sDisplayIndex = "masterindex";
	if rRecordType.sDisplayIndex then
		sDisplayIndex = rRecordType.sDisplayIndex;
	end
	
	local aMappings = LibraryData.getMappings(sRecordType);
	Interface.toggleWindow(sDisplayIndex, aMappings[1]);
end

function initializeSidebar()
	bDelayUpdate = true;
	for _,v in ipairs(aSidebarOrder) do
		DesktopManager.removeLibraryDockShortcut(v);
	end
	aSidebarOrder = {};
	if not CampaignRegistry.sidebar or (CampaignRegistry.sidebar == "") then
		if User.isLocal() then
			CampaignRegistry.sidebar = aDefaultSidebarState["create"];
		elseif User.isHost() then
			CampaignRegistry.sidebar = aDefaultSidebarState["gm"];
		else
			CampaignRegistry.sidebar = aDefaultSidebarState["play"];
		end
	end
	local aSavedOrder = StringManager.split(CampaignRegistry.sidebar, ",", true);
	for _,v in ipairs(aSavedOrder) do
		if LibraryData.getRecordTypeInfo(v) then
			table.insert(aSidebarOrder, v);
			DesktopManager.addLibraryDockShortcut(v);
		end
	end
	bDelayUpdate = false;
	updateControls();
end

function resetSidebar(sMode)
	if sMode == "all" then
		local aAllOrder = StringManager.split(aDefaultSidebarState["gm"], ",", true);
		local aAllRecordTypes = LibraryData.getRecordTypes();
		for _,vRecordType in pairs(aAllRecordTypes) do
			if not StringManager.contains(aAllOrder, vRecordType) and not LibraryData.isHidden(vRecordType) then
				table.insert(aAllOrder, vRecordType);
			end
		end
		CampaignRegistry.sidebar = table.concat(aAllOrder, ",");
	else
		CampaignRegistry.sidebar = aDefaultSidebarState[sMode];
	end
	
	initializeSidebar();
end

function onSidebarOptionChanged(sRecordType, nValue)
	local rRecordType = LibraryData.getRecordTypeInfo(sRecordType);
	if not rRecordType then
		return;
	end
	
	setSidebarButtonState(sRecordType, (nValue == 1));
end
function getSidebarButtonState(sRecordType)
	return StringManager.contains(aSidebarOrder, sRecordType);
end
function setSidebarButtonState(sRecordType, bState)
	local bCurrentState = getSidebarButtonState(sRecordType);
	if bState == bCurrentState then
		return;
	end
	
	if bState then
		table.insert(aSidebarOrder, sRecordType);
		DesktopManager.addLibraryDockShortcut(sRecordType);
	else
		for k,v in ipairs(aSidebarOrder) do
			if v == sRecordType then
				table.remove(aSidebarOrder, k);
				break;
			end
		end
		DesktopManager.removeLibraryDockShortcut(sRecordType);
	end
end

function setDefaultSidebarState(sMode, sNewDefaultState)
	aDefaultSidebarState[sMode] = sNewDefaultState;
end

function appendDefaultSidebarState(sMode, sAppend)
	aDefaultSidebarState[sMode] = aDefaultSidebarState[sMode] .. "," .. sAppend;
end

--
--  Suggested module set management
--

local aDataModuleSets = {};

function addDataModuleSets(aDataModulesSetsValue)
	if not aDataModulesSetsValue then
		return;
	end
	for _,v in ipairs(aDataModulesSetsValue) do
		addDataModuleSet(v.name, v.modules);
	end
end

function addDataModuleSet(sDataModuleSetNameValue, aDataModulesValue)
	table.insert(aDataModuleSets, { sName=sDataModuleSetNameValue, aModules=aDataModulesValue });
end

function getDataModuleSets()
	return aDataModuleSets;
end

local aTokenPackSets = {};

function addTokenPackSets(aTokenPacksSetsValue)
	if not aTokenPacksSetsValue then
		return;
	end
	for _,v in ipairs(aTokenPacksSetsValue) do
		addTokenPackSet(v.name, v.modules);
	end
end

function addTokenPackSet(sTokenPackSetNameValue, aTokenPacksValue)
	table.insert(aTokenPackSets, { sName=sTokenPackSetNameValue, aModules=aTokenPacksValue });
end

function getTokenPackSets()
	return aTokenPackSets;
end
